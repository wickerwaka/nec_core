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

flags_t reg_psw;

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

reg [15:0] dp_din_low; // for 32-bit reads
wire [31:0] dp_din32 = { dp_din, dp_din_low };

// Instruction prefetch
reg new_pc;

wire [7:0] ipq[8];
wire [3:0] ipq_len;

function bit [7:0] ipq_byte(int ofs);
    return ipq[reg_pc[2:0] + ofs[2:0]];
endfunction

// bleh, something better here?
function int calc_imm_size(width_e width, operand_e s0, operand_e s1);
    case(s0)
    OPERAND_IMM: return width == DWORD ? 4 : width == WORD ? 2 : 1;
    OPERAND_IMM8: return 1;
    OPERAND_IMM_EXT: return 1;
    endcase

    case(s1)
    OPERAND_IMM: return width == DWORD ? 4 : width == WORD ? 2 : 1;
    OPERAND_IMM8: return 1;
    OPERAND_IMM_EXT: return 1;
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

task set_reg8(input reg8_index_e r, input bit[7:0] val);
    case(r)
    AL: reg_aw[7:0]  <= val;
    AH: reg_aw[15:8] <= val;
    BL: reg_bw[7:0]  <= val;
    BH: reg_bw[15:8] <= val;
    CL: reg_cw[7:0]  <= val;
    CH: reg_cw[15:8] <= val;
    DL: reg_dw[7:0]  <= val;
    DH: reg_dw[15:8] <= val;
    endcase
endtask

task set_reg16(input reg16_index_e r, input bit[15:0] val);
    case(r)
    AW: reg_aw <= val;
    BW: reg_bw <= val;
    CW: reg_cw <= val;
    DW: reg_dw <= val;
    SP: reg_sp <= val;
    BP: reg_bp <= val;
    IX: reg_ix <= val;
    IY: reg_iy <= val;
    endcase
endtask

