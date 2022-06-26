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

module tb_div_unit();


    logic clk;
    logic rst;
    
    logic input_valid;
    logic input_ready;
    logic[0:4] rs_id_in;
    logic[0:4] result_reg_addr_in;
    
    logic[0:31] op1;
    logic[0:31] op2;
    div_decode_t control;
    
    logic output_valid;
    logic output_ready;
    logic[0:4] rs_id_out;
    logic[0:4] result_reg_addr_out;
    
    logic[0:31] result;
    cond_exception_t cr0_xer;


    div_unit #(
        .RS_ID_WIDTH(5)
    ) dut (
        .*
    );
    
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        
        input_valid = 0;
        rs_id_in = 0;
        result_reg_addr_in = 0;
        
        op1 = 0;
        op2 = 0;
        control = {default: {default: '0}};
        
        output_ready = 0;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #2
        output_ready = 1;
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 5;
        result_reg_addr_in = 6;
        
        op1 = 25;
        op2 = 5;
        control = {div_signed: 0, alter_CR0: 0, alter_OV: 0};
        @(posedge clk);
        #2
        input_valid = 0;
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 4;
        result_reg_addr_in = 5;
        
        op1 = -25;
        op2 = 5;
        control = {div_signed: 1, alter_CR0: 0, alter_OV: 0};
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 3;
        result_reg_addr_in = 4;
        
        op1 = 179;
        op2 = 16;
        control = {div_signed: 1, alter_CR0: 0, alter_OV: 0};
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 2;
        result_reg_addr_in = 3;
        
        op1 = 28910;
        op2 = 1247;
        control = {div_signed: 0, alter_CR0: 1, alter_OV: 1};
        
        while(~input_ready) begin
            @(posedge clk);
            #2;
        end
        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 1;
        result_reg_addr_in = 2;
        
        op1 = 32'h80000000;
        op2 = -1;
        control = {div_signed: 1, alter_CR0: 0, alter_OV: 1};
        
        while(~input_ready) begin
            @(posedge clk);
            #2;
        end

        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 0;
        result_reg_addr_in = 1;
        
        op1 = 3948934;
        op2 = 0;
        control = {div_signed: 0, alter_CR0: 0, alter_OV: 1};
        
        while(~input_ready) begin
            @(posedge clk);
            #2;
        end

        @(posedge clk);
        #2
        input_valid = 1;
        rs_id_in = 31;
        result_reg_addr_in = 1;
        
        op1 = 32'hFFFFFFFF;
        op2 = 3857369;
        control = {div_signed: 0, alter_CR0: 0, alter_OV: 0};
        
        while(~input_ready) begin
            @(posedge clk);
            #2;
        end

        @(posedge clk);
        #2;
        input_valid = 0;
        @(posedge clk);
        #2;
        input_valid = 1;
        rs_id_in = 30;
        result_reg_addr_in = 0;
        
        op1 = 60;
        op2 = 6;
        control = {div_signed: 1, alter_CR0: 0, alter_OV: 0};
        
        while(~input_ready) begin
            @(posedge clk);
            #2;
        end
        @(posedge clk);
        #2;
        input_valid = 0;

        for(int i = 0; i < 32; i++) begin
            @(posedge clk);
            #2;
        end
        output_ready = 0;
        for(int i = 0; i < 16; i++) begin
            @(posedge clk);
            #2;
        end
        output_ready = 1;
    end

endmodule