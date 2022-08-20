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

module simple_write_back_arbiter #(
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
    output logic[0:31] spr_result_out,

    // CR inputs
    input logic cr_input_valid,
    output logic cr_input_ready,
    input logic[0:RS_ID_WIDTH-1] cr_rs_id_in,
    input logic cr_input_enable[0:7],
    input logic[0:31] cr_result_in,

    input logic cmp_cr_input_valid,
    output logic cmp_cr_input_ready,
    input logic[0:RS_ID_WIDTH-1] cmp_cr_rs_id_in,
    input logic[0:2] cmp_cr_input_addr,
    input logic[0:3] cmp_cr_result_in,

    // CR outputs
    output logic cr_output_valid,
    output logic[0:RS_ID_WIDTH-1] cr_rs_id_out[0:7],
    output logic cr_output_enable[0:7],
    output logic[0:31] cr_result_out
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

    logic cr_output_valid_comb;
    logic[0:RS_ID_WIDTH-1] cr_rs_id_out_comb[0:7];
    logic cr_output_enable_comb[0:7];
    logic[0:31] cr_result_out_comb;

    logic cr_chosen, cr_chosen_ff;

    logic cr_pointer, cr_pointer_ff;

    logic[0:$clog2(ARBITER_DEPTH)-1] pointer, pointer_ff;
    logic[0:$clog2(ARBITER_DEPTH)-1] next;

    function logic[0:3] check_condition(logic[0:31] result, logic so);
        if($signed(result) < 0) begin
            return {3'b100, so};
        end
        else if($signed(result) > 0) begin
            return {3'b010, so};
        end
        else begin
            return {3'b001, so};
        end
    endfunction

    always_comb
    begin
        logic found;

        gpr_input_ready = '{default: 0};
        next = 0;

        // Search next
        found = 0;
        next = pointer_ff;
        for(int i = 0; i < ARBITER_DEPTH; i++) begin
            logic[0:$clog2(ARBITER_DEPTH)-1] current = (pointer_ff + i) % ARBITER_DEPTH;
            if(gpr_input_valid[current] & ~found) begin
                next = current;
                found = 1;
            end
        end

        // Default values
        gpr_input_ready = '{default: '0};

        gpr_output_valid_comb = 0;
        gpr_rs_id_out_comb = 0;
        gpr_result_reg_addr_out_comb = 0;
        gpr_result_out_comb = 0;

        spr_input_ready = 0;

        spr_output_valid_comb = 0;
        spr_rs_id_out_comb = 0;
        spr_result_reg_addr_out_comb = 0;
        spr_result_out_comb = 0;

        cr_input_ready = 0;
        cmp_cr_input_ready = 0;

        cr_output_valid_comb = 0;
        cr_rs_id_out_comb = '{default: '0};
        cr_output_enable_comb = '{default: '0};
        cr_result_out_comb = 0;

        pointer = pointer_ff;
        spr_chosen = spr_chosen_ff;
        cr_chosen = cr_chosen_ff;
        cr_pointer = cr_pointer_ff;

        if(spr_chosen_ff & spr_input_valid) begin

            spr_input_ready = 1'b1;

            spr_output_valid_comb = spr_input_valid;
            spr_rs_id_out_comb = spr_rs_id_in;
            spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
            spr_result_out_comb = spr_result_in;

            if(~gpr_cr0_xer_in[next].xer_valid) begin
                gpr_input_ready[next] = 1'b1;

                gpr_output_valid_comb = gpr_input_valid[next];
                gpr_rs_id_out_comb = gpr_rs_id_in[next];
                gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
                gpr_result_out_comb = gpr_result_in[next];

                cr_output_valid_comb = gpr_input_valid[next];
                cr_rs_id_out_comb[0] = gpr_rs_id_in[next];
                cr_output_enable_comb[0] = gpr_cr0_xer_in[next].CR0_valid;
                cr_result_out_comb[0:3] = check_condition(gpr_result_in[next], gpr_cr0_xer_in[next].so);

                pointer = pointer_ff + 1;
                cr_chosen = 1;
            end

            spr_chosen = 0;
        end
        else if(cr_chosen_ff & (cr_input_valid | cmp_cr_input_valid)) begin
            if(cr_pointer_ff == 0 & (cr_input_valid | ~cmp_cr_input_valid)) begin
                cr_input_ready = 1;

                cr_output_valid_comb = cr_input_valid;
                cr_rs_id_out_comb = '{default: cr_rs_id_in};
                cr_output_enable_comb = cr_input_enable;
                cr_result_out_comb = cr_result_in;
                
                cr_pointer = 1;
            end
            else begin
                cmp_cr_input_ready = 1;

                cr_output_valid_comb = cmp_cr_input_valid;
                cr_rs_id_out_comb = '{default: cmp_cr_rs_id_in};
                cr_output_enable_comb[cmp_cr_input_addr] = 1;
                cr_result_out_comb = cmp_cr_result_in;

                cr_pointer = 0;
            end

            if(~gpr_cr0_xer_in[next].CR0_valid) begin
                gpr_input_ready[next] = 1'b1;

                gpr_output_valid_comb = gpr_input_valid[next];
                gpr_rs_id_out_comb = gpr_rs_id_in[next];
                gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
                gpr_result_out_comb = gpr_result_in[next];

                spr_output_valid_comb = gpr_cr0_xer_in[next].xer_valid;
                spr_rs_id_out_comb = gpr_rs_id_in[next];
                spr_result_reg_addr_out_comb = 1;   // XER is at address 1
                spr_result_out_comb = gpr_cr0_xer_in[next].xer;

                pointer = pointer_ff + 1;
            end

            cr_chosen = 0;
        end
        else begin  // GPR chosen
            gpr_input_ready[next] = 1'b1;

            gpr_output_valid_comb = gpr_input_valid[next];
            gpr_rs_id_out_comb = gpr_rs_id_in[next];
            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
            gpr_result_out_comb = gpr_result_in[next];

            spr_output_valid_comb = gpr_cr0_xer_in[next].xer_valid;
            spr_rs_id_out_comb = gpr_rs_id_in[next];
            spr_result_reg_addr_out_comb = 1;   // XER is at address 1
            spr_result_out_comb = gpr_cr0_xer_in[next].xer;

            cr_output_valid_comb = gpr_input_valid[next];
            cr_rs_id_out_comb[0] = gpr_rs_id_in[next];
            cr_output_enable_comb[0] = gpr_cr0_xer_in[next].CR0_valid;
            cr_result_out_comb[0:3] = check_condition(gpr_result_in[next], gpr_cr0_xer_in[next].so);

            pointer = pointer_ff + 1;

            spr_chosen = 1;
            cr_chosen = 1;
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

            spr_chosen_ff <= 0;

            spr_output_valid <= 0;
            spr_rs_id_out <= 0;
            spr_result_reg_addr_out <= 0;
            spr_result_out <= 0;

            cr_chosen_ff <= 0;
            cr_pointer_ff <= 0;

            cr_output_valid <= 0;
            cr_rs_id_out <= '{default: '0};
            cr_output_enable <= '{default: '0};
            cr_result_out <= 0;
        end
        else begin
            pointer_ff <= pointer;

            gpr_output_valid <= gpr_output_valid_comb;
            gpr_rs_id_out <= gpr_rs_id_out_comb;
            gpr_result_reg_addr_out <= gpr_result_reg_addr_out_comb;
            gpr_result_out <= gpr_result_out_comb;

            spr_chosen_ff <= spr_chosen;

            spr_output_valid <= spr_output_valid_comb;
            spr_rs_id_out <= spr_rs_id_out_comb;
            spr_result_reg_addr_out <= spr_result_reg_addr_out_comb;
            spr_result_out <= spr_result_out_comb;

            cr_chosen_ff <= cr_chosen;
            cr_pointer_ff <= cr_pointer;

            cr_output_valid <= cr_output_valid_comb;
            cr_rs_id_out <= cr_rs_id_out_comb;
            cr_output_enable <= cr_output_enable_comb;
            cr_result_out <= cr_result_out_comb;
        end
    end
endmodule