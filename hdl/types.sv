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
        OP_MOV_PSW_AH,
        OP_B_COND
    } opcode_e;

    typedef enum {
        ALU_OP_NONE,
        ALU_OP_ADD
    } alu_operation_e;

    typedef enum {
        OPERAND_ACC,
        OPERAND_IMM,
        OPERAND_IMM_EXT,
        OPERAND_MODRM,
        OPERAND_REG_0,
        OPERAND_REG_1,
        OPERAND_SREG,
        OPERAND_NONE
    } operand_e;

    typedef enum {
        BYTE,
        WORD,
        DWORD
    } width_e;

    typedef struct {
        opcode_e opcode;
        alu_operation_e alu_operation;
        operand_e source0;
        operand_e source1;
        operand_e dest;

        bit use_modrm;
        bit [1:0] mod;
        bit [2:0] rm;
        bit [2:0] reg0;
        bit [2:0] reg1;
        bit [1:0] sreg;

        bit [3:0] cond;

        width_e width;

        bit [3:0] pre_size;
    } pre_decode_t;

    typedef struct {
        bit V;
        bit S;
        bit Z;
        bit AC;
        bit P;
        bit CY;

        bit MD;
        bit DIR;
        bit IE;
        bit BRK;
    } flags_t;

endpackage
