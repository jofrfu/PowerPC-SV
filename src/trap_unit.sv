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

module trap_unit #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,
    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    
    input logic[0:31] op1,
    input logic[0:31] op2,
    input trap_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    
    output logic trap   // The writeback bus is seperate from the GPR writeback bus
);

    logic valid_stages_ff[0:1];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:1];
    trap_decode_t control_ff;
    
    assign output_valid = valid_stages_ff[1];
    assign rs_id_out = rs_id_stages_ff[1];

    logic[0:31] op1_ff;
    logic[0:31] op2_ff;

    logic trap_comb;

    assign trap_comb =  ($signed(op1_ff)    <   $signed(op2_ff) & control_ff.TO[0]) |
                        ($signed(op1_ff)    >   $signed(op2_ff) & control_ff.TO[1]) |
                        ($signed(op1_ff)    ==  $signed(op2_ff) & control_ff.TO[2]) |
                        (op1_ff             <   op2_ff          & control_ff.TO[3]) |
                        (op1_ff             >   op2_ff          & control_ff.TO[4]);

    logic pipe_enable[0:1];

    `declare_or_reduce(2)
    
    always_comb
    begin
        pipe_enable[1] = (~valid_stages_ff[1] & valid_stages_ff[0]) | (output_ready & valid_stages_ff[1]);
        pipe_enable[0] = (~valid_stages_ff[0] & input_valid) | (pipe_enable[1] & valid_stages_ff[0]);
             
        // If data can move in the pipeline, we can still take input data
        input_ready = or_reduce(pipe_enable);
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff <= '{default: '0};
            rs_id_stages_ff <= '{default: '{default: '0}};
            control_ff      <= '{default: '0};
            
            op1_ff <= 0;
            op2_ff <= 0;

            trap <= 0;
        end
        else begin
            if(pipe_enable[0]) begin
                valid_stages_ff[0]              <= input_valid;
                rs_id_stages_ff[0]              <= rs_id_in;
                control_ff                      <= control;
                
                op1_ff   <= op1;
                op2_ff   <= op2;
            end

            if(pipe_enable[1]) begin
                valid_stages_ff[1]              <= valid_stages_ff[0];
                rs_id_stages_ff[1]              <= rs_id_stages_ff[0];

                trap <= trap_comb;
            end
        end
    end

endmodule