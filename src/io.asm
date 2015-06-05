

proc print uses di ax dx, string
	mov si, [string]
	.loop_start:
		cmp byte [si], 0
		je .loop_end
		mov dl, [si]
		mov ah, 0x2
		int 0x21
		inc si
	jmp .loop_start
	.loop_end:
	ret
endp

proc print_hex uses ax dx cx bx, number

	mov cx, 4
	.out_loop:
		mov dx, 0
		mov ax, [number]
		mov bx, 10h
		div bx
		mov [number], ax

		cmp dl, 9
		jg .char
		add dl, '0'
		jmp .char_end
		.char:
		add dl, 87
		.char_end:
		push dx
	loop .out_loop

	mov ah, 02h
	mov cx, 4
	.print_loop:
		pop dx
		int 21h
	loop .print_loop

	ret

endp



proc read_arg uses si di cx, buffer, limit
	mov si, 0x82
	mov di, [buffer]
	mov cl, [0x80]
	mov ch, 0
	sub cx, 1
	cmp cx, [limit]
	jl @f
		mov cx, [limit]
		sub cx, 1
	@@:

	cld
	rep movsb

	mov byte [di], 0

	ret
endp

proc open_file uses dx, filename
	mov ah, 0x3D
	mov dx, [filename]
	mov al, 0
	int 0x21
	jc .err ; if not error
		ret
	.err:
		cmp ax, 0x2
		jne @f
			stdcall print, .file_not_found_str
			mov ax, 0
			ret
		@@:

		stdcall print, .unknown_error_str
		stdcall print_hex, ax
		jmp exit

.file_not_found_str db "File not found.", 13, 10, 0
.unknown_error_str db "Can not open file: unknown error: ", 0

endp



proc write_file uses dx, filename
	mov ah, 0x3C
	mov dx, [filename]
	mov al, 0
	mov cx, 0
	int 0x21
	jc .err ; if not error
		ret
	.err:
		cmp ax, 0x2
		jne @f
			stdcall print, .file_not_found_str
			mov ax, 0
			ret
		@@:

		stdcall print, .unknown_error_str
		stdcall print_hex, ax
		jmp exit

.file_not_found_str db "File not found.", 13, 10, 0
.unknown_error_str db "Can not open file: unknown error: ", 0

endp


proc print_int uses ax dx cx, x
	mov ax, [x]
	mov dx, 0
	mov cx, 10
	idiv cx

	cmp ax, 0
	je .skip
	stdcall print_int, ax
	.skip:
	mov ah, 02h
	add dl, 30h
	int 21h
	ret
endp

