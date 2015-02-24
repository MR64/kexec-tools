/*
 * crashdump for arm64
 *
 * Copyright (c) 2014 Linaro Limited
 * Author: AKASHI Takahiro <takahiro.akashi@linaro.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef CRASHDUMP_ARM64_H
#define CRASHDUMP_ARM64_H

#include "kexec.h"

#define CRASH_MAX_MEMORY_RANGES	32

extern struct memory_ranges usablemem_rgns;

int load_crashdump_segments(struct kexec_info *info, char **option);
void modify_ehdr_for_crashmem(struct mem_ehdr *ehdr);
void set_crash_entry(struct mem_ehdr *ehdr, struct kexec_info *info);
off_t locate_dtb_in_crashmem(struct kexec_info *info, off_t dtb_size);

#endif
