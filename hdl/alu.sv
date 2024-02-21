`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module alu(
    input clk,

    input alu_operation_e operation,
    input [15:0] ta,
    input [15:0] tb,
    input wide,
    output [31:0] result,

    output [5:0]  alu_cycles,

    input flags_t flags_in,
    output flags_t flags
);

always_comb begin
    bit calc_parity;
    bit calc_sign;
    bit calc_zero;
    flags_t fcalc;
    bit [15:0] res;
    bit [16:0] temp17;
    bit [16:0] temp17_2;
    bit [8:0] temp9;
    bit [31:0] result32;
    bit use_result32;
    bit [17:0] sh18;
    bit [33:0] sh34;
    bit [5:0] sz;
    bit [5:0] sz_inv;

    bit [15:0] bit_shift_mask;
    
    bit_shift_mask = 16'd1 << ( wide ? tb[3:0] : { 1'b0, tb[2:0] } );

    calc_parity = 0;
    calc_sign = 0;
    calc_zero = 0;
    use_result32 = 0;
    result32 = 32'd0;
    res = 16'd0;
    temp17 = 17'd0;
    temp9 = 9'd0;
    temp17_2 = 17'd0;
    sz = 6'd0;
    sz_inv = 6'd0;
    sh18 = 18'd0;
    sh34 = 34'd0;

    flags = flags_in;

    alu_cycles = 0;

    case(operation)
    ALU_OP_ADD, ALU_OP_ADDC, ALU_OP_INC: begin
        if (operation == ALU_OP_INC)
            temp17 = 17'd1;
        else if (operation == ALU_OP_ADDC)
            temp17 = { 1'b0, tb } + { 16'd0, flags_in.CY };
        else
            temp17 = { 1'b0, tb };
        
        temp17_2 = { 1'b0, ta } + temp17;
        res = temp17_2[15:0];

        if (operation != ALU_OP_INC)
            flags.CY = wide ? temp17_2[16] : temp17_2[8];
        
        flags.AC = ( {1'b0, temp17[3:0]} + {1'b0, ta[3:0]} ) > 5'd15 ? 1 : 0;

        if (wide)
            flags.V = (ta[15] ^ res[15]) & (temp17[15] ^ res[15]);
        else
            flags.V = (ta[7] ^ res[7]) & (temp17[7] ^ res[7]);

        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SUB, ALU_OP_CMP, ALU_OP_DEC, ALU_OP_SUBC: begin
        if (operation == ALU_OP_DEC)
            temp17 = 17'd1;
        else if (operation == ALU_OP_SUBC)
            temp17 = {1'b0, tb} + { 16'd0, flags_in.CY };
        else
            temp17 = {1'b0, tb};

        temp17_2 = ta - temp17;
        res = temp17_2[15:0];

        if (operation != ALU_OP_DEC)
            flags.CY = temp17 > {1'b0, ta} ? 1 : 0;

        flags.AC = temp17_2[3:0] > ta[3:0] ? 1 : 0;

        if (wide)
            flags.V = (ta[15] ^ temp17[15]) & (ta[15] ^ res[15]);
        else
            flags.V = (ta[7] ^ temp17[7]) & (ta[7] ^ res[7]);
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_AND: begin
        res = ta & tb;
        flags.CY = 0;
        flags.V = 0;
        flags.AC = 0;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end
    
    ALU_OP_OR: begin
        res = ta | tb;
        flags.CY = 0;
        flags.V = 0;
        flags.AC = 0;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end
    
    ALU_OP_XOR: begin
        res = ta ^ tb;
        flags.CY = 0;
        flags.V = 0;
        flags.AC = 0;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_NOT: begin
        res = ~ta;
    end

    ALU_OP_NEG: begin
        res = (~ta) + 16'd1;
        flags.CY = ta != 16'd0 ? 1 : 0;
        
        // TODO - MAME doesn't update these flags, but documentation says it should
        //flags.AC = ta[3:0] > 4'd0 ? 1 : 0;   
        //flags.V = 0;
        //if (wide && ta == 16'h8000) flags.V = 1;
        //if (~wide && ta[7:0] == 8'h80) flags.V = 1;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SET1: begin
        res = ta | bit_shift_mask;
    end
    ALU_OP_CLR1: begin
        res = ta & ~bit_shift_mask;
    end

    ALU_OP_TEST1: begin
        res = ta & bit_shift_mask;
        
        flags.CY = 0;
        flags.V = 0;

        calc_zero = 1;
    end

    ALU_OP_NOT1: begin
        res = ta ^ bit_shift_mask;
    end
    
    ALU_OP_ADJ4A: begin 
        temp9 = { 1'b0, ta[7:0] };
        flags.CY = 0;

        if (flags_in.AC || ta[3:0] > 4'h9) begin
            temp9 = temp9 + 9'd06;
            flags.AC = 1;
            flags.CY = flags_in.CY | temp9[8];
        end else begin
            flags.AC = 0;
        end

        if (flags_in.CY || ta[7:0] > 8'h99) begin
            temp9 = temp9 + 9'h60;
            flags.CY = 1;
        end else begin
            flags.CY = 0;
        end
        res = { 8'd0, temp9[7:0] };
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_ADJ4S: begin 
        temp9 = { 1'b0, ta[7:0] };
        flags.CY = 0;

        if (flags_in.AC || ta[3:0] > 4'h9) begin
            temp9 = temp9 - 9'd06;
            flags.AC = 1;
            flags.CY = flags_in.CY | temp9[8];
        end else begin
            flags.AC = 0;
        end

        if (flags_in.CY || ta[7:0] > 8'h99) begin
            temp9 = temp9 - 9'h60;
            flags.CY = 1;
        end else begin
            flags.CY = 0;
        end
        res = { 8'd0, temp9[7:0] };
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_ADJBA: begin
        if (flags_in.AC || ta[3:0] > 4'h9) begin
                        res = ta + 16'h0106;
                        flags.AC = 1;
            flags.CY = 1;
        end else begin
            res = ta;
            flags.AC = 0;
            flags.CY = 0;
        end
        res[7:4] = 4'd0;
    end 

    ALU_OP_ADJBS: begin
        if (flags_in.AC || ta[3:0] > 4'h9) begin
            res = ta - 16'h0006;
            res[15:7] = res[15:7] - 8'h1;
            flags.AC = 1;
            flags.CY = 1;
        end else begin
            res = ta;
            flags.AC = 0;
            flags.CY = 0;
        end
        res[7:4] = 4'd0;
    end 

    ALU_OP_ROL: begin
        sz[3:0] = tb[3:0];
        temp17 = { flags_in.CY, ta } << sz;
        if (wide) begin
            res = (ta << sz[3:0]) | (ta >> (5'd16 - sz[3:0]));
            flags.CY = temp17[16];
            alu_cycles = { 2'd0, tb[3:0] };
        end else begin
            res[7:0] = (ta[7:0] << sz[2:0]) | (ta[7:0] >> (4'd8 - sz[2:0]));
            flags.CY = temp17[8];
            alu_cycles = { 3'd0, tb[2:0] };
        end
    end

    ALU_OP_ROL1: begin
        if (wide) begin
            res = {ta[14:0], ta[15]};
            flags.CY = ta[15];
            flags.V = ta[15] ^ ta[14];
        end else begin
            res[7:0] = {ta[6:0], ta[7]};
            flags.CY = ta[7];
            flags.V = ta[7] ^ ta[6];
        end
    end

    // TODO: how does real hardware deal with shift values > 31 ?
    ALU_OP_ROLC: begin
        if (wide) begin
            sz = { 1'b0, tb[4:0] };
            sz_inv = 6'd34 - sz;
            sh34 = { flags.CY, ta, flags.CY, ta };
            sh34 = (sh34 << sz) | (sh34 >> sz_inv);
            res = sh34[15:0];
            flags.CY = sh34[16];
            alu_cycles = { 1'd0, tb[4:0] };
        end else begin
            sz = { 2'b00, tb[3:0] };
            sz_inv = 6'd18 - sz;
            sh18 = { flags.CY, ta[7:0], flags.CY, ta[7:0] };
            sh18 = (sh18 << sz) | (sh18 >> sz_inv);
            res[7:0] = sh18[7:0];
            flags.CY = sh18[8];
            alu_cycles = { 2'd0, tb[3:0] };
        end
    end

    ALU_OP_ROLC1: begin
        if (wide) begin
            res = {ta[14:0], flags_in.CY};
            flags.CY = ta[15];
            flags.V = ta[15] ^ ta[14];
        end else begin
            res[7:0] = {ta[6:0], flags_in.CY};
            flags.CY = ta[7];
            flags.V = ta[7] ^ ta[6];
        end
    end

    ALU_OP_ROR: begin
        sz[3:0] = tb[3:0];
        temp17 = { ta, flags_in.CY } >> sz;
        flags.CY = temp17[0];
        if (wide) begin
            res = (ta >> sz[3:0]) | (ta << (5'd16 - sz[3:0]));
            alu_cycles = { 2'd0, tb[3:0] };
        end else begin
            res[7:0] = (ta[7:0] >> sz[2:0]) | (ta[7:0] << (4'd8 - sz[2:0]));
            alu_cycles = { 3'd0, tb[2:0] };
        end
    end

    ALU_OP_ROR1: begin
        flags.CY = ta[0];
        if (wide) begin
            res = {ta[0], ta[15:1]};
            flags.V = ta[15] ^ ta[0];
        end else begin
            res[7:0] = {ta[0], ta[7:1]};
            flags.V = ta[7] ^ ta[0];
        end
    end

    ALU_OP_RORC: begin
        if (wide) begin
            sz = { 1'b0, tb[4:0] };
            sz_inv = 6'd34 - sz;
            sh34 = { flags.CY, ta, flags.CY, ta };
            sh34 = (sh34 >> sz) | (sh34 << sz_inv);
            res = sh34[15:0];
            flags.CY = sh34[16];
            alu_cycles = { 1'd0, tb[4:0] };
        end else begin
            sz = { 2'b00, tb[3:0] };
            sz_inv = 6'd18 - sz;
            sh18 = { flags.CY, ta[7:0], flags.CY, ta[7:0] };
            sh18 = (sh18 >> sz) | (sh18 << sz_inv);
            res[7:0] = sh18[7:0];
            flags.CY = sh18[8];
            alu_cycles = { 2'd0, tb[3:0] };
        end
    end

    ALU_OP_RORC1: begin
        flags.CY = ta[0];
        if (wide) begin
            res = {flags_in.CY, ta[15:1]};
            flags.V = ta[15] ^ flags_in.CY;
        end else begin
            res[7:0] = {flags_in.CY, ta[7:1]};
            flags.V = ta[7] ^ flags_in.CY;
        end
    end

    ALU_OP_SHL: begin
        temp17 = { 1'b0, ta } << tb[4:0];
        if (wide) begin
            flags.CY = temp17[16];
        end else begin
            flags.CY = temp17[8];
        end
        res = temp17[15:0];
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SHL1: begin
        if (wide) begin
            flags.CY = ta[15];
            flags.V = ta[15] ^ ta[14];
            res = { ta[14:0], 1'b0 };
        end else begin
            flags.CY = ta[7];
            flags.V = ta[7] ^ ta[6];
            res[7:0] = { ta[6:0], 1'b0 };
        end
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SHR: begin
        temp17 = { ta, 1'b0 } >> tb[4:0];
        if (~wide) begin
            flags.CY = temp17[0];
        end else begin
            flags.CY = temp17[0];
        end
        res = temp17[16:1];
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SHR1: begin
        if (wide) begin
            flags.CY = ta[0];
            flags.V = ta[15];
            res = { 1'b0, ta[15:1] };
        end else begin
            flags.CY = ta[0];
            flags.V = ta[7];
            res[7:0] = { 1'b0, ta[7:1] };
        end
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SHRA: begin
        flags.V = 0;
        if (~wide) begin
            temp17 = $signed({ {8{ta[7]}}, ta[7:0], flags_in.CY }) >>> tb[4:0];
            flags.CY = temp17[0];
        end else begin
            temp17 = $signed({ ta, flags_in.CY }) >>> tb[4:0];
            flags.CY = temp17[0];
        end
        res = temp17[16:1];
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SHRA1: begin
        if (wide) begin
            flags.CY = ta[0];
            flags.V = 0;
            res = { ta[15], ta[15:1] };
        end else begin
            flags.CY = ta[0];
            flags.V = 0;
            res[7:0] = { ta[7], ta[7:1] };
        end
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_MULU: begin
        flags.CY = 0;
        flags.V = 0;
        use_result32 = 1;
        result32 = ta * tb;
        if (wide) begin
            flags.CY = |result32[31:16];
            flags.V = |result32[31:16];
        end else begin
            flags.CY = |result32[31:8];
            flags.V = |result32[31:8];
        end
    end
    
    ALU_OP_MUL: begin 
        flags.CY = 0;
        flags.V = 0;

        use_result32 = 1;

        if (wide) begin
            result32 = $signed(ta) * $signed(tb);
            if (16'd0 != result32[31:16]) begin
                flags.CY = 1;
                flags.V = 1;
            end
        end else begin
            result32[15:0] = $signed(ta[7:0]) * $signed(tb[7:0]);
            if (8'd0 != result32[15:8]) begin
                flags.CY = 1;
                flags.V = 1;
            end
        end
    end                              

    default: begin end
    endcase

    if (use_result32) begin
        result = result32;
    end else begin
        if (calc_parity) flags.P = ~(res[0] ^ res[1] ^ res[2] ^ res[3] ^ res[4] ^ res[5] ^ res[6] ^ res[7]);
        if (calc_sign) flags.S = wide ? res[15] : res[7];
        if (calc_zero) flags.Z = wide ? res[15:0] == 16'd0 : res[7:0] == 8'd0;

        result = { 16'd0, wide ? res[15:0] : { 8'd0, res[7:0] } };
    end
end

endmodule
