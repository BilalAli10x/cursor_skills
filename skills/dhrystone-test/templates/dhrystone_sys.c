/* Freestanding glue for riscv-tests Dhrystone: mailbox printf, string ops.
 * putchar stores one byte at 0x80000008; the testbench $write's it.
 * Completion is a store of 1 to 0x80000000 (done from dhrystone_main.c).
 */

#include <stdarg.h>

#define PUTCHAR ((volatile unsigned long *)0x80000008UL)

static void putchar_m(char c)
{
    *PUTCHAR = (unsigned char)c;
}

char *strcpy(char *dst, const char *src)
{
    char *d = dst;
    while ((*d++ = *src++) != '\0')
        ;
    return dst;
}

int strcmp(const char *a, const char *b)
{
    while (*a && (*a == *b)) {
        a++;
        b++;
    }
    return (unsigned char)*a - (unsigned char)*b;
}

void *memcpy(void *dst, const void *src, unsigned long n)
{
    unsigned char *d = dst;
    const unsigned char *s = src;
    while (n--)
        *d++ = *s++;
    return dst;
}

static void print_uint(unsigned long v, int width, int zero_pad)
{
    char buf[24];
    int i = 0;
    if (v == 0)
        buf[i++] = '0';
    while (v) {
        buf[i++] = '0' + (char)(v % 10);
        v /= 10;
    }
    while (width-- > i)
        putchar_m(zero_pad ? '0' : ' ');
    while (i--)
        putchar_m(buf[i]);
}

static void print_int(long v)
{
    if (v < 0) {
        putchar_m('-');
        print_uint((unsigned long)(-v), 0, 0);
    } else {
        print_uint((unsigned long)v, 0, 0);
    }
}

static int vprintf_m(const char *fmt, va_list ap)
{
    int n = 0;
    for (; *fmt; fmt++) {
        if (*fmt != '%') {
            putchar_m(*fmt);
            n++;
            continue;
        }
        fmt++;

        /* flags */
        int zero_pad = 0;
        if (*fmt == '0') {
            zero_pad = 1;
            fmt++;
        }

        /* width */
        int width = 0;
        while (*fmt >= '0' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }

        /* length modifier */
        int is_long = 0;
        if (*fmt == 'l') {
            is_long = 1;
            fmt++;
        }

        switch (*fmt) {
        case 's': {
            const char *s = va_arg(ap, const char *);
            if (!s)
                s = "(null)";
            while (*s) {
                putchar_m(*s++);
                n++;
            }
            break;
        }
        case 'd':
            print_int(is_long ? va_arg(ap, long) : va_arg(ap, int));
            break;
        case 'u':
            print_uint(is_long ? va_arg(ap, unsigned long)
                                : va_arg(ap, unsigned int),
                        width, zero_pad);
            break;
        case 'c':
            putchar_m((char)va_arg(ap, int));
            break;
        case '%':
            putchar_m('%');
            break;
        default:
            putchar_m('%');
            if (*fmt)
                putchar_m(*fmt);
            break;
        }
    }
    return n;
}

int printf(const char *fmt, ...)
{
    va_list ap;
    int n;
    va_start(ap, fmt);
    n = vprintf_m(fmt, ap);
    va_end(ap);
    return n;
}

void debug_printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vprintf_m(fmt, ap);
    va_end(ap);
}
