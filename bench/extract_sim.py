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

    start_start = False
    start_end = False
    cycles = 0
    for time, clk_val in clk[10:]:
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

        addr_bin = get_value(addr_ser, time)
        addr = int(addr_bin[-8:], 2)
        
        line = f'{cycles:03d} CLK={clk_val}'

        for n in ['/DSTB', '/BCYST', 'BUSST0', 'BUSST1', 'M/IO', 'R/W', '/BUSLOCK']:
            line += f' {n}={kvp[n]}'
        
        line += f' A={addr:02x}\n'

        fp.write(line)

        if clk_val == '2':
            cycles += 1

