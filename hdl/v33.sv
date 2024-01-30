`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module V33(
    input               clk,
    input               ce_1,
    input               ce_2,


    // Pins
    input               reset,
    input               hldrq,
    input               n_ready,
    input               bs16,

    output              hldak,
    output              n_buslock,
    output              n_ube,
    output              r_w,
    output              m_io,
    output              busst0,
    output              busst1,
    output              aex,
    output              n_bcyst,
    output              n_dstb,

    input               intreq,
    input               n_nmi,

    input               n_cpbusy,
    input               n_cperr,
    input               cpreq,

    output      [23:0]  addr,
    output      [15:0]  dout,
    input       [15:0]  din
);

// Register file
// Segment registers
reg [15:0] reg_ds0, reg_ds1, reg_ss, reg_ps;
// General purpose
reg [15:0] reg_aw, reg_bw, reg_cw, reg_dw;
reg [15:0] reg_sp, reg_bp, reg_ix, reg_iy;

reg [15:0] reg_pc;

// Data Pointer operations
reg [15:0] dp_addr;
reg [15:0] dp_dout;
wire [15:0] dp_din;
sreg_index_e dp_sreg;
reg dp_write;
reg dp_wide;
reg dp_io;
reg dp_req;
wire dp_ready;

// Instruction prefetch
reg new_pc;

wire [7:0] ipq[8];
wire [3:0] ipq_len;

function bit [7:0] ipq_byte(int ofs);
    return ipq[reg_pc[2:0] + ofs[2:0]];
endfunction

// bleh, something better here?
function int calc_imm_size(operand_e s0, operand_e s1);
    case(s0)
    OPERAND_IMM8,
    OPERAND_IMM8_EXT: return 1;
    OPERAND_IMM16: return 2;
    endcase
    
    case(s1)
    OPERAND_IMM8,
    OPERAND_IMM8_EXT: return 1;
    OPERAND_IMM16: return 2;
    endcase

    return 0;
endfunction

function int calc_disp_size(bit [2:0] mem, bit [1:0] mod);
    case(mod)
    2'b00: begin
        if (mem == 3'b110) return 2;
        return 0;
    end
    2'b01: return 1;
    2'b10: return 2;
    2'b11: return 0;
    endcase
endfunction

function bit [15:0] calc_ea(bit [2:0] mem, bit [1:0] mod, bit [15:0] disp);
    bit [15:0] addr;
    case(mem)
    3'b000: addr = reg_bw + reg_ix;
    3'b001: addr = reg_bw + reg_iy;
    3'b010: addr = reg_bp + reg_ix;
    3'b011: addr = reg_bp + reg_iy;
    3'b100: addr = reg_ix;
    3'b101: addr = reg_iy;
    3'b110: addr = mod == 0 ? disp : reg_bp;
    3'b111: addr = reg_bw;
    endcase

    if (mod == 2'b01) addr = addr + { 8'd0, disp[7:0] };
    else if (mod == 2'b10) addr = addr + disp;

    return addr;
endfunction

function bit [7:0] get_reg8(reg8_index_e r);
    case(r)
    AL: return reg_aw[7:0];
    AH: return reg_aw[15:8];
    BL: return reg_bw[7:0];
    BH: return reg_bw[15:8];
    CL: return reg_cw[7:0];
    CH: return reg_cw[15:8];
    DL: return reg_dw[7:0];
    DH: return reg_dw[15:8];
    endcase
endfunction

function bit [15:0] get_reg16(reg16_index_e r);
    case(r)
    AW: return reg_aw;
    BW: return reg_bw;
    CW: return reg_cw;
    DW: return reg_dw;
    SP: return reg_sp;
    BP: return reg_bp;
    IX: return reg_ix;
    IY: return reg_iy;
    endcase
endfunction

function bit [15:0] get_operand(operand_e operand);
    case(operand)
    OPERAND_ACC8: return { 8'd0, reg_aw[7:0] };
    OPERAND_ACC16: return reg_aw;
    OPERAND_IMM16: return fetched_imm;
    OPERAND_IMM8: return { 8'd0, fetched_imm[7:0] };
    OPERAND_IMM8_EXT: return { {8{fetched_imm[7]}}, fetched_imm[7:0] };
    OPERAND_MEM8: return { 8'd0, dp_din[7:0] };
    OPERAND_MEM16: return dp_din;
    OPERAND_MEM32: return 16'hffff; // TODO MEM32
    OPERAND_SREG: begin
        case(decoded.sreg)
        DS0: return reg_ds0;
        DS1: return reg_ds1;
        SS: return reg_ss;
        PS: return reg_ps;
        endcase
    end
    OPERAND_REG16_0: return get_reg16(reg16_index_e'(decoded.reg0));
    OPERAND_REG16_1: return get_reg16(reg16_index_e'(decoded.reg1));
    OPERAND_REG8_0: return { 8'd0, get_reg8(reg8_index_e'(decoded.reg0)) };
    OPERAND_REG8_1: return { 8'd0, get_reg8(reg8_index_e'(decoded.reg1)) };
    endcase
endfunction

bus_control_unit BCU(
    .clk, .ce_1, .ce_2,
    .reset, .hldrq, .n_ready, .bs16,
    .hldak, .n_buslock, .n_ube, .r_w,
    .m_io, .busst0, .busst1, .aex,
    .n_bcyst, .n_dstb,
    .addr, .dout, .din,

    .reg_ps, .reg_ss, .reg_ds0, .reg_ds1,

    .pfp_set(new_pc),
    .ipq, .ipq_head(reg_pc), .ipq_len,

    .dp_addr, .dp_dout, .dp_din, .dp_sreg,
    .dp_write, .dp_wide, .dp_io, .dp_req,
    .dp_ready,

    .implementation_fault()
);

wire next_valid_op;
pre_decode_t next_decode;
pre_decode_t decoded;

pre_decode pre_decode(
    .clk, .ce(ce_1),
    .q_len(ipq_len),
    .q0(ipq_byte(0)), .q1(ipq_byte(1)), .q2(ipq_byte(2)),
    .valid_op(next_valid_op),
    .decoded(next_decode)
);

alu_operation_e alu_operation;
reg [15:0] alu_ta, alu_tb;
reg alu_execute;
wire alu_busy;
wire [15:0] alu_result;
reg alu_result_wait;

alu ALU(
    .clk, .ce(ce_1|ce_2),

    .reset,

    .operation(alu_operation),
    .ta(alu_ta),
    .tb(alu_tb),
    .result(alu_result),

    .execute(alu_execute),
    .busy(alu_busy)
);

enum {IDLE, FETCH_OPERANDS, START_EXECUTE, STORE_RESULT} state;

int disp_size, imm_size;
reg [15:0] calculated_ea;
reg [15:0] fetched_imm;
reg [15:0] op_result;

always_ff @(posedge clk) begin
    bit [15:0] addr;
    bit [15:0] result16;
    bit [7:0] result8;

    if (reset) begin
        dp_req <= 0;
        reg_ps <= 16'hffff;
        reg_pc <= 16'd0;
        new_pc <= 1;
        state <= IDLE;
        alu_execute <= 0;
        alu_result_wait <= 0;
    end else if (ce_1 | ce_2) begin
        new_pc <= 0;
        alu_execute <= 0;

        if (ce_1) begin
            case(state)
            IDLE: begin
                alu_result_wait <= 0;

                if (next_valid_op) begin
                    decoded <= next_decode;
                    reg_pc <= reg_pc + { 12'd0, next_decode.pre_size };
                    disp_size <= next_decode.calc_ea ? calc_disp_size(next_decode.ea_mem, next_decode.ea_mod) : 0;
                    imm_size <= calc_imm_size(next_decode.source0, next_decode.source1);
                    state <= FETCH_OPERANDS;
                end
            end
            START_EXECUTE: begin
                if (decoded.source_mem == OPERAND_NONE || dp_ready) begin
                    case(decoded.opcode)
                    OP_MOV: begin
                        op_result <= get_operand(decoded.source0);
                        state <= STORE_RESULT;
                    end
                    OP_ALU: begin
                        alu_ta <= get_operand(decoded.source0);
                        alu_tb <= get_operand(decoded.source1);
                        alu_operation <= decoded.alu_operation; // TODO: flags
                        alu_execute <= 1;
                        alu_result_wait <= 1;
                        state <= STORE_RESULT;
                    end
                    endcase
                end
            end
            endcase
        end else if (ce_2) begin
            case(state)
            FETCH_OPERANDS: begin
                if (int'(ipq_len) >= (disp_size + imm_size)) begin
                    fetched_imm[7:0] <= ipq_byte(disp_size);
                    fetched_imm[15:8] <= ipq_byte(disp_size + 1);
                    addr = calc_ea(decoded.ea_mem, decoded.ea_mod, { ipq_byte(1), ipq_byte(0) });
                    calculated_ea <= addr;

                    if (decoded.source_mem == OPERAND_NONE) begin
                        reg_pc <= reg_pc + disp_size[15:0] + imm_size[15:0];
                        state <= START_EXECUTE;
                    end else if (dp_ready) begin
                        dp_addr <= addr;
                        dp_write <= 0;
                        dp_io <= 0; // TODO
                        dp_sreg <= DS0; // TODO
                        dp_wide <= decoded.source_mem == OPERAND_MEM16 ? 1 : 0; // TODO - 32-bit
                        dp_req <= ~dp_req;
                        reg_pc <= reg_pc + disp_size[15:0] + imm_size[15:0];
                        state <= START_EXECUTE;
                    end
                end
            end
            STORE_RESULT: begin
                result8 = alu_result_wait ? alu_result[7:0] : op_result[7:0];
                result16 = alu_result_wait ? alu_result : op_result;

                if (~alu_result_wait | ~alu_busy) begin
                    case(decoded.dest)
                    OPERAND_ACC8: reg_aw[7:0] <= result8;
                    OPERAND_ACC16: reg_aw <= result16;
                    OPERAND_MEM8,
                    OPERAND_MEM16,
                    OPERAND_MEM32: begin
                        dp_addr <= calculated_ea;
                        dp_dout <= result16;
                        dp_write <= 1;
                        dp_io <= 0; // TODO
                        dp_sreg <= DS0; // TODO
                        dp_wide <= decoded.source_mem == OPERAND_MEM16 ? 1 : 0; // TODO - 32-bit
                        dp_req <= ~dp_req;
                    end
                    OPERAND_SREG: begin
                        case(decoded.sreg)
                        DS0: reg_ds0 <= result16;
                        DS1: reg_ds1 <= result16;
                        SS: reg_ss <= result16;
                        PS: reg_ps <= result16;
                        endcase
                    end
                    OPERAND_REG16_0,
                    OPERAND_REG16_1: begin
                        case(reg16_index_e'(decoded.dest == OPERAND_REG16_0 ? decoded.reg0 : decoded.reg1))
                        AW: reg_aw <= result16;
                        BW: reg_bw <= result16;
                        CW: reg_cw <= result16;
                        DW: reg_dw <= result16;
                        SP: reg_sp <= result16;
                        BP: reg_bp <= result16;
                        IX: reg_ix <= result16;
                        IY: reg_iy <= result16;
                        endcase
                    end
                    OPERAND_REG8_0,
                    OPERAND_REG8_1: begin
                        case(reg8_index_e'(decoded.dest == OPERAND_REG8_0 ? decoded.reg0 : decoded.reg1))
                        AL: reg_aw[7:0] <= result8;
                        AH: reg_aw[15:8] <= result8;
                        BL: reg_bw[7:0] <= result8;
                        BH: reg_bw[15:8] <= result8;
                        CL: reg_cw[7:0] <= result8;
                        CH: reg_cw[15:8] <= result8;
                        DL: reg_dw[7:0] <= result8;
                        DH: reg_dw[15:8] <= result8;
                        endcase
                    end
                    endcase
                    state <= IDLE;
                end
            end
            endcase
        end
    end
end
endmodule