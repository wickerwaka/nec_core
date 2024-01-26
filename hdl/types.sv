package types;
    typedef enum bit [1:0] {DS1, PS, SS, DS0} sreg_index_e;
    typedef enum bit [2:0] {AL, CL, DL, BL, AH, CH, DH, BH} reg8_index_e;
    typedef enum bit [2:0] {AW, CW, DW, BW, SP, BP, IX, IY} reg16_index_e;

    typedef enum {
        OP_ADD,
        OP_ADD4S
    } opcode_e;

    typedef enum {
        ALU_OP_NONE,
        ALU_OP_ADD
    } alu_operation_e;

    typedef enum {
        OP_DST_ACC,
        OP_DST_MEM,
        OP_DST_REG0,
        OP_DST_REG1
    } op_dst_e;

    typedef enum {
        OP_SRC_IMM,
        OP_SRC_MEM,
        OP_SRC_REG0,
        OP_SRC_REG1
    } op_src_e;


endpackage
