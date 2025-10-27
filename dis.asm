.model small
.stack 100h

.data
	errorMsg db "Netinkama Ivestis$"
	inputOK  db "Input File Opened correctly!$"
	outputOK db "Output File Created correctly!$"
	inputNOTOK db "Error Opening Input File!$"
	outputNOTOK db "Error Creating Output File!$"
	space db " $"
	newlineNotFile db 10, 13, "$"
	newline db 13, "$"
	inputFileName db 64 dup (0)
	inputFileHandle dw ?
	inputFileSize dw ?
	
	outputFileName db 64 dup(0)
	outputFileHandle dw ?
	
	inputBuffer db 32768 dup(0)
	neatpazinta db "NEATPAZINTA$"
	
	tempChar db 0
	
	REG8_NAMES db 'ALCLDLBLAHCHDHBH'
	REG16_NAMES db 'AXCXDXBXSPBPSIDI'
	
	rm_bx_si db '[BX+SI$'
	rm_bx_di db '[BX+DI$'
	rm_bp_si db '[BP+SI$'
	rm_bp_di db '[BP+DI$'
	rm_si    db '[SI$'
	rm_di    db '[DI$'
	rm_bp    db '[BP$'
	rm_bx    db '[BX$'
	
	AddrModeTable dw rm_bx_si, rm_bx_di, rm_bp_si, rm_bp_di, rm_si, rm_di, rm_bp, rm_bx
	
	wFlag db ?
	
	SegmentPrefix db 0
	SegmentES db 'ES:', '$'
	SegmentCS db 'CS:', '$'
	SegmentSS db 'SS:', '$'
	SegmentDS db 'DS:', '$'

	
	mov10 db "AL, $"
	mov11 db "AX, $"
	mov20 db ", AL$"
	mov21 db ", AX$"
	w_0 db "8 bits$"
	w_1 db "16 bits$"
	
.code
start:
	
	mov ax, @data
	mov ds, ax
	
	xor si, si
	xor ch, ch
	mov cl, es:[80h]
	cmp cl, 0
	je 	klaida
	mov di, offset inputFileName
loop_skip_space:
	cmp si, cx
	je  klaida
	mov al, es:[81h + si]
	cmp al, ' '
	jne inputNameLoop
	inc si
	jmp loop_skip_space
	
inputNameLoop:
	
	cmp si, cx
	je klaida
	mov al, es:[81h + si]
	cmp al, ' '
	je inputFileEnd
	mov [di], al
	inc di
	inc si
	jmp inputNameLoop

inputFileEnd:
	
	mov di, offset outputFileName

loop_skip_space2:
	cmp si, cx
	je klaida
	mov al, es:[81h + si]
	cmp al, ' '
	jne outputNameLoop
	inc si
	jmp loop_skip_space2
klaida:
	mov ah, 9
	mov dx, offset errorMsg
	int 21h
	
	mov ah, 4Ch
	int 21h
outputNameLoop:
	cmp si, cx
	je outputFileEnd
	mov al, es:[81h + si]
	cmp al, ' '
	je outputFileEnd
	cmp al, 13
	je outputFileEnd
	mov [di], al
	inc di
	inc si
	jmp outputNameLoop
	
outputFileEnd:
	;****************** Failu atidarymai ********************
	; open input file
	mov ah, 3Dh
	mov al, 00
	mov dx, offset inputFileName
	int 21h
	jc inputErr
	mov [inputFileHandle], ax
	;OkMsg
	mov ah, 9
	mov dx, offset inputOK
	int 21h
	mov dx, offset newlineNotFile
	int 21h
	; create output file
	mov ah, 3Ch
	mov cx, 0
	mov dx, offset outputFileName
	int 21h
	jc outputErr
	mov [outputFileHandle], ax
	;OkMsg
	mov ah, 9
	mov dx, offset outputOK
	int 21h
	mov dx, offset newlineNotFile
	int 21h
	;****************** Failu atidarymo pabaiga *******************
	
	
	;****************** Nuskaitymas is failo i bufferi ************
	
	CALL Skaitymas
	
	;****************** Nuskaitymo pabaiga ************************


	
	;****************** Instrukciju atpazinimas *******************
	xor di, di
	;mov di, offset inputBuffer
