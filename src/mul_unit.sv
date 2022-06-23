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

module mul_unit #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,
    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    input logic[0:4] result_reg_addr_in,
    
    input logic[0:31] op1,
    input logic[0:31] op2,
    input mul_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,
    output cond_exception_t cr0_xer
);

    logic valid_stages_ff[0:1];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:1];
    logic[0:4] result_reg_addr_stages_ff[0:1];
    mul_decode_t control_stages_ff[0:2];
    
    logic[0:32] op1_ff[0:1];
    logic[0:32] op2_ff[0:1];
    
    logic[0:32] op1_comb;
    logic[0:32] op2_comb;
    
    always_comb
    begin
        if(control_stages_ff[0].mul_signed) begin
            // Sign extend
            op1_comb[0] = op1_ff[0][1];
            op2_comb[0] = op2_ff[0][1];
            
            op1_comb[1:32] = op1_ff[0][1:32];
            op2_comb[1:32] = op1_ff[0][1:32];
        end
        else begin
            op1_comb[0] = 0;
            op2_comb[0] = 0;
            
            op1_comb[1:32] = op1_ff[0][1:32];
            op2_comb[1:32] = op1_ff[0][1:32];
        end
    end

    logic[0:65] result_all;
    logic[0:65] result_all_ff;
    
    assign result_all = $signed(op1_ff[1]) * $signed(op2_ff[1]);
        
    logic[0:65] result_comb;
    
    always_comb
    begin
        if(control_stages_ff[2].mul_higher) begin
            result_comb = result_all_ff[2:33];
        end
        else begin
            result_comb = result_all_ff[34:65];
        end
    end
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            control_stages_ff   <= {default: {default: '0}};
            op1_ff              <= {default: {default: '0}};
            op2_ff              <= {default: {default: '0}};
            result              <= 0;
        end 
        else begin
            control_stages_ff[0]    <= control;
            control_stages_ff[1:2]  <= control_stages_ff[0:1];
            
            op1_ff[0]   <= op1;
            op2_ff[0]   <= op2;
            op1_ff[1]   <= op1_comb;
            op2_ff[1]   <= op2_comb;
            result_all_ff <= result_all;
            result      <= result_comb;
        end
    end
endmodule