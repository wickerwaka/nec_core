// Auto-generated from {input_nane} by {sys.argv[0]}
// DO NOT EDIT

typedef enum bit [1:0] {
    DS1 = 2'b00,
    PS  = 2'b01,
    SS  = 2'b10,
    DS0 = 2'b11
} sreg_index_e /* verilator public */;

typedef enum bit [2:0] {
    AL = 3'b000,
    CL = 3'b001,
    DL = 3'b010,
    BL = 3'b011,
    AH = 3'b100,
    CH = 3'b101,
    DH = 3'b110,
    BH = 3'b111
} reg8_index_e /* verilator public */;

typedef enum bit [2:0] {
    AW = 3'b000,
    CW = 3'b001,
    DW = 3'b010,
    BW = 3'b011,
    SP = 3'b100,
    BP = 3'b101,
    IX = 3'b110,
    IY = 3'b111
} reg16_index_e /* verilator public */;

typedef enum bit [5:0] {
    OP_INVALID       = 6'b000000,
    OP_NOP           = 6'b000001,
    OP_ALU           = 6'b000010,
    OP_MOV           = 6'b000011,
    OP_MOV_SEG       = 6'b000100,
    OP_MOV_AH_PSW    = 6'b000101,
    OP_MOV_PSW_AH    = 6'b000110,
    OP_XCH           = 6'b000111,
    OP_B_COND        = 6'b001000,
    OP_B_CW_COND     = 6'b001001,
    OP_IN            = 6'b001010,
    OP_OUT           = 6'b001011,
    OP_BR_REL        = 6'b001100,
    OP_BR_ABS        = 6'b001101,
    OP_RET           = 6'b001110,
    OP_RET_POP_VALUE = 6'b001111,
    OP_STM           = 6'b010000,
    OP_LDM           = 6'b010001,
    OP_MOVBK         = 6'b010010,
    OP_CMPBK         = 6'b010011,
    OP_CMPM          = 6'b010100,
    OP_INM           = 6'b010101,
    OP_OUTM          = 6'b010110,
    OP_NOT1_CY       = 6'b010111,
    OP_CLR1_CY       = 6'b011000,
    OP_SET1_CY       = 6'b011001,
    OP_DI            = 6'b011010,
    OP_EI            = 6'b011011,
    OP_CLR1_DIR      = 6'b011100,
    OP_SET1_DIR      = 6'b011101,
    OP_HALT          = 6'b011110,
    OP_SHIFT         = 6'b011111,
    OP_SHIFT_1       = 6'b100000,
    OP_SHIFT_CL      = 6'b100001,
    OP_LDEA          = 6'b100010,
    OP_CVTDB         = 6'b100011,
    OP_CVTBD         = 6'b100100,
    OP_CVTBW         = 6'b100101,
    OP_CVTWL         = 6'b100110,
    OP_DIV           = 6'b100111,
    OP_DIVU          = 6'b101000,
    OP_PREPARE       = 6'b101001,
    OP_DISPOSE       = 6'b101010,
    OP_CHKIND        = 6'b101011,
    OP_TRANS         = 6'b101100,
    OP_BRK3          = 6'b101101,
    OP_BRK           = 6'b101110,
    OP_BRKV          = 6'b101111,
    OP_ADD4S         = 6'b110000,
    OP_SUB4S         = 6'b110001,
    OP_CMP4S         = 6'b110010,
    OP_ROR4          = 6'b110011,
    OP_ROL4          = 6'b110100,
    OP_PUSH          = 6'b110101,
    OP_POP           = 6'b110110
} opcode_e /* verilator public */;

