#include <stdio.h>

unsigned char table[256];


void range(char from, char to, unsigned char bit) {
	for (int i = from; i <= to; ++i) {
		table[i] |= bit;
	}
}

void at(char ch, unsigned char bit) {
	table[ch] |= bit;
}

void atm(const char* chars, unsigned char bit) {
	while (*chars != 0) {
		table[*chars] |= bit;
		chars += 1;
	}
}

#define IS_CHAR 1
#define IS_ALLOWED 2
#define IS_USERNAME_SAFE_SYMBOL 4
#define IS_DOMAIN_SAFE_SYMBOL 8
#define IS_DIGIT 16
#define IS_DOT 32
#define IS_DASH 64
#define IS_SPACE_SYMBOL 128

int main() {

	for (int i = 0; i < 256; ++i) {
		table[i] = 0;
	}

	range('a', 'z', IS_CHAR | IS_ALLOWED | IS_USERNAME_SAFE_SYMBOL | IS_DOMAIN_SAFE_SYMBOL);
	range('A', 'Z', IS_CHAR | IS_ALLOWED | IS_USERNAME_SAFE_SYMBOL | IS_DOMAIN_SAFE_SYMBOL);
	range('0', '9', IS_CHAR | IS_ALLOWED | IS_USERNAME_SAFE_SYMBOL | IS_DOMAIN_SAFE_SYMBOL);
	range('0', '9', IS_DIGIT);

	atm("@._-", IS_ALLOWED);
	atm("!#$%&'*+-/=?^_`{|}~", IS_ALLOWED | IS_USERNAME_SAFE_SYMBOL);
	at('.', IS_DOT);
	at('-', IS_DASH);

	printf("char_table:\n");	
	for (int i = 0; i < 256; ++i) {
		printf("db %d\n", table[i]);
	}

	return 0;
}