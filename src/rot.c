static inline void riscv_wfi(void)
{
	__asm__ volatile("wfi");
}

void loop(void)
{
	// int rc = 0;
	do {
		riscv_wfi();
	} while (1);

	// return rc;
}
