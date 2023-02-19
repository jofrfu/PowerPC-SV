#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <cstdint>
#include "Vppc_top.h"
#include "Vppc_top___024unit.h"

#define MAX_SIM_TIME 2000

int main(int argc, char** argv, char** env) {
    Vppc_top *dut = new Vppc_top;
    vluint64_t sim_time = 0;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("ppc_top.vcd");




    uint32_t instructions[23] = {
        0x38800100, 0x38A00008, 0x7CC42A14, 0x7CE42BD6, 0x7D0429D6, 0x38800001, 0x5084402E, 0x60840002, 0x5084402E, 0x60840003, 0x5084402E, 0x60840004, 0x90800000, 0x38A00005, 0x50A5402E, 0x60A50006, 0x50A5402E, 0x60A50007, 0x50A5402E, 0x60A50008, 0x90A00004, 0x81E00000, 0x82000004
    };




    dut->rst = 1;
    
    for(int i = 0; i < 6; i++) {
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    dut->rst = 0;

    for(int i = 0; i < 5; i++) {
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    for(int i = 0; i < 23; i++) {
        dut->clk ^= 1;
        dut->instruction_valid = 1;
        dut->instruction = instructions[i];
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;

        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    dut->instruction_valid = 0;
    dut->instruction = 0;

    while (sim_time < MAX_SIM_TIME) {
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}