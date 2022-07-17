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

module write_back_arbiter #(
    parameter int RS_ID_WIDTH = 5,
    parameter int ARBITER_DEPTH = 8
)(
    input logic clk,
    input logic rst,

    // GPR inputs
    input logic gpr_input_valid[0:ARBITER_DEPTH-1],
    output logic gpr_input_ready[0:ARBITER_DEPTH-1],
    input logic[0:RS_ID_WIDTH-1] gpr_rs_id_in[0:ARBITER_DEPTH-1],
    input logic[0:4] gpr_result_reg_addr_in[0:ARBITER_DEPTH-1],
    input logic[0:31] gpr_result_in[0:ARBITER_DEPTH-1],
    input cond_exception_t gpr_cr0_xer_in[0:ARBITER_DEPTH-1],

    // GPR outputs
    output logic gpr_output_valid,
    output logic[0:RS_ID_WIDTH-1] gpr_rs_id_out,
    output logic[0:4] gpr_result_reg_addr_out,
    output logic[0:31] gpr_result_out,
    output cond_exception_t gpr_cr0_xer_out,

    // SPR inputs
    input logic spr_input_valid,
    output logic spr_input_ready,
    input logic[0:RS_ID_WIDTH-1] spr_rs_id_in,
    input logic[0:9] spr_result_reg_addr_in,
    input logic[0:31] spr_result_in,
    
    // SPR outputs
    output logic spr_output_valid,
    output logic[0:RS_ID_WIDTH-1] spr_rs_id_out,
    output logic[0:9] spr_result_reg_addr_out,
    output logic[0:31] spr_result_out

    // CR inputs

    // CR outputs
);

    logic gpr_output_valid_comb;
    logic[0:RS_ID_WIDTH-1] gpr_rs_id_out_comb;
    logic[0:4] gpr_result_reg_addr_out_comb;
    logic[0:31] gpr_result_out_comb;
    cond_exception_t gpr_cr0_xer_out_comb;

    logic spr_output_valid_comb;
    logic[0:RS_ID_WIDTH-1] spr_rs_id_out_comb;
    logic[0:9] spr_result_reg_addr_out_comb;
    logic[0:31] spr_result_out_comb;

    logic spr_chosen, spr_chosen_ff;

    logic[0:$clog2(ARBITER_DEPTH)-1] pointer, pointer_ff;
    logic next;

    always_comb
    begin
        gpr_input_ready = '{default: 0};
        next = 0;

        if(spr_chosen_ff & spr_input_valid) begin
            spr_output_valid_comb = spr_input_valid;
            spr_input_ready = 1;
            spr_rs_id_out_comb = spr_rs_id_in;
            spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
            spr_result_out_comb = spr_result_in;

            spr_chosen = 0;
        end
        else begin
            // TODO: Implement once the XER field is correctly implemnted in units...
            spr_chosen = 1;
        end

        // Take the next pointer, if SPR is either not written or it's not SPR input bus' turn
        if(gpr_input_valid[pointer_ff] & 
         ~(spr_chosen_ff & (gpr_cr0_xer_in[pointer_ff].alter_CA | gpr_cr0_xer_in[pointer_ff].alter_CA))) begin
            gpr_output_valid_comb = gpr_input_valid[pointer_ff];
            gpr_input_ready[pointer_ff] = 1;
            gpr_rs_id_out_comb = gpr_rs_id_in[pointer_ff];
            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[pointer_ff];
            gpr_result_out_comb = gpr_result_in[pointer_ff];
            gpr_cr0_xer_out_comb = gpr_cr0_xer_in[pointer_ff];

            pointer = pointer_ff + 1;
        end
        else begin
            for(int i = 1; i < ARBITER_DEPTH; i++) begin
                logic current = (pointer_ff + i) % ARBITER_DEPTH;
                if(gpr_input_valid[current] &
                 ~(spr_chosen_ff & (gpr_cr0_xer_in[current].alter_CA | gpr_cr0_xer_in[current].alter_CA))) begin
                    next = current;
                    break;
                end
            end

            gpr_output_valid_comb = gpr_input_valid[next];
            gpr_input_ready[next] = 1;
            gpr_rs_id_out_comb = gpr_rs_id_in[next];
            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
            gpr_result_out_comb = gpr_result_in[next];
            gpr_cr0_xer_out_comb = gpr_cr0_xer_in[next];

            pointer = next + 1;
        end
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            pointer_ff <= 0;

            gpr_output_valid <= 0;
            gpr_rs_id_out <= 0;
            gpr_result_reg_addr_out <= 0;
            gpr_result_out <= 0;
            gpr_cr0_xer_out <= '{default: '0};
        end
        else begin
            pointer_ff <= pointer;

            gpr_output_valid <= gpr_output_valid_comb;
            gpr_rs_id_out <= gpr_rs_id_out_comb;
            gpr_result_reg_addr_out <= gpr_result_reg_addr_out_comb;
            gpr_result_out <= gpr_result_out_comb;
            gpr_cr0_xer_out <= gpr_cr0_xer_out_comb;
        end
    end
endmodule