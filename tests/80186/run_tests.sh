#! /bin/bash

TESTS="add bcdcnv bitwise cmpneg control datatrnf div interrupt jmpmov jump1 jump2 mul rep rotate shifts sub"

RUNNER=../../build/test_186
mkdir -p sim_traces

for test in $TESTS;
do
    echo ${test}
    ${RUNNER} ${test}.bin > sim_traces/${test}_186.tr
done