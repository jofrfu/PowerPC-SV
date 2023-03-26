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

module gp_reg_file #(
    parameter int READ_PORTS = 1,
    parameter int WRITE_PORTS = 1,
    parameter int UPDATE_PORTS = 1,
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    // Read ports are used to read all information about registers
    // including which reservation station holds the data, if the register content is invalid
    input logic[0:4]                read_addr[0:READ_PORTS-1],
    output logic                    read_value_valid[0:READ_PORTS-1],
    output logic[0:31]              read_value[0:READ_PORTS-1],
    output logic[0:RS_ID_WIDTH-1]   read_rs_id[0:READ_PORTS-1],
    
    // The write port stores the result of units
    input logic[0:4]                write_addr[0:WRITE_PORTS-1],
    input logic                     write_enable[0:WRITE_PORTS-1],
    input logic[0:31]               write_value[0:WRITE_PORTS-1],
    input logic[0:RS_ID_WIDTH-1]    write_rs_id[0:WRITE_PORTS-1],
    
    // The update port is used to invalidate data and assign the ID of the reservation station
    // which currently calculates the content of that register
    input logic[0:4]                update_addr[0:UPDATE_PORTS-1],
    input logic                     update_enable[0:UPDATE_PORTS-1],
    input logic[0:RS_ID_WIDTH-1]    update_rs_id[0:UPDATE_PORTS-1]
);
    
    typedef struct packed {
        logic value_valid;  // Denotes, if the register content is valid or hold by a reservation station
        logic[0:31] value;  // The actual content of a register
        logic[0:RS_ID_WIDTH-1] rs_id;   // The ID of the reservation station
                                        // which holds the instruction to calculate the content of the register
    } register_t;
    
    register_t registers_ff[0:31];
    
    always_comb
    begin
        for(int i = 0; i < READ_PORTS; i++) begin
            read_value_valid[i] = registers_ff[read_addr[i]].value_valid;
            read_value[i]       = registers_ff[read_addr[i]].value;
            read_rs_id[i]       = registers_ff[read_addr[i]].rs_id;
        end
    end
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            registers_ff <= '{default: '{default: '0}};
        end
        else begin
            for(int i = 0; i < WRITE_PORTS; i++) begin
                if(write_enable[i] & registers_ff[write_addr[i]].rs_id == write_rs_id[i]) begin
                    // Write and validate the register content
                    registers_ff[write_addr[i]].value       <= write_value[i];
                    registers_ff[write_addr[i]].value_valid <= 1;
                end
            end
            
            for(int i = 0; i < UPDATE_PORTS; i++) begin
                if(update_enable[i]) begin
                    // Invalidate the register content and update the reservation station ID
                    registers_ff[update_addr[i]].value_valid    <= 0;
                    registers_ff[update_addr[i]].rs_id          <= update_rs_id[i];
                end
            end
        end
    end
endmodule