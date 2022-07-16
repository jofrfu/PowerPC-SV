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

module ppc_core (
    input logic clk,
    input logic rst,

    input logic instruction_valid,
    output logic instruction_ready,
    input  logic[0:31] instruction
);

    localparam int RS_ID_WIDTH = 5;

    logic decode_valid;
    logic decode_ready;
    decode_result_t decode;

    instruction_decode instr_decode(
        .clk(clk),
        .rst(rst),

        .instruction_valid(instruction_valid),
        .instruction_ready(instruction_ready),
        .instruction(instruction)

        .decode_valid(decode_valid),
        .decode_ready(decode_ready),
        .decode(decode)
    );

    logic[0:RS_ID_WIDTH-1] id_taken;
    logic write_to_gpr;
    logic write_to_spr;
    logic write_to_cr;
    logic alter_CR0;
    logic alter_CA;
    logic alter_OV;

    logic add_sub_valid;
    logic add_sub_ready;
    add_sub_decode_t add_sub_decode;
    logic[0:RS_ID_WIDTH-1] add_sub_id;

    logic mul_valid;
    logic mul_ready;
    mul_decode_t mul_decode;
    logic[0:RS_ID_WIDTH-1] mul_id;

    logic div_valid;
    logic div_ready;
    div_decode_t div_decode;
    logic[0:RS_ID_WIDTH-1] div_id;

    logic log_valid;
    logic log_ready;
    log_decode_t log_decode;
    logic[0:RS_ID_WIDTH-1] log_id;

    logic rot_valid;
    logic rot_ready;
    rotate_decode_t rot_decode;
    logic[0:RS_ID_WIDTH-1] rot_id;

    logic cmp_valid;
    logic cmp_ready;
    cmp_decode_t cmp_decode;
    logic[0:RS_ID_WIDTH-1] cmp_id;

    logic sys_valid;
    logic sys_ready;
    system_decode_t sys_decode;
    logic[0:RS_ID_WIDTH-1] sys_id;

    logic trap_valid;
    logic trap_ready;
    trap_decode_t trap_decode;
    logic[0:RS_ID_WIDTH-1] trap_id;

    dispatcher dispatch(
        .input_valid(decode_valid),
        .input_ready(decode_ready),
        .*
    );

    // GPR read port
    logic[0:4] gpr_read_addr[0:2];
    logic gpr_read_value_valid[0:2];
    logic[0:31] gpr_read_value[0:2];
    logic[0:RS_ID_WIDTH-1] gpr_read_rs_id[0:2];
    // GPR write port
    logic[0:4] gpr_write_addr;
    logic gpr_write_enable;
    logic[0:31] gpr_write_value;
    logic[0:RS_ID_WIDTH-1] gpr_write_rs_id;
    // GPR RS ID update port
    logic[0:4] gpr_update_addr;
    logic gpr_update_enable;
    logic[0:RS_ID_WIDTH-1] gpr_update_rs_id;

    gp_reg_file #(
        .READ_PORTS(3),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) GPRs (
        .clk(clk),
        .rst(rst),

        .read_addr(gpr_read_addr),
        .read_value_valid(gpr_read_value_valid),
        .read_value(gpr_read_value),
        .read_rs_id(gpr_read_rs_id),

        .write_addr(gpr_write_addr),
        .write_enable(gpr_write_enable),
        .write_value(gpr_write_value),
        .write_rs_id(gpr_write_rs_id),

        .update_addr(gpr_update_addr),
        .update_enable(gpr_update_enable),
        .update_rs_id(gpr_update_rs_id)
    );

    // SPR read port
    logic[0:9] spr_read_addr;
    logic spr_read_value_valid;
    logic[0:31] spr_read_value;
    logic[0:RS_ID_WIDTH-1] spr_read_rs_id;
    // SPR write port
    logic[0:9] spr_write_addr;
    logic spr_write_enable;
    logic[0:31] spr_write_value;
    logic[0:RS_ID_WIDTH-1] spr_write_rs_id;
    // SPR RS ID update port
    logic[0:9] spr_update_addr;
    logic spr_update_enable;
    logic[0:RS_ID_WIDTH-1] spr_update_rs_id;

    sp_reg_file #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) SPRs (
        .clk(clk),
        .rst(rst),

        .read_addr(spr_read_addr),
        .read_value_valid(spr_read_value_valid),
        .read_value(spr_read_value),
        .read_rs_id(spr_read_rs_id),

        .write_addr(spr_write_addr),
        .write_enable(spr_write_enable),
        .write_value(spr_write_value),
        .write_rs_id(spr_write_rs_id),

        .update_addr(spr_update_addr),
        .update_enable(spr_update_enable),
        .update_rs_id(spr_update_rs_id)
    );

    // CR read port
    logic cr_read_value_valid[0:7];
    logic[0:31] cr_read_value;
    logic[0:RS_ID_WIDTH-1] cr_read_rs_id[0:7];
    // CR write port
    logic cr_write_enable[0:7];
    logic[0:31] cr_write_value;
    logic[0:RS_ID_WIDTH-1] cr_write_rs_id[0:7];
    // CR RS ID update port
    logic cr_update_enable;
    logic[0:RS_ID_WIDTH-1] cr_update_rs_id;

    cond_reg_file #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) CRs (
        .clk(clk),
        .rst(rst),

        .read_value_valid(cr_read_value_valid),
        .read_value(cr_read_value),
        .read_rs_id(cr_read_rs_id),

        .write_enable(cr_write_enable),
        .write_value(cr_write_value),
        .write_rs_id(cr_write_rs_id),

        .update_enable(cr_update_enable),
        .update_rs_id(cr_update_rs_id)
    );

    // GPR read bus signals
    logic[0:31] gpr_op1, gpr_op2, gpr_target;
    logic[0:RS_ID_WIDTH-1] gpr_op1_rs_id, gpr_op2_rs_id, gpr_target_rs_id;
    logic gpr_op1_valid, gpr_op2_valid, gpr_target_valid;

    assign gpr_read_addr[0] = decode.control.op1_reg_address;
    assign gpr_read_addr[1] = decode.control.op2_reg_address;
    assign gpr_read_addr[2] = decode.control.result_reg_address;
    assign gpr_op1_rs_id = gpr_read_rs_id[0];
    assign gpr_op2_rs_id = gpr_read_rs_id[1];
    assign gpr_target_rs_id = gpr_read_rs_id[2];

    assign gpr_update_addr = decode.control.result_reg_address;
    assign gpr_update_enable = write_to_gpr;
    assign gpr_update_rs_id = id_taken;

    always_comb
    begin
        if(decode.control.op1_use_imm) begin
            gpr_op1 = decode.control.op1_immediate;
            gpr_op1_valid = 1;
        end
        else begin
            gpr_op1 = gpr_read_value[0];
            gpr_op1_valid = gpr_read_value_valid[0];
        end

        if(decode.control.op2_use_imm) begin
            gpr_op2 = decode.control.op2_immediate;
            gpr_op2_valid = 1;
        end
        else begin
            gpr_op2 = gpr_read_value[1];
            gpr_op2_valid = gpr_read_value_valid[1];
        end

        gpr_target = gpr_read_value[2];
        gpr_target_valid = gpr_read_value_valid[2];
    end

    // SPR read bus signals. Address 1 refers to the XER.
    assign spr_read_addr = read_CA ? 1 : sys_decode.SPR;
    assign spr_update_addr = alter_CA ? 1 : sys_decode.SPR;
    assign spr_update_enable = alter_CA | write_to_spr;
    assign spr_update_rs_id = id_taken;


    // Write back signals per unit going to the GPR arbiter. TODO: Add all the units
    logic arbiter_valid[0:0];
    logic arbiter_ready[0:0];
    logic[0:RS_ID_WIDTH-1] arbiter_rs_id[0:0];
    logic[0:4] arbiter_result_reg_addr[0:0];
    logic[0:31] arbiter_result[0:0];
    cond_exception_t arbiter_cr0_xer[0:0];

    // Add and Sub unit signals
    add_sub_wrapper #(
        .RS_OFFSET(0),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) ADD_SUB (
        .clk(clk),
        .rst(rst),

        .input_valid(add_sub_valid),
        .input_ready(add_sub_ready),
        .result_reg_addr_in(decode.control.result_reg_addr_in),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .carry_in(spr_read_value[2]),   // bit 2 is the carry bit
        .carry_valid(spr_read_value_valid),
        .carry_rs_id(spr_read_rs_id),
        .control(add_sub_decode),

        .id_taken(add_sub_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .output_valid(arbiter_valid[0]),
        .output_ready(arbiter_ready[0]),
        .rs_id_out(arbiter_rs_id[0]),
        .result_reg_addr_out(arbiter_result_reg_addr[0]),
        .result(arbiter_result[0]),
        .cr0_xer(arbiter_cr0_xer[0])
    );

    // Arbiter output signals
    logic arbiter_output_valid;
    logic arbiter_rs_id_out;
    logic arbiter_result_reg_addr_out;
    logic arbiter_result_out;
    cond_exception_t arbiter_cr0_xer_out

    // Connect the arbiter output to the GPRs
    assign gpr_write_enable = arbiter_output_valid;
    assign gpr_write_addr = arbiter_result_reg_addr_out;
    assign gpr_write_value = (arbiter_result_out);

    gpr_write_back_arbiter #(
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .ARBITER_DEPTH(1)
    ) GPR_ARBITER (
        .clk(clk),
        .rst(rst),

        .input_valid(arbiter_valid),
        .input_ready(arbiter_ready),
        .rs_id_in(arbiter_rs_id),
        .result_reg_addr_in(arbiter_result_reg_addr),
        .result_in(arbiter_result),
        .cr0_xer_in(arbiter_cr0_xer),

        .output_valid(arbiter_output_valid),
        .output_ready(1), // GPRs always take data
        .rs_id_out(arbiter_rs_id_out),
        .result_reg_addr_out(arbiter_result_reg_addr_out),
        .result_out(arbiter_result_out),
        .cr0_xer_out(arbiter_cr0_xer_out)
    );
endmodule