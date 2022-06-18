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

module tb_reservation_station;

    logic clk;
    logic rst;
    
    //------ Simple ready-valid interface for new instructions ------
    logic                     take_valid;
    logic                     take_ready;
    
    logic                     op_value_valid_in[0:1];
    logic[0:4]                op_rs_id_in[0:1];
    logic[0:31]               op_value_in[0:1];
    add_sub_decode_t          control_in;
    
    logic[0:4]                id_taken;
    //---------------------------------------------------------------
    
    //------ Simple valid interface for updated operands ------
    logic                     operand_valid;
    
    logic[0:4]                update_op_rs_id_in;
    logic[0:31]               update_op_value_in;
    //---------------------------------------------------------
    
    //------ Simple ready-valid interface for output ------
    logic        output_valid;
    logic        output_ready;
    
    logic[0:31]  op_value_out[0:1];
    add_sub_decode_t control_out;
    //-----------------------------------------------------
    
    reservation_station #(
        .OPERANDS(2),
        .RS_OFFSET(0),
        .RS_DEPTH(8),
        .RS_ID_WIDTH(5),
        .CONTROL_TYPE(add_sub_decode_t)
    ) dut(
        .*
    );
    
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        rst = 0;
        take_valid = 0;
        op_value_valid_in = {0, 0};
        op_rs_id_in = {0, 0};
        op_value_in = {0, 0};
        control_in = {default: {default: '0}};
        
        operand_valid = 0;
        update_op_rs_id_in = 0;
        update_op_value_in = 0;
        
        output_ready = 0;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        for(int i = 0; i < 10; i++) begin
            if(take_ready) begin
                take_valid = 1;
                op_value_valid_in = {1,1};
                op_rs_id_in = {0, 0};
                op_value_in = {i, i+1};
                control_in.subtract = 1;
                control_in.add_CA = 1;
            end
            @(posedge clk);
        end
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 0;
        take_valid = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        if(take_ready) begin
            take_valid = 1;
            op_value_valid_in = {1,0};
            op_rs_id_in = {0, 5};
            op_value_in = {10, 0};
            control_in.subtract = 0;
            control_in.add_CA = 1;
        end
        @(posedge clk);
        take_valid = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        operand_valid = 1;
        update_op_rs_id_in = 4;
        update_op_value_in = 12;
        @(posedge clk);
        operand_valid = 0;
        @(posedge clk);
        operand_valid = 1;
        update_op_rs_id_in = 5;
        update_op_value_in = 16;
        @(posedge clk);
        operand_valid = 0;
        @(posedge clk);
        output_ready = 0;
        @(posedge clk);
        @(posedge clk);
        if(take_ready) begin
            take_valid = 1;
            op_value_valid_in = {1,0};
            op_rs_id_in = {0, 5};
            op_value_in = {10, 0};
            control_in.subtract = 0;
            control_in.add_CA = 1;
        end
        @(posedge clk);
        take_valid = 0;
        @(posedge clk);
        @(posedge clk);
        operand_valid = 1;
        update_op_rs_id_in = 5;
        update_op_value_in = 16;
        @(posedge clk);
        operand_valid = 0;
        @(posedge clk);
    end
    
endmodule