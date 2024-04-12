#! /usr/bin/env python3

import sys
import os.path
from termcolor import colored

def read_cycles(name, p):
    cycles = []
    with open(os.path.join(p, name + '.txt.cycles'), 'rt') as fp:
        lines = fp.readlines()
        for line in lines[1:]:
            line = line.strip()
            cycles.append(int(line))
    return cycles

def read_names(test_name, p):
    names = []
    with open(p, 'rt') as fp:
        lines = fp.readlines()
        for line in lines:
            line = line.strip()
            if line:
                a, _, b = line.partition(',')
                if a == test_name:
                    names.append(b)
    return names

test_name = sys.argv[1]

m107 = read_cycles(test_name, sys.argv[2])
sim = read_cycles(test_name, sys.argv[3])
names = read_names(test_name, sys.argv[4])

name_len = max([len(x) for x in names])

for n, m, s in zip(names, m107, sim):
    delta = abs(m - s)
    per = int((delta / m) * 100)
    color = "green"

    if per >= 5:
        color = "red"
    elif per > 0:
        color = "yellow"

    print(colored(f"{n:<{name_len}}: {m} {s} {per}%", color))
