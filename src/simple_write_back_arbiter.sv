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

    typedef struct packed {
        logic gpr_output_valid;
        logic[0:RS_ID_WIDTH-1] gpr_rs_id_out;
        logic[0:4] gpr_result_reg_addr_out;
        logic[0:31] gpr_result_out;
        cond_exception_t gpr_cr0_xer_out;

        logic spr_output_valid;
        logic[0:RS_ID_WIDTH-1] spr_rs_id_out;
        logic[0:9] spr_result_reg_addr_out;
        logic[0:31] spr_result_out;

        logic cr_output_valid;
        logic[0:7][0:RS_ID_WIDTH-1] cr_rs_id_out;
        logic[0:7] cr_output_enable;
        logic[0:31] cr_result_out;
    } busses;

    busses arbitrate_comb, arbitrate_ff;
    logic gpr_enable, cr_enable, spr_enable;

    logic spr_output_valid_comb, spr_output_valid_ff;
    logic[0:RS_ID_WIDTH-1] spr_rs_id_out_comb, spr_rs_id_out_ff;
    logic[0:9] spr_result_reg_addr_out_comb, spr_result_reg_addr_out_ff;
    logic[0:31] spr_result_out_comb, spr_result_out_ff;
    logic spr_chosen, spr_chosen_ff;

    logic cr_output_valid_comb, cr_output_valid_ff;
    logic[0:7][0:RS_ID_WIDTH-1] cr_rs_id_out_comb, cr_rs_id_out_ff;
    logic[0:7] cr_output_enable_comb, cr_output_enable_ff;
    logic[0:31] cr_result_out_comb, cr_result_out_ff;

    logic cr_chosen, cr_chosen_ff;

    logic cr_pointer, cr_pointer_ff;

    logic[0:$clog2(ARBITER_DEPTH)-1] pointer, pointer_ff;
    logic[0:$clog2(ARBITER_DEPTH)-1] next;

    function logic[0:3] check_condition(input logic[0:31] result, input logic so);
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

        gpr_input_ready = '{default: '0};
        gpr_input_ready[next] = gpr_enable;

        arbitrate_comb.gpr_output_valid = gpr_input_valid[next];
        arbitrate_comb.gpr_rs_id_out = gpr_rs_id_in[next];
        arbitrate_comb.gpr_result_reg_addr_out = gpr_result_reg_addr_in[next];
        arbitrate_comb.gpr_result_out = gpr_result_in[next];

        arbitrate_comb.spr_output_valid = gpr_cr0_xer_in[next].xer_valid;
        arbitrate_comb.spr_rs_id_out = gpr_rs_id_in[next];
        arbitrate_comb.spr_result_reg_addr_out = 1;   // XER is at address 1
        arbitrate_comb.spr_result_out = gpr_cr0_xer_in[next].xer;

        arbitrate_comb.cr_output_valid = gpr_cr0_xer_in[next].CR0_valid;
        arbitrate_comb.cr_rs_id_out[1:7] = '{default: '0};
        arbitrate_comb.cr_rs_id_out[0] = gpr_rs_id_in[next];
        arbitrate_comb.cr_output_enable[1:7] = '{default: '0};
        arbitrate_comb.cr_output_enable[0] = gpr_cr0_xer_in[next].CR0_valid;
        arbitrate_comb.cr_result_out[4:31] = '{default: '0};
        arbitrate_comb.cr_result_out[0:3] = check_condition(gpr_result_in[next], gpr_cr0_xer_in[next].so);
    end


    always_comb
    begin
        if(cr_pointer_ff == 0 & (cr_input_valid | ~cmp_cr_input_valid)) begin
            cr_input_ready = cr_enable;
            cmp_cr_input_ready = 1'b0;

            cr_output_valid_comb = cr_input_valid;
            for(int i = 0; i < 8; i++) begin
                cr_rs_id_out_comb[i] = cr_rs_id_in;
                cr_output_enable_comb[i] = cr_input_enable[i];
            end
            cr_result_out_comb = cr_result_in;
            
            cr_pointer = 1'b1;
        end
        else begin
            cr_input_ready = 1'b0;
            cmp_cr_input_ready = cr_enable;

            cr_output_valid_comb = cmp_cr_input_valid;
            for(int i = 0; i < 8; i++) begin
                cr_rs_id_out_comb[i] = cmp_cr_rs_id_in;
            end
            cr_output_enable_comb = 8'b0;
            cr_output_enable_comb[cmp_cr_input_addr] = 1'b1;
            cr_result_out_comb = cmp_cr_result_in;

            cr_pointer = 1'b0;
        end
    end

    always_comb
    begin
        spr_input_ready = spr_enable;

        spr_output_valid_comb = spr_input_valid;
        spr_rs_id_out_comb = spr_rs_id_in;
        spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
        spr_result_out_comb = spr_result_in;
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            pointer_ff <= 0;

            arbitrate_ff <= '{default: '0};

            spr_output_valid_ff <= 0;
            spr_rs_id_out_ff <= 0;
            spr_result_reg_addr_out_ff <= 0;
            spr_result_out_ff <= 0;

            cr_pointer_ff <= 0;

            cr_output_valid_ff <= 0;
            cr_rs_id_out_ff <= '{default: '0};
            cr_output_enable_ff <= '{default: '0};
            cr_result_out_ff <= 0;
        end
        else begin
            if(gpr_enable) begin
                pointer_ff <= pointer;
                arbitrate_ff <= arbitrate_comb;
            end

            if(spr_enable) begin
                spr_output_valid_ff <= spr_output_valid_comb;
                spr_rs_id_out_ff <= spr_rs_id_out_comb;
                spr_result_reg_addr_out_ff <= spr_result_reg_addr_out_comb;
                spr_result_out_ff <= spr_result_out_comb;
            end

            if(cr_enable) begin
                cr_pointer_ff <= cr_pointer;
                cr_output_valid_ff <= cr_output_valid_comb;
                cr_rs_id_out_ff <= cr_rs_id_out_comb;
                cr_output_enable_ff <= cr_output_enable_comb;
                cr_result_out_ff <= cr_result_out_comb;
            end
        end
    end

    busses output_bus_comb;

    always_comb
    begin
        if(spr_chosen_ff & spr_output_valid_ff) begin
            output_bus_comb.gpr_rs_id_out           = arbitrate_ff.gpr_rs_id_out;
            output_bus_comb.gpr_result_reg_addr_out = arbitrate_ff.gpr_result_reg_addr_out;
            output_bus_comb.gpr_result_out          = arbitrate_ff.gpr_result_out;

            output_bus_comb.spr_output_valid        = spr_output_valid_ff;
            output_bus_comb.spr_rs_id_out           = spr_rs_id_out_ff;
            output_bus_comb.spr_result_reg_addr_out = spr_result_reg_addr_out_ff;
            output_bus_comb.spr_result_out          = spr_result_out_ff;

            output_bus_comb.cr_rs_id_out            = arbitrate_ff.cr_rs_id_out;
            output_bus_comb.cr_output_enable        = arbitrate_ff.cr_output_enable;
            output_bus_comb.cr_result_out           = arbitrate_ff.cr_result_out;

            if(~arbitrate_ff.spr_output_valid) begin
                output_bus_comb.gpr_output_valid    = arbitrate_ff.gpr_output_valid;
                output_bus_comb.cr_output_valid     = arbitrate_ff.cr_output_valid;

                gpr_enable = 1'b1;
                spr_enable = 1'b1;
                cr_enable = ~cr_output_valid_ff;
            end
            else begin
                output_bus_comb.gpr_output_valid    = 1'b0;
                output_bus_comb.cr_output_valid     = 1'b0;

                gpr_enable = ~arbitrate_ff.gpr_output_valid;
                spr_enable = 1'b1;
                cr_enable = ~cr_output_valid_ff;
            end

            spr_chosen = 1'b0;
            cr_chosen = cr_chosen_ff;
        end
        else if(cr_chosen_ff & cr_output_valid_ff) begin
            output_bus_comb.gpr_rs_id_out           = arbitrate_ff.gpr_rs_id_out;
            output_bus_comb.gpr_result_reg_addr_out = arbitrate_ff.gpr_result_reg_addr_out;
            output_bus_comb.gpr_result_out          = arbitrate_ff.gpr_result_out;

            output_bus_comb.spr_rs_id_out           = arbitrate_ff.spr_rs_id_out;
            output_bus_comb.spr_result_reg_addr_out = arbitrate_ff.spr_result_reg_addr_out;
            output_bus_comb.spr_result_out          = arbitrate_ff.spr_result_out;

            output_bus_comb.cr_output_valid         = cr_output_valid_ff;
            output_bus_comb.cr_rs_id_out            = cr_rs_id_out_ff;
            output_bus_comb.cr_output_enable        = cr_output_enable_ff;
            output_bus_comb.cr_result_out           = cr_result_out_ff;

            if(~arbitrate_ff.spr_output_valid) begin
                output_bus_comb.gpr_output_valid    = arbitrate_ff.gpr_output_valid;
                output_bus_comb.spr_output_valid    = arbitrate_ff.spr_output_valid;

                gpr_enable = 1'b1;
                spr_enable = ~spr_output_valid_ff;
                cr_enable = 1'b1;
            end
            else begin
                output_bus_comb.gpr_output_valid    = 1'b0;
                output_bus_comb.spr_output_valid     = 1'b0;

                gpr_enable = ~arbitrate_ff.gpr_output_valid;
                spr_enable = ~spr_output_valid_ff;
                cr_enable = 1'b1;
            end

            spr_chosen = spr_chosen_ff;
            cr_chosen = 1'b0;
        end
        else begin
            output_bus_comb.gpr_output_valid        = arbitrate_ff.gpr_output_valid;
            output_bus_comb.gpr_rs_id_out           = arbitrate_ff.gpr_rs_id_out;
            output_bus_comb.gpr_result_reg_addr_out = arbitrate_ff.gpr_result_reg_addr_out;
            output_bus_comb.gpr_result_out          = arbitrate_ff.gpr_result_out;

            output_bus_comb.spr_output_valid        = arbitrate_ff.spr_output_valid;
            output_bus_comb.spr_rs_id_out           = arbitrate_ff.spr_rs_id_out;
            output_bus_comb.spr_result_reg_addr_out = arbitrate_ff.spr_result_reg_addr_out;
            output_bus_comb.spr_result_out          = arbitrate_ff.spr_result_out;

            output_bus_comb.cr_output_valid         = arbitrate_ff.cr_output_valid;
            output_bus_comb.cr_rs_id_out            = arbitrate_ff.cr_rs_id_out;
            output_bus_comb.cr_output_enable        = arbitrate_ff.cr_output_enable;
            output_bus_comb.cr_result_out           = arbitrate_ff.cr_result_out;

            gpr_enable = 1'b1;
            spr_enable = ~spr_output_valid_ff;
            cr_enable = ~cr_output_valid_ff;

            spr_chosen = 1'b1;
            cr_chosen = 1'b1;
        end
    end


    always_ff @(posedge clk)
    begin
        if(rst) begin
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

            cr_output_valid <= 0;
            cr_rs_id_out <= '{default: '0};
            cr_output_enable <= '{default: '0};
            cr_result_out <= 0;
        end
        else begin
            gpr_output_valid <= output_bus_comb.gpr_output_valid;
            gpr_rs_id_out <= output_bus_comb.gpr_rs_id_out;
            gpr_result_reg_addr_out <= output_bus_comb.gpr_result_reg_addr_out;
            gpr_result_out <= output_bus_comb.gpr_result_out;

            spr_chosen_ff <= spr_chosen;

            spr_output_valid <= output_bus_comb.spr_output_valid;
            spr_rs_id_out <= output_bus_comb.spr_rs_id_out;
            spr_result_reg_addr_out <= output_bus_comb.spr_result_reg_addr_out;
            spr_result_out <= output_bus_comb.spr_result_out;

            cr_chosen_ff <= cr_chosen;

            cr_output_valid <= output_bus_comb.cr_output_valid;
            for(int i = 0; i < 8; i++) begin
                cr_rs_id_out[i] <= output_bus_comb.cr_rs_id_out[i];
                cr_output_enable[i] <= output_bus_comb.cr_output_enable[i];
            end
            cr_result_out <= output_bus_comb.cr_result_out;
        end
    end
endmodule