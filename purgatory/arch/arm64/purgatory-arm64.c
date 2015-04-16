/*
 * ARM64 purgatory.
 */

#include <stdint.h>
#include <purgatory.h>

/* Symbols set by kexec. */

extern uint32_t *arm64_sink;
extern void (*arm64_kernel_entry)(uint64_t);
extern uint64_t arm64_dtb_addr;

static void wait_for_xmit_complete(void)
{
	volatile uint32_t status;
	volatile uint32_t *status_reg;

	/*
	 * Since most of the UART with ARM platform has LSR register at
	 * offset 0x14 and should have value as 0x60 for TX empty, so we
	 * have hardcoded these values. Can modify in future if need
	 * arises.
	 */
	status_reg = (volatile uint32_t *)((uint64_t)arm64_sink + 0x14);
	while (1) {
		status = *status_reg;
		if ((status & 0x60) == 0x60)
			break;
	}
}

void putchar(int ch)
{
	if (!arm64_sink)
		return;

	wait_for_xmit_complete();
	*arm64_sink = ch;

	if (ch == '\n') {
		wait_for_xmit_complete();
		*arm64_sink = '\r';
	}
}

void setup_arch(void)
{
	printf("purgatory: kernel_entry: %lx\n",
		(unsigned long)arm64_kernel_entry);
	printf("purgatory: dtb:          %lx\n", arm64_dtb_addr);
}

void post_verification_setup_arch(void)
{
	arm64_kernel_entry(arm64_dtb_addr);
}
