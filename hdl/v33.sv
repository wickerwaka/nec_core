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

flags_t flags;
wire [15:0] reg_psw = {
    flags.MD,
    3'b111,
    flags.V,
    flags.DIR,
    flags.IE,
    flags.BRK,
    flags.S,
    flags.Z,
    1'b0,
    flags.AC,
    1'b0,
    flags.P,
    1'b1,
    flags.CY
};

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

wire next_valid_op;
pre_decode_t next_decode;
pre_decode_t decoded;


reg prefix_active;
reg segment_override_active;
sreg_index_e segment_override;

reg repeat_active;

enum { REPEAT_C, REPEAT_NC, REPEAT_Z, REPEAT_NZ } repeat_cond;

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

function sreg_index_e override_segment(sreg_index_e seg);
    if (segment_override_active) return segment_override;
    return seg;
endfunction

task write_memory(input bit [15:0] addr, input sreg_index_e seg, input width_e width, input [15:0] data);
    dp_addr <= addr;
    dp_dout <= data;
    dp_write <= 1;
    dp_io <= 0;
    dp_sreg <= seg;
    dp_wide <= width == BYTE ? 0 : 1;
    dp_req <= ~dp_req;
endtask

task read_memory(input bit [15:0] addr, input sreg_index_e seg, input width_e width);
    dp_addr <= addr;
    dp_write <= 0;
    dp_io <= 0;
    dp_sreg <= seg;
    dp_wide <= width == BYTE ? 0 : 1;
    dp_req <= ~dp_req;
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

    .flags_in(flags),
    .flags(alu_flags_result),

    .execute(alu_execute),
    .busy(alu_busy)
);

