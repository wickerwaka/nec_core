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
        '/DSTB': 'libsigrok4DSL./DSTB',
        '/BCYST': 'libsigrok4DSL./BCYST',
        'BUSST0': 'libsigrok4DSL.BUSST0',
        'BUSST1': 'libsigrok4DSL.BUSST1',
        'M/IO': 'libsigrok4DSL.M/IO',
        'R/W': 'libsigrok4DSL.R/W',
        '/BUSLOCK': 'libsigrok4DSL./BUSLOCK',
        'A0': 'libsigrok4DSL.A0',
        'A1': 'libsigrok4DSL.A1',
        'A2': 'libsigrok4DSL.A2',
        'A3': 'libsigrok4DSL.A3',
        'A4': 'libsigrok4DSL.A4',
        'A5': 'libsigrok4DSL.A5',
        'A6': 'libsigrok4DSL.A6',
        'A7': 'libsigrok4DSL.A7',
    }

    clk = get_series(vcd_obj, 'libsigrok4DSL.CLK')

    series = dict((x, get_series(vcd_obj, y)) for x,y in name_map.items())

    fp = None
    if len(sys.argv) > 2:
        fp = open(sys.argv[2], 'wt')
    else:
        fp = sys.stdout

    start_start = False
    start_end = False
    cycles = 0
    section_start = 0
    section_cycles = []
    kvp = {}
    edge = {}
    state = 'init'
    for time, clk_val in clk:
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

        addr = 0
        for a in ['A7', 'A6', 'A5', 'A4', 'A3', 'A2', 'A1', 'A0']:
            addr = (addr * 2) + kvp[a]
        
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
        
        fp.write("hw_cycles\n")
        for c in section_cycles:
            fp.write(f"{c}\n")
        fp.close()

