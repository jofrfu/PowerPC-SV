# Assembly test file for ppc cond_reg_file
li 4, 256
li 5, 8
# Test superscalar add, div and mul
add 6, 4, 5
divw 7, 4, 5
mullw 8, 4, 5
