.model tiny
.code
locals ??
org 100h

Start:

;------------------------------------------------
jmp Beginning
include clrs.asm
include strfuncs.asm
include funcs.asm
;------------------------------------------------

;------------------------------------------------
Beginning:
	mov ax, 0B800h
	mov es, ax		; ES = B800h

	call ClrScr 		; ClearScreen() <-- clears full screen

;------------------------------------------------
; arguments: frame_type, frame_colour, filling_colour, text_colour, text
; (x_coord, y_coord, length, height,)
;------------------------------------------------

	call CheckForCmdArgs		; CheckForCmdArgs()
	cmp ax, 0d			; ax == 0
	je Set_Default_Phys_Args
	mov di, 0082h			; di = 0082h
	jmp Process_Phys_Args

Set_Default_Phys_Args:
	mov di, offset Default_Phys_Args	; di = Default_Phys_Args	

Process_Phys_Args:
	mov cx, 4d		; cx = 4
	rep push dx
	
				; mov cx, 5d		; cx = 5 <-- amount of physical args
	mov cx, 1d		; cx = 1 <-- amount of physical args

Reading_Phys_Args:		; x, y, length, height
	call GetNum		; GetNumber()
	push dx
	inc di			; di++
	loop Reading_Phys_Args
	
	mov cx, 3d		; cx = 3 <-- amount of colour args

Reading_Clr_Args:	
	call Hton		; HexToNumber() <-- gets colour attr of the frame, filling and symbols
	push ax
	add di, 3d		; di += 3
	loop Reading_Clr_Args	

	push di			; <-- address of msg
	mov si, sp		; si = sp

;-------------------
;Defining frame type
;-------------------
	mov bl, 9d				; bl = 9
	mov al, [si+8]				; frame type
	mul bl					; ax *= bl
	mov di, offset Default_Frm_Symb_Attr	; di = Line_Symb_Attr 
	add di, ax				; di += ax
	mov word ptr [si+8], di			; [si+8] = di

;---------------
;Forming message
;---------------
	call CheckForCmdArgs	; CheckForCmdArgs()
	cmp ax, 0d		; ax == 0
	je Correcting_Frm_Attrs	; <-- if there is no cmd args
	mov bx, 0080h		; bx = 0080h		
	xor ax, ax		; ax = 0
	mov al, [bx]		; al = [bx]
	mov bx, 0081h		; bx = 81h
	add bx, ax		; bx += ax
	mov byte ptr [bx], "$"	; [bx] = $ <-- end of the message

Correcting_Frm_Attrs:

;-----------------------
;Defining frame's height
;-----------------------
	mov di, [si]		; message start
	mov ah, STRSPLIT_SYMBOL ; ah = "\"
	call CntStrSymb		; CountStringSymbol() <-- cx = amount of strings in message - 1
	inc cx			; cx++
	push cx			; [si-2] <-- amount of strings
	add cx, 4d		; cx += 4 <-- new frame's height
	mov [si+10], cl		; [si+10] = cl

;-----------------------
;Defining frame's length
;-----------------------
	mov di, [si]		; message start
	call CntStrMaxLen	; CountStringMaxLength() <-- cl = max width of message lines
	mov [si-1], cl		; [si+1] <-- width of text
	add cl, 4d		; cl += 4 <-- new frame's length
	mov [si+12], cl		; [si+12] = cl

;----------------
;X-centring frame
;----------------
	mov bh, [si+12]		; length
	mov dh, 80d		; al = 80
	sub dh, bh 		; al -= bh
	shr dh, 1		; al /= 2
	inc dh			; dh++
	mov [si+16], dh		; x coord = dh

;----------------
;Y-Centring frame
;----------------
	mov bl, [si+10]		; height
	mov dl, 27d		; al = 27
	sub dl, bl 		; al -= bl
	shr dl, 1		; al /= 2
	inc dl			; dl++
	mov [si+14], dl		; y coord = dl

Drawing:
	call ClrScr		; <-- clears screen

;-------------
;Drawing_Frame
;-------------
	mov word ptr di, [si+8]	; frame type
	mov bh, [si+12]		; length
	mov bl, [si+10]		; height
	mov dl, [si+14]		; y coord
	mov dh, [si+16]		; x coord
	mov ah,	[si+6]		; colour of frame
	mov al, [si+4]		; colour of center

	call DrwFrm 		; DrawFrame() <-- draws frame

;---------------
;Writing message
;---------------
	mov di, [si]		; message start
	mov dl, [si+14]		; y coord
	mov cl, [si+10]		; height
	sub cl, [si-2]		; 
	shr cl, 1		; cl = (height - amount of str)/2
	add dl, cl		; dl += cl <-- text y-centring	
	mov dh, [si+16]		; x coord
	mov cl, [si+12]		; length
	sub cl, [si-1]		; 
	shr cl, 1		; cl = (length - width of txt)/2
	add dh, cl		; dl += cl <-- text x-centring	
	mov ah, [si+2]		; colour of text
	call Printf		; Printf() <- prints message

