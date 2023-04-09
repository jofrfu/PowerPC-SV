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

module branch_unit(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,

    input branch_inner_decode_t control,
    input logic[0:31] cia_in,
    input logic[0:3] cond_reg_in,
    input logic[0:31] link_reg_in,
    input logic[0:31] count_reg_in,
    
    output logic output_valid,
    input logic output_ready,
    output logic nia_valid,
    output logic[0:31] nia_out,
    output logic link_reg_valid,
    output logic[0:31] link_reg_out,
    output logic count_reg_valid,
    output logic[0:31] count_reg_out
);

    logic[0:31] nia_ext;
    logic[0:31] count_reg;
    logic ctr_ok, cond_ok;
    
    assign ctr_ok = control.BO[2] | ((count_reg != 32'b0) ^ control.BO[3]);
    assign cond_ok = control.BO[0] | (cond_reg_in[control.BI[3:4]] ^ ~control.BO[1]);

    always_comb
    begin
        case(control.operation)
            BRANCH:
            begin
                // Sign extend
                nia_ext = {6{control.LI[0]}, control.LI, 2'b0};

                if(control.AA) begin
                    nia_out = nia_ext;
                end
                else begin
                    nia_out = nia_ext + cia_in;
                end

                nia_valid = 1'b1;

                // Don't cares
                count_reg_valid = 1'b0;
                count_reg_out = 32'bx;
            end
            BRANCH_CONDITIONAL:
            begin
                // Sign extend
                nia_ext = {16{control.BD[0]}, control.BD, 2'b0};

                if(control.BO[2] == 1'b0) begin
                    count_reg_valid = 1'b1;
                    // Decrement counter
                    count_reg = count_reg_in - 1'b1;
                end
                else begin
                    count_reg_valid = 1'b0;
                    count_reg = count_reg_in;
                end
                
                if(ctr_ok && cond_ok) begin
                    nia_valid = 1'b1;
                    if (control.AA) begin
                        nia_out = nia_ext;
                    end
                    else begin
                        nia_out = cia_in + nia_ext;
                    end
                end
                else begin
                    nia_valid = 1'b0;
                    nia_out = 32'bx;
                end

                count_reg_out = count_reg;
            end
            BRANCH_CONDITIONAL_LINK:
            begin
                if(control.BO[2] == 1'b0) begin
                    count_reg_valid = 1'b1;
                    // Decrement counter
                    count_reg = count_reg_in - 1'b1;
                end
                else begin
                    count_reg_valid = 1'b0;
                    count_reg = count_reg_in;
                end
                
                if(ctr_ok && cond_ok) begin
                    nia_valid = 1'b1;
                    nia_out = {link_reg_in[0:29], 2'b00};
                end
                else begin
                    nia_valid = 1'b0;
                    nia_out = 32'bx;
                end

                count_reg_out = count_reg;

                // Don't cares
                nia_ext = 32'bx
            end
            BRANCH_CONDITIONAL_COUNT:
            begin
                if(cond_ok) begin
                    nia_valid = 1'b1;
                    nia_out = count_reg_in[0:29, 2'b00];
                end
                else begin
                    nia_valid = 1'b0;
                    nia_out = 32'bx;
                end

                // Don't cares
                count_reg_valid = 1'b0;
                count_reg_out = 32'bx;
                nia_ext = 32'bx
            end
        endcase

        if(control.LK) begin
            link_reg_valid = 1'b1;
            link_reg_out = cia_in + 4;
        end
        else begin
            link_reg_valid = 1'b0;
            link_reg_out = 32'bx;
        end
    end



endmodule