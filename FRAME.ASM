.model tiny
.code
locals ??
org 100h

Start:

;------------------------------------------------
jmp Beggining
include clrs.asm
include funcs.asm
;------------------------------------------------

;------------------------------------------------
Beggining:
	mov ax, 0B800h
	mov es, ax		; ES = B800h

	call ClrScr 		; ClearScreen() <-- clears full screen

	push bp
	mov bp, sp		; bp = sp

	call CheckForCmdArgs		; CheckForCmdArgs()
	cmp ax, 0d			; ax == 0
	je Set_Default_Phys_Args
	mov di, 0082h			; di = 0082h
	jmp Process_Phys_Args

Set_Default_Phys_Args:
	mov di, offset Default_Phys_Args	; di = Default_Phys_Args	

Process_Phys_Args:
	mov cx, 5d				; cx = 5 <-- amount of physical args

;	mov si, offset Default_Phys_Args	; si = Default_Args

Reading_Phys_Args:		; x, y, length, height
	call GetNum		; GetNumber()

;	cmp bx, 0d		; bx == 0
;	ja Phys_Arg_Typed
;	mov bx, cx		; bx = cx
;	sub bx, 5d		; bx -= 5
;	shl bx, 1d		; bx *= 2
;	add bx, si		; bx += si
;	mov dx, [bx]		; dx = default argument (i)
;Phys_Arg_Typed:		; if argument was typed 

	push dx
	inc di			; di++
	loop Reading_Phys_Args
	
	mov cx, 3d		; cx = 3 <-- amount of colour args

Reading_Clr_Args:	
	call Hton		; HexToNumber() <-- gets colour attr of the frame, filling and symbols
	push ax
	add di, 3d		; di += 3
	loop Reading_Clr_Args	

	push di
	mov si, sp			; si = sp

;-------------
;Drawing_Frame
;-------------
	mov bl, 9d				; bl = 9
	mov al, [si+8]				; frame type
	mul bl					; ax *= bl
	mov di, offset Default_Frm_Symb_Attr	; di = Line_Symb_Attr 
	add di, ax				; di += ax
		
	mov bh, [si+12]			; length
	mov bl, [si+10]			; height

	;mov dl, [si+16]
	;mov dh, [si+14]

;----------------
;X_Centring_Frame
;----------------
	mov dh, 80d		; al = 80
	sub dh, bh 		; al -= bh
	shr dh, 1		; al /= 2
	inc dh			; dh++
	mov [si+16], dh		; x coord = dh

;----------------
;Y_Centring_Frame
;----------------
	mov dl, 27d		; al = 27
	sub dl, bl 		; al -= bl
	shr dl, 1		; al /= 2
	inc dl			; dl++
	mov [si+14], dl		; y coord = dl

	mov ah,	[si+6]		; colour of frame
	mov al, [si+4]		; colour of center

	call DrwFrm 		; DrawFrame() <-- draws frame

;---------------
;Writing message
;---------------
	call CheckForCmdArgs	; CheckForCmdArgs()
	cmp ax, 0d		; ax == 0
	je Process_Msg
	mov bx, 0080h		; bx = 0080h		
	xor ax, ax		; ax = 0
	mov al, [bx]		; al = [bx]
	mov bx, 0081h		; bx = 81h
	add bx, ax		; bx += ax
	mov byte ptr [bx], "$"	; [bx] = $ <-- end of the message

Process_Msg:
	mov di, [si]		; message start
	mov dh, 34d		; x coord of up left point
	mov dl, 12d		; y coord of up left point
	mov dl, [si+14]		; y coord
	add dl, 2d		; dl += 2	
	mov dh, [si+16]		; x coord
	add dh, 2d		; dh += 2
	mov ah, [si+2]		; colour of text
	call Printf		; Printf() <- prints message

	mov cx, 9d		; cx = 9 <-- whole number of args
	rep pop dx		; for (int i = cx; i > 0; i--) {pop dx}

	pop bp

	EXIT	; exit(0)
;------------------------------------------------

;------------------------------------------------
Default_Len_Of_Args	db	39d
Default_Phys_Args:	db	"24 ", "13 ", "33 ", "5 ", "0 "
Default_Clr_Args:	db	"40 ", "00 ", "40 "
Default_Message:	db	"DEFAULT MESSAGE: NO ARGUMENTS", "$"

Default_Frm_Symb_Attr:	db	LEFT_UP_BRACKET, UP_BRACKET, RIGHT_UP_BRACKET, LEFT_BRACKET, BOX_PATTERN, RIGHT_BRACKET, LEFT_BOTTOM_BRACKET, BOTTOM_BRACKET, RIGHT_BOTTOM_BRACKET
First_Frm_Symb_Attr:	db	HEART_SYMBOL, HEART_SYMBOL, HEART_SYMBOL, HEART_SYMBOL, BOX_PATTERN, HEART_SYMBOL, HEART_SYMBOL, HEART_SYMBOL, HEART_SYMBOL
Second_Frm_Symb_Attr:	db	DOG_SYMBOL, DOG_SYMBOL, DOG_SYMBOL, DOG_SYMBOL, BOX_PATTERN, DOG_SYMBOL, DOG_SYMBOL, DOG_SYMBOL, DOG_SYMBOL
Third_Frm_Symb_Attr:	db	DOLLAR_SYMBOL, DOLLAR_SYMBOL, DOLLAR_SYMBOL, DOLLAR_SYMBOL, BOX_PATTERN, DOLLAR_SYMBOL, DOLLAR_SYMBOL, DOLLAR_SYMBOL, DOLLAR_SYMBOL
Forth_Frm_Symb_Attr:	db	POINT_SYMBOL, UP_BRACKET, POINT_SYMBOL, LEFT_BRACKET, BOX_PATTERN, RIGHT_BRACKET, POINT_SYMBOL, BOTTOM_BRACKET, POINT_SYMBOL
Fifth_Frm_Symb_Attr:	db	"abcd efgh"
Clr_Frm_Symb_Attr:	db	BOX_PATTERN, BOX_PATTERN, BOX_PATTERN, BOX_PATTERN, BOX_PATTERN, BOX_PATTERN, BOX_PATTERN, BOX_PATTERN, BOX_PATTERN
;------------------------------------------------

end Start