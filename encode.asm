	;; file: encode.asm
	;;
	;;

%define STDIN 0
%define STDOUT 1
%define SYSCALL_EXIT 1
%define SYSCALL_READ 3
%define SYSCALL_WRITE 4
%define BUFLEN 256

	SECTION .data   	;initialized data section ex)msg
msg_err:	db "Read error", 10
len_err:	equ $-msg_err


	SECTION .bss		;uninitialized data section

input:	resb BUFLEN		;buf for input
iLen:	resb 4			;length of input
iLen2:	resb 4
result:	resb BUFLEN		;result of the code

	
	SECTION .text		;code section.
	global _start		;let loader see entry point

_start:	 nop			;entry point
start:				;address for gdb

	mov	eax, SYSCALL_READ ;
	mov 	ebx, STDIN
	mov	ecx, input
	mov 	edx, BUFLEN
	int 	080h

	;; error check

	mov	[iLen], eax
	mov	[iLen2], eax
	cmp	eax, 0
	jg 	read_OK
	mov	eax, SYSCALL_WRITE
	mov	ebx, STDOUT
	mov	ecx, msg_err
	mov	edx, len_err
	int 	080h
	jmp	exit

read_OK:
	;;
Loop_init:
	mov	ecx, [iLen]
	mov	edx, 0
	mov	esi, input
	mov	edi, result

Loop_top:
	;; when there are no input
	mov	edx, 0
	mov 	[result], edx
	mov	ecx, [iLen]
	cmp	ecx, 0
	je	setMB3		;set mb when %3 is 0

	;; for 1st element
	and 	eax, 0		;zero out eax
	mov	al, [esi]	;mov first element from esi to al
	shl	eax, 24		;shift to very left
	mov	edx, eax	;move to dx register
	inc	esi
	dec	ecx
	cmp	ecx, 0
	je	setMB1		;set mb when %3 is 1

	;; for 2nd element

	and	eax, 0		;zero out eax
	mov	al, [esi]	;mov 2nd element to al
	and	al, 0FEh		;cut out the b0 
	shl	eax, 16		;shift to 23 to 17
	or 	edx, eax	;add to edx register
	mov	al, [esi]
	and 	al, 000001h		;get b0
        shl	eax, 15		;shift to 15
	or	edx, eax	; add to edx register
	inc	esi
	dec	ecx
	cmp	ecx, 0
	je	setMB2		;set mb when %3 is 2

	;;for 3rd element
	and	eax, 0		; zero out eax
	mov	al, [esi]	;mov to 3rd element to al
	and	al, 0FCh 	;cout out the c1 n c0
	shl	eax, 7		;shift to 15
	or	edx, eax 	;add to edx register


	and	eax, 0
	mov	al, [esi]
	and	al, 03h		;get c1, c0
	shl	eax, 6		;shift to 5
	or	edx, eax	;add to edx register
	inc	esi
	dec 	ecx

	mov	[iLen2], ecx
	
	;;set mb, when %3 is 0, is no need; already set to '0' initially
	jmp 	Loop_cont
	
	
setMB1:
	mov	eax, 08h
	or	edx, eax
	mov	[iLen2], ecx
	jmp	Loop_cont
	
setMB2:
	mov	eax, 020h
	or	edx, eax
	mov	[iLen2], ecx
	jmp	Loop_cont
	
setMB3:
	mov	edx, 000h


Loop_cont:
	mov	eax, edx	;make a copy of value

getp4:
	and	eax, 0FFFF0000h	;zero out 16 bits
	mov	ebx, eax		;copy to ebx register
	shr	eax, 16			
	xor 	ax, bx
	xor 	al, ah
	jp	getp3			;do nothing if piraty is even
	jpo 	odd_labelP4		;jump if piraty is odd

odd_labelP4:
	mov	eax, 000010000h	;set p4 to 1
	or	edx, eax		;combine with result
	
getp3:
	mov	eax, edx	;recopy original data
	and	eax, 0FF00FF00h	; zero out
	mov	ebx, eax		; copy to ebx register
	shr	eax, 16
	xor	ax, bx
	xor	al, ah
	jp	getp2			;do nothing if piraty is even
	jpo	odd_labelP3		;jump if piraty is odd

odd_labelP3:
	mov	eax, 000000100h		;set p3 to 1
	or	edx, eax		;combine with result
	
getp2:
	mov	eax, edx	
	and	eax, 0F0F0F0F0h	;zero out
	mov	ebx, eax		; copy to ebx register
	shr	eax, 16
	xor 	ax, bx
	xor 	al, ah
	jp	getp1			;do nothing if piraty is even
	jpo 	odd_labelP2		;jump if piraty is odd

odd_labelP2:
	mov	eax, 000000010h		;set p3 to 1
	or	edx, eax		;combine with result
	
getp1:
	mov	eax, edx
	and	eax, 0CCCCCCCCh	;zero out
	mov	ebx, eax		; copy to ebx register
	shr	eax, 16
	xor 	ax, bx
	xor 	al, ah
	jp	getp0			;do nothing if piraty is even
	jpo	odd_labelP1		;jump if piraty is odd

odd_labelP1:
	mov	eax, 000000004h		;set p3 to 1
	or	edx, eax		;combine with result
	
getp0:
	mov	eax, edx
	and	eax, 0AAAAAAAAh	;zero out
	mov	ebx, eax		; copy to ebx register
	shr	eax, 16
	xor	ax, bx
	xor 	al, ah
	jp	Loop_end			;do nothing if piraty is even
	jpo 	odd_labelP0		;jump if piraty is odd

odd_labelP0:
	mov	eax, 0000000002h		;set p3 to 1
	or	edx, eax		;combine with result
	


Loop_end:	
	mov	[result], edx	;put data into stack, result

	mov	eax, SYSCALL_WRITE
	mov	ebx, STDOUT
	mov	ecx, result
	mov	edx, 4
	int	080h

	mov	ecx, [iLen2]
	mov	[iLen], ecx
	cmp	ecx, 0
	jnz	Loop_top
	int 	080h


exit:	mov	eax, SYSCALL_EXIT
	mov	ebx, 0
	int	080h
