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
    input       [15:0]  din,

    // Non-hardware
    input               turbo
);

// Register file
// Segment registers
reg [15:0] reg_ds0 /*verilator public*/;
reg [15:0] reg_ds1 /*verilator public*/;
reg [15:0] reg_ss  /*verilator public*/;
reg [15:0] reg_ps  /*verilator public*/;

// General purpose
reg [15:0] reg_aw  /*verilator public*/;
reg [15:0] reg_bw  /*verilator public*/;
reg [15:0] reg_cw  /*verilator public*/;
reg [15:0] reg_dw  /*verilator public*/;
reg [15:0] reg_sp  /*verilator public*/;
reg [15:0] reg_bp  /*verilator public*/;
reg [15:0] reg_ix  /*verilator public*/;
reg [15:0] reg_iy  /*verilator public*/;

wire [15:0] cur_pc  /*verilator public*/;

reg halt /*verilator public*/; // TODO, do something with this

flags_t flags;
wire [15:0] reg_psw /*verilator public*/ = {
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
reg dp_zero_seg;
reg dp_write;
reg dp_wide;
reg dp_io;
reg dp_req;
wire dp_ready;

reg [15:0] dp_din_low; // for 32-bit reads
wire [31:0] dp_din32 = { dp_din, dp_din_low };

// Instruction prefetch
reg [15:0] next_pc /*verilator public*/;
reg set_pc /*verilator public*/;

wire [7:0] ipq[8];
wire [3:0] ipq_len;

nec_decode_t next_decode;
nec_decode_t decoded /*verilator public*/;

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

    if (mod == 2'b01) addr = addr + { {8{disp[7]}}, disp[7:0] };
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

task set_sreg(input sreg_index_e r, input bit[15:0] val);
    case(r)
    DS0: reg_ds0 <= val;
    DS1: reg_ds1 <= val;
    SS: reg_ss <= val;
    PS: begin
        reg_ps <= val;
        next_pc <= decoded.end_pc;
        set_pc <= 1;
    end
    endcase
endtask

task write_memory(input bit [15:0] addr, input sreg_index_e seg, input width_e width, input [15:0] data);
    dp_addr <= addr;
    dp_dout <= data;
    dp_write <= 1;
    dp_io <= 0;
    dp_zero_seg <= 0;
    dp_sreg <= seg;
    dp_wide <= width == BYTE ? 0 : 1;
    dp_req <= 1;
endtask

task read_memory(input bit [15:0] addr, input sreg_index_e seg, input width_e width);
    dp_addr <= addr;
    dp_write <= 0;
    dp_io <= 0;
    dp_sreg <= seg;
    dp_zero_seg <= 0;
    dp_wide <= width == BYTE ? 0 : 1;
    dp_req <= 1;
endtask

task start_alu(input bit [15:0] ta, input bit [15:0] tb, input alu_operation_e op, width_e width);
    alu_ta <= ta;
    alu_tb <= tb;
    alu_operation <= op;
    alu_wide <= width == WORD ? 1 : 0;
endtask

function bit [15:0] get_operand(operand_e operand);
    if (decoded.width == BYTE) begin
        case(operand)
        OPERAND_ACC: return { 8'd0, reg_aw[7:0] };
        OPERAND_IMM: return { 8'd0, decoded.imm[7:0] };
        OPERAND_IMM8: return { 8'd0, decoded.imm[7:0] };
        OPERAND_IMM_EXT: return { {8{decoded.imm[7]}}, decoded.imm[7:0] };
        OPERAND_MODRM: begin
            if (decoded.mod == 2'b11)
                return { 8'd0, get_reg8(reg8_index_e'(decoded.rm)) };
            else
                return { 8'd0, dp_din[7:0] };
        end
        OPERAND_REG_0: return { 8'd0, get_reg8(reg8_index_e'(decoded.reg0)) };
        OPERAND_REG_1: return { 8'd0, get_reg8(reg8_index_e'(decoded.reg1)) };
        OPERAND_CL: return { 8'd0, reg_cw[7:0] };
        default: return 16'hffff;
        endcase
    end else if (decoded.width == WORD) begin
        case(operand)
        OPERAND_ACC: return reg_aw;
        OPERAND_IMM: return decoded.imm[15:0];
        OPERAND_IMM8: return { 8'd0, decoded.imm[7:0] };
        OPERAND_IMM_EXT: return { {8{decoded.imm[7]}}, decoded.imm[7:0] };
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
        OPERAND_CL: return { 8'd0, reg_cw[7:0] };
        default: return 16'hffff;
        endcase
    end
    return 16'hfefe;
endfunction


function alu_operation_e shift_alu_op(bit [2:0] shift);
    case(shift)
    3'b000: return ALU_OP_ROL;
    3'b001: return ALU_OP_ROR;
    3'b010: return ALU_OP_ROLC;
    3'b011: return ALU_OP_RORC;
    3'b100: return ALU_OP_SHL;
    3'b101: return ALU_OP_SHR;
    3'b110: return ALU_OP_NONE;
    3'b111: return ALU_OP_SHRA;
    endcase
endfunction

function alu_operation_e shift1_alu_op(bit [2:0] shift);
    case(shift)
    3'b000: return ALU_OP_ROL1;
    3'b001: return ALU_OP_ROR1;
    3'b010: return ALU_OP_ROLC1;
    3'b011: return ALU_OP_RORC1;
    3'b100: return ALU_OP_SHL1;
    3'b101: return ALU_OP_SHR1;
    3'b110: return ALU_OP_NONE;
    3'b111: return ALU_OP_SHRA1;
    endcase
endfunction

reg [7:0] interrupt_vector;
wire bcu_intreq;
wire bcu_intack;
wire [7:0] bcu_intvec;

bus_control_unit BCU(
    .clk, .ce_1, .ce_2,
    .reset, .hldrq, .n_ready, .bs16,
    .hldak, .n_buslock, .n_ube, .r_w,
    .m_io, .busst0, .busst1, .aex,
    .n_bcyst, .n_dstb,
    .addr, .dout, .din,

    .reg_ps, .reg_ss, .reg_ds0, .reg_ds1,

    .pfp_set(set_pc),
    .ipq, .ipq_head(set_pc ? next_pc : cur_pc), .ipq_len,

    .dp_addr, .dp_dout, .dp_din, .dp_sreg,
    .dp_write, .dp_wide, .dp_io, .dp_req,
    .dp_ready, .dp_zero_seg,

    .buslock_prefix(decoded.buslock),

    .intreq(bcu_intreq), .intack(bcu_intack), .intvec(bcu_intvec),

    .implementation_fault()
);

reg read_decode;
wire next_decode_valid;
wire decode_busy;
wire decode_consume = state == IDLE;

nec_decode nec_decode(
    .clk, .ce(ce_1 | ce_2),
    .ipq_len,
    .ipq,
    .new_pc(next_pc), .set_pc,
    .pc(cur_pc),
    .read_decode(read_decode),
    .consume(decode_consume),
    .valid(next_decode_valid),
    .busy(decode_busy),
    .decoded(next_decode)
);

alu_operation_e alu_operation;
reg [15:0] alu_ta, alu_tb;
wire [31:0] alu_result;
flags_t alu_flags_result;
reg use_alu_result;
reg alu_wide;
wire [5:0] alu_cycles;

alu ALU(
    .clk,

    .operation(alu_operation),
    .ta(alu_ta),
    .tb(alu_tb),
    .result(alu_result),
    .wide(alu_wide),

    .alu_cycles,

    .flags_in(flags),
    .flags(alu_flags_result)
);

reg div_start, div_wide, div_signed;
wire div_done, div_overflow, div_dbz;
reg [32:0] div_num, div_denom;
wire [15:0] div_quot, div_rem;

nec_divider divider(
    .clk, .ce(ce_1 | ce_2),
    .reset,
    .start(div_start),
    .done(div_done),
    .overflow(div_overflow),
    .dbz(div_dbz),
    .wide(div_wide),
    .a(div_num),
    .b(div_denom),
    .quot(div_quot),
    .rem(div_rem)
);

cpu_state_e state /* verilator public */;

assign bcu_intreq = state == INT_ACK_WAIT;

reg [15:0] calculated_ea;
reg [15:0] op_result;

reg [15:0] branch_new_pc;
reg [15:0] branch_new_ps;
reg use_branch_result;

reg [3:0] exec_stage;

reg [15:0] push_list;
reg [15:0] pop_list;
reg [15:0] push_sp_save;

reg [4:0] prepare_nesting_level;
reg [15:0] prepare_sp_save;

reg [6:0] bcd_offset;
reg [4:0] bcd_acc_high, bcd_acc_low;
reg [7:0] bcd_acc, bcd_src;
reg [4:0] bcd_result_high, bcd_result_low;

reg stack_modified_pc, stack_modified_ps;

reg [5:0] cycles;
reg [5:0] op_cycles = 0;

always_ff @(posedge clk) begin
    bit [15:0] addr;
    bit [31:0] result32;
    bit [15:0] temp;
    bit [15:0] src;
    bit [7:0] temp8;

    if (reset) begin
        dp_req <= 0;
        reg_ps <= 16'hffff;
        reg_ss <= 16'd0;
        reg_ds0 <= 16'd0;
        reg_ds1 <= 16'd0;
        next_pc <= 16'd0;
        set_pc <= 1;

        reg_aw <= 16'd0;
        reg_bw <= 16'd0;
        reg_cw <= 16'd0;
        reg_dw <= 16'd0;
        reg_sp <= 16'd0;
        reg_bp <= 16'd0;
        reg_ix <= 16'd0;
        reg_iy <= 16'd0;

        flags.V <= 0;
        flags.S <= 0;
        flags.Z <= 0;
        flags.AC <= 0;
        flags.P <= 0;
        flags.CY <= 0;
        flags.MD <= 1;
        flags.DIR <= 0;
        flags.IE <= 0;
        flags.BRK <= 0;

        state <= IDLE;
        use_alu_result <= 0;
        use_branch_result <= 0;

        stack_modified_pc <= 0;
        stack_modified_ps <= 0;

        halt <= 0;
    end else if (ce_1 | ce_2) begin
        div_start <= 0;
        read_decode <= 0;
        set_pc <= 0;
        dp_req <= 0;

        if (ce_1 & dp_ready & ~&cycles) cycles <= cycles + 6'd1;

        case(state)
            IDLE: if (ce_1) begin
                use_alu_result <= 0;
                use_branch_result <= 0;
                stack_modified_pc <= 0;
                stack_modified_ps <= 0;

                exec_stage <= 4'd0;

                if (1) begin
                    op_cycles <= 6'd0;
                    cycles <= 6'd1;

                    if (intreq & flags.IE) begin
                        state <= INT_ACK_WAIT;
                    end else if (~decode_busy & next_decode_valid & (dp_ready | ~next_decode.mem_read)) begin
                        push_sp_save <= reg_sp;
                        push_list <= next_decode.push;
                        pop_list <= next_decode.pop;

                        read_decode <= 1;
                        decoded <= next_decode;
                        next_pc <= next_decode.end_pc;

                        op_cycles <= next_decode.cycles;
                        if (next_decode.mem_read | next_decode.mem_write) begin
                            op_cycles <= next_decode.mem_cycles;
                        end

                        addr = calc_ea(next_decode.rm, next_decode.mod, next_decode.disp);
                        calculated_ea <= addr;

                        if (next_decode.mem_read & ~next_decode.defer_read) begin
                            read_memory(addr, next_decode.segment, next_decode.width);
                            if (next_decode.width == DWORD) begin
                                state <= FETCH_OPERANDS2;
                            end else begin
                                if (next_decode.push != 16'd0)
                                    state <= PUSH;
                                else if (next_decode.pop != 16'd0)
                                    state <= POP;
                                else
                                    state <= EXECUTE;
                            end
                        end else begin
                            if (next_decode.push != 16'd0)
                                state <= PUSH;
                            else if (next_decode.pop != 16'd0)
                                state <= POP;
                            else
                                state <= EXECUTE;
                        end
                    end
                end
            end // IDLE

            FETCH_OPERANDS: if (ce_1 & dp_ready) begin
                read_memory(calculated_ea, decoded.segment, decoded.width);
                if (next_decode.width == DWORD) begin
                    state <= FETCH_OPERANDS2;
                end else begin
                    if (push_list != 16'd0)
                        state <= PUSH;
                    else if (pop_list != 16'd0)
                        state <= POP;
                    else
                        state <= EXECUTE;
                end
            end

            FETCH_OPERANDS2: if (ce_1 & dp_ready) begin
                dp_din_low <= dp_din;

                read_memory(calculated_ea + 16'd2, decoded.segment, WORD);
                if (push_list != 16'd0)
                    state <= PUSH;
                else if (pop_list != 16'd0)
                    state <= POP;
                else
                    state <= EXECUTE;
            end // FETCH_OPERANDS2

            INT_ACK_WAIT: if (ce_1) begin
                if (bcu_intack) begin
                    interrupt_vector <= bcu_intvec;
                    state <= INT_INITIATE;
                end
            end // INT_ACK_WAIT

            INT_INITIATE: if (ce_1) begin
                push_list <= STACK_PC | STACK_PS | STACK_PSW;
                state <= INT_PUSH;
            end

            INT_FETCH_VEC: if (dp_ready & ce_1) begin
                flags.IE <= 0;
                flags.BRK <= 0;
                dp_addr <= { 6'd0, interrupt_vector[7:0], 2'b00 };
                dp_write <= 0;
                dp_io <= 0;
                dp_zero_seg <= 1;
                dp_wide <= 1;
                dp_req <= 1;
                state <= INT_FETCH_WAIT1;
            end

            INT_FETCH_WAIT1: if (dp_ready & ce_1) begin
                next_pc <= dp_din;
                dp_addr <= { 6'd0, interrupt_vector[7:0], 2'b10 };
                dp_req <= 1;
                state <= INT_FETCH_WAIT2;
            end

            INT_FETCH_WAIT2: if (dp_ready & ce_1) begin
                reg_ps <= dp_din;
                set_pc <= 1;
                state <= IDLE;
            end

            EXECUTE: begin
                bit working;
                bit exception;

                if (dp_ready & ce_1) begin
                    working = 0;
                    exception = 0;
                
                    exec_stage <= exec_stage + 4'd1;

                    case(decoded.opcode)
                        OP_NOP, OP_PUSH, OP_POP: begin
                        end

                        OP_NOT1_CY:  flags.CY <= ~flags.CY;
                        OP_CLR1_CY:  flags.CY <= 0;
                        OP_SET1_CY:  flags.CY <= 1;
                        OP_DI:       flags.IE <= 0;
                        OP_EI:       flags.IE <= 1;
                        OP_CLR1_DIR: flags.DIR <= 0;
                        OP_SET1_DIR: flags.DIR <= 1;
                        OP_HALT:     halt <= 1;

                        OP_CVTWL: reg_dw <= reg_aw[15] ? 16'hffff : 16'h0000;
                        OP_CVTBW: reg_aw[15:8] <= reg_aw[7] ? 8'hff : 8'h00;

                        OP_CVTBD: begin
                            if (exec_stage == 0) begin
                                div_signed <= 0;
                                div_start <= 1;
                                div_num <= { 25'd0, reg_aw[7:0] };
                                div_denom <= 33'd10;
                                working = 1;
                            end else begin
                                if (div_done) begin
                                    reg_aw[15:8] <= div_quot[7:0];
                                    reg_aw[7:0] <= div_rem[7:0];
                                    flags.Z <= ~(|{div_quot[7:0], div_rem[7:0]});
                                    flags.S <= div_rem[7];
                                    flags.P <= ~(^div_rem[7:0]);
                                end else begin
                                    working = 1;
                                    exec_stage <= exec_stage;
                                end
                            end
                        end

                        // TODO verify
                        OP_CVTDB: begin
                            temp8 = reg_aw[7:0] + (reg_aw[15:8] * 8'd10);
                            flags.Z <= ~|temp8;
                            flags.S <= temp8[7];
                            flags.P <= ~(^temp8);
                            reg_aw <= { 8'd0, temp8 };
                        end

                        OP_MOV: begin
                            op_result <= get_operand(decoded.source0);
                        end

                        OP_MOV_SEG: begin
                            set_reg16(reg16_index_e'(decoded.reg0), dp_din32[15:0]);
                            set_sreg(sreg_index_e'(decoded.sreg), dp_din32[31:16]);
                        end

                        OP_MOV_PSW_AH: begin
                            flags.CY  <= reg_aw[8];
                            flags.P   <= reg_aw[10];
                            flags.AC  <= reg_aw[12];
                            flags.Z   <= reg_aw[14];
                            flags.S   <= reg_aw[15];
                        end

                        OP_MOV_AH_PSW: begin
                            reg_aw[15:8]  <= reg_psw[7:0];
                        end

                        OP_LDEA: begin
                            op_result <= calculated_ea;
                        end

                        OP_XCH: begin
                            bit [15:0] dest;
                            dest = get_operand(decoded.dest);
                            op_result <= get_operand(OPERAND_REG_0);
                            if (decoded.width == BYTE)
                                set_reg8(reg8_index_e'(decoded.reg0), dest[7:0]);
                            else
                                set_reg16(reg16_index_e'(decoded.reg0), dest);
                        end

                        OP_ALU: begin
                            start_alu(get_operand(decoded.source0), get_operand(decoded.source1), decoded.alu_operation, decoded.width);
                            use_alu_result <= 1;
                        end

                        OP_SHIFT_1: begin
                            start_alu(get_operand(decoded.source0), 16'd0, shift1_alu_op(decoded.shift), decoded.width);
                            use_alu_result <= 1;
                        end

                        OP_SHIFT_CL: begin
                            start_alu(get_operand(decoded.source0), {8'd0, reg_cw[7:0]}, shift_alu_op(decoded.shift), decoded.width);
                            use_alu_result <= 1;
                        end

                        OP_SHIFT: begin
                            start_alu(get_operand(decoded.source0), get_operand(decoded.source1), shift_alu_op(decoded.shift), decoded.width);
                            use_alu_result <= 1;
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
                            4'b1100: cond = (flags.S ^ flags.V) & ~flags.Z; /* LT */
                            4'b1101: cond = ~(flags.S ^ flags.V) | flags.Z; /* GE */
                            4'b1110: cond = (flags.S ^ flags.V) | flags.Z; /* LE */
                            4'b1111: cond = ~((flags.S ^ flags.V) | flags.Z); /* GT */
                            endcase

                            op_cycles <= cond ? 2 : 3;

                            if (cond) begin
                                branch_new_pc <= decoded.end_pc + get_operand(decoded.source0);
                                branch_new_ps <= reg_ps;
                                use_branch_result <= 1;
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

                            op_cycles <= cond ? 2 : 3;

                            if (cond) begin
                                branch_new_pc <= decoded.end_pc + get_operand(decoded.source0);
                                branch_new_ps <= reg_ps;
                                use_branch_result <= 1;
                            end
                        end

                        OP_BR_REL: begin
                            branch_new_pc <= decoded.end_pc + get_operand(decoded.source0);
                            branch_new_ps <= reg_ps;
                            use_branch_result <= 1;
                        end

                        OP_BR_ABS: begin
                            if (decoded.source0 == OPERAND_IMM && decoded.width == DWORD) begin
                                branch_new_pc <= decoded.imm[15:0];
                                branch_new_ps <= decoded.imm[31:16];
                            end else if (decoded.width == WORD) begin
                                branch_new_pc <= get_operand(decoded.source0);
                                branch_new_ps <= reg_ps;
                            end else if (decoded.source0 == OPERAND_MODRM && decoded.width == DWORD) begin
                                branch_new_pc <= dp_din32[15:0];
                                branch_new_ps <= dp_din32[31:16];
                            end
                            use_branch_result <= 1;
                        end

                        OP_RET: begin
                            set_pc <= 1;
                        end

                        OP_RET_POP_VALUE: begin
                            reg_sp <= reg_sp + get_operand(decoded.source0);
                            set_pc <= 1;
                        end

                        OP_IN: begin
                            if (exec_stage == 0) begin
                                dp_write <= 0;
                                dp_io <= 1;
                                dp_wide <= decoded.width == WORD ? 1 : 0;
                                if (decoded.source0 == OPERAND_IMM8) begin
                                    dp_addr <= { 8'd0, decoded.imm[7:0] };
                                end else begin
                                    dp_addr <= reg_dw;
                                end
                                dp_req <= 1;
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
                                dp_addr <= { 8'd0, decoded.imm[7:0] };
                            end else begin
                                dp_addr <= reg_dw;
                            end
                            dp_req <= 1;
                        end

                        OP_STM: begin
                            bit do_work = 1;
                            if (decoded.rep != REPEAT_NONE) begin
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
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, decoded.segment, decoded.width);
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

                                if (decoded.rep != REPEAT_NONE) working = reg_cw != 16'd0;
                            end
                        end

                        OP_MOVBK: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, decoded.segment, decoded.width);
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

                                if (decoded.rep != REPEAT_NONE) working = reg_cw != 16'd0;
                            end
                        end
                        OP_CMPBK: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, decoded.segment, decoded.width);
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
                                working = 1;
                            end else if (exec_stage == 3) begin
                                working = 1;
                                flags <= alu_flags_result;
                                exec_stage <= 0;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) working = 0;
                                    else if (decoded.rep == REPEAT_NZ) working = ~alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_Z) working = alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_NC) working = ~alu_flags_result.CY;
                                    else if (decoded.rep == REPEAT_C) working = alu_flags_result.CY;
                                end else begin
                                    working = 0;
                                end
                            end
                        end

                        OP_CMPM: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
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
                                working = 1;
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                            end else if (exec_stage == 2) begin
                                working = 1;
                                flags <= alu_flags_result;
                                exec_stage <= 0;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) working = 0;
                                    else if (decoded.rep == REPEAT_NZ) working = ~alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_Z) working = alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_NC) working = ~alu_flags_result.CY;
                                    else if (decoded.rep == REPEAT_C) working = alu_flags_result.CY;
                                end else begin
                                    working = 0;
                                end
                            end
                        end

                        OP_DIV,
                        OP_DIVU: begin
                            bit [15:0] operand;
                            operand = get_operand(OPERAND_MODRM);

                            if (exec_stage == 0) begin
                                div_start <= 1;
                                if (decoded.opcode == OP_DIVU) begin
                                    if (decoded.width == BYTE) begin
                                        div_wide <= 0;
                                        div_num <= { 17'd0, reg_aw };
                                        div_denom <= { 25'd0, operand[7:0] };
                                    end else begin
                                        div_wide <= 1;
                                        div_num <= { 1'd0, reg_dw, reg_aw };
                                        div_denom <= { 17'd0, operand[15:0] };
                                    end
                                end else begin
                                    if (decoded.width == BYTE) begin
                                        div_wide <= 0;
                                        div_num <= { {17{reg_aw[15]}}, reg_aw };
                                        div_denom <= { {25{operand[7]}}, operand[7:0] };
                                    end else begin
                                        div_wide <= 1;
                                        div_num <= { reg_dw[15], reg_dw, reg_aw };
                                        div_denom <= { {17{operand[15]}}, operand[15:0] };
                                    end
                                end
                                working = 1;
                            end else begin
                                if (div_done) begin
                                    if (decoded.width == BYTE) begin
                                        if (div_dbz | div_overflow) begin
                                            interrupt_vector <= 8'd0;
                                            exception = 1;
                                        end else begin
                                            reg_aw <= { div_rem[7:0], div_quot[7:0] };
                                        end
                                    end else begin
                                        if (div_dbz | div_overflow) begin
                                            interrupt_vector <= 8'd0;
                                            exception = 1;
                                        end else begin
                                            reg_aw <= div_quot[15:0];
                                            reg_dw <= div_rem[15:0];
                                        end
                                    end
                                end else begin
                                    working = 1;
                                    exec_stage <= exec_stage;
                                end
                            end
                        end

                        OP_PREPARE: begin
                            working = exec_stage != 3;
                            if (exec_stage == 0) begin
                                prepare_nesting_level <= decoded.imm[20:16];
                                reg_sp <= reg_sp - 16'd2;
                                prepare_sp_save <= reg_sp - 16'd2;
                                write_memory(reg_sp - 16'd2, SS, WORD, reg_bp);
                                working = 1;

                                case(decoded.imm[20:16])
                                5'd0: exec_stage <= 3;
                                5'd1: exec_stage <= 2;
                                default: exec_stage <= 1;
                                endcase
                            end else if (exec_stage == 1) begin
                                reg_sp <= reg_sp - 16'd2;
                                reg_bp <= reg_bp - 16'd2;
                                write_memory(reg_sp - 16'd2, SS, WORD, reg_bp - 16'd2);
                                prepare_nesting_level <= prepare_nesting_level - 5'd1;
                                if (prepare_nesting_level > 5'd2) exec_stage <= exec_stage; 
                            end else if (exec_stage == 2) begin
                                reg_sp <= reg_sp - 16'd2;
                                write_memory(reg_sp - 16'd2, SS, WORD, prepare_sp_save);
                            end else if (exec_stage == 3) begin
                                reg_bp <= prepare_sp_save;
                                reg_sp <= reg_sp - decoded.imm[15:0];
                            end
                        end

                        OP_DISPOSE: begin
                            working = exec_stage == 0;
                            if (exec_stage == 0) begin
                                reg_sp <= reg_bp + 2;
                                read_memory(reg_bp, SS, WORD);
                            end else begin
                                reg_bp <= dp_din;
                            end
                        end

                        OP_CHKIND: begin
                            temp = get_reg16(reg16_index_e'(decoded.reg0));
                            if (dp_din_low > temp || dp_din < temp) begin
                                interrupt_vector <= 8'd5;
                                exception = 1;
                            end
                        end

                        OP_TRANS: begin
                            working = exec_stage == 0;
                            if (exec_stage == 0) begin
                                read_memory(reg_bw + { 8'd0, reg_aw[7:0]}, decoded.segment, BYTE);
                            end else begin
                                reg_aw[7:0] <= dp_din[7:0];
                            end
                        end

                        OP_BRK3: begin
                            interrupt_vector <= 8'd3;
                            exception = 1;
                        end

                        OP_BRK: begin
                            interrupt_vector <= decoded.imm[7:0];
                            exception = 1;
                        end

                        OP_BRKV: begin
                            if (flags.V) begin
                                interrupt_vector <= 8'd4;
                                exception = 1;
                            end
                        end

                        OP_ADD4S, OP_SUB4S, OP_CMP4S: begin
                            working = 1;
                            if (exec_stage == 0) begin
                                bcd_offset <= 7'd0;
                                flags.Z <= 1;
                                flags.CY <= 0;
                            end else if (exec_stage == 1) begin
                                if (bcd_offset == reg_cw[7:1]) begin
                                    working = 0;
                                end else begin
                                    read_memory(reg_ix + {9'd0, bcd_offset}, decoded.segment, BYTE);
                                end
                            end else if (exec_stage == 2) begin
                                bcd_src <= dp_din[7:0] + { 7'd0, flags.CY };
                                flags.CY <= 0;
                                read_memory(reg_iy + {9'd0, bcd_offset}, DS1, BYTE);
                            end else if (exec_stage == 3) begin
                                if (decoded.opcode == OP_ADD4S) begin
                                    bcd_acc_low  <= { 1'b0, dp_din[3:0] } + { 1'b0, bcd_src[3:0] };
                                    bcd_acc_high <= { 1'b0, dp_din[7:4] } + { 1'b0, bcd_src[7:4] };
                                end else begin
                                    bcd_acc_low  <= { 1'b0, dp_din[3:0] } - { 1'b0, bcd_src[3:0] };
                                    bcd_acc_high <= { 1'b0, dp_din[7:4] } - { 1'b0, bcd_src[7:4] };
                                end
                            end else if (exec_stage == 4) begin
                                bcd_result_low = bcd_acc_low;
                                bcd_result_high = bcd_acc_high;
                                if (bcd_result_low > 5'd9) begin
                                    if (decoded.opcode == OP_ADD4S) begin
                                        bcd_result_low = bcd_acc_low + 5'd6;
                                        bcd_result_high = bcd_acc_high + 5'd1;
                                    end else begin
                                        bcd_result_low = bcd_acc_low + 5'd6;
                                        bcd_result_high = bcd_acc_high + 5'd1;
                                    end
                                end

                                if (bcd_result_high > 5'd9) begin
                                    if (decoded.opcode == OP_ADD4S) begin
                                        bcd_result_high = bcd_result_high + 5'd6;
                                    end else begin
                                        bcd_result_high = bcd_result_high - 5'd6;
                                    end
                                    flags.CY <= 1;
                                end
                                bcd_acc <= { bcd_result_high[3:0], bcd_result_low[3:0] };
                            end else if (exec_stage == 5) begin
                                if (|bcd_acc) flags.Z <= 0;
                                if (decoded.opcode != OP_CMP4S) begin
                                    write_memory(reg_iy + { 9'd0, bcd_offset}, DS1, BYTE, { 8'd0, bcd_acc });
                                end
                                bcd_offset <= bcd_offset + 7'd1;
                                exec_stage <= 1; // loop                                
                            end
                        end

                        OP_ROL4: begin
                            temp = get_operand(decoded.source0);
                            reg_aw[3:0] <= temp[7:4];
                            op_result <= { 8'd0, temp[3:0], reg_aw[3:0] };
                        end

                        OP_ROR4: begin
                            temp = get_operand(decoded.source0);
                            reg_aw[3:0] <= temp[3:0];
                            op_result <= { 8'd0, reg_aw[3:0], temp[7:4] };
                        end

                        default: begin // TODO exception
                        end

                    endcase

                    if (~working) begin
                        if (exception) begin
                            state <= INT_INITIATE;
                        end else begin
                            state <= STORE_RESULT;
                        end
                    end
                end
            end // EXECUTE

            POP_WAIT: if (dp_ready & ce_1) begin
                bit [15:0] list;
                int pop_idx = 0;
                bit skip_sp;
                bit mem_write;

                skip_sp = 0;
                mem_write = 0;

                list = pop_list;
                for (int i = 0; i < 16; i = i + 1) begin
                    if (list[i]) pop_idx = i;
                end

                case(pop_idx)
                    0:  reg_aw <= dp_din;
                    1:  reg_cw <= dp_din;
                    2:  reg_dw <= dp_din;
                    3:  reg_bw <= dp_din;
                    4:  reg_sp <= dp_din;
                    5:  begin
                        reg_bp <= dp_din;
                        skip_sp = 1;
                    end
                    6:  reg_bp <= dp_din;
                    7:  reg_ix <= dp_din;
                    8:  reg_iy <= dp_din;
                    9:  reg_ds1 <= dp_din;
                    10: begin
                        flags.CY  <= dp_din[0];
                        flags.P   <= dp_din[2];
                        flags.AC  <= dp_din[4];
                        flags.Z   <= dp_din[6];
                        flags.S   <= dp_din[7];
                        flags.BRK <= dp_din[8];
                        flags.IE  <= dp_din[9];
                        flags.DIR <= dp_din[10];
                        flags.V   <= dp_din[11];
                        // flags.MD  <= dp_din[15]; // TODO V33, no MD flag, V20/30 will need this
                    end
                    11: begin
                        reg_ps <= dp_din;
                        stack_modified_ps <= 1;
                    end
                    12: reg_ss <= dp_din;
                    13: reg_ds0 <= dp_din;
                    14: begin
                        next_pc <= dp_din;
                        stack_modified_pc <= 1;
                    end
                    15: begin
                        if (decoded.mod == 2'b11) begin
                            set_reg16(reg16_index_e'(decoded.rm), dp_din);
                        end else begin
                            write_memory(calculated_ea, decoded.segment, WORD, dp_din);
                            mem_write = 1;
                        end
                    end
                endcase

                list[pop_idx] = 0;
                pop_list <= list;

                if (skip_sp) reg_sp <= reg_sp + 16'd2;

                if (list == 16'd0) begin
                    if (decoded.opcode == OP_POP) begin
                        state <= IDLE;
                    end else begin
                        if (decoded.mem_read & decoded.defer_read) begin
                            state <= FETCH_OPERANDS;
                        end else begin
                            state <= EXECUTE;
                        end
                    end
                end else begin
                    if (mem_write) begin
                        state <= POP;
                    end else begin
                        if (skip_sp) begin
                            read_memory(reg_sp + 16'd2, SS, WORD);
                            reg_sp <= reg_sp + 16'd4;
                        end else begin
                            read_memory(reg_sp, SS, WORD);
                            reg_sp <= reg_sp + 16'd2;
                        end
                        state <= POP_WAIT;
                    end
                end
            end // POP_WAIT

            INT_PUSH,
            PUSH: if (dp_ready & ce_1) begin
                bit [15:0] push_data;
                bit [15:0] list;
                int push_idx;

                push_idx = 0;
                list = push_list;
                for (int i = 15; i >= 0; i = i - 1) begin
                    if (list[i]) push_idx = i;
                end

                reg_sp <= reg_sp - 16'd2;

                case(push_idx)
                0:  push_data = reg_aw;
                1:  push_data = reg_cw;
                2:  push_data = reg_dw;
                3:  push_data = reg_bw;
                4:  push_data = push_sp_save;
                5:  push_data = push_sp_save; // DISCARD
                6:  push_data = reg_bp;
                7:  push_data = reg_ix;
                8:  push_data = reg_iy;
                9:  push_data = reg_ds1;
                10: push_data = reg_psw;
                11: push_data = reg_ps;
                12: push_data = reg_ss;
                13: push_data = reg_ds0;
                14: push_data = next_pc;
                15: push_data = get_operand(decoded.source0);
                endcase

                write_memory(reg_sp - 16'd2, SS, WORD, push_data);

                list[push_idx] = 0;
                push_list <= list;

                if (list == 16'd0) begin
                    if (state == INT_PUSH) begin
                        state <= INT_FETCH_VEC;
                    end else if (decoded.opcode == OP_PUSH) begin
                        state <= IDLE;
                    end else begin
                        if (decoded.mem_read & decoded.defer_read) begin
                            state <= FETCH_OPERANDS;
                        end else begin
                            state <= EXECUTE;
                        end
                    end
                end 
            end // PUSH

            POP: if (dp_ready & ce_1) begin
                read_memory(reg_sp, SS, WORD);
                reg_sp <= reg_sp + 16'd2;

                state <= POP_WAIT;
            end // POP


            STORE_RESULT: begin
                //if (ce_1 & ~&cycles) cycles <= cycles + 6'd1;
 
                if (ce_2 && dp_ready && cycles >= (use_alu_result ? op_cycles + alu_cycles : op_cycles)) begin

                    if (use_branch_result) begin
                        set_pc <= 1;
                        next_pc <= branch_new_pc;
                        reg_ps <= branch_new_ps;
                        state <= IDLE;
                    end else begin
                        result32 = use_alu_result ? alu_result : { 16'd0, op_result };

                        case(decoded.dest)
                        OPERAND_ACC: begin
                            if (decoded.width == BYTE)
                                reg_aw[7:0] <= result32[7:0];
                            else
                                reg_aw <= result32[15:0];
                        end
                        OPERAND_MODRM: begin
                            if (decoded.mod == 2'b11) begin
                                if (decoded.width == BYTE)
                                    set_reg8(reg8_index_e'(decoded.rm), result32[7:0]);
                                else
                                    set_reg16(reg16_index_e'(decoded.rm), result32[15:0]);
                            end else begin
                                write_memory(calculated_ea, decoded.segment, decoded.width, result32[15:0]);
                            end
                        end
                        OPERAND_SREG: begin
                            set_sreg(sreg_index_e'(decoded.sreg), result32[15:0]);
                        end
                        OPERAND_REG_0: begin
                            if (decoded.width == BYTE)
                                set_reg8(reg8_index_e'(decoded.reg0), result32[7:0]);
                            else
                                set_reg16(reg16_index_e'(decoded.reg0), result32[15:0]);
                        end
                        OPERAND_REG_1: begin
                            if (decoded.width == BYTE)
                                set_reg8(reg8_index_e'(decoded.reg1), result32[7:0]);
                            else
                                set_reg16(reg16_index_e'(decoded.reg1), result32[15:0]);
                        end
                        OPERAND_PRODUCT: begin
                            if (decoded.width == WORD) reg_dw <= result32[31:16];
                            reg_aw <= result32[15:0];
                        end
                        default: begin end
                        endcase

                        if (use_alu_result) begin
                            flags <= alu_flags_result;
                            op_cycles <= op_cycles + alu_cycles;
                        end

                        state <= IDLE;
                    end
                end
            end // STORE_RESULT

            // for linting, should not be possible
            default: begin end
        endcase
    end
end
endmodule