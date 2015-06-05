
data_end_ptr dw 0
search_pos dw buffer_in_1.start

proc find_emails
	
	.loop_start:
		stdcall get_buffer_at_ptr, word [search_pos]
		stdcall make_buffer_avaliable, ax
		cmp ax, 0
		je .eof

		.continue_scan:
		stdcall scan_for_atc
		bt ax, 0
		jc .atc_found
		jmp .loop_start

	.atc_found:
		stdcall prepare_buffer_to_recognition
		stdcall recognize_email
		jmp .continue_scan

	.eof:
		ret
endp

proc make_buffer_avaliable uses bx cx dx, buffer_id
	mov dx, [buffer_id]
	cmp dx, word [.last_loaded_buffer]
	je .already_loaded

	mov word [.last_loaded_buffer], dx

	mov bx, [file_in]
	mov cx, buffer_size
	stdcall get_buffer_start, [buffer_id]
	mov dx, ax
	mov ah, 0x3F

	int 0x21

	cmp ax, 0
	je .eof

	add dx, ax
	mov [data_end_ptr], dx

	mov ax, 1
	ret

.already_loaded:
	stdcall get_buffer_end, dx
	cmp ax, [data_end_ptr]
	jne .eof

	mov ax, 2
	ret
.eof:
	mov ax, 0
	ret

.last_loaded_buffer dw 0xFF
endp

proc scan_for_atc uses cx dx di
	mov di, [search_pos]
	cmp di, word [data_end_ptr]
	je .eob
	jge .over_1
		mov cx, [data_end_ptr]
		sub cx, [search_pos]
		jmp .over_2
	.over_1:
		mov ax, [search_pos]
		sub ax, [data_end_ptr]
		mov cx, 2 * buffer_size
		sub cx, ax
	.over_2:

	mov di, [search_pos]
	mov al, '@'

	repne scasb
	je .found

	mov [search_pos], di
	assert_eq word [search_pos], word [data_end_ptr]
	mov ax, 0
	ret
.found:
	sub di, 1
	mov [search_pos], di
	mov ax, 1
	ret
.eob:
	mov ax, 0
	ret
endp

proc prepare_buffer_to_recognition uses ax bx
	stdcall get_buffer_at_ptr, word [search_pos]
	mov bx, ax
	stdcall get_buffer_end, ax
	sub ax, max_domain_size
	cmp ax, [search_pos]
	jg @f
		xor bx, 1
		stdcall make_buffer_avaliable, bx
	@@:
	ret
endp

proc recognize_email uses ax dx
	
	stdcall find_email_start
	cmp ax, 0
	je .fail
	mov bx, ax
	stdcall find_email_end
	cmp ax, 0
	je .fail

	stdcall store_email, bx, ax

	mov [search_pos], ax

	ret

.fail:
	inc [search_pos]
	stdcall normalize_search_pos
	ret
endp

proc normalize_search_pos
	cmp word [search_pos], buffer_in_2.end
	jge .g
	cmp word [search_pos], buffer_in_1.start
	jl .l
	ret

	.g:	
		sub word [search_pos], 2 * buffer_size
		cmp word [search_pos], buffer_in_2.end
		jge .g
		ret
	.l:
		add word [search_pos], 2 * buffer_size
		cmp word [search_pos], buffer_in_1.start
		jl .l
		ret

endp

proc store_email uses si di ax dx, st, en
	mov si, [st]
	mov di, [en]
	.loop_start:
		cmp si, di
		je .exit
		lodsb
		norm_si_forward
		mov dl, al
		mov ah, 0x2
		int 0x21
	jmp .loop_start
	.exit:
	mov ah, 0x2
	mov dl, 13
	int 0x21
	mov dl, 10
	int 0x21

	ret

endp
