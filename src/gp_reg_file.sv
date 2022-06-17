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

module gp_reg_file #(
    parameter int READ_PORTS = 3
)(
    input logic clk,
    input logic rst,
    
    input logic[0:4] read_select[0:READ_PORTS-1],
    output logic[0:31] read_data[0:READ_PORTS-1],
    
    input logic[0:4] write_select,
    input logic[0:4] write_enable,
    input logic[0:31] write_data
);

    logic[0:31] registers_ff[0:31];
    
    always_comb
    begin
        for(int i = 0; i < READ_PORTS; i++) begin
            read_data[i] <= registers_ff[read_select[i]];
        end
    end
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            registers_ff <= {default: {default: '0}};
        end
        else if(write_enable) begin
            registers_ff[write_select] <= write_data;
        end
    end
endmodule