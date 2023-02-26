# Assembly test file for ppc cond_reg_file
li 4, 256
li 5, 8
# Test superscalar add, div and mul
add 6, 4, 5
divw 7, 4, 5
mullw 8, 4, 5
# Test load and store
li 4, 0x01
slwi 4, 4, 8
ori 4, 4, 0x02
slwi 4, 4, 8
ori 4, 4, 0x03
slwi 4, 4, 8
ori 4, 4, 0x04

stw 4, 0(0)

li 5, 0x05
slwi 5, 5, 8
ori 5, 5, 0x06
slwi 5, 5, 8
ori 5, 5, 0x07
slwi 5, 5, 8
ori 5, 5, 0x08

stw 5, 4(0)

lwz 15, 0(0)
lwz 16, 4(0)
