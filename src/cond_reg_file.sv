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

module cond_reg_file #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    // Read ports are used to read all information about registers
    // including which reservation station holds the data, if the register content is invalid
    output logic                    read_value_valid[0:7],
    output logic[0:31]              read_value,
    output logic[0:RS_ID_WIDTH-1]   read_rs_id[0:7],
    
    // The write port stores the result of units
    input logic                     write_enable[0:7],
    input logic[0:31]               write_value,
    input logic[0:RS_ID_WIDTH-1]    write_rs_id[0:7],
    
    // The update port is used to invalidate data and assign the ID of the reservation station
    // which currently calculates the content of that register
    input logic                     update_enable[0:7],
    input logic[0:RS_ID_WIDTH-1]    update_rs_id
);

    // The condition register is split into 8 registers of 4 bit 
    logic value_valid_ff[0:7];  // Denotes, if the register content is valid or hold by a reservation station
    logic[0:31] value_ff;       // The actual content of a register
    logic[0:RS_ID_WIDTH-1] rs_id_ff[0:7];   // The ID of the reservation station
                                            // which holds the instruction to calculate the content of the register

    always_comb
    begin
        read_value_valid = value_valid_ff;
        read_value       = value_ff;
        read_rs_id       = rs_id_ff;
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            value_valid_ff <= {default: '0};
            value_ff <= 0;
            rs_id_ff <= {default: '0};
        end
        else begin
            for(int i = 0; i < 8; i++) begin
                if(write_enable[i] & rs_id_ff[i] == write_rs_id[i]) begin
                    // Write and validate the register content
                    value_ff[i*4 +: 4]  <= write_value[i*4 +: 4];
                    value_valid_ff[i]   <= 1;
                end
                
                if(update_enable[i]) begin
                    // Invalidate the register content and update the reservation station ID
                    value_valid_ff[i]   <= 0;
                    rs_id_ff[i]         <= update_rs_id;
                end
            end
        end
    end
endmodule