// Based on:
// Project F Library - Division: Unsigned Integer with Remainder
// (C)2023 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io/verilog-lib/

// Adapted to specific needs of NEC Vxx CPUs
// 32 bit and 16 bit modes
// Clock enable
// overflow detection
// signed support
`default_nettype none

module nec_divider(
    input wire logic clk,           // clock
    input wire logic ce,            // clock enable
    input wire logic reset,         // reset
    input wire logic start,         // start calculation
    input wire logic wide,          // 32 / 16
    output     logic done,          // calculation is complete (high for one tick)
    output     logic overflow,      // result overflowed
    output     logic dbz,           // divide by zero
    input wire logic [32:0] a,      // dividend (numerator), signed
    input wire logic [32:0] b,      // divisor (denominator), signed
    output     logic [15:0] quot,   // result value: quotient
    output     logic [15:0] rem     // result: remainder
);

logic busy;
logic [31:0] b1;             // copy of divisor
logic [31:0] quo, quo_next;  // intermediate quotient
logic [32:0] acc, acc_next;    // accumulator (1 bit wider)
int i;                            // iteration counter

// division algorithm iteration
always_comb begin
    if (acc >= {1'b0, b1}) begin
        acc_next = acc - b1;
        {acc_next, quo_next} = {acc_next[31:0], quo, 1'b1};
    end else begin
        {acc_next, quo_next} = {acc, quo} << 1;
    end
end

// calculation control
always_ff @(posedge clk) begin
    if (ce) begin
        done <= 0;
        if (start) begin
            overflow <= 0;
            i <= 0;
            if (b == 0) begin  // catch divide by zero
                busy <= 0;
                done <= 1;
                dbz <= 1;
            end else begin
                busy <= 1;
                dbz <= 0;
                if (wide) begin
                    b1 <= b[32] ? -b[31:0] : b[31:0];
                    {acc, quo} <= {{32{1'b0}}, (a[32] ? -a[31:0] : a[31:0]), 1'd0};  // initialize calculation
                end else begin
                    b1 <= { b[32] ? -b[15:0] : b[15:0], 16'd0 }; 
                    {acc, quo} <= {{32{1'b0}}, (a[32] ? -a[15:0] : a[15:0]), 17'd0};  // initialize calculation
                end
            end
        end else if (busy) begin
            if (i == (wide ? 31 : 31)) begin  // we're done
                busy <= 0;
                done <= 1;
                if (wide) begin
                    overflow <= |quo_next[31:16];
                    if (a[32]) rem <= -(acc_next[16:1]);
                    else rem <= acc_next[16:1];
                end else begin
                    overflow <= |quo_next[31:8];
                    if (a[32]) rem <= -(acc_next[32:17]);
                    else rem <= acc_next[32:17];
                end

                quot <= quo_next[15:0];
                if (a[32] ^ b[32]) quot <= -(quo_next[15:0]);

            end else begin  // next iteration
                i <= i + 1;
                acc <= acc_next;
                quo <= quo_next;
            end
        end
    end // ce
    if (reset) begin
        busy <= 0;
        done <= 0;
        overflow <= 0;
        dbz <= 0;
        quot <= 0;
        rem <= 0;
    end
end

endmodule

/*
MIT License

Copyright (c) 2023 Will Green, Project F

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/