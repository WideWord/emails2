
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
		stdcall flush_output
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

	mov cx, [data_end_ptr]
	cmp cx, di
	jl .end_less_pos
		sub cx, di
	jmp .end_less_pos_over
	.end_less_pos:
		mov cx, buffer_in_2.end
		sub cx, di
	.end_less_pos_over:

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

output_pos dw buffer_out.start

proc store_email uses si di ax dx, st, en
	inc word [email_counter]

	mov si, [st]
	mov dx, [en]
	mov di, [output_pos]

	.loop_start:
		movsb

		norm_forward si

		cmp si, dx
		jne .loop_start

	mov al, 13
	stosb
	mov al, 10
	stosb

	mov [output_pos], di

	cmp di, buffer_out.end - max_email_size
	jl @f
		stdcall flush_output
	@@:
	ret
endp

proc flush_output uses ax bx cx dx
	mov ah, 0x40
	mov bx, [file_out]
	mov cx, [output_pos]
	sub cx, buffer_out.start
	cmp cx, 0
	je .exit
	mov dx, buffer_out.start
	int 0x21
	mov [output_pos], buffer_out.start
	.exit:
	ret
endp



