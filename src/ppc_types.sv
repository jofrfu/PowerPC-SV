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

`define PPC_TYPES

package ppc_types;

    // ------ Types for instruction formats START ------
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:23] LI;
        logic AA;
        logic LK;
    } I_form_t;
	
    function I_form_t logic_to_I_form(input logic[0:31] instruction);
        logic_to_I_form.OPCD    = instruction[0:5];
        logic_to_I_form.LI      = instruction[6:29];
        logic_to_I_form.AA      = instruction[30];
        logic_to_I_form.LK      = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] BO;
        logic[0:4] BI;
        logic[0:13] BD;
        logic AA;
        logic LK;
    } B_form_t;
    
    function B_form_t logic_to_B_form(input logic[0:31] instruction);
        logic_to_B_form.OPCD    = instruction[0:5];
        logic_to_B_form.BO      = instruction[6:10];
        logic_to_B_form.BI      = instruction[11:15];
        logic_to_B_form.BD      = instruction[16:29];
        logic_to_B_form.AA      = instruction[30];
        logic_to_B_form.LK      = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:6] LEV;
        logic ALWAYS_ONE;
    } SC_form_t;
    
    function SC_form_t logic_to_SC_form(input logic[0:31] instruction);
        logic_to_SC_form.OPCD    = instruction[0:5];
        logic_to_SC_form.LEV     = instruction[20:26];
        logic_to_SC_form.ALWAYS_ONE = instruction[30];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        // Same field for RT, RS, BF/L, TO, FRT and FRS
        logic[0:4] RT, RS, TO, FRT, FRS;
        logic[0:2] BF;
        logic L;
        
        logic[0:4] RA;
        // Same field for D, SI, UI
        logic[0:15] D, UI;
        logic signed[0:15] SI;
    } D_form_t;
	
    function D_form_t logic_to_D_form(input logic[0:31] instruction);
        logic_to_D_form.OPCD    = instruction[0:5];
        
        logic_to_D_form.RT      = instruction[6:10];
        logic_to_D_form.RS      = instruction[6:10];
        logic_to_D_form.TO      = instruction[6:10];
        logic_to_D_form.FRT     = instruction[6:10];
        logic_to_D_form.FRS     = instruction[6:10];
        logic_to_D_form.BF      = instruction[6:8];
        logic_to_D_form.L       = instruction[10];
        
        logic_to_D_form.RA      = instruction[11:15];
        
        logic_to_D_form.D       = instruction[16:31];
        logic_to_D_form.SI      = instruction[16:31];
        logic_to_D_form.UI      = instruction[16:31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        // Same field for RT and RS
        logic[0:4] RT, RS;
        
        logic[0:4] RA;
        logic[0:13] DS;
        logic[0:1] XO;
    } DS_form_t;
	
    function DS_form_t logic_to_DS_form(input logic[0:31] instruction);
        logic_to_DS_form.OPCD   = instruction[0:5];
        
        logic_to_DS_form.RT     = instruction[6:10];
        logic_to_DS_form.RS     = instruction[6:10];
        
        logic_to_DS_form.RA     = instruction[11:15];
        logic_to_DS_form.DS     = instruction[16:29];
        logic_to_DS_form.XO     = instruction[30:31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        // Same field for RT, RS, BF/L, TO, FRT and FRS
        logic[0:4] RT, RS, TO, FRT, FRS, BT;
        logic[0:3] TH;
        logic[0:2] BF;
        logic L_1;
        logic[0:1] L_2;
        
        // Same fields
        logic[0:4] RA, FRA;
        logic[0:3] SR;
        logic[0:2] BFA;
        logic L_3;
        
        // Same fields for RB, NB, SH, FRB and U
        logic[0:4] RB, NB, SH, FRB;
        logic[0:3] U;
        
        logic[0:9] XO;
        
        logic Rc; // or always one
    } X_form_t;
	
    function X_form_t logic_to_X_form(input logic[0:31] instruction);
        logic_to_X_form.OPCD    = instruction[0:5];
        
        logic_to_X_form.RT      = instruction[6:10];
        logic_to_X_form.RS      = instruction[6:10];
        logic_to_X_form.TO      = instruction[6:10];
        logic_to_X_form.FRT     = instruction[6:10];
        logic_to_X_form.FRS     = instruction[6:10];
        logic_to_X_form.BT      = instruction[6:10];
        logic_to_X_form.BF      = instruction[6:8];
        logic_to_X_form.L_1     = instruction[10];
        logic_to_X_form.TH      = instruction[7:10];
        logic_to_X_form.L_2     = instruction[9:10];
        
        logic_to_X_form.RA      = instruction[11:15];
        logic_to_X_form.FRA     = instruction[11:15];
        logic_to_X_form.SR      = instruction[12:15];
        logic_to_X_form.L_3     = instruction[15];
        logic_to_X_form.BFA     = instruction[11:13];
        
        logic_to_X_form.RB      = instruction[16:20];
        logic_to_X_form.NB      = instruction[16:20];
        logic_to_X_form.SH      = instruction[16:20];
        logic_to_X_form.FRB     = instruction[16:20];
        logic_to_X_form.U       = instruction[16:19];
        
        logic_to_X_form.XO      = instruction[21:30];
        
        logic_to_X_form.Rc      = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        
        logic[0:4] BT, BO;
        logic[0:2] BF;
        
        logic[0:4] BA, BI;
        logic[0:2] BFA;
        
        logic[0:4] BB;
        logic[0:1] BH;
        
        logic[0:9] XO;
        logic LK;
    } XL_form_t;
	
    function XL_form_t logic_to_XL_form(input logic[0:31] instruction);
        logic_to_XL_form.OPCD   = instruction[0:5];
        
        logic_to_XL_form.BT     = instruction[6:10];
        logic_to_XL_form.BO     = instruction[6:10];
        logic_to_XL_form.BF     = instruction[6:8];
        
        logic_to_XL_form.BA     = instruction[11:15];
        logic_to_XL_form.BI     = instruction[11:15];
        logic_to_XL_form.BFA    = instruction[11:13];
        
        logic_to_XL_form.BB     = instruction[16:20];
        logic_to_XL_form.BH     = instruction[19:20];
        
        logic_to_XL_form.XO     = instruction[21:30];
        
        logic_to_XL_form.LK     = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        
        logic[0:4] RT, RS;
        
        logic[0:9] spr, tbr;
        logic ALWAYS_ZERO, ALWAYS_ONE;
        logic[0:7] FXM;
        
        logic[0:9] XO;
    } XFX_form_t;
	
    function XFX_form_t logic_to_XFX_form(input logic[0:31] instruction);
        logic_to_XFX_form.OPCD  = instruction[0:5];
        
        logic_to_XFX_form.RT    = instruction[6:10];
        logic_to_XFX_form.RS    = instruction[6:10];
        
        logic_to_XFX_form.spr   = instruction[11:20];
        logic_to_XFX_form.tbr   = instruction[11:20];
        logic_to_XFX_form.ALWAYS_ZERO   = instruction[11];
        logic_to_XFX_form.ALWAYS_ONE    = instruction[11];
        logic_to_XFX_form.FXM   = instruction[12:19];
        
        logic_to_XFX_form.XO    = instruction[21:30];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:7] FLM;
        logic[0:4] FRB;
        logic[0:9] XO;
        logic Rc;
    } XFL_form_t;
	
    function XFL_form_t logic_to_XFL_form(input logic[0:31] instruction);
        logic_to_XFL_form.OPCD  = instruction[0:5];
        logic_to_XFL_form.FLM   = instruction[7:14];
        logic_to_XFL_form.FRB   = instruction[16:20];
        logic_to_XFL_form.XO    = instruction[21:30];
        logic_to_XFL_form.Rc    = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] RS;
        logic[0:4] RA;
        logic[0:5] sh;
        logic[0:8] XO;
        logic Rc;
    } XS_form_t;
	
    function XS_form_t logic_to_XS_form(input logic[0:31] instruction);
        logic_to_XS_form.OPCD   = instruction[0:5];
        logic_to_XS_form.RS     = instruction[6:10];
        logic_to_XS_form.RA     = instruction[11:15];
        logic_to_XS_form.sh     = {instruction[16:20], instruction[30]};
        logic_to_XS_form.XO     = instruction[21:29];
        logic_to_XS_form.Rc     = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] RT;
        logic[0:4] RA;
        logic[0:4] RB;
        logic OE;
        logic[0:8] XO;
        logic Rc;
    } XO_form_t;
	
    function XO_form_t logic_to_XO_form(input logic[0:31] instruction);
        logic_to_XO_form.OPCD   = instruction[0:5];
        logic_to_XO_form.RT     = instruction[6:10];
        logic_to_XO_form.RA     = instruction[11:15];
        logic_to_XO_form.RB     = instruction[16:20];
        logic_to_XO_form.OE     = instruction[21];
        logic_to_XO_form.XO     = instruction[22:30];
        logic_to_XO_form.Rc     = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] FRT;
        logic[0:4] FRA;
        logic[0:4] FRB;
        logic[0:4] FRC;
        logic[0:4] XO;
        logic Rc;
    } A_form_t;
	
    function A_form_t logic_to_A_form(input logic[0:31] instruction);
        logic_to_A_form.OPCD    = instruction[0:5];
        logic_to_A_form.FRT     = instruction[6:10];
        logic_to_A_form.FRA     = instruction[11:15];
        logic_to_A_form.FRB     = instruction[16:20];
        logic_to_A_form.FRC     = instruction[21:25];
        logic_to_A_form.XO      = instruction[26:30];
        logic_to_A_form.Rc      = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] RS;
        logic[0:4] RA;
        logic[0:4] RB, SH;
        logic[0:4] MB;
        logic[0:4] ME;
        logic Rc;
    } M_form_t;
	
    function M_form_t logic_to_M_form(input logic[0:31] instruction);
        logic_to_M_form.OPCD    = instruction[0:5];
        logic_to_M_form.RS      = instruction[6:10];
        logic_to_M_form.RA      = instruction[11:15];
        
        logic_to_M_form.RB      = instruction[16:20];
        logic_to_M_form.SH      = instruction[16:20];
        
        logic_to_M_form.MB      = instruction[21:25];
        logic_to_M_form.ME      = instruction[26:30];
        logic_to_M_form.Rc      = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] RS;
        logic[0:4] RA;
        logic[0:5] sh;
        logic[0:5] mb, me;
        logic[0:2] XO;
        logic Rc;
    } MD_form_t;
	
    function MD_form_t logic_to_MD_form(input logic[0:31] instruction);
        logic_to_MD_form.OPCD   = instruction[0:5];
        logic_to_MD_form.RS     = instruction[6:10];
        logic_to_MD_form.RA     = instruction[11:15];
        
        logic_to_MD_form.sh     = {instruction[16:20], instruction[30]};
        
        logic_to_MD_form.mb     = instruction[21:26];
        logic_to_MD_form.me     = instruction[21:26];
        
        logic_to_MD_form.XO     = instruction[27:29];
        
        logic_to_MD_form.Rc     = instruction[31];
    endfunction
    
    typedef struct packed {
        logic[0:5] OPCD;
        logic[0:4] RS;
        logic[0:4] RA;
        logic[0:4] RB;
        logic[0:5] mb, me;
        logic[0:3] XO;
        logic Rc;
    } MDS_form_t;
	
    function MDS_form_t logic_to_MDS_form(input logic[0:31] instruction);
        logic_to_MDS_form.OPCD  = instruction[0:5];
        logic_to_MDS_form.RS    = instruction[6:10];
        logic_to_MDS_form.RA    = instruction[11:15];
        logic_to_MDS_form.RB    = instruction[16:20];
        
        logic_to_MDS_form.mb    = instruction[21:26];
        logic_to_MDS_form.me    = instruction[21:26];
        
        logic_to_MDS_form.XO    = instruction[27:30];
        
        logic_to_MDS_form.Rc    = instruction[31];
    endfunction
    // ------ Types for instruction formats END ------
    
    
    
    // ------ Types for branch processor START ------
    typedef enum logic[0:1] {
        BRANCH, BRANCH_CONDITIONAL, BRANCH_CONDITIONAL_LINK, BRANCH_CONDITIONAL_COUNT
    } branch_op_t;
    
    typedef struct packed {
        branch_op_t operation;
        logic LK;
        logic AA;
        logic[0:23] LI;
        logic[0:13] BD;
        logic[0:4] BI;
        logic[0:4] BO;
        logic[0:1] BH;
    } branch_inner_decode_t;
    
    typedef enum logic[0:3] {
        COND_AND, COND_OR, COND_XOR, COND_NAND, COND_NOR, COND_EQUIVALENT, COND_AND_COMPLEMENT, COND_OR_COMPLEMENT, COND_MOVE
    } condition_op_t;
    
    typedef struct packed {
        condition_op_t operation;
        logic[0:4] CR_op1_reg_address;
        logic[0:4] CR_op2_reg_address;
        logic[0:4] CR_result_reg_address;
    } condition_decode_t;
    
    typedef enum logic[0:1] {
        EXEC_BRANCH_NONE = 0, EXEC_BRANCH, EXEC_SYSTEM_CALL, EXEC_CONDITION
    } branch_execute_t;
    
    typedef struct packed {
        branch_execute_t execute;
        branch_inner_decode_t branch_decoded;
        logic[0:6] system_call_decoded;
        condition_decode_t condition_decoded;
    } branch_decode_t;
    // ------ Types for branch processor END ------
    
    
    
    // ------ Types for fixed point processor START ------
    typedef struct packed {
        logic[0:4] op1_reg_address;
        logic[0:4] op2_reg_address;
        logic[0:4] result_reg_address;
        logic op1_use_imm;
        logic op2_use_imm;
        logic[0:31] op1_immediate;
        logic[0:31] op2_immediate;
    } common_control_t;
    
    typedef struct packed {
        logic[0:1] word_size; // in bytes-1
        logic write_ea; // write effective address
        logic sign_extend;
        logic little_endian;
        logic multiple;
    } load_store_decode_t;
    
    typedef struct packed {
        logic subtract;
        logic alter_CA;
        logic alter_CR0;
        logic alter_OV;
        logic add_CA;
    } add_sub_decode_t;
    
    typedef struct packed {
        logic mul_signed;
        logic mul_higher;
        logic alter_CR0;
        logic alter_OV;
    } mul_decode_t;
    
    typedef struct packed {
        logic div_signed;
        logic alter_CR0;
        logic alter_OV;
    } div_decode_t;
    
    typedef struct packed {
        logic cmp_signed;
        //logic[0:2] BF;
    } cmp_decode_t;
    
    typedef struct packed {
        logic[0:4] TO;
    } trap_decode_t;
    
    typedef enum logic[0:3] {
		LOG_AND, LOG_OR, LOG_XOR, LOG_NAND, LOG_NOR,
		LOG_EQUIVALENT, LOG_AND_COMPLEMENT, LOG_OR_COMPLEMENT,
		LOG_EXTEND_SIGN_BYTE, LOG_EXTEND_SIGN_HALFWORD, // LOG_EXTEND_SIGN_WORD is not supported
		LOG_COUNT_LEADING_ZEROS_WORD // LOG_COUNT_LEADING_ZEROS_DOUBLEWORD is not supported
		// LOG_POPULATION_COUNT_BYTES // popcntb doesn't seem to exist on 32 bit implementations, but it's not mentioned anywhere
	} logical_op_t;
    
    typedef struct packed {
        logical_op_t operation;
        logic alter_CR0;
    } log_decode_t;
    
    typedef struct packed {
        logic[0:4] MB;
        logic[0:4] ME;
        logic mask_insert;
        // Shift specific variables
        logic shift;
        logic left;
        logic sign_extend;

        logic alter_CR0;
    } rotate_decode_t;
    
    typedef enum logic[0:1] {
        SYS_MOVE_TO_SPR, SYS_MOVE_FROM_SPR, SYS_MOVE_TO_CR, SYS_MOVE_FROM_CR
    } system_op_t;
    
    typedef struct packed {
        system_op_t operation;
        logic[0:9] SPR; // Special purpose register address
        logic[0:7] FXM; // Field mask
    } system_decode_t;
    
    typedef enum logic[0:3] {
        EXEC_FIXED_NONE = 0, EXEC_LOAD, EXEC_STORE, EXEC_LOAD_STRING, EXEC_STORE_STRING, EXEC_ADD_SUB, EXEC_MUL, EXEC_DIV, EXEC_COMPARE, EXEC_TRAP, EXEC_LOGICAL, EXEC_ROTATE, /*EXEC_SHIFT,*/ EXEC_SYSTEM
    } fixed_execute_t;
    
    typedef struct packed {
        fixed_execute_t execute;
        common_control_t control;
        load_store_decode_t load_store;
        add_sub_decode_t add_sub;
        mul_decode_t mul;
        div_decode_t div;
        cmp_decode_t cmp;
        trap_decode_t trap;
        log_decode_t log;
        rotate_decode_t rotate;
        system_decode_t system;
    } fixed_point_decode_t;
    // ------ Types for fixed point processor END ------
    
    
    
    // ------ Types for floating point processor START ------
    //typedef struct packed {
    //} floating_point_decode_t
    // ------ Types for floating point processor END ------
    
    
    typedef struct packed {
        branch_decode_t branch;
        fixed_point_decode_t fixed_point;
        //floating_point_decode_t floating_point;
    } decode_result_t;
    
    
    // ------ Functions for simpler decoding START ------
    function fixed_point_decode_t decode_load_zero(input D_form_t D_form, input int bytes, logic update, logic algebraic, logic multiple);
        decode_load_zero = '{default: '{default: '0}};
        if(D_form.RA == 0 && update == 0) begin
            decode_load_zero.control.op1_use_imm = 1;	// immediate is zero by default																			
        end else begin																			
            decode_load_zero.control.op1_reg_address = D_form.RA;						
        end						
        decode_load_zero.control.op2_use_imm = 1;					
        decode_load_zero.control.op2_immediate = D_form.D;
        decode_load_zero.load_store.word_size = bytes-1;								
        decode_load_zero.control.result_reg_address = D_form.RT;
        decode_load_zero.load_store.sign_extend = algebraic;
        decode_load_zero.load_store.write_ea = update;
        decode_load_zero.load_store.multiple = multiple;
    endfunction
    
    function fixed_point_decode_t decode_load_store_x_form(input X_form_t X_form, input int bytes, logic update, logic algebraic, logic reversed);
        decode_load_store_x_form = '{default: '{default: '0}};
        if(X_form.RA == 0 && update == 0) begin
            decode_load_store_x_form.control.op1_use_imm = 1;	// immediate is zero by default																			
        end else begin																				
            decode_load_store_x_form.control.op1_reg_address = X_form.RA;						
        end												
        decode_load_store_x_form.control.op2_reg_address = X_form.RB;
        decode_load_store_x_form.load_store.word_size = bytes-1;								
        decode_load_store_x_form.control.result_reg_address = X_form.RT;
        decode_load_store_x_form.load_store.sign_extend = algebraic;
        decode_load_store_x_form.load_store.write_ea = update;
        decode_load_store_x_form.load_store.little_endian = reversed;
    endfunction
    // ------ Functions for simpler decoding END ------
    
    // ------ Types for fixed point units START ------
    // Used to set bits in CR0 and XER
    typedef struct packed {
        // XER
        logic xer_valid;
        logic[0:31] xer;
        // CR0
        logic CR0_valid;
        logic so;   // SO is needed for CR0 calculation
    } cond_exception_t;
    // ------ Types for fixed point units END ------
    

`define declare_or_reduce(WIDTH)    \
    function logic or_reduce(input logic x[0:WIDTH-1]); \
        logic res = x[0];                               \
        for(int i = 1; i < WIDTH; i++) begin            \
            res |= x[i];                                \
        end                                             \
        return res;                                     \
    endfunction

    /*
    virtual class Reduction #(parameter WIDTH=32);
        static function logic or_reduce(input logic x[0:WIDTH-1]);
            logic res = x[0];
            for(int i = 1; i < WIDTH; i++) begin
                res |= x[i];
            end
            return res;
        endfunction
    
        static function logic and_reduce(input logic x[0:WIDTH-1]);
            logic res = x[0];
            for(int i = 1; i < WIDTH; i++) begin
                res &= x[i];
            end
            return res;
        endfunction
    endclass
    */
endpackage