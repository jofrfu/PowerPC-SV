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
    output cond_exception_t cr0_xer,

    // Interface to data cache or memory
    output logic to_mem_valid,
    input  logic to_mem_ready,
    output logic[0:31] mem_address,
    output logic[0:3]  mem_write_en,
    output logic[0:31] mem_write_data,
    output logic[0:3]  mem_read_en,

    input  logic from_mem_valid,
    output logic from_mem_ready,
    input  logic[0:31] mem_read_data,
    input  logic       mem_read_data_valid
    //
);
    logic valid_stages_ff[0:2 + DATA_MEM_READ_LATENCY];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:2 + DATA_MEM_READ_LATENCY];
    logic[0:4] result_reg_addr_stages_ff[0:2 + DATA_MEM_READ_LATENCY];
    load_store_decode_t control_stages_ff[0:1 + DATA_MEM_READ_LATENCY];
    logic store_ff[0:1 + DATA_MEM_READ_LATENCY];


    logic[0:31] op1_ff, op2_ff, source_ff;
    logic[0:31] effective_address_comb, effective_address_ff;
    logic[0:3] wen_comb, wen_ff;
    logic[0:31] write_data_comb, write_data_ff;

    always_comb
    begin
        // Unaligned accesses should be handled in the cache, with the help of the busy and read_data_valid signals
        if(store_ff[0]) begin
            case(control_stages_ff[0].word_size)
                0:  
                    begin
                        wen_comb = 4'b1000;
                    end
                1:  
                    begin
                        wen_comb = 4'b1100;
                    end
                2:  
                    begin
                        // This case shouldn't happen!
                        wen_comb = 4'b0000;
                    end
                3:  
                    begin
                        wen_comb = 4'b1111;
                    end
            endcase
        end
        else begin
            wen_comb = 4'b0000;
        end

        case(control_stages_ff[0].word_size)
            0:  
                begin
                    write_data_comb[0:7] = source_ff[24:31];
                end
            1:  
                begin
                    write_data_comb[0:7] = source_ff[16:23];
                    write_data_comb[8:15] = source_ff[24:31];
                end
            2:  
                begin
                    // This case shouldn't happen!
                    write_data_comb = source_ff;
                end
            3:  
                begin
                    write_data_comb = source_ff;
                end
        endcase
    end


    assign effective_address_comb = op1_ff + op2_ff;

    assign mem_address      = effective_address_ff;
    assign mem_write_en     = wen_ff & {4{store_ff[1]}};
    assign mem_read_en      = wen_ff & {4{~store_ff[1]}};
    assign mem_write_data   = write_data_ff;


    logic pipe_enable[0:4];



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
                valid_stages_ff[1]              <= valid_stages_ff[0];
                rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
                result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];
                control_stages_ff[1]            <= control_stages_ff[0];
                store_ff[1]                     <= store_ff[0];

                effective_address_ff    <= effective_address_comb;
                wen_ff                  <= wen_comb;
                write_data_ff           <= write_data_comb;
            end
        end    
    end

endmodule