;------------------------------------------------
;Counts string length before stopping symbol
;------------------------------------------------
;Entry:		AH = stop-symbol of the string
;		SI = address of the string
;Exit:		CX = length (without ENDL_SYMBOL)
;		BX = address of the symbol after the stop-symbol
;Expects:	string contains stop-symbol
;Destroys:	AL BX CX
;------------------------------------------------
StrLenS	proc
	push si
	xor cx, cx			; cx = 0
	
??Next_Symbol:
	lodsb				; al = [si++]
	cmp al, ah			; al == ah
	je ??Exit_Function
	inc cx				; cx++
	jmp ??Next_Symbol		

??Exit_Function:
	mov bx, si
	pop si
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Counts a number of givven symbols in given str
;------------------------------------------------
;Entry:		AH = code of the symbol we search
;		DI = address of string ends with ENDL_SYMBOL
;Exit:		CX = number of repeats
;Expects:	None
;Destroys:	AL CX
;------------------------------------------------
CntStrSymb	proc
	push si
	xor cx, cx
	mov si, di

??Next_Symbol:
	lodsb				; al = [si++]
	cmp al, ENDL_SYMBOL		; al == ENDL_SYMBOL
	je ??Exit_Function
	cmp al, ah			; al != ah
	jne ??Next_Symbol
	inc cx				; cx++
	jmp ??Next_Symbol	

??Exit_Function:
	pop si
	ret
	endp
;------------------------------------------------

;---------------------------------------------------
;Counts a length of the longest line from the string
;---------------------------------------------------
;Entry:		DI = address of string ends with ENDL_SYMBOL
;Exit:		CL = length of the longest line
;Expects:	lines are splitted by STRSPLIT_SYMBOL
;Destroys:	AL CX
;------------------------------------------------
CntStrMaxLen	proc
	push si
	xor cx, cx
	mov si, di

??Next_Symbol:
	lodsb				; al = [si++]
	cmp al, ENDL_SYMBOL		; al == ENDL_SYMBOL
	je ??Prepare_Out
	cmp al, SEP_SYMBOL		; al == SEP_SYMBOL
	je ??Skip_ClrChng_Symbols
	inc cl				; cl++
	cmp al, STRSPLIT_SYMBOL			; al != STRSPLIT_SYMBOL
	jne ??Next_Symbol
	dec cl				; cl--
	cmp cl, ch			; cl > ch
	ja ??Set_New_Max
	xor cl, cl			; cl = 0
	jmp ??Next_Symbol

??Skip_ClrChng_Symbols:
	add si, 2d			; si += 3
	jmp ??Next_Symbol	

??Set_New_Max:
	mov ch, cl			; ch = cl
	xor cl, cl
	jmp ??Next_Symbol	

??Prepare_Out:
	cmp cl, ch			; cl > ch
	jae ??Exit_Function
	mov cl, ch

??Exit_Function:
	pop si
	ret
	endp
;------------------------------------------------