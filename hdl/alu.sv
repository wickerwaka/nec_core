`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module alu(
    input clk,
    input ce,

    input reset,

    input alu_operation_e operation,
    input [15:0] ta,
    input [15:0] tb,
    input wide,
    output reg [15:0] result,

    input flags_t flags_in,
    output flags_t flags,

    input execute,
    output busy
);

reg executing = 0;

assign busy = execute | executing;

always_ff @(posedge clk) begin
    bit done = 0;
    bit calc_parity = 0;
    bit calc_sign = 0;
    bit calc_zero = 0;
    flags_t fcalc;
    bit [16:0] r;

    if (reset) begin
        executing <= 0;
    end else if (ce) begin
        if (execute) begin
            executing <= 1;
            flags <= flags_in;
            case(operation)
            ALU_OP_ADD: begin
                r = { 1'b0, ta } + { 1'b0, tb };
                flags.CY <= wide ? r[16] : r[8];
                if (({1'b0, ta[3:0]} + {1'b0, tb[3:0]}) >= 5'd16)
                    flags.AC <= 1;
                else
                    flags.AC <= 0;
                
                if (wide)
                    flags.V <= (ta[15] ^ r[15]) & (tb[15] ^ r[15]);
                else
                    flags.V <= (ta[7] ^ r[7]) & (tb[7] ^ r[7]);

                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end
            ALU_OP_NONE: executing <= 0;
            endcase
        end else if (executing) begin
            executing <= 0;
        end

        if (done) begin
            executing <= 0;
            if (~wide) r = r & 17'h000ff;
            if (calc_parity) flags.P <= r[0] ^ r[1] ^ r[2] ^ r[3] ^ r[4] ^ r[5] ^ r[6] ^ r[7];
            if (calc_sign) flags.S <= wide ? r[15] : r[7];
            if (calc_zero) flags.Z <= r[15:0] == 16'd0;

            result <= r[15:0];
        end
    end
end

endmodule
