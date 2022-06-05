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

module instruction_decode(
    input logic clk,
    input logic rst,
    
    input logic[0:31] instruction,
    
    output decode_result_t decode
);

    decode_result_t decode_comb;
    decode_result_t decode_ff;

    always_comb
    begin
        // Convert the instruction in each format for convinience
        static I_form_t I_form = logic_to_I_form(instruction);
        static B_form_t B_form = logic_to_B_form(instruction);
        static SC_form_t SC_form = logic_to_SC_form(instruction);
        static D_form_t D_form = logic_to_D_form(instruction);
        static DS_form_t DS_form = logic_to_DS_form(instruction);
        static X_form_t X_form = logic_to_X_form(instruction);
        static XL_form_t XL_form = logic_to_XL_form(instruction);
        static XFX_form_t XFX_form = logic_to_XFX_form(instruction);
        static XFL_form_t XFL_form = logic_to_XFL_form(instruction);
        static XS_form_t XS_form = logic_to_XS_form(instruction);
        static XO_form_t XO_form = logic_to_XO_form(instruction);
        static A_form_t A_form = logic_to_A_form(instruction);
        static M_form_t M_form = logic_to_M_form(instruction);
        static MD_form_t MD_form = logic_to_MD_form(instruction);
        static MDS_form_t MDS_form = logic_to_MDS_form(instruction);
        //-----------------------------------------------------
        
        decode_comb = {default: {default: '0}};
        
        case(I_form.OPCD)
            // B Form Branch instructions
            16: // bc, bca, bcl, bcla
                begin
                    decode_comb.branch.execute = EXEC_BRANCH;
                    decode_comb.branch.branch_decoded.operation = BRANCH_CONDITIONAL;
                    decode_comb.branch.branch_decoded.LK = B_form.LK;
                    decode_comb.branch.branch_decoded.AA = B_form.AA;
                    decode_comb.branch.branch_decoded.LI = 0;
                    decode_comb.branch.branch_decoded.BD = B_form.BD;
                    decode_comb.branch.branch_decoded.BI = B_form.BI;
                    decode_comb.branch.branch_decoded.BO = B_form.BO;
                    decode_comb.branch.branch_decoded.BH = 0;
                end
            // SC Form System Call instructions
            17:
                case(SC_form.ALWAYS_ONE)
                    // SC Form System Call instructions
                    0:  // Invalid instruction!
                        begin
                        end
                    1:
                        begin
                            decode_comb.branch.execute = EXEC_SYSTEM_CALL;
                            decode_comb.branch.system_call_decoded = SC_form.LEV;
                        end
                endcase
            // I Form Branch instructions
            18: // b, ba, bl, bla
                begin
                    decode_comb.branch.execute = EXEC_BRANCH;
                    decode_comb.branch.branch_decoded.operation = BRANCH;
                    decode_comb.branch.branch_decoded.LK = I_form.LK;
                    decode_comb.branch.branch_decoded.AA = I_form.AA;
                    decode_comb.branch.branch_decoded.LI = I_form.LI;
                    decode_comb.branch.branch_decoded.BD = 0;
                    decode_comb.branch.branch_decoded.BI = 0;
                    decode_comb.branch.branch_decoded.BO = 0;
                    decode_comb.branch.branch_decoded.BH = 0;
                end
            19:
                case(XL_form.XO)
                    // XL Form Branch instructions
                    16: // bclr, bclrl
                        begin
                            decode_comb.branch.execute = EXEC_BRANCH;
                            decode_comb.branch.branch_decoded.operation = BRANCH_CONDITIONAL_LINK;
                            decode_comb.branch.branch_decoded.LK = XL_form.LK;
                            decode_comb.branch.branch_decoded.AA = 0;
                            decode_comb.branch.branch_decoded.LI = 0;
                            decode_comb.branch.branch_decoded.BD = 0;
                            decode_comb.branch.branch_decoded.BI = XL_form.BI;
                            decode_comb.branch.branch_decoded.BO = XL_form.BO;
                            decode_comb.branch.branch_decoded.BH = XL_form.BH;
                        end
                    528: // bcctr, bcctrl
                        begin
                            decode_comb.branch.execute = EXEC_BRANCH;
                            decode_comb.branch.branch_decoded.operation = BRANCH_CONDITIONAL_COUNT;
                            decode_comb.branch.branch_decoded.LK = XL_form.LK;
                            decode_comb.branch.branch_decoded.AA = 0;
                            decode_comb.branch.branch_decoded.LI = 0;
                            decode_comb.branch.branch_decoded.BD = 0;
                            decode_comb.branch.branch_decoded.BI = XL_form.BI;
                            decode_comb.branch.branch_decoded.BO = XL_form.BO;
                            decode_comb.branch.branch_decoded.BH = XL_form.BH;
                        end
                    // XL Form Condition instructions
                    0:  // mcrf
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_MOVE;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    33: // crnor
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_NOR;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    129:    // crandc
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_AND_COMPLEMENT;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    193:    // crxor
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_XOR;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    257:    // crand
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_AND;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    289:    // creqv
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_EQUIVALENT;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    417:    // crorc
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_OR_COMPLEMENT;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                    449:    // cror
                        begin
                            decode_comb.branch.execute = EXEC_CONDITION;
                            decode_comb.branch.condition_decoded.operation = COND_OR;
                            decode_comb.branch.condition_decoded.CR_op1_reg_address = XL_form.BA;
                            decode_comb.branch.condition_decoded.CR_op2_reg_address = XL_form.BB;
                            decode_comb.branch.condition_decoded.CR_result_reg_address = XL_form.BT;
                        end
                endcase
            // M Form rotate instructions
            20: // rlwimi, rlwimi.
                begin
                    decode_comb.fixed_point.execute = EXEC_ROTATE;
                    decode_comb.fixed_point.control.op1_reg_address = M_form.RS;
                    decode_comb.fixed_point.control.result_reg_address = M_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = M_form.SH;
                    
                    decode_comb.fixed_point.rotate.MB = M_form.MB;
                    decode_comb.fixed_point.rotate.ME = M_form.ME;
                    decode_comb.fixed_point.rotate.mask_insert = 1;
                    decode_comb.fixed_point.rotate.shift = 0;
                    decode_comb.fixed_point.rotate.left = 0;
                    decode_comb.fixed_point.rotate.sign_extend = 0;
                    decode_comb.fixed_point.rotate.alter_CR0 = M_form.Rc;
                end
            21: // rlwinm, rlwinm.
                begin
                    decode_comb.fixed_point.execute = EXEC_ROTATE;
                    decode_comb.fixed_point.control.op1_reg_address = M_form.RS;
                    decode_comb.fixed_point.control.result_reg_address = M_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = M_form.SH;
                    
                    decode_comb.fixed_point.rotate.MB = M_form.MB;
                    decode_comb.fixed_point.rotate.ME = M_form.ME;
                    decode_comb.fixed_point.rotate.mask_insert = 0;
                    decode_comb.fixed_point.rotate.shift = 0;
                    decode_comb.fixed_point.rotate.left = 0;
                    decode_comb.fixed_point.rotate.sign_extend = 0;
                    decode_comb.fixed_point.rotate.alter_CR0 = M_form.Rc;
                end
            23: // rlwnm, rlwnm.
                begin
                    decode_comb.fixed_point.execute = EXEC_ROTATE;
                    decode_comb.fixed_point.control.op1_reg_address = M_form.RS;
                    decode_comb.fixed_point.control.result_reg_address = M_form.RA;
                    decode_comb.fixed_point.control.op2_reg_address = M_form.RB;
                    
                    decode_comb.fixed_point.rotate.MB = M_form.MB;
                    decode_comb.fixed_point.rotate.ME = M_form.ME;
                    decode_comb.fixed_point.rotate.mask_insert = 0;
                    decode_comb.fixed_point.rotate.shift = 0;
                    decode_comb.fixed_point.rotate.left = 0;
                    decode_comb.fixed_point.rotate.sign_extend = 0;
                    decode_comb.fixed_point.rotate.alter_CR0 = M_form.Rc;
                end
            31:
                case(X_form.XO)
                    // X Form load instructions
                    23: // lwzx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    55: // lwzux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 1, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    87: // lbzx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 1, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    119: // lbzux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 1, 1, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    279: // lhzx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    311: // lhzux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 1, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    341: // lwax
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 1, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    343: // lhax
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 0, 1, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    373: // lwaux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 1, 1, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    375: // lhaux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 1, 1, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    // X Form store instructions
                    151: // stwx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_STORE;
                        end
                    183: // stwux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 1, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    215: // stbx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 1, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_STORE;
                        end
                    247: // stbux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 1, 1, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    407: // sthx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_STORE;
                        end
                    439: // sthux
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 1, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_STORE;
                        end
                    // Load/Store reverse order (little endian)
                    534: // lwbrx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 0, 1);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    662: // stwbrx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 0, 1);
                            decode_comb.fixed_point.execute = EXEC_STORE;
                        end
                    790: // lhbrx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 0, 0, 1);
                            decode_comb.fixed_point.execute = EXEC_LOAD;
                        end
                    918: // sthbrx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 2, 0, 0, 1);
                            decode_comb.fixed_point.execute = EXEC_STORE;
                        end
                endcase
        endcase
    end
    
    always_ff @(posedge clk)
    begin
        if(rst) begin
            decode_ff <= {default: {default: '0}};
        end
        else begin
            decode_ff <= decode_comb;
        end
    end
    
    assign decode = decode_ff;

endmodule