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
    input branch_decoded_t control,
    
    input logic[0:31] current_instruction_address,
    output logic[0:31] next_instruction_address,
    output logic speculative
);



endmodule