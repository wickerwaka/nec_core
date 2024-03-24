`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module nec_decode(
    input clk,
    input ce_1,
    input ce_2,

    output reg [15:0] pc,

    input [15:0] new_pc,
    input        set_pc,

    input        retire_op,

    input [3:0] ipq_len,
    input [7:0] ipq[8],

    output logic valid,

    output nec_decode_t decoded
);

/* verilator lint_off CASEX */
/* verilator lint_off CASEOVERLAP */
`include "opcodes.svh"
/* verilator lint_on CASEOVERLAP */
/* verilator lint_on CASEX */

function bit [7:0] ipq_byte(bit [2:0] ofs);
    return ipq[pc[2:0] + ofs[2:0]];
endfunction

decode_state_e state;

nec_decode_t d; // in flight
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

reg [2:0] disp_read;
reg [2:0] imm_read;

task reset_decode();
    d.segment_override <= 0;
    d.segment <= DS0;
    d.buslock <= 0;
    d.rep <= REPEAT_NONE;
    d.mem_write <= 0;
    d.mem_read <= 0;
    d.mod <= 2'b11;
    d.dest <= OPERAND_NONE;
    d.source0 <= OPERAND_NONE;
    d.source1 <= OPERAND_NONE;
    d.opcode <= OP_INVALID;
    d.alu_operation <= ALU_OP_NONE;
    d.push <= 16'd0;
    d.pop <= 16'd0;

    d.cycles <= 0;
    d.mem_cycles <= 0;

    disp_read <= 3'd0;
    imm_read <= 3'd0;
    state <= INITIAL;
endtask


wire [2:0] disp_size = calc_disp_size(d.rm, d.mod);
wire [2:0] imm_size = calc_imm_size(d.width, d.source0, d.source1);

wire decode_ready = state == TERMINAL && disp_size == disp_read && imm_size == imm_read;
assign valid = decode_ready & ~set_pc;


always_ff @(posedge clk) begin
    bit [3:0] avail;
    bit [7:0] q;

    avail = ipq_len;

    q = ipq_byte(0);

    if (ce_1 | ce_2) begin
        if (set_pc) begin
            pc <= new_pc;
            reset_decode();
        end else if (ce_1) begin
            case(state)
                TERMINAL: begin
                    if (disp_read < disp_size) begin
                        if (avail > 0) begin
                            d.disp[(disp_read*8) +: 8] <= q;
                            pc <= pc + 16'd1;
                            disp_read <= disp_read + 3'd1;
                        end
                    end else if (imm_read < imm_size) begin
                        if (avail > 0) begin
                            d.imm[(imm_read*8) +: 8] <= q;
                            pc <= pc + 16'd1;
                            imm_read <= imm_read + 3'd1;
                        end
                    end else if (retire_op) begin
                        reset_decode();
                        if (avail > 0) begin
                            process_decode(q);
                            pc <= pc + 16'd1;
                        end
                    end
                end

                default: begin
                    if (avail > 0) begin
                        process_decode(q);
                        pc <= pc + 16'd1;
                    end
                end

            endcase
        end
    end
end

endmodule