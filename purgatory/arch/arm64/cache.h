#ifndef	__CACHE_H__
#define __CACHE_H__

#define VA_BITS			42
#define SECTION_SHIFT		29
#define PAGE_TABLE_SIZE		(1 << (VA_BITS - SECTION_SHIFT + 3))

#define TCR_TG0_64K 		(1 << 14)
#define TCR_SHARED_NON		(0 << 12)
#define TCR_ORGN_WBWA		(1 << 10)
#define TCR_IRGN_WBWA		(1 << 8)
#define TCR_T0SZ(x)		((64 - (x)) << 0)
#define TCR_EL1_IPS_BITS	(3 << 32) /* 42 bits physical address */
#define TCR_EL2_IPS_BITS	(3 << 16) /* 42 bits physical address */
#define TCR_EL3_IPS_BITS	(3 << 16) /* 42 bits physical address */

#define TCR_FLAGS (TCR_TG0_64K | TCR_SHARED_NON | TCR_ORGN_WBWA | \
		TCR_IRGN_WBWA | TCR_T0SZ(VA_BITS))

#define MT_DEVICE_NGNRNE	0
#define MT_DEVICE_NGNRE		1
#define MT_DEVICE_GRE		2
#define MT_NORMAL_NC		3
#define MT_NORMAL		4

#define MEMORY_ATTRIBUTES	((0x00 << (MT_DEVICE_NGNRNE*8)) | \
				(0x04 << (MT_DEVICE_NGNRE*8)) | \
				(0x0c << (MT_DEVICE_GRE*8)) | \
				(0x44 << (MT_NORMAL_NC*8)) | \
				(0xff << (MT_NORMAL*8)))

#define CR_M			(1 << 0)	/* MMU enable */
#define CR_C			(1 << 2)	/* Dcache enable */


#define PMD_TYPE_SECT		(1 << 0)
#define PMD_SECT_AF		(1 << 10)
#define PMD_ATTRINDX(t)		((t) << 2)
#define PMD_FLAGS	(PMD_TYPE_SECT | PMD_SECT_AF)
#define MM_MMUFLAGS	PMD_ATTRINDX(MT_NORMAL) | PMD_FLAGS

#endif
