/* Default bring-up program.
 *
 * After finishing work, write a known value to 0x10000000 (halt mailbox)
 * via a volatile pointer, then spin. The testbench watches that store;
 * the core treats it as an ordinary memory write.
 */

#define HALT_ADDR  ((volatile unsigned long *)0x10000000UL)
#define HALT_VALUE (1UL)

int main(void)
{
    /* Volatile so the compiler cannot fold the loop away. */
    volatile unsigned long acc = 0;
    for (unsigned long i = 1; i <= 16; i++)
        acc += i;

    (void)acc;
    *HALT_ADDR = HALT_VALUE;

    for (;;)
        ;
    return 0;
}
