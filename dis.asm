.model small
.stack 100h

.data
	errorMsg db "Netinkama Ivestis$"
	inputOK  db "Input File Opened correctly!$"
	outputOK db "Output File Created correctly!$"
	inputNOTOK db "Error Opening Input File!$"
	outputNOTOK db "Error Creating Output File!$"
	space db " $"
	newline db 10, 13, "$"
	inputFileName db 64 dup (0)
	inputFileHandle dw ?
	inputFileSize dw ?
	
	outputFileName db 64 dup(0)
	outputFileHandle dw ?
	
	inputBuffer db 60000 dup(0)
	neatpazinta db "NEATPAZINTA$"
	
	msg00000 db "[BX+SI$"
	msg00001 db "[BX+DI$"
	msg00010 db "[BP+SI$"
	msg00011 db "[BP+DI$"
	msg00100 db "[SI$"
	msg00101 db "[DI$"
	;msg00110 tiesioginis adresas
	msg00111 db "[BX]$"
	
	msg01110 db "[BP$"
	
	mov10 db "al <- $"
	mov11 db "ax <- $"
	mov20 db "al -> $"
	mov21 db "ax -> $"
	w_0 db "8 bits$"
	w_1 db "16 bits$"
	
.code
start:
	
	mov ax, @data
	mov ds, ax
	
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
	mov dx, offset newline
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
	mov dx, offset newline
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
	mov cx, 60000
	mov dx, offset inputBuffer
	int 21h
	mov [inputFileSize], ax
	RET
Skaitymas ENDP
PRINT PROC
	push ax
	mov ah, 2
	int 21h
	pop ax
	RET
PRINT ENDP
PRINTS PROC
	push ax
	push bx
	push cx
	push dx
	mov ah, 9
	int 21h
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
decodeREG0 PROC
	push ax
	mov ah, 2
	cmp cl, 0
	je regAL
	cmp cl, 1
	je regCL
	cmp cl, 2
	je regDL
	cmp cl, 3
	je regBL
	cmp cl, 4
	je regAH
	cmp cl, 5
	je regCH
	cmp cl, 6
	je regDH
	cmp cl, 7
	je regBH
regAL:
	mov dl, 'A'
	int 21h
	mov dl, 'L'
	int 21h
	pop ax
	RET
regCL:
	mov dl, 'C'
	int 21h
	mov dl, 'L'
	int 21h
	pop ax
	RET
regDL:
	mov dl, 'D'
	int 21h
	mov dl, 'L'
	int 21h
	pop ax
	RET
regBL:
	mov dl, 'B'
	int 21h
	mov dl, 'L'
	int 21h
	pop ax
	RET
regAH:
	mov dl, 'A'
	int 21h
	mov dl, 'H'
	int 21h
	pop ax
	RET
regCH:
	mov dl, 'C'
	int 21h
	mov dl, 'H'
	int 21h
	pop ax
	RET
regDH:
	mov dl, 'D'
	int 21h
	mov dl, 'H'
	int 21h
	pop ax
	RET
regBH:
	mov dl, 'B'
	int 21h
	mov dl, 'H'
	int 21h
	pop ax
	RET
decodeREG0 ENDP
decodeREG1 PROC
	push ax
	mov ah, 2
	cmp cl, 0
	je regAX
	cmp cl, 1
	je regCX
	cmp cl, 2
	je regDX
	cmp cl, 3
	je regBX
	cmp cl, 4
	je regSP
	cmp cl, 5
	je regBP
	cmp cl, 6
	je regSI
	cmp cl, 7
	je regDI
regAX:
	mov dl, 'A'
	int 21h
	mov dl, 'X'
	int 21h
	pop ax
	RET
regCX:
	mov dl, 'C'
	int 21h
	mov dl, 'X'
	int 21h
	pop ax
	RET
regDX:
	mov dl, 'D'
	int 21h
	mov dl, 'X'
	int 21h
	pop ax
	RET
regBX:
	mov dl, 'B'
	int 21h
	mov dl, 'X'
	int 21h
	pop ax
	RET
regSP:
	mov dl, 'S'
	int 21h
	mov dl, 'P'
	int 21h
	pop ax
	RET
regBP:
	mov dl, 'B'
	int 21h
	mov dl, 'P'
	int 21h
	pop ax
	RET
