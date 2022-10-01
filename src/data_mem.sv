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

module data_mem #(
    parameter int RS_ID_WIDTH = 5,
    parameter int MEMORY_DEPTH = 32768
)(
    input logic clk,
    input logic rst,

    input logic input_valid,
    output logic input_ready,

    input logic[0:RS_ID_WIDTH-1] rs_id_in,
    input logic[0:4] result_reg_addr_in,

    input logic[0:31] mem_address,
    input logic[0:3]  mem_write_en,
    input logic[0:31] mem_write_data,
    input logic[0:3]  mem_read_en,



    output logic output_valid,
    input logic output_ready,

    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,

    output logic[0:31] mem_read_data
);

    typedef enum {IDLE, READ_SINGLE, READ_MULTIPLE, WRITE_SINGLE, WRITE_MULTIPLE} state_t;

    state_t state_ff;

    logic[0:$clog2(MEMORY_DEPTH)-1] address_ff;

    // write state registers
    logic[0:3] w_mask_part0_ff, w_mask_part1_ff;
    logic[0:31] w_word_part0_ff, w_word_part1_ff;

    // read state registers
    logic[0:3] r_mask_part0_ff, r_mask_part1_ff;
    logic[0:31] r_word_part0_ff, r_word_part1_ff;


    always_ff @(posedge clk)
    begin
        if(rst) begin
            state_ff = IDLE;
            input_ready = 1'b0;
            address_ff = 0;
            w_mask_part0_ff = 0;
            w_mask_part1_ff = 0;
            w_word_part0_ff = 0;
            w_word_part1_ff = 0;
            r_mask_part0_ff = 0;
            r_mask_part1_ff = 0;
            r_word_part0_ff = 0;
            r_word_part1_ff = 0;
        end
        else begin
            case(state_ff)
                IDLE:
                    begin
                        if(input_valid) begin
                            input_ready = 1'b1;
                            address_ff = mem_address[0:29];
                            if(|mem_write_en) begin
                                case(mem_address[30:31])
                                    2'b00:
                                        begin
                                            state_ff = WRITE_SINGLE;
                                            w_mask_part0_ff = mem_write_en;
                                            w_word_part0_ff = mem_write_data;
                                            w_mask_part1_ff = 4'b0;
                                            w_word_part1_ff = 32'b0;
                                        end
                                    2'b01:
                                        begin
                                            if(mem_write_en[3]) begin
                                                state_ff = WRITE_MULTIPLE;
                                                w_mask_part0_ff = {1'b0, mem_write_en[0:2]};
                                                w_word_part0_ff = {8'b0, mem_write_data[0:23]};
                                                w_mask_part1_ff = {mem_write_en[3], 3'b0};
                                                w_word_part1_ff = {mem_write_data[24:31], 24'b0};
                                            end
                                            else begin
                                                state_ff = WRITE_SINGLE;
                                                w_mask_part0_ff = {1'b0, mem_write_en[0:2]};
                                                w_word_part0_ff = {8'b0, mem_write_data[0:23]};
                                                w_mask_part1_ff = 4'b0;
                                                w_word_part1_ff = 32'b0;
                                            end
                                        end
                                    2'b10:
                                    2'b11:
                                endcase
                            end
                            else if(|mem_read_en) begin

                            end
                        end
                    end
                READ_SINGLE:
                    begin
                        input_ready = 1'b0;
                    end
                READ_MULTIPLE:
                    begin
                        input_ready = 1'b0;
                    end
                WRITE_SINGLE:
                    begin
                        input_ready = 1'b0;
                    end
                WRITE_MULTIPLE:
                    begin
                        input_ready = 1'b0;
                    end
            endcase
        end
    end







    memory mem(
        .clk(clk),


    );
endmodule