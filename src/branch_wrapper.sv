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
import ppc_types::*;

module branch_unit(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,

    input branch_inner_decode_t control,
    input logic[0:31] cia_in,
    input logic[0:3] cond_reg_in,
    input logic[0:31] link_reg_in,
    input logic[0:31] count_reg_in,
    
    output logic output_valid,
    input logic output_ready,
    output logic nia_valid,
    output logic[0:31] nia_out,
    output logic link_reg_valid,
    output logic[0:31] link_reg_out,
    output logic count_reg_valid,
    output logic[0:31] count_reg_out,

    // Marks all new incoming instructions as speculative
    output logic speculative,
    // Marks all marked instructions as non-sepculative
    output logic clear_speculative,
    // Flushes all speculative instructions in the pipeline
    output logic flush_speculative
);


endmodule