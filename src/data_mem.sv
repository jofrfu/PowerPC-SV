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

    typedef enum {IDLE, READ_MULTIPLE, WRITE_MULTIPLE} state_t;

    state_t state, state_ff;

    // write state registers
    logic[0:3] w_mask_part0, w_mask_part1, w_mask_part1_ff;
    logic[0:31] w_word_part0, w_word_part1, w_word_part1_ff;

    // read state registers
    logic[0:3] r_mask_part0_ff, r_mask_part1_ff;
    logic[0:31] r_word_part0_ff, r_word_part1_ff;

    logic[0:$clog2(MEMORY_DEPTH)-1] address, address_part1, address_part1_ff;


    always_comb
    begin
        case(state_ff)
            IDLE:
                begin
                    if(input_valid) begin
                        input_ready = 1'b1;
                        address = mem_address[0:29];
                        address_part1 = mem_address[0:29] + 1;
                        if(|mem_write_en) begin
                            case(mem_address[30:31])
                                2'b00:
                                    begin
                                        state = IDLE;
                                        w_mask_part0 = mem_write_en;
                                        w_word_part0 = mem_write_data;
                                        w_mask_part1 = 0;
                                        w_word_part1 = 0;
                                    end
                                2'b01:
                                    begin
                                        w_mask_part0 = {1'b0, mem_write_en[0:2]};
                                        w_word_part0 = {8'b0, mem_write_data[0:23]};
                                        w_mask_part1 = {mem_write_en[3], 3'b0};
                                        w_word_part1 = {mem_write_data[24:31], 24'b0};
                                        if(mem_write_en[3]) begin
                                            state = WRITE_MULTIPLE;
                                        end
                                        else begin
                                            state = IDLE;
                                        end
                                    end
                                2'b10:
                                    begin
                                        w_mask_part0 = {2'b0, mem_write_en[0:1]};
                                        w_word_part0 = {16'b0, mem_write_data[0:15]};
                                        w_mask_part1 = {mem_write_en[2:3], 2'b0};
                                        w_word_part1 = {mem_write_data[16:31], 16'b0};
                                        if(|mem_write_en[2:3]) begin
                                            state = WRITE_MULTIPLE;
                                        end
                                        else begin
                                            state = IDLE;
                                        end
                                    end
                                2'b11:
                                    begin
                                        w_mask_part0 = {3'b0, mem_write_en[0]};
                                        w_word_part0 = {24'b0, mem_write_data[0:7]};
                                        w_mask_part1 = {mem_write_en[1:3], 3'b0};
                                        w_word_part1 = {mem_write_data[8:31], 8'b0};
                                        if(|mem_write_en[1:3]) begin
                                            state = WRITE_MULTIPLE;
                                        end
                                        else begin
                                            state = IDLE;
                                        end
                                    end
                            endcase
                        end
                        else if(|mem_read_en) begin
                            input_ready = 1'b1;
                        end
                        else begin
                            input_ready = 1'b0;
                        end
                    end
                end
            READ_MULTIPLE:
                begin
                    input_ready = 1'b0;
                end
            WRITE_MULTIPLE:
                begin
                    input_ready = 1'b0;

                    w_mask_part0 = w_mask_part1_ff;
                    w_word_part0 = w_word_part1_ff;
                    w_mask_part1 = 0;
                    w_word_part1 = 0;
                    address = address_part1_ff;
                    address_part1 = 0;

                    state = IDLE;
                end
        endcase
    end






    always_ff @(posedge clk)
    begin
        if(rst) begin
            state_ff <= IDLE;
            address_part1_ff <= 0;
            w_mask_part1_ff <= 0;
            w_word_part1_ff <= 0;
        end
        else begin
            state_ff <= state;
            address_part1_ff <= address_part1;
            w_mask_part1_ff <= w_mask_part1;
            w_word_part1_ff <= w_word_part1;
        end
    end







    memory mem #(
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    )(
        .clk(clk),

        .address(address),
        .wen(w_mask_part0),
        .write_data(w_word_part0),

        .read_data(mem_read_data)
    );
endmodule