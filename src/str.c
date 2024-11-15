#include "str.h"
#include <types.h>

extern int uart_putc(char c);
extern char uart_getc(void);

int gets(char *buf, uint32_t size)
{
	uint32_t i = 0;
	char c;
	while (i < size - 1) {
		c = uart_getc();
		if (c == '\r' || c == '\n') {
			break;
		}
		buf[i++] = c;
		uart_putc(c);
	}
	buf[i] = '\0';
	return i;
}
