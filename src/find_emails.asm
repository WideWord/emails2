
data_end_ptr dw 0
search_pos dw buffer_in_1.start

proc find_emails uses ax
	
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

	if buf_debug
		stdcall print_int, [buffer_id]
		stdcall print, .space
		stdcall print_hex, [search_pos]
		stdcall print, .buffer_load_str
	end if

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

	if buf_debug
		stdcall print_int, [buffer_id]
		stdcall print, .space
		stdcall print_hex, [search_pos]
		stdcall print, .buffer_rej_str
	end if

	stdcall get_buffer_end, dx
	cmp ax, [data_end_ptr]
	jne .eof
	cmp [search_pos], ax
	je .eof

	mov ax, 2
	ret
.eof:
	mov ax, 0
	ret

.last_loaded_buffer dw 0xFF
.buffer_load_str db " buffer load", 13, 10, 0
.buffer_rej_str db " buffer rej", 13, 10, 0
.space db ' ', 0
endp

proc scan_for_atc uses cx dx di bx
	mov di, [search_pos]
	cmp di, word [data_end_ptr]
	je .eob

	
	stdcall get_buffer_at_ptr, di
	stdcall get_buffer_end, ax
	mov cx, ax
	sub cx, di

	mov bx, [data_end_ptr]
	cmp bx, di
	jg @f
		add bx, 2 * buffer_size
	@@:
	sub bx, di
	cmp bx, cx
	jg @f
		mov cx, bx
	@@:

	cmp cx, 0
	je .eob

	mov di, [search_pos]
	mov al, '@'

	repne scasb
	je .found

	norm_forward di

	mov [search_pos], di
	mov ax, 0
	ret
.found:
	sub di, 1
	norm_backward di
	mov [search_pos], di
	mov ax, 1
	ret
.eob:
	stdcall get_buffer_at_ptr, [search_pos]
	stdcall get_buffer_end, ax
	mov [search_pos], ax
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

proc recognize_email uses ax dx bx
	inc word [email_counter]

	stdcall find_email_start
	mov bx, ax
	stdcall find_email_end
	cmp ax, 0
	je .fail
	cmp bx, 0
	je .fail

	stdcall store_email, bx, ax

	mov [search_pos], ax
	ret

.fail:
	inc [search_pos]
	norm_forward word [search_pos]
	ret

endp

proc store_email uses si di ax dx, st, en
	mov si, [st]
	mov di, [en]
	.loop_start:
		cmp si, di
		je .exit
		lodsb
		norm_forward si
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
