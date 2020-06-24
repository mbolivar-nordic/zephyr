/*
 * Copyright (c) 2012-2014 Wind River Systems, Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr.h>
#include <device.h>
#include <sys/printk.h>
#include <stdio.h>

#define DEBRACKETED_HANDLES(node_id, dt_handles, extra_handles)	\
	DT_DEP_ORD(node_id),					\
	__DEBRACKET dt_handles					\
	DEVICE_HANDLE_SEP,					\
	__DEBRACKET extra_handles				\
	DEVICE_HANDLE_ENDS,

#define UART0 DT_NODELABEL(uart0)

static void dump_handles(int16_t *handles)
{
	int16_t *p = handles;

	printk("node handle: %d\n", *p);
	p++;

	while (*p != DEVICE_HANDLE_SEP) {
		printk("dt-derived handle: %d\n", *p);
		p++;
	}
	p++;

	while (*p != DEVICE_HANDLE_ENDS) {
		printk("non-dt handle: %d\n", *p);
		p++;
	}
	
	printk("----\n");
}

void main(void)
{
	int16_t only_dt[] = {
		DEBRACKETED_HANDLES(UART0,
				    (DT_REQUIRES_DEP_ORDS(UART0)),
				    ()) 
	};

	int16_t only_extra[] = {
		DEBRACKETED_HANDLES(UART0,
				    (),
				    (DEVICE_HANDLE_SYSCLOCK,)) 
	};

	int16_t dt_and_extra[] = {
		DEBRACKETED_HANDLES(UART0,
				    (DT_REQUIRES_DEP_ORDS(UART0)),
				    (DEVICE_HANDLE_SYSCLOCK,))
	};

	dump_handles(only_dt);
	dump_handles(only_extra);
	dump_handles(dt_and_extra);
}
