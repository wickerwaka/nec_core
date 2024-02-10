cmake_minimum_required(VERSION 3.27)

project(nec_core)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

add_executable(bus_control_unit src/bcu.cpp)
verilate(bus_control_unit
    TRACE
    SOURCES hdl/types.sv hdl/bus_control_unit.sv hdl/divu_int.sv hdl/divider.sv
    INCLUDE_DIRS hdl
    TOP_MODULE bus_control_unit
    PREFIX bus_control_unit)

add_executable(v33 src/main.cpp)
verilate(v33
    TRACE
    SOURCES hdl/types.sv hdl/bus_control_unit.sv hdl/v33.sv hdl/pre_decode.sv hdl/alu.sv
    INCLUDE_DIRS hdl
    TOP_MODULE V33
    PREFIX v33)
