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

module div_unit #(
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
    input div_decode_t control,
    
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,
    output cond_exception_t cr0_xer
);

    logic valid_stages_ff[0:1];
    logic[0:RS_ID_WIDTH-1] rs_id_stages_ff[0:1];
    logic[0:4] result_reg_addr_stages_ff[0:1];
    div_decode_t control_stages_ff[0:1];

    logic[0:31] op1_ff[0:1];
    logic[0:31] op2_ff[0:1];

    logic op1_sign_ff;
    logic op2_sign_ff;
    
    logic[0:31] op1_comb;
    logic[0:31] op2_comb;

    logic op1_sign_comb;
    logic op2_sign_comb;
    
    always_comb
    begin
        if(control_stages_ff[0].div_signed) begin
            // Convert to sign magnitude, if necessary
            if(op1_ff[0][0] == 0) begin
                op1_comb = op1_ff[0];
                op1_sign_comb = 0;
            end
            else begin
                op1_comb = ~op1_ff[0] + 1;
                op1_sign_comb = 1;
            end

            if(op2_ff[0][0] == 0) begin
                op2_comb = op2_ff[0];
                op2_sign_comb = 0;
            end
            else begin
                op2_comb = ~op2_ff[0] + 1;
                op2_sign_comb = 1;
            end
        end
        else begin
            op1_comb = op1_ff[0];
            op2_comb = op2_ff[0];

            op1_sign_comb = 0;
            op2_sign_comb = 0;
        end
    end

    logic pipe_enable[0:2];

    always_ff @(posedge clk)
    begin
        if(rst) begin
            valid_stages_ff             <= '{default: '0};
            rs_id_stages_ff             <= '{default: '{default: '0}};
            result_reg_addr_stages_ff   <= '{default: '{default: '0}};
            control_stages_ff           <= '{default: '{default: '0}};

            op1_ff <= '{default: '{default: '0}};
            op2_ff <= '{default: '{default: '0}};

            op1_sign_ff <= 0;
            op2_sign_ff <= 0;
        end
        else begin
            if(pipe_enable[0]) begin
                valid_stages_ff[0]              <= input_valid;
                rs_id_stages_ff[0]              <= rs_id_in;
                result_reg_addr_stages_ff[0]    <= result_reg_addr_in;
                control_stages_ff[0]            <= control;

                op1_ff[0] <= op1;
                op2_ff[0] <= op2;
            end

            if(pipe_enable[1]) begin
                valid_stages_ff[1]              <= valid_stages_ff[0];
                rs_id_stages_ff[1]              <= rs_id_stages_ff[0];
                result_reg_addr_stages_ff[1]    <= result_reg_addr_stages_ff[0];
                control_stages_ff[1]            <= control_stages_ff[0];

                op1_ff[1] <= op1_comb;
                op2_ff[1] <= op2_comb;

                op1_sign_ff <= op1_sign_comb;
                op2_sign_ff <= op2_sign_comb;
            end
        end
    end



    //------ Divider starts here ------

    logic busy_ff;
    logic OV_ff;

    logic[0:RS_ID_WIDTH-1] rs_id_ff;
    logic[0:4] result_reg_addr_ff;
    div_decode_t div_control_ff;
    logic result_sign_ff;

    logic [0:31] final_quotient_ff;
    logic [0:31] final_remainder_ff;
    logic result_valid_ff;

    // Internal divider signals
    logic [0:31] divisor_ff;
    logic [0:31] quotient_ff;
    logic [0:31] quotient_comb;
    logic [0:32] acccumulator_ff;
    logic [0:32] acccumulator_comb;
    logic [0:$clog2(32)-1] i_ff;     // iteration counter

    always_comb 
    begin
        if (acccumulator_ff >= divisor_ff) begin
            acccumulator_comb = acccumulator_ff - divisor_ff;
            {acccumulator_comb, quotient_comb} = {acccumulator_comb[1:32], quotient_ff, 1'b1};
        end 
        else begin
            {acccumulator_comb, quotient_comb} = {acccumulator_ff[1:32], quotient_ff, 1'b0};
        end
    end

    always_ff @(posedge clk) 
    begin
        if(rst) begin
            rs_id_ff <= 0;
            result_reg_addr_ff <= 0;
            div_control_ff <= 0;
            result_sign_ff <= 0;
            result_valid_ff <= 0;
            OV_ff <= 0;

            busy_ff <= 0;
            result_valid_ff <= 0;
            final_quotient_ff <= 0;
            final_remainder_ff <= 0;
            i_ff <= 0;
            acccumulator_ff <= 0;
            quotient_ff <= 0;
        end
        else begin
            if(busy_ff) begin
                if (i_ff == 31) begin  // we're done
                    if(pipe_enable[2] | ~output_valid) begin 
                        // only propagate result, if result register is empty or the output registers are activated
                        busy_ff <= 0;
                        result_valid_ff <= 1;
                        final_quotient_ff <= quotient_comb;
                        final_remainder_ff <= acccumulator_comb[0:31];  // undo final shift
                    end
                end 
                else begin  // next iteration
                    i_ff <= i_ff + 1;
                    acccumulator_ff <= acccumulator_comb;
                    quotient_ff <= quotient_comb;
                end
            end
            else if(valid_stages_ff[1]) begin
                rs_id_ff <= rs_id_stages_ff[1];
                result_reg_addr_ff <= result_reg_addr_stages_ff[1];
                div_control_ff <= control_stages_ff[1];
                result_sign_ff <= op1_sign_ff ^ op2_sign_ff;

                i_ff <= 0;

                // divide by zero and the most negative number divided by -1 (the result wouldn't fit in 32 bits) is undefined
                if(op2_ff[1] == 0 || (op2_sign_ff == 1 && op2_ff[1] == 1 && op1_sign_ff == 1 && op1_ff[1] == 32'h80000000)) begin
                    busy_ff <= 0;
                    OV_ff <= 1;
                    result_valid_ff <= 1;
                    final_quotient_ff <= 0;
                    final_remainder_ff <= 0;
                end
                else begin  // initialize values
                    busy_ff <= 1;
                    OV_ff <= 0;
                    divisor_ff <= op2_ff[1];
                    result_valid_ff <= 0;
                    {acccumulator_ff, quotient_ff} <= {32'b0, op1_ff[1], 1'b0};
                end
            end
            else begin // reset valid signal
                result_valid_ff <= 0;
            end
        end
    end

    //------ Divider ends here ------


    always_comb
    begin
        // After divider
        pipe_enable[2] = (~output_valid & result_valid_ff) | (output_ready & output_valid);
        // Before divider
        pipe_enable[1] = (~valid_stages_ff[1] & valid_stages_ff[0]) | (!busy_ff & valid_stages_ff[1]);
        pipe_enable[0] = (~valid_stages_ff[0] & input_valid) | (pipe_enable[1] & valid_stages_ff[0]);

        input_ready = ~valid_stages_ff[0] | ~valid_stages_ff[1] | ~busy_ff;
    end

    cond_exception_t cr0_xer_comb;
    logic[0:31] result_comb;

    always_comb
    begin
        if(result_sign_ff == 1) begin
            // Convert to two's complement
            result_comb = ~final_quotient_ff + 1;
        end
        else begin
            result_comb = final_quotient_ff;
        end

        cr0_xer_comb.OV = OV_ff;
        cr0_xer_comb.OV_valid = div_control_ff.alter_OV;
        cr0_xer_comb.CA = 0;
        cr0_xer_comb.CA_valid = 0;
        cr0_xer_comb.CR0_valid = div_control_ff.alter_CR0;
    end

    always_ff @(posedge clk)
    begin
        if(rst) begin
            cr0_xer <= '{default: '0};
            result <= 0;
            rs_id_out <= 0;
            result_reg_addr_out <= 0;
            output_valid <= 0;
        end
        else begin
            if(pipe_enable[2]) begin
                cr0_xer <= cr0_xer_comb;
                result <= result_comb;
                rs_id_out <= rs_id_ff;
                result_reg_addr_out <= result_reg_addr_ff;
                output_valid <= result_valid_ff;
            end
        end
    end

endmodule