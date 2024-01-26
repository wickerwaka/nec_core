`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module pre_decode(
    input clk,
    input ce,

    input [7:0] q0,
    input [7:0] q1,
    input [7:0] q2,

    output reg wide,
    output reg sign_extend,
    output reg valid_op,

    output opcode_e opcode,
    output alu_operation_e alu_operation,
    output op_src_e op_source,
    output op_dst_e op_dest,

    output reg [1:0] ea_mod,
    output reg [2:0] ea_mem,
    output reg [2:0] reg0,
    output reg [2:0] reg1,

    output reg [1:0] pre_size
);

wire [23:0] q = { q0, q1, q2 };

always_ff @(posedge clk) begin
    if (ce) begin
        sign_extend <= 0;
        wide <= 1;
        valid_op <= 0;

        casex(q)
        24'b0000000xxxxxxxxxxxxxxxxx: begin opcode <= OP_ADD; alu_operation <= ALU_OP_ADD; op_source <= OP_SRC_REG0; op_dest <= OP_DST_MEM; wide <= q[16]; ea_mod <= q[15:14]; ea_mem <= q[10:8]; reg0 <= q[13:11]; pre_size <= 2; valid_op <= 1; end
        24'b0000001xxxxxxxxxxxxxxxxx: begin opcode <= OP_ADD; alu_operation <= ALU_OP_ADD; op_source <= OP_SRC_MEM; op_dest <= OP_DST_REG0; wide <= q[16]; ea_mod <= q[15:14]; ea_mem <= q[10:8]; reg0 <= q[13:11]; pre_size <= 2; valid_op <= 1; end
        24'b0000010xxxxxxxxxxxxxxxxx: begin opcode <= OP_ADD; alu_operation <= ALU_OP_ADD; op_source <= OP_SRC_IMM; op_dest <= OP_DST_ACC; wide <= q[16]; pre_size <= 1; valid_op <= 1; end
        24'b0000001x11xxxxxxxxxxxxxx: begin opcode <= OP_ADD; alu_operation <= ALU_OP_ADD; op_source <= OP_SRC_REG1; op_dest <= OP_DST_REG0; wide <= q[16]; reg0 <= q[13:11]; reg1 <= q[10:8]; pre_size <= 2; valid_op <= 1; end
        24'b100000xxxx000xxxxxxxxxxx: begin opcode <= OP_ADD; alu_operation <= ALU_OP_ADD; op_source <= OP_SRC_IMM; op_dest <= OP_DST_MEM; sign_extend <= q[17]; wide <= q[16]; ea_mod <= q[15:14]; ea_mem <= q[10:8]; pre_size <= 2; valid_op <= 1; end
        24'b100000xx11000xxxxxxxxxxx: begin opcode <= OP_ADD; alu_operation <= ALU_OP_ADD; op_source <= OP_SRC_IMM; op_dest <= OP_DST_REG0; sign_extend <= q[17]; wide <= q[16]; reg0 <= q[10:8]; pre_size <= 2; valid_op <= 1; end
        24'b0000111100100000xxxxxxxx: begin opcode <= OP_ADD4S; alu_operation <= ALU_OP_NONE; pre_size <= 2; valid_op <= 1; end
        endcase
    end
end

endmodule