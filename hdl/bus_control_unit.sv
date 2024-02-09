`ifdef LINTING
`include "types.sv"
`endif

import types::*;

// V33 bus control with prefetch
// Not implemented:
//   buslock, hldrq, hldak
//   extended addressing (aex)
//   bus sizing
//   co-processor memory access
// TODO
//   Halting
//   Interrupt ack
module bus_control_unit(
    input               clk,
    input               ce_1,
    input               ce_2,


    // Pins
    input               reset,
    input               hldrq,
    input               n_ready,
    input               bs16,

    output  reg         hldak,
    output              n_buslock,
    output  reg         n_ube,
    output              r_w,
    output              m_io,
    output              busst0,
    output              busst1,
    output              aex,
    output              n_bcyst,
    output              n_dstb,

    output  reg [23:0]  addr,
    output      [15:0]  dout,
    input       [15:0]  din,


    // Execution Unit Communication
    input       [15:0]  reg_ps,
    input       [15:0]  reg_ss,
    input       [15:0]  reg_ds0,
    input       [15:0]  reg_ds1,

    // instruction queue
    // inputs only read on ce1
    input               pfp_set,
    input       [15:0]  ipq_head,
    output  reg [7:0]   ipq[8],
    output      [3:0]   ipq_len,

    // Data pointer read/write
    input       [15:0]  dp_addr,
    input       [15:0]  dp_dout,
    output  reg [15:0]  dp_din,
    input sreg_index_e  dp_sreg,
    input               dp_write,
    input               dp_wide,
    input               dp_io,
    input               dp_req, // edge triggered
    input               dp_zero_seg,
    output              dp_ready,

    output  reg         implementation_fault,

    // Interrupt handling
    input               intreq,
    output  reg         intack,
    output  reg  [7:0]  intvec
);

function bit [23:0] physical_addr(sreg_index_e sreg, bit [15:0] ea);
    bit [19:0] addr;
    case(sreg)
    DS0: addr = {reg_ds0, 4'd0} + {4'd0, ea};
    DS1: addr = {reg_ds1, 4'd0} + {4'd0, ea};
    SS: addr = {reg_ss, 4'd0} + {4'd0, ea};
    PS: addr = {reg_ps, 4'd0} + {4'd0, ea};
    endcase
    return { 4'd0, addr };
endfunction

enum {T_1, T_2, T_IDLE} t_state;
enum {INT_ACK1, INT_ACK2, IO_READ, IO_WRITE, HALT_ACK, IPQ_FETCH, MEM_READ, MEM_WRITE} cycle_type;

assign n_bcyst = ~(t_state == T_1);

// Set external bus status signals based on cycle_type
always_comb begin
    case(cycle_type)
    INT_ACK1,
    INT_ACK2:  begin m_io = 0; r_w = 1; busst1 = 0; busst0 = 0; end
    IO_READ:   begin m_io = 0; r_w = 1; busst1 = 0; busst0 = 1; end
    IO_WRITE:  begin m_io = 0; r_w = 0; busst1 = 0; busst0 = 1; end
    HALT_ACK:  begin m_io = 0; r_w = 0; busst1 = 1; busst0 = 1; end
    IPQ_FETCH: begin m_io = 1; r_w = 1; busst1 = 0; busst0 = 0; end
    MEM_READ:  begin m_io = 1; r_w = 1; busst1 = 0; busst0 = 1; end
    MEM_WRITE: begin m_io = 1; r_w = 0; busst1 = 0; busst0 = 1; end
    endcase
end

reg [15:0] reg_pfp;
reg discard_ipq_fetch = 0;
assign ipq_len = pfp_set ? 4'd0 : reg_pfp[3:0] - ipq_head[3:0];

assign dp_ready = (dp_ack == dp_req);
reg dp_ack;
reg second_byte;
int intack_idles;


always_ff @(posedge clk) begin
    bit [3:0] new_ipq_used;

    if (reset) begin
        t_state <= T_IDLE;

        hldak <= 0;
        n_ube <= 0;
        n_dstb <= 1;

        cycle_type <= IPQ_FETCH;
        intack <= 0;

        implementation_fault <= 0;

        reg_pfp <= ipq_head;
        discard_ipq_fetch <= 0;

        dp_ack <= 0;
        dp_din <= 16'hffff;

        second_byte <= 0;
    end else if (ce_1 | ce_2) begin
        bit [15:0] cur_pfp;
        new_ipq_used = ipq_len;
        cur_pfp = reg_pfp;
        if (pfp_set) begin
            reg_pfp <= ipq_head;
            cur_pfp = ipq_head;
            new_ipq_used = 0;
            discard_ipq_fetch <= 1;
        end

        if (~intreq) intack <= 0;

        if (ce_1) begin
            case(t_state)
            T_IDLE: begin
                n_dstb <= 1; // clear data strobe
                intack_idles <= intack_idles + 1;
                if (cycle_type == INT_ACK1) begin
                    if (intack_idles == 6) begin
                        t_state <= T_1;
                        cycle_type <= INT_ACK2;
                        intack_idles <= 0;
                    end
                end else if (cycle_type == INT_ACK2) begin
                    if (intack_idles == 5) begin
                        cycle_type <= IPQ_FETCH;
                        intack <= 1;
                    end
                end else if (intreq & ~intack) begin
                    cycle_type <= INT_ACK1;
                    t_state <= T_1;
                    intack_idles <= 0;
                    n_ube <= 1;
                end else if (dp_req != dp_ack) begin
                    t_state <= T_1;
                    if (dp_io) begin
                        addr <= {8'd0, second_byte ? (dp_addr + 16'd1) : dp_addr};
                        cycle_type <= dp_write ? IO_WRITE : IO_READ;
                    end else begin
                        if (dp_zero_seg) begin
                            addr <= { 8'd0, second_byte ? (dp_addr + 16'd1) : dp_addr };
                        end else begin
                            addr <= physical_addr(dp_sreg, second_byte ? (dp_addr + 16'd1) : dp_addr);
                        end
                        cycle_type <= dp_write ? MEM_WRITE : MEM_READ;
                    end
                    n_ube <= second_byte | (~dp_wide & ~dp_addr[0]);
                end else if (new_ipq_used < 7) begin
                    t_state <= T_1;
                    cycle_type <= IPQ_FETCH;
                    addr <= physical_addr(PS, cur_pfp);
                    n_ube <= 0; // always
                    discard_ipq_fetch <= 0;
                end
            end
            T_1: t_state <= T_2;
            endcase
        end else if (ce_2) begin
            case(t_state)
            T_1: begin
                n_dstb <= 0;
                dout <= dp_addr[0] ? { dp_dout[7:0], dp_dout[15:8] } : dp_dout;
            end
            T_2: begin
                if (~n_ready) begin
                    second_byte <= 0;
                    case(cycle_type)
                    IPQ_FETCH: begin
                        if (~pfp_set & ~discard_ipq_fetch) begin
                            if (reg_pfp[0]) begin
                                ipq[reg_pfp[2:0]] <= din[15:8];
                                reg_pfp <= reg_pfp + 16'd1;
                            end else begin
                                ipq[reg_pfp[2:0]] <= din[7:0];
                                ipq[reg_pfp[2:0] + 1] <= din[15:8];
                                reg_pfp <= reg_pfp + 16'd2;
                            end
                        end
                    end
                    MEM_READ, IO_READ: begin
                        dp_ack <= dp_req;
                        if (dp_wide & ~dp_addr[0]) begin
                            dp_din <= din;
                        end else if (dp_wide & ~n_ube) begin
                            dp_din[7:0] <= din[15:8];
                            second_byte <= 1;
                            dp_ack <= dp_ack;
                        end else if (dp_wide) begin
                            dp_din[15:8] <= din[7:0];
                        end else if (~n_ube) begin
                            dp_din[7:0] <= din[15:8];
                        end else begin
                            dp_din[7:0] <= din[7:0];
                        end
                    end
                    MEM_WRITE, IO_WRITE: begin
                        if (dp_wide & dp_addr[0] & ~n_ube) begin
                            second_byte <= 1;
                        end else begin
                            dp_ack <= dp_req;
                        end
                    end
                    INT_ACK1,
                    INT_ACK2: begin
                        intvec <= dp_din[7:0];
                    end
                    endcase

                    t_state <= T_IDLE;
                end
            end
            endcase
        end
    end
end

endmodule