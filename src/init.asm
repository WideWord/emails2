
prg_start:
	stdcall read_arg, .filename, 16
	stdcall open_file, .filename
	mov [file_in], ax
	stdcall write_file, .out_filename
	mov [file_out], ax

	stdcall get_timestamp

	stdcall find_emails

	mov bx, ax
	stdcall get_timestamp
	sub ax, bx
	stdcall print_ms
	stdcall print, .space
	stdcall print_int, [email_counter]
	ret


.filename: rept 16 { db 0 }
.out_filename db "out", 0
.space db " ", 0


exit:
	mov ax, 0x4C00
	int 0x21


file_in dw 0
file_out dw 0

email_counter dw 0