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

// synthesis translate_off
`include "ppc_types.sv"
// synthesis translate_on

import ppc_types::*;

module ppc_core (
    input logic clk,
    input logic rst,

    input logic instruction_valid,
    output logic instruction_ready,
    input  logic[0:31] instruction,

    //------ Interface to data cache or memory ------
    output logic to_mem_valid,
    input  logic to_mem_ready,
    output logic[0:RS_ID_WIDTH-1] to_mem_rs_id,
    output logic[0:4] to_mem_reg_addr,

    output logic[0:31] mem_address,
    output logic[0:3]  mem_write_en,
    output logic[0:31] mem_write_data,
    output logic[0:3]  mem_read_en,
    //-----------------------------------------------

    //------ Interface from data cache or memory ------
    input  logic from_mem_valid,
    output logic from_mem_ready,
    input  logic[0:RS_ID_WIDTH-1] from_mem_rs_id,
    input  logic[0:4] from_mem_reg_addr,

    input  logic[0:31] mem_read_data,
    //-------------------------------------------------

    output logic trap
);

    localparam int RS_ID_WIDTH = 7;

    logic decode_valid;
    logic decode_ready;
    decode_result_t decode;

    instruction_decode instr_decode(
        .clk(clk),
        .rst(rst),

        .instruction_valid(instruction_valid),
        .instruction_ready(instruction_ready),
        .instruction(instruction),

        .decode_valid(decode_valid),
        .decode_ready(decode_ready),
        .decode(decode)
    );

    logic[0:RS_ID_WIDTH-1] id_taken;
    logic write_to_gpr;
    logic write_to_spr;
    logic write_to_cr;
    logic alter_xer;
    logic alter_CR0;
    logic read_xer;

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

    logic load_store_valid;
    logic load_store_ready;
    load_store_decode_t load_store_decode;
    logic store_not_load;
    logic[0:RS_ID_WIDTH-1] load_store_id;

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

    dispatcher #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) dispatch(
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

        .read_addr('{spr_read_addr}),
        .read_value_valid('{spr_read_value_valid}),
        .read_value('{spr_read_value}),
        .read_rs_id('{spr_read_rs_id}),

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
    logic cr_update_enable[0:7];
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

    assign gpr_read_addr[0] = decode.fixed_point.control.op1_reg_address;
    assign gpr_read_addr[1] = decode.fixed_point.control.op2_reg_address;
    assign gpr_read_addr[2] = decode.fixed_point.control.result_reg_address;
    assign gpr_op1_rs_id = gpr_read_rs_id[0];
    assign gpr_op2_rs_id = gpr_read_rs_id[1];
    assign gpr_target_rs_id = gpr_read_rs_id[2];

    assign gpr_update_addr = decode.fixed_point.control.result_reg_address;
    assign gpr_update_enable = write_to_gpr & decode_valid & decode_ready;
    assign gpr_update_rs_id = id_taken;

    always_comb
    begin
        if(decode.fixed_point.control.op1_use_imm) begin
            gpr_op1 = decode.fixed_point.control.op1_immediate;
            gpr_op1_valid = 1;
        end
        else begin
            gpr_op1 = gpr_read_value[0];
            gpr_op1_valid = gpr_read_value_valid[0];
        end

        if(decode.fixed_point.control.op2_use_imm) begin
            gpr_op2 = decode.fixed_point.control.op2_immediate;
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
    assign spr_read_addr = read_xer ? 1 : sys_decode.SPR;
    assign spr_update_addr = alter_xer ? 1 : sys_decode.SPR;
    assign spr_update_enable = (alter_xer | write_to_spr) & decode_valid & decode_ready;
    assign spr_update_rs_id = id_taken;

    // CR update bus assignments
    assign cr_update_rs_id = id_taken;
    for(genvar i = 0; i < 8; i++) begin
        if(i == 0) begin
            assign cr_update_enable[i] = (sys_decode.FXM[i] | decode.fixed_point.control.result_reg_address == i | alter_CR0) & write_to_cr & decode_valid & decode_ready;
        end
        else begin
            assign cr_update_enable[i] = (sys_decode.FXM[i] | decode.fixed_point.control.result_reg_address == i) & write_to_cr & decode_valid & decode_ready;
        end
    end

    // Write back signals per unit going to the GPR arbiter. TODO: Add all the units
    logic arbiter_valid[0:6];
    logic arbiter_ready[0:6];
    logic[0:RS_ID_WIDTH-1] arbiter_rs_id[0:6];
    logic[0:4] arbiter_result_reg_addr[0:6];
    logic[0:31] arbiter_result[0:6];
    cond_exception_t arbiter_cr0_xer[0:6];

    logic arbiter_spr_valid;
    logic arbiter_spr_ready;
    logic[0:RS_ID_WIDTH-1] arbiter_spr_rs_id;
    logic[0:4] arbiter_spr_result_reg_addr;
    logic[0:31] arbiter_spr_result;

    logic arbiter_cr_valid;
    logic arbiter_cr_ready;
    logic[0:RS_ID_WIDTH-1] arbiter_cr_rs_id;
    logic arbiter_cr_enable[0:7];
    logic[0:31] arbiter_cr_result;

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
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .xer_in(spr_read_value),
        .xer_valid(spr_read_value_valid | ~read_xer),
        .xer_rs_id(spr_read_rs_id),
        .control(add_sub_decode),

        .id_taken(add_sub_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .update_xer_valid(spr_write_enable),
        .update_xer_rs_id_in(spr_write_rs_id),
        .update_xer_value_in(spr_write_value),

        .output_valid(arbiter_valid[0]),
        .output_ready(arbiter_ready[0]),
        .rs_id_out(arbiter_rs_id[0]),
        .result_reg_addr_out(arbiter_result_reg_addr[0]),
        .result(arbiter_result[0]),
        .cr0_xer(arbiter_cr0_xer[0])
    );

    // Mul unit signals
    mul_wrapper #(
        .RS_OFFSET(8),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) MUL (
        .clk(clk),
        .rst(rst),

        .input_valid(mul_valid),
        .input_ready(mul_ready),
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .xer(spr_read_value),
        .xer_valid(spr_read_value_valid | ~read_xer),
        .xer_rs_id(spr_read_rs_id),
        .control(mul_decode),

        .id_taken(mul_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .update_xer_valid(spr_write_enable),
        .update_xer_rs_id_in(spr_write_rs_id),
        .update_xer_value_in(spr_write_value),

        .output_valid(arbiter_valid[1]),
        .output_ready(arbiter_ready[1]),
        .rs_id_out(arbiter_rs_id[1]),
        .result_reg_addr_out(arbiter_result_reg_addr[1]),
        .result(arbiter_result[1]),
        .cr0_xer(arbiter_cr0_xer[1])
    );

    // Div unit signals
    div_wrapper #(
        .RS_OFFSET(16),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) DIV (
        .clk(clk),
        .rst(rst),

        .input_valid(div_valid),
        .input_ready(div_ready),
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .xer(spr_read_value),
        .xer_valid(spr_read_value_valid | ~read_xer),
        .xer_rs_id(spr_read_rs_id),
        .control(div_decode),

        .id_taken(div_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .update_xer_valid(spr_write_enable),
        .update_xer_rs_id_in(spr_write_rs_id),
        .update_xer_value_in(spr_write_value),

        .output_valid(arbiter_valid[2]),
        .output_ready(arbiter_ready[2]),
        .rs_id_out(arbiter_rs_id[2]),
        .result_reg_addr_out(arbiter_result_reg_addr[2]),
        .result(arbiter_result[2]),
        .cr0_xer(arbiter_cr0_xer[2])
    );

    // Log unit signals
    log_wrapper #(
        .RS_OFFSET(24),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) LOG (
        .clk(clk),
        .rst(rst),

        .input_valid(log_valid),
        .input_ready(log_ready),
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .xer(spr_read_value),
        .xer_valid(spr_read_value_valid | ~read_xer),
        .xer_rs_id(spr_read_rs_id),
        .control(log_decode),

        .id_taken(log_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .update_xer_valid(spr_write_enable),
        .update_xer_rs_id_in(spr_write_rs_id),
        .update_xer_value_in(spr_write_value),

        .output_valid(arbiter_valid[3]),
        .output_ready(arbiter_ready[3]),
        .rs_id_out(arbiter_rs_id[3]),
        .result_reg_addr_out(arbiter_result_reg_addr[3]),
        .result(arbiter_result[3]),
        .cr0_xer(arbiter_cr0_xer[3])
    );

    // Rot unit signals
    rot_wrapper #(
        .RS_OFFSET(32),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) ROT (
        .clk(clk),
        .rst(rst),

        .input_valid(rot_valid),
        .input_ready(rot_ready),
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .target(gpr_target),
        .target_valid(gpr_target_valid),
        .target_rs_id(gpr_target_rs_id),
        .xer(spr_read_value),
        .xer_valid(spr_read_value_valid | ~read_xer),
        .xer_rs_id(spr_read_rs_id),
        .control(rot_decode),

        .id_taken(rot_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .update_xer_valid(spr_write_enable),
        .update_xer_rs_id_in(spr_write_rs_id),
        .update_xer_value_in(spr_write_value),

        .output_valid(arbiter_valid[4]),
        .output_ready(arbiter_ready[4]),
        .rs_id_out(arbiter_rs_id[4]),
        .result_reg_addr_out(arbiter_result_reg_addr[4]),
        .result(arbiter_result[4]),
        .cr0_xer(arbiter_cr0_xer[4])
    );

    // Load/store unit signals
    load_store_wrapper #(
        .RS_OFFSET(40),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) LOAD_STORE (
        .clk(clk),
        .rst(rst),

        .input_valid(load_store_valid),
        .input_ready(load_store_ready),
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .source(gpr_target),
        .source_valid(gpr_target_valid),
        .source_rs_id(gpr_target_rs_id),

        .control(load_store_decode),
        .store(store_not_load),

        .id_taken(load_store_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .output_valid(arbiter_valid[5]),
        .output_ready(arbiter_ready[5]),
        .rs_id_out(arbiter_rs_id[5]),
        .result_reg_addr_out(arbiter_result_reg_addr[5]),
        .result(arbiter_result[5]),

        .to_mem_valid(to_mem_valid),
        .to_mem_ready(to_mem_ready),
        .to_mem_rs_id(to_mem_rs_id),
        .to_mem_reg_addr(to_mem_reg_addr),

        .mem_address(mem_address),
        .mem_write_en(mem_write_en),
        .mem_write_data(mem_write_data),
        .mem_read_en(mem_read_en),

        .from_mem_valid(from_mem_valid),
        .from_mem_ready(from_mem_ready),
        .from_mem_rs_id(from_mem_rs_id),
        .from_mem_reg_addr(from_mem_reg_addr),

        .mem_read_data(mem_read_data)
    );

    assign arbiter_cr0_xer[5] = '{default: '0};

    logic cmp_output_valid;
    logic cmp_output_ready;
    logic[0:RS_ID_WIDTH-1] cmp_rs_id;
    logic[0:2] cmp_result_reg_addr;
    logic[0:3] cmp_result;

    cmp_wrapper #(
        .RS_OFFSET(48),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) CMP (
        .clk(clk),
        .rst(rst),

        .input_valid(cmp_valid),
        .input_ready(cmp_ready),
        .result_reg_addr_in(decode.fixed_point.control.result_reg_address),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .xer_so(spr_read_value[0]),
        .xer_so_valid(spr_read_value_valid),
        .xer_so_rs_id(spr_read_rs_id),
        .control(cmp_decode),

        .id_taken(cmp_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .update_xer_so_valid(spr_write_enable),
        .update_xer_so_rs_id_in(spr_write_rs_id),
        .update_xer_so_value_in(spr_write_value[0]),

        .output_valid(cmp_output_valid),
        .output_ready(cmp_output_ready),
        .rs_id_out(cmp_rs_id),
        .result_reg_addr_out(cmp_result_reg_addr),
        .result(cmp_result)
    );

    trap_wrapper #(
        .RS_OFFSET(56),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) TRAP (   
        .clk(clk),
        .rst(rst),

        .input_valid(trap_valid),
        .input_ready(trap_ready),

        .op1(gpr_op1),
        .op1_valid(gpr_op1_valid),
        .op1_rs_id(gpr_op1_rs_id),
        .op2(gpr_op2),
        .op2_valid(gpr_op2_valid),
        .op2_rs_id(gpr_op2_rs_id),
        .control(trap_decode),

        .id_taken(trap_id),

        .update_op_valid(gpr_write_enable),
        .update_op_rs_id_in(gpr_write_rs_id),
        .update_op_value_in(gpr_write_value),

        .output_valid(),
        .output_ready(1'b1),
        .rs_id_out(),

        .trap(trap)
    );

    logic[0:4] sys_result_reg_addr;
    assign sys_result_reg_addr = (decode.fixed_point.system.operation == SYS_MOVE_FROM_CR | decode.fixed_point.system.operation == SYS_MOVE_FROM_CR) ? decode.fixed_point.control.result_reg_address :
                                  decode.fixed_point.system.operation == SYS_MOVE_TO_SPR ? decode.fixed_point.system.SPR : 0;


    logic cr_read_valid[0:7];
    always_comb
    begin
        for(int i = 0; i < 8; i++) begin
            // If data is not read by the system instructions (FXM field), it is set to valid.
            cr_read_valid[i] = cr_read_value_valid[i] | ~decode.fixed_point.system.FXM[i];
        end
    end

    sys_wrapper #(
        .RS_OFFSET(64),
        .RS_DEPTH(2), // This component holds 3*2 reservation stations (GPR, SPR and CR)
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) SYS (
        .clk(clk),
        .rst(rst),

        .input_valid(sys_valid),
        .input_ready(sys_ready),
        .result_reg_addr_in(sys_result_reg_addr),

        .gpr_op(gpr_read_value[0]),
        .gpr_op_valid(gpr_read_value_valid[0]),
        .gpr_op_rs_id(gpr_read_rs_id[0]),
        .spr_op(spr_read_value),
        .spr_op_valid(spr_read_value_valid),
        .spr_op_rs_id(spr_read_rs_id),
        .cr_op({cr_read_value[0:3], cr_read_value[4:7],cr_read_value[8:11], cr_read_value[12:15], cr_read_value[16:19], cr_read_value[20:23], cr_read_value[24:27], cr_read_value[28:31]}),
        .cr_op_valid(cr_read_valid),
        .cr_op_rs_id(cr_read_rs_id),
        .control(decode.fixed_point.system),

        .id_taken(sys_id),
        
        .update_gpr_op_valid(gpr_write_enable),
        .update_gpr_op_rs_id_in(gpr_write_rs_id),
        .update_gpr_op_value_in(gpr_write_value),

        .update_spr_op_valid(spr_write_enable),
        .update_spr_op_rs_id_in(spr_write_rs_id),
        .update_spr_op_value_in(spr_write_value),

        .update_cr_op_valid(cr_write_enable),
        .update_cr_op_rs_id_in(cr_write_rs_id),
        .update_cr_op_value_in({cr_write_value[0:3], cr_write_value[4:7], cr_write_value[8:11], cr_write_value[12:15], cr_write_value[16:19], cr_write_value[20:23], cr_write_value[24:27], cr_write_value[28:31]}),

        .gpr_output_valid(arbiter_valid[6]),
        .gpr_output_ready(arbiter_ready[6]),
        .gpr_rs_id_out(arbiter_rs_id[6]),
        .gpr_result_reg_addr_out(arbiter_result_reg_addr[6]),
        .gpr_result(arbiter_result[6]),

        .spr_output_valid(arbiter_spr_valid),
        .spr_output_ready(arbiter_spr_ready),
        .spr_rs_id_out(arbiter_spr_rs_id),
        .spr_result_reg_addr_out(arbiter_spr_result_reg_addr),
        .spr_result(arbiter_spr_result),

        .cr_output_valid(arbiter_cr_valid),
        .cr_output_ready(arbiter_cr_ready),
        .cr_result_enable(arbiter_cr_enable),
        .cr_rs_id_out(arbiter_cr_rs_id),
        .cr_result(arbiter_cr_result)
    );

    assign arbiter_cr0_xer[6] = '{default: '0};

    // Arbiter output signals
    logic arbiter_output_valid;
    logic[0:RS_ID_WIDTH-1] arbiter_rs_id_out;
    logic[0:4] arbiter_result_reg_addr_out;
    logic[0:31] arbiter_result_out;
    cond_exception_t arbiter_cr0_xer_out;

    // Connect the arbiter output to the GPRs. TODO: Directly assign, when the output signals were removed.
    assign gpr_write_enable = arbiter_output_valid;
    assign gpr_write_addr = arbiter_result_reg_addr_out;
    assign gpr_write_value = arbiter_result_out;
    assign gpr_write_rs_id = arbiter_rs_id_out;

    logic cr_output_valid;
    logic cr_output_enable[0:7];

    assign cr_write_enable = {cr_output_enable[0] & cr_output_valid,
                              cr_output_enable[1] & cr_output_valid,
                              cr_output_enable[2] & cr_output_valid,
                              cr_output_enable[3] & cr_output_valid,
                              cr_output_enable[4] & cr_output_valid,
                              cr_output_enable[5] & cr_output_valid,
                              cr_output_enable[6] & cr_output_valid,
                              cr_output_enable[7] & cr_output_valid};

    simple_write_back_arbiter #(
        .RS_ID_WIDTH(RS_ID_WIDTH),
        .ARBITER_DEPTH(7)
    ) ARBITER (
        .clk(clk),
        .rst(rst),

        .gpr_input_valid(arbiter_valid),
        .gpr_input_ready(arbiter_ready),
        .gpr_rs_id_in(arbiter_rs_id),
        .gpr_result_reg_addr_in(arbiter_result_reg_addr),
        .gpr_result_in(arbiter_result),
        .gpr_cr0_xer_in(arbiter_cr0_xer),

        .gpr_output_valid(arbiter_output_valid),
        .gpr_rs_id_out(arbiter_rs_id_out),
        .gpr_result_reg_addr_out(arbiter_result_reg_addr_out),
        .gpr_result_out(arbiter_result_out),

        .spr_input_valid(arbiter_spr_valid),
        .spr_input_ready(arbiter_spr_ready),
        .spr_rs_id_in(arbiter_spr_rs_id),
        .spr_result_reg_addr_in(arbiter_spr_result_reg_addr),
        .spr_result_in(arbiter_spr_result),

        .spr_output_valid(spr_write_enable),
        .spr_rs_id_out(spr_write_rs_id),
        .spr_result_reg_addr_out(spr_write_addr),
        .spr_result_out(spr_write_value),

        .cr_input_valid(arbiter_cr_valid),
        .cr_input_ready(arbiter_cr_ready),
        .cr_rs_id_in(arbiter_cr_rs_id),
        .cr_input_enable(arbiter_cr_enable),
        .cr_result_in(arbiter_cr_result),

        .cmp_cr_input_valid(cmp_output_valid),
        .cmp_cr_input_ready(cmp_output_ready),
        .cmp_cr_rs_id_in(cmp_rs_id),
        .cmp_cr_input_addr(cmp_result_reg_addr),
        .cmp_cr_result_in(cmp_result),

        .cr_output_valid(cr_output_valid),
        .cr_rs_id_out(cr_write_rs_id),
        .cr_output_enable(cr_output_enable),
        .cr_result_out(cr_write_value)
    );
endmodule