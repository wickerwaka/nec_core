package types;
    typedef enum bit [1:0] {DS1, PS, SS, DS0} sreg_index_e;
    typedef enum bit [2:0] {AL, CL, DL, BL, AH, CH, DH, BH} reg8_index_e;
    typedef enum bit [2:0] {AW, CW, DW, BW, SP, BP, IX, IY} reg16_index_e;

    
    const bit [15:0] STACK_AW         = 16'h0001;
    const bit [15:0] STACK_CW         = 16'h0002;
    const bit [15:0] STACK_DW         = 16'h0004;
    const bit [15:0] STACK_BW         = 16'h0008;
    const bit [15:0] STACK_SP         = 16'h0010;
    const bit [15:0] STACK_SP_DISCARD = 16'h0020;
    const bit [15:0] STACK_BP         = 16'h0040;
    const bit [15:0] STACK_IX         = 16'h0080;
    const bit [15:0] STACK_IY         = 16'h0100;
    const bit [15:0] STACK_DS1        = 16'h0200;
    const bit [15:0] STACK_PSW        = 16'h0400;
    const bit [15:0] STACK_PS         = 16'h0800;
    const bit [15:0] STACK_SS         = 16'h1000;
    const bit [15:0] STACK_DS0        = 16'h2000;
    const bit [15:0] STACK_PC         = 16'h4000;
    const bit [15:0] STACK_OPERAND    = 16'h8000;
    
    typedef enum {
        OP_NOP,
        OP_ALU,
        OP_MOV,
        OP_MOV_SEG,
        OP_MOV_AH_PSW,
        OP_MOV_PSW_AH,
        OP_XCH,
        OP_B_COND,
        OP_B_CW_COND,
        OP_IN,
        OP_OUT,
        OP_BR_REL,
        OP_BR_ABS,
        OP_CALL_REL,
        OP_CALL_NEAR,
        OP_CALL_FAR,
        OP_POP_VALUE,
        OP_SEG_PREFIX,
        OP_REP_PREFIX,
        OP_BUSLOCK_PREFIX,
        OP_STM,
        OP_LDM,
        OP_MOVBK,
        OP_CMPBK,
        OP_CMPM,
        OP_INM,
        OP_OUTM,
        OP_NOT1_CY,
        OP_CLR1_CY,
        OP_SET1_CY,
        OP_DI,
        OP_EI,
        OP_CLR1_DIR,
        OP_SET1_DIR,
        OP_HALT,
        OP_SHIFT,
        OP_SHIFT_1,
        OP_SHIFT_CL,
        OP_LDEA,
        OP_CVTBW,
        OP_CVTWL,
        OP_DIV,
        OP_DIVU,

        OP_PREPARE,
        OP_DISPOSE,
        
        // pseido op for interrupt procesing
        OP_INT
    } opcode_e;

    typedef enum bit [5:0] {
        ALU_OP_ADD  = 6'b00000,
        ALU_OP_OR   = 6'b00001,
        ALU_OP_ADDC = 6'b00010,
        ALU_OP_SUBC = 6'b00011,
        ALU_OP_AND  = 6'b00100,
        ALU_OP_SUB  = 6'b00101,
        ALU_OP_XOR  = 6'b00110,
        ALU_OP_CMP  = 6'b00111,

        ALU_OP_NOT,
        ALU_OP_NEG,
        ALU_OP_INC,
        ALU_OP_DEC,

        ALU_OP_ROL,
        ALU_OP_ROR,
        ALU_OP_ROLC,
        ALU_OP_RORC,
        ALU_OP_SHL,
        ALU_OP_SHR,
        ALU_OP_SHRA,

        ALU_OP_ROL1,
        ALU_OP_ROR1,
        ALU_OP_ROLC1,
        ALU_OP_RORC1,
        ALU_OP_SHL1,
        ALU_OP_SHR1,
        ALU_OP_SHRA1,

        ALU_OP_ADJ4S,
        ALU_OP_ADJ4A,
        ALU_OP_ADJBS,
        ALU_OP_ADJBA,

        ALU_OP_SET1,
        ALU_OP_CLR1,
        ALU_OP_TEST1,
        ALU_OP_NOT1,

        ALU_OP_MULU,
        ALU_OP_MUL,

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
        OPERAND_PRODUCT, // DW:AW registers
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
        bit [2:0] shift;

        width_e width;

        bit [15:0] push;
        bit [15:0] pop;

        bit prefix;

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
