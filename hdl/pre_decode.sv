`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module pre_decode(
    input clk,
    input ce,

    input [3:0] q_len,
    input [7:0] q0,
    input [7:0] q1,
    input [7:0] q2,

    output reg valid_op,

    output pre_decode_t decoded
);

wire [23:0] q = { q0, q1, q2 };

/* verilator lint_off CASEX */

always_ff @(posedge clk) begin
    pre_decode_t d;
    if (ce) begin
        valid_op <= 0;

        d.opcode = OP_NOP;
        d.push = 16'd0;
        d.pop = 16'd0;
        d.alu_operation = ALU_OP_NONE;

        casex(q)
        `include "opcodes.svh"
        endcase

        d.opcode_byte = q0;

        if (q_len < d.pre_size) valid_op <= 0;
        
        decoded <= d;
    end
end

endmodule