enum {IDLE, FETCH_OPERANDS, FETCH_OPERANDS2, PUSH, POP, POP_WAIT, EXECUTE, STORE_RESULT} state;

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

        prefix_active <= 0;
        segment_override_active <= 0;
        repeat_active <= 0;
        repeat_cond <= REPEAT_Z;
    end else if (ce_1 | ce_2) begin
        alu_execute <= 0;

        case(state)
            IDLE: if (ce_1) begin
                alu_result_wait <= 0;
                new_pc <= 0; // TODO - should this be every CE?

                // If prefixes are active and the _last_ op was not a prefix, then end it
                if (prefix_active & ~decoded.prefix) begin
                    prefix_active <= 0;
                    segment_override_active <= 0;
                    repeat_active <= 0;
                end

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
            end // IDLE

            EXECUTE: begin
                bit working = 0;
                if (dp_ready) begin
                    exec_stage <= exec_stage + 4'd1;

                    case(decoded.opcode)
                        OP_NOP: begin
                        end

                        OP_MOV: begin
                            op_result <= get_operand(decoded.source0);
                        end

                        OP_ALU: begin
                            alu_ta <= get_operand(decoded.source0);
                            alu_tb <= get_operand(decoded.source1);
                            alu_operation <= decoded.alu_operation; // TODO: flags
                            alu_execute <= 1;
                            alu_result_wait <= 1;
                            alu_wide <= decoded.width == WORD ? 1 : 0;
                        end

                        OP_B_COND: begin
                            bit cond = 0;
                            case(decoded.cond)
                            4'b0000: cond = flags.V; /* V */
                            4'b0001: cond = ~flags.V; /* NV */
                            4'b0010: cond = flags.CY; /* C/L */
                            4'b0011: cond = ~flags.CY; /* NC/NL */
                            4'b0100: cond = flags.Z; /* E/Z */
                            4'b0101: cond = ~flags.Z; /* NE/NZ */
                            4'b0110: cond = (flags.CY | flags.Z); /* NH */
                            4'b0111: cond = ~(flags.CY | flags.Z); /* H */
                            4'b1000: cond = flags.S; /* N */
                            4'b1001: cond = ~flags.S; /* P */
                            4'b1010: cond = flags.P; /* PE */
                            4'b1011: cond = ~flags.P; /* PO */
                            4'b1100: cond = (flags.S ^ flags.V); /* LT */
                            4'b1101: cond = ~(flags.S ^ flags.V); /* GE */
                            4'b1110: cond = (flags.S ^ flags.V); /* LE */
                            4'b1111: cond = ~((flags.S ^ flags.V) | flags.Z); /* GT */
                            endcase

                            if (cond) begin
                                reg_pc <= reg_pc + get_operand(decoded.source0);
                                new_pc <= 1;
                            end
                        end

                        OP_B_CW_COND: begin
                            bit cond = 0;
                            case(decoded.cond)
                            4'b0000: begin
                                reg_cw <= reg_cw - 16'd1;
                                cond = reg_cw != 16'd1 && ~flags.Z;
                            end
                            4'b0001: begin
                                reg_cw <= reg_cw - 16'd1;
                                cond = reg_cw != 16'd1 && flags.Z;
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
                        end

                        OP_BR_REL: begin
                            reg_pc <= reg_pc + get_operand(decoded.source0);
                            new_pc <= 1;
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
                        end

                        OP_POP_VALUE: begin
                            reg_sp <= reg_sp + get_operand(decoded.source0);
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
                                working = 1;
                            end else begin
                                if (decoded.width == BYTE)
                                    set_reg8(AL, dp_din[7:0]);
                                else
                                    set_reg16(AW, dp_din);
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

                        OP_SEG_PREFIX: begin
                            segment_override <= sreg_index_e'(decoded.sreg);
                            segment_override_active <= 1;
                            prefix_active <= 1;
                        end

                        OP_REP_PREFIX: begin
                            repeat_active <= 1;
                            prefix_active <= 1;
                            case (decoded.opcode_byte[1:0])
                                2'b00: repeat_cond <= REPEAT_NC;
                                2'b01: repeat_cond <= REPEAT_C;
                                2'b10: repeat_cond <= REPEAT_NZ;
                                2'b11: repeat_cond <= REPEAT_Z;
                            endcase
                        end

                        OP_STM: begin
                            bit do_work = 1;
                            if (repeat_active) begin
                                if (reg_cw == 16'd0) begin
                                    do_work = 0;
                                end else begin
                                    reg_cw <= reg_cw - 16'd1;
                                    working = reg_cw == 16'd1 ? 0 : 1;
                                end
                            end

                            if (do_work) begin
                                write_memory(reg_iy, DS1, decoded.width, reg_aw);
                                if (flags.DIR)
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                else
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                            end
                        end

                        OP_LDM: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (repeat_active) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, override_segment(DS0), decoded.width);
                                    working = 1;
                                end
                            end else begin
                                if (decoded.width == BYTE)
                                    reg_aw[7:0] <= dp_din[7:0];
                                else
                                    reg_aw <= dp_din;

                                if (flags.DIR) begin
                                    reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                                exec_stage <= 0;

                                if (repeat_active) working = reg_cw != 16'd0;
                            end
                        end

                        OP_MOVBK: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (repeat_active) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, override_segment(DS0), decoded.width);
                                    working = 1;
                                end
                            end else begin
                                write_memory(reg_iy, DS1, decoded.width, dp_din);
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                                exec_stage <= 0;

                                if (repeat_active) working = reg_cw != 16'd0;
                            end
                        end
                        OP_CMPBK: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (repeat_active) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, override_segment(DS0), decoded.width);
                                    working = 1;
                                end
                            end else if (exec_stage == 1) begin
                                alu_ta <= dp_din;
                                read_memory(reg_iy, DS1, decoded.width);
                                working = 1;
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                            end else if (exec_stage == 2) begin
                                alu_tb <= dp_din;
                                alu_operation <= ALU_OP_CMP;
                                alu_wide <= decoded.width == WORD ? 1 : 0;
                                alu_execute <= 1;
                                working = 1;
                            end else if (exec_stage == 3) begin
                                working = 1;
                                if (alu_busy) begin
                                    exec_stage <= exec_stage; // wait
                                end else begin
                                    flags <= alu_flags_result;
                                    exec_stage <= 0;
                                    if (repeat_active) begin
                                        if (reg_cw == 16'd0) working = 0;
                                        else if (repeat_cond == REPEAT_NZ) working = ~alu_flags_result.Z;
                                        else if (repeat_cond == REPEAT_Z) working = alu_flags_result.Z;
                                        else if (repeat_cond == REPEAT_NC) working = ~alu_flags_result.CY;
                                        else if (repeat_cond == REPEAT_C) working = alu_flags_result.CY;
                                    end else begin
                                        working = 0;
                                    end
                                end
                            end
                        end

                        OP_CMPM: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (repeat_active) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_iy, DS1, decoded.width);
                                    working = 1;
                                end
                            end else if (exec_stage == 1) begin
                                alu_ta <= reg_aw;
                                alu_tb <= dp_din;
                                alu_operation <= ALU_OP_CMP;
                                alu_wide <= decoded.width == WORD ? 1 : 0;
                                alu_execute <= 1;
                                working = 1;
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                            end else if (exec_stage == 2) begin
                                working = 1;
                                if (alu_busy) begin
                                    exec_stage <= exec_stage; // wait
                                end else begin
                                    flags <= alu_flags_result;
                                    exec_stage <= 0;
                                    if (repeat_active) begin
                                        if (reg_cw == 16'd0) working = 0;
                                        else if (repeat_cond == REPEAT_NZ) working = ~alu_flags_result.Z;
                                        else if (repeat_cond == REPEAT_Z) working = alu_flags_result.Z;
                                        else if (repeat_cond == REPEAT_NC) working = ~alu_flags_result.CY;
                                        else if (repeat_cond == REPEAT_C) working = alu_flags_result.CY;
                                    end else begin
                                        working = 0;
                                    end
                                end
                            end
                        end
                    endcase

                    if (~working) begin
                        if (decoded.dest == OPERAND_NONE) begin
                            state <= IDLE;
                        end else begin
                            state <= STORE_RESULT;
                        end
                    end
                end
            end // EXECUTE

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
                    4:  reg_sp <= dp_din;
                    5:  reg_bp <= dp_din;
                    6:  reg_ix <= dp_din;
                    7:  reg_iy <= dp_din;
                    8:  reg_ds1 <= dp_din;
                    9:  begin
                        flags.CY  <= dp_din[0];
                        flags.P   <= dp_din[2];
                        flags.AC  <= dp_din[4];
                        flags.Z   <= dp_din[6];
                        flags.S   <= dp_din[7];
                        flags.BRK <= dp_din[8];
                        flags.IE  <= dp_din[9];
                        flags.DIR <= dp_din[10];
                        flags.V   <= dp_din[11];
                        flags.MD  <= dp_din[15];
                    end
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
                            write_memory(calculated_ea, override_segment(DS0), WORD, dp_din);
                        end
                    end
                    endcase

                    pop_list[pop_idx] <= 0;

                    if (pop_idx == last_pop_idx) begin
                        if (decoded.opcode == OP_NOP) begin
                            state <= IDLE;
                        end else begin
                            state <= EXECUTE;
                        end
                    end else begin
                        state <= POP;
                    end
                end
            end // POP_WAIT

            FETCH_OPERANDS: if (ce_2) begin
                if (int'(ipq_len) >= (disp_size + imm_size)) begin
                    fetched_imm[7:0] <= ipq_byte(disp_size);
                    fetched_imm[15:8] <= ipq_byte(disp_size + 1);
                    fetched_imm[23:16] <= ipq_byte(disp_size + 2);
                    fetched_imm[31:24] <= ipq_byte(disp_size + 3);
                    addr = calc_ea(decoded.rm, decoded.mod, { ipq_byte(1), ipq_byte(0) });
                    calculated_ea <= addr;

                    if (dp_ready & mem_read) begin
                        read_memory(addr, override_segment(DS0), decoded.width);
                        reg_pc <= reg_pc + disp_size[15:0] + imm_size[15:0];
                        if (decoded.width == DWORD) begin
                            state <= FETCH_OPERANDS2;
                        end else begin
                            if (push_list != 16'd0)
                                state <= PUSH;
                            else if (pop_list != 16'd0)
                                state <= POP;
                            else
                                state <= EXECUTE;
                        end
                    end else if (~mem_read) begin
                        reg_pc <= reg_pc + disp_size[15:0] + imm_size[15:0];
                        if (push_list != 16'd0)
                            state <= PUSH;
                        else if (pop_list != 16'd0)
                            state <= POP;
                        else
                            state <= EXECUTE;
                    end
                end
            end // FETCH_OPERANDS

            FETCH_OPERANDS2: if (ce_2) begin
                if (dp_ready) begin
                    dp_din_low <= dp_din;

                    read_memory(calculated_ea + 16'd2, override_segment(DS0), WORD);
                    if (push_list != 16'd0)
                        state <= PUSH;
                    else if (pop_list != 16'd0)
                        state <= POP;
                    else
                        state <= EXECUTE;
                end
            end // FETCH_OPERANDS2

            PUSH: if (ce_2) begin
                bit [15:0] push_data;
                if (dp_ready) begin
                    int push_idx = 0;
                    for (int i = 14; i >= 0; i = i - 1) begin
                        if (push_list[i]) push_idx = i;
                    end

                    reg_sp <= reg_sp - 16'd2;

                    case(push_idx)
                    0:  push_data = reg_aw;
                    1:  push_data = reg_cw;
                    2:  push_data = reg_dw;
                    3:  push_data = reg_bw;
                    4:  push_data = push_sp_save;
                    5:  push_data = reg_bp;
                    6:  push_data = reg_ix;
                    7:  push_data = reg_iy;
                    8:  push_data = reg_ds1;
                    9:  push_data = reg_psw;
                    10: push_data = reg_ps;
                    11: push_data = reg_ss;
                    12: push_data = reg_ds0;
                    13: push_data = reg_pc;
                    14: push_data = get_operand(decoded.source0);
                    endcase

                    write_memory(reg_sp - 16'd2, SS, WORD, push_data);

                    push_list[push_idx] <= 0;

                    if (push_idx == last_push_idx) begin
                        if (decoded.opcode == OP_NOP) begin
                            state <= IDLE;
                        end else begin
                            state <= EXECUTE;
                        end
                    end 
                end
            end // PUSH

            POP: if (ce_2) begin
                if (dp_ready) begin
                    int pop_idx = 0;
                    for (int i = 0; i < 15; i = i + 1) begin
                        if (pop_list[i]) pop_idx = i;
                    end

                    read_memory(reg_sp, SS, WORD);
                    reg_sp <= reg_sp + 16'd2;

                    state <= POP_WAIT;
                end
            end // POP

            STORE_RESULT: if (ce_2) begin
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
                            write_memory(calculated_ea, override_segment(DS0), decoded.width, result16);
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

                    if (alu_result_wait) flags <= alu_flags_result;
                    state <= IDLE;
                end
            end // STORE_RESULT
        endcase
    end
end
endmodule