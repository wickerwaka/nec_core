`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module V33(
    input               clk,
    input               ce_1,
    input               ce_2,


    // Pins
    input               reset,
    input               hldrq,
    input               n_ready,
    input               bs16,

    output              hldak,
    output              n_buslock,
    output              n_ube,
    output              r_w,
    output              m_io,
    output              busst0,
    output              busst1,
    output              aex,
    output              n_bcyst,
    output              n_dstb,

    input               intreq,
    input               n_nmi,

    input               n_cpbusy,
    input               n_cperr,
    input               cpreq,

    output      [23:0]  addr,
    output      [15:0]  dout,
    input       [15:0]  din
);

// Register file
// Segment registers
reg [15:0] reg_ds0, reg_ds1, reg_ss, reg_ps;
// General purpose
reg [15:0] reg_aw, reg_bw, reg_cw, reg_dw;
reg [15:0] reg_sp, reg_bp, reg_ix, reg_iy;

// Data Pointer operations
reg [15:0] dp_addr;
reg [15:0] dp_dout;
wire [15:0] dp_din;
sreg_index_e dp_sreg;
reg dp_write;
reg dp_wide;
reg dp_io;
reg dp_req;
wire dp_ready;

// Instruction prefetch
reg [15:0] pfp_new;
reg pfp_set;
reg [3:0] ipq_consume;
wire [3:0] ipq_used;
wire [7:0] ipq[8];

function bit [15:0] calc_ea(bit [2:0] mem, bit [1:0] mod, bit [15:0] disp);
    bit [15:0] addr;
    case(mem)
    3'b000: addr = reg_bw + reg_ix;
    3'b001: addr = reg_bw + reg_iy;
    3'b010: addr = reg_bp + reg_ix;
    3'b011: addr = reg_bp + reg_iy;
    3'b100: addr = reg_ix;
    3'b101: addr = reg_iy;
    3'b110: addr = mod == 0 ? disp : reg_bp;
    3'b111: addr = reg_bw;
    endcase

    if (mod == 2'b01) addr = addr + { 8'd0, disp[7:0] };
    else if (mod == 2'b10) addr = addr + disp;

    return addr;
endfunction

bus_control_unit BCU(
    .clk, .ce_1, .ce_2,
    .reset, .hldrq, .n_ready, .bs16,
    .hldak, .n_buslock, .n_ube, .r_w,
    .m_io, .busst0, .busst1, .aex,
    .n_bcyst, .n_dstb,
    .addr, .dout, .din,

    .reg_ps, .reg_ss, .reg_ds0, .reg_ds1,

    .pfp_new, .pfp_set,
    .ipq_consume, .ipq_used, .ipq,

    .dp_addr, .dp_dout, .dp_din, .dp_sreg,
    .dp_write, .dp_wide, .dp_io, .dp_req,
    .dp_ready,

    .implementation_fault()
);

pre_decode pre_decode(
    .clk, .ce(ce_1),
    .q0(ipq[0]), .q1(ipq[1]), .q2(ipq[2]),
    .wide(pre_wide), .sign_extend(pre_sign_extend), .valid_op(pre_valid_op),
    .opcode(pre_opcode), .alu_operation(pre_alu_operation),
    .op_source(pre_op_source), .op_dest(pre_op_dest),
    .ea_mod(pre_ea_mod), .ea_mem(pre_ea_mem),
    .reg0(pre_reg0), .reg1(pre_reg1), .pre_size(pre_size)
);

always_ff @(posedge clk) begin
    if (reset) begin
        dp_req <= 0;
    end else if (ce_1) begin
    end
end
endmodule