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
    input logic[0:31] xer,
    input mul_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,
    output cond_exception_t cr0_xer
);

    logic valid_stages_ff[0:3];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:3];
    logic[0:4] result_reg_addr_stages_ff[0:3];
    mul_decode_t control_stages_ff[0:2];
    
    assign output_valid = valid_stages_ff[3];   
    assign rs_id_out = rs_id_stages_ff[3];
    assign result_reg_addr_out = result_reg_addr_stages_ff[3];

    logic[0:32] op1_ff[0:2];
    logic[0:32] op2_ff[0:2];
    logic[0:31] xer_ff[0:2];
    
    logic[0:32] op1_comb;
    logic[0:32] op2_comb;
    
    always_comb
    begin
        if(control_stages_ff[0].mul_signed) begin
            // Sign extend
            op1_comb[0] = op1_ff[0][1];
            op2_comb[0] = op2_ff[0][1];
            
            op1_comb[1:32] = op1_ff[0][1:32];
            op2_comb[1:32] = op2_ff[0][1:32];
        end
        else begin
            op1_comb[0] = 0;
            op2_comb[0] = 0;
            
            op1_comb[1:32] = op1_ff[0][1:32];
            op2_comb[1:32] = op2_ff[0][1:32];
        end
    end

    logic[0:65] result_all;
    logic[0:65] result_all_ff;
    
    assign result_all = $signed(op1_ff[1]) * $signed(op2_ff[1]);
    
    cond_exception_t cr0_xer_comb;
    logic[0:65] result_comb;
    
    always_comb
    begin
        logic OV = 0; 

        if(control_stages_ff[2].mul_higher) begin
            result_comb = result_all_ff[2:33];
        end
        else begin
            result_comb = result_all_ff[34:65];
        end

        // Check overflow for lower part of the result
        if(op1_ff[2][0] ^ op2_ff[2][0]) begin
            if(result_all_ff[0:34] != 35'h7FFFFFFFF) begin
                OV = 1;
            end
            else begin
                OV = 0;
            end
        end
        else begin
            // Unsigned
            // On signed multiplication, the MSB of the 32 bit
            // result has to be checked as well
            // (if it's one, the result would be signed, which is incorrect)
            if(result_all_ff[0:34] != 35'h0) begin
                OV = 1;
            end
            else begin
                OV = 0;
            end
        end

        cr0_xer_comb.xer = xer_ff[2];

        if(control_stages_ff[2].alter_OV) begin
            cr0_xer_comb.xer[1] = OV;
            cr0_xer_comb.xer[0] = xer_ff[2][0] | OV;
        end
        else begin
            cr0_xer_comb.xer[1] = xer_ff[2][1];
            cr0_xer_comb.xer[0] = xer_ff[2][0];
        end

        cr0_xer_comb.so = cr0_xer_comb.xer[0];

        cr0_xer_comb.xer_valid  = control_stages_ff[2].alter_OV;
        cr0_xer_comb.CR0_valid  = control_stages_ff[2].alter_CR0;
    end
    
    logic pipe_enable[0:3];
    
    `declare_or_reduce(4)

    always_comb
    begin
        pipe_enable[3] = (~valid_stages_ff[3] & valid_stages_ff[2]) | (output_ready & valid_stages_ff[3]);
        pipe_enable[2] = (~valid_stages_ff[2] & valid_stages_ff[1]) | (pipe_enable[3] & valid_stages_ff[2]);
        pipe_enable[1] = (~valid_stages_ff[1] & valid_stages_ff[0]) | (pipe_enable[2] & valid_stages_ff[1]);
        pipe_enable[0] = (~valid_stages_ff[0] & input_valid) | (pipe_enable[1] & valid_stages_ff[0]);
             
        // If data can move in the pipeline, we can still take input data
        input_ready = or_reduce(pipe_enable);
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= '{default: '0};
            rs_id_stages_ff             <= '{default: '{default: '0}};
            result_reg_addr_stages_ff   <= '{default: '{default: '0}};
            control_stages_ff   <= '{default: '{default: '0}};
            op1_ff              <= '{default: '{default: '0}};
            op2_ff              <= '{default: '{default: '0}};
            xer_ff              <= '{default: '{default: '0}};
            result              <= 0;
            cr0_xer             <= '{default: '0};
        end 
        else begin
            if(pipe_enable[0]) begin
                valid_stages_ff[0]              <= input_valid;
                rs_id_stages_ff[0]              <= rs_id_in;
                result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
                control_stages_ff[0]            <= control;

                op1_ff[0]   <= op1;
                op2_ff[0]   <= op2;
                xer_ff[0]   <= xer;
            end

            if(pipe_enable[1]) begin
                valid_stages_ff[1]            <= valid_stages_ff[0];
                rs_id_stages_ff[1]            <= rs_id_stages_ff[0];
                result_reg_addr_stages_ff[1]  <= result_reg_addr_stages_ff[0];
                control_stages_ff[1]          <= control_stages_ff[0];
            
                op1_ff[1]   <= op1_comb;
                op2_ff[1]   <= op2_comb;
                xer_ff[1]   <= xer_ff[0];
            end

            if(pipe_enable[2]) begin
                valid_stages_ff[2]            <= valid_stages_ff[1];
                rs_id_stages_ff[2]            <= rs_id_stages_ff[1];
                result_reg_addr_stages_ff[2]  <= result_reg_addr_stages_ff[1];
                control_stages_ff[2]          <= control_stages_ff[1];

                op1_ff[2]   <= op1_ff[1];
                op2_ff[2]   <= op2_ff[1];
                xer_ff[2]   <= xer_ff[1];

                result_all_ff <= result_all;
            end
            
            if(pipe_enable[3]) begin
                valid_stages_ff[3]            <= valid_stages_ff[2];
                rs_id_stages_ff[3]            <= rs_id_stages_ff[2];
                result_reg_addr_stages_ff[3]  <= result_reg_addr_stages_ff[2];
                
                result <= result_comb;
                cr0_xer <= cr0_xer_comb;
            end
        end
    end
endmodule