loop_check_OPK:
	cmp di, [inputFileSize]
	jae print_output
	CALL detectPrefix
	CALL checkMOV
	
	
	;mov dx, offset neatpazinta
	;CALL PRINTS
	;mov dx, offset newline
	;CALL PRINTS
	;inc di
	jmp loop_check_OPK
	
print_output:
	; BUS PRINT I FAILA
	
	; tada end program
	mov ah, 4Ch
	int 21h
inputErr:
	mov ah, 9
	mov dx, offset inputNOTOK
	int 21h
	
	mov ah, 4Ch
	int 21h
outputErr:
	mov ah, 9
	mov dx, offset outputNOTOK
	int 21h
	
	mov ah, 4Ch
	int 21h

Skaitymas PROC
	mov ah, 3Fh
	mov bx, [inputFileHandle]
	mov cx, 32768
	mov dx, offset inputBuffer
	int 21h
	mov [inputFileSize], ax
	RET
Skaitymas ENDP
PRINT PROC
	push ax
	push bx
	push cx
	push dx
	push ds
		
	mov ah, 40h                    ; DOS write to file
    mov bx, [outputFileHandle]     ; BX = file handle
    mov cx, 1                      ; one byte
    mov al, dl
	mov [tempChar], al
    mov dx, offset tempChar             ; pointer to a memory byte
    int 21h
	
	pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT ENDP
PRINTS PROC
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov bx, [outputFileHandle]
	mov si, dx
	
writeLoop:
	mov al, [si]
	cmp al, '$'
	je writeLoopEnd
	mov dl, al
	CALL PRINT
	inc si
	jmp writeLoop
writeLoopEnd:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	RET
PRINTS ENDP
toHexPrint PROC
	mov dh, dl
	and dl, 0Fh
	shr dh, 4
	cmp dh, 9
	jbe HighSkaitmuo
	add dh, 'A' - 10
	jmp HighDone
HighSkaitmuo:
	add dh, '0'
HighDone:
	cmp dl, 9
	jbe LowSkaitmuo
	add dl, 'A' - 10
	jmp LowDone
LowSkaitmuo:
	add dl, '0'
LowDone:
	push dx
	mov dl, dh
	CALL PRINT
	pop dx
	CALL PRINT
	RET
toHexPrint ENDP
decodeModRM PROC
	; AL = ModR/M byte
	; ah = mod, cl = reg, bl = r/m
	mov ah, al
	and ah, 11000000b
	shr ah, 6 	; ah = 2 pirmi al baitai
	
	mov cl, al
	and cl, 00111000b ; cl = reg
	shr cl, 3
	
	mov bl, al
	and bl, 00000111b ; bl = r/m
	
	RET
decodeModRM ENDP
decodeREG PROC
	push ax
	push bx
	push dx
	
	mov dx, cx
	shl dx, 1
	mov bx, dx
	
	cmp al, 0
	je use8
	mov si, offset REG16_NAMES
	jmp gotTable
use8:
	mov si, offset REG8_NAMES
gotTable:	
	add si, bx
	
	mov dl, [si]
	CALL PRINT
	mov dl, [si+1]
	CALL PRINT
	
	pop dx
	pop bx
	pop ax
	RET
decodeREG ENDP
decodeRM PROC
	push ax
	push bx
	push dx
	
	mov [wFlag], al
	
	cmp ah, 11b
	je rmMod11
	cmp ah, 00b
	je rmMod00
	cmp ah, 01b
	jne rmMod01skip
	jmp rmMod01
rmMod01skip:
	cmp ah, 10b
	jne rmMod10skip
	jmp rmMod10
rmMod10skip:
	jmp rmEnd
;------------------------------
rmMod11:
	mov al, [wFlag]
	cmp al, 0
	je rm_8
	jmp rm_16
rm_8:
	CALL PrintSegmentPrefix
	shl bx, 1
	mov dl, [REG8_NAMES + bx]
	call PRINT
	mov dl, [REG8_NAMES + bx + 1]
	call PRINT
	add di, 1
	jmp rmEnd
