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

module dispatcher(
    // Input interface from instruction decode
    input logic input_valid,
    output logic input_ready,
    input decode_result_t decode,

    // Output interfaces to each unit
    output logic add_sub_valid,
    input logic add_sub_ready,
    output add_sub_decode_t add_sub_decode,
    
    output logic mul_valid,
    input logic mul_ready,
    output mul_decode_t mul_decode,

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


    always_comb
    begin
        add_sub_decode = decode.fixed_point.add_sub;
        mul_decode = decode.fixed_point.mul;
        div_decode = decode.fixed_point.div;
        cmp_decode = decode.fixed_point.cmp;
        trap_decode = decode.fixed_point.trap;
        log_decode = decode.fixed_point.log;
        rot_decode = decode.fixed_point.rotate;
        sys_decode = decode.fixed_point.system;

        add_sub_valid = 0;
        mul_valid = 0;
        div_valid = 0;
        cmp_valid = 0;
        trap_valid = 0;
        log_valid = 0;
        rot_valid = 0;
        sys_valid = 0;

        case(decode.fixed_point.execute)
            //EXEC_FIXED_NONE:
            //EXEC_LOAD:
            //EXEC_STORE:
            //EXEC_LOAD_STRING:
            //EXEC_STORE_STRING:
            EXEC_ADD_SUB:
                begin
                    input_ready = add_sub_ready;
                    add_sub_valid = input_valid;
                end
            EXEC_MUL:
                begin
                    input_ready = mul_ready;
                    mul_valid = input_valid;
                end
            EXEC_DIV:
                begin
                    input_ready = div_ready;
                    div_valid = input_valid;
                end
            EXEC_COMPARE:
                begin
                    input_ready = cmp_ready;
                    cmp_valid = input_valid;
                end
            EXEC_TRAP:
                begin
                    input_ready = trap_ready;
                    trap_valid = input_valid;
                end
            EXEC_LOGICAL:
                begin
                    input_ready = log_ready;
                    log_valid = input_valid;
                end
            EXEC_ROTATE:
                begin
                    input_ready = rot_ready;
                    rot_valid = input_valid;
                end
            EXEC_SYSTEM:
                begin
                    input_ready = sys_ready;
                    sys_valid = input_valid;
                end
            default:
                // Invalid instruction!
                begin
                    input_ready = 1;
                    // TODo: Trap on invalid instructions
                end
        endcase
    end
endmodule