.include "./cs47_proj_macro.asm"
.text
.globl au_logical
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:
	# Caller RTE store
	addi $sp, $sp, -20
	sw $fp, 16($sp)
	sw $ra, 12($sp)
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	addi $fp, $sp, 20
	
	beq $a2, '+', add_logical
	beq $a2, '-', sub_logical
	beq $a2, '*', mul_signed
	beq $a2, '/', div_signed
#<------------------ FOR DIV ---------------------->#
div_unsigned:
	# Caller RTE store
	addi $sp, $sp, -40
	sw $fp, 36($sp)
	sw $ra, 32($sp)
	sw $s0, 28($sp) #index var I
	sw $s1, 24($sp) #Q (dividend)
	sw $s2, 20($sp) #D (divisor)
	sw $s3, 16($sp) #R
	sw $s4, 12($sp) #S
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	addi $fp, $sp, 40
	
	li $s0, 0
	move $s1, $a0
	move $s2, $a1
	li $s3, 0
	
	unsigned_division_start:
	sll $s3, $s3, 1 # R = R << 1
	
	li $t2, 31
	extract_nth_bit($t0, $s1, $t2) #$t0 = Q[31]
	lui $t3, 0x0000
	ori $t3, 0x0001
	insert_to_nth_bit($s3, $zero, $t0, $t3) #R[0] = Q[31]
	
	sll $s1, $s1, 1 # Q = Q << 1
	
	move $a0, $s3
	move $a1, $s2
	li $a2, '-'
	jal au_logical #R - D
	
	move $a0, $s1
	move $a1, $s2 #restore $a1 and $a0
	move $s4, $v0 #S = R - D
	
	blt $s4, $zero, unsigned_less_than #if S < 0
	move $s3, $s4 #R = S
	lui $t3, 0x0000
	ori $t3, 0x0001
	li $t0, 1
	insert_to_nth_bit($s1, $zero, $t0, $t3) #Q[0] = 1
	
	unsigned_less_than:
	addi $s0, $s0, 1
	
	bne $s0, 32, unsigned_division_start
	
	move $v0, $s1
	move $v1, $s3
	
	lw $fp, 36($sp)
	lw $ra, 32($sp)
	lw $s0, 28($sp) 
	lw $s1, 24($sp) 
	lw $s2, 20($sp) 
	lw $s3, 16($sp)
	lw $s4, 12($sp) 
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	addi $sp, $sp, 40
	jr 	$ra
div_signed:
	# Caller RTE store
	addi $sp, $sp, -40
	sw $fp, 36($sp)
	sw $ra, 32($sp)
	sw $s0, 28($sp) # N1
	sw $s1, 24($sp) # N2
	sw $s2, 20($sp) #R
	sw $s3, 16($sp) #Q
	sw $s4, 12($sp) #S
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	addi $fp, $sp, 40
	
	move $s2, $a0
	move $s3, $a1 #save $a0 and $a1 temporarily
	
	jal twos_complement_if_neg
	move $s0, $v0 # N1 = 2's complement $a0
	
	move $a0, $a1
	jal twos_complement_if_neg
	move $s1, $v0 # N2 = 2's complement $a1
	
	move $a0, $s0
	move $a1, $s1
	
	move $s0, $s2
	move $s1, $s3 #temp sub
	
	jal div_unsigned
	move $s2, $v1 #R
	move $s3, $v0 #Q
	
	li $t3, 31
	extract_nth_bit($t0, $s0, $t3) #$a0[31]
	extract_nth_bit($t2, $s1, $t3) #$a1[31]
	
	xor $s4, $t0, $t2 #S = $a0[31] xor $a1[31]
	
	move $v0, $s3
	
	bne $s4, 1, do_remainder_sign # if S = 1, do 2s complement (Q)
    	move $a0, $s3 
    	jal twos_complement
    	
    	do_remainder_sign: #if S = 1, do 2s complement (R)
	move $v1, $s2
    	li $t3, 31
	extract_nth_bit($t0, $s0, $t3) #$a0[31]
	bne $t0, 1, end_signed_div
    	move $a0, $s2 
    	move $s0, $v0
    	jal twos_complement
    	move $v1, $v0
    	move $v0, $s0
    	
    	end_signed_div: 
    	lw $fp, 36($sp)
	lw $ra, 32($sp)
	lw $s0, 28($sp) 
	lw $s1, 24($sp) 
	lw $s2, 20($sp) 
	lw $s3, 16($sp) 
	lw $s4, 12($sp)
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 40
	j au_logical_exit
