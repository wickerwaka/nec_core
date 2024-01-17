module nec_decode(
    input clk,
    input ce,

    output reg [7:0] count
);

always_ff @(posedge clk) begin
    if (ce) begin
        count <= count + 8'd1;
    end
end

endmodule