/*
 * Cache maintenance
 * Some of the routine has been copied from Linux Kernel, therefore
 * copying the license as well.
 *
 * Copyright (C) 2001 Deep Blue Solutions Ltd.
 * Copyright (C) 2012 ARM Ltd.
 * Copyright (C) 2015 Pratyush Anand <panand@redhat.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "cache.h"

/*
 * dcache_line_size - get the minimum D-cache line size from the CTR register.
 */
	.macro	dcache_line_size, reg, tmp
	mrs	\tmp, ctr_el0			// read CTR
	ubfm	\tmp, \tmp, #16, #19		// cache line size encoding
	mov	\reg, #4			// bytes per word
	lsl	\reg, \reg, \tmp		// actual cache line size
	.endm

/*
 *	__inval_cache_range(start, end)
 *	- start	- start address of region
 *	- end	- end address of region
 */
__inval_cache_range:
	dcache_line_size x2, x3
	sub	x3, x2, #1
	tst	x1, x3				// end cache line aligned?
	bic	x1, x1, x3
	b.eq	1f
	dc	civac, x1			// clean & invalidate D / U line
1:	tst	x0, x3				// start cache line aligned?
	bic	x0, x0, x3
	b.eq	2f
	dc	civac, x0			// clean & invalidate D / U line
	b	3f
2:	dc	ivac, x0			// invalidate D / U line
3:	add	x0, x0, x2
	cmp	x0, x1
	b.lo	2b
	dsb	sy
	ret
/*
 *	__flush_dcache_range(start, end)
 *	- start	- start address of region
 *	- end	- end address of region
 *
 */
__flush_dcache_range:
	dcache_line_size x2, x3
	sub	x3, x2, #1
	bic	x0, x0, x3
1:	dc	civac, x0			// clean & invalidate D line / unified line
	add	x0, x0, x2
	cmp	x0, x1
	b.lo	1b
	dsb	sy
	ret

/*
 *	enable_dcache(start, end, page_table)
 *	- start	- start address of ram
 *	- end	- end address of ram
 *	- page_table - base of page table
 */
.globl enable_dcache
enable_dcache:
	stp	x6, x7, [sp,#-16]!
	stp	x16, x17, [sp,#-16]!
	stp	x18, x19, [sp,#-16]!

	/* save args */
	mov x16, x0	/* first segment start */
	mov x17, x1	/* last segment end */
	mov x18, x2 	/* page table */
	mov x19, x30	/* save ret addr */

	/*
	 * Invalidate the page tables to avoid potential
	 * dirty cache lines being evicted.
	 */
	mov x0, x18
	add x1, x0, #PAGE_TABLE_SIZE
	bl __inval_cache_range

	/*
	 * Clear the page tables.
	 */
	mov x0, x18
	add x1, x0, #PAGE_TABLE_SIZE
1:	stp	xzr, xzr, [x0], #16
	stp	xzr, xzr, [x0], #16
	stp	xzr, xzr, [x0], #16
	stp	xzr, xzr, [x0], #16
	cmp	x0, x1
	b.lo	1b

	/*
	 * Create the identity mapping.
	 */
	ldr	x6, =SECTION_SHIFT
	ldr	x7, =MM_MMUFLAGS
	lsr	x0, x16, x6	//first index
	lsr	x1, x17, x6	//last index

next_sect:
	lsl	x2, x0, x6	//section
	orr	x2, x2, x7
	str	x2, [x18, x0, lsl #3]
	add	x0, x0, #1
	cmp	x0, x1
	b.ls	next_sect

	/*
	 * Since the page tables have been populated with non-cacheable
	 * accesses (MMU disabled), invalidate the idmap page
	 * tables again to remove any speculatively loaded cache lines.
	 */
	mov x0, x18
	add x1, x0, #PAGE_TABLE_SIZE
	bl __inval_cache_range

	mrs 	x0, CurrentEL
	cmp	x0, #12	//EL3
	b.eq	set_el3
	cmp	x0, #8	//EL2
	b.eq	set_el2
	cmp	x0, #4	//EL1
	b.eq	set_el1
	b	done_enable

set_el1:
	msr	ttbr0_el1, x18
	ldr	x0, =TCR_FLAGS
	orr	x0, x0, #TCR_EL1_IPS_BITS
	msr	tcr_el1, x0
	ldr	x0, =MEMORY_ATTRIBUTES
	msr	mair_el1, x0
	mrs	x0, sctlr_el1
	orr	x0, x0, #CR_M
	orr	x0, x0, #CR_C
	msr	sctlr_el1, x0
	b	done_enable
set_el2:
	msr	ttbr0_el2, x18
	ldr	x0, =TCR_FLAGS
	orr	x0, x0, #TCR_EL2_IPS_BITS
	msr	tcr_el2, x0
	ldr	x0, =MEMORY_ATTRIBUTES
	msr	mair_el2, x0
	mrs	x0, sctlr_el2
	orr	x0, x0, #CR_M
	orr	x0, x0, #CR_C
	msr	sctlr_el2, x0
	b	done_enable
set_el3:
	msr	ttbr0_el3, x18
	ldr	x0, =TCR_FLAGS
	orr	x0, x0, #TCR_EL3_IPS_BITS
	msr	tcr_el3, x0
	ldr	x0, =MEMORY_ATTRIBUTES
	msr	mair_el3, x0
	mrs	x0, sctlr_el3
	orr	x0, x0, #CR_M
	orr	x0, x0, #CR_C
	msr	sctlr_el3, x0
done_enable:

	mov	x30, x19
	ldp	x18, x19, [sp],#16
	ldp	x16, x17, [sp],#16
	ldp	x6, x7, [sp],#16

	ret

.globl disable_dcache
disable_dcache:
	stp	x5, x30, [sp,#-16]!
	mrs 	x5, CurrentEL
	cmp	x5, #12	//EL3
	b.eq	disable_el3
	cmp	x5, #8	//EL2
	b.eq	disable_el2
	cmp	x5, #4	//EL1
	b.eq	disable_el1
	b	done_disable
disable_el3:
	mrs	x5, sctlr_el3
	bic	x5, x2, #CR_M
	bic	x5, x2, #CR_C
	msr	sctlr_el3, x5
	b	done_disable
disable_el2:
	mrs	x5, sctlr_el2
	bic	x5, x2, #CR_M
	bic	x5, x2, #CR_C
	msr	sctlr_el2, x5
	b	done_disable
disable_el1:
	mrs	x5, sctlr_el1
	bic	x5, x2, #CR_M
	bic	x5, x2, #CR_C
	msr	sctlr_el1, x5
done_disable:
	bl __flush_dcache_range
	ldp	x5, x30, [sp],#16
	ret
