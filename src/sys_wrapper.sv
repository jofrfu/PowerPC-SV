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

module sys_wrapper #(
    parameter int RS_OFFSET = 0,
    parameter int RS_DEPTH = 2,
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    //------ Simple ready-valid interface for new instructions ------
    input logic input_valid,
    output logic input_ready,
    input logic[0:4] result_reg_addr_in,
    
    input logic[0:31] gpr_op,
    input logic gpr_op_valid,
    input logic[0:RS_ID_WIDTH-1] gpr_op_rs_id,
    input logic[0:31] spr_op,
    input logic spr_op_valid,
    input logic[0:RS_ID_WIDTH-1] spr_op_rs_id,
    input logic[0:31] cr_op,
    input logic cr_op_valid,
    input logic[0:RS_ID_WIDTH-1] cr_op_rs_id,
    input system_decode_t control,

    output logic[0:RS_ID_WIDTH-1] id_taken,
    //---------------------------------------------------------------

    //------ Simple valid interface for updated GPR operands ------
    input logic                     update_gpr_op_valid,
    
    input logic[0:RS_ID_WIDTH-1]    update_gpr_op_rs_id_in,
    input logic[0:31]               update_gpr_op_value_in,
    //-------------------------------------------------------------

    //------ Simple valid interface for updated SPR operands ------
    input logic                     update_spr_op_valid,
    
    input logic[0:RS_ID_WIDTH-1]    update_spr_op_rs_id_in,
    input logic[0:31]               update_spr_op_value_in,
    //-------------------------------------------------------------

    //------ Simple valid interface for updated CR operands ------
    input logic                     update_cr_op_valid,
    
    input logic[0:RS_ID_WIDTH-1]    update_cr_op_rs_id_in,
    input logic[0:31]               update_cr_op_value_in,
    //-------------------------------------------------------------
    
    //------ Simple ready-valid interface for GPR results ------
    output logic gpr_output_valid,
    input logic gpr_output_ready,
    output logic[0:RS_ID_WIDTH-1] gpr_rs_id_out,
    output logic[0:4] gpr_result_reg_addr_out,
    
    output logic[0:31] gpr_result,
    //-----------------------------------------------------

    //------ Simple ready-valid interface for GPR results ------
    output logic spr_output_valid,
    input logic spr_output_ready,
    output logic[0:RS_ID_WIDTH-1] spr_rs_id_out,
    output logic[0:9] spr_result_reg_addr_out,
    
    output logic[0:31] spr_result,
    //-----------------------------------------------------

    //------ Simple ready-valid interface for GPR results ------
    output logic cr_output_valid,
    input logic cr_output_ready,
    output logic cr_result_enable[0:7],
    output logic[0:RS_ID_WIDTH-1] cr_rs_id_out,
    
    output logic[0:31] cr_result
    //-----------------------------------------------------
);

    typedef struct {
        system_decode_t sys;
        logic[0:4] result_reg_addr;
    } control_t;

    control_t rs_control_in;

    assign rs_control_in.sys = control;
    assign rs_control_in.result_reg_addr = result_reg_addr_in;


    logic rs_gpr_valid, rs_spr_valid, rs_cr_valid;
    logic rs_gpr_ready, rs_spr_ready, rs_cr_ready;

    logic[0:31] rs_gpr_op, rs_spr_op, rs_cr_op;
    control_t rs_gpr_control_out, rs_spr_control_out, rs_cr_control_out;
    logic[0:RS_ID_WIDTH-1] rs_gpr_id_to_unit, rs_spr_id_to_unit, rs_cr_id_to_unit;

    logic gpr_input_ready, spr_input_ready, cr_input_ready;
    logic[0:RS_ID_WIDTH-1] gpr_id_taken, spr_id_taken, cr_id_taken;

    always_comb
    begin
        case(control.operation)
            SYS_MOVE_TO_SPR:
                begin
                    input_ready = gpr_input_ready;
                    id_taken = gpr_id_taken;
                end
            SYS_MOVE_FROM_SPR:
                begin
                    input_ready = spr_input_ready;
                    id_taken = spr_id_taken;
                end
            SYS_MOVE_TO_CR:
                begin
                    input_ready = gpr_input_ready;
                    id_taken = gpr_id_taken;
                end
            SYS_MOVE_FROM_CR:
                begin
                    input_ready = cr_input_ready;
                    id_taken = cr_id_taken;
                end
            default:
                begin
                    input_ready = 0;
                    id_taken = 0;
                end
        endcase
    end

    reservation_station #(
        .OPERANDS(1),
        .RS_OFFSET(RS_OFFSET),
        .RS_DEPTH(RS_DEPTH),
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .CONTROL_TYPE(control_t)
    ) GPR_RS (
        .clk(clk),
        .rst(rst),

        .take_valid(input_valid & (control.operation == SYS_MOVE_TO_SPR | control.operation == SYS_MOVE_TO_CR)),
        .take_ready(gpr_input_ready),

        .op_value_valid_in({gpr_op_valid}),
        .op_rs_id_in({gpr_op_rs_id}),
        .op_value_in({gpr_op}),
        .control_in(rs_control_in),

        .id_taken(gpr_id_taken),

        .operand_valid({update_gpr_op_valid}),
        .update_op_rs_id_in({update_gpr_op_rs_id_in}),
        .update_op_value_in({update_gpr_op_value_in}),
    
        .output_valid(rs_gpr_valid),
        .output_ready(rs_gpr_ready),

        .op_value_out('{rs_gpr_op}),
        .control_out(rs_gpr_control_out),
        .op_rs_id_out(rs_gpr_id_to_unit)
    );

    reservation_station #(
        .OPERANDS(1),
        .RS_OFFSET(RS_OFFSET),
        .RS_DEPTH(RS_DEPTH),
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .CONTROL_TYPE(control_t)
    ) SPR_RS (
        .clk(clk),
        .rst(rst),

        .take_valid(input_valid & (control.operation == SYS_MOVE_FROM_SPR)),
        .take_ready(spr_input_ready),

        .op_value_valid_in({spr_op_valid}),
        .op_rs_id_in({spr_op_rs_id}),
        .op_value_in({spr_op}),
        .control_in(rs_control_in),

        .id_taken(spr_id_taken),

        .operand_valid({update_spr_op_valid}),
        .update_op_rs_id_in({update_spr_op_rs_id_in}),
        .update_op_value_in({update_spr_op_value_in}),
    
        .output_valid(rs_spr_valid),
        .output_ready(rs_spr_ready),

        .op_value_out('{rs_spr_op}),
        .control_out(rs_spr_control_out),
        .op_rs_id_out(rs_spr_id_to_unit)
    );

    reservation_station #(
        .OPERANDS(1),
        .RS_OFFSET(RS_OFFSET),
        .RS_DEPTH(RS_DEPTH),
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .CONTROL_TYPE(control_t)
    ) CR_RS (
        .clk(clk),
        .rst(rst),

        .take_valid(input_valid & control.operation == SYS_MOVE_FROM_CR),
        .take_ready(cr_input_ready),

        .op_value_valid_in({cr_op_valid}),
        .op_rs_id_in({cr_op_rs_id}),
        .op_value_in({cr_op}),
        .control_in(rs_control_in),

        .id_taken(cr_id_taken),

        .operand_valid({update_cr_op_valid}),
        .update_op_rs_id_in({update_cr_op_rs_id_in}),
        .update_op_value_in({update_cr_op_value_in}),
    
        .output_valid(rs_cr_valid),
        .output_ready(rs_cr_ready),

        .op_value_out('{rs_cr_op}),
        .control_out(rs_cr_control_out),
        .op_rs_id_out(rs_cr_id_to_unit)
    );

    logic rs_output_valid;
    logic rs_output_ready;
    logic[0:RS_ID_WIDTH-1] rs_id_to_unit;
    logic[0:31] rs_op;
    control_t rs_control_out;

    always_comb
    begin
        logic[0:2] valids = {rs_gpr_valid, rs_spr_valid, rs_cr_valid};

        rs_gpr_ready = 0;
        rs_spr_ready = 0;
        rs_cr_ready  = 0;

        case(valids)
            3'b000:
                begin
                    rs_output_valid = 0;
                    rs_id_to_unit = 0;
                    rs_op = 0;
                    rs_control_out = '{default: '{default: '0}};
                end
            3'b100:
                begin
                    rs_output_valid = rs_gpr_valid;
                    rs_gpr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_gpr_id_to_unit;
                    rs_op           = rs_gpr_op;
                    rs_control_out  = rs_gpr_control_out;
                end
            3'b010:
                begin
                    rs_output_valid = rs_spr_valid;
                    rs_spr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_spr_id_to_unit;
                    rs_op           = rs_spr_op;
                    rs_control_out  = rs_spr_control_out;
                end
            3'b001:
                begin
                    rs_output_valid = rs_cr_valid;
                    rs_cr_ready     = rs_output_ready;
                    rs_id_to_unit   = rs_cr_id_to_unit;
                    rs_op           = rs_cr_op;
                    rs_control_out  = rs_cr_control_out;
                end
            3'b110:
                if(rs_gpr_id_to_unit < rs_spr_id_to_unit) begin
                    rs_output_valid = rs_gpr_valid;
                    rs_gpr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_gpr_id_to_unit;
                    rs_op           = rs_gpr_op;
                    rs_control_out  = rs_gpr_control_out;
                end
                else begin
                    rs_output_valid = rs_spr_valid;
                    rs_spr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_spr_id_to_unit;
                    rs_op           = rs_spr_op;
                    rs_control_out  = rs_spr_control_out;
                end
            3'b101:
                if(rs_gpr_id_to_unit < rs_cr_id_to_unit) begin
                    rs_output_valid = rs_gpr_valid;
                    rs_gpr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_gpr_id_to_unit;
                    rs_op           = rs_gpr_op;
                    rs_control_out  = rs_gpr_control_out;
                end
                else begin
                    rs_output_valid = rs_cr_valid;
                    rs_cr_ready     = rs_output_ready;
                    rs_id_to_unit   = rs_cr_id_to_unit;
                    rs_op           = rs_cr_op;
                    rs_control_out  = rs_cr_control_out;
                end
            3'b011:
                if(rs_spr_id_to_unit < rs_cr_id_to_unit) begin
                    rs_output_valid = rs_spr_valid;
                    rs_spr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_spr_id_to_unit;
                    rs_op           = rs_spr_op;
                    rs_control_out  = rs_spr_control_out;
                end
                else begin
                    rs_output_valid = rs_cr_valid;
                    rs_cr_ready     = rs_output_ready;
                    rs_id_to_unit   = rs_cr_id_to_unit;
                    rs_op           = rs_cr_op;
                    rs_control_out  = rs_cr_control_out;
                end
            3'b111:
                if(rs_gpr_id_to_unit < rs_spr_id_to_unit & rs_gpr_id_to_unit < rs_cr_id_to_unit) begin
                    rs_output_valid = rs_gpr_valid;
                    rs_gpr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_gpr_id_to_unit;
                    rs_op           = rs_gpr_op;
                    rs_control_out  = rs_gpr_control_out;
                end
                else if(rs_spr_id_to_unit < rs_gpr_id_to_unit & rs_spr_id_to_unit < rs_cr_id_to_unit) begin
                    rs_output_valid = rs_spr_valid;
                    rs_spr_ready    = rs_output_ready;
                    rs_id_to_unit   = rs_spr_id_to_unit;
                    rs_op           = rs_spr_op;
                    rs_control_out  = rs_spr_control_out;
                end
                else begin
                    rs_output_valid = rs_cr_valid;
                    rs_cr_ready     = rs_output_ready;
                    rs_id_to_unit   = rs_cr_id_to_unit;
                    rs_op           = rs_cr_op;
                    rs_control_out  = rs_cr_control_out;
                end
        endcase
    end

    sys_unit #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) SYS (
        .clk(clk),
        .rst(rst),

        .input_valid(rs_output_valid),
        .input_ready(rs_output_ready),

        .rs_id_in(rs_id_to_unit),
        .result_reg_addr_in(rs_control_out.result_reg_addr),

        .op1(rs_op),
        .control(rs_control_out.sys),

        .gpr_output_valid(gpr_output_valid),
        .gpr_output_ready(gpr_output_ready),
        .gpr_rs_id_out(gpr_rs_id_out),
        .gpr_result_reg_addr_out(gpr_result_reg_addr_out),
        .gpr_result(gpr_result),

        .spr_output_valid(spr_output_valid),
        .spr_output_ready(spr_output_ready),
        .spr_rs_id_out(spr_rs_id_out),
        .spr_result_reg_addr_out(spr_result_reg_addr_out),
        .spr_result(spr_result),

        .cr_output_valid(cr_output_valid),
        .cr_output_ready(cr_output_ready),
        .cr_enable(cr_result_enable),
        .cr_rs_id_out(cr_rs_id_out),
        .cr_result(cr_result)
    );
endmodule