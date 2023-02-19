# Assembly test file for ppc cond_reg_file
li 4, 256
li 5, 8
# Test superscalar add, div and mul
add 6, 4, 5
divw 7, 4, 5
mullw 8, 4, 5
# Test load and store, TODO: understand what's going on here!
li 4, 0x01
rlwimi 4, 4, 8, 0, 23
ori 4, 4, 0x02
rlwimi 4, 4, 8, 0, 23
ori 4, 4, 0x03
rlwimi 4, 4, 8, 0, 23
ori 4, 4, 0x04

stw 4, 0(0)

li 5, 0x05
rlwimi 5, 5, 8, 0, 23
ori 5, 5, 0x06
rlwimi 5, 5, 8, 0, 23
ori 5, 5, 0x07
rlwimi 5, 5, 8, 0, 23
ori 5, 5, 0x08

stw 5, 4(0)

lwz 15, 0(0)
lwz 16, 4(0)
