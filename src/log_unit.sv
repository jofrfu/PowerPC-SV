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

module log_unit #(
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
    input logic so,
    input log_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,
    output cond_exception_t cr0_xer
);
    logic valid_stages_ff[0:2];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:2];
    logic[0:4] result_reg_addr_stages_ff[0:2];
    add_sub_decode_t control_stages_ff[0:1];

    logic so_ff[0:1];
    
    assign output_valid = valid_stages_ff[2];
    assign rs_id_out = rs_id_stages_ff[2];
    assign result_reg_addr_out = result_reg_addr_stages_ff[2];

    logic[0:31] op1_ff;
    logic[0:31] op2_ff;

    logic[0:31] and_ff;
    logic[0:31] or_ff;
    logic[0:31] xor_ff;
    logic[0:31] nand_ff;
    logic[0:31] nor_ff;
    logic[0:31] eqv_ff;
    logic[0:31] andc_ff;
    logic[0:31] orc_ff;
    logic[0:31] extb_ff;
    logic[0:31] exth_ff;
    logic[0:31] cnt_comb, cnt_ff;
    // popcntb doesn't seem to exist on 32 bit implementations, but it's not mentioned anywhere

    always_comb
    begin
        cnt_comb = 0;
        for(int i = 0; i < 32; i++) begin
            if(op1_ff[i] == 0) begin
                cnt_comb++;
            end
            else begin
                break;
            end
        end
    end

    logic[0:31] result_comb;

    always_comb
    begin
        case(control_stages_ff[1])
            LOG_AND:
                result_comb = and_ff;
            LOG_OR:
                result_comb = or_ff;
            LOG_XOR:
                result_comb = xor_ff;
            LOG_NAND:
                result_comb = nand_ff;
            LOG_NOR:
                result_comb = nor_ff;
            LOG_EQUIVALENT:
                result_comb = eqv_ff;
            LOG_AND_COMPLEMENT:
                result_comb = andc_ff;
            LOG_OR_COMPLEMENT:
                result_comb = orc_ff;
            LOG_EXTEND_SIGN_BYTE:
                result_comb = extb_ff;
            LOG_EXTEND_SIGN_HALFWORD:
                result_comb = exth_ff;
            LOG_COUNT_LEADING_ZEROS_WORD:
                result_comb = cnt_ff;
            default:
                result_comb = 0;
        endcase
    end

    logic pipe_enable[0:2];

    always_comb
    begin
        pipe_enable[2] = (~valid_stages_ff[2] & valid_stages_ff[1]) | (output_ready & valid_stages_ff[2]);
        pipe_enable[1] = (~valid_stages_ff[1] & valid_stages_ff[0]) | (pipe_enable[2] & valid_stages_ff[1]);
        pipe_enable[0] = (~valid_stages_ff[0] & input_valid) | (pipe_enable[1] & valid_stages_ff[0]);
             
        // If data can move in the pipeline, we can still take input data
        input_ready = Reduction#(3)::or_reduce(pipe_enable);
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= '{default: '0};
            rs_id_stages_ff             <= '{default: '{default: '0}};
            result_reg_addr_stages_ff   <= '{default: '{default: '0}};
            control_stages_ff           <= '{default: '{default: '0}};

            so_ff <= '{default: '0};
                        
            op1_ff <= 0;
            op2_ff <= 0;

            and_ff  <= 0;
            or_ff   <= 0;
            xor_ff  <= 0;
            nand_ff <= 0;
            nor_ff  <= 0;
            eqv_ff  <= 0;
            andc_ff <= 0;
            orc_ff  <= 0;
            extb_ff <= 0;
            exth_ff <= 0;
            cnt_ff  <= 0;

            result  <= 0;
            cr0_xer <= '{default: '0};
        end
        else begin
            if(pipe_enable[0]) begin
                valid_stages_ff[0]              <= input_valid;
                rs_id_stages_ff[0]              <= rs_id_in;
                result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
                control_stages_ff[0]            <= control;

                so_ff[0] <= so;

                op1_ff  <= op1;
                op2_ff  <= op2;
            end

            if(pipe_enable[1]) begin
                valid_stages_ff[1]              <= valid_stages_ff[0];
                rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
                result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];
                control_stages_ff[1]            <= control_stages_ff[0];

                so_ff[1] <= so_ff[0];

                and_ff  <= op1_ff & op2_ff;
                or_ff   <= op1_ff | op2_ff;
                xor_ff  <= op1_ff ^ op2_ff;
                nand_ff <= ~(op1_ff & op2_ff);
                nor_ff  <= ~(op1_ff | op2_ff);
                eqv_ff  <= ~(op1_ff ^ op2_ff);
                andc_ff <= op1_ff & ~op2_ff;
                orc_ff  <= op1_ff | ~op2_ff;
                extb_ff <= {{24{op1_ff[24]}}, op1_ff[24:31]};
                exth_ff <= {{16{op1_ff[16]}}, op1_ff[16:31]};
                cnt_ff  <= cnt_comb;
            end

            if(pipe_enable[2]) begin
                valid_stages_ff[2]              <= valid_stages_ff[1];
                rs_id_stages_ff[2]              <= rs_id_stages_ff[1];
                result_reg_addr_stages_ff[2]    <= result_reg_addr_stages_ff[1];

                result  <= result_comb;
                cr0_xer.CR0_valid <= control_stages_ff[1].alter_CR0;
                cr0_xer.so <= so_ff[1];
                cr0_xer.xer = 0;
                cr0_xer.xer_valid = 0;
            end
        end
    end
endmodule