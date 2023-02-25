#!/bin/bash

verilator -Wno-LITENDIAN -Wno-ENUMVALUE --cc --trace --exe main.cpp ppc_top.sv
make -j -C obj_dir -f Vppc_top.mk Vppc_top
./obj_dir/Vppc_top
