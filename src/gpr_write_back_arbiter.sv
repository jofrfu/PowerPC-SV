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

module gpr_write_back_arbiter #(
    parameter int RS_ID_WIDTH = 5,
    parameter int ARBITER_DEPTH = 8
)(
    input logic clk,
    input logic rst,

    input logic input_valid[0:ARBITER_DEPTH-1],
    output logic input_ready[0:ARBITER_DEPTH-1],
    input logic[0:RS_ID_WIDTH-1] rs_id_in[0:ARBITER_DEPTH-1],
    input logic[0:4] result_reg_addr_in[0:ARBITER_DEPTH-1],
    input logic[0:31] result_in[0:ARBITER_DEPTH-1],
    input cond_exception_t cr0_xer_in[0:ARBITER_DEPTH-1],

    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    output logic[0:31] result_out,
    output cond_exception_t cr0_xer_out
);

    logic[0:$clog2(ARBITER_DEPTH)-1] pointer, pointer_ff;
    logic next;

    always_comb
    begin
        input_ready = {default: 0};
        next = 0;

        if(input_valid[pointer_ff]) begin
            output_valid = input_valid[pointer_ff];
            input_ready[pointer_ff] = output_ready;
            rs_id_out = rs_id_in[pointer_ff];
            result_reg_addr_out = result_reg_addr_in[pointer_ff];
            result_out = result_in[pointer_ff];
            cr0_xer_out = cr0_xer_in[pointer_ff];

            pointer = pointer_ff + 1;
        end
        else begin
            for(int i = 1; i < ARBITER_DEPTH; i++) begin
                if(input_valid[pointer_ff + i]) begin
                    next = pointer_ff + i;
                    break;
                end
            end

            output_valid = input_valid[next];
            input_ready[next] = output_ready;
            rs_id_out = rs_id_in[next];
            result_reg_addr_out = result_reg_addr_in[next];
            result_out = result_in[next];
            cr0_xer_out = cr0_xer_in[next];

            pointer = next + 1;
        end
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            pointer_ff <= 0;
        end
        else begin
            if(output_ready) begin
                pointer_ff <= pointer;
            end
        end
    end
endmodule