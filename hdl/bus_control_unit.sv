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
    input       [15:0]  pfp_new,
    input               pfp_set,
    input       [3:0]   ipq_consume,
    output  reg [3:0]   ipq_used,
    output  reg [7:0]   ipq[8],

    // Data pointer read/write
    input       [15:0]  dp_addr,
    input       [15:0]  dp_dout,
    output  reg [15:0]  dp_din,
    input sreg_index_e  dp_sreg,
    input               dp_write,
    input               dp_wide,
    input               dp_io,
    input               dp_req, // edge triggered
    output              dp_ready,

    output  reg         implementation_fault
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
enum {INT_ACK, IO_READ, IO_WRITE, HALT_ACK, IPQ_FETCH, MEM_READ, MEM_WRITE} cycle_type;

assign n_bcyst = ~(t_state == T_1);

// Set external bus status signals based on cycle_type
always_comb begin
    case(cycle_type)
    INT_ACK:   begin m_io = 0; r_w = 1; busst1 = 0; busst0 = 0; end
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

assign dp_ready = (dp_ack == dp_req);
reg dp_ack;
reg second_byte;

always_ff @(posedge clk) begin
    bit [3:0] new_ipq_used;

    if (reset) begin
        t_state <= T_IDLE;

        hldak <= 0;
        n_ube <= 0;
        n_dstb <= 1;

        cycle_type <= IPQ_FETCH;

        implementation_fault <= 0;

        reg_pfp <= 16'd0;
        ipq_used <= 4'd0;
        discard_ipq_fetch <= 0;

        dp_ack <= 0;
        dp_din <= 16'hffff;

        second_byte <= 0;
    end else if (ce_1) begin
        new_ipq_used = ipq_used - ipq_consume;
        if (pfp_set) begin
            reg_pfp <= pfp_new;
            new_ipq_used = 0;
            if (cycle_type == IPQ_FETCH && t_state != T_IDLE) discard_ipq_fetch <= 1;
        end else if (ipq_consume > ipq_used) begin
            implementation_fault <= 1;
        end else if (ipq_consume > 0) begin
            for( int x = 0; x < 8; x++) begin
                ipq[x] <= ipq[x + int'(ipq_consume)];
            end
        end

        case(t_state)
        T_IDLE: begin
            n_dstb <= 1; // clear data strobe
            if (dp_req != dp_ack) begin
                t_state <= T_1;
                if (dp_io) begin
                    addr <= {8'd0, second_byte ? (dp_addr + 16'd1) : dp_addr};
                    cycle_type <= dp_write ? IO_WRITE : IO_READ;
                end else begin
                    addr <= physical_addr(dp_sreg, second_byte ? (dp_addr + 16'd1) : dp_addr);
                    cycle_type <= dp_write ? MEM_WRITE : MEM_READ;
                end
                n_ube <= second_byte | (~dp_wide & ~dp_addr[0]);
            end else if (new_ipq_used < 7) begin
                t_state <= T_1;
                cycle_type <= IPQ_FETCH;
                addr <= physical_addr(PS, reg_pfp);
                n_ube <= 0; // always
            end
        end
        T_1: t_state <= T_2;
        endcase

        ipq_used <= new_ipq_used; 

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
                    if (~discard_ipq_fetch) begin
                        if (reg_pfp[0]) begin
                            ipq[int'(ipq_used)] <= din[15:8];
                            ipq_used <= ipq_used + 'd1;
                            reg_pfp <= reg_pfp + 16'd1;
                        end else begin
                            ipq[int'(ipq_used)] <= din[7:0];
                            ipq[int'(ipq_used) + 1] <= din[15:8];
                            ipq_used <= ipq_used + 'd2;
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
                endcase

                t_state <= T_IDLE;
            end
        end
        endcase
    end


end

endmodule