;------------------------------------------------
VIDEOMEM_SEG		equ	0B800h
;------------------------------------------------

;------------------------------------------------
;Exits DOS
;------------------------------------------------
;Entry:		None
;Exit:		Not defined
;Expects:	None
;Destroys:	None
;------------------------------------------------
EXIT	macro
	mov ax, 4c00h
	int 21h
	endm
;------------------------------------------------

;------------------------------------------------
;Draws 1 cell
;------------------------------------------------
;Entry:		AH = color attribute
;		AL = filling symbol
;		BX = address in videosegment
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	None
;------------------------------------------------
DrwCll	proc
	mov es:[bx], ax
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Counts the effective address of the cell
;------------------------------------------------
;Entry:		DH = x coordinate (0 - 80) of start
;		DL = y coordinate (0 - 25) of start
;Exit:		BX = address of the cell in videosegment
;Expects:	None
;Destroys:	AX BX DX
;------------------------------------------------
CntAddr proc
	xor bx, bx		; bx = 0
	mov al, 80d		; al = 80
	dec dl			; dl--
	mul dl			; ax = al * dl		
	mov dl, dh		; dl = dh
	xor dh, dh		; dh = 0
	dec dl			; dl--
	add ax, dx		; ax += dx
	shl ax, 1		; ax *= 2
	mov bx, ax		; bx = ax
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Clears the rectangle with symbols
;------------------------------------------------
;Entry:		AH = color attribute
;		AL = filling symbol
;		BH = length
;		BL = width
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	BX CX
;------------------------------------------------
DrwRect	proc
	push ax
	push bx

	mov al, bh		
	mul bl			; ax = al * bl
	mov cx, ax		; cx = ax - area

	call CntAddr		; CountAddress() <-- bx = address of the first cell
	
	pop dx			; dh = length, dl = width
	pop ax			; ax = symbol + colour attribute

	mov dh, dl		; dh = dl
	xor dl, dl		; dl = 0	

??Horizontal_Next:
	call DrwCll		; DrawCell()
	add bx, 2		; bx += 2
	inc dl			; dl++
	cmp dl, dh		; dl == dh
	je ??Vertical_Next
	loop ??Horizontal_Next

??Vertical_Next:
	dec cx			; cx--
	add bx, 80d * 2d	; 
	shl dl, 1		; 
	push dx			;
	xor dh, dh		; dh = 0
	sub bx, dx		; bx += 80*2 - width*2 <-- shift to the next string
	pop dx			;
	xor dl, dl		; dl = 0
	cmp cx, 0		; cx == 0
	ja ??Horizontal_Next 

	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Clears the full screen with black
;------------------------------------------------
;Entry:		None
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	AX BX CX DX
;------------------------------------------------
ClrScr	proc
	mov ah,	BLACK_ON_BLACK  ; black colour set
	mov al, BOX_PATTERN	; box pattern set
	mov dh, 1d		; x coord of up left point
	mov dl, 1d		; y coord of up left point
	mov bh, 25d		; full screen length
	mov bl, 80d		; full screen width
	call DrwRect		; DrawRectangle()
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Draws the line
;------------------------------------------------
;Entry:		AL = symbol attribute
;		AH = color attribute
;		BH = length
;		BL = horizontal (0), vertical (1)
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;Exit:		BX = address of the cell next to the last cell of the line
;Expects:	ES = 0B800h
;Destroys:	BX CX
;------------------------------------------------
DrwLine	proc
	push ax
	push bx

	call CntAddr	; CountAddress()
	
	pop dx		; dh = length, dl = flag
	pop ax		; symbol + colour

	mov cl, dh	; cl = dh

	cmp dl, 00h
	je ??Drw_Horizontal_Line
	cmp dl, 0FFh
	je ??Drw_Vertical_Line
	jmp ??End_Drawing_Line

??Drw_Horizontal_Line:
	call DrwCll			; DrawCell()
	add bx, 2			; bx += 2 <-- next cell
	loop ??Drw_Horizontal_Line
	jmp ??End_Drawing_Line

??Drw_Vertical_Line:
	call DrwCll			; DrawCell()
	add bx, 160d			; bx += 160 <-- next string	
	loop ??Drw_Vertical_Line

??End_Drawing_Line:
	ret
	endp	
;------------------------------------------------

