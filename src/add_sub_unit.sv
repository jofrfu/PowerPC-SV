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

module add_sub_unit #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    input logic[0:4] result_reg_addr_in,
    
    input logic[0:31] op1,
    input logic[0:31] op2,
    input logic carry_in,   // Assigned to operand 3 at index 0 in RS
    input add_sub_decode_t control,
    
    output logic output_valid,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,
    output cond_exception_t cr0_xer
);

    logic valid_stages_ff[0:3];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:3];
    logic[0:4] result_reg_addr_stages_ff[0:3];
    add_sub_decode_t control_stages_ff[0:2];
    
    assign output_valid = valid_stages_ff[3];
    assign rs_id_out = rs_id_stages_ff[3];
    assign result_reg_addr_out = result_reg_addr_stages_ff[3];
    
    logic carry_ff[0:2];

    logic[0:31] op1_ff[0:1];
    logic[0:31] op2_ff[0:1];
    
    logic[0:31] op1_comb;
    logic carry_comb;
    
    always_comb
    begin
        if(control_stages_ff[0].subtract) begin
            op1_comb = ~op1_ff[0];
            if(control_stages_ff[0].add_CA) begin
                carry_comb = carry_ff[0];
            end
            else begin
                carry_comb = 1;
            end
        end
        else if(control_stages_ff[0].add_CA) begin
            op1_comb = op1_ff[0];
            carry_comb = carry_ff[0];
        end
        else begin
            op1_comb = op1_ff[0];
            carry_comb = 0;
        end
    end
    
    // Two clock cycle adder signals
    logic[0:31] sum_comb;
    logic[0:31] sum_ff;
    
    logic[0:31] carry_generate_comb;
    logic[0:31] carry_generate_ff;
    
    logic[0:31] carry_propagate_comb;
    logic[0:31] carry_propagate_ff;
    
    cond_exception_t cr0_xer_comb;
    logic[0:31] result_comb;
    
    always_comb
    begin
        logic[0:32] carry;
    
        // Stage 1 of adder
        sum_comb = op1_ff[1] ^ op2_ff[1];
        carry_generate_comb = op1_ff[1] & op2_ff[1];
        carry_propagate_comb = op1_ff[1] | op2_ff[1];
        
        // Stage 2 of adder
        carry[32] = carry_ff[2];
        for(int i = 31; i >= 0; i--) begin
            carry[i] = carry_generate_ff[i] | (carry_propagate_ff[i] & carry[i+1]);
        end
        result_comb = sum_ff ^ carry[1:32];
        cr0_xer_comb.CA = carry[0];
        cr0_xer_comb.OV = carry[0] ^ carry[1];
        
        // Set valid signals
        cr0_xer_comb.CA_valid = control_stages_ff[2].alter_CA;
        cr0_xer_comb.OV_valid = control_stages_ff[2].alter_OV;
        cr0_xer_comb.CR0_valid = control_stages_ff[2].alter_CR0;
    end
    
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= {default: '0};
            rs_id_stages_ff             <= {default: {default: '0}};
            result_reg_addr_stages_ff   <= {default: {default: '0}};
            control_stages_ff           <= {default: {default: '0}};
            
            carry_ff <= {default: '0};
            
            op1_ff <= {default: {default: '0}};
            op2_ff <= {default: {default: '0}};
            
            sum_ff              <= 0;
            carry_generate_ff   <= 0;
            carry_propagate_ff  <= 0;
            
            result <= 0;
            cr0_xer <= {default: '0};
        end
        else begin
            valid_stages_ff[0]              <= input_valid;
            rs_id_stages_ff[0]              <= rs_id_in;
            result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
            control_stages_ff[0]            <= control;
            
            valid_stages_ff[1:3]            <= valid_stages_ff[0:2];
            rs_id_stages_ff[1:3]            <= rs_id_stages_ff[0:2];
            result_reg_addr_stages_ff[1:3]  <= result_reg_addr_stages_ff[0:2];
            control_stages_ff[1:2]          <= control_stages_ff[0:1];
            
            carry_ff[0] <= carry_in;
            carry_ff[1] <= carry_comb;
            carry_ff[2] <= carry_ff[1];
            
            op1_ff[0] <= op1;
            op2_ff[0] <= op2;
            op1_ff[1] <= op1_comb;
            op2_ff[1] <= op2_ff[0];
            
            sum_ff              <= sum_comb;
            carry_generate_ff   <= carry_generate_comb;
            carry_propagate_ff  <= carry_propagate_comb;
            
            result <= result_comb;
            cr0_xer <= cr0_xer_comb;
        end
    end
endmodule