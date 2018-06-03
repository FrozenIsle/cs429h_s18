
	.global depDivs
depDivs:
	/* lie */
	movq $1000, %rdi
	movq $3, %rsi
	.loop_deDivs:
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax

		divq %rsi
		divq %rsi
		divq %rsi
		divq %rsi
		divq %rsi

		divq %rsi
		divq %rsi
		divq %rsi
		divq %rsi
		divq %rsi

		divq %rsi
		divq %rsi
		divq %rsi
		divq %rsi
		divq %rsi

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_deDivs

	movq $15000, %rax
    ret


	.global indepDivs
indepDivs:
	/* lie */
	/* lie */
	movq $1000, %rdi
	movq $3, %rsi
	.loop_indeDivs:
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax

		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax

		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax
		divq %rsi

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_indeDivs

	movq $15000, %rax
    ret



	.global indepMuls
indepMuls:
	/* lie */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movq $1000, %rdi
//	movq $3, %rsi
	.loop_indeMuls:

		imulq $3, %rsi
		imulq $3, %rdx
		imulq $3, %rcx
		imulq $3, %r8
		imulq $3, %r9

		imulq $3, %r10
		imulq $3, %r11
		imulq $3, %r12
		imulq $3, %r13
		imulq $3, %r14

		imulq $3, %r15

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_indeMuls

	movq $11000, %rax
	
	popq %r15
	popq %r14
	popq %r13
	popq %r12

    ret


	.global depMuls
depMuls:
	/* lie */
	movq $1000, %rdi
	movq $1, %rsi
	.loop_deMuls:

		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi

		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi

		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi
		imulq $3, %rsi

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_deMuls

	movq $15000, %rax
    ret

	.global nops
nops:
	/* lie */
	movq $1000, %rdi
	.loop_nop:

		nop
		nop
		nop
		nop
		nop

		nop
		nop
		nop
		nop
		nop

		nop
		nop
		nop
		nop
		nop

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_nop

	movq $15000, %rax
    ret

	.global depLoads
depLoads:
	/* lie */
	movq $1000, %rdi

	movq %rsp, %rsi
	subq $8, %rsi
	movq %rsi, (%rsi)
	.loop_deLoads:

		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi

		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi

		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi
		movq (%rsi), %rsi

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_deLoads

	movq $15000, %rax
    ret

	.global indepLoads
indepLoads:
	/* lie */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movq $1000, %rdi

	movq %rsp, %rsi
	subq $8, %rsi
	movq %rsi, (%rsi)

	movq %rsi, %rdx
	subq $8, %rdx
	movq %rdx, (%rdx)

	movq %rdx, %rcx
	subq $8, %rcx
	movq %rcx, (%rcx)

	movq %rcx, %r8
	subq $8, %r8
	movq %r8, (%r8)

	movq %r8, %r9
	subq $8, %r9
	movq %r9, (%r9)
	
	movq %r9, %r10
	subq $8, %r10
	movq %r10, (%r10)

	movq %r10, %r11
	subq $8, %r11
	movq %r11, (%r11)

	movq %r11, %r12
	subq $8, %r12
	movq %r12, (%r12)

	movq %r12, %r13
	subq $8, %r13
	movq %r13, (%r13)
	
	movq %r13, %r14
	subq $8, %r14
	movq %r14, (%r14)

	movq %r14, %r15
	subq $8, %r15
	movq %r15, (%r15)

	.loop_indeLoads:

		movq (%rsi), %rsi
		movq (%rdx), %rdx
		movq (%rcx), %rcx
		movq (%r8), %r8
		movq (%r9), %r9

		movq (%r10), %r10
		movq (%r11), %r11
		movq (%r12), %r12
		movq (%r13), %r13
		movq (%r14), %r14

		movq (%r15), %r15

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_indeLoads

	movq $11000, %rax
	
	popq %r15
	popq %r14
	popq %r13
	popq %r12

    ret

	.globl indepAdds
indepAdds:
	/* lie */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movq $1000, %rdi
	.loop_indeAdds:

		addq $3, %rsi
		addq $3, %rdx
		addq $3, %rcx
		addq $3, %r8
		addq $3, %r9

		addq $3, %r10
		addq $3, %r11
		addq $3, %r12
		addq $3, %r13
		addq $3, %r14

		addq $3, %r15

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_indeAdds

	movq $11000, %rax
	
	popq %r15
	popq %r14
	popq %r13
	popq %r12

    ret

	.globl depAdds
depAdds:
	/* lie */
	movq $1000, %rdi
	movq $0, %rsi
	.loop_deAdds:
		movq $0, %rdx
		movq $0xffffffffffffffff, %rax

		addq  $3, %rsi
		addq $3, %rsi
		addq $3,  %rsi
		addq $3, %rsi
		addq $3, %rsi

		addq $3, %rsi
		addq $3, %rsi
		addq $3, %rsi
		addq $3, %rsi
		addq $3, %rsi

		addq $3, %rsi
		addq $3, %rsi
		addq $3, %rsi
		addq $3, %rsi
		addq $3, %rsi

		subq $1, %rdi
		cmpq $0, %rdi
		jne .loop_deAdds

	movq $15000, %rax
    ret
