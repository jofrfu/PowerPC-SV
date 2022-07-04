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

module dispatcher #(
    parameter int RS_ID_WIDTH = 5
)(
    input logic clk,
    input logic rst,
    
    input logic input_valid,
    output logic input_ready,
    input decode_result_t decode,
    
    output logic add_sub_valid,
    input logic add_sub_ready,
    output add_sub_decode_t add_sub_decode,
    
    output logic mul_valid,
    input logic mul_ready,
    output mul_decode_t div_decode,

    output logic div_valid,
    input logic div_ready,
    output div_decode_t div_decode,

    output logic log_valid,
    input logic log_ready,
    output log_decode_t log_decode,

    output logic rot_valid,
    input logic rot_ready,
    output rotate_decode_t rot_decode,

    output logic cmp_valid,
    input logic cmp_ready,
    output cmp_decode_t cmp_decode,

    output logic sys_valid,
    input logic sys_ready,
    output system_decode_t sys_decode,

    output logic trap_valid,
    input logic trap_ready,
    output trap_decode_t trap_decode
);

endmodule