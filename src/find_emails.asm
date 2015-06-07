
data_end_ptr dw 0
search_pos dw buffer_in_1.start
eof_flag db 0



macro scan_for_atc_inline {
	mov di, [search_pos]
	cmp di, word [data_end_ptr]
	je .scan_for_atc_eob

	mov cx, [data_end_ptr]
	cmp cx, di
	jl .scan_for_atc_end_less_pos
		sub cx, di
	jmp .scan_for_atc_end_less_pos_over
	.scan_for_atc_end_less_pos:
		mov cx, buffer_in_2.end
		sub cx, di
	.scan_for_atc_end_less_pos_over:

	cmp cx, 0
	je .scan_for_atc_eob

	mov di, [search_pos]
	mov al, '@'

	repne scasb
	je .scan_for_atc_found

	norm_forward di

	mov [search_pos], di
	jmp .loop_start

.scan_for_atc_found:
	sub di, 1
	norm_backward di
	mov [search_pos], di
	jmp .atc_found

.scan_for_atc_eob:
	stdcall get_buffer_at_ptr, [search_pos]
	stdcall get_buffer_end, ax
	mov [search_pos], ax
	jmp .loop_start
}


proc find_emails uses ax
	
	.loop_start:
		get_buffer_at_ptr_inl al, word [search_pos]
		xor ah, ah
		stdcall make_buffer_avaliable, ax
		cmp ax, 0
		je .eof

		.continue_scan:
		scan_for_atc_inline

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
	cmp dl, byte [.last_loaded_buffer]
	je .already_loaded

	if buf_debug
		stdcall print_int, [buffer_id]
		stdcall print, .space
		stdcall print_hex, [search_pos]
		stdcall print, .buffer_load_str
	end if

	mov [.last_loaded_buffer], dl

	mov bx, [file_in]
	mov cx, buffer_size
	stdcall get_buffer_start, dx
	mov dx, ax
	mov ah, 0x3F

	int 0x21

	cmp ax, cx
	je .over_eof_flag
		mov byte [eof_flag], 1
	.over_eof_flag:

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

.last_loaded_buffer db 0xFF
.buffer_load_str db " buffer load", 13, 10, 0
.buffer_rej_str db " buffer rej", 13, 10, 0
.space db ' ', 0
endp



output_pos dw buffer_out.start

macro store_email_inst postfix, check_eob {
	proc store_email#postfix uses si di ax dx, st, en
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
}

store_email_inst _no_check_eob, 0
store_email_inst _check_eob, 1

macro store_email_call check_eob, from, to {
	if check_eob
		stdcall store_email_check_eob, from, to
	else
		stdcall store_email_no_check_eob, from, to
	end if
}



proc prepare_buffer_to_recognition uses ax bx
	get_buffer_at_ptr_inl al, word [search_pos]
	mov bl, al
	stdcall get_buffer_end, ax
	sub ax, max_domain_size
	cmp ax, [search_pos]
	jg @f
		xor bl, 1
		stdcall make_buffer_avaliable, bx
	@@:
	ret
endp

macro recognize_email_inst postfix, check_eob_forward, check_eob_backward, check_eof {
	proc recognize_email#postfix uses ax dx bx
		find_email_start_call check_eob_backward
		mov bx, ax
		find_email_end_call check_eob_forward, check_eof
		cmp ax, 0
		je .fail
		cmp bx, 0
		je .fail
		store_email_call check_eob_forward, bx, ax
		mov [search_pos], ax
		ret
	.fail:
		inc [search_pos]
		norm_forward word [search_pos]
		ret

	endp
}

recognize_email_inst _000, 0, 0, 0
recognize_email_inst _001, 0, 0, 1
recognize_email_inst _010, 0, 1, 0
recognize_email_inst _011, 0, 1, 1
recognize_email_inst _100, 1, 0, 0
recognize_email_inst _101, 1, 0, 1
recognize_email_inst _110, 1, 1, 0
recognize_email_inst _111, 1, 1, 1

macro recognize_email_inst_call check_eob_forward, check_eob_backward, check_eof {
	stdcall recognize_email_#check_eob_forward#check_eob_backward#check_eof
}

proc recognize_email
	cmp [search_pos], buffer_in_1.start + max_username_size
	jl .cb
		cmp [search_pos], buffer_in_2.end - max_domain_size
		jg .nbcf
			test [eof_flag], 1
			je .nbnfce
				recognize_email_inst_call 0, 0, 0
				ret
			.nbnfce:
				recognize_email_inst_call 0, 0, 1
				ret
		.nbcf:
			test [eof_flag], 1
			je .nbcfce
				recognize_email_inst_call 1, 0, 0
				ret
			.nbcfce:
				recognize_email_inst_call 1, 0, 1
				ret
	.cb:
		cmp [search_pos], buffer_in_2.end - max_domain_size
		jg .cbcf
			test [eof_flag], 1
			je .cbnfce
				recognize_email_inst_call 0, 1, 0
				ret
			.cbnfce:
				recognize_email_inst_call 0, 1, 1
				ret
		.cbcf:
			test [eof_flag], 1
			je .cbcfce
				recognize_email_inst_call 1, 1, 0
				ret
			.cbcfce:
				recognize_email_inst_call 1, 1, 1
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