regSI:
	mov dl, 'S'
	int 21h
	mov dl, 'I'
	int 21h
	pop ax
	RET
regDI:
	mov dl, 'D'
	int 21h
	mov dl, 'I'
	int 21h
	pop ax
	RET
decodeREG1 ENDP
decodeRM0 PROC
	cmp ah, 0
	jne mod00continue
	jmp mod00
mod00continue:
	cmp ah, 1
	jne mod01continue
	jmp mod01
mod01continue:
	cmp ah, 2
	jne mod10continue
	jmp mod10
mod10continue:
	cmp ah, 3
	jmp mod11
mod00:
	cmp bl, 0
	je rm00000
	cmp bl, 1
	je rm00001
	cmp bl, 2
	je rm00010
	cmp bl, 3
	je rm00011
	cmp bl, 4
	je rm00100
	cmp bl, 5
	je rm00101
	cmp bl, 6
	je rm00110
	cmp bl, 7
	je rm00111
rm00000:
	mov dx, offset msg00000
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00001:
	mov dx, offset msg00001
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00010:
	mov dx, offset msg00010
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00011:
	mov dx, offset msg00011
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00100:
	mov dx, offset msg00100
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00101:
	mov dx, offset msg00101
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00110:
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + DI + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + DI + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm00111:
	mov dx, offset msg00111
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
mod01:
	cmp bl, 0
	jne rmcontinue
	jmp rm01000
rmcontinue:
	cmp bl, 1
	jne rmcontinue2
	jmp rm01001
rmcontinue2:
	cmp bl, 2
	jne rmcontinue3
	jmp rm01010
rmcontinue3:
	cmp bl, 3
	jne rmcontinue4
	jmp rm01011
rmcontinue4:
	cmp bl, 4
	jne rmcontinue5
	jmp rm01100
rmcontinue5:
	cmp bl, 5
	jne rmcontinue6
	jmp rm01101
rmcontinue6:
	cmp bl, 6
	jne rmcontinue7
	jmp rm01110
rmcontinue7:
	cmp bl, 7
	jmp rm01111
rm01000:

	mov dx, offset msg00000
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01001:
	mov dx, offset msg00001
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01010:
	mov dx, offset msg00010
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01011:
	mov dx, offset msg00011
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01100:
	mov dx, offset msg00100
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01101:
	mov dx, offset msg00101
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01110:
	mov dx, offset msg01110
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01111:
	mov dx, offset msg00111
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
mod10:
	cmp bl, 0
	jne rmcontinue8
	je rm10000
rmcontinue8:
	cmp bl, 1
	jne rmcontinue9
	jmp rm10001
rmcontinue9:
	cmp bl, 2
	jne rmcontinue10
	jmp rm10010
rmcontinue10:
	cmp bl, 3
	jne rmcontinue11
	jmp rm10011
rmcontinue11:
	cmp bl, 4
	jne rmcontinue12
	jmp rm10100
rmcontinue12:
	cmp bl, 5
	jne rmcontinue13
	jmp rm10101
rmcontinue13:
	cmp bl, 6
	jne rmcontinue14
	jmp rm10110
rmcontinue14:
	cmp bl, 7
	jmp rm10111
rm10000:
	mov dx, offset msg00000
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10001:
	mov dx, offset msg00001
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10010:
	mov dx, offset msg00010
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10011:
	mov dx, offset msg00011
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10100:
	mov dx, offset msg00100
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10101:
	mov dx, offset msg00101
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10110:
	mov dx, offset msg01110
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10111:
	mov dx, offset msg00111
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
mod11:
	cmp bl, 0
	je rm11000
	cmp bl, 1
	je rm11001
	cmp bl, 2
	je rm11010
	cmp bl, 3
	je rm11011
	cmp bl, 4
	je rm11100
	cmp bl, 5
	je rm11101
	cmp bl, 6
	je rm11110
	cmp bl, 7
	je rm11111
rm11000:
	mov dl, 'A'
	CALL PRINT
	mov dl, 'L'
	CALL PRINT
	inc di
	RET
rm11001:
	mov dl, 'C'
	CALL PRINT
	mov dl, 'L'
	CALL PRINT
	inc di
	RET
rm11010:
	mov dl, 'D'
	CALL PRINT
	mov dl, 'L'
	CALL PRINT
	inc di
	RET
rm11011:
	mov dl, 'B'
	CALL PRINT
	mov dl, 'L'
	CALL PRINT
	inc di
	RET
