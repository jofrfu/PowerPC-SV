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

module tb_rot_unit();


    logic clk;
    logic rst;
    
    logic input_valid;
    logic input_ready;
    logic[0:4] rs_id_in;
    logic[0:4] result_reg_addr_in;
    
    logic[0:31] op1;
    logic[0:31] op2;
    logic[0:31] target;
    rotate_decode_t control;
    
    logic output_valid;
    logic output_ready;
    logic[0:4] rs_id_out;
    logic[0:4] result_reg_addr_out;
    
    logic[0:31] result;
    cond_exception_t cr0_xer;


    rot_unit #(
        .RS_ID_WIDTH(5)
    ) dut (
        .*
    );
    
    always #10 clk = ~clk;
    
    rotate_decode_t control_stream[4] = {
        '{
            MB: 16,
            ME: 28,
            mask_insert: 1,
            shift: 0,
            left: 0,
            sign_extend: 0,
            alter_CR0: 1
        },
        '{
            MB: 0,
            ME: 31,
            mask_insert: 0,
            shift: 0,
            left: 0,
            sign_extend: 0,
            alter_CR0: 0
        },
        '{
            MB: 0,
            ME: 31,
            mask_insert: 0,
            shift: 0,
            left: 0,
            sign_extend: 0,
            alter_CR0: 0
        },
        '{
            MB: 24,
            ME: 7,
            mask_insert: 0,
            shift: 0,
            left: 0,
            sign_extend: 0,
            alter_CR0: 0
        }
    };
    
    logic[0:31] op1_stream[4] = {
        32'h5E44C80,
        32'h5E44C80,
        32'h5E44C80,
        32'h5E44C80
    };
    
    logic[0:31] op2_stream[4] = {
        17,
        8,
        17,
        17
    };
    
    logic[0:31] target_stream[4] = {
        32'hFFFF0000,
        0,
        0,
        0
    };
    
    initial begin
        clk = 0;
        rst = 0;
        
        input_valid = 0;
        rs_id_in = 0;
        result_reg_addr_in = 0;
        
        op1 = 0;
        op2 = 0;
        target = 0;
        control = {default: {default: '0}};
        
        output_ready = 0;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        for(int i = 0; i < 4; i++) begin
            #2
            input_valid = 1;
            rs_id_in = i;
            result_reg_addr_in = 31-i;
            
            op1 = op1_stream[i];
            op2 = op2_stream[i];
            target = target_stream[i];
            control = control_stream[i];
            @(posedge clk);
        end
        #2
        input_valid = 0;
        rs_id_in = 0;
        result_reg_addr_in = 0;
        
        op1 = 0;
        op2 = 0;
        target = 0;
        control = {default: {default: '0}};
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 0;
        for(int i = 0; i < 4; i++) begin
            #2
            input_valid = 1;
            rs_id_in = i;
            result_reg_addr_in = 31-i;
            
            op1 = op1_stream[i];
            op2 = op2_stream[i];
            target = target_stream[i];
            control = control_stream[i];
            @(posedge clk);
        end
        #2
        input_valid = 0;
        rs_id_in = 0;
        result_reg_addr_in = 0;
        
        op1 = 0;
        op2 = 0;
        target = 0;
        control = {default: {default: '0}};
        
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 12;
        result_reg_addr_in = 17;
        
        op1 = op1_stream[0];
        op2 = op2_stream[0];
        target = target_stream[0];
        control = control_stream[0];
        @(posedge clk);
        #2
        input_valid = 0;
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 13;
        result_reg_addr_in = 14;
        
        op1 = op1_stream[1];
        op2 = op2_stream[1];
        target = target_stream[1];
        control = control_stream[1];
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 11;
        result_reg_addr_in = 14;
        
        op1 = op1_stream[2];
        op2 = op2_stream[2];
        target = target_stream[2];
        control = control_stream[2];
        @(posedge clk);
        #2
        input_valid = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 0;
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 12;
        result_reg_addr_in = 17;
        
        op1 = op1_stream[0];
        op2 = op2_stream[0];
        target = target_stream[0];
        control = control_stream[0];
        @(posedge clk);
        #2
        input_valid = 0;
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 13;
        result_reg_addr_in = 14;
        
        op1 = op1_stream[1];
        op2 = op2_stream[1];
        target = target_stream[1];
        control = control_stream[1];
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 11;
        result_reg_addr_in = 14;
        
        op1 = op1_stream[2];
        op2 = op2_stream[2];
        target = target_stream[2];
        control = control_stream[2];
        @(posedge clk);
        #2
        input_valid = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        output_ready = 1;
    end
endmodule