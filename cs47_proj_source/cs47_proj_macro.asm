# Add you macro definition here - do not touch cs47_common_macro.asm"
#<------------------ MACRO DEFINITIONS ---------------------->#
	# Macro : extract_nth_bit
        # Usage: extract nth bit from a bit pattern
        #	$regD: Will contain 0x0 or 0x1 depending on nth bit being 0 or 1
        #	$regS: Source bit pattern
        #	$regT: Bit position n(0-31)
	.macro	extract_nth_bit($regD, $regS, $regT)
	lui $t1, 0x0000
	ori $t1, 0x0001
	sllv $t1, $t1, $regT  #shift $t1 left by n amount
	and $regD, $regS, $t1 # ex if n = 1 and regS = 00001110; compares 0001110 to 000000010 which returns 0000010
	srlv $regD, $regD, $regT #shift back to pos; ex if 0000010, now 0000001
	.end_macro
	
	# Macro : insert_to_nth_bit
        # Usage: insert 1/0 bit at nth bit of a bit pattern
        #	$regD: bit pattern at which 1/0 inserted
        #	$regS: n position
        #	$regT: Reg containing 0x0 or 0x1
        #	$maskReg: Reg to hold temporary mask
	.macro	insert_to_nth_bit($regD, $regS, $regT, $maskReg)
	sllv $maskReg, $maskReg, $regS # M = M << n
	nor $maskReg, $maskReg, $maskReg # M = !M
	and $t1, $maskReg, $regD # M! && D
	
	sllv $regT, $regT, $regS # b = b << n
	
	or $regD, $t1, $regT # (M! && D)||b
	.end_macro