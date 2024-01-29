package types;
    typedef enum bit [1:0] {DS1, PS, SS, DS0} sreg_index_e;
    typedef enum bit [2:0] {AL, CL, DL, BL, AH, CH, DH, BH} reg8_index_e;
    typedef enum bit [2:0] {AW, CW, DW, BW, SP, BP, IX, IY} reg16_index_e;

    typedef enum {
        OP_ALU,
        OP_ADD4S,
        OP_MOV,
        OP_MOV_SEG,
        OP_MOV_AH_PSW,
        OP_MOV_PSW_AH
    } opcode_e;

    typedef enum {
        ALU_OP_NONE,
        ALU_OP_ADD
    } alu_operation_e;

    typedef enum {
        OPERAND_ACC8,
        OPERAND_ACC16,
        OPERAND_IMM8,
        OPERAND_IMM8_EXT,
        OPERAND_IMM16,
        OPERAND_MEM8,
        OPERAND_MEM16,
        OPERAND_MEM32,
        OPERAND_REG8_0,
        OPERAND_REG8_1,
        OPERAND_REG16_0,
        OPERAND_REG16_1,
        OPERAND_SREG,
        OPERAND_NONE
    } operand_e;

    typedef struct {
        opcode_e opcode;
        alu_operation_e alu_operation;
        operand_e source_mem;
        operand_e source0;
        operand_e source1;
        operand_e dest;


        bit calc_ea;
        bit [1:0] ea_mod;
        bit [2:0] ea_mem;
        bit [2:0] reg0;
        bit [2:0] reg1;
        bit [1:0] sreg;

        bit [3:0] pre_size;
    } pre_decode_t;


endpackage
