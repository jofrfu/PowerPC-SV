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

module rot_unit #(
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
    input logic[0:31] target,
    input rotate_decode_t control,
    
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
    rotate_decode_t control_stages_ff[0:2];
    
    assign output_valid = valid_stages_ff[3];
    assign rs_id_out = rs_id_stages_ff[3];
    assign result_reg_addr_out = result_reg_addr_stages_ff[3];
    
    logic[0:31] op1_ff[0:2];
    logic[0:5] op2_ff[0:1], op2_comb; // Op2 is the shift operand
    logic[0:31] target_ff[0:2]; // Content of target register is used as a third operand

    logic[0:4] mask_begin_ff, mask_begin_comb;
    logic[0:4] mask_end_ff, mask_end_comb;

    logic compute_mask_ff, compute_mask_comb;

    always_comb
    begin
        if(control_stages_ff[0].shift) begin
            if(control_stages_ff[0].left) begin
                if(op2_ff[0] == 0) begin
                    mask_begin_comb = 0;
                    mask_end_comb = 31 - op2_ff[0][1:5];
                    compute_mask_comb = 1;
                end
                else begin
                    mask_begin_comb = 0;
                    mask_end_comb = 0;
                    compute_mask_comb = 0;
                end
                op2_comb = op2_ff[0];
            end
            else begin
                mask_begin_comb = op2_ff[0][1:5];
                mask_end_comb = 31;
                compute_mask_comb = ~op2_ff[0][0];
                // Make the rotate left go around completely for right shifts.
                op2_comb = 32 - op2_ff[0];
            end
        end
        else begin
            mask_begin_comb = control_stages_ff[0].MB;
            mask_end_comb = control_stages_ff[0].ME;
            compute_mask_comb = 1;
        end
    end

    logic[0:31] mask_ff, mask_comb;
    logic[0:31] shifted_ff, shifted_comb;

    always_comb
    begin
        if(compute_mask_ff) begin
            for(int i = 0; i < 32; i++) begin
                if(mask_begin_comb > mask_end_comb) begin
                    mask_comb[i] = (i >= mask_begin_ff) | (i <= mask_end_ff);
                end
                else begin
                    mask_comb[i] = (i >= mask_begin_comb) & (i <= mask_end_comb);
                end
            end
        end
        else begin
            mask_comb = 32'b0;
        end

        // Rotate left
        for(int i = 0; i < 32; i++) begin
            shifted_comb[i - op2_ff[1][1:5]] = op1_ff[1][i];
        end
    end

    logic[0:31] result_comb;
    cond_exception_t cr0_xer_comb;

    always_comb
    begin
        if(control_stages_ff[2].mask_insert) begin
            result_comb = (shifted_ff & mask_ff) | (target_ff[2] & ~mask_ff);
            cr0_xer_comb.CA = 0;
            cr0_xer_comb.CA_valid = 0;
        end
        else if(control_stages_ff[2].shift & ~control_stages_ff[2].left & control_stages_ff[2].sign_extend) begin
            logic[0:31] sign = {32{op1_ff[2][0]}};
            result_comb = (shifted_ff & mask_ff) | (sign & ~mask_ff);
            cr0_xer_comb.CA = sign & ((shifted_ff & ~mask_ff) != 0);
            cr0_xer_comb.CA_valid = 1;
        end
        else begin
            result_comb = shifted_ff & mask_ff;
            cr0_xer_comb.CA = 0;
            cr0_xer_comb.CA_valid = 0;
        end

        cr0_xer_comb.OV = 0;
        cr0_xer_comb.OV_valid = 0;
        cr0_xer_comb.CR0_valid = control_stages_ff[2].alter_CR0;
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= {default: '0};
            rs_id_stages_ff             <= {default: {default: '0}};
            result_reg_addr_stages_ff   <= {default: {default: '0}};
            control_stages_ff           <= {default: {default: '0}};
            
            op1_ff <= {default: {default: '0}};
            op2_ff <= {default: {default: '0}};
            target_ff <= {default: {default: '0}};

            mask_begin_ff <= 0;
            mask_end_ff <= 0;

            compute_mask_ff <= 0;

            mask_ff <= 0;
            shifted_ff <= 0;
            
            result <= 0;
            cr0_xer <= {default: '0};
        end
        else begin
            valid_stages_ff[0]              <= input_valid;
            rs_id_stages_ff[0]              <= rs_id_in;
            result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
            control_stages_ff[0]            <= control;
            
            op1_ff[0]   <= op1;
            op2_ff[0]   <= op2;
            target_ff[0]<= target;

            mask_begin_ff <= mask_begin_comb;
            mask_end_ff <= mask_end_comb;

            valid_stages_ff[1]              <= valid_stages_ff[0];
            rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
            result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];
            control_stages_ff[1]            <= control_stages_ff[0];
            
            op1_ff[1]   <= op1_ff[0];
            op2_ff[1]   <= op2_ff[0];
            target_ff[1]<= target_ff[0];

            compute_mask_ff <= compute_mask_comb;

            valid_stages_ff[2]              <= valid_stages_ff[1];
            rs_id_stages_ff[2]              <= rs_id_stages_ff[1];
            result_reg_addr_stages_ff[2]    <= result_reg_addr_stages_ff[1];
            control_stages_ff[2]            <= control_stages_ff[1];
            
            op1_ff[2]   <= op1_ff[1];
            target_ff[2]<= target_ff[1];

            mask_ff <= mask_comb;
            shifted_ff <= shifted_comb;

            valid_stages_ff[3]              <= valid_stages_ff[2];
            rs_id_stages_ff[3]              <= rs_id_stages_ff[2];
            result_reg_addr_stages_ff[3]    <= result_reg_addr_stages_ff[2];

            result <= result_comb;
            cr0_xer <= cr0_xer_comb;
        end
    end

endmodule