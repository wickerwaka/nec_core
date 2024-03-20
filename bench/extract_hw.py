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
    for time, clk_val in clk:
        kvp = {}
        for name, ser in series.items():
            val = get_value(ser, time)
            kvp[name] = int(val)

        if kvp['M/IO'] == 0 and not start_start:
            start_start = True
            continue

        if kvp['M/IO'] == 1 and start_start and not start_end:
            start_end = True
        

        if kvp['M/IO'] == 0 and start_start and start_end:
            break

        if not start_end:
            continue

        addr = 0
        for a in ['A7', 'A6', 'A5', 'A4', 'A3', 'A2', 'A1', 'A0']:
            addr = (addr * 2) + kvp[a]
        
        line = f'{cycles:03d} CLK={clk_val}'

        for n in ['/DSTB', '/BCYST', 'BUSST0', 'BUSST1', 'M/IO', 'R/W']:
            line += f' {n}={kvp[n]}'
        
        line += f' A={addr:02x}\n'

        fp.write(line)

        if clk_val == '0':
            cycles += 1

