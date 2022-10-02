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

module memory #(
    parameter int RS_ID_WIDTH = 5,
    parameter int MEMORY_DEPTH = 32768
)(
    input logic clk,

    input logic[0:$clog2(MEMORY_DEPTH)-1] address,
    input logic[0:3] wen,
    input logic[0:31] write_data,

    output logic read_data
);

    logic[0:31] memory[0:MEMORY_DEPTH-1];

    always_ff @(posedge clk)
    begin
        for(int i = 0; i < 4; i++) begin
            if(wen(i)) begin
                memory[address][i +: 8] <= write_data[i +: 8];
            end
        end

        read_data <= memory[address];
    end
endmodule;