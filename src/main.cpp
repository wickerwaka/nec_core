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

    memory[0xfff0] = 0xb8;
    memory[0xfff1] = 0x41;
    memory[0xfff2] = 0x00;
    memory[0xfff3] = 0x01;
    memory[0xfff4] = 0xc0;
    memory[0xfff5] = 0x83;
    memory[0xfff6] = 0xc0;
    memory[0xfff7] = 0x03;
    memory[0xfff8] = 0x83;
    memory[0xfff9] = 0xc0;
    memory[0xfffa] = 0x01;
    memory[0xfffb] = 0x75;
    memory[0xfffc] = 0xfb;

    top->ce_1 = 0;
    top->ce_2 = 1;

    top->reset = 1;
    tick(10);
    top->reset = 0;

    tick(400);

    top->final();
    tfp->close();

    delete top;
    delete contextp;
    return 0;
}