rm11100:
	mov dl, 'A'
	CALL PRINT
	mov dl, 'H'
	CALL PRINT
	inc di
	RET
rm11101:
	mov dl, 'C'
	CALL PRINT
	mov dl, 'H'
	CALL PRINT
	inc di
	RET
rm11110:
	mov dl, 'D'
	CALL PRINT
	mov dl, 'H'
	CALL PRINT
	inc di
	RET
rm11111:
	mov dl, 'B'
	CALL PRINT
	mov dl, 'H'
	CALL PRINT
	inc di
	RET
decodeRM0 ENDP
decodeRM1 PROC
	cmp ah, 0
	jne mod00continue1
	jmp mod00s
mod00continue1:
	cmp ah, 1
	jne mod01continue1
	jmp mod01s
mod01continue1:
	cmp ah, 2
	jne mod10continue1
	jmp mod10s
mod10continue1:
	cmp ah, 3
	jmp mod11s
mod00s:
	cmp bl, 0
	je rm00000s
	cmp bl, 1
	je rm00001s
	cmp bl, 2
	je rm00010s
	cmp bl, 3
	je rm00011s
	cmp bl, 4
	je rm00100s
	cmp bl, 5
	je rm00101s
	cmp bl, 6
	je rm00110s
	cmp bl, 7
	je rm00111s