;------
;Moving
;------
;	mov ah, 86h		;
;	mov cx, 001Eh		;
;	mov dx, 8480h		;
;	int 15h			; sleep(2s)
; 
;	mov byte ptr cl, [si+14]
;	dec cl
;	mov byte ptr [si+14], cl
;	cmp cl, 3d
;	jae Drawing

Type_Cmd:
	mov ah, 10h		; ah = 10h
	int 16h			; reading one key symbol

	cmp ah, 1Ch		; <Enter>
	je Exit_Programm_1

Move_Up:
	cmp ah, 11h			; <up>
	jne Move_Down
	mov cl, [si+14]			; y coord
	dec cl				; cl--
	mov [si+14], cl			; [si+14] = cl
	cmp cl, 3d			; cl >= 3
	jae Drawing_1
	inc cl				; cl++
	mov [si+14], cl			; [si+14] = cl
	jmp Type_Cmd				

Move_Down:
	cmp ah, 1Fh			; <down>
	jne Move_Left
	mov cl, [si+14]			; y coord
	inc cl				; cl++
	mov [si+14], cl			; [si+14] = cl
	add cl, [si+10]			; cl += [si+10]
	cmp cl, 26d			; cl <= 26
	jbe Drawing_1
	mov cl, [si+14]			; cl = [si+14]
	dec cl				; cl--
	mov [si+14], cl			; [si+14] = cl
	jmp Type_Cmd			

Move_Left:
	cmp ah, 1Eh			; <left>
	jne Move_Right
	mov byte ptr cl, [si+16]	; x coord
	dec cl				; cl--
	mov byte ptr [si+16], cl	; [si+16] = cl
	cmp cl, 1d			; cl >= 1
	jae Drawing_1	
	inc cl				; cl++
	mov byte ptr [si+16], cl	; [si+16] = cl
	jmp Type_Cmd			

Move_Right:
	cmp ah, 20h			; <right>
	jne Zoom_Plus			; if key is wrong
	mov byte ptr cl, [si+16]	; x coord
	inc cl				; cl++
	mov byte ptr [si+16], cl	; [si+16] = cl
	add byte ptr cl, [si+12]	; cl += [si+12]
	cmp cl, 81d			; cl <= 81
	jbe Drawing_1
	mov cl, [si+16]			; cl = [si+16]
	dec cl				; cl--
	mov byte ptr [si+16], cl	; [si+16] = cl
	jmp Type_Cmd			

;------------------
jmp After_Exit_Programm_1
Drawing_1:
	jmp Drawing
Type_Cmd_1:
	jmp Type_Cmd
Exit_Programm_1:
	jmp Exit_Programm
After_Exit_Programm_1:
;------------------

Zoom_Plus:
	cmp ah, 0Dh				; <+>
	jne Zoom_Minus
	sub byte ptr [si+16], 2d		; x coord
	dec byte ptr [si+14]			; y coord
;	mov bh, [si+12]				; length
;	mov bl, [si+10]				; height
	add byte ptr [si+12], 4d		; length
	add byte ptr [si+10], 2d		; height
	jmp Drawing_1
;Plus_Check_For_X_Fit:
;	cmp byte ptr [si+12], 80d		; bh <= 80
;	jbe Plus_Check_For_Y_Fit
;	mov [si+12], bh
;Plus_Check_For_Y_Fit:
;	cmp byte ptr [si+10], 23d		; bl <= 23
;	jbe Drawing_1
;	mov [si+12], bh
;	jmp Type_Cmd_1

Zoom_Minus:
	cmp ah, 0Ch				; <->
	jne Type_Cmd_1
	add byte ptr [si+16], 2d		; x coord
	inc byte ptr [si+14]			; y coord
;	mov bh, [si+12]				; length
;	mov bl, [si+10]				; height
	sub byte ptr [si+12], 4d		; length
	sub byte ptr [si+10], 2d		; height
	jmp Drawing_1
;Minus_Check_For_X_Fit:
;	cmp byte ptr [si+12], 80d		; bh <= 80
;	jbe Minus_Check_For_Y_Fit
;	mov [si+12], bh
;Minus_Check_For_Y_Fit:
;	cmp byte ptr [si+10], 23d		; bl <= 23
;	jbe Drawing_1
;	mov [si+12], bh
;	jmp Type_Cmd_1

Exit_Programm:
	pop dx			; params of text
	mov cx, 9d		; cx = 9 <-- whole number of args
	rep pop dx		; for (int i = cx; i > 0; i--) {pop dx}

	EXIT	; exit(0)
;------------------------------------------------

;------------------------------------------------
Default_Len_Of_Args	db	39d
Default_Phys_Args:	db	"0 "					; "24 ", "13 ", "33 ", "5 ", 
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