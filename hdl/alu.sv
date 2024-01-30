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
    output reg [15:0] result,

    input execute,
    output busy
);

reg executing = 0;

assign busy = execute | executing;

always_ff @(posedge clk) begin
    if (reset) begin
        executing <= 0;
    end else if (ce) begin
        if (execute) begin
            executing <= 1;
            case(operation)
            ALU_OP_ADD: begin
                result <= ta + tb;
                executing <= 0;
            end
            ALU_OP_NONE: executing <= 0;
            endcase
        end else if (executing) begin
            executing <= 0;
        end
    end
end

endmodule
