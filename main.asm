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
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	mov ax, [numberOfFATs]
	mov bl, [reservedSectors]
	mov cx, [sectorsPerFAT]
	mul ecx
	add eax, ebx 
	mov [rootDirStartSector], eax


	xor ebx, ebx
	mov bx, [bytesPerSector]
	mul ebx
	mov [rootDirOffset], eax

	xor eax, eax
	xor ebx, ebx
	mov ax, [rootEntryCount]
	mov bl, 0x20
	mul ebx
	mov [rootDirSizeBytes], eax	

	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	mov bx, [bytesPerSector]
	mov cx, [bytesPerSector]
	mov dl, 0x01
	sub bx, dx
	add eax, ebx
	xor edx, edx
	div ecx
	mov [rootDirSectors], eax

	cmp edx, 0
	jne .fail_brokenDisk
	
	mov eax, [rootDirStartSector]
	mov ebx, [rootDirSectors]
	add eax, ebx
	mov [firstDataSector], eax

	xor eax, eax
	xor ebx, ebx
	mov ax, [reservedSectors]
	mov bx, [bytesPerSector]
	add eax, ebx
	mov [fatOffset], eax

	mov al, 0x10				; DAP size
	mov [0x9000], al			
	mov al, 0x00 				; reserved 0
	mov [0x9001], al
	mov eax, [rootDirSectors]	; how many sectors to load (1 sector usually 512 bytes)
	mov [0x9002], ax
	xor eax, eax				; where to save BX segment (0)
	mov [0x9004], ax
	mov [0x9012], eax			; first part of LBA (0 since disk too small)
	mov ax, 0x8000				; where to save es offset (0x8000)
	mov [0x9006], ax
	mov eax, rootDirOffset
	mov ebx, 0x0200				; second part of LBA, calculated as diskOffset/512
	div ebx
	mov [0x9008], eax ; Create the DAP

	mov ah, 0x42
	mov dl, 0x80
	mov si, 0x9000
	int 0x13		; Request read from disk
	jc .fail_brokenDisk

.find_file:
	xor eax, eax
	xor ebx, ebx


.incorrectName:
	xor eax, eax
	xor ebx, ebx
	mov eax, [rootDirOffset]
	mov ebx, 0x20
	add eax, ebx
	mov [rootDirOffset], eax
	jmp .find_file

.fail_fileNotFound:
	jmp .draw_CLI

.fail_brokenDisk:
	jmp .draw_CLI
	
;Layout info
rootDirStartSector db 0x00000000 ;4 bytes
rootDirOffset db 0x00000000 ;4 bytes
rootDirSizeBytes db 0x00000000 ;4 bytes
rootDirSectors db 0x00000000 ;4 bytes
firstDataSector db 0x00000000 ;4 bytes
fatOffset db 0x00000000 ;4 bytes

;Directory scanning
entryCount db 0x0000 ;might delete
entryOffset db 0x00000000 ;4 bytes
entryFirstByte db 0x00 ;1 byte
filenameMatch db 0x00 ;1 byte

;File metadata
firstCluster db 0x0000 ;2 bytes
fileSize db 0x00000000 ;4 bytes
currentCluster db 0x0000 ;2 bytes
nextCluster db 0x0000 ;2 bytes

;Cluster math
firstSectorOfCluster db 0x00000000 ;4 bytes
fileDataOffset db 0x00000000 ;4 bytes
fatEntryOffset db 0x00000000 ;4 bytes

targetName db "HELLO   " ;TODO: Make sure it is connected to the tty
targetExtension db "BIN"

string_size db 0x00

times (448 - ($ - $$)) db 0 ; 512 boot segment - 2 bytes at the end - 62 bytes due to FAT16 headers
dw 0xaa55

