# ALU-Calculator
Logical Implementation of ALU that uses the basic mathematical operations addition, subtraction, multiplication, and division with MIPS Assembly on MARS (MIPS Assembler and Runtime Simulator) by both logical and normal procedures.  

A.	MIPS Normal Procedure
The process for MIPS Normal Procedure is relatively simple. Given the $a2 argument, it can be determined what mathematical operation will be done, and branch accordingly.
1)	 For Operand ‘+’: 
Add the two mathematical operands, using the “add” instruction to determine the sum.
2)	For Operand ‘-’: 
Subtract the second mathematical operand from the first, using the “sub” instruction to determine the difference.
3)	For Operand ‘*’: 
Multiply the two mathematical operands, using the “mul” instruction to determine the product.
4)	For Operand ‘/’: 
Divide the first mathematical operand using the second, using the “div” method to determine the quotient and remainder.

B.	MIPS Logical Procedure
Procedures in au_logical use and call multiple procedures to aid with the mathematical process.
1)	add_sub_logical
add_sub_logical uses three variables: $a0, $a1, and $a2, which contains operand one, second operand, either 0x00000000 or 0xFFFFFFFF depending on the operation to be done being either subtraction or addition.
The index and sum are initialized as zero through registers $s0 and $s1.
For subtraction, the second operand $a1 is negated using NOR or NOT. Binary addition is used to add each bit one at a time. Using the extract_nth_bit macro the bit at the current index is stored into a temporary register and the sum is found by using XOR on the two. To find the carry out, the logical equation C(A xor B) + AB is used where A is operand 1 bit, B is operand 2 bit, and C the carry in bit. The product of this equation is then inserted into the sum at index point. Until the index equals 32, the index increments and the operation repeats. When the index equals 32, the loop ends.
For multiplication and division equations, the overflow operation is needed. Hence in add_sub_logical after finding the total sum, overflow is found by doing XOR on the sum’s bit at index 31 and 32, returning the 0 or 1 value in $v1. 
2)	add_logical 
If $a2 is equal to “+”, au_logical calls add_logical, initializing $a2 to 0x00000000 and calling add_sub_logical. The sum returned by add_sub_logical is then stored in $v0 and returned.
3)	sub_logical
If $a2 is equal to “-”, au_logical calls add_logical, initializing $a2 to 0xFFFFFFFF and calling add_sub_logical. The difference returned by add_sub_logical is then stored in $v0 and returned.
4)	twos_complement
For calculations in multiplication and division operations, twos_complement is used. procedure takes in argument $a0, and returns its two’s complement. $v0 is returned with value ~$a0 + 1. To do this $a0 is negated using not or nor, and $a1 is loaded with 1 to call add_logical. add_logical returns $v0, which is also returned by twos_complement.
5)	twos_complement_if_neg
Before twos_complement, twos_complement_if_neg sees if the $a0 operand is negative or not. If it is negative, it calls twos_complement and returns $v0 from it. Else it returns $v0 to be $a0 with no changes.
6)	twos_complement_64bit
twos_complement_64bit uses two arguments, $a0 and $a1, which are the lower 8 bit of the number and the higher 8 bit respectively. It returns $v0, the 2’s complement of $a0 and $v1, the 2’s complement of $a1. This is also where the final carryout from add_sub_logical is utilized.
$a0 and $a1 are inverted using NOT, and add_logical is called to add 1 to both. After add_logical is complete, the carry out from $v1 is checked. As seen in Fig. 11, if $v1 is 1, the hi bit ($a1) is negative, and $v1 is loaded with 0xFFFFFFFF. Otherwise $v1 equals $v0 from ~$a1+1, and $v0 equals $v0 from ~$a0+1.
7)	bit_replicator
bit_replicator replicates a given bit value 32 times, taking in argument $a0 which will contain either 0x0 or 0x1 and returning $v0. If $a0 equals 0x0, $v0 returns 0x00000000, otherwise $a0 is 0x1 and $v0 returns 0xFFFFFFFF.
8)	mul_unsigned
mul_unsigned returns the product from doing unsigned multiplication. It uses two arguments: $a0 and $a1, the multiplicand and the multiplier, and returns $v0 and $v1, the lo bits and the hi bit of the product. It initializes index at 0, high register at 0, low register as $a1, and multiplier as $a0, the multiplicand.
To begin multiplication, the least significant bit of the low register is replicated using bit_replicator. Then we find the AND of the multiplier and the replicated low register, using OR on that and the hi register. The lo register shifts right by 1 bit, and the insert_to_nth_bit macro inserts the bit at 0 in hi register to index 31 on the low register. The high register then shifts right by 1 bit. The index increments and will repeat the operation until the index equals to 32.
When the index is 32, the operation ends, with $v0 returning the lo register and $v1 returning the hi register.
9)	mul_signed
mul_signed returns the product from doing signed multiplication. It uses two arguments: $a0 and $a1, the multiplicand and the multiplier, and returns $v0 and $v1, the lo bits and the hi bit of the product. 
twos_complement_if_neg is called on both $a0 and $a1. Then unsigned multiplication is called. To determine if the product is negative, we extract the 31st of the multiplicand and the 32nd bit of the multiplier and call XOR. If the result is 1, it twos_complement_64bit is called as the result is negative. Otherwise $v0 and $v1 are the respective lo and hi results found by unsigned multiplication.
10)	div_unsigned
div_unsigned returns the quotient after unsigned division. It uses $a0 and $a1, dividend and the divisor, and returns $v0 and $v1, quotient and the remainder. It initializes index at 0, quotient as the dividend, divisor as $a1, and remainder as 0.
The operation begins by shifting the remainder left by 1 bit. At the remainder’s 0th index, the quotient’s 31st index bit is inserted using the macro extract_nth_bit. After that, the quotient is shifted left by 1 bit. sub_logical is called to subtract the remainder by the divisor. If the difference is lower than 0, remainder initializes to the difference and the quotient at its 0th index has 1 inserted using extract_nth_bit. Regardless of whether or not the difference is less than 0, the index increments, and the procedure repeats until the index equals to 32, after which it returns $v0 and $v1.
11)	div_signed
div_signed returns the quotient from doing signed division. It uses $a0 and $a1, dividend and the divisor, and returns $v0 and $v1, quotient and the remainder. 
twos_complement_if_neg is called on both $a0 and $a1. Then unsigned division is called. The sign of the quotient is determined after extracting the 31st of the dividend and the 32nd bit of the divisor and XOR them to get a result. If it is 1, and twos_complement is called to determine the negative quotient. Otherwise $v0 is the quotient as is.
The same procedure occurs to find the sign of the remainder, as seen in Fig. 16. The 31st bit of $a0 is extracted. If it is equal to one, the remainder is negative and twos_complement must be called on the remainder to determine its value. Otherwise $v0 is equal to the remainder as is.

C.	Macros
1)	extract_nth_bit($regD, $regS, $regT)
Macro extract_nth_bit is used by extracting a bit at a given position in a provided bit pattern. There are three used arguments: $regD which will contain 0x0 or 0x1 and we will return, $regS which is the original bit pattern, and $regT which is the position at which we extract.
To extract a bit, we use a mask register, 0x00000001, and shift it left by the amount given by $regT. After we reach that position we compare it to $regS with AND, which will return a bit pattern that is all 0 except for at the position of $regT, which can either be 0 or 1. We then shift right the mask by $regT amount and return it in $regD.
2)	insert_to_nth_bit($regD, $regS, $regT, $maskReg)
Macro insert_to_nth_bit is used by inserting a bit at a given position in a provided bit pattern. It takes in four arguments: $regD as the bit pattern where we will insert, $regS as the position from where the bit will be inserted, $regT as the register holding the 0x1 or 0x0 that we will insert, and $maskReg as the register holding a temporary mask.
The $maskReg is shifted left by the amount given by $regS, and turned into its complement by either NOR or NOT. Then AND is used on ~$maskReg and $regD. $regT is shifted left by $regS amount, and it is then used OR with ~$maskReg AND $regD. The resulting amount is returned in $regD.
