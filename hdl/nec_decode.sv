`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module nec_decode(
    input clk,
    input ce,

    output reg [15:0] pc,

    input [15:0] new_pc,
    input        set_pc,

    input        start,

    input [3:0] ipq_len,
    input [7:0] ipq[8],

    output logic busy,
    output logic valid,

    output nec_decode_t decoded
);

function bit [7:0] ipq_byte(bit [2:0] ofs);
    return ipq[pc[2:0] + ofs[2:0]];
endfunction

wire [23:0] q = { ipq_byte(0), ipq_byte(1), ipq_byte(2) };

decode_stage_e stage;
reg segment_override;
nec_decode_t d;

assign busy = (start | set_pc) || ( stage != INVALID && stage != DECODED );
assign valid = (stage == DECODED) && ~(start | set_pc);
assign decoded = d;

function bit [2:0] calc_imm_size(width_e width, operand_e s0, operand_e s1);
    case(s0)
    OPERAND_IMM: return width == DWORD ? 3'd4 : width == WORD ? 3'd2 : 3'd1;
    OPERAND_IMM8: return 3'd1;
    OPERAND_IMM_EXT: return 3'd1;
    default: begin end
    endcase

    case(s1)
    OPERAND_IMM: return width == DWORD ? 3'd4 : width == WORD ? 3'd2 : 3'd1;
    OPERAND_IMM8: return 3'd1;
    OPERAND_IMM_EXT: return 3'd1;
    default: begin end
    endcase

    return 3'd0;
endfunction

function bit [2:0] calc_disp_size(bit [2:0] mem, bit [1:0] mod);
    case(mod)
    2'b00: begin
        if (mem == 3'b110) return 3'd2;
        return 3'd0;
    end
    2'b01: return 3'd1;
    2'b10: return 3'd2;
    2'b11: return 3'd0;
    endcase
endfunction

function sreg_index_e calc_seg(bit [2:0] mem, bit [1:0] mod);
    sreg_index_e seg;
    case(mem)
    3'b010: seg = SS;
    3'b011: seg = SS;
    3'b110: seg = mod == 0 ? DS0 : SS;
    default: seg = DS0;
    endcase

    return seg;
endfunction

/* verilator lint_off CASEX */
always_ff @(posedge clk) begin
    bit valid_op;
    bit [2:0] op_size;
    bit [2:0] imm_size, disp_size;

    if (ce) begin
        if (set_pc) begin
            pc <= new_pc;
            stage <= OPCODE_FIRST;
        end else if (start) begin
            stage <= OPCODE_FIRST;
        end else begin
            case(stage)
                OPCODE_FIRST,
                OPCODE: if (ipq_len > 0) begin
                    if (stage == OPCODE_FIRST) begin
                        segment_override <= 0;
                        d.segment <= DS0;
                        d.buslock <= 0;
                        d.rep <= REPEAT_NONE;
                        d.pc <= pc;
                        stage <= OPCODE;
                    end

                    d.opcode <= OP_INVALID;
                    d.alu_operation <= ALU_OP_NONE;
                    d.push <= 16'd0;
                    d.pop <= 16'd0;
                    d.cycles <= 0;
                    d.mem_cycles <= 0;

                    valid_op = 0;
                    case(q[23:16])
                        8'b00100110: begin segment_override <= 1; d.segment <= DS1; pc <= pc + 16'd1; end
                        8'b00101110: begin segment_override <= 1; d.segment <= PS; pc <= pc + 16'd1; end
                        8'b00110110: begin segment_override <= 1; d.segment <= SS; pc <= pc + 16'd1; end
                        8'b00111110: begin segment_override <= 1; d.segment <= DS0; pc <= pc + 16'd1; end
                        8'b11110000: begin d.buslock <= 1; pc <= pc + 16'd1; end
                        8'b11110011: begin d.rep <= REPEAT_Z; pc <= pc + 16'd1; end
                        8'b01100101: begin d.rep <= REPEAT_C; pc <= pc + 16'd1; end
                        8'b01100100: begin d.rep <= REPEAT_NC; pc <= pc + 16'd1; end
                        8'b11110010: begin d.rep <= REPEAT_NZ; pc <= pc + 16'd1; end

                        default: begin
                            casex(q)
                                `include "opcodes.svh"
                            endcase
                        end
                    endcase
                    
                    if (valid_op && (ipq_len >= {1'd0, op_size})) begin
                        stage <= IMMEDIATES;
                        pc <= pc + {13'd0, op_size};
                    end
                end

                IMMEDIATES: begin
                    disp_size = 3'd0;
                    imm_size = 3'd0;
                    d.mem_read <= 0;
                    d.mem_write <= 0;
                    d.defer_read <= 0;

                    if (~segment_override & d.use_modrm) d.segment <= calc_seg(d.rm, d.mod);

                    d.defer_read <= (d.push != 16'd0 && d.opcode != OP_PUSH) || (d.pop != 16'd0 && d.opcode != OP_POP);

                    if (d.use_modrm & d.mod != 2'b11) begin
                        disp_size = calc_disp_size(d.rm, d.mod);
                        if (d.opcode != OP_LDEA) begin
                            d.mem_read <= (d.source0 == OPERAND_MODRM || d.source1 == OPERAND_MODRM) ? 1 : 0;
                            d.mem_write <= d.dest == OPERAND_MODRM ? 1 : 0;
                        end
                    end

                    if (d.opcode == OP_PREPARE) begin
                        imm_size = 3'd3;
                    end else begin
                        imm_size = calc_imm_size(d.width, d.source0, d.source1);
                    end

                    if (ipq_len >= (disp_size + imm_size)) begin
                        d.imm[7:0] <= ipq_byte(disp_size);
                        d.imm[15:8] <= ipq_byte(disp_size + 3'd1);
                        d.imm[23:16] <= ipq_byte(disp_size + 3'd2);
                        d.imm[31:24] <= ipq_byte(disp_size + 3'd3);
                        d.disp <= { ipq_byte(3'd1), ipq_byte(3'd0) };
                        d.end_pc <= pc + { 13'd0, disp_size + imm_size };
                        pc <= pc + { 13'd0, disp_size + imm_size };
                        stage <= DECODED;
                    end
                end

                default: begin
                end
            endcase
        end
    end
end

endmodule