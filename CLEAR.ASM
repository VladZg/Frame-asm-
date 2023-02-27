.model tiny
.code
locals ??
org 100h

Start:

jmp Beginning
include clrs.asm
include funcs.asm

Beginning:
	mov ax, 0B800h
	mov es, ax		; ES = B800h
	call ClrScr 		; ClearScreen()

	EXIT			; exit(0)

end Start