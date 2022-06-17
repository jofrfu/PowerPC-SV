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

module reservation_station #(
    parameter int OPERANDS = 2,
    parameter int DEPTH = 8,
    parameter type CONTROL_TYPE = add_sub_decode_t
)(
    input logic clk,
    input logic rst,
    
    // Simple ready-valid interface for input
    input logic input_valid,
    output logic input_ready,
    
    // Simple ready-valid interface for output
    output logic input_valid,
    input logic input_ready,
    
    output logic[0:4] result_reg_addr,
    output logic[0:31] result_value
);

    typedef struct packed {
        logic valid;
        common_control_t common_control;
        CONTROL_TYPE specific_control;
        logic[0:31] op1_value;
        logic[0:31] op2_value;
    } station_t;

    station_t station_fifo[0:DEPTH-1];
    
    always_comb
    begin
        
    end
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            
        end
        else begin
            
        end
    end
endmodule