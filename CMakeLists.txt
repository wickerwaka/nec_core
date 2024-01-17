cmake_minimum_required(VERSION 3.27)

project(nec_core)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(nec_sim src/main.cpp)
verilate(nec_sim
    SOURCES hdl/decode.sv
    PREFIX nec_core)
