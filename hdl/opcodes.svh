24'b0000111100100000xxxxxxxx: begin d.opcode = OP_ALU4S; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_NONE; d.source0 = OPERAND_NONE; d.source1 = OPERAND_NONE; d.pre_size = 2; valid_op <= 1; end
24'b1000000011000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_REG8_0; d.source1 = OPERAND_IMM8; d.reg0 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b1000000111000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_REG16_0; d.source1 = OPERAND_IMM8; d.reg0 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b1000001011000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_REG8_0; d.source1 = OPERAND_IMM8; d.reg0 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b1000001111000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_REG16_0; d.source1 = OPERAND_IMM8_EXT; d.reg0 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b10000000xx000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_MEM8; d.source0 = OPERAND_MEM8; d.source1 = OPERAND_IMM8; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b10000001xx000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_MEM16; d.source0 = OPERAND_MEM16; d.source1 = OPERAND_IMM16; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b10000010xx000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_MEM8; d.source0 = OPERAND_MEM8; d.source1 = OPERAND_IMM8; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b10000011xx000xxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_MEM16; d.source0 = OPERAND_MEM16; d.source1 = OPERAND_IMM8_EXT; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b10001110110xxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_SREG; d.source0 = OPERAND_REG16_0; d.source1 = OPERAND_NONE; d.reg0 = q[10:8]; d.sreg = q[12:11]; d.pre_size = 2; valid_op <= 1; end
24'b10001100110xxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_SREG; d.source1 = OPERAND_NONE; d.reg0 = q[10:8]; d.sreg = q[12:11]; d.pre_size = 2; valid_op <= 1; end
24'b0000001111xxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_REG16_0; d.source1 = OPERAND_REG16_1; d.reg0 = q[13:11]; d.reg1 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b0000001011xxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_REG8_0; d.source1 = OPERAND_REG8_1; d.reg0 = q[13:11]; d.reg1 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b1000101011xxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_REG8_1; d.source1 = OPERAND_NONE; d.reg0 = q[13:11]; d.reg1 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b1000101111xxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_REG16_1; d.source1 = OPERAND_NONE; d.reg0 = q[13:11]; d.reg1 = q[10:8]; d.pre_size = 2; valid_op <= 1; end
24'b10001110xx0xxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.dest = OPERAND_SREG; d.source0 = OPERAND_MEM16; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.sreg = q[12:11]; d.pre_size = 2; valid_op <= 1; end
24'b10001100xx0xxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.dest = OPERAND_MEM16; d.source0 = OPERAND_SREG; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.sreg = q[12:11]; d.pre_size = 2; valid_op <= 1; end
24'b00000000xxxxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_MEM8; d.source0 = OPERAND_MEM8; d.source1 = OPERAND_REG8_0; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b00000001xxxxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_MEM16; d.source0 = OPERAND_MEM16; d.source1 = OPERAND_REG16_0; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b00000010xxxxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_REG8_0; d.source1 = OPERAND_MEM8; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b00000011xxxxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 1; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_REG16_0; d.source1 = OPERAND_MEM16; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b00000100xxxxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_ACC8; d.source0 = OPERAND_ACC8; d.source1 = OPERAND_IMM8; d.pre_size = 1; valid_op <= 1; end
24'b00000101xxxxxxxxxxxxxxxx: begin d.opcode = OP_ALU; d.alu_operation = ALU_OP_ADD; d.calc_ea = 0; d.dest = OPERAND_ACC16; d.source0 = OPERAND_ACC16; d.source1 = OPERAND_IMM16; d.pre_size = 1; valid_op <= 1; end
24'b10001000xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.dest = OPERAND_MEM8; d.source0 = OPERAND_REG8_0; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b10001001xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.dest = OPERAND_MEM16; d.source0 = OPERAND_REG16_0; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b10001010xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_MEM8; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b10001011xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_MEM16; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b10100000xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.ea_mem = 3'b110; d.ea_mod = 2'b11; d.dest = OPERAND_ACC8; d.source0 = OPERAND_MEM8; d.source1 = OPERAND_NONE; d.pre_size = 1; valid_op <= 1; end
24'b10100001xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.ea_mem = 3'b110; d.ea_mod = 2'b11; d.dest = OPERAND_ACC16; d.source0 = OPERAND_MEM16; d.source1 = OPERAND_NONE; d.pre_size = 1; valid_op <= 1; end
24'b10100010xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.ea_mem = 3'b110; d.ea_mod = 2'b11; d.dest = OPERAND_MEM8; d.source0 = OPERAND_ACC8; d.source1 = OPERAND_NONE; d.pre_size = 1; valid_op <= 1; end
24'b10100011xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 1; d.ea_mem = 3'b110; d.ea_mod = 2'b11; d.dest = OPERAND_MEM16; d.source0 = OPERAND_ACC16; d.source1 = OPERAND_NONE; d.pre_size = 1; valid_op <= 1; end
24'b11000101xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV_SEG; d.alu_operation = ALU_OP_NONE; d.sreg = DS0; d.calc_ea = 1; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_MEM32; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b11000100xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV_SEG; d.alu_operation = ALU_OP_NONE; d.sreg = DS1; d.calc_ea = 1; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_MEM32; d.source1 = OPERAND_NONE; d.ea_mod = q[15:14]; d.ea_mem = q[10:8]; d.reg0 = q[13:11]; d.pre_size = 2; valid_op <= 1; end
24'b10011111xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV_AH_PSW; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_NONE; d.source0 = OPERAND_NONE; d.source1 = OPERAND_NONE; d.pre_size = 1; valid_op <= 1; end
24'b10011110xxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV_PSW_AH; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_NONE; d.source0 = OPERAND_NONE; d.source1 = OPERAND_NONE; d.pre_size = 1; valid_op <= 1; end
24'b10110xxxxxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_REG8_0; d.source0 = OPERAND_IMM8; d.source1 = OPERAND_NONE; d.reg0 = q[18:16]; d.pre_size = 1; valid_op <= 1; end
24'b10111xxxxxxxxxxxxxxxxxxx: begin d.opcode = OP_MOV; d.alu_operation = ALU_OP_NONE; d.calc_ea = 0; d.dest = OPERAND_REG16_0; d.source0 = OPERAND_IMM16; d.source1 = OPERAND_NONE; d.reg0 = q[18:16]; d.pre_size = 1; valid_op <= 1; end