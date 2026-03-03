bits 16
org 0x7C3E

bytesPerSector equ 0x7C0B
sectorsPerCluster equ 0x7C0D
reservedSectors equ 0x7C0E
numberOfFATs equ 0x7C10
rootEntryCount equ 0x7C11
sectorsPerFAT equ 0x7C16

.draw_CLI:
	mov ah, 0x00
	mov [string_size], ah ;Input index

	mov ah, 0x0E
	mov al, ">"
	int 0x10

	mov ah, 0x0E
	mov al, " "
	int 0x10			;CLI interface

.wait_for_key:
	mov ah, 0x00
	int 0x16

	cmp al, 0x0D
	je .handle_command

	mov bx, 0x0000
	mov bl, [string_size]
	inc bl
	mov [string_size], bl ;Increment index
	add bx, 0x0500
	mov [bx], al ;Save written char into a string
	
	mov ah, 0x0E
	int 0x10

	jmp .wait_for_key

.handle_command:
	;Implement

	mov ah, 0x0E
	mov al, 0x0D
	int 0x10
	mov ah, 0x0E
	mov al, 0x0A
	int 0x10		; Move carry

	mov cx, 0x0000

.print:

	cmp cl, [string_size]
	jz .done_print

	;mov ah, 0x0E
	;mov al, "#" ; Debug, remember to remove this!
	;int 0x10

	mov bx, 0x0500
	add bx, cx
	add bx, 1
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
	mov al, 0x0A ; Move carry
	int 0x10
	
	jmp .draw_CLI

.run_prg:


	
;Layout info
rootDirStartSector db 0x00000000
rootDirOffset db 0x00000000
rootDirSizeBytes db 0x00000000
rootDirSectors db 0x00000000
firstDataSector db 0x00000000
fatOffset db 0x00000000

;Directory scanning
entryCount db 0x0000 ;might delete
entryOffset db 0x00000000
entryFirstByte db 0x00
filenameMatch db 0x00

;File metadata
firstCluster db 0x0000
fileSize db 0x00000000
currentCluster db 0x0000
nextCluster db 0x0000

;Cluster math
firstSectorOfCluster db 0x00000000
fileDataOffset db 0x00000000
fatEntryOffset db 0x00000000

targetName db "HELLO   BIN" ;TODO: Make sure it is connected to the tty

string_size db 0x00

times (448 - ($ - $$)) db 0 ; 512 boot segment - 2 bytes at the end - 62 bytes due to FAT16 headers
dw 0xaa55

