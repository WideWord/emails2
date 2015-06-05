
macro logs string {
	;push ax
	;push dx

	;mov ah, 0x9
	;mov dx, string
	;int 0x21

	;pop dx
	;pop ax
}

macro assert_eq a, b {
	
}