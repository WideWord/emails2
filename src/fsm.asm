
macro norm_backward x {
	cmp x, buffer_in_1.start - 1
	jg @f
		add x, 2 * buffer_size
	@@:
}

macro norm_forward x {
	cmp x, buffer_in_2.end
	jl @f
		sub x, 2 * buffer_size
	@@:
}

macro state name, is_forward, is_ok, check_eob_forward, check_eob_backward, check_eof, prefix {
name:
	lodsb
	xlatb
	if is_forward
		if check_eob_forward
			norm_forward si
		end if
		if check_eof
			cmp si, [data_end_ptr]
			je prefix#find_email_end_eof
		end if
	else
		if check_eob_backward
			norm_backward si
		end if
	end if

	if is_ok
		mov dx, si
	end if

	dec cx
	cmp cx, 0
	if is_forward
		je prefix#find_email_end_fail
	else
		je prefix#find_email_start_fail
	end if

}

macro when cond, st {
	bt ax, cond
	jc st
}

macro when_not cond, st {
	bt ax, cond
	jnc st
}

macro otherwise st {
	jmp st
}

macro b_fsm_inst prefix, check_eob_forward, check_eob_backward, check_eof {

	state prefix#b_init, 0, 0, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_username_safe_symbol, prefix#b_mid
		when ct_is_dot, prefix#find_email_start_exit
		when ct_is_space_symbol, prefix#find_email_start_exit
		otherwise prefix#find_email_start_fail

	state prefix#b_mid, 0, 1, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_username_safe_symbol, prefix#b_mid
		when ct_is_dot, prefix#b_after_dot
		when ct_is_space_symbol, prefix#find_email_start_exit
		otherwise prefix#find_email_start_fail

	state prefix#b_after_dot, 0, 0, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_username_safe_symbol, prefix#b_mid
		when ct_is_dot, prefix#find_email_start_fail
		when ct_is_space_symbol, prefix#find_email_start_exit
		otherwise prefix#find_email_start_fail

}

macro find_email_start_inst prefix, check_eob_backward {
	proc prefix#find_email_start uses si cx bx dx

		mov si, [search_pos]
		sub si, 1
		if check_eob_backward
			norm_backward si
		end if

		mov cx, max_username_size
		std
		mov bx, char_table

		mov dx, 0

		jmp prefix#b_init
		prefix#find_email_start_exit:

		cmp dx, 0
		je prefix#find_email_start_fail
		mov si, dx

		add si, 2
		if check_eob_backward
			norm_forward si
		end if

		mov ax, si
		ret
	prefix#find_email_start_fail:
		mov ax, 0
		ret
	endp

	b_fsm_inst prefix, 0, check_eob_backward, 0
}

find_email_start_inst inst_no_check_eob_, 0
find_email_start_inst inst_check_eob_, 1

macro find_email_start_call check_eob {
	if check_eob
		stdcall inst_check_eob_find_email_start
	else
		stdcall inst_no_check_eob_find_email_start
	end if
}


macro f_fsm_isnt prefix, check_eob_forward, check_eob_backward, check_eof {
	
	state prefix#f_init, 1, 0, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_domain_safe_symbol, prefix#f_mid
		when ct_is_space_symbol, prefix#find_email_end_exit
		otherwise prefix#find_email_end_fail

	state prefix#f_mid, 1, 1, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_domain_safe_symbol, prefix#f_mid
		when ct_is_dot, prefix#f_after_dot
		when ct_is_dash, prefix#f_after_dash
		when ct_is_space_symbol, prefix#find_email_end_exit
		otherwise prefix#find_email_end_fail

	state prefix#f_after_dot, 1, 0, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_domain_safe_symbol, prefix#f_mid
		when ct_is_dot, prefix#find_email_end_fail
		when ct_is_dash, prefix#find_email_end_fail
		when ct_is_space_symbol, prefix#find_email_end_exit
		otherwise prefix#find_email_end_fail

	state prefix#f_after_dash, 1, 0, check_eob_forward, check_eob_backward, check_eof, prefix
		when ct_is_domain_safe_symbol, prefix#f_mid
		when ct_is_dot, prefix#find_email_end_fail
		when ct_is_dash, prefix#f_after_dash
		when ct_is_space_symbol, prefix#find_email_end_exit
		otherwise prefix#find_email_end_fail
}

macro find_email_end_inst prefix, check_eob_forward, check_eof {

	proc prefix#find_email_end uses si cx bx dx

		mov si, [search_pos]
		add si, 1

		if check_eob_forward
			norm_forward si
		end if

		mov cx, max_domain_size
		cld
		mov bx, char_table

		mov dx, 0

		jmp prefix#f_init
		prefix#find_email_end_exit:

		cmp dx, 0
		je prefix#find_email_end_fail
		mov si, dx

		dec si
		if check_eob_forward
			norm_backward si
		end if
		prefix#find_email_end_eof:
		cmp si, [search_pos]
		je prefix#find_email_end_fail

		mov ax, si
		ret

	prefix#find_email_end_fail:
		mov ax, 0
		ret

	endp

	f_fsm_isnt prefix, check_eob_forward, 0, check_eof

}

find_email_end_inst inst_ff_, 0, 0
find_email_end_inst inst_ft_, 0, 1
find_email_end_inst inst_tf_, 1, 0
find_email_end_inst inst_tt_, 1, 1

macro find_email_end_call check_eob_forward, check_eof {
	if check_eob_forward
		if check_eof
			stdcall inst_tt_find_email_end
		else
			stdcall inst_tf_find_email_end
		end if
	else
		if check_eof
			stdcall inst_ft_find_email_end
		else
			stdcall inst_ff_find_email_end
		end if
	end if
}
