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
    input logic cmp_cr_input_addr[0:2],
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
    logic[0:$clog2(ARBITER_DEPTH)-1] next_without_xer;
    logic[0:$clog2(ARBITER_DEPTH)-1] next_without_cr0;
    logic[0:$clog2(ARBITER_DEPTH)-1] next_without_xer_and_cr0;

    function logic[0:3] check_condition(logic[0:31] result, logic so);
        if(result < 0) begin
            return {3'b100, so};
        end
        else if(result > 0) begin
            return {3'b010, so};
        end
        else begin
            return {3'b001, so};
        end
    endfunction

    typedef struct {
        logic gpr_spr;
        logic gpr_cr;
        logic gpr_cmp;
        logic gpr_spr_cr;
        logic gpr_spr_cmp;
        logic gpr_cr_cmp;
        logic gpr_spr_cr_cmp;
    } collision_t;

    function collision_t check_collision(   
                                            logic[0:$clog2(ARBITER_DEPTH)-1] i,
                                            logic gpr_input_valid[0:ARBITER_DEPTH-1],
                                            cond_exception_t gpr_cr0_xer_in[0:ARBITER_DEPTH-1],
                                            logic spr_input_valid,
                                            logic cr_input_valid,
                                            logic cr_input_enable[0:7],
                                            logic cmp_cr_input_valid,
                                            logic[0:2] cmp_cr_input_addr
                                        );
        check_collision.gpr_spr         = gpr_input_valid[i] & gpr_cr0_xer_in[i].xer_valid & spr_input_valid;
        check_collision.gpr_cr          = gpr_input_valid[i] & gpr_cr0_xer_in[i].CR0_valid & cr_input_valid     & cr_input_enable[0];
        check_collision.gpr_cmp         = gpr_input_valid[i] & gpr_cr0_xer_in[i].CR0_valid & cmp_cr_input_valid & (cmp_cr_input_addr == 0);
        check_collision.gpr_spr_cr      = check_collision.gpr_spr   & check_collision.gpr_cr;
        check_collision.gpr_spr_cmp     = check_collision.gpr_spr   & check_collision.gpr_cmp;
        check_collision.gpr_cr_cmp      = check_collision.gpr_cr    & check_collision.gpr_cmp;
        check_collision.gpr_spr_cr_cmp  = check_collision.gpr_spr   & check_collision.gpr_cr    & check_collision.gpr_cmp;
    endfunction

    always_comb
    begin
        gpr_input_ready = '{default: 0};
        next = 0;
        next_without_xer = 0;
        next_without_cr0 = 0;
        next_without_xer_and_cr0 = 0;

        // Search next
        for(int i = 0; i < ARBITER_DEPTH; i++) begin
            logic current = (pointer_ff + i) % ARBITER_DEPTH;
            if(gpr_input_valid[current]) begin
                next = current;
                break;
            end
        end

        // Search next without XER access
        for(int i = 0; i < ARBITER_DEPTH; i++) begin
            logic current = (pointer_ff + i) % ARBITER_DEPTH;
            if(gpr_input_valid[current] & ~gpr_cr0_xer_in[current].xer_valid) begin
                next_without_xer = current;
                break;
            end
        end

        // Search next without CR0 access
        for(int i = 0; i < ARBITER_DEPTH; i++) begin
            logic current = (pointer_ff + i) % ARBITER_DEPTH;
            if(gpr_input_valid[current] & ~gpr_cr0_xer_in[current].CR0_valid) begin
                next_without_cr0 = current;
                break;
            end
        end

        // Search next without CR0 access
        for(int i = 0; i < ARBITER_DEPTH; i++) begin
            logic current = (pointer_ff + i) % ARBITER_DEPTH;
            if(gpr_input_valid[current] & ~gpr_cr0_xer_in[current].xer_valid & ~gpr_cr0_xer_in[current].CR0_valid) begin
                next_without_xer_and_cr0 = current;
                break;
            end
        end


        collision_t next_collisions                     = check_collision(next, gpr_input_valid, gpr_cr0_xer_in, spr_input_valid, cr_input_valid, cr_input_enable, cmp_cr_input_valid, cmp_cr_input_addr);
        collision_t next_without_xer_collisions         = check_collision(next_without_xer, gpr_input_valid, gpr_cr0_xer_in, spr_input_valid, cr_input_valid, cr_input_enable, cmp_cr_input_valid, cmp_cr_input_addr);
        collision_t next_without_cr_collisions          = check_collision(next_without_cr0, gpr_input_valid, gpr_cr0_xer_in, spr_input_valid, cr_input_valid, cr_input_enable, cmp_cr_input_valid, cmp_cr_input_addr);
        collision_t next_without_xer_and_cr_collisions  = check_collision(next_without_xer_and_cr0, gpr_input_valid, gpr_cr0_xer_in, spr_input_valid, cr_input_valid, cr_input_enable, cmp_cr_input_valid, cmp_cr_input_addr);


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
        cr_rs_id_out_comb = 0;
        cr_output_enable_comb = '{default: '0};
        cr_result_out_comb = 0;



        case({spr_input_valid, cr_input_valid, cmp_cr_input_valid})
            3'b000: // No overlap
                begin
                    gpr_input_ready[next] = 1;

                    gpr_output_valid_comb = gpr_input_valid[next];
                    gpr_rs_id_out_comb = gpr_rs_id_in[next];
                    gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
                    gpr_result_out_comb = gpr_result_in[next];

                    spr_output_valid_comb = gpr_cr0_xer_in[next].xer_valid;
                    spr_rs_id_out_comb = gpr_rs_id_in[next];
                    spr_result_reg_addr_out_comb = 1;   // XER is at address 1
                    spr_result_out_comb = gpr_cr0_xer_in[next].xer;

                    cr_output_valid_comb = gpr_cr0_xer_in[next].CR0_valid;
                    cr_rs_id_out_comb = gpr_rs_id_in[next];
                    cr_output_enable_comb[0] = gpr_cr0_xer_in[next].CR0_valid;
                    cr_result_out_comb[0:3] = check_condition(gpr_result_in[next], gpr_cr0_xer_in[next].so);

                    pointer = next + 1;
                end
            3'b100: // Potential overlap in GPR and SPR
                begin
                    if(spr_chosen_ff) begin
                        spr_input_ready = 1;

                        spr_output_valid_comb = spr_input_valid;
                        spr_rs_id_out_comb = spr_rs_id_in;
                        spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
                        spr_result_out_comb = spr_result_in;

                        // Check for collision
                        if(~next_without_xer_collisions.gpr_spr & ~gpr_cr0_xer_in[next_without_xer].xer_valid) begin
                            // Only on a successful search, we can arbitrate the GPR result
                            gpr_input_ready[next_without_xer] = 1;

                            gpr_output_valid_comb = gpr_input_valid[next_without_xer];
                            gpr_rs_id_out_comb = gpr_rs_id_in[next_without_xer];
                            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next_without_xer];
                            gpr_result_out_comb = gpr_result_in[next_without_xer];

                            cr_output_valid_comb = gpr_cr0_xer_in[next_without_xer].CR0_valid;
                            cr_rs_id_out_comb = gpr_rs_id_in[next_without_xer];
                            cr_output_enable_comb[0] = gpr_cr0_xer_in[next_without_xer].CR0_valid;
                            cr_result_out_comb[0:3] = check_condition(gpr_result_in[next_without_xer], gpr_cr0_xer_in[next_without_xer].so);

                            pointer = next_without_xer + 1;
                        end

                        spr_chosen = 0;
                    end
                    else begin
                        // Check for collision
                        if(~next_without_xer_collisions.gpr_spr & gpr_input_valid[next_without_xer]) begin
                            // Only on a successful search, we can arbitrate the GPR result
                            gpr_input_ready[next_without_xer] = 1;

                            gpr_output_valid_comb = gpr_input_valid[next_without_xer];
                            gpr_rs_id_out_comb = gpr_rs_id_in[next_without_xer];
                            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next_without_xer];
                            gpr_result_out_comb = gpr_result_in[next_without_xer];

                            cr_output_valid_comb = gpr_cr0_xer_in[next_without_xer].CR0_valid;
                            cr_rs_id_out_comb = gpr_rs_id_in[next_without_xer];
                            cr_output_enable_comb[0] = gpr_cr0_xer_in[next_without_xer].CR0_valid;
                            cr_result_out_comb[0:3] = check_condition(gpr_result_in[next_without_xer], gpr_cr0_xer_in[next_without_xer].so);

                            pointer = next_without_xer + 1;

                            spr_input_ready = 1;

                            spr_output_valid_comb = spr_input_valid;
                            spr_rs_id_out_comb = spr_rs_id_in;
                            spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
                            spr_result_out_comb = spr_result_in;
                        end
                        else if(gpr_input_valid[next]) begin
                            // No match found, GPR has priority
                            gpr_input_ready[next] = 1;

                            gpr_output_valid_comb = gpr_input_valid[next];
                            gpr_rs_id_out_comb = gpr_rs_id_in[next];
                            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
                            gpr_result_out_comb = gpr_result_in[next];

                            spr_output_valid_comb = gpr_cr0_xer_in[next].xer_valid;
                            spr_rs_id_out_comb = gpr_rs_id_in[next];
                            spr_result_reg_addr_out_comb = 1;   // XER is at address 1
                            spr_result_out_comb = gpr_cr0_xer_in[next].xer;

                            cr_output_valid_comb = gpr_cr0_xer_in[next].CR0_valid;
                            cr_rs_id_out_comb = gpr_rs_id_in[next];
                            cr_output_enable_comb[0] = gpr_cr0_xer_in[next].CR0_valid;
                            cr_result_out_comb[0:3] = check_condition(gpr_result_in[next], gpr_cr0_xer_in[next].so);

                            pointer = next + 1;
                        end
                        else begin 
                            // GPR is not valid, arbitrate SPR
                            spr_input_ready = 1;

                            spr_output_valid_comb = spr_input_valid;
                            spr_rs_id_out_comb = spr_rs_id_in;
                            spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
                            spr_result_out_comb = spr_result_in;
                        end

                        spr_chosen = 1;
                    end
                end
            3'b010: // Potential overlap in GPR and CR
                begin

                end
            3'b001: // Potential overlap in GPR and CMP
                begin

                end
            3'b110: // Potential overlap in GPR, SPR and CR
                begin

                end
            3'b101: // Potential overlap in GPR and CMP
                begin

                end
            3'b011: // Potential overlap in GPR, CR and CMP
                begin

                end
            3'b111: // Potential overlap in GPR, SPR, CR and CMP
                begin

                end
        endcase











        if(spr_chosen_ff & spr_input_valid) begin
            spr_output_valid_comb = spr_input_valid;
            spr_input_ready = 1;
            spr_rs_id_out_comb = spr_rs_id_in;
            spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
            spr_result_out_comb = spr_result_in;

            // CR requests cannot be executed, because CR and SPR requests are coming from the same unit
            cr_input_ready = 0;

            // Default values
            cr_output_enable_comb = '{default: '0};
            cr_result_out_comb = 0;
            cr_rs_id_out_comb = '{default: '0};

            // Check if compare unit can write in parallel
            if(cmp_cr_input_addr != 0 | ~gpr_cr0_xer_in[next_without_xer].CR0_valid) begin
                cmp_cr_input_ready = 1;

                if(gpr_cr0_xer_in[next_without_xer].CR0_valid) begin
                    cr_output_valid_comb = 1;
                    cr_rs_id_out_comb[0] = gpr_rs_id_in[next_without_xer];
                    cr_output_enable_comb[0] = 1;
                    cr_result_out_comb[0:3] = check_condition(gpr_result_in[next_without_xer], gpr_cr0_xer_in[next_without_xer].so);

                    cr_rs_id_out_comb[cmp_cr_input_addr] = cmp_cr_rs_id_in;
                    cr_output_enable_comb[cmp_cr_input_addr] = 1;
                    cr_result_out_comb[i*4 +: 4] = cmp_cr_result_in;
                end
                else begin
                    cr_output_valid_comb = cmp_cr_input_valid;
                    cr_rs_id_out_comb[cmp_cr_input_addr] = cmp_cr_rs_id_in;
                    cr_output_enable_comb[cmp_cr_input_addr] = 1;
                    cr_result_out_comb[cmp_cr_input_addr*4 +: 4] = cmp_cr_result_in;
                end

                cr_pointer = 0;
            end
            else begin
                cmp_cr_input_ready = 0;

                cr_output_valid_comb = gpr_cr0_xer_in[next_without_xer].CR0_valid;
                cr_rs_id_out_comb[0] = gpr_rs_id_in[next_without_xer];
                cr_output_enable_comb[0] = 1;
                cr_result_out_comb[0:3] = check_condition(gpr_result_in[next_without_xer], gpr_cr0_xer_in[next_without_xer].so);

                cr_pointer = cr_pointer_ff;
            end

            gpr_output_valid_comb = gpr_input_valid[next_without_xer];
            gpr_input_ready[next_without_xer] = ~gpr_cr0_xer_in[next_without_xer].xer_valid;
            gpr_rs_id_out_comb = gpr_rs_id_in[next_without_xer];
            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next_without_xer];
            gpr_result_out_comb = gpr_result_in[next_without_xer];

            if(~gpr_cr0_xer_in[next_without_xer].xer_valid & gpr_input_valid[next_without_xer]) begin
                pointer = next_without_xer + 1;
            end
            else begin
                pointer = pointer_ff + 1;
            end

            spr_chosen = 0;
            cr_chosen = cr_chosen_ff;
        end
        else if(cr_chosen_ff & (cr_input_valid | cmp_cr_input_valid)) begin
            // Default values
            cr_output_enable_comb = '{default: '0};
            cr_rs_id_out_comb = '{default: '0};
            cr_result_out_comb = 0;

            if(~cr_pointer_ff & cr_input_valid) begin
                cr_input_ready = 1;
                cr_output_valid_comb = 1;
                cr_rs_id_out_comb = '{default: cr_rs_id_in};
                cr_output_enable_comb = cr_input_enable;
                cr_result_out_comb = cr_result_in;

                cr_pointer = 1;
            end
            else begin
                cr_input_ready = 1;
                cr_output_valid_comb = 1;
                cr_rs_id_out_comb[cmp_cr_input_addr] = cmp_cr_rs_id_in;
                cr_output_enable_comb[cmp_cr_input_addr] = 1;
                cr_result_out_comb[cmp_cr_input_addr*4 +: 4] = cmp_cr_result_in;

                cr_pointer = 0;
            end

            if((~cr_pointer_ff & cr_input_valid & cr_input_enable[0]) | (cr_pointer_ff & cmp_cr_input_valid & cmp_cr_input_addr == 0)) begin
                gpr_output_valid_comb = gpr_input_valid[next_without_cr0];
                gpr_input_ready[next_without_xer] = ~gpr_cr0_xer_in[next_without_cr0].CR0_valid;
                gpr_rs_id_out_comb = gpr_rs_id_in[next_without_cr0];
                gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next_without_cr0];
                gpr_result_out_comb = gpr_result_in[next_without_cr0];

                if(~gpr_cr0_xer_in[next_without_cr0].CR0_valid & gpr_input_valid[next_without_cr0]) begin
                    pointer = next_without_cr0 + 1;
                end
                else begin
                    pointer = pointer_ff + 1;
                end

                // Check if SPR can be written
                if(gpr_cr0_xer_in[next_without_cr0].xer_valid) begin
                    spr_input_ready = 0;
                    spr_output_valid_comb = gpr_cr0_xer_in[next_without_cr0].xer_valid;
                    spr_rs_id_out_comb = gpr_rs_id_in[next_without_cr0];
                    spr_result_reg_addr_out_comb = 1;   // XER is at address 1
                    spr_result_out_comb = gpr_cr0_xer_in[next_without_cr0].xer;
                end
                else begin
                    spr_input_ready = 1;
                    spr_output_valid_comb = spr_input_valid;
                    spr_rs_id_out_comb = spr_rs_id_in;
                    spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
                    spr_result_out_comb = spr_result_in;
                end
            end
            else begin
                gpr_output_valid_comb = gpr_input_valid[next];
                gpr_input_ready[next_without_xer] = 1;
                gpr_rs_id_out_comb = gpr_rs_id_in[next];
                gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
                gpr_result_out_comb = gpr_result_in[next];

                if(~gpr_cr0_xer_in[next].CR0_valid & gpr_input_valid[next]) begin
                    pointer = next + 1;
                end
                else begin
                    pointer = pointer_ff + 1;
                end

                // Check if SPR can be written
                if(gpr_cr0_xer_in[next].xer_valid) begin
                    spr_input_ready = 0;
                    spr_output_valid_comb = gpr_cr0_xer_in[next].xer_valid;
                    spr_rs_id_out_comb = gpr_rs_id_in[next];
                    spr_result_reg_addr_out_comb = 1;   // XER is at address 1
                    spr_result_out_comb = gpr_cr0_xer_in[next].xer;
                end
                else begin
                    spr_input_ready = 1;
                    spr_output_valid_comb = spr_input_valid;
                    spr_rs_id_out_comb = spr_rs_id_in;
                    spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
                    spr_result_out_comb = spr_result_in;
                end
            end

            spr_chosen = spr_chosen_ff;
            cr_chosen = 0;
        end
        else begin
            // GPR request can be freely executed
            gpr_output_valid_comb = gpr_input_valid[next];
            gpr_input_ready[next] = ~gpr_cr0_xer_in[next].CR0_valid;
            gpr_rs_id_out_comb = gpr_rs_id_in[next];
            gpr_result_reg_addr_out_comb = gpr_result_reg_addr_in[next];
            gpr_result_out_comb = gpr_result_in[next];

            // Check if SPR can be written
            if(gpr_cr0_xer_in[next].xer_valid) begin
                spr_input_ready = 0;
                spr_output_valid_comb = gpr_cr0_xer_in[next].xer_valid;
                spr_rs_id_out_comb = gpr_rs_id_in[next];
                spr_result_reg_addr_out_comb = 1;   // XER is at address 1
                spr_result_out_comb = gpr_cr0_xer_in[next].xer;
            end
            else begin
                spr_input_ready = 1;
                spr_output_valid_comb = spr_input_valid;
                spr_rs_id_out_comb = spr_rs_id_in;
                spr_result_reg_addr_out_comb = spr_result_reg_addr_in;
                spr_result_out_comb = spr_result_in;
            end

            // Default values
            cr_output_enable_comb = '{default: '0};
            cr_rs_id_out_comb = '{default: '0};
            cr_result_out_comb = 0;

            // Check if compare unit can write in parallel
            if((cmp_cr_input_valid & cmp_cr_input_addr != 0) | (cr_input_valid & cr_input_enable[0] == 0) | ~gpr_cr0_xer_in[next].CR0_valid) begin

                if(gpr_cr0_xer_in[next].CR0_valid) begin
                    cr_output_valid_comb = 1;
                    cr_rs_id_out_comb[0] = gpr_rs_id_in[next];
                    cr_output_enable_comb[0] = 1;
                    cr_result_out_comb[0:3] = check_condition(gpr_result_in[next], gpr_cr0_xer_in[next].so);

                    cr_rs_id_out_comb[cmp_cr_input_addr] = cmp_cr_rs_id_in;
                    cr_output_enable_comb[cmp_cr_input_addr] = 1;
                    cr_result_out_comb[i*4 +: 4] = cmp_cr_result_in;
                end
                else begin
                    if(~cr_pointer_ff & cr_input_valid) begin
                        cr_input_ready = 1;
                        cr_output_valid_comb = 1;
                        cr_rs_id_out_comb = '{default: cr_rs_id_in};
                        cr_output_enable_comb = cr_input_enable;
                        cr_result_out_comb = cr_result_in;

                        cr_pointer = 1;
                    end
                    else begin
                        cr_input_ready = 1;
                        cr_output_valid_comb = 1;
                        cr_rs_id_out_comb[cmp_cr_input_addr] = cmp_cr_rs_id_in;
                        cr_output_enable_comb[cmp_cr_input_addr] = 1;
                        cr_result_out_comb[cmp_cr_input_addr*4 +: 4] = cmp_cr_result_in;

                        cr_pointer = 0;
                    end
                end

                cr_pointer = 0;
            end
            else begin
                cmp_cr_input_ready = 0;

                cr_output_valid_comb = gpr_cr0_xer_in[next_without_xer].CR0_valid;
                cr_rs_id_out_comb[0] = gpr_rs_id_in[next_without_xer];
                cr_output_enable_comb[0] = 1;
                cr_result_out_comb[0:3] = check_condition(gpr_result_in[next_without_xer], gpr_cr0_xer_in[next_without_xer].so);

                cr_pointer = cr_pointer_ff;
            end

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

            cr_output_valid <= cr_output_valid_comb;
            cr_rs_id_out <= cr_rs_id_out_comb;
            cr_output_enable <= cr_output_enable_comb;
            cr_result_out <= cr_result_out_comb;
        end
    end
endmodule