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

module tb_add_sub_unit();


    logic clk;
    logic rst;
    
    logic input_valid;
    logic[0:4] rs_id_in;
    logic[0:4] result_reg_addr_in;
    
    logic[0:31] op1;
    logic[0:31] op2;
    logic carry_in;   // Assigned to operand 3 at index 0 in RS
    add_sub_decode_t control;
    
    logic output_valid;
    logic[0:4] rs_id_out;
    logic[0:4] result_reg_addr_out;
    
    logic[0:31] result;
    cond_exception_t cr0_xer;


    add_sub_unit #(
        .RS_ID_WIDTH(5)
    ) dut (
        .*
    );
    
    always #10 clk = ~clk;
    
    add_sub_decode_t control_stream[4] = {
        '{
            subtract: 0,
            alter_CA: 0,
            alter_CR0: 0,
            alter_OV: 0,
            add_CA: 0
        },
        '{
            subtract: 1,
            alter_CA: 1,
            alter_CR0: 0,
            alter_OV: 0,
            add_CA: 0
        },
        '{
            subtract: 0,
            alter_CA: 1,
            alter_CR0: 0,
            alter_OV: 1,
            add_CA: 0
        },
        '{
            subtract: 0,
            alter_CA: 0,
            alter_CR0: 0,
            alter_OV: 0,
            add_CA: 1
        }
    };
    
    logic[0:31] op1_stream[4] = {
        89,
        89,
        'h7FFFFFFE,
        'hFFFFFFFF
    };
    
    logic[0:31] op2_stream[4] = {
        187,
        187,
        5,
        0
    };
    
    logic carry_stream[4] = {
        0,
        0,
        0,
        1
    };
    
    initial begin
        clk = 0;
        rst = 0;
        
        input_valid = 0;
        rs_id_in = 0;
        result_reg_addr_in = 0;
        
        op1 = 0;
        op2 = 0;
        carry_in = 0;
        control = {default: {default: '0}};
        
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        for(int i = 0; i < 4; i++) begin
            input_valid = 1;
            rs_id_in = i;
            result_reg_addr_in = 31-i;
            
            op1 = op1_stream[i];
            op2 = op2_stream[i];
            carry_in = carry_stream[i];
            control = control_stream[i];
            @(posedge clk);
        end
        input_valid = 0;
        rs_id_in = 0;
        result_reg_addr_in = 0;
        
        op1 = 0;
        op2 = 0;
        carry_in = 0;
        control = {default: {default: '0}};
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
    end
endmodule