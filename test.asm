.model small

BSeg SEGMENT
ORG 100h
ASSUME ds:BSeg, cs:BSeg, ss:BSeg

start:
	mov dx, si
	mov cx, bp
	mov di, sp
	mov ah, al
	mov [bx + si], 1234h
	mov [si], 12
	mov [var2], 0ABCDh
	mov [var], 0ABh
	mov var, 0ABh
	mov ax, 102h
	mov al, 1h
	mov bx, 0203h
	mov bh, 2h
	mov cx, 384h
	mov ch, 03h
	mov dx, 405h
	mov dl, 04h
	mov al, [var]
	mov ax, [var2]
	mov [var], al
	mov [var2], ax
	mov bx, ss:[12h]
	mov ax, es:[si]
	mov ax, cs:[bx]
	mov ax, cs:[0002h]
	mov ax, es:[0000h]
	mov ax, cs:[bp+12h]
	mov ax, ds:[bp+12h]
	mov ax, es:[bp+12h]
	mov bx, ss:[bx+12h]
	mov ax, ds:[bp+2h]
	
	var2 dw 54h
	var db 54h
	msg dw 112h
	msg2 db 1
BSeg ENDS
END start