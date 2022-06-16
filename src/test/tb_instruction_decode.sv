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

module tb_instruction_decode;

    logic clk;
    logic rst;
    logic[0:31] instruction;
    decode_result_t decode;
    
    instruction_decode dut(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .decode(decode)
    );
    
    decode_result_t results[4] = `include "results_instruction_decode.txt"
    logic[0:31] stimuli[4] = {
        'h4829C034,
        'h4829C036,
        'h4829C035,
        'h4829C037
        /*41095BBC,
        41095BBE,
        41095BBD,
        42405BBF,
        4D890420,
        4D890421,
        4D090020,
        4D090021*/
    };
    
    
    function logic compare(input decode_result_t a, input decode_result_t b);
        if(a.branch.execute != EXEC_BRANCH_NONE || b.branch.execute != EXEC_BRANCH_NONE 
        && a.branch.execute == b.branch.execute) begin
            if(a.fixed_point.execute != EXEC_FIXED_NONE) begin
                return 0;
            end
            
            case(a.branch.execute)
                EXEC_BRANCH:
                EXEC_SYSTEM_CALL:
                EXEC_CONDITION:
            endcase
                
        end else if(a.fixed_point.execute != EXEC_FIXED_NONE || b.fixed_point.execute != EXEC_FIXED_NONE 
                 && a.fixed_point.execute == b.fixed_point.execute) begin
            if(a.branch.execute != EXEC_BRANCH_NONE) begin
                return 0;
            end
        end // TODO: add floating point
    endfunction
    
    always #10 clk = ~clk;
    
    initial begin
        clk <= 0;
        rst <= 0;
        instruction <= 0;
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);
        
        for(int i = 0; i < 4; i++) begin
            instruction <= stimuli[i];
            @(posedge clk);
            if(decode != results[i]) begin
                $display("Not equal!");
            end
        end
    end
endmodule