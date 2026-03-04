BITS 16
ORG 0x8000

.loop:
	mov ah, 0x0E
	mov al, "H"
	int 0x10
	jmp .loop
