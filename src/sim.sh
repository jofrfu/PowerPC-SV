#!/bin/bash

verilator --cc --trace --exe main.cpp ppc_core.sv
make -j -C obj_dir -f Vppc_core.mk Vppc_core
./obj_dir/Vppc_core