;------------------------------------------------
;Draws the advanced horizontal line |L|M|M|M|M|R|
;------------------------------------------------
;Entry:		AH = bracket color attribute
;		AL = filling color attribute
;		BH = length
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;		DI = address of the array with 3 symbols (L, M, R)
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	None
;------------------------------------------------
DrwAdvLine	proc
	cmp bh, 3d		; bh < 3
	jb ??Exit_Function

	push ax
	push bx
	push cx
	push dx
	push di

	push bx
	push dx
	push ax

	call CntAddr	; CountAddress()
	pop ax
	push ax
	mov al, [di]
	call DrwCll	; DrawCell() <-- draws the left symbol

	pop ax
	pop dx
	inc dh		; dh++
	pop bx
	sub bh, 2	; bh -= 2
	xor bl, bl	; bl = 0
	inc di		; di++
	push ax
	mov ah, al	; ah = al
	mov al, [di]	; al = [di]
	call DrwLine	; DrawLine() <-- draws the middle line

	pop ax
	inc di		; di++
	mov al, [di]	; al = [di]
	call DrwCll	; DrawCell() <-- draws the right symbol
	add bx, 2d	; bx += 2

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

??Exit_Function:
	ret
	endp	
;------------------------------------------------

;------------------------------------------------
;Draws the frame
;------------------------------------------------
;Entry:		AH = brackets color attribute
;		AL = filling color attribute
;		BH = length
;		BL = height
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;		DI = address of the array with 9 symbols of frame
;Exit:		BX = address of the cell next to the last cell of the line
;Expects:	ES = 0B800h
;Destroys:	AX BX CX DX DI
;------------------------------------------------
DrwFrm	proc
	cmp bh, 3d		; bh < 3
	jb ??Exit_Function
	cmp bl, 3d		; bl < 3
	jb ??Exit_Function

	push ax
	mov al, ah
??Drw_First_String:
	call DrwAdvLine		; DrawAdvancedLine() <-- draws the first string
	
	add di, 3		; di += 3
	xor cx, cx		; cx = 0
	mov cl, bl		; cl = bl
	sub cl, 2d		; cl -= 2
	
	pop ax
??Drw_Middle_Strings:
	inc dl			; dl++
	call DrwAdvLine		; DrawAdvancedLine() <-- draws the middle string
	loop ??Drw_Middle_Strings	

	inc dl			; dl++
	add di, 3d		; di += 3
	
	mov al, ah
??Drw_Last_String:
	call DrwAdvLine		; DrawAdvancedLine() <-- draws the last string

??Exit_Function:
	ret
	endp	
;------------------------------------------------

;------------------------------------------------
;Check if there arguments of cmd
;------------------------------------------------
;Entry:		None
;Exit:		AX = is there arguments flag (1 - True, 0 - False)
;Expects:	None
;Destroys:	AX
;------------------------------------------------
CheckForCmdArgs	proc
	push di
	xor ax, ax		; ax = 0
	mov di, 0080h		; di = 80h
	cmp byte ptr [di], 1d		; [di] <= 1
	jbe ??Exit_Function
	mov al, 1d		; al = 1

??Exit_Function:	
	pop di
	ret
	endp

;------------------------------------------------

;------------------------------------------------
;Gets a number from the string until not a number symbol
;------------------------------------------------
;Entry:		DI = address of string with a num
;Exit:		DX = value of a number
;		BX = shift from the beginning of the string to the stop symbol
;Expects:	None
;Destroys:	AX BX DI
;------------------------------------------------
GetNum	proc
	xor dx, dx
	mov bx, di		; bx = di
	push cx
	push bx

??Next_Symbol:	
	mov ah, [bx]
	cmp ah, "0"		; ah < 2 ('1')
	jb ??Exit_Function
	cmp ah, "9"		; ah > 11 ('0')
	ja ??Exit_Function

	mov al, ah		; al = ah
	xor ah, ah		; ah = 0

	cmp ax, "0"		; ax != "0"
	jne ??Not_Zero		;

??Zero:
	xor cx, cx		; cx = 0
	jmp ??Process_Number

??Not_Zero:
	mov cx, ax		; cx = ax
	sub cx, "0"

??Process_Number:
	push bx			
	mov ax, dx		; ax = dx
	mov bx, 10d		; bx = 10
	mul bx			; ax *= bx
	add ax, cx		; ax += cx
	mov dx, ax
	pop bx
	inc bx
	inc di
	jmp ??Next_Symbol

??Exit_Function:
	mov ax, bx		; ax = bx
	pop bx
	sub ax, bx		; ax -= bx
	mov bx, ax		; bx = ax
	pop cx

	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Translates hex num into number
;------------------------------------------------
;Entry:		DI = beginning adress of hex num
;Exit:		AX = translated number
;Expects:	None
;Destroys:	AX
;------------------------------------------------
Hton	proc
	push di
	push cx
	push bx
	mov cx, 4d		; cx = 4

??Next_Symbol:
	mov bx, bx		; bx = 0
	mov bl, [di]		; bl = [di]

??Check_For_Hex_Num:
	cmp bl, "0"		
	jb ??Check_For_Hex_Symb ; bl < "0"
	cmp bl, "9"		
	ja ??Check_For_Hex_Symb ; bl > "9"
	jmp ??Translate_Num

