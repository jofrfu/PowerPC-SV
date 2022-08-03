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

module sys_unit #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,
    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    input logic[0:4] result_reg_addr_in,
    
    input logic[0:31] op1,
    input system_decode_t control,
    
    // GPR output bus
    output logic gpr_output_valid,
    input logic gpr_output_ready,
    output logic[0:RS_ID_WIDTH-1] gpr_rs_id_out,
    output logic[0:4] gpr_result_reg_addr_out,
    output logic[0:31] gpr_result,

    // SPR output bus
    output logic spr_output_valid,
    input logic spr_output_ready,
    output logic[0:RS_ID_WIDTH-1] spr_rs_id_out,
    output logic[0:9] spr_result_reg_addr_out,
    output logic[0:31] spr_result,

    // CR output bus
    output logic cr_output_valid,
    input logic cr_output_ready,
    output logic cr_enable[0:7],
    output logic[0:RS_ID_WIDTH-1] cr_rs_id_out,
    output logic[0:31] cr_result
);

    logic valid_stages_ff;
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:1];
    logic[0:4] result_reg_addr_stages_ff[0:1];
    system_decode_t control_stages_ff[0:1];

    assign gpr_rs_id_out = rs_id_stages_ff[1];
    assign spr_rs_id_out = rs_id_stages_ff[1];
    assign cr_rs_id_out = rs_id_stages_ff[1];

    assign gpr_result_reg_addr_out = result_reg_addr_stages_ff[1];
    assign spr_result_reg_addr_out = control_stages_ff[1].SPR;
    for(genvar i = 0; i < 8; i++) begin // Packed to unpacked conversion
        assign cr_enable[i] = control_stages_ff[1].FXM[i];
    end 

    logic[0:31] op1_ff;

    logic gpr_output_valid_comb;
    logic spr_output_valid_comb;
    logic cr_output_valid_comb;

    logic[0:31] gpr_result_comb;
    logic[0:31] spr_result_comb;
    logic[0:31] cr_result_comb;

    logic output_valid, output_ready;

    always_comb
    begin
        gpr_output_valid_comb = 0;
        spr_output_valid_comb = 0;
        cr_output_valid_comb = 0;

        spr_result_comb = op1_ff;
        gpr_result_comb = op1_ff;
        cr_result_comb = op1_ff;

        
        case(control_stages_ff[0].operation)
            SYS_MOVE_TO_SPR:
                begin
                    spr_output_valid_comb = valid_stages_ff;
                    output_ready = spr_output_ready;
                end
            SYS_MOVE_FROM_SPR:
                begin
                    gpr_output_valid_comb = valid_stages_ff;
                    output_ready = gpr_output_ready;
                end
            SYS_MOVE_TO_CR:
                begin
                    cr_output_valid_comb = valid_stages_ff;
                    output_ready = cr_output_ready;
                end
            SYS_MOVE_FROM_CR:
                begin
                    gpr_output_valid_comb = valid_stages_ff;
                    output_ready = gpr_output_ready;
                end
            default:
                begin
                    gpr_output_valid_comb = 0;
                    spr_output_valid_comb = 0;
                    cr_output_valid_comb = 0;
                    output_ready = 0;
                end
        endcase
    end

    logic pipe_enable[0:1];

    `declare_or_reduce(2)

    always_comb
    begin
        pipe_enable[1] = (~output_valid & valid_stages_ff) | (output_ready & valid_stages_ff);
        pipe_enable[0] = (~valid_stages_ff & input_valid) | (pipe_enable[1] & valid_stages_ff);

        // If data can move in the pipeline, we can still take input data
        input_ready = or_reduce(pipe_enable);
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= 0;
            rs_id_stages_ff             <= '{default: '{default: '0}};
            result_reg_addr_stages_ff   <= '{default: '{default: '0}};
            control_stages_ff           <= '{default: '{default: '0}};
        end
        else begin
            if(pipe_enable[0]) begin
                valid_stages_ff                 <= input_valid;
                rs_id_stages_ff[0]              <= rs_id_in;
                result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
                control_stages_ff[0]            <= control;
                
                op1_ff      <= op1;
            end

            if(pipe_enable[1]) begin
                output_valid                    <= valid_stages_ff;
                gpr_output_valid                <= gpr_output_valid_comb;
                spr_output_valid                <= spr_output_valid_comb;
                cr_output_valid                 <= cr_output_valid_comb;
                rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
                result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];
                control_stages_ff[1]            <= control_stages_ff[0];

                gpr_result                      <= gpr_result_comb;
                spr_result                      <= spr_result_comb;
                cr_result                       <= cr_result_comb;
            end
        end
    end
    

endmodule