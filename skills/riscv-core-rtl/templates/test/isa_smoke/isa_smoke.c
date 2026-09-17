/* Directed I/Zicsr smoke. The generating skill extends this with M/A/C
   checks matching the requested ISA. Writes 1 to 0x10000000 on success. */

#define HALT ((volatile unsigned long *)0x10000000UL)

static void done(unsigned long code)
{
    *HALT = code;
    for (;;)
        ;
}

int main(void)
{
    volatile unsigned long a = 7, b = 6;
    unsigned long cyc0, cyc1;

    if (a + b != 13)
        done(2);

    __asm__ volatile ("csrr %0, mcycle" : "=r"(cyc0));
    __asm__ volatile ("csrr %0, mcycle" : "=r"(cyc1));
    if (cyc1 <= cyc0)
        done(8);

    done(1);
    return 0;
}
