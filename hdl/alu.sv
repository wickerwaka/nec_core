`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module alu(
    input clk,
    input ce,

    input reset,

    input alu_operation_e operation,
    input [15:0] ta,
    input [15:0] tb,
    input wide,
    output reg [15:0] result,

    input flags_t flags_in,
    output flags_t flags,

    input execute,
    output busy
);

reg executing = 0;

assign busy = execute | executing;

/*

                           when ALU_OP_ROR4 =>
                              result := x"00" & regs.reg_ax(3 downto 0) & source1Val(7 downto 4);
                              regs.reg_ax(7 downto 0) <= regs.reg_ax(7 downto 4) & source1Val(3 downto 0);

                           when ALU_OP_ROL4 =>
                              result := x"00" & source1Val(3 downto 0) & regs.reg_ax(3 downto 0);
                              regs.reg_ax(7 downto 0) <= regs.reg_ax(7 downto 4) & source1Val(7 downto 4);
                           
                           
                           
                           when ALU_OP_MUL =>
                              regs.FlagCar <= '0'; regs.FlagOvf <= '0';
                              if (opsize = 1) then
                                 result32 := resize(source1Val(7 downto 0) * memFetchValue2, 32);
                                 regs.reg_ax <= result32(15 downto 0);
                                 if (result32(31 downto 8) /= x"000000") then
                                    regs.FlagCar <= '1'; regs.FlagOvf <= '1';
                                 end if;
                              else
                                 result32 := source1Val * memFetchValue2;
                                 regs.reg_ax <= result32(15 downto 0);
                                 regs.reg_dx <= result32(31 downto 16);
                                 if (result32(31 downto 16) /= x"0000") then
                                    regs.FlagCar <= '1'; regs.FlagOvf <= '1';
                                 end if;
                              end if;
                           
                           when ALU_OP_MULI => 
                              regs.FlagCar <= '0'; regs.FlagOvf <= '0';
                              if (opsize = 1) then
                                 result32 := unsigned(to_signed(to_integer(signed(source1Val(7 downto 0))) * to_integer(signed(memFetchValue2(7 downto 0))), 32));
                                 if (opcode = OP_NOP) then regs.reg_ax <= result32(15 downto 0); end if;
                                 if (result32(31 downto 8) /= x"000000") then
                                    regs.FlagCar <= '1'; regs.FlagOvf <= '1';
                                 end if;
                              else
                                 if (source1 = OPSOURCE_FETCHVALUE8) then
                                    result32 := unsigned(to_signed(to_integer(signed(source1Val(7 downto 0))) * to_integer(signed(memFetchValue2)), 32));
                                 else
                                    result32 := unsigned(to_signed(to_integer(signed(source1Val)) * to_integer(signed(memFetchValue2)), 32));
                                 end if;
                                 if (opcode = OP_NOP) then
                                    regs.reg_ax <= result32(15 downto 0);
                                    regs.reg_dx <= result32(31 downto 16);
                                 end if;
                                 if (result32(31 downto 16) /= x"0000") then
                                    regs.FlagCar <= '1'; regs.FlagOvf <= '1';
                                 end if;
                              end if;
                              result := result32(15 downto 0);                              
*/

always_ff @(posedge clk) begin
    bit done = 0;
    bit calc_parity = 0;
    bit calc_sign = 0;
    bit calc_zero = 0;
    flags_t fcalc;
    bit [15:0] res;
    bit [16:0] temp17;
    bit [15:0] temp1;
    bit [8:0] temp9;

    bit [15:0] bit_shift_mask = 16'd1 << ( wide ? tb[3:0] : { 1'b0, tb[2:0] } );

    if (reset) begin
        executing <= 0;
    end else if (ce) begin
        if (execute) begin
            executing <= 1;
            flags <= flags_in;

            case(operation)
            ALU_OP_ADD, ALU_OP_ADDC, ALU_OP_INC: begin
                if (operation == ALU_OP_INC)
                    temp1 = 16'd1;
                else if (operation == ALU_OP_ADDC)
                    temp1 = tb + { 15'd0, flags_in.CY };
                else
                    temp1 = tb;
                
                temp17 = { 1'b0, ta } + { 1'b0, temp1 };

                if (operation != ALU_OP_INC)
                    flags.CY <= wide ? temp17[16] : temp17[8];
                
                flags.AC <= ( {1'b0, temp1[3:0]} + {1'b0, ta[3:0]} ) > 5'd16 ? 1 : 0;

                res = temp17[15:0];

                if (wide)
                    flags.V <= (ta[15] ^ res[15]) & (temp1[15] ^ res[15]);
                else
                    flags.V <= (ta[7] ^ res[7]) & (temp1[7] ^ res[7]);

                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end

            ALU_OP_SUB, ALU_OP_CMP, ALU_OP_DEC, ALU_OP_SUBC: begin
                if (operation == ALU_OP_DEC)
                    temp1 = 16'd1;
                else if (operation == ALU_OP_SUBC)
                    temp1 = tb + { 15'd0, flags_in.CY };
                else
                    temp1 = tb;

                res = ta - temp1;

                if (operation != ALU_OP_DEC)
                    flags.CY <= temp1 > ta ? 1 : 0;

                flags.AC <= temp1[3:0] > ta[3:0] ? 1 : 0;

                if (wide)
                    flags.V <= (ta[15] ^ temp1[15]) & (ta[15] ^ res[15]);
                else
                    flags.V <= (ta[7] ^ temp1[7]) & (ta[7] ^ res[7]);
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end

            ALU_OP_AND: begin
                res = ta & tb;
                flags.CY <= 0;
                flags.V <= 0;
                flags.AC <= 0;
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end
            
            ALU_OP_OR: begin
                res = ta | tb;
                flags.CY <= 0;
                flags.V <= 0;
                flags.AC <= 0;
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end
            
            ALU_OP_XOR: begin
                res = ta ^ tb;
                flags.CY <= 0;
                flags.V <= 0;
                flags.AC <= 0;
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end

            ALU_OP_NOT: begin
                res = ~ta;
                done = 1;
            end

            ALU_OP_NEG: begin
                res = 16'd0 - ta;
                flags.CY <= ta > 'd0 ? 1 : 0;
                flags.AC <= ta[3:0] > 'd0 ? 1 : 0;   

                flags.V <= 0;
                if (wide && ta == 16'h8000) flags.V <= 1;
                if (~wide && ta[7:0] == 8'h80) flags.V <= 1;
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end

            ALU_OP_SET1: begin
                res = ta | bit_shift_mask;
                done = 1;
            end
            ALU_OP_CLR1: begin
                res = ta & ~bit_shift_mask;
                done = 1;
            end

            ALU_OP_TEST1: begin
                res = ta & bit_shift_mask;
                
                flags.CY <= 0;
                flags.V <= 0;

                calc_zero = 1;
                done = 1;
            end

            ALU_OP_NOT1: begin
                res = ta ^ bit_shift_mask;
                done = 1;
            end
            
            ALU_OP_ADJ4A: begin 
                temp9 = { 1'b0, ta[7:0] };
                flags.CY <= 0;

                if (flags_in.AC || ta[3:0] > 4'h9) begin
                    temp9 = temp9 + 9'd06;
                    flags.AC <= 1;
                    flags.CY <= flags_in.CY | temp9[8];
                end else begin
                    flags.AC <= 0;
                end

                if (flags_in.CY || ta[7:0] > 8'h99) begin
                    temp9 = temp9 + 9'h60;
                    flags.CY <= 1;
                end else begin
                    flags.CY <= 0;
                end
                res = { 8'd0, temp9[7:0] };
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end

            ALU_OP_ADJ4S: begin 
                temp9 = { 1'b0, ta[7:0] };
                flags.CY <= 0;

                if (flags_in.AC || ta[3:0] > 4'h9) begin
                    temp9 = temp9 - 9'd06;
                    flags.AC <= 1;
                    flags.CY <= flags_in.CY | temp9[8];
                end else begin
                    flags.AC <= 0;
                end

                if (flags_in.CY || ta[7:0] > 8'h99) begin
                    temp9 = temp9 - 9'h60;
                    flags.CY <= 1;
                end else begin
                    flags.CY <= 0;
                end
                res = { 8'd0, temp9[7:0] };
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
                done = 1;
            end

            ALU_OP_ADJBA: begin
                if (flags_in.AC || ta[3:0] > 4'h9) begin
                    res = ta + 16'h0106;
                    flags.AC <= 1;
                    flags.CY <= 1;
                end else begin
                    res = ta;
                    flags.AC <= 0;
                    flags.CY <= 0;
                end
                res[7:4] = 4'd0;
                done = 1;
            end 

            ALU_OP_ADJBS: begin
                if (flags_in.AC || ta[3:0] > 4'h9) begin
                    res = ta - 16'h0006;
                    res[15:7] = res[15:7] - 8'h1;
                    flags.AC <= 1;
                    flags.CY <= 1;
                end else begin
                    res = ta;
                    flags.AC <= 0;
                    flags.CY <= 0;
                end
                res[7:4] = 4'd0;
                done = 1;
            end 

            ALU_OP_ROL: begin
                bit [4:0] sz;
                sz = tb[4:0];
                temp17 = { 1'b0, ta } << sz;
                if (wide) begin
                    res = (ta << sz[3:0]) | (ta >> ~sz[3:0]);
                    flags.CY <= temp17[16];
                    flags.V <= ta[15] ^ res[15];
                end else begin
                    res[7:0] = (ta[7:0] << sz[2:0]) | (ta[7:0] >> ~sz[2:0]);
                    flags.CY <= temp17[8];
                    flags.V <= ta[7] ^ res[7];
                end
            end

            ALU_OP_ROLC: begin
                bit [33:0] sh34;
                bit [17:0] sh18;
                bit [5:0] sz;
                bit [5:0] sz_inv;
                if (wide) begin
                    sz = { 1'b0, tb[4:0] };
                    sz_inv = 6'd34 - sz;
                    sh34 = { flags.CY, ta, flags.CY, ta };
                    sh34 = (sh34 << sz) | (sh34 >> sz_inv);
                    res = sh34[15:0];
                    flags.CY <= sh34[16];
                    flags.V <= ta[15] ^ res[15];
                end else begin
                    sz = { 2'b00, tb[3:0] };
                    sz_inv = 6'd18 - sz;
                    sh18 = { flags.CY, ta[7:0], flags.CY, ta[7:0] };
                    sh18 = (sh18 << sz) | (sh18 >> sz_inv);
                    res[7:0] = sh18[7:0];
                    flags.CY <= sh18[8];
                    flags.V <= ta[7] ^ res[7];
                end
            end

            ALU_OP_ROR: begin
                bit [4:0] sz;
                sz = tb[4:0];
                temp17 = { ta, 1'b0 } >> sz;
                flags.CY <= temp17[0];
                if (wide) begin
                    res = (ta >> sz[3:0]) | (ta << ~sz[3:0]);
                    flags.V <= ta[15] ^ res[15];
                end else begin
                    res[7:0] = (ta[7:0] >> sz[2:0]) | (ta[7:0] << ~sz[2:0]);
                    flags.V <= ta[7] ^ res[7];
                end
            end

            ALU_OP_RORC: begin
                bit [33:0] sh34;
                bit [17:0] sh18;
                bit [5:0] sz;
                bit [5:0] sz_inv;
                if (wide) begin
                    sz = { 1'b0, tb[4:0] };
                    sz_inv = 6'd34 - sz;
                    sh34 = { flags.CY, ta, flags.CY, ta };
                    sh34 = (sh34 >> sz) | (sh34 << sz_inv);
                    res = sh34[15:0];
                    flags.CY <= sh34[16];
                    flags.V <= ta[15] ^ res[15];
                end else begin
                    sz = { 2'b00, tb[3:0] };
                    sz_inv = 6'd18 - sz;
                    sh18 = { flags.CY, ta[7:0], flags.CY, ta[7:0] };
                    sh18 = (sh18 >> sz) | (sh18 << sz_inv);
                    res[7:0] = sh18[7:0];
                    flags.CY <= sh18[8];
                    flags.V <= ta[7] ^ res[7];
                end
            end

            ALU_OP_SHL: begin
                temp17 = { 1'b0, ta } << ta[4:0];
                if (wide) begin
                    flags.CY <= temp17[16];
                    flags.V <= ta[15] ^ temp17[15];
                end else begin
                    flags.CY <= temp17[8];
                    flags.V <= ta[7] ^ temp17[7];
                end
                res = temp17[15:0];
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
            end

            ALU_OP_SHR: begin
                temp17 = { ta, 1'b0 } >> ta[4:0];
                if (~wide) begin
                    flags.CY <= temp17[0];
                    flags.V <= ta[7] ^ temp17[8];
                end else begin
                    flags.CY <= temp17[0];
                    flags.V <= ta[15] ^ temp17[16];
                end
                res = temp17[16:1];
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
            end

            ALU_OP_SHRA: begin
                flags.V <= 0;
                if (~wide) begin
                    temp17 = { {8{ta[7]}}, ta[7:0], 1'b0 } >>> ta[4:0];
                    flags.CY <= temp17[0];
                end else begin
                    temp17 = { ta, 1'b0 } >>> ta[4:0];
                    flags.CY <= temp17[0];
                end
                res = temp17[16:1];
                calc_parity = 1; calc_sign = 1; calc_zero = 1;
            end

            default: executing <= 0;
            endcase
        end else if (executing) begin
            executing <= 0;
        end

        if (done) begin
            executing <= 0;
            if (calc_parity) flags.P <= res[0] ^ res[1] ^ res[2] ^ res[3] ^ res[4] ^ res[5] ^ res[6] ^ res[7];
            if (calc_sign) flags.S <= wide ? res[15] : res[7];
            if (calc_zero) flags.Z <= wide ? res[15:0] == 16'd0 : res[7:0] == 8'd0;

            result <= wide ? res[15:0] : { 8'd0, res[7:0] };
        end
    end
end

endmodule
