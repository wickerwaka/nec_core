#include "v33.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

VerilatedContext *contextp;
v33 *top;
VerilatedVcdC *tfp;

constexpr size_t MEM_SIZE = 64 * 1024;

uint8_t memory[MEM_SIZE];

uint16_t read_mem(uint32_t addr, bool ube)
{
    uint32_t aligned_addr = (addr & ~1) % MEM_SIZE;
    return memory[aligned_addr] | (memory[aligned_addr + 1] << 8);
}

void tick(int count = 1)
{
    for( int i = 0; i < count; i++ )
    {
        if (top->n_dstb)
        {
            if (top->r_w && top->m_io)
            {
                top->din = read_mem(top->addr, (~top->n_ube) & 1);
            }
        }

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
    top = new v33{contextp};

    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("v33.vcd");

    memory[0xfff0] = 0xb0;
    memory[0xfff1] = 0xde;
    memory[0xfff2] = 0xb8;
    memory[0xfff3] = 0xbe;
    memory[0xfff4] = 0xef;

    top->ce_1 = 0;
    top->ce_2 = 1;

    top->reset = 1;
    tick(10);
    top->reset = 0;

    tick(200);

    top->final();
    tfp->close();

    delete top;
    delete contextp;
    return 0;
}