function bit [15:0] get_operand(operand_e operand);
    if (decoded.width == BYTE) begin
        case(operand)
        OPERAND_ACC: return { 8'd0, reg_aw[7:0] };
        OPERAND_IMM: return { 8'd0, fetched_imm[7:0] };
        OPERAND_IMM8: return { 8'd0, fetched_imm[7:0] };
        OPERAND_IMM_EXT: return { {8{fetched_imm[7]}}, fetched_imm[7:0] };
        OPERAND_MODRM: begin
            if (decoded.mod == 2'b11)
                return { 8'd0, get_reg8(reg8_index_e'(decoded.rm)) };
            else
                return { 8'd0, dp_din[7:0] };
        end
        OPERAND_REG_0: return { 8'd0, get_reg8(reg8_index_e'(decoded.reg0)) };
        OPERAND_REG_1: return { 8'd0, get_reg8(reg8_index_e'(decoded.reg1)) };
        endcase
    end else if (decoded.width == WORD) begin
        case(operand)
        OPERAND_ACC: return reg_aw;
        OPERAND_IMM: return fetched_imm[15:0];
        OPERAND_IMM8: return { 8'd0, fetched_imm[7:0] };
        OPERAND_IMM_EXT: return { {8{fetched_imm[7]}}, fetched_imm[7:0] };
        OPERAND_MODRM: begin
            if (decoded.mod == 2'b11)
                return get_reg16(reg16_index_e'(decoded.rm));
            else
                return dp_din;
        end
        OPERAND_SREG: begin
            case(decoded.sreg)
            DS0: return reg_ds0;
            DS1: return reg_ds1;
            SS: return reg_ss;
            PS: return reg_ps;
            endcase
        end
        OPERAND_REG_0: return get_reg16(reg16_index_e'(decoded.reg0));
        OPERAND_REG_1: return get_reg16(reg16_index_e'(decoded.reg1));
        endcase
    end
    return 16'hfefe;
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
    .clk, .ce(ce_1 | ce_2),
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
flags_t alu_flags_result;
reg alu_result_wait;
reg alu_wide;

alu ALU(
    .clk, .ce(ce_1|ce_2),

    .reset,

    .operation(alu_operation),
    .ta(alu_ta),
    .tb(alu_tb),
    .result(alu_result),
    .wide(alu_wide),

    .flags_in(reg_psw),
    .flags(alu_flags_result),

    .execute(alu_execute),
    .busy(alu_busy)
);

enum {IDLE, FETCH_OPERANDS, FETCH_OPERANDS2, PUSH, POP, POP_WAIT, START_EXECUTE, STORE_RESULT} state;

int disp_size, imm_size;
reg io_read, mem_read;
reg [15:0] calculated_ea;
reg [31:0] fetched_imm;
reg [15:0] op_result;

reg [3:0] exec_stage;

int last_push_idx, last_pop_idx;
reg [15:0] push_list;
reg [15:0] pop_list;
reg [15:0] push_sp_save;

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
        alu_execute <= 0;

        if (ce_1) begin
            case(state)
            IDLE: begin
                alu_result_wait <= 0;
                new_pc <= 0; // TODO - should this be every CE?

                if (next_valid_op & ~new_pc) begin
                    disp_size <= 0;
                    mem_read <= 0;
                    exec_stage <= 4'd0;

                    push_sp_save <= reg_sp;
                    push_list <= next_decode.push;
                    pop_list <= next_decode.pop;

                    for (int i = 14; i >= 0; i = i - 1) begin
                        if (next_decode.pop[i]) last_pop_idx <= i;
                    end

                    for (int i = 0; i < 15; i = i + 1) begin
                        if (next_decode.push[i]) last_push_idx <= i;
                    end

                    decoded <= next_decode;
                    reg_pc <= reg_pc + { 12'd0, next_decode.pre_size };
                    if (next_decode.use_modrm & next_decode.mod != 2'b11) begin
                        disp_size <= calc_disp_size(next_decode.rm, next_decode.mod);
                        mem_read <= (next_decode.source0 == OPERAND_MODRM || next_decode.source1 == OPERAND_MODRM) ? 1 : 0;
                    end

                    imm_size <= calc_imm_size(next_decode.width, next_decode.source0, next_decode.source1);
                    state <= FETCH_OPERANDS;
                end
            end
            START_EXECUTE: begin
                if (dp_ready) begin
                    exec_stage <= exec_stage + 4'd1;

                    case(decoded.opcode)
                    OP_NOP: begin
                        state <= IDLE;
                    end
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
                        alu_wide <= decoded.width == WORD ? 1 : 0;
                        state <= STORE_RESULT;
                    end
                    OP_B_COND: begin
                        bit cond = 0;
                        case(decoded.cond)
                        4'b0000: cond = reg_psw.V; /* V */
                        4'b0001: cond = ~reg_psw.V; /* NV */
                        4'b0010: cond = reg_psw.CY; /* C/L */
                        4'b0011: cond = ~reg_psw.CY; /* NC/NL */
                        4'b0100: cond = reg_psw.Z; /* E/Z */
                        4'b0101: cond = ~reg_psw.Z; /* NE/NZ */
                        4'b0110: cond = (reg_psw.CY | reg_psw.Z); /* NH */
                        4'b0111: cond = ~(reg_psw.CY | reg_psw.Z); /* H */
                        4'b1000: cond = reg_psw.S; /* N */
                        4'b1001: cond = ~reg_psw.S; /* P */
                        4'b1010: cond = reg_psw.P; /* PE */
                        4'b1011: cond = ~reg_psw.P; /* PO */
                        4'b1100: cond = (reg_psw.S ^ reg_psw.V); /* LT */
                        4'b1101: cond = ~(reg_psw.S ^ reg_psw.V); /* GE */
                        4'b1110: cond = (reg_psw.S ^ reg_psw.V); /* LE */
                        4'b1111: cond = ~((reg_psw.S ^ reg_psw.V) | reg_psw.Z); /* GT */
                        endcase

                        if (cond) begin
                            reg_pc <= reg_pc + get_operand(decoded.source0);
                            new_pc <= 1;
                        end

                        state <= IDLE;
                    end
                    OP_B_CW_COND: begin
                        bit cond = 0;
                        case(decoded.cond)
                        4'b0000: begin
                            reg_cw <= reg_cw - 16'd1;
                            cond = reg_cw != 16'd1 && ~reg_psw.Z;
                        end
                        4'b0001: begin
                            reg_cw <= reg_cw - 16'd1;
                            cond = reg_cw != 16'd1 && reg_psw.Z;
                        end
                        4'b0010: begin
                            reg_cw <= reg_cw - 16'd1;
                            cond = reg_cw != 16'd1;
                        end
                        4'b0011: cond = (reg_cw == 0);
                        default: begin
                        end
                        endcase

                        if (cond) begin
                            reg_pc <= reg_pc + get_operand(decoded.source0);
                            new_pc <= 1;
                        end

                        state <= IDLE;
                    end
                    OP_BR_REL: begin
                        reg_pc <= reg_pc + get_operand(decoded.source0);
                        new_pc <= 1;
                        state <= IDLE;
                    end
                    OP_BR_ABS: begin
                        if (decoded.source0 == OPERAND_IMM && decoded.width == DWORD) begin
                            reg_pc <= fetched_imm[15:0];
                            reg_ps <= fetched_imm[31:16];
                            new_pc <= 1;
                        end else if (decoded.width == WORD) begin
                            reg_pc <= get_operand(decoded.source0);
                            new_pc <= 1;
                        end else if (decoded.source0 == OPERAND_MODRM && decoded.width == DWORD) begin
                            reg_pc <= dp_din32[15:0];
                            reg_ps <= dp_din32[31:16];
                            new_pc <= 1;
                        end
                        state <= IDLE;
                    end
                    OP_POP_VALUE: begin
                        reg_sp <= reg_sp + get_operand(decoded.source0);
                        state <= IDLE;
                    end
                    OP_IN: begin
                        if (exec_stage == 0) begin
                            dp_write <= 0;
                            dp_io <= 1;
                            dp_wide <= decoded.width == WORD ? 1 : 0;
                            if (decoded.source0 == OPERAND_IMM8) begin
                                dp_addr <= { 8'd0, fetched_imm[7:0] };
                            end else begin
                                dp_addr <= reg_dw;
                            end
                            dp_req <= ~dp_req;
                        end else begin
                            if (decoded.width == BYTE)
                                set_reg8(AL, dp_din[7:0]);
                            else
                                set_reg16(AW, dp_din);
                            state <= IDLE;
                        end
                    end
                    OP_OUT: begin
                        dp_write <= 1;
                        dp_io <= 1;
                        dp_wide <= decoded.width == WORD ? 1 : 0;
                        dp_dout <= reg_aw;
                        if (decoded.source0 == OPERAND_IMM8) begin
                            dp_addr <= { 8'd0, fetched_imm[7:0] };
                        end else begin
                            dp_addr <= reg_dw;
                        end
                        dp_req <= ~dp_req;
                    end


                    endcase
                end
            end
            POP_WAIT: begin
                if (dp_ready) begin
                    int pop_idx = 0;
                    for (int i = 0; i < 15; i = i + 1) begin
                        if (pop_list[i]) pop_idx = i;
                    end

                    case(pop_idx)
                    0:  reg_aw <= dp_din;
                    1:  reg_cw <= dp_din;
                    2:  reg_dw <= dp_din;
                    3:  reg_bw <= dp_din;
                    4:  reg_sp <= dp_din; // TODO, right value?
                    5:  reg_bp <= dp_din;
                    6:  reg_ix <= dp_din;
                    7:  reg_iy <= dp_din;
                    8:  reg_ds1 <= dp_din;
                    9:  begin end // reg_psw <= dp_din; // TODO
                    10: begin
                        reg_ps <= dp_din;
                        new_pc <= 1;
                    end
                    11: reg_ss <= dp_din;
                    12: reg_ds0 <= dp_din;
                    13: begin
                        reg_pc <= dp_din;
                        new_pc <= 1;
                    end
                    14: begin
                        if (decoded.mod == 2'b11) begin
                            set_reg16(reg16_index_e'(decoded.rm), dp_din);
                        end else begin
                            dp_addr <= calculated_ea;
                            dp_dout <= dp_din;
                            dp_write <= 1;
                            dp_io <= 0;
                            dp_sreg <= DS0; // TODO
                            dp_wide <= 1;
                            dp_req <= ~dp_req;
                        end
                    end
                    endcase

                    pop_list[pop_idx] <= 0;

                    if (pop_idx == last_pop_idx) begin
                        if (decoded.opcode == OP_NOP) begin
                            state <= IDLE;
                        end else begin
                            state <= START_EXECUTE;
                        end
                    end else begin
                        state <= POP;
                    end
                end
            end

            endcase
        end else if (ce_2) begin
            case(state)
            FETCH_OPERANDS: begin
                if (int'(ipq_len) >= (disp_size + imm_size)) begin
                    fetched_imm[7:0] <= ipq_byte(disp_size);
                    fetched_imm[15:8] <= ipq_byte(disp_size + 1);
                    fetched_imm[23:16] <= ipq_byte(disp_size + 2);
                    fetched_imm[31:24] <= ipq_byte(disp_size + 3);
                    addr = calc_ea(decoded.rm, decoded.mod, { ipq_byte(1), ipq_byte(0) });
                    calculated_ea <= addr;

                    if (dp_ready & mem_read) begin
                        dp_addr <= addr;
                        dp_write <= 0;
                        dp_io <= 0;
                        dp_sreg <= DS0; // TODO
                        dp_wide <= decoded.width == BYTE ? 0 : 1;
                        dp_req <= ~dp_req;
                        reg_pc <= reg_pc + disp_size[15:0] + imm_size[15:0];
                        if (decoded.width == DWORD) begin
                            state <= FETCH_OPERANDS2;
                        end else begin
                        if (push_list != 16'd0)
                            state <= PUSH;
                        else if (pop_list != 16'd0)
                            state <= POP;
                        else
                            state <= START_EXECUTE;                        end
                    end else if (~mem_read) begin
                        reg_pc <= reg_pc + disp_size[15:0] + imm_size[15:0];
                        if (push_list != 16'd0)
                            state <= PUSH;
                        else if (pop_list != 16'd0)
                            state <= POP;
                        else
                            state <= START_EXECUTE;
                    end
                end
            end
            FETCH_OPERANDS2: begin
                if (dp_ready) begin
                    dp_din_low <= dp_din;

                    dp_addr <= calculated_ea + 16'd2;
                    dp_write <= 0;
                    dp_io <= 0;
                    dp_sreg <= DS0; // TODO
                    dp_wide <= 1;
                    dp_req <= ~dp_req;
                    if (push_list != 16'd0)
                        state <= PUSH;
                    else if (pop_list != 16'd0)
                        state <= POP;
                    else
                        state <= START_EXECUTE;
                end
            end

            PUSH: begin
                if (dp_ready) begin
                    int push_idx = 0;
                    for (int i = 14; i >= 0; i = i - 1) begin
                        if (push_list[i]) push_idx = i;
                    end

                    dp_addr <= reg_sp - 16'd2;
                    reg_sp <= reg_sp - 16'd2;
                    dp_write <= 1;
                    dp_io <= 0;
                    dp_sreg <= SS;
                    dp_wide <= 1;
                    dp_req <= ~dp_req;

                    case(push_idx)
                    0:  dp_dout <= reg_aw;
                    1:  dp_dout <= reg_cw;
                    2:  dp_dout <= reg_dw;
                    3:  dp_dout <= reg_bw;
                    4:  dp_dout <= push_sp_save;
                    5:  dp_dout <= reg_bp;
                    6:  dp_dout <= reg_ix;
                    7:  dp_dout <= reg_iy;
                    8:  dp_dout <= reg_ds1;
                    9:  dp_dout <= 0; // reg_psw; // TODO
                    10: dp_dout <= reg_ps;
                    11: dp_dout <= reg_ss;
                    12: dp_dout <= reg_ds0;
                    13: dp_dout <= reg_pc;
                    14: dp_dout <= get_operand(decoded.source0);
                    endcase

                    push_list[push_idx] <= 0;

                    if (push_idx == last_push_idx) begin
                        if (decoded.opcode == OP_NOP) begin
                            state <= IDLE;
                        end else begin
                            state <= START_EXECUTE;
                        end
                    end 
                end
            end

            POP: begin
                if (dp_ready) begin
                    int pop_idx = 0;
                    for (int i = 0; i < 15; i = i + 1) begin
                        if (pop_list[i]) pop_idx = i;
                    end

                    dp_addr <= reg_sp;
                    reg_sp <= reg_sp + 16'd2;
                    dp_write <= 0;
                    dp_io <= 0;
                    dp_sreg <= SS;
                    dp_wide <= 1;
                    dp_req <= ~dp_req;

                    state <= POP_WAIT;
                end
            end

            STORE_RESULT: begin
                result8 = alu_result_wait ? alu_result[7:0] : op_result[7:0];
                result16 = alu_result_wait ? alu_result : op_result;

                // TODO, do we need to wait for dp_ready here? should it be more focused on just the writing case?
                if (dp_ready & (~alu_result_wait | ~alu_busy)) begin
                    case(decoded.dest)
                    OPERAND_ACC: begin
                        if (decoded.width == BYTE)
                            reg_aw[7:0] <= result8;
                        else
                            reg_aw <= result16;
                    end
                    OPERAND_MODRM: begin
                        if (decoded.mod == 2'b11) begin
                            if (decoded.width == BYTE)
                                set_reg8(reg8_index_e'(decoded.rm), result8);
                            else
                                set_reg16(reg16_index_e'(decoded.rm), result16);
                        end else begin
                            dp_addr <= calculated_ea;
                            dp_dout <= result16;
                            dp_write <= 1;
                            dp_io <= 0;
                            dp_sreg <= DS0; // TODO
                            dp_wide <= decoded.width == WORD ? 1 : 0; // TODO - 32-bit
                            dp_req <= ~dp_req;
                        end
                    end
                    OPERAND_SREG: begin
                        case(decoded.sreg)
                        DS0: reg_ds0 <= result16;
                        DS1: reg_ds1 <= result16;
                        SS: reg_ss <= result16;
                        PS: begin
                            reg_ps <= result16;
                            new_pc <= 1;
                        end
                        endcase
                    end
                    OPERAND_REG_0: begin
                        if (decoded.width == BYTE)
                            set_reg8(reg8_index_e'(decoded.reg0), result8);
                        else
                            set_reg16(reg16_index_e'(decoded.reg0), result16);
                    end
                    OPERAND_REG_1: begin
                        if (decoded.width == BYTE)
                            set_reg8(reg8_index_e'(decoded.reg1), result8);
                        else
                            set_reg16(reg16_index_e'(decoded.reg1), result16);
                    end
                    endcase

                    if (alu_result_wait) reg_psw <= alu_flags_result;
                    state <= IDLE;
                end
            end
            endcase
        end
    end
end
endmodule