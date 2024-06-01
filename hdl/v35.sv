`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module V35(
    input               clk,


    input               ce_1, // X1
    input               ce_2, // X2


    input               n_reset,


    // A0-19
    output      [19:0]  addr,


    // Memory access signals
    output              r_w,
    output              n_ube,
    output              n_iostb,
    output              n_mreq,
    output              n_mstb,


    // Bus Control
    input               ready,
    input               n_poll, 

    //input               n_ea,

    //output              n_hldak,
    //input               hldrq,
    //output              n_refrq,



    // D0-15
    output      [15:0]  dout,
    input       [15:0]  din,


    // PORTS
    output       [7:0]  p0out,
    input        [7:0]  p0in,
    output       [7:0]  p1out,
    input        [7:0]  p1in,
    output       [7:0]  p2out,
    input        [7:0]  p2in,


    // Analog Comparator
    //input        [7:0]  ptin,


    // Clock Outputs
    //output              clkout,
    //output              tout,


    // Serial
    //input               n_cts0,
    //input               n_cts1,
    //input               rxd0,
    //input               rxd1,
    //output              txd0,
    //output              txd1,
    //output              n_sck0,


    // DMA
    //output              n_dmaak0,
    //output              n_dmaak1,
    //input               dmarq0,
    //input               dmarq1,
    //output              n_tc0,
    //output              n_tc1,


    // Interrupts
    input               intreq, // INT
    output              n_intak,

    input               n_intp0,
    input               n_intp1,
    input               n_intp2,

    input               nmi,


    // Non-hardware
    input               turbo
);

endmodule
