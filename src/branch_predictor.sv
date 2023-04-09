
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


// The branch predictor also serves as a reservation station with one slot
module branch_predictor #(
    parameter int RS_ID_WIDTH = 5    
)(
    input logic clk,
    input logic rst,
    
    //------ Simple ready-valid interface for new instructions ------
    input logic take_valid,
    output logic take_ready,

    input logic[0:31] cia_in,

    input logic[0:3] cond_reg_in,
    input logic cond_reg_valid_in,
    input logic[0:RS_ID_WIDTH-1] cond_reg_rs_id_in,

    input logic[0:31] link_reg_in,
    input logic link_reg_valid_in,
    input logic[0:RS_ID_WIDTH-1] link_reg_rs_id_in,

    input logic[0:31] count_reg_in,
    input logic count_reg_valid_in,
    input logic[0:RS_ID_WIDTH-1] count_reg_rs_id_in,

    input branch_inner_decode_t control,
    //---------------------------------------------------------------

    //------ Simple valid interface for updated operands ------
    input logic update_cond_reg_valid,
    input logic[0:3] update_cond_reg,
    input logic[0:RS_ID_WIDTH-1] update_cond_reg_rs_id,

    input logic update_link_reg_valid,
    input logic[0:31] update_link_reg,
    input logic[0:RS_ID_WIDTH-1] update_link_reg_rs_id,

    input logic update_count_reg_valid,
    input logic[0:31] update_count_reg,
    input logic[0:RS_ID_WIDTH-1] update_count_reg_rs_id,
    //---------------------------------------------------------
    






    output logic output_valid,
    input logic output_ready,
    output logic nia_valid,
    output logic[0:31] nia_out,
    output logic link_reg_valid_out,
    output logic[0:31] link_reg_out,
    output logic count_reg_valid_out,
    output logic[0:31] count_reg_out,
    
    // Marks all new incoming instructions as speculative
    output logic speculative,
    // Marks all marked instructions as non-sepculative
    output logic clear_speculative,
    // Flushes all speculative instructions in the pipeline
    output logic flush_speculative
)
    typedef enum {INVALID, BRANCHED_SPECULATIVE, BRANCHED} branch_state_t;

    branch_state_t state_ff;

    logic can_take;

    logic cond_valid, cond_valid_ff, link_valid, link_valid_ff, count_valid, count_valid_ff;
    logic[0:3] cond_ff;
    logic[0:31] link_ff, count_ff;
    logic[0:RS_ID_WIDTH-1] cond_rs_id_ff, link_rs_id_ff, count_rs_id_ff;
    branch_inner_decode_t control_ff;


    assign can_take = state_ff == INVALID;
    assign take_ready = can_take;

    assign cond_valid = cond_reg_valid_in & (control.operation != BRANCH | control.BO[0] == 1'b0);
    assign link_valid = link_reg_valid_in & control.operation == BRANCH_CONDITIONAL_LINK;
    assign count_valid = count_reg_valid_in & (control.operation == BRANCH_CONDITIONAL_COUNT | control.BO[2] == 1'b0);

    always_ff @(posedge clk)
    begin
        if(rst) begin
            state_ff <= INVALID;
            cond_valid_ff <= 1'b0;
            link_valid_ff <= 1'b0;
            count_valid_ff <= 1'b0;
            cond_ff <= 4'b0;
            link_ff <= 32'b0;
            count_ff <= 32'b0;
            cond_rs_id_ff <= 0;
            link_rs_id_ff <= 0;
            count_rs_id_ff <= 0;
        end
        else begin
            if(can_take && take_valid) begin
                if(cond_valid & link_valid & count_valid) begin
                    state_ff <= BRANCHED;
                end
                else begin
                    state_ff <= BRANCHED_SPECULATIVE;
                end
            end
        end
    end 




endmodule