??Check_For_Hex_Symb:
	cmp bl, "A"		
	jb ??Exit_Function	; bl < "A"
	cmp bl, "F"
	ja ??Exit_Function	; bl > "F"
	jmp ??Translate_Ltr

??Translate_Num:
	sub bl, 48d		; num symb --> num
	jmp ??Process_Num

??Translate_Ltr:
	sub bl, 55d		; ltr symb -> num

??Process_Num:
	shl ax, 4		; ax *= 16
	add ax, bx		; ax += bx
	inc di			; di++
	loop ??Next_Symbol

??Exit_Function:	
	pop bx
	pop cx
	pop di
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Printf without args
;------------------------------------------------
;Entry:		AH = colour attribute
;		DH = x coordinate (0 - 80) of start
;		DL = y coordinate (0 - 25) of start
;		DI = address of fmt string ends with '$'
;Exit:		DI = length of out string
;Expects:	ES = 0B800h
;Destroys:	BX
;------------------------------------------------
Printf	proc
	push si
	push dx
	push ax
	push dx
	call CntAddr	; CountAddress()
	pop dx
	mov si, di	; si = di
	xor di, di	; di = 0		
	pop ax

??Text_Printf:		
	lodsb					; al = [si++]
	cmp al, ENDL_SYMBOL			; al == "$" symbol of the end 
	je ??Exit_Printf
	cmp al, SEP_SYMBOL			; al == "&" symbol of chng colour attr
	je ??Change_Clr
	cmp al, STRSPLIT_SYMBOL 		; al == "\" symbol of the split str
	jne ??Printf_Ltr

??Split_Str:
	push ax
	inc dl			; dl++
	push dx 
	call CntAddr		; CountAddress() <-- adress of the first symbol of the next str
	pop dx
	pop ax
	jmp ??Text_Printf

??Change_Clr:
	push ax
	push di
	mov di, si				; di = si
	call Hton				; HexToNumber()
	pop di
	mov cx, ax				; cx = ax
	pop ax
	mov ah, cl				; ah = cl <-- changing colour attribute
	add si, 2d				; si += 2
	jmp ??Text_Printf			; write next symbol of fmt string
		
??Printf_Ltr:
	inc di					; di++
	call DrwCll				; DrawCell()
	
	add bx, 2				; bx += 2
	jmp ??Text_Printf			; write next symbol of fmt string

??Exit_Printf:
	mov cx, dx	; cx = dx
	pop dx
	sub cx, dx	; cx -= dx
	pop si

	ret
	endp
;------------------------------------------------

;------------------------------------------------
ARG_TXT_CLR		equ	WHITE_ON_RED
FMT_TXT_CLR		equ	WHITE_ON_BLACK
;------------------------------------------------
;------------------------------------------------
;Printf with cmd args
;------------------------------------------------
;Entry:		DH = x coordinate (0 - 80) of start
;		DL = y coordinate (0 - 25) of start
;		DI = address of fmt string ends with ENDL_SYMBOL
;Exit:		DI = length of out string
;Expects:	ES = 0B800h
;		SI = 0080h (beggining of cmd)
;Destroys:	BX CX SI
;------------------------------------------------
CmdPrintf	proc
	call CntAddr				; CountAddress()

	mov si, di
	xor di, di

??Fmt_Text_Printf:		
	lodsb					; al = [si++]
	cmp al, ENDL_SYMBOL			; al == "$"
	je ??Cnt_Arg_Length
	cmp al, SEP_SYMBOL			; al != "<" symbol of chng colour attr
	jne ??Printf_Ltr
	push ax
	push di
	mov di, si				; di = si
	call Hton				; HexToNumber()
	pop di
	mov cx, ax				; cx = ax
	pop ax
	mov ah, cl				; ah = cl <-- changing colour attribute
	add si, 2d				; si += 2
	jmp ??Fmt_Text_Printf			; write next symbol of fmt string
		
??Printf_Ltr:
	inc di					; di++
	mov ah, FMT_TXT_CLR   	 		; white on black
	call DrwCll				; DrawCell()
	
	add bx, 2				; bx += 2
	jmp ??Fmt_Text_Printf			; write next symbol of fmt string

??Cnt_Arg_Length:
	mov si, 0080h 				; si = 80h
	lodsb					; al = [si++]
	xor cx, cx				; cx = 0 
	mov cl, al				; cl = al
	cmp cl, 0				; cl == 0
	je ??CmdPrintf_Exit
	sub cl, 1
	inc si
	
??Arg_Text_Printf:
	lodsb					; al = [si++]
	
	mov ah, ARG_TXT_CLR			; white on black
	call DrwCll				; DrawCell()

	inc di
	add bx, 2				; bx += 2
	loop ??Arg_Text_Printf			; write next symbol of argument

??CmdPrintf_Exit:
	ret
	endp
;------------------------------------------------