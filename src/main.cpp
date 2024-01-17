#include "nec_core.h"
#include "verilated.h"

int main(int argc, char **argv)
{
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    nec_core *top = new nec_core{contextp};
    top->ce = 1;
    while (!contextp->gotFinish())
    {
        top->clk = ~top->clk;
        top->eval();
        printf("%d\n", top->count);
    }
    delete top;
    delete contextp;
    return 0;
}