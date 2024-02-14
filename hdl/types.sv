package types;
    `include "enums.svh"
    
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
    } nec_decode_t;

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
