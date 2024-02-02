24'b0000111100100000xxxxxxxx: begin /* ADD4S */
	d.opcode = OP_ADD4S;
	d.alu_operation = ALU_OP_NONE;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000000x11000xxxxxxxxxxx: begin /* ADD reg, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_IMM;
	d.reg0 = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000001x11000xxxxxxxxxxx: begin /* ADD reg, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_IMM_EXT;
	d.reg0 = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b11111111xx100xxxxxxxxxxx: begin /* BR ptr16 */
	d.opcode = OP_BR_ABS;
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
	d.opcode = OP_CALL_NEAR;
	d.alu_operation = ALU_OP_NONE;
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
24'b11111111xx011xxxxxxxxxxx: begin /* CALL memptr32 */
	d.opcode = OP_CALL_FAR;
	d.alu_operation = ALU_OP_NONE;
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
24'b1000000xxx000xxxxxxxxxxx: begin /* ADD mem, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000001xxx000xxxxxxxxxxx: begin /* ADD mem, sext_imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_IMM_EXT;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b0000001x11xxxxxxxxxxxxxx: begin /* ADD reg, reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_REG_1;
	d.reg0 = q[13:11];
	d.reg1 = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b1000101x11xxxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
	d.use_modrm = 0;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_1;
	d.source1 = OPERAND_NONE;
	d.reg0 = q[13:11];
	d.reg1 = q[10:8];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b10001110xx0xxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
24'b11000101xxxxxxxxxxxxxxxx: begin /* MOV_SEG */
	d.opcode = OP_MOV_SEG;
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011110xxxxxxxxxxxxxxxx: begin /* MOV_PSW_AH */
	d.opcode = OP_MOV_PSW_AH;
	d.alu_operation = ALU_OP_NONE;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11101001xxxxxxxxxxxxxxxx: begin /* BR near-label */
	d.opcode = OP_BR_REL;
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
	d.width = DWORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b11101000xxxxxxxxxxxxxxxx: begin /* CALL near */
	d.opcode = OP_CALL_NEAR;
	d.alu_operation = ALU_OP_NONE;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b10011010xxxxxxxxxxxxxxxx: begin /* CALL far-proc */
	d.opcode = OP_CALL_FAR;
	d.alu_operation = ALU_OP_NONE;
	d.width = DWORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010000xxxxxxxxxxxxxxxx: begin /* PUSH AW */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_AW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010001xxxxxxxxxxxxxxxx: begin /* PUSH CW */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_CW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010010xxxxxxxxxxxxxxxx: begin /* PUSH DW */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010011xxxxxxxxxxxxxxxx: begin /* PUSH BW */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_BW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010100xxxxxxxxxxxxxxxx: begin /* PUSH SP */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_SP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010101xxxxxxxxxxxxxxxx: begin /* PUSH BP */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_BP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010110xxxxxxxxxxxxxxxx: begin /* PUSH IX */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_IX;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01010111xxxxxxxxxxxxxxxx: begin /* PUSH IY */
	d.alu_operation = ALU_OP_NONE;
	d.push = STACK_IY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011000xxxxxxxxxxxxxxxx: begin /* POP AW */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_AW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011001xxxxxxxxxxxxxxxx: begin /* POP CW */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_CW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011010xxxxxxxxxxxxxxxx: begin /* POP DW */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011011xxxxxxxxxxxxxxxx: begin /* POP BW */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_BW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011100xxxxxxxxxxxxxxxx: begin /* POP SP */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_SP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011101xxxxxxxxxxxxxxxx: begin /* POP BP */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_BP;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011110xxxxxxxxxxxxxxxx: begin /* POP IX */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_IX;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b01011111xxxxxxxxxxxxxxxx: begin /* POP IY */
	d.alu_operation = ALU_OP_NONE;
	d.pop = STACK_IY;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_NONE;
	d.source1 = OPERAND_NONE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b0000000xxxxxxxxxxxxxxxxx: begin /* ADD mem, reg */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 1;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_REG_0;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b0000001xxxxxxxxxxxxxxxxx: begin /* ADD reg, mem */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 1;
	d.dest = OPERAND_REG_0;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_MODRM;
	d.mod = q[15:14];
	d.rm = q[10:8];
	d.reg0 = q[13:11];
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 2;
	valid_op <= 1;
end
24'b0000010xxxxxxxxxxxxxxxxx: begin /* ADD acc, imm */
	d.opcode = OP_ALU;
	d.alu_operation = ALU_OP_ADD;
	d.use_modrm = 0;
	d.dest = OPERAND_ACC;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_IMM;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1000100xxxxxxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
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
24'b1000101xxxxxxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
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
24'b1010000xxxxxxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
	d.use_modrm = 1;
	d.rm = 3'b101;
	d.mod = 2'b00;
	d.dest = OPERAND_ACC;
	d.source0 = OPERAND_MODRM;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1010001xxxxxxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
	d.use_modrm = 1;
	d.rm = 3'b101;
	d.mod = 2'b00;
	d.dest = OPERAND_MODRM;
	d.source0 = OPERAND_ACC;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1110010xxxxxxxxxxxxxxxxx: begin /* IN acc, imm8 */
	d.opcode = OP_IN;
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
	d.reg0 = DW;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_REG_0;
	d.source1 = OPERAND_NONE;
	d.width = q[16] ? WORD : BYTE;
	d.pre_size = 1;
	valid_op <= 1;
end
24'b1011xxxxxxxxxxxxxxxxxxxx: begin /* MOV */
	d.opcode = OP_MOV;
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
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
	d.alu_operation = ALU_OP_NONE;
	d.width = WORD;
	d.use_modrm = 0;
	d.dest = OPERAND_NONE;
	d.source0 = OPERAND_IMM_EXT;
	d.source1 = OPERAND_NONE;
	d.cond = q[19:16];
	d.pre_size = 1;
	valid_op <= 1;
end