#<------------------ FOR MULT ---------------------->#
# return $v0: two's complement of $a0
twos_complement: 
	# Caller RTE store
	addi $sp, $sp, -32
	sw $fp, 28($sp)
	sw $ra, 24($sp)
	sw $s0, 20($sp)
	sw $s1, 16($sp) 
	sw $s2, 12($sp)
	sw $a1, 8($sp)
	sw $a2, 4($sp)
	sw $a0, 0($sp)
	addi $fp, $sp, 32
	
	nor $a0, $a0, $a0 #~$a0
	li $a1, 1
	li $a2, '+'
	jal au_logical #~$a0+1
	
	#Restore frame
	lw $fp, 28($sp)
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $a1, 8($sp)
	lw $a2, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 32
	jr 	$ra
	
# return $v0: two's complement of $a0 if $a0 is neg
twos_complement_if_neg: 
	# Caller RTE store
	addi $sp, $sp, -12
	sw $fp, 8($sp)
	sw $ra, 4($sp)
	addi $fp, $sp, 12
	
	bge $a0, $zero, is_pos #if not negative, return $a0
	jal twos_complement
	
	if_neg_finished:
	lw $fp, 8($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 12
	jr 	$ra
	
	is_pos: 
	move $v0, $a0
	j if_neg_finished
	
twos_complement_64bit: 
	# Caller RTE store
	addi $sp, $sp, -32
	sw $fp, 28($sp)
	sw $ra, 24($sp)
	sw $s0, 20($sp)
	sw $s1, 16($sp) 
	sw $s2, 12($sp)
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	addi $fp, $sp, 32
	
	not $a0, $a0	#$a0 = ~$a0 (not hi)
	move $s2, $a1 #temp store
	li $a1, 1
	li $a2, '+'
	jal au_logical	#~$a0 + 1 (not hi + 1)
	#move $v0, $s1   #lo part of 64 bit
	
	move $a0, $v1	#$a1 = carry
	move $a1, $s2
	move $s2, $v0 #temp carry
	not $a1, $a1
	li $a2, '+'
	jal au_logical	#~$a1 + 1 (not lo + 1)
	bne $v1, 1, pos #if $v1 is 1, neg hi
	lui $v1, 0xFFFF
	ori $v1, 0xFFFF
	move $v0, $s2
	j signed_restore
	
	pos:
	move $v1, $v0	#hi part of 64 bit
	move $v0, $s2
	
	signed_restore:
	#Restore frame
	lw $fp, 28($sp)
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	addi $sp, $sp, 32
	jr 	$ra
	
bit_replicator:
	# Caller RTE store
	addi $sp, $sp, -8
	sw $fp, 4($sp)
	sw $ra, 0($sp)
	addi $fp, $sp, 8
	
	beq $a0, 0x0, return_zero
	lui $v0, 0xFFFF
	ori $v0, 0xFFFF
	j bit_rep_end
	
	return_zero:
	lui $v0, 0x0000
	ori $v0, 0x0000
	
	bit_rep_end:
	lw $fp, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr 	$ra
	
mul_unsigned: 
	# Caller RTE store
	addi $sp, $sp, -40
	sw $fp, 36($sp)
	sw $ra, 32($sp)
	sw $s0, 28($sp) #index var I
	sw $s1, 24($sp) #H (high)
	sw $s2, 20($sp) #L (low)
	sw $s3, 16($sp) #M (multiplicand)
	sw $s4, 12($sp) #X
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	addi $fp, $sp, 40
	
	move $s2, $a1 # L = MPLR
	move $s3, $a0 # M = MCND
	move $s0, $zero # I = 0
	move $s1, $zero # H = 0
	
	begin_mul: #multiplication begins here
	extract_nth_bit($a0, $s2, $zero) #$a0 = L[0]
	jal bit_replicator #$v0 = R = 32{L[0]}
	
	and $s4, $v0, $s3 # X = M & R
	
	move $a0, $s1 #H
	move $a1, $s4 #X
	li $a2, '+'
	jal au_logical #H+X
	move $s1, $v0 #H = H+X
	
	srl $s2, $s2, 1 # L = L>>1 
	
	extract_nth_bit($t2, $s1, $zero) #H[0]
	
	li $t3, 31
	lui $t4, 0x0000 #$maskReg
	ori $t4, 0x0001 
	insert_to_nth_bit($s2, $t3, $t2, $t4) # L[31] = H[0]
	
	srl $s1, $s1, 1 # H = H>>1
	
	addi $s0, $s0, 1
	bne $s0, 32, begin_mul
	
	move $v0, $s2 #$v0 = lo
    	move $v1, $s1 #$v1 = hi
    	
	lw $fp, 36($sp)
	lw $ra, 32($sp)
	lw $s0, 28($sp) 
	lw $s1, 24($sp) 
	lw $s2, 20($sp) 
	lw $s3, 16($sp)
	lw $s4, 12($sp) 
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	addi $sp, $sp, 40
	jr 	$ra

mul_signed:
	# Caller RTE store
	addi $sp, $sp, -40
	sw $fp, 36($sp)
	sw $ra, 32($sp)
	sw $s0, 28($sp) # N1
	sw $s1, 24($sp) # N2
	sw $s2, 20($sp) #Rhi
	sw $s3, 16($sp) #Rlo
	sw $s4, 12($sp) #S
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	addi $fp, $sp, 40
	
	move $s2, $a0
	move $s3, $a1 #save $a0 and $a1 temporarily
	
	jal twos_complement_if_neg
	move $s0, $v0 # N1 = 2's complement $a0
	
	move $a0, $a1
	jal twos_complement_if_neg
	move $s1, $v0 # N2 = 2's complement $a1
	
	move $a0, $s0
	move $a1, $s1
	
	move $s0, $s2
	move $s1, $s3 #temp sub
	
	jal mul_unsigned
	move $s2, $v1 #Rhi = hi
	move $s3, $v0 #Rlo = lo
	
	li $t3, 31
	extract_nth_bit($t0, $s0, $t3) #$a0[31]
	extract_nth_bit($t2, $s1, $t3) #$a1[31]
	
	xor $s4, $t0, $t2 #S = $a0[31] xor $a1[31]
	
	beq $s4, 1, make_complement_mult_signed # if S = 1, do 2s complement 64 bit
    	move $v0, $s3
    	move $v1, $s2
    	
    	end_signed_mult: 
    	lw $fp, 36($sp)
	lw $ra, 32($sp)
	lw $s0, 28($sp) 
	lw $s1, 24($sp) 
	lw $s2, 20($sp) 
	lw $s3, 16($sp) 
	lw $s4, 12($sp)
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 40
	j au_logical_exit
	
	make_complement_mult_signed:
	move $a0, $s3 #$a0 = lo
	move $a1, $s2 #$a1 = hi
    	jal twos_complement_64bit
    	j end_signed_mult
#<------------------ FOR ADD/SUB ---------------------->#
#return $a0+$a1 = $v0
add_logical:
	# Caller RTE store
	addi $sp, $sp, -32
	sw $fp, 28($sp)
	sw $ra, 24($sp)
	sw $s0, 20($sp) #index var I
	sw $s1, 16($sp) #summation S
	sw $s2, 12($sp) #C
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	addi $fp, $sp, 32
	
	lui $a2, 0x0000 #upper 
	ori $a2, 0x0000 #lower
	jal add_sub_logical 
	move $v0, $s1 
	
	#Restore frame
	lw $fp, 28($sp)
	lw $ra, 24($sp)
	lw $s0, 20($sp) 
	lw $s1, 16($sp) 
	lw $s2, 12($sp) 
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	addi $sp, $sp, 32
	
	j au_logical_exit
	
#return $a0-$a1 = $v0
sub_logical:
	# Caller RTE store
	addi $sp, $sp, -32
	sw $fp, 28($sp)
	sw $ra, 24($sp)
	sw $s0, 20($sp) #index var I
	sw $s1, 16($sp) #summation S
	sw $s2, 12($sp) #C
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	addi $fp, $sp, 32
	
	lui $a2, 0xFFFF
	ori $a2, 0xFFFF
	jal add_sub_logical
	move $v0, $s1 
	
	#Restore frame
	lw $fp, 28($sp)
	lw $ra, 24($sp)
	lw $s0, 20($sp) 
	lw $s1, 16($sp) 
	lw $s2, 12($sp) 
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	addi $sp, $sp, 32
	
	j au_logical_exit
	
add_sub_logical:
	move $s0, $zero # I = 0
	move $s1, $zero # S = 0
	extract_nth_bit($s2, $a2, $zero) #C = $a2[0]
	beq $s2, 0, addition #if '+' go to add
	
	subtraction:
	nor $a1, $a1, $a1 # $a1 negated ($a1 = ~$a1)
	
	addition:
	extract_nth_bit($t0, $a0, $s0) # $t0 = $a0[I] = A
	extract_nth_bit($t2, $a1, $s0) # $t1 = $a1[I] = B
	
	#one bit addition A xor B xor C
	xor $t3, $t0, $t2 # A xor B
	xor $t4, $t3, $s2 
	
	#carry out:
	and $t5, $t0, $t2 #AB
	and $s2, $s2, $t3 # C(A xor B)
	or $s2, $s2, $t5 # C(A xor B) + AB
    	
	lui $t6, 0x0000 #$maskReg
	ori $t6, 0x0001 
	
	insert_to_nth_bit($s1, $s0, $t4, $t6) # S[I] = Y
	addi $s0, $s0, 1 # I++	
	bne $s0, 32, addition
	
	#for overflow
	li $s0, 31
	extract_nth_bit($t0, $s1, $s0) # $t0 = $a0[I] = A
	li $s0, 32
	extract_nth_bit($t2, $s1, $s0) # $t1 = $a1[I] = B
	xor $v1, $t1, $t2 #xor Cn-1 and Cn
	
	jr $ra

au_logical_exit:
	#Restore frame
	lw $fp, 16($sp)
	lw $ra, 12($sp)
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	addi $sp, $sp, 20
	
	jr 	$ra 
