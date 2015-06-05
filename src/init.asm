
prg_start:
	stdcall read_arg, .filename, 16
	stdcall open_file, .filename
	mov [file_in], ax
	stdcall write_file, .out_filename
	mov [file_out], ax
	jmp find_emails

.filename: rept 16 { db 0 }
.out_filename db "out", 0

exit:
	mov ax, 0x4C00
	int 0x21


file_in dw 0
file_out dw 0