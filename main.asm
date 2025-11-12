org 0x7c00

.draw_CLI:
	mov ah, 0x00
	mov [string_size], ah

	mov ah, 0x0E
	mov al, ">"
	int 0x10

	mov ah, 0x0E
	mov al, " "
	int 0x10

.wait_for_key:
	mov ah, 0x00
	int 0x16

	mov bx, 0x0000
	mov bl, [string_size]
	inc bl
	mov [string_size], bl ;Save written char into a string
	add bx, 0x0500
	mov [bx], al

	cmp al, 0x0D
	
	mov ah, 0x0E
	int 0x10

	jne .wait_for_key

.handle_command:
	;Implement
	mov ah, 0x0E
	mov al, 0x0A
	int 0x10

	mov bx, 0x0500
	add bx, [string_size]
	mov al, [bx]
	mov ah, 0x0E
	int 0x10

	mov cx, 0x0000

.print:

	cmp cl, [string_size]
	jz .done_print

	;mov ah, 0x0E
	;mov al, "#" ; Debug, remember to remove this!
	;int 0x10

	mov bx, 0x0500
	add bx, cx
	mov al, [bx]
	mov ah, 0x0E
	int 0x10

	inc cl
	jmp .print

.done_print:
	mov ah, 0x0E
	mov al, 0x0D
	int 0x10

	mov ah, 0x0E
	mov al, 0x0A
	int 0x10
	
	jmp .draw_CLI

string_size db 0x00

times (510 - ($ - $$)) db 0
dw 0xaa55

