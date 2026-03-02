disk.img: main.asm
	nasm main.asm
	cp fat16.img disk.img
	dd if=main of=disk.img bs=1 seek=62 conv=notrunc
	rm main
