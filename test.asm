.model small

BSeg SEGMENT
ORG 100h
ASSUME ds:BSeg, cs:BSeg, ss:BSeg

start:

	mov ax, [msg]
	mov [msg], ax
	mov al, [msg2]
	mov ax, [msg]
	mov [di+10], 017Fh
	mov [di + bp + 23h], 2F23h
	mov cl, dl
	mov dl, al
	mov cl, [msg2]
	mov bl, [msg2+bp]
	mov ax, bx
	mov al, 3
	mov dx, 1264h
	
	msg dw 112h
	msg2 db 1
BSeg ENDS
END start