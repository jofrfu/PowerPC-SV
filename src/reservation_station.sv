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
    parameter int OPERANDS = 2,     // Describes how many operands are used by instructions
    parameter int OPERAND_WIDTH = 32,   // Describes the bit width of operands
    parameter int RS_OFFSET = 0,    // The address offset of these particular reservation stations
    parameter int RS_DEPTH = 8,     // Describes the number of reservation station for one unit
    parameter int RS_ID_WIDTH = 5,  // The bit width of the ID (or address) of all reservations stations in the system
    parameter type CONTROL_TYPE = add_sub_decode_t  // The control type for the unit
)(
    input logic clk,
    input logic rst,
    
    //------ Simple ready-valid interface for new instructions ------
    input logic                     take_valid,
    output logic                    take_ready,
    
    input logic                     op_value_valid_in[0:OPERANDS-1],
    input logic[0:RS_ID_WIDTH-1]    op_rs_id_in[0:OPERANDS-1],
    input logic[0:OPERAND_WIDTH-1] op_value_in[0:OPERANDS-1],
    input CONTROL_TYPE              control_in,
    
    output logic[0:RS_ID_WIDTH-1]   id_taken,
    //---------------------------------------------------------------
    
    //------ Simple valid interface for updated operands ------
    input logic                     operand_valid[0:OPERANDS-1],
    
    input logic[0:RS_ID_WIDTH-1]    update_op_rs_id_in[0:OPERANDS-1],
    input logic[0:OPERAND_WIDTH-1]  update_op_value_in[0:OPERANDS-1],
    //---------------------------------------------------------
    
    //------ Simple ready-valid interface for output ------
    output logic        output_valid,
    input logic         output_ready,
    
    output logic[0:OPERAND_WIDTH-1] op_value_out[0:OPERANDS-1],
    output CONTROL_TYPE             control_out,
    output logic[0:RS_ID_WIDTH-1]   op_rs_id_out
    //-----------------------------------------------------
);

    typedef struct packed {
        logic valid;
        CONTROL_TYPE control;
        logic[0:OPERANDS-1] op_value_valid;
        logic[0:OPERANDS-1][0:RS_ID_WIDTH-1] op_rs_id;
        logic[0:OPERANDS-1][0:OPERAND_WIDTH-1] op_value;
    } station_t;

    // Storage of reservation stations of a specific unit
    station_t reservation_stations_ff[0:RS_DEPTH-1];
    
    
    logic can_take; // Designates, if the instruction can be taken or not
    logic[0:RS_ID_WIDTH-1] id_take; // Used to inform which reservation station is used to calculate the result
    
    // Checks if there is a free place in reservation stations
    always_comb
    begin
        can_take = 0;
        id_take = RS_OFFSET;
        for(int i = RS_DEPTH-1; i >= 0; i--) begin
            if(~reservation_stations_ff[i].valid) begin
                can_take = 1;
                id_take = i + RS_OFFSET;
            end
        end
    end
    
    assign take_ready = can_take;
    assign id_taken = id_take;
    //------------------------------------
    
    logic can_dispatch; // Designates, if an instruction can be dispatched to the unit
    logic[0:RS_ID_WIDTH-1] id_dispatch; // Used to inform which reservation station should be dispatched
    
    // Checks if there is a reservation station ready for dispatch
    always_comb
    begin
        can_dispatch = 0;
        id_dispatch = RS_OFFSET;
        for(int i = RS_DEPTH-1; i >= 0; i--) begin            
            if(&reservation_stations_ff[i].op_value_valid & reservation_stations_ff[i].valid) begin
                can_dispatch = 1;
                id_dispatch = i + RS_OFFSET;
            end
        end
    end
    
    assign output_valid = can_dispatch;
    for(genvar i = 0; i < OPERANDS; i++) begin
        assign op_value_out[i] = reservation_stations_ff[id_dispatch - RS_OFFSET].op_value[i];
    end
    assign control_out  = reservation_stations_ff[id_dispatch - RS_OFFSET].control;
    assign op_rs_id_out = id_dispatch;
    //------------------------------------
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            reservation_stations_ff <= '{default: '{default: '0}};
        end
        else begin
            // Add the request, if an entry is available
            if(can_take && take_valid) begin
                reservation_stations_ff[id_take - RS_OFFSET].valid   <= 1;
                reservation_stations_ff[id_take - RS_OFFSET].control <= control_in;
                for(int i = 0; i < OPERANDS; i++) begin
                    // The operands needed by the instruction can either come from a register or a unit
                    if(operand_valid[i]) begin
                        if(~op_value_valid_in[i] & update_op_rs_id_in[i] == (id_take - RS_OFFSET)) begin
                            reservation_stations_ff[id_take - RS_OFFSET].op_value_valid[i] <= 1;
                            reservation_stations_ff[id_take - RS_OFFSET].op_value[i]       <= update_op_value_in[i];
                        end
                    end else begin
                        reservation_stations_ff[id_take - RS_OFFSET].op_value_valid[i] <= op_value_valid_in[i];
                        reservation_stations_ff[id_take - RS_OFFSET].op_value[i]       <= op_value_in[i];
                    end
                    reservation_stations_ff[id_take - RS_OFFSET].op_rs_id[i] <= op_rs_id_in[i];
                end
            end
            
            // Reset the entry, if it was dispatched
            if(can_dispatch && output_ready) begin
                reservation_stations_ff[id_dispatch - RS_OFFSET].valid <= 0;
            end
            
            // Update the values of registers in the reservation stations
            for(int i = 0; i < RS_DEPTH; i++) begin
                for(int j = 0; j < OPERANDS; j++) begin
                    if(operand_valid[j]) begin
                        if(reservation_stations_ff[i].valid && ~reservation_stations_ff[i].op_value_valid[j]) begin
                            if(reservation_stations_ff[i].op_rs_id[j] == update_op_rs_id_in[j]) begin
                                reservation_stations_ff[i].op_value_valid[j]    <= 1;
                                reservation_stations_ff[i].op_value[j]          <= update_op_value_in[j];
                            end
                        end
                    end
                end
            end
        end
    end
endmodule