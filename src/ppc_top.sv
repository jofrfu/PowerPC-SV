/*
    Copyright 2022 Jonas Fuhrmann

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
==============================================================================*/

// synthesis translate_off
`include "ppc_types.sv"
// synthesis translate_on

import ppc_types::*;

module ppc_top (
    input logic clk,
    input logic rst,

    input logic instruction_valid,
    output logic instruction_ready,
    input  logic[0:31] instruction,

    output logic trap
);
    localparam int RS_ID_WIDTH = 7;

    //------ Interface to data cache or memory ------
    logic to_mem_valid;
    logic to_mem_ready;
    logic[0:RS_ID_WIDTH-1] to_mem_rs_id;
    logic[0:4] to_mem_reg_addr;

    logic[0:31] mem_address;
    logic[0:3]  mem_write_en;
    logic[0:31] mem_write_data;
    logic[0:3]  mem_read_en;
    //-----------------------------------------------

    //------ Interface from data cache or memory ------
    logic from_mem_valid;
    logic from_mem_ready;
    logic[0:RS_ID_WIDTH-1] from_mem_rs_id;
    logic[0:4] from_mem_reg_addr;

    logic[0:31] mem_read_data;
    //-------------------------------------------------


    ppc_core core (
        .*
    );

    data_mem mem (
        .input_valid(to_mem_valid),
        .input_ready(to_mem_ready),
        .rs_id_in(to_mem_rs_id),
        .result_reg_addr_in(to_mem_reg_addr),

        .output_valid(from_mem_valid),
        .output_ready(from_mem_ready),
        .rs_id_out(from_mem_rs_id),
        .result_reg_addr_out(from_mem_reg_addr),

        .*
    );


endmodule