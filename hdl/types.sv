package types;
    typedef enum bit [1:0] {DS1, PS, SS, DS0} sreg_index_e;
    typedef enum bit [2:0] {AL, CL, DL, BL, AH, CH, DH, BH} reg8_index_e;
    typedef enum bit [2:0] {AW, CW, DW, BW, SP, BP, IX, IY} reg16_index_e;

    
    const bit [15:0] STACK_AW    = 16'h0001;
    const bit [15:0] STACK_CW    = 16'h0002;
    const bit [15:0] STACK_DW    = 16'h0004;
    const bit [15:0] STACK_BW    = 16'h0008;
    const bit [15:0] STACK_SP    = 16'h0010;
    const bit [15:0] STACK_BP    = 16'h0020;
    const bit [15:0] STACK_IX    = 16'h0040;
    const bit [15:0] STACK_IY    = 16'h0080;
    const bit [15:0] STACK_DS1   = 16'h0100;
    const bit [15:0] STACK_PSW   = 16'h0200;
    const bit [15:0] STACK_PS    = 16'h0400;
    const bit [15:0] STACK_SS    = 16'h0800;
    const bit [15:0] STACK_DS0   = 16'h1000;
    const bit [15:0] STACK_PC    = 16'h2000;
    const bit [15:0] STACK_MODRM = 16'h4000;
    const bit [15:0] STACK_IMM   = 16'h8000;
    
    typedef enum {
        OP_NOP,
        OP_ALU,
        OP_ADD4S,
        OP_MOV,
        OP_MOV_SEG,
        OP_MOV_AH_PSW,
        OP_MOV_PSW_AH,
        OP_B_COND,
        OP_B_CW_COND,
        OP_IN,
        OP_OUT,
        OP_BR_REL,
        OP_BR_ABS,
        OP_CALL_REL,
        OP_CALL_NEAR,
        OP_CALL_FAR,
        OP_POP_VALUE
    } opcode_e;

    typedef enum bit [4:0] {
        ALU_OP_ADD  = 'b00000,
        ALU_OP_OR   = 'b00001,
        ALU_OP_ADDC = 'b00010,
        ALU_OP_SUBC = 'b00011,
        ALU_OP_AND  = 'b00100,
        ALU_OP_SUB  = 'b00101,
        ALU_OP_XOR  = 'b00110,
        ALU_OP_CMP  = 'b00111,

        ALU_OP_NOT,
        ALU_OP_NEG,
        ALU_OP_INC,
        ALU_OP_DEC,

        ALU_OP_SET1,
        ALU_OP_CLR1,
        ALU_OP_TEST1,
        ALU_OP_NOT1,

        ALU_OP_NONE
    } alu_operation_e;

    typedef enum {
        OPERAND_ACC,
        OPERAND_IMM,
        OPERAND_IMM8,
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

        bit [7:0] opcode_byte;

        bit use_modrm;
        bit [1:0] mod;
        bit [2:0] rm;
        bit [2:0] reg0;
        bit [2:0] reg1;
        bit [1:0] sreg;

        bit [3:0] cond;

        width_e width;

        bit [15:0] push;
        bit [15:0] pop;

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
