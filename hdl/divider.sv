module divider2(
    input clk,
    input ce,
    input reset,
    input start,
    output reg done,
    output valid,
    output dbz,
    input wide,
    input is_signed,
    input [31:0] num,
    input [31:0] denom,
    output [31:0] quot,
    output [31:0] rem
);

reg [31:0] div_num, div_denom, div_quot, div_rem;

reg div_start;
wire div_done;

divu_int #(.WIDTH(32)) divu(
    .clk, .rst(reset),
    .valid, .dbz, .busy(),
    .start(div_start),
    .done(div_done),
    .a(div_num),
    .b(div_denom),
    .val(div_quot),
    .rem(div_rem)
);

always_ff @(posedge clk) begin
    div_start <= 0;
    if (ce) begin
        if (start) begin
            div_num <= num[31] & is_signed ? -num : num;
            div_denom <= denom[31] & is_signed ? -denom : denom;
            div_start <= 1;
            done <= 0;
        end
    end

    if (div_done) begin
        done <= 1;
        quot <= div_quot;
        rem <= div_rem;
        if (is_signed) begin
            if (num[31] ^ denom[31]) quot <= -div_quot;
            if (num[31]) rem <= -rem;
        end
    end
end

endmodule
