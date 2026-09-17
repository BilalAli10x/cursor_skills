/* I-extension directed test: ADDI/ADD/load/store. Halt 1 = pass. */

#define HALT ((volatile unsigned long *)0x10000000UL)

static void done(unsigned long code)
{
    *HALT = code;
    for (;;)
        ;
}

int main(void)
{
    volatile unsigned long x = 40;
    x = x + 2;
    if (x != 42)
        done(2);
    done(1);
    return 0;
}
