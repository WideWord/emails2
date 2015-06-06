
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

macro state name, is_forward, is_ok {
name:
	lodsb
	xlatb
	if is_forward
		norm_forward si
		cmp si, [data_end_ptr]
		je find_email_end.eof
	else
		norm_backward si
	end if

	if is_ok
		mov dx, si
	end if

	dec cx
	cmp cx, 0
	if is_forward
		je find_email_end.fail
	else
		je find_email_start.fail
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

proc find_email_start uses si cx bx dx

	mov si, [search_pos]
	sub si, 1
	norm_backward si

	mov cx, max_username_size
	std
	mov bx, char_table

	mov dx, 0

	jmp b_init
	.exit:

	cmp dx, 0
	je .fail
	mov si, dx

	add si, 2
	norm_forward si
	norm_backward si

	mov ax, si
	ret
.fail:
	mov ax, 0
	ret
endp

state b_init, 0, 0
	when ct_is_username_safe_symbol, b_mid
	when ct_is_dot, find_email_start.exit
	when ct_is_space_symbol, find_email_start.exit
	otherwise find_email_start.fail

state b_mid, 0, 1
	when ct_is_username_safe_symbol, b_mid
	when ct_is_dot, b_after_dot
	when ct_is_space_symbol, find_email_start.exit
	otherwise find_email_start.fail

state b_after_dot, 0, 0
	when ct_is_username_safe_symbol, b_mid
	when ct_is_dot, find_email_start.fail
	when ct_is_space_symbol, find_email_start.exit
	otherwise find_email_start.fail



proc find_email_end uses si cx bx dx

	mov si, [search_pos]
	add si, 1

	norm_forward si

	mov cx, max_domain_size
	cld
	mov bx, char_table

	mov dx, 0

	jmp f_init
	.exit:

	cmp dx, 0
	je .fail
	mov si, dx

	dec si
	norm_backward si
	.eof:
	cmp si, [search_pos]
	je .fail

	mov ax, si
	ret

.fail:
	mov ax, 0
	ret
endp

state f_init, 1, 0
	when ct_is_domain_safe_symbol, f_mid
	when ct_is_space_symbol, find_email_end.exit
	otherwise find_email_end.fail

state f_mid, 1, 1
	when ct_is_domain_safe_symbol, f_mid
	when ct_is_dot, f_after_dot
	when ct_is_dash, f_after_dash
	when ct_is_space_symbol, find_email_end.exit
	otherwise find_email_end.fail

state f_after_dot, 1, 0
	when ct_is_domain_safe_symbol, f_mid
	when ct_is_dot, find_email_end.fail
	when ct_is_dash, find_email_end.fail
	when ct_is_space_symbol, find_email_end.exit
	otherwise find_email_end.fail

state f_after_dash, 1, 0
	when ct_is_domain_safe_symbol, f_mid
	when ct_is_dot, find_email_end.fail
	when ct_is_dash, f_after_dash
	when ct_is_space_symbol, find_email_end.exit
	otherwise find_email_end.fail

