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

module div_wrapper #(
    parameter int RS_OFFSET = 0,
    parameter int RS_DEPTH = 8,
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    //------ Simple ready-valid interface for new instructions ------
    input logic input_valid,
    output logic input_ready,
    input logic[0:4] result_reg_addr_in,
    
    input logic[0:31] op1,
    input logic op1_valid,
    input logic[0:RS_ID_WIDTH-1] op1_rs_id,
    input logic[0:31] op2,
    input logic op2_valid,
    input logic[0:RS_ID_WIDTH-1] op2_rs_id,
    input div_decode_t control,

    output logic[0:RS_ID_WIDTH-1] id_taken,
    //---------------------------------------------------------------

    //------ Simple valid interface for updated GPR operands ------
    input logic                     update_op_valid,
    
    input logic[0:RS_ID_WIDTH-1]    update_op_rs_id_in,
    input logic[0:31]               update_op_value_in,
    //-------------------------------------------------------------
    
    //------ Simple ready-valid interface for results ------
    output logic output_valid,
    input logic output_ready,
    output logic[0:RS_ID_WIDTH-1] rs_id_out,
    output logic[0:4] result_reg_addr_out,
    
    output logic[0:31] result,
    output cond_exception_t cr0_xer
    //-----------------------------------------------------
);

    typedef struct {
        div_decode_t div;
        logic[0:4] result_reg_addr;
    } control_t;

    control_t rs_control_in;

    assign rs_control_in.div = control;
    assign rs_control_in.result_reg_addr = result_reg_addr_in;


    logic rs_output_valid;
    logic rs_output_ready;

    logic[0:31] rs_op1, rs_op2;
    control_t rs_control_out;
    logic[0:RS_ID_WIDTH-1] rs_id_to_unit;

    reservation_station #(
        .OPERANDS(2),
        .RS_OFFSET(RS_OFFSET),
        .RS_DEPTH(RS_DEPTH),
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .CONTROL_TYPE(control_t)
    ) RS (
        .clk(clk),
        .rst(rst),

        .take_valid(input_valid),
        .take_ready(input_ready),

        .op_value_valid_in({op1_valid, op2_valid}),
        .op_rs_id_in({op1_rs_id, op2_rs_id}),
        .op_value_in({op1, op2}),
        .control_in(rs_control_in),

        .id_taken(id_taken),

        .operand_valid({update_op_valid, update_op_valid}),
        .update_op_rs_id_in({update_op_rs_id_in, update_op_rs_id_in}),
        .update_op_value_in({update_op_value_in, update_op_value_in}),
    
        .output_valid(rs_output_valid),
        .output_ready(rs_output_ready),

        .op_value_out('{rs_op1, rs_op2}),
        .control_out(rs_control_out),
        .op_rs_id_out(rs_id_to_unit)
    );

    div_unit #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) DIV (
        .clk(clk),
        .rst(rst),

        .input_valid(rs_output_valid),
        .input_ready(rs_output_ready),

        .rs_id_in(rs_id_to_unit),
        .result_reg_addr_in(rs_control_out.result_reg_addr),

        .op1(rs_op1),
        .op2(rs_op2),
        .control(rs_control_out.div),

        .output_valid(output_valid),
        .output_ready(output_ready),

        .rs_id_out(rs_id_out),
        .result_reg_addr_out(result_reg_addr_out),
        .result(result),
        .cr0_xer(cr0_xer)
    );
endmodule