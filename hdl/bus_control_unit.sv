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
    output  reg         r_w,
    output  reg         m_io,
    output  reg         busst0,
    output  reg         busst1,
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
    input       [1:0]   dp_sreg,
    input               dp_read,
    input       [1:0]   dp_be,
    input               dp_req,


    output  reg         implementation_fault,
);

typedef enum bit [1:0] {DS1, PS, SS, DS0} e_sreg_index;

enum {T1, T2, T_WAIT, T_IDLE} t_state;

assign n_bcyst = ~(t_state == T1);

reg [15:0] reg_pfp;

always_ff @(posedge clk) begin
    bit check_idle = 0;
    bit [3:0] new_ipq_used = ipq_used;
    if (reset) begin
        t_state <= T_IDLE;

        hldak <= 0;
        n_ube <= 0;
        r_w <= 1;
        m_io <= 1;

        implementation_fault <= 0;

        reg_pfp <= 16'd0;
        ipq_used <= 4'd0;

    end else if (ce_1) begin
        if (ipq_consume > ipq_used) begin
            implementation_fault <= 1;
        end else if (ipq_consume > 0) begin
            new_ipq_used = ipq_used - ipq_consume;
            for( int x = 0; x < 8; x++) begin
                ipq[x] <= ipq[x + ipq_consume];
            end
        end

        case(t_state)
        T1: begin
            if (dp_req) begin
                case(dp_sreg)
                DS0: addr <= {4'd0, reg_ds0, 4'd0} + {8'd0, dp_addr};
                DS1: addr <= {4'd0, reg_ds1, 4'd0} + {8'd0, dp_addr};
                SS: addr <= {4'd0, reg_ss, 4'd0} + {8'd0, dp_addr};
                PS: addr <= {4'd0, reg_ps, 4'd0} + {8'd0, dp_addr};
                endcase
            end
        end
        endcase

        ipq_used <= new_ipq_used; 

    end else if (ce_2) begin
        case(t_state)
        T1: begin
            t_state <= T2;
        end
        T2: begin
            if (n_ready) begin
                t_state <= T_WAIT;
            end else begin

                check_idle = 1;
            end
        end
        T_WAIT: begin
            if (~n_ready) begin
                check_idle = 1;
            end
        end
        T_IDLE: check_idle = 1;
        endcase

        if (check_idle) begin
            if (dp_req) begin
                t_state <= T1;
            end else begin
                t_state <= T_IDLE;
            end
        end
    end


end

endmodule