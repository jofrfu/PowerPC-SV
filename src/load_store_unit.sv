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

module load_store_unit #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,
    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    input logic[0:4] result_reg_addr_in,
    
    input logic[0:31] op1,
    input logic[0:31] op2,
    input logic[0:31] source,
    input logic store, // 1 = store, 0 = load
    input load_store_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,

    output logic ea_valid,
    input logic ea_ready,
    output logic[0:RS_ID_WIDTH-1] ea_rs_id_out,
    output logic[0:4] ea_reg_addr_out,

    output logic[0:31] effective_address,

    // Interface to data cache or memory
    output logic to_mem_valid,
    input  logic to_mem_ready,
    output logic[0:RS_ID_WIDTH-1] to_mem_rs_id,
    output logic[0:4] to_mem_reg_addr,

    output logic[0:31] mem_address,
    output logic[0:3]  mem_write_en,
    output logic[0:31] mem_write_data,
    output logic[0:3]  mem_read_en,

    // Interface from data cache or memory
    input  logic from_mem_valid,
    output logic from_mem_ready,
    input  logic[0:RS_ID_WIDTH-1] from_mem_rs_id,
    input  logic[0:4] from_mem_reg_addr,

    input  logic[0:31] mem_read_data
);
    logic valid_stages_ff[0:1];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:1];
    logic[0:4] result_reg_addr_stages_ff[0:1];
    load_store_decode_t control_stages_ff[0:1];
    logic store_ff[0:1];


    logic[0:31] op1_ff, op2_ff, source_ff;
    logic[0:31] effective_address_comb, effective_address_ff;
    logic[0:3] wen_comb, wen_ff;
    logic[0:31] write_data_comb, write_data_ff;

    // Effective address output
    logic[0:31] ea_out_ff;
    logic ea_out_valid_ff;
    logic[0:4] ea_reg_addr_ff;
    logic[0:RS_ID_WIDTH-1] ea_rs_id_ff;

    always_comb
    begin
        // Unaligned accesses should be handled in the cache, with the help of the busy and read_data_valid signals
        case(control_stages_ff[0].word_size)
            0:  
                begin
                    wen_comb = 4'b1000;
                    write_data_comb[0:7] = source_ff[24:31];
                    write_data_comb[8:31] = 24'bx;
                end
            1:  
                begin
                    wen_comb = 4'b1100;
                    write_data_comb[0:7] = source_ff[16:23];
                    write_data_comb[8:15] = source_ff[24:31];
                    write_data_comb[16:31] = 16'bx;
                end
            2:  
                begin
                    // This case shouldn't happen!
                    wen_comb = 4'b0000;
                    write_data_comb = source_ff;
                end
            3:  
                begin
                    wen_comb = 4'b1111;
                    write_data_comb = source_ff;
                end
        endcase
    end


    assign effective_address_comb = op1_ff + op2_ff;

    assign to_mem_valid     = valid_stages_ff[1];
    assign to_mem_rs_id     = rs_id_stages_ff[1];
    assign to_mem_reg_addr  = result_reg_addr_stages_ff[1];

    assign mem_address      = effective_address_ff;
    assign mem_write_en     = wen_ff & {4{store_ff[1]}};
    assign mem_read_en      = wen_ff & {4{~store_ff[1]}};
    assign mem_write_data   = write_data_ff;



    assign output_valid         = from_mem_valid;
    assign from_mem_ready       = output_ready;
    assign rs_id_out            = from_mem_rs_id;
    assign result_reg_addr_out  = from_mem_reg_addr;
    assign result               = mem_read_data;



    assign ea_valid             = ea_out_valid_ff;
    assign ea_rs_id_out         = ea_rs_id_ff;
    assign ea_reg_addr_out      = ea_reg_addr_ff;
    assign effective_address    = ea_out_ff;


    logic pipe_enable[0:1];
    logic ea_enable;

    always_comb
    begin
        ea_enable = (~ea_out_valid_ff & valid_stages_ff[0]) | (ea_ready & ea_out_valid_ff);
        pipe_enable[1] = (~valid_stages_ff[1] & valid_stages_ff[0]) | (to_mem_ready & valid_stages_ff[1]);
        pipe_enable[0] = (~valid_stages_ff[0] & input_valid) | (ea_enable & pipe_enable[1] & valid_stages_ff[0]);
             
        // If data can move in the pipeline, we can still take input data
        input_ready = pipe_enable[0] | (pipe_enable[1] & ea_enable);
    end

    always_ff @(posedge clk) 
    begin
        if(rst) begin
            valid_stages_ff             <= '{default: '0};
            rs_id_stages_ff             <= '{default: '{default: '0}};
            result_reg_addr_stages_ff   <= '{default: '{default: '0}};
            control_stages_ff           <= '{default: '{default: '0}};

            op1_ff      <= 32'b0;
            op2_ff      <= 32'b0;
            source_ff   <= 32'b0;

            effective_address_ff    <= 32'b0;
            wen_ff                  <= 4'b0;
            write_data_ff           <= 32'b0;

            ea_out_valid_ff <= 1'b0;
            ea_rs_id_ff     <= 0;
            ea_reg_addr_ff  <= 5'b0;
            ea_out_ff       <= 32'b0;
        end
        else begin

            if(pipe_enable[0]) begin
                valid_stages_ff[0]              <= input_valid;
                rs_id_stages_ff[0]              <= rs_id_in;
                result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
                control_stages_ff[0]            <= control;
                store_ff[0]                     <= store;

                op1_ff      <= op1;
                op2_ff      <= op2;
                source_ff   <= source;
            end

            if(pipe_enable[1]) begin
                valid_stages_ff[1]              <= valid_stages_ff[0] & ea_enable;
                rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
                result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];
                control_stages_ff[1]            <= control_stages_ff[0];
                store_ff[1]                     <= store_ff[0];

                effective_address_ff    <= effective_address_comb;
                wen_ff                  <= wen_comb;
                write_data_ff           <= write_data_comb;
            end

            if(ea_enable) begin
                ea_out_valid_ff <= valid_stages_ff[0] & control_stages_ff[0].write_ea & pipe_enable[1];
                // RS IDs must be unique for results. Odd IDs are reserved for effective address write-backs.
                ea_rs_id_ff     <= rs_id_stages_ff[0] + 1'b1;
                ea_reg_addr_ff  <= result_reg_addr_stages_ff[0];
                ea_out_ff       <= effective_address_comb;
            end
        end    
    end

endmodule