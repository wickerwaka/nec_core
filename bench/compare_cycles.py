#! /usr/bin/env python3

import sys
from termcolor import colored

def read_cycles(name):
    cycles = []
    with open(name, 'rt') as fp:
        lines = fp.readlines()
        for line in lines[1:]:
            line = line.strip()
            cycles.append(int(line))
    return cycles

def read_names(name):
    names = []
    with open(name, 'rt') as fp:
        lines = fp.readlines()
        for line in lines:
            line = line.strip()
            names.append(line)
    return names

m107 = read_cycles(sys.argv[1])
sim = read_cycles(sys.argv[2])
names = read_names(sys.argv[3])

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