rm00000s:
	mov dx, offset msg00000
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00001s:
	mov dx, offset msg00001
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00010s:
	mov dx, offset msg00010
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00011s:
	mov dx, offset msg00011
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00100s:
	mov dx, offset msg00100
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00101s:
	mov dx, offset msg00101
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
rm00110s:
	mov dl, '['
	CALL PRINT
	mov dl, [inputBuffer + DI + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + DI + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm00111s:
	mov dx, offset msg00111
	CALL PRINTS
	mov dl, ']'
	CALL PRINT
	inc di
	RET
mod01s:
	cmp bl, 0
	jne rmcontinueS
	jmp rm01000s
rmcontinueS:
	cmp bl, 1
	jne rmcontinue2S
	jmp rm01001s
rmcontinue2S:
	cmp bl, 2
	jne rmcontinue3S
	jmp rm01010s
rmcontinue3S:
	cmp bl, 3
	jne rmcontinue4S
	jmp rm01011s
rmcontinue4S:
	cmp bl, 4
	jne rmcontinue5S
	jmp rm01100s
rmcontinue5S:
	cmp bl, 5
	jne rmcontinue6S
	jmp rm01101s
rmcontinue6S:
	cmp bl, 6
	jne rmcontinue7S
	jmp rm01110s
rmcontinue7S:
	cmp bl, 7
	jmp rm01111s
rm01000s:

	mov dx, offset msg00000
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01001s:
	mov dx, offset msg00001
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01010s:
	mov dx, offset msg00010
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01011s:
	mov dx, offset msg00011
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01100s:
	mov dx, offset msg00100
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01101s:
	mov dx, offset msg00101
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01110s:
	mov dx, offset msg01110
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
rm01111s:
	mov dx, offset msg00111
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 2
	RET
mod10s:
	cmp bl, 0
	jne rmcontinue8S
	je rm10000s
rmcontinue8S:
	cmp bl, 1
	jne rmcontinue9S
	jmp rm10001s
rmcontinue9S:
	cmp bl, 2
	jne rmcontinue10S
	jmp rm10010s
rmcontinue10S:
	cmp bl, 3
	jne rmcontinue11S
	jmp rm10011s
rmcontinue11S:
	cmp bl, 4
	jne rmcontinue12S
	jmp rm10100s
rmcontinue12S:
	cmp bl, 5
	jne rmcontinue13S
	jmp rm10101s
rmcontinue13S:
	cmp bl, 6
	jne rmcontinue14S
	jmp rm10110s
rmcontinue14S:
	cmp bl, 7
	jmp rm10111s
rm10000s:
	mov dx, offset msg00000
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10001s:
	mov dx, offset msg00001
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10010s:
	mov dx, offset msg00010
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10011s:
	mov dx, offset msg00011
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10100s:
	mov dx, offset msg00100
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10101s:
	mov dx, offset msg00101
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10110s:
	mov dx, offset msg01110
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
rm10111s:
	mov dx, offset msg00111
	CALL PRINTS
	mov dl, '+'
	CALL PRINT
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dl, ']'
	CALL PRINT
	add di, 3
	RET
mod11s:
	cmp bl, 0
	je rm11000s
	cmp bl, 1
	je rm11001s
	cmp bl, 2
	je rm11010s
	cmp bl, 3
	je rm11011s
	cmp bl, 4
	je rm11100s
	cmp bl, 5
	je rm11101s
	cmp bl, 6
	je rm11110s
	cmp bl, 7
	je rm11111s
rm11000s:
	mov dl, 'A'
	CALL PRINT
	mov dl, 'X'
	CALL PRINT
	inc di
	RET
rm11001s:
	mov dl, 'C'
	CALL PRINT
	mov dl, 'X'
	CALL PRINT
	inc di
	RET
rm11010s:
	mov dl, 'D'
	CALL PRINT
	mov dl, 'X'
	CALL PRINT
	inc di
	RET
rm11011s:
	mov dl, 'B'
	CALL PRINT
	mov dl, 'X'
	CALL PRINT
	inc di
	RET
rm11100s:
	mov dl, 'S'
	CALL PRINT
	mov dl, 'P'
	CALL PRINT
	inc di
	RET
rm11101s:
	mov dl, 'B'
	CALL PRINT
	mov dl, 'P'
	CALL PRINT
	inc di
	RET
rm11110s:
	mov dl, 'S'
	CALL PRINT
	mov dl, 'I'
	CALL PRINT
	inc di
	RET
rm11111s:
	mov dl, 'D'
	CALL PRINT
	mov dl, 'I'
	CALL PRINT
	inc di
	RET
decodeRM1 ENDP
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
	; 5. segmento registras <> registras/atmintis		 aka 1000 11d0 mod 0sr r/m [poslinkis]
	; 6. MOV registras < betarpiškas operandas			 aka B0h 1011 wreg bojb [bovb]
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
	mov dx, offset w_0
	CALL PRINTS
	mov dx, offset space
	CALL PRINTS
	mov dx, offset mov10
	CALL PRINTS
	
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov1_0p ENDP
mov1_1p PROC

	mov dx, offset w_1
	CALL PRINTS
	mov dx, offset space
	CALL PRINTS
	mov dx, offset mov11
	CALL PRINTS
	
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov1_1p ENDP
mov2_0p PROC
	mov dx, offset w_0
	CALL PRINTS
	mov dx, offset space
	CALL PRINTS
	mov dx, offset mov20
	CALL PRINTS
	
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	add di, 3
	RET
mov2_0p ENDP
mov2_1p PROC
	mov dx, offset w_1
	CALL PRINTS
	
	mov dx, offset space
	CALL PRINTS
	mov dx, offset mov21
	CALL PRINTS
	
	mov dl, [inputBuffer + di + 2]
	CALL toHexPrint
	mov dl, [inputBuffer + di + 1]
	CALL toHexPrint
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
	;CALL decodeREG0 ; print the reg
	
	CALL decodeRM0	; paziuri i mod ir i r/m ir atspausdina registra/memory
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
	CALL PRINT
	
	mov dl, [inputBuffer + di]
	CALL toHexPrint
	mov dx, offset newline
	CALL PRINTS
	inc di
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
	
	CALL decodeRM1	; paziuri i mod ir i r/m ir atspausdina registra/memory
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
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
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	CALL decodeRM0
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
	CALL PRINT
	
	CALL decodeREG0
	RET
mov4_00p ENDP
mov4_01p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	CALL decodeREG0
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
	CALL PRINT
	
	CALL decodeRM0
	
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_01p ENDP
mov4_10p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	CALL decodeREG0
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
	CALL PRINT
	
	CALL decodeRM0
	
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_10P ENDP
mov4_11p PROC
	inc di
	mov al, [inputBuffer + di]
	CALL decodeModRM
	
	mov dl, [inputBuffer + di]
	CALL decodeREG1
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
	CALL PRINT
	
	CALL decodeRM1
	
	mov dx, offset newline
	CALL PRINTS
	RET
mov4_11p ENDP
mov5_0p PROC ; 1011 wreg bojb [bovb]
	mov al, [inputBuffer + di]
	and al, 7
	CALL decodeREG0
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
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
	CALL decodeREG1
	
	mov dl, '<'
	CALL PRINT
	mov dl, '-'
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