typedef enum bit [5:0] {
    ALU_OP_ADD   = 6'b000000,
    ALU_OP_OR    = 6'b000001,
    ALU_OP_ADDC  = 6'b000010,
    ALU_OP_SUBC  = 6'b000011,
    ALU_OP_AND   = 6'b000100,
    ALU_OP_SUB   = 6'b000101,
    ALU_OP_XOR   = 6'b000110,
    ALU_OP_CMP   = 6'b000111,
    ALU_OP_NOT   = 6'b001000,
    ALU_OP_NEG   = 6'b001001,
    ALU_OP_INC   = 6'b001010,
    ALU_OP_DEC   = 6'b001011,
    ALU_OP_ROL   = 6'b001100,
    ALU_OP_ROR   = 6'b001101,
    ALU_OP_ROLC  = 6'b001110,
    ALU_OP_RORC  = 6'b001111,
    ALU_OP_SHL   = 6'b010000,
    ALU_OP_SHR   = 6'b010001,
    ALU_OP_SHRA  = 6'b010010,
    ALU_OP_ROL1  = 6'b010011,
    ALU_OP_ROR1  = 6'b010100,
    ALU_OP_ROLC1 = 6'b010101,
    ALU_OP_RORC1 = 6'b010110,
    ALU_OP_SHL1  = 6'b010111,
    ALU_OP_SHR1  = 6'b011000,
    ALU_OP_SHRA1 = 6'b011001,
    ALU_OP_ADJ4S = 6'b011010,
    ALU_OP_ADJ4A = 6'b011011,
    ALU_OP_ADJBS = 6'b011100,
    ALU_OP_ADJBA = 6'b011101,
    ALU_OP_SET1  = 6'b011110,
    ALU_OP_CLR1  = 6'b011111,
    ALU_OP_TEST1 = 6'b100000,
    ALU_OP_NOT1  = 6'b100001,
    ALU_OP_MULU  = 6'b100010,
    ALU_OP_MUL   = 6'b100011,
    ALU_OP_NONE  = 6'b100100
} alu_operation_e /* verilator public */;

typedef enum bit [3:0] {
    OPERAND_NONE    = 4'b0000,
    OPERAND_ACC     = 4'b0001,
    OPERAND_IMM     = 4'b0010,
    OPERAND_IMM8    = 4'b0011,
    OPERAND_IMM_EXT = 4'b0100,
    OPERAND_MODRM   = 4'b0101,
    OPERAND_REG_0   = 4'b0110,
    OPERAND_REG_1   = 4'b0111,
    OPERAND_SREG    = 4'b1000,
    OPERAND_PRODUCT = 4'b1001,
    OPERAND_CL      = 4'b1010
} operand_e /* verilator public */;

typedef enum bit [1:0] {
    BYTE  = 2'b00,
    WORD  = 2'b01,
    DWORD = 2'b10
} width_e /* verilator public */;

typedef enum bit [3:0] {
    IDLE            = 4'b0000,
    FETCH_OPERANDS  = 4'b0001,
    FETCH_OPERANDS2 = 4'b0010,
    PUSH            = 4'b0011,
    POP             = 4'b0100,
    POP_WAIT        = 4'b0101,
    EXECUTE         = 4'b0110,
    STORE_RESULT    = 4'b0111,
    INT_ACK_WAIT    = 4'b1000,
    INT_INITIATE    = 4'b1001,
    INT_FETCH_VEC   = 4'b1010,
    INT_FETCH_WAIT1 = 4'b1011,
    INT_FETCH_WAIT2 = 4'b1100,
    INT_PUSH        = 4'b1101
} cpu_state_e /* verilator public */;

typedef enum bit [2:0] {
    INVALID       = 3'b000,
    INIT          = 3'b001,
    WAIT_OPCODE   = 3'b010,
    WAIT_OPERANDS = 3'b011,
    DECODED       = 3'b100
} decode_stage_e /* verilator public */;

typedef enum bit [2:0] {
    REPEAT_NONE = 3'b000,
    REPEAT_C    = 3'b001,
    REPEAT_NC   = 3'b010,
    REPEAT_Z    = 3'b011,
    REPEAT_NZ   = 3'b100
} repeat_e /* verilator public */;

typedef enum bit [1:0] {
    T_1    = 2'b00,
    T_2    = 2'b01,
    T_IDLE = 2'b10
} bcu_t_state_e /* verilator public */;

typedef enum bit [2:0] {
    INT_ACK1  = 3'b000,
    INT_ACK2  = 3'b001,
    IO_READ   = 3'b010,
    IO_WRITE  = 3'b011,
    HALT_ACK  = 3'b100,
    IPQ_FETCH = 3'b101,
    MEM_READ  = 3'b110,
    MEM_WRITE = 3'b111
} bcu_cycle_type_e /* verilator public */;

