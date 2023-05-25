.include "./cs47_proj_macro.asm"
.text
.globl au_normal
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_normal:
	beq $a2, '+', au_normal_add # if '+' add
	beq $a2, '-', au_normal_sub # if '-' sub
	beq $a2, '*', au_normal_mul # if '*' mul
	beq $a2, '/', au_normal_div # if '/' div
au_normal_add:
	add	$v0, $a0, $a1
	j	au_normal_exit
au_normal_sub:
	sub	$v0, $a0, $a1 
	j	au_normal_exit
au_normal_mul:
	mult $a0, $a1
	mflo	$v0 
	mfhi	$v1 
	j	au_normal_exit
au_normal_div:
	div 	$a0, $a1 
	mfhi	$v1
	mflo	$v0	
	j	au_normal_exit
au_normal_exit:
	jr	$ra
