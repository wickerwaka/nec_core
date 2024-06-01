#include "bus_control_unit.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

VerilatedContext *contextp;
bus_control_unit *top;
VerilatedVcdC *tfp;

void tick(int count = 1)
{
    for( int i = 0; i < count; i++ )
    {
        contextp->timeInc(1);
        top->clk = 0;

        top->eval();
        tfp->dump(contextp->time());

        contextp->timeInc(1);
        top->clk = 1;
        top->ce_1 = (~top->ce_1) & 1;
        top->ce_2 = (~top->ce_2) & 1;

        top->eval();
        tfp->dump(contextp->time());
    }
}

void tick_ce()
{
    tick(1);
    if (top->ce_1) tick(1);
}

int main(int argc, char **argv)
{
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    top = new bus_control_unit{contextp};

    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("bus_control.vcd");

    top->ready = 1;
    top->reg_ps = 0xffff;
    top->reg_ds0 = 0x1000;
    top->ipq_head = 0x0000;

    top->ce_1 = 0;
    top->ce_2 = 1;

    top->reset = 1;
    tick(10);
    top->reset = 0;

    tick_ce();
    tick_ce();

    top->dp_req = 1;
    top->dp_addr = 0x100;
    top->dp_io = 0;
    top->dp_write = 1;
    top->dp_wide = 1;
    top->dp_sreg = 3;

    tick(1);

    top->dp_req = 0;

    tick(9);

    top->dp_req = 1;
    top->dp_addr = 0x101;
    top->dp_io = 0;
    top->dp_write = 0;
    top->dp_wide = 1;
    top->dp_sreg = 3;

    tick(1);
    
    top->dp_req = 0;

    tick(9);
    tick_ce();
    top->ipq_head += 3;
    tick(20);

    top->final();
    tfp->close();

    delete top;
    delete contextp;
    return 0;
}