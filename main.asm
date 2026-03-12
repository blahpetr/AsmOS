bits 16
org 0x7C3E

bytesPerSector equ 0x7C0B
sectorsPerCluster equ 0x7C0D
reservedSectors equ 0x7C0E
numberOfFATs equ 0x7C10
rootEntryCount equ 0x7C11
sectorsPerFAT equ 0x7C16

;Layout info
rootDirStartSector equ 0x6000 ;4 bytes
rootDirOffset equ 0x6004 ;4 bytes
rootDirSizeBytes equ 0x6008 ;4 bytes
rootDirSectors equ 0x600C ;4 bytes
firstDataSector equ 0x6010 ;4 bytes
fatOffset equ 0x6014 ;4 bytes
curentScanOffset equ 0x6018 ; 2 bytes
BootDrive equ 0x601A ; 1 byte

targetName equ 0x0500 ; 8 bytes

	mov [BootDrive], dl
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
	add bx, targetName
	mov [bx-1], al ;Save written char into a string
	
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

	;cmp edx, 0
	;jne .fail_brokenDisk
	
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
	mov [0x9006], ax
	mov [0x900C], eax			; first part of LBA (0 since disk too small)
	mov ax, 0x8000				; where to save es offset (0x8000)
	mov [curentScanOffset], ax
	mov [0x9004], ax
	mov eax, [rootDirOffset]
	mov ebx, 0x0200				; second part of LBA, calculated as diskOffset/512
	xor edx, edx
	div ebx
	mov [0x9008], eax ; Create the DAP

	mov ah, 0x42
	mov dl, [BootDrive]
	mov si, 0x9000
	int 0x13		; Request read from disk
	jc .fail_brokenDisk
	
.find_file:
	mov ax, 0x0000       ; or the segment where 0x8000 resides
	mov es, ax

	mov bx, [curentScanOffset]
	mov eax, es:[bx]
	mov ebx, es:[bx+4]
	mov ecx, [targetName]
	mov edx, [targetName+4]

	cmp ax, 0x0000
	je .fail_fileNotFound ;This one gets executed, ax is not supposed to be 0x0000
	
	cmp eax, ecx
	jne .incorrectName

	cmp ebx, edx
	jne .incorrectName 

	xor eax, eax
	mov bx, [curentScanOffset]
	mov ax, [bx+26]

	sub ax, 0x0002
	xor bx, bx
	mov bl, [sectorsPerCluster]
	mul bx
	mov ebx, [firstDataSector]
	add eax, ebx

	mov [0x9008], eax 
	mov al, 0x10				; DAP size
	mov [0x9000], al			
	mov al, 0x00 				; reserved 0
	mov [0x9001], al
	xor ax, ax
	mov al, [sectorsPerCluster] ; how many sectors to load (1 sector usually 512 bytes)
	mov [0x9002], ax
	mov ax, 0x8000				; where to save BX segment (0)
	mov [0x9004], ax
	xor eax, eax				; where to save es offset (0x8000)
	mov [0x9006], ax
	mov [0x900C], eax			; first part of LBA (0 since disk too small)
								; Create the DAP

	mov ah, 0x42
	mov dl, [BootDrive]
	mov si, 0x9000
	int 0x13		; Request read from disk
	jc .fail_brokenDisk

	mov ax, 0x8000
	jmp ax

.incorrectName:

	xor eax, eax
	xor ebx, ebx
	mov eax, [curentScanOffset]
	mov ebx, 0x20
	add eax, ebx
	mov [curentScanOffset], eax
	jmp .find_file

.fail_fileNotFound:
	jmp .draw_CLI

.fail_brokenDisk:
	jmp .draw_CLI

targetExtension db "BIN"

string_size db 0x00

times (448 - ($ - $$)) db 0 ; 512 boot segment - 2 bytes at the end - 62 bytes due to FAT16 headers
dw 0xaa55

