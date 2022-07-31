#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <cstdint>
#include "Vppc_core.h"
#include "Vppc_core___024unit.h"

#define MAX_SIM_TIME 200

int main(int argc, char** argv, char** env) {
    Vppc_core *dut = new Vppc_core;
    vluint64_t sim_time = 0;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("ppc_core.vcd");




    int32_t instructions[5] = {
        0x38800100,
        0x38A00008,
        0x7CC42A14,
        0x7CE42BD6,
        0x7D0429D6
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

    for(int i = 0; i < 5; i++) {
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