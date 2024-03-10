#include "v33.h"
#include "v33___024root.h"
#include "v33_V33.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

VerilatedContext *contextp;
v33 *top;
VerilatedVcdC *tfp;

constexpr size_t RAM_SIZE = 1024 * 1024;

uint8_t ram[RAM_SIZE];

uint16_t read_mem(uint32_t addr, bool ube)
{
    uint32_t aligned_addr = (addr & ~1) % RAM_SIZE;
    return ram[aligned_addr] | (ram[aligned_addr + 1] << 8);
}

void write_mem(uint32_t addr, bool ube, uint16_t dout)
{
    addr = addr % RAM_SIZE;
    if ((addr & 1) && ube)
    {
        ram[addr] = dout >> 8;
    }
    else if (((addr & 1) == 0) && !ube)
    {
        ram[addr] = dout & 0xff;
    }
    else
    {
        ram[addr] = dout & 0xff;
        ram[addr + 1] = dout >> 8;
    }
}

v33_types::cpu_state_e prev_state = v33_types::IDLE;
void print_trace(const v33_V33 *cpu)
{
    static bool skip = true; // skip the first output because mame does
    if( cpu->state != v33_types::IDLE && prev_state == v33_types::IDLE)
    {
        if (!skip)
        {
            printf("psw=%04X aw=%04X cw=%04X dw=%04X bw=%04X sp=%04X bp=%04X ix=%04X iy=%04X ds1=%04X ps=%04X ss=%04X ds0=%04X %05X\n",
                cpu->reg_psw,
                cpu->reg_aw,
                cpu->reg_cw,
                cpu->reg_dw,
                cpu->reg_bw,
                cpu->reg_sp,
                cpu->reg_bp,
                cpu->reg_ix,
                cpu->reg_iy,
                cpu->reg_ds1,
                cpu->reg_ps,
                cpu->reg_ss,
                cpu->reg_ds0,
                (cpu->reg_ps << 4) + cpu->decoded.__PVT__pc
            );
        }
        skip = false;
    }
    prev_state = (v33_types::cpu_state_e)cpu->state;
}

void tick(int count = 1)
{
    for( int i = 0; i < count; i++ )
    {
        if (~top->n_dstb)
        {
            if (top->r_w && top->m_io)
            {
                top->din = read_mem(top->addr, (~top->n_ube) & 1);
            }
            else
            {
                top->din = 0xffff;
            }

            if (!top->r_w && top->m_io)
            {
                write_mem(top->addr, (~top->n_ube) & 1, top->dout);
            }
        }

        contextp->timeInc(1);
        top->clk = 0;

        top->eval();
        tfp->dump(contextp->time());
        print_trace(top->rootp->V33);

        contextp->timeInc(1);
        top->clk = 1;
        top->ce_1 = (~top->ce_1) & 1;
        top->ce_2 = (~top->ce_2) & 1;

        top->eval();
        tfp->dump(contextp->time());
        print_trace(top->rootp->V33);
    }
}

void tick_ce()
{
    tick(1);
    if (top->ce_1) tick(1);
}


int main(int argc, char **argv)
{
    if (argc != 2)
    {
        printf( "Usage: %s BIN_FILE\n", argv[0] );
        return -1;
    }

    FILE *fp = fopen( argv[1], "rb" );
    if (fp == nullptr)
    {
        printf( "Could not open %s\n", argv[1] );
        return -1;
    }

    fread(&ram[0xf0000], 1, 64 * 1024, fp);
    fclose(fp);

    contextp = new VerilatedContext;
    top = new v33{contextp};

    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("test_186.vcd");

    top->ce_1 = 0;
    top->ce_2 = 1;

    top->reset = 1;
    tick(10);
    top->reset = 0;
    tick(1);

    for( int i = 0; i < 2; i++ )
    {
        top->rootp->V33->reg_ps = 0xf000;
        top->rootp->V33->next_pc = 0xfff0;
        top->rootp->V33->set_pc = 1;
    }
    
    top->rootp->V33->set_pc = 1;

    while(true)
    {
        tick(1);
        if (top->rootp->V33->halt) break;
    }

    top->final();
    tfp->close();

    delete top;
    delete contextp;
    return 0;
}