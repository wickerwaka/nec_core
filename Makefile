BUILD_DIR = build
VERILATOR = verilator
VERILATOR_ARGS = --exe --cc --build -j 8 --trace --Mdir $(BUILD_DIR) -Ihdl --MMD --MP
PYTHON = python3


HDL_SRC = hdl/types.sv \
		  hdl/bus_control_unit.sv \
		  hdl/nec_divider.sv \
		  hdl/v33.sv \
		  hdl/nec_decode.sv \
		  hdl/alu.sv \

HDL_GEN = hdl/opcodes.svh hdl/enums.svh

TIMING_TESTS = \
				nop_loop \
				mov_2byte_from_mem \
				mov_2byte_to_mem \
				mov_3byte_from_mem \
				mov_3byte_to_mem

TIMING_TEST_TRACES = $(patsubst %,traces/sim/%.txt,$(TIMING_TESTS))

all: $(TIMING_TEST_TRACES)

$(BUILD_DIR)/v33: $(HDL_SRC) $(HDL_GEN) bench/main.cpp
	$(VERILATOR) $(VERILATOR_ARGS) --prefix v33 --top V33 $(HDL_SRC) bench/main.cpp

hdl/opcodes.svh: hdl/opcodes.yaml hdl/gen_decode.py
	$(PYTHON) hdl/gen_decode.py

hdl/enums.svh: hdl/enums.yaml hdl/gen_enums.py
	$(PYTHON) hdl/gen_enums.py

testrom/build/test_%/cpu.bin: ALWAYS
	$(MAKE) -C testrom TEST=$*

traces/sim/%.vcd: testrom/build/test_%/cpu.bin $(BUILD_DIR)/v33
	$(BUILD_DIR)/v33 $< $@

traces/sim/%.txt: traces/sim/%.vcd
	$(PYTHON) bench/extract_sim.py $< $@

.PHONY: ALWAYS