rm_16:
	CALL PrintSegmentPrefix
	shl bl, 1
	mov dl, [REG16_NAMES + bx]
	call PRINT
	mov dl, [REG16_NAMES + bx + 1]
	call PRINT
	add di, 1
	jmp rmEnd
;-------------------------------
rmMod00:
	; mod = 00 -> memory, no displacement
    cmp bl, 110b
    je  rmTiesioginis  ; [disp16] case
	CALL PrintSegmentPrefix
    shl bx, 1
    mov dx, [AddrModeTable + bx]
    call PRINTS
	mov dl, ']'
	call PRINT
	add di, 1
    jmp rmEnd
rmTiesioginis:
	CALL PrintSegmentPrefix
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	jmp rmEnd
;----------------------------------
rmMod01:
	CALL PrintSegmentPrefix
	shl bx, 1
	mov dx, [AddrModeTable + bx]
	CALL PRINTS
	mov dl, '+'
	call PRINT
	mov dl, [inputBuffer + di + 1]
	call toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	jmp rmEnd
;----------------------------------
rmMod10:
	CALL PrintSegmentPrefix
	shl bx, 1
	mov dx, [AddrModeTable + bx]
	CALL PRINTS
	mov dl, '+'
	call PRINT
	mov dl, [inputBuffer + di + 2]
	call toHexPrint
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	call toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	jmp rmEnd
;----------------------------------
rmEnd:
	mov SegmentPrefix, 0
	pop dx
	pop bx
	pop ax
	RET
decodeRM ENDP
detectPrefix PROC
	mov al, [inputBuffer + di]
	cmp al, 26h
	je prefixES
	cmp al, 2Eh
	je prefixCS
	cmp al, 36h
	je prefixSS
	cmp al, 3Eh
	je prefixDS
	jmp noPrefix
	
prefixES:
	mov SegmentPrefix, 26h
	inc di
	jmp noPrefix
prefixCS:
	mov SegmentPrefix, 2Eh
	inc di
	jmp noPrefix
prefixSS:
	mov SegmentPrefix, 36h
	inc di
	jmp noPrefix
prefixDS:
	mov SegmentPrefix, 3Eh
	inc di
	jmp noPrefix
noPrefix:
	RET
detectPrefix ENDP
PrintSegmentPrefix PROC
    cmp SegmentPrefix, 0
    je  noSegPrint

    cmp SegmentPrefix, 26h
    je  segESl
    cmp SegmentPrefix, 2Eh
    je  segCSl
    cmp SegmentPrefix, 36h
    je  segSSl
    cmp SegmentPrefix, 3Eh
    je  segDSl
    jmp noSegPrint

segESl:
    mov dx, offset SegmentES
    CALL PRINTS
    jmp noSegPrint
segCSl:
    mov dx, offset SegmentCS
    CALL PRINTS
    jmp noSegPrint
segSSl:
    mov dx, offset SegmentSS
    CALL PRINTS
    jmp noSegPrint
segDSl:
    mov dx, offset SegmentDS
    CALL PRINTS
noSegPrint:
    RET
PrintSegmentPrefix ENDP
checkMOV PROC
	mov al, [inputBuffer + di]
	;************* COMPARE 6 ATVEJAI ***************
	; 1. MOV akumuliatorius <- atmintis. 				 aka  1010 000w ajb avb
	cmp al, 0A0h
	je mov1_0
	cmp al, 0A1h
	je mov1_1
	
	; 2. MOV atmintis  atmintis <- akumuliatorius  aka  1010 000w ajb avb
	cmp al, 0A2h
	je mov2_0
	cmp al, 0A3h
	je mov2_1
	; 3. MOV registras/atmintis < betarpiškas operandas. aka 1100 011w mod 000 r/m [poslinkis] bojb [bovb]
	cmp al, 0C6h
	je mov3_0
	cmp al, 0C7h
	je mov3_1
	; 4. MOV registras <> registras/atmintis 			 aka 88h 1000 10dw mod reg r/m [poslinkis]
	cmp al, 88h
	je mov4_00
	cmp al, 89h
	je mov4_01
	cmp al, 8Ah
	je mov4_10
	cmp al, 8Bh
	je mov4_11
	; 6. segmento registras <> registras/atmintis		 aka 1000 11d0 mod 0sr r/m [poslinkis]
	; 5. MOV registras < betarpiškas operandas			 aka B0h 1011 wreg bojb [bovb]
	mov dl, al
	shr dl, 3
	cmp dl, 16h
	je mov5_0
	cmp dl, 17h
	je mov5_1
	mov dx, offset neatpazinta
	CALL PRINTS
	mov dx, offset newline
	CALL PRINTS
	inc di
	RET

