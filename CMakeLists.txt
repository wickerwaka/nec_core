cmake_minimum_required(VERSION 3.27)

project(nec_core)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(nec_sim src/main.cpp)
verilate(nec_sim
    TRACE
    SOURCES hdl/types.sv hdl/bus_control_unit.sv hdl/v33.sv
    INCLUDE_DIRS hdl
    PREFIX nec_core)
