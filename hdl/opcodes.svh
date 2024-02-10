24'b11111111xx100xxxxxxxxxxx: begin /* BR ptr16 */
	d.opcode = OP_BR_ABS;
	d.width = WORD;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11111111xx101xxxxxxxxxxx: begin /* BR memptr32 */
	d.opcode = OP_BR_ABS;
	d.width = DWORD;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11111111xx010xxxxxxxxxxx: begin /* CALL ptr16 */
	d.opcode = OP_BR_ABS;
	d.width = WORD;
	d.push = STACK_PC;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11111111xx011xxxxxxxxxxx: begin /* CALL memptr32 */
	d.opcode = OP_BR_ABS;
	d.width = DWORD;
	d.push = STACK_PC | STACK_PS;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11111111xx110xxxxxxxxxxx: begin /* PUSH reg16/mem16 */
	d.push = STACK_OPERAND;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b10001111xx000xxxxxxxxxxx: begin /* POP reg16/mem16 */
	d.pop = STACK_OPERAND;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000000xxx111xxxxxxxxxxx: begin /* CMP mem/reg, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_CMP;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000001xxx111xxxxxxxxxxx: begin /* CMP mem/reg, sext_imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_CMP;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM_EXT;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111111xxx001xxxxxxxxxxx: begin /* DEC mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_DEC;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111111xxx000xxxxxxxxxxx: begin /* INC mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_INC;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx000xxxxxxxxxxx: begin /* TEST mem/reg, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_AND;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx010xxxxxxxxxxx: begin /* NOT mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_NOT;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx011xxxxxxxxxxx: begin /* NEG mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_NEG;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx100xxxxxxxxxxx: begin /* MULU mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_MULU;
	d.use_modrm = 1;
	d.dest = OPERAND_PRODUCT;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_MODRM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx101xxxxxxxxxxx: begin /* MUL mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_MUL;
	d.use_modrm = 1;
	d.dest = OPERAND_PRODUCT;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_MODRM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx110xxxxxxxxxxx: begin /* DIVU mem/reg */
	d.opcode = OP_DIVU;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1111011xxx111xxxxxxxxxxx: begin /* DIV mem/reg */
	d.opcode = OP_DIV;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1100011xxx000xxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b10001110xx0xxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.width = WORD;
	d.use_modrm = 1;
	d.dest = OPERAND_SREG;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.sreg = q[12:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b10001100xx0xxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.width = WORD;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_SREG;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.sreg = q[12:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b10010000xxxxxxxxxxxxxxxx: begin /* NOP */
	d.opcode = OP_NOP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01101011xxxxxxxxxxxxxxxx: begin /* MUL reg, mem/reg, sext_imm8 */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_MUL;
	d.width = WORD;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM_EXT;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b01101001xxxxxxxxxxxxxxxx: begin /* MUL reg, mem/reg, imm16 */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_MUL;
	d.width = WORD;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b00100111xxxxxxxxxxxxxxxx: begin /* ADJ4A */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADJ4A;
	d.reg0 = AW;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00101111xxxxxxxxxxxxxxxx: begin /* ADJ4S */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADJ4S;
	d.reg0 = AW;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00110111xxxxxxxxxxxxxxxx: begin /* ADJBA */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADJBA;
	d.reg0 = AW;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00111111xxxxxxxxxxxxxxxx: begin /* ADJBS */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADJBS;
	d.reg0 = AW;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011000xxxxxxxxxxxxxxxx: begin /* CVTBW */
	d.opcode = OP_CVTBW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011001xxxxxxxxxxxxxxxx: begin /* CVTWL */
	d.opcode = OP_CVTWL;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10001101xxxxxxxxxxxxxxxx: begin /* LDEA reg16, mem16 */
	d.opcode = OP_LDEA;
	d.width = WORD;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11000101xxxxxxxxxxxxxxxx: begin /* MOV_SEG */
	d.opcode = OP_MOV_SEG;
	d.sreg = DS0;
	d.width = DWORD;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11000100xxxxxxxxxxxxxxxx: begin /* MOV_SEG */
	d.opcode = OP_MOV_SEG;
	d.sreg = DS1;
	d.width = DWORD;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b10011111xxxxxxxxxxxxxxxx: begin /* MOV_AH_PSW */
	d.opcode = OP_MOV_AH_PSW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011110xxxxxxxxxxxxxxxx: begin /* MOV_PSW_AH */
	d.opcode = OP_MOV_PSW_AH;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11101001xxxxxxxxxxxxxxxx: begin /* BR near-label */
	d.opcode = OP_BR_REL;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11101011xxxxxxxxxxxxxxxx: begin /* BR short-label */
	d.opcode = OP_BR_REL;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM_EXT;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11101010xxxxxxxxxxxxxxxx: begin /* BR far-label */
	d.opcode = OP_BR_ABS;
	d.width = DWORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11101000xxxxxxxxxxxxxxxx: begin /* CALL near */
	d.opcode = OP_BR_REL;
	d.width = WORD;
	d.push = STACK_PC;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011010xxxxxxxxxxxxxxxx: begin /* CALL far-proc */
	d.opcode = OP_BR_ABS;
	d.width = DWORD;
	d.push = STACK_PC | STACK_PS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11000011xxxxxxxxxxxxxxxx: begin /* RET */
	d.pop = STACK_PC;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11001010xxxxxxxxxxxxxxxx: begin /* RET pop-value */
	d.opcode = OP_POP_VALUE;
	d.width = WORD;
	d.pop = STACK_PC;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11001011xxxxxxxxxxxxxxxx: begin /* RETF */
	d.pop = STACK_PC | STACK_PS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11000010xxxxxxxxxxxxxxxx: begin /* RETF pop-value */
	d.opcode = OP_POP_VALUE;
	d.width = WORD;
	d.pop = STACK_PC | STACK_PS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11001111xxxxxxxxxxxxxxxx: begin /* RETI */
	d.pop = STACK_PC | STACK_PS | STACK_PSW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010000xxxxxxxxxxxxxxxx: begin /* PUSH AW */
	d.push = STACK_AW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010001xxxxxxxxxxxxxxxx: begin /* PUSH CW */
	d.push = STACK_CW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010010xxxxxxxxxxxxxxxx: begin /* PUSH DW */
	d.push = STACK_DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010011xxxxxxxxxxxxxxxx: begin /* PUSH BW */
	d.push = STACK_BW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010100xxxxxxxxxxxxxxxx: begin /* PUSH SP */
	d.push = STACK_SP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010101xxxxxxxxxxxxxxxx: begin /* PUSH BP */
	d.push = STACK_BP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010110xxxxxxxxxxxxxxxx: begin /* PUSH IX */
	d.push = STACK_IX;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010111xxxxxxxxxxxxxxxx: begin /* PUSH IY */
	d.push = STACK_IY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00000110xxxxxxxxxxxxxxxx: begin /* PUSH DS1 */
	d.push = STACK_DS1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00001110xxxxxxxxxxxxxxxx: begin /* PUSH PS */
	d.push = STACK_PS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00010110xxxxxxxxxxxxxxxx: begin /* PUSH SS */
	d.push = STACK_SS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00011110xxxxxxxxxxxxxxxx: begin /* PUSH DS0 */
	d.push = STACK_DS0;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011100xxxxxxxxxxxxxxxx: begin /* PUSH PSW */
	d.push = STACK_PSW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01100000xxxxxxxxxxxxxxxx: begin /* PUSH R */
	d.push = STACK_AW | STACK_CW | STACK_DW | STACK_BW | STACK_SP | STACK_BP | STACK_IX | STACK_IY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01101010xxxxxxxxxxxxxxxx: begin /* PUSH imm8 */
	d.width = BYTE;
	d.push = STACK_OPERAND;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01101000xxxxxxxxxxxxxxxx: begin /* PUSH imm16 */
	d.width = WORD;
	d.push = STACK_OPERAND;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011000xxxxxxxxxxxxxxxx: begin /* POP AW */
	d.pop = STACK_AW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011001xxxxxxxxxxxxxxxx: begin /* POP CW */
	d.pop = STACK_CW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011010xxxxxxxxxxxxxxxx: begin /* POP DW */
	d.pop = STACK_DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011011xxxxxxxxxxxxxxxx: begin /* POP BW */
	d.pop = STACK_BW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011100xxxxxxxxxxxxxxxx: begin /* POP SP */
	d.pop = STACK_SP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011101xxxxxxxxxxxxxxxx: begin /* POP BP */
	d.pop = STACK_BP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011110xxxxxxxxxxxxxxxx: begin /* POP IX */
	d.pop = STACK_IX;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011111xxxxxxxxxxxxxxxx: begin /* POP IY */
	d.pop = STACK_IY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00000111xxxxxxxxxxxxxxxx: begin /* POP DS1 */
	d.pop = STACK_DS1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00001111xxxxxxxxxxxxxxxx: begin /* PPOP PS */
	d.pop = STACK_PS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00010111xxxxxxxxxxxxxxxx: begin /* POP SS */
	d.pop = STACK_SS;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00011111xxxxxxxxxxxxxxxx: begin /* POP DS0 */
	d.pop = STACK_DS0;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011101xxxxxxxxxxxxxxxx: begin /* POP PSW */
	d.pop = STACK_PSW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01100001xxxxxxxxxxxxxxxx: begin /* POP R */
	d.pop = STACK_AW | STACK_CW | STACK_DW | STACK_BW | STACK_SP_DISCARD | STACK_BP | STACK_IX | STACK_IY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11001000xxxxxxxxxxxxxxxx: begin /* PREPARE imm16, imm8 */
	d.opcode = OP_PREPARE;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11001001xxxxxxxxxxxxxxxx: begin /* DISPOSE */
	d.opcode = OP_DISPOSE;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11110011xxxxxxxxxxxxxxxx: begin /* REP/REPE/REPZ */
	d.opcode = OP_REP_PREFIX;
	d.prefix = 1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01100101xxxxxxxxxxxxxxxx: begin /* REPC */
	d.opcode = OP_REP_PREFIX;
	d.prefix = 1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01100100xxxxxxxxxxxxxxxx: begin /* REPNC */
	d.opcode = OP_REP_PREFIX;
	d.prefix = 1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11110010xxxxxxxxxxxxxxxx: begin /* REPNE/REPNZ */
	d.opcode = OP_REP_PREFIX;
	d.prefix = 1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11110100xxxxxxxxxxxxxxxx: begin /* HALT */
	d.opcode = OP_HALT;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11110101xxxxxxxxxxxxxxxx: begin /* NOT1 CY */
	d.opcode = OP_NOT1_CY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11111000xxxxxxxxxxxxxxxx: begin /* CLR1 CY */
	d.opcode = OP_CLR1_CY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11111001xxxxxxxxxxxxxxxx: begin /* SET1 CY */
	d.opcode = OP_SET1_CY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11111010xxxxxxxxxxxxxxxx: begin /* DI */
	d.opcode = OP_DI;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11111011xxxxxxxxxxxxxxxx: begin /* EI */
	d.opcode = OP_EI;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11111100xxxxxxxxxxxxxxxx: begin /* CLR1 DIR */
	d.opcode = OP_CLR1_DIR;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11111101xxxxxxxxxxxxxxxx: begin /* SET1 DIR */
	d.opcode = OP_SET1_DIR;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1000000xxxxxxxxxxxxxxxxx: begin /* ALU_OP mem/reg, imm */
	d.opcode = OP_ALU;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.alu_operation = alu_operation_e'(q[13:11]);
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000001xxxxxxxxxxxxxxxxx: begin /* ALU_OP mem/reg, sext_imm */
	d.opcode = OP_ALU;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM_EXT;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.alu_operation = alu_operation_e'(q[13:11]);
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1101000xxxxxxxxxxxxxxxxx: begin /* SHIFT mem/reg, 1 */
	d.opcode = OP_SHIFT_1;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.shift = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1101001xxxxxxxxxxxxxxxxx: begin /* SHIFT mem/reg, CL */
	d.opcode = OP_SHIFT_CL;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.shift = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1100000xxxxxxxxxxxxxxxxx: begin /* SHIFT mem/reg, imm */
	d.opcode = OP_SHIFT;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM8;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.shift = q[13:11];
	d.pre_size = 2;
	valid_op <= 1;
end
24'b0011100xxxxxxxxxxxxxxxxx: begin /* CMP mem/reg, reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_CMP;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_REG_0;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b0011101xxxxxxxxxxxxxxxxx: begin /* CMP reg, mem/reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_CMP;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_MODRM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b0011110xxxxxxxxxxxxxxxxx: begin /* CMP acc, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_CMP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_IMM;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1000010xxxxxxxxxxxxxxxxx: begin /* TEST mem/reg, reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_AND;
	d.use_modrm = 1;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_REG_0;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1010100xxxxxxxxxxxxxxxxx: begin /* TEST acc, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_AND;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_IMM;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1000100xxxxxxxxxxxxxxxxx: begin /* MOV mem/reg, reg */
	d.opcode = OP_MOV;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000101xxxxxxxxxxxxxxxxx: begin /* MOV reg, mem/reg */
	d.opcode = OP_MOV;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1010000xxxxxxxxxxxxxxxxx: begin /* MOV ACC, dmem */
	d.opcode = OP_MOV;
	d.use_modrm = 1;
	d.rm = 3'b110;
	d.mod = 2'b00;
	d.dest = OPERAND_ACC;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010001xxxxxxxxxxxxxxxxx: begin /* MOV dmem, ACC */
	d.opcode = OP_MOV;
	d.use_modrm = 1;
	d.rm = 3'b110;
	d.mod = 2'b00;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1000011xxxxxxxxxxxxxxxxx: begin /* XCH mem/reg, reg */
	d.opcode = OP_XCH;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1110010xxxxxxxxxxxxxxxxx: begin /* IN acc, imm8 */
	d.opcode = OP_IN;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM8;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1110110xxxxxxxxxxxxxxxxx: begin /* IN acc, DW */
	d.opcode = OP_IN;
	d.reg0 = DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1110011xxxxxxxxxxxxxxxxx: begin /* OUT imm8, acc */
	d.opcode = OP_OUT;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM8;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1110111xxxxxxxxxxxxxxxxx: begin /* OUT DW, acc */
	d.opcode = OP_OUT;
	d.reg0 = DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1111000xxxxxxxxxxxxxxxxx: begin /* BUSLOCK */
	d.opcode = OP_BUSLOCK_PREFIX;
	d.prefix = 1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010101xxxxxxxxxxxxxxxxx: begin /* STM */
	d.opcode = OP_STM;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010011xxxxxxxxxxxxxxxxx: begin /* CMPBK */
	d.opcode = OP_CMPBK;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010111xxxxxxxxxxxxxxxxx: begin /* CMPM */
	d.opcode = OP_CMPM;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010110xxxxxxxxxxxxxxxxx: begin /* LDM */
	d.opcode = OP_LDM;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010010xxxxxxxxxxxxxxxxx: begin /* MOVBK */
	d.opcode = OP_MOVBK;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b001xx110xxxxxxxxxxxxxxxx: begin /* SEG PREFIX */
	d.opcode = OP_SEG_PREFIX;
	d.prefix = 1;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.sreg = q[20:19];
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01001xxxxxxxxxxxxxxxxxxx: begin /* DEC reg16 */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_DEC;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.reg0 = q[18:16];
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01000xxxxxxxxxxxxxxxxxxx: begin /* INC reg16 */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_INC;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.reg0 = q[18:16];
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10010xxxxxxxxxxxxxxxxxxx: begin /* XCH AW, reg16 */
	d.opcode = OP_XCH;
	d.reg1 = AW;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_1;
	d.source0 = OPERAND_REG_1;
	d.source1 = OPERAND_NONE;
	d.reg0 = q[18:16];
	d.pre_size = 1;
	valid_op <= 1;
end
24'b00xxx00xxxxxxxxxxxxxxxxx: begin /* ALU_OP mem/reg, reg */
	d.opcode = OP_ALU;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_REG_0;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.alu_operation = alu_operation_e'(q[21:19]);
	d.pre_size = 2;
	valid_op <= 1;
end
24'b00xxx01xxxxxxxxxxxxxxxxx: begin /* ALU_OP reg, mem/reg */
	d.opcode = OP_ALU;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_MODRM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.alu_operation = alu_operation_e'(q[21:19]);
	d.pre_size = 2;
	valid_op <= 1;
end
24'b00xxx10xxxxxxxxxxxxxxxxx: begin /* ALU_OP acc, imm */
	d.opcode = OP_ALU;
	d.use_modrm = 0;
	d.dest = OPERAND_ACC;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_IMM;
	d.width = q[16] ? WORD : BYTE;
	d.alu_operation = alu_operation_e'(q[21:19]);
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1011xxxxxxxxxxxxxxxxxxxx: begin /* MOV reg, imm */
	d.opcode = OP_MOV;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.reg0 = q[18:16];
	d.width = q[19] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b0111xxxxxxxxxxxxxxxxxxxx: begin /* B cond, disp */
	d.opcode = OP_B_COND;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM_EXT;
	d.source1 = OPERAND_NONE;
	d.cond = q[19:16];
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1110xxxxxxxxxxxxxxxxxxxx: begin /* B_CW_COND */
	d.opcode = OP_B_CW_COND;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM_EXT;
	d.source1 = OPERAND_NONE;
	d.cond = q[19:16];
	d.pre_size = 1;
	valid_op <= 1;
end
