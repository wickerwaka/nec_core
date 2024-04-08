#! /usr/bin/env python3

from pyDigitalWaveTools.vcd.parser import VcdParser
from bisect import bisect_right
import sys

def get_series(obj, path: str):
    if path == '':
        return obj['data']
    
    name, _, remainder = path.partition('.')
    for child in obj['children']:
        if child['name'] == name:
            return get_series(child, remainder)
    
    return None


def get_value(series, time):
    x = bisect_right(series, time, key=lambda x: x[0])
    if x == 0:
        return None
    return series[x-1][1]

def read_vcd(name: str):
    print(f"Reading {name}")
    fp = open(name, 'rt')
    vcd = VcdParser()
    vcd.parse(fp)
    vcd_obj = vcd.scope.toJson()
    return vcd_obj

if __name__ == '__main__':
    vcd_name = sys.argv[1]
    
    vcd_obj = read_vcd(vcd_name)

    name_map = {
        '/DSTB': 'TOP.V33.n_dstb',
        '/BCYST': 'TOP.V33.n_bcyst',
        '/BUSLOCK': 'TOP.V33.n_buslock',
        'BUSST0': 'TOP.V33.busst0',
        'BUSST1': 'TOP.V33.busst1',
        'M/IO': 'TOP.V33.m_io',
        'R/W': 'TOP.V33.r_w',
    }

    clk = get_series(vcd_obj, 'TOP.V33.ce_2')
    series = {}
    addr_ser = get_series(vcd_obj, 'TOP.V33.addr')

    for x, y in name_map.items():
        series[x] = get_series(vcd_obj, y)

    fp = None
    if len(sys.argv) > 2:
        fp = open(sys.argv[2], 'wt')
    else:
        fp = sys.stdout

    state = 'init'
    cycles = 0
    section_start = 0
    section_cycles = []
    kvp = {}
    edge = {}
    for time, clk_val in clk[10:]:
        for name, ser in series.items():
            val = int(get_value(ser, time))
            old_val = kvp.get(name, 0)
            if val == old_val:
                if val:
                    edge[name] = 'H'
                else:
                    edge[name] = 'L'
            elif val == 1:
                edge[name] = 'R'
            else:
                edge[name] = 'F'
            kvp[name] = val

        addr_bin = get_value(addr_ser, time)
        addr = int(addr_bin[-8:], 2)
        
        io_strobe = edge['M/IO'] == 'L' and edge['/DSTB'] == 'F'

        if state == 'init':
            if addr == 0xad and io_strobe:
                state = 'wait'

        if state == 'wait':
            if edge['M/IO'] == 'R':
                state = 'dump'

        if state == 'dump':
            if addr == 0xad and io_strobe:
                state = 'exit'
        
        if state == 'exit':
            break

        if state == 'dump':
            if io_strobe and addr == 0xf2:
                section_start = cycles

            if io_strobe and addr == 0xf4:
                section_cycles.append(cycles - section_start)

            line = f'CLK={clk_val}'

            for n in ['/DSTB', '/BCYST', 'BUSST0', 'BUSST1', 'M/IO', 'R/W', '/BUSLOCK']:
                line += f' {n}={kvp[n]}'
            
            line += f' A={addr:02x}\n'

            fp.write(line)

            if clk_val == '1':
                cycles += 1

    fp.close()

    if len(section_cycles):
        fp = None
        if len(sys.argv) > 2:
            fp = open(sys.argv[2] + ".cycles", 'wt')
        else:
            fp = sys.stdout
        
        fp.write("sim_cycles\n")
        for c in section_cycles:
            fp.write(f"{c}\n")
        fp.close()