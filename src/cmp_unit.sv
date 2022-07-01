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

module cmp_unit #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,
    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    input logic[0:2] result_reg_addr_in,    // In this case, the CR are used fro results
    
    input logic[0:31] op1,
    input logic[0:31] op2,
    input logic xer_so,     // We need the SO field
    input cmp_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:2] result_reg_addr_out,
    
    output logic[0:3] result    // The writeback bus is seperate from the GPR writeback bus
);

    logic valid_stages_ff[0:1];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:1];
    logic[0:2] result_reg_addr_stages_ff[0:1];
    cmp_decode_t control_ff;
    
    assign output_valid = valid_stages_ff[1];
    assign rs_id_out = rs_id_stages_ff[1];
    assign result_reg_addr_out = result_reg_addr_stages_ff[1];

    logic[0:31] op1_ff;
    logic[0:31] op2_ff;
    logic so_ff;

    logic[0:3] cr_comb;

    always_comb
    begin
        logic signed[0:32] op1_tmp;
        logic signed[0:32] op2_tmp;

        op1_tmp[1:32] = op1_ff;
        op2_tmp[1:32] = op2_ff;
        if(control_ff.cmp_signed) begin
            op1_tmp[0] = op1_ff[0];
            op2_tmp[0] = op2_ff[0];
        end
        else begin
            op1_tmp[0] = 0;
            op2_tmp[0] = 0;
        end

        if(op1_tmp < op2_tmp) begin
            cr_comb[0:2] = 3'b100;
        end
        else if(op1_tmp > op2_tmp) begin
            cr_comb[0:2] = 3'b010;
        end
        else begin
            cr_comb[0:2] = 3'b001;
        end
        cr_comb[3] = so_ff;
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= {default: '0};
            rs_id_stages_ff             <= {default: {default: '0}};
            result_reg_addr_stages_ff   <= {default: {default: '0}};
            control_ff                  <= {default: '0};
            
            op1_ff <= 0;
            op2_ff <= 0;
            so_ff  <= 0;

            result <= 0;
        end
        else begin
            valid_stages_ff[0]              <= input_valid;
            rs_id_stages_ff[0]              <= rs_id_in;
            result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
            control_ff[0]                   <= control;
            
            op1_ff[0]   <= op1;
            op2_ff[0]   <= op2;
            so_ff       <= xer_so;

            valid_stages_ff[1]              <= valid_stages_ff[0];
            rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
            result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];

            result <= cr_comb;
        end
    end

endmodule