mov1_0:
	CALL mov1_0p
	RET
mov1_1:
	CALL mov1_1p
	RET
mov2_0:
	CALL mov2_0p
	RET
mov2_1:
	CALL mov2_1p
	RET
mov3_0:
	CALL mov3_0p
	RET
mov3_1:
	CALL mov3_1p
	RET
mov4_00:
	CALL mov4_00p
	RET
mov4_01:
	CALL mov4_01p
	RET
mov4_10:
	CALL mov4_10p
	RET
mov4_11:
	CALL mov4_11p
	RET
mov5_0:
	CALL mov5_0p
	RET
mov5_1:
	CALL mov5_1p
	RET
checkMOV ENDP
mov1_0p PROC
	mov dx, offset mov10
	CALL PRINTS
	CALL PrintSegmentPrefix
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov1_0p ENDP
mov1_1p PROC

	mov dx, offset mov11
	CALL PRINTS
	CALL PrintSegmentPrefix
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov1_1p ENDP
mov2_0p PROC
	CALL PrintSegmentPrefix
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	mov dx, offset mov20
	CALL PRINTS
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov2_0p ENDP
mov2_1p PROC
	CALL PrintSegmentPrefix
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	
	mov dx, offset mov21
	CALL PRINTS
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov2_1p ENDP
mov3_0p PROC
	mov al, [inputBuffer + di + 1]
	CALL decodeModRM ; ah = mod, cl = reg, bl = r/m
	cmp cl, 0
	jne endmov3_0p

	inc di
	mov dl, [inputBuffer + di]
	
	mov al, 0
	CALL decodeRM	; paziuri i mod ir i r/m ir atspausdina registra/memory
	
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT
	
	mov dl, [inputBuffer + di]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 2
	RET
endmov3_0p:
	RET
mov3_0p ENDP
mov3_1p PROC
	mov al, [inputBuffer + di + 1]
	CALL decodeModRM ; ah = mod, cl = reg, bl = r/m
	cmp cl, 0
	jne endmov3_1p

	inc di
	mov dl, [inputBuffer + di]
	
	mov al, 1
	CALL decodeRM	; paziuri i mod ir i r/m ir atspausdina registra/memory
	
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT
	
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, [inputBuffer + di]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 2
	RET
endmov3_1p:
	RET
mov3_1p ENDP
mov4_00p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM ; ah = mod cl = reg bl = r/m
	
	mov dl, [inputBuffer + di]
	mov al, 0
	CALL decodeRM
	
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT
	mov al, 0
	CALL decodeREG
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_00p ENDP
mov4_01p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	mov al, 1
	CALL decodeRM
	
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT
	
	push ax
	mov al, 1
	CALL decodeREG
	pop ax
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_01p ENDP
mov4_10p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	mov al, 0
	CALL decodeREG
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT
	mov al, 0
	CALL decodeRM
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_10P ENDP
mov4_11p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	push ax
	mov al, 1
	CALL decodeREG
	pop ax
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT
	mov al, 1
	CALL decodeRM
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_11p ENDP
mov5_0p PROC ; 1011 wreg bojb [bovb]
	mov al, [inputBuffer + di]
	and al, 7
	mov cl, al
	mov al, 0
	CALL decodeREG
	
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT 
	
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 2
	RET
mov5_0p ENDP
mov5_1p PROC
	mov al, [inputBuffer + di]
	and al, 7
	mov cl, al
	mov al, 1
	CALL decodeREG
	
	mov dl, ','
	CALL PRINT
	mov dl, ' '
	CALL PRINT 
	
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov5_1p ENDP
END start