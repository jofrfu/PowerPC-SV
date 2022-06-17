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
                    begin
                        if(a.branch.branch_decoded.operation != a.branch.branch_decoded.operation) return 0;
                        if(a.branch.branch_decoded.LK != b.branch.branch_decoded.LK) return 0;
                        if(a.branch.branch_decoded.AA != b.branch.branch_decoded.AA) return 0;
                        if(a.branch.branch_decoded.LI != b.branch.branch_decoded.LI) return 0;
                        if(a.branch.branch_decoded.BD != b.branch.branch_decoded.BD) return 0;
                        if(a.branch.branch_decoded.BI != b.branch.branch_decoded.BI) return 0;
                        if(a.branch.branch_decoded.BO != b.branch.branch_decoded.BO) return 0;
                        if(a.branch.branch_decoded.BH != b.branch.branch_decoded.BH) return 0;
                    end
                EXEC_SYSTEM_CALL:
                    if(a.branch.system_call_decoded != b.branch.system_call_decoded) return 0;
                EXEC_CONDITION:
                    begin
                        if(a.branch.condition_decoded.operation != b.branch.condition_decoded.operation) return 0;
                        if(a.branch.condition_decoded.CR_op1_reg_address != b.branch.condition_decoded.CR_op1_reg_address) return 0;
                        if(a.branch.condition_decoded.CR_op2_reg_address != b.branch.condition_decoded.CR_op2_reg_address) return 0;
                        if(a.branch.condition_decoded.CR_result_reg_address != b.branch.condition_decoded.CR_result_reg_address) return 0;
                    end
            endcase
                
        end else if(a.fixed_point.execute != EXEC_FIXED_NONE || b.fixed_point.execute != EXEC_FIXED_NONE 
                 && a.fixed_point.execute == b.fixed_point.execute) begin
            if(a.branch.execute != EXEC_BRANCH_NONE) begin
                return 0;
            end
        end // TODO: add floating point
        return 1;
    endfunction
    
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        rst = 0;
        instruction = 0;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        
        for(int i = 0; i < 4; i++) begin
            instruction = stimuli[i];
            @(posedge clk);
            #5
            if(~compare(decode, results[i])) begin
                $display("Not equal at %d!", i);
            end
        end
    end
endmodule