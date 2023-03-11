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
    parameter int RS_ID_WIDTH = 7,
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

    state_t state, state_ff, last_state_ff;

    // write state registers
    logic[0:3] w_mask_part0, w_mask_part1, w_mask_part1_ff;
    logic[0:31] w_word_part0, w_word_part1, w_word_part1_ff;

    // read state registers
    logic[0:3] r_mask, r_mask_ff;
    logic[0:31] r_word, r_word_part0_ff;

    logic[0:$clog2(MEMORY_DEPTH)-1] address, address_part1, address_part1_ff;

    logic[0:1] address_offset, address_offset_ff;
    logic[0:RS_ID_WIDTH-1] stage_rs_id, stage_rs_id_ff;
    logic[0:4] stage_result_reg_addr, stage_result_reg_addr_ff;
    logic stage_output_valid, stage_output_valid_ff;

    always_comb
    begin
        case(state_ff)
            IDLE:
                begin
                    address_offset = mem_address[30:31];
                    stage_rs_id = rs_id_in;
                    stage_result_reg_addr = result_reg_addr_in;
                    r_mask = mem_read_en;

                    if(input_valid) begin
                        input_ready = 1'b1;
                        address = mem_address[0:29];
                        address_part1 = mem_address[0:29] + 1;
                        if(|mem_write_en) begin
                            stage_output_valid = 1'b0;

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
                                        w_word_part0 = {8'bx, mem_write_data[0:23]};
                                        w_mask_part1 = {mem_write_en[3], 3'b0};
                                        w_word_part1 = {mem_write_data[24:31], 24'bx};
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
                                        w_word_part0 = {16'bx, mem_write_data[0:15]};
                                        w_mask_part1 = {mem_write_en[2:3], 2'b0};
                                        w_word_part1 = {mem_write_data[16:31], 16'bx};
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
                                        w_word_part0 = {24'bx, mem_write_data[0:7]};
                                        w_mask_part1 = {mem_write_en[1:3], 1'b0};
                                        w_word_part1 = {mem_write_data[8:31], 8'bx};
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
                            w_mask_part0 = 4'b0;
                            w_mask_part1 = 4'b0;
                            w_word_part0 = 32'bx;
                            w_word_part1 = 32'bx;

                            case(mem_address[30:31])
                                2'b00:
                                    begin
                                        state = IDLE;
                                        stage_output_valid = 1'b1;
                                    end
                                2'b01:
                                    begin
                                        if(mem_read_en[3]) begin
                                            state = READ_MULTIPLE;
                                            stage_output_valid = 1'b0;
                                        end
                                        else begin
                                            state = IDLE;
                                            stage_output_valid = 1'b1;
                                        end
                                    end
                                2'b10:
                                    begin
                                        if(|mem_write_en[2:3]) begin
                                            state = READ_MULTIPLE;
                                            stage_output_valid = 1'b0;
                                        end
                                        else begin
                                            state = IDLE;
                                            stage_output_valid = 1'b1;
                                        end
                                    end
                                2'b11:
                                    begin
                                        if(|mem_write_en[1:3]) begin
                                            state = READ_MULTIPLE;
                                            stage_output_valid = 1'b0;
                                        end
                                        else begin
                                            state = IDLE;
                                            stage_output_valid = 1'b1;
                                        end
                                    end
                            endcase
                        end
                        else begin
                            input_ready = 1'b0;
                            stage_output_valid = 1'b0;
                            w_mask_part0 = 4'b0;
                            w_mask_part1 = 4'b0;
                            w_word_part0 = 32'bx;
                            w_word_part1 = 32'bx;
                        end
                    end
                    else begin
                        input_ready = 1'b0;
                        stage_output_valid = 1'b0;
                        w_mask_part0 = 4'b0;
                        w_mask_part1 = 4'b0;
                        w_word_part0 = 32'bx;
                        w_word_part1 = 32'bx;
                    end
                end
            READ_MULTIPLE:
                begin
                    input_ready = 1'b0;
                    address_offset = address_offset_ff;
                    stage_output_valid = 1'b1;
                    stage_rs_id = stage_rs_id_ff;
                    stage_result_reg_addr = stage_result_reg_addr_ff;
                    r_mask = r_mask_ff;

                    w_mask_part0 = 4'b0;
                    w_mask_part1 = 4'b0;
                    w_word_part0 = 32'bx;
                    w_word_part1 = 32'bx;
                    address = address_part1_ff;
                    address_part1 = 0;

                    state = IDLE;
                end
            WRITE_MULTIPLE:
                begin
                    input_ready = 1'b0;
                    address_offset = 2'bx;
                    stage_rs_id = {RS_ID_WIDTH{1'bx}};
                    stage_result_reg_addr = 5'bx;

                    w_mask_part0 = w_mask_part1_ff;
                    w_word_part0 = w_word_part1_ff;
                    w_mask_part1 = 4'b0;
                    w_word_part1 = 32'bx;
                    address = address_part1_ff;
                    address_part1 = 0;

                    state = IDLE;
                end
        endcase
    end

    logic[0:31] final_read_data;
    logic[0:55] double_word = {r_word_part0_ff, r_word};

    always_comb
    begin
        case(last_state_ff)
            IDLE:
                begin
                    final_read_data = r_word;
                end
            READ_MULTIPLE:
                begin
                    final_read_data = double_word[address_offset_ff*8 +: 32];
                end
            WRITE_MULTIPLE:
                begin
                    final_read_data = 32'bx;
                end
        endcase

        mem_read_data = final_read_data & {{8{r_mask_ff[0]}}, {8{r_mask_ff[1]}}, {8{r_mask_ff[2]}}, {8{r_mask_ff[3]}}};
    end


    logic enable;

    // TODO: Check correctness of the equation. I think the enable has to be used in the input_ready as well to support backpressure!
    assign enable = (output_valid & output_ready) | (stage_output_valid & ~stage_output_valid_ff);

    assign output_valid = stage_output_valid_ff;
    assign rs_id_out = stage_rs_id_ff;
    assign result_reg_addr_out = stage_result_reg_addr_ff;


    always_ff @(posedge clk)
    begin
        if(rst) begin
            state_ff <= IDLE;
            last_state_ff <= IDLE;
            address_part1_ff <= 0;
            w_mask_part1_ff <= 4'b0;
            w_word_part1_ff <= 0;

            r_word_part0_ff <= 0;
            r_mask_ff <= 4'b0;
            address_offset_ff <= 0;
            stage_rs_id_ff <= 0;
            stage_result_reg_addr_ff <= 0;
            stage_output_valid_ff <= 1'b0;
        end
        else begin
            if(enable) begin
                state_ff <= state;
                last_state_ff <= state_ff;
                address_part1_ff <= address_part1;
                w_mask_part1_ff <= w_mask_part1;
                w_word_part1_ff <= w_word_part1;

                r_word_part0_ff <= r_word;
                r_mask_ff <= mem_read_en;
                address_offset_ff <= address_offset;
                stage_rs_id_ff <= stage_rs_id;
                stage_result_reg_addr_ff <= stage_result_reg_addr;
                stage_output_valid_ff <= stage_output_valid;
            end
        end
    end


    memory #(
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) mem (
        .clk(clk),

        .address(address),
        .wen(w_mask_part0),
        .write_data(w_word_part0),

        .read_data(r_word)
    );
endmodule