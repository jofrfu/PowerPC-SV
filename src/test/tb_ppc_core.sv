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

module tb_ppc_core ();

    logic clk;
    logic rst;

    logic instruction_valid;
    logic instruction_ready;
    logic[0:31] instruction;

    // TODO: Remove signals below, only needed to keep internal signals
    logic top_output_valid;
    logic[0:5] top_rs_id_out;
    logic[0:4] top_result_reg_addr_out;
    logic[0:31] top_result_out;
    logic trap;

    ppc_core core(
        .*
    );

    always #10 clk = ~clk;

    logic[0:31] instruction_stream[0:4] = {
        32'h38800100,
        32'h38A00008,
        32'h7CC42A14,
        32'h7CE42BD6,
        32'h7D0429D6
    };

    initial
    begin
        rst = 1;
        instruction_valid = 0;
        instruction = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);
        @(negedge clk);
        instruction_valid = 1;
        for(int i = 0; i < 5; i++) begin
            instruction = instruction_stream[i];
            @(negedge clk);
        end
        instruction = 0;
        instruction_valid = 0;
    end
endmodule