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
    
    input logic instruction_valid,
    output logic instruction_ready,
    input logic[0:31] instruction,
    
    output logic decode_valid,
    input logic decode_ready,
    output decode_result_t decode
);

    decode_result_t decode_comb;
    decode_result_t decode_ff;

    always_comb
    begin
        // Convert the instruction in each format for convinience
        I_form_t I_form = logic_to_I_form(instruction);
        B_form_t B_form = logic_to_B_form(instruction);
        SC_form_t SC_form = logic_to_SC_form(instruction);
        D_form_t D_form = logic_to_D_form(instruction);
        DS_form_t DS_form = logic_to_DS_form(instruction);
        X_form_t X_form = logic_to_X_form(instruction);
        XL_form_t XL_form = logic_to_XL_form(instruction);
        XFX_form_t XFX_form = logic_to_XFX_form(instruction);
        XFL_form_t XFL_form = logic_to_XFL_form(instruction);
        XS_form_t XS_form = logic_to_XS_form(instruction);
        XO_form_t XO_form = logic_to_XO_form(instruction);
        A_form_t A_form = logic_to_A_form(instruction);
        M_form_t M_form = logic_to_M_form(instruction);
        MD_form_t MD_form = logic_to_MD_form(instruction);
        MDS_form_t MDS_form = logic_to_MDS_form(instruction);
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
                casez(X_form.XO)
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
                    // Load/Store string word
                    533: // lswx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_LOAD_STRING;
                        end
                    597: // lswi
                        begin
                            if(X_form.RA == 0) begin
                                decode_comb.fixed_point.control.op1_use_imm = 1;	// immediate is zero by default																			
                            end else begin																				
                                decode_comb.fixed_point.control.op1_reg_address = X_form.RA;						
                            end
                            
                            if(X_form.NB == 0) begin
                                decode_comb.fixed_point.control.op2_use_imm = 1;																		
                                decode_comb.fixed_point.control.op2_immediate = 32;
                            end else begin
                                decode_comb.fixed_point.control.op2_use_imm = 1;
                                decode_comb.fixed_point.control.op2_immediate = X_form.NB;						
                            end
                            
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.load_store.word_size = 4-1;								
                            decode_comb.fixed_point.control.result_reg_address = X_form.RT;
                            
                            decode_comb.fixed_point.execute = EXEC_LOAD_STRING;
                        end
                    661: // stswx
                        begin
                            decode_comb.fixed_point = decode_load_store_x_form(X_form, 4, 0, 0, 0);
                            decode_comb.fixed_point.execute = EXEC_STORE_STRING;
                        end
                    725: // stswi
                        begin
                            if(X_form.RA == 0) begin
                                decode_comb.fixed_point.control.op1_use_imm = 1;	// immediate is zero by default																			
                            end else begin																				
                                decode_comb.fixed_point.control.op1_reg_address = X_form.RA;						
                            end
                            
                            if(X_form.NB == 0) begin
                                decode_comb.fixed_point.control.op2_use_imm = 1;																		
                                decode_comb.fixed_point.control.op2_immediate = 32;
                            end else begin
                                decode_comb.fixed_point.control.op2_use_imm = 1;
                                decode_comb.fixed_point.control.op2_immediate = X_form.NB;						
                            end
                            
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.load_store.word_size = 4-1;								
                            decode_comb.fixed_point.control.result_reg_address = X_form.RT;
                            
                            decode_comb.fixed_point.execute = EXEC_STORE_STRING;
                        end
                    // XO Form Add/Sub instructions
                    10'b?000001000: // 8 subfc, subfc., subfco, subfco.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.add_sub.subtract = 1;
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                        end
                    10'b?000001010: // 10 addc, addc., addco, addco.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                        end
                    10'b?000101000: // 40 subf, subf., subfo, subfo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.add_sub.subtract = 1;
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                        end
                    10'b?001101000: // 104 neg, neg., nego, nego.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.add_sub.subtract = 1;
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_use_imm = 1; // immediate is zero by default
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                        end
                    10'b?010001000: // 136 subfe, subfe., subfeo, subfeo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.add_sub.subtract = 1;
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                            decode_comb.fixed_point.add_sub.add_CA = 1;
                        end
                    10'b?010001010: // 138 adde, adde., addeo, addeo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                            decode_comb.fixed_point.add_sub.add_CA = 1;
                        end
                    10'b?011001000: // 200 subfze, subfze., subfzeo, subfzeo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.add_sub.subtract = 1;
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_use_imm = 1; // immediate is zero by default
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                            decode_comb.fixed_point.add_sub.add_CA = 1;
                        end
                    10'b?011001010: // 202 addze, addze., addzeo, addzeo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_use_imm = 1; // immediate is zero by default
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                            decode_comb.fixed_point.add_sub.add_CA = 1;
                        end
                    10'b?011101000: // 232 subfme, subfme., subfmeo, subfmeo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.add_sub.subtract = 1;
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_use_imm = 1;
                            decode_comb.fixed_point.control.op2_immediate = 32'hFFFFFFFF;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                            decode_comb.fixed_point.add_sub.add_CA = 1;
                        end
                    10'b?011101010: // 234 addme, addme., addmeo, addmeo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_use_imm = 1;
                            decode_comb.fixed_point.control.op2_immediate = 32'hFFFFFFFF;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CA = 1;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                            decode_comb.fixed_point.add_sub.add_CA = 1;
                        end
                    10'b?100001010: // 266 add, add., addo, addo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.add_sub.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.add_sub.alter_OV = XO_form.OE;
                        end
                    // XO Form Mul instructions
                    10'b?000001011: // 11 mulhwu, mulhwu.
                        begin
                            decode_comb.fixed_point.execute = EXEC_MUL;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.mul.mul_higher = 1;
                            decode_comb.fixed_point.mul.alter_CR0 = XO_form.Rc;
                        end
                    10'b?001001011: // 75 mulhw, mulhw., mulhwo, mulhwo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_MUL;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.mul.mul_signed = 1;
                            decode_comb.fixed_point.mul.mul_higher = 1;
                            decode_comb.fixed_point.mul.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.mul.alter_OV = XO_form.OE;
                        end
                    10'b?011101011: // 235 mullw, mullw., mullwo, mullwo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_MUL;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.mul.mul_signed = 1;
                            decode_comb.fixed_point.mul.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.mul.alter_OV = XO_form.OE;
                        end
                    // XO Form Div instructions
                    10'b?111001011: // 459 divwu, divwu., divwuo, divwuo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_DIV;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.div.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.div.alter_OV = XO_form.OE;
                        end
                    10'b?111101011: // 491 divw, divw., divwo, divwo.
                        begin
                            decode_comb.fixed_point.execute = EXEC_DIV;
                            
                            decode_comb.fixed_point.control.op1_reg_address = XO_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = XO_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = XO_form.RT;
                            decode_comb.fixed_point.div.div_signed = 1;
                            decode_comb.fixed_point.div.alter_CR0 = XO_form.Rc;
                            decode_comb.fixed_point.div.alter_OV = XO_form.OE;
                        end
                    // X Form Cmp instructions
                    0: // cmp
                        begin
                            decode_comb.fixed_point.execute = EXEC_COMPARE;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.BF;
                            decode_comb.fixed_point.cmp.cmp_signed = 1;
                        end
                    32: // cmpl
                        begin
                            // L is unused in 32 Bit implementations
                            decode_comb.fixed_point.execute = EXEC_COMPARE;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.BF;
                        end
                    // X Form Trap instructions
                    4:  // tw
                        begin
                            decode_comb.fixed_point.execute = EXEC_TRAP;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RA;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.trap.TO = X_form.TO;
                        end
                    // X Form Logical instructions
                    26: // cntlzw, cntlzw.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_COUNT_LEADING_ZEROS_WORD;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    28: // and, and.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_AND;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    60: // andc, andc.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_AND_COMPLEMENT;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    124: // nor, nor.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_NOR;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    284: // eqv, eqv.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_EQUIVALENT;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    316: // xor, xor.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_XOR;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    412: // orc, orc.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_OR_COMPLEMENT;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    444: // or, or.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_OR;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    476: // nand, nand.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_NAND;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    922: // extsh, extsh.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_EXTEND_SIGN_HALFWORD;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    954: // extsb, extsb.
                        begin
                            decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                            decode_comb.fixed_point.log.operation = LOG_EXTEND_SIGN_BYTE;
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    // X Form shift instructions
                    24: // slw, slw.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ROTATE;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.rotate.shift = 1;
                            decode_comb.fixed_point.rotate.left = 1;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    536: // srw, srw.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ROTATE;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.rotate.shift = 1;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    792: // sraw, sraw.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ROTATE;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_reg_address = X_form.RB;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.rotate.shift = 1;
                            decode_comb.fixed_point.rotate.sign_extend = 1;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    824: // srawi, srawi.
                        begin
                            decode_comb.fixed_point.execute = EXEC_ROTATE;
                            
                            decode_comb.fixed_point.control.op1_reg_address = X_form.RS;
                            decode_comb.fixed_point.control.op2_use_imm = 1;
                            decode_comb.fixed_point.control.op2_immediate = X_form.SH;
                            decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                            decode_comb.fixed_point.rotate.shift = 1;
                            decode_comb.fixed_point.rotate.sign_extend = 1;
                            decode_comb.fixed_point.log.alter_CR0 = X_form.Rc;
                        end
                    // XFX Form move system register instructions
                    19: // mfcr
                        begin
                            if(XFX_form.ALWAYS_ZERO == 0) begin
                                decode_comb.fixed_point.execute = EXEC_SYSTEM;
                                
                                decode_comb.fixed_point.system.operation = SYS_MOVE_FROM_CR;
                                decode_comb.fixed_point.control.op1_reg_address = XFX_form.RT;
                            end
                        end
                    144: // mtcrf
                        begin
                            if(XFX_form.ALWAYS_ZERO == 0) begin
                                decode_comb.fixed_point.execute = EXEC_SYSTEM;
                                
                                decode_comb.fixed_point.system.operation = SYS_MOVE_TO_CR;
                                decode_comb.fixed_point.control.op1_reg_address = XFX_form.RS;
                                decode_comb.fixed_point.system.FXM = XFX_form.FXM;
                            end
                        end
                    339: // mfspr
                        begin
                            decode_comb.fixed_point.execute = EXEC_SYSTEM;
                            
                            decode_comb.fixed_point.system.operation = SYS_MOVE_FROM_SPR;
                            decode_comb.fixed_point.control.op1_reg_address = XFX_form.RT;
                            // Reverse the SPR field according to spec
                            decode_comb.fixed_point.system.SPR = {XFX_form.spr[5:9], XFX_form.spr[0:4]};
                        end
                    467: // mtspr
                        begin
                            decode_comb.fixed_point.execute = EXEC_SYSTEM;
                            
                            decode_comb.fixed_point.system.operation = SYS_MOVE_TO_SPR;
                            decode_comb.fixed_point.control.op1_reg_address = XFX_form.RS;
                            // Reverse the SPR field according to spec
                            decode_comb.fixed_point.system.SPR = {XFX_form.spr[5:9], XFX_form.spr[0:4]};
                        end
                    // X Form floating point Load/Store instructions
                    // TODO: Implement
                endcase
            // D Form load instructions
            32: // lwz
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 4, 0, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            33: // lwzu
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 4, 1, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            34: // lbz
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 1, 0, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            35: // lbzu
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 1, 1, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            40: // lhz
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 2, 0, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            41: // lhzu
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 2, 1, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            42: // lha
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 2, 0, 1, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            43: // lhau
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 2, 1, 1, 0);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            // D Form store instructions
            36: // stw
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 4, 0, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            37: // stwu
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 4, 1, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            38: // stb
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 1, 0, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            39: // stbu
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 1, 1, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            44: // sth
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 2, 0, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            45: // sthu
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 2, 1, 0, 0);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            // D Form multiple load/store instructions
            46: // lmw
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 4, 0, 0, 1);
                    decode_comb.fixed_point.execute = EXEC_LOAD;
                end
            47: // stmw
                begin
                    decode_comb.fixed_point = decode_load_zero(D_form, 4, 0, 0, 1);
                    decode_comb.fixed_point.execute = EXEC_STORE;
                end
            // D Form Add/Sub instructions
            8:  // subfic
                begin
                    decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                    decode_comb.fixed_point.add_sub.subtract = 1;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.control.result_reg_address = D_form.RT;
                    decode_comb.fixed_point.add_sub.alter_CA = 1;
                end
            12:  // addic
                begin
                    decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.control.result_reg_address = D_form.RT;
                    decode_comb.fixed_point.add_sub.alter_CA = 1;
                end
            13:  // addic.
                begin
                    decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                            
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.control.result_reg_address = D_form.RT;
                    decode_comb.fixed_point.add_sub.alter_CA = 1;
                    decode_comb.fixed_point.add_sub.alter_CR0 = 1;
                end
            14:  // addi
                begin
                    decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                    
                    if(D_form.RA == 0) begin
                        decode_comb.fixed_point.control.op1_use_imm = 1; // Immediate is zero by default
                    end else begin
                        decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    end
                    
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.control.result_reg_address = D_form.RT;
                end
            15:  // addis
                begin
                    decode_comb.fixed_point.execute = EXEC_ADD_SUB;
                    
                    if(D_form.RA == 0) begin
                        decode_comb.fixed_point.control.op1_use_imm = 1; // Immediate is zero by default
                    end else begin
                        decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    end
                    
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {D_form.SI, 16'b0};
                    decode_comb.fixed_point.control.result_reg_address = D_form.RT;
                end
            // D Form Mul instructions
            7:  // mulli
                begin
                    decode_comb.fixed_point.execute = EXEC_MUL;
                    
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.control.result_reg_address = D_form.RT;
                    decode_comb.fixed_point.mul.mul_signed = 1;
                end
            // D Form Cmp instructions
            10: // cmpli
                begin
                    // L is unused in 32 Bit implementations
                    decode_comb.fixed_point.execute = EXEC_COMPARE;
                    
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = D_form.UI;
                    decode_comb.fixed_point.control.result_reg_address = D_form.BF;
                end
            11: // cmpi
                begin
                    // L is unused in 32 Bit implementations
                    decode_comb.fixed_point.execute = EXEC_COMPARE;
                    
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.control.result_reg_address = D_form.BF;
                end
            // D Form Trap instructions
            3: // twi
                begin
                    decode_comb.fixed_point.execute = EXEC_TRAP;
                            
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RA;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {{16{D_form.SI[0]}}, D_form.SI};
                    decode_comb.fixed_point.trap.TO = D_form.TO;
                end
            // D Form Logical instructions
            24: // ori
                begin
                    decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                    decode_comb.fixed_point.log.operation = LOG_OR;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RS;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = D_form.UI;
                    decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                end
            25: // oris
                begin
                    decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                    decode_comb.fixed_point.log.operation = LOG_OR;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RS;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {D_form.UI, 16'b0};
                    decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                end
            26: // xori
                begin
                    decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                    decode_comb.fixed_point.log.operation = LOG_XOR;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RS;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = D_form.UI;
                    decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                end
            27: // xoris
                begin
                    decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                    decode_comb.fixed_point.log.operation = LOG_XOR;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RS;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {D_form.UI, 16'b0};
                    decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                end
            28: // andi.
                begin
                    decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                    decode_comb.fixed_point.log.operation = LOG_AND;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RS;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = D_form.UI;
                    decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                    decode_comb.fixed_point.log.alter_CR0 = 1;
                end
            29: // andis.
                begin
                    decode_comb.fixed_point.execute = EXEC_LOGICAL;
                            
                    decode_comb.fixed_point.log.operation = LOG_AND;
                    decode_comb.fixed_point.control.op1_reg_address = D_form.RS;
                    decode_comb.fixed_point.control.op2_use_imm = 1;
                    decode_comb.fixed_point.control.op2_immediate = {D_form.UI, 16'b0};
                    decode_comb.fixed_point.control.result_reg_address = X_form.RA;
                    decode_comb.fixed_point.log.alter_CR0 = 1;
                end
        endcase
    end
    
    logic enable;
    assign enable = (~decode_valid & instruction_valid) | (decode_ready & decode_valid);
    assign instruction_ready = enable;

    always_ff @(posedge clk)
    begin
        if(rst) begin
            decode_valid <= 0;
            decode_ff <= {default: {default: '0}};
        end
        else begin
            if(enable) begin
                decode_valid <= instruction_valid;
                decode_ff <= decode_comb;
            end
        end
    end
    
    assign decode = decode_ff;

endmodule