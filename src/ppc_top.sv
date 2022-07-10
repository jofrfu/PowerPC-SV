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

module ppc_top (
    input logic clk,
    input logic rst,

    input logic input_valid,
    output logic input_ready,
    input  logic[0:31] instruction
);

    localparam int RS_ID_WIDTH = 5;

    // GPR read port
    logic[0:4] gpr_read_addr[0:1];
    logic gpr_read_value_valid[0:1];
    logic[0:31] gpr_read_value[0:1];
    logic[0:RS_ID_WIDTH-1] gpr_read_rs_id[0:1];
    // GPR write port
    logic[0:4] gpr_write_addr;
    logic gpr_write_enable;
    logic[0:31] gpr_write_value;
    // GPR RS ID update port
    logic[0:4] gpr_update_addr;
    logic gpr_update_enable;
    logic[0:RS_ID_WIDTH-1] gpr_update_rs_id;

    gp_reg_file #(
        .READ_PORTS(2),
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
    // SPR RS ID update port
    logic[0:9] spr_update_addr;
    logic spr_update_enable;
    logic[0:RS_ID_WIDTH-1] spr_update_rs_id;

    sp_reg_file #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) GPRs (
        .clk(clk),
        .rst(rst),

        .read_addr(spr_read_addr),
        .read_value_valid(spr_read_value_valid),
        .read_value(spr_read_value),
        .read_rs_id(spr_read_rs_id),

        .write_addr(spr_write_addr),
        .write_enable(spr_write_enable),
        .write_value(spr_write_value),

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
    // CR RS ID update port
    logic cr_update_enable;
    logic[0:RS_ID_WIDTH-1] cr_update_rs_id[0:7];

    cond_reg_file #(
        .RS_ID_WIDTH(RS_ID_WIDTH)
    ) GPRs (
        .clk(clk),
        .rst(rst),

        .read_value_valid(cr_read_value_valid),
        .read_value(cr_read_value),
        .read_rs_id(cr_read_rs_id),

        .write_enable(cr_write_enable),
        .write_value(cr_write_value),

        .update_enable(cr_update_enable),
        .update_rs_id(cr_update_rs_id)
    );




    // Add and Sub unit signals
    
endmodule