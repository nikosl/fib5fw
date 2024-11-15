# fib5fw

riscv fw

dtc -I dtb -O dts -o riscv64-virt.dts riscv64-virt.dtb
  rtc@101000 {
   interrupts = <0x0b>;
   interrupt-parent = <0x03>;
   reg = <0x00 0x101000 0x00 0x1000>;
   compatible = "google,goldfish-rtc";
  };

  serial@10000000 {
   interrupts = <0x0a>;
   interrupt-parent = <0x03>;
   clock-frequency = <0x384000>; // 3686400Hz
   reg = <0x00 0x10000000 0x00 0x100>;
   compatible = "ns16550a";
  }

## PLIC

| IRQ  | Dev   |
|------|-------|
| 0x0a | uart0 |
| ---  | ---   |
| 0x0b | rtc   |

 PLIC_BASE           0x0c000000
 PLIC_PRIORITY_BASE  0x4
 PLIC_PENDING_BASE   0x1000
 PLIC_ENABLE_BASE    0x2000
 PLIC_ENABLE_STRIDE  0x80
 PLIC_CONTEXT_BASE   0x200000
 PLIC_CONTEXT_STRIDE 0x1000

 PLIC_MODE_MACHINE    0x0
 PLIC_MODE_SUPERVISOR 0x1

 PLIC_PRIORITY(interrupt) \
    (PLIC_BASE + PLIC_PRIORITY_BASE * interrupt)

 PLIC_THRESHOLD(hart, mode) \
    (PLIC_BASE + PLIC_CONTEXT_BASE + PLIC_CONTEXT_STRIDE *(2* hart + mode))

 PLIC_CLAIM(hart, mode) \
    (PLIC_THRESHOLD(hart, mode) + 4)

 PLIC_ENABLE(hart, mode) \
    (PLIC_BASE + PLIC_ENABLE_BASE + PLIC_ENABLE_STRIDE *(2* hart + mode))

0x0C00_2000 Hart 0 M-mode enable registers

```dts
plic@c000000 {
   phandle = <0x03>;
   riscv,ndev = <0x60>;
   reg = <0x00 0xc000000 0x00 0x600000>;
   interrupts-extended = <0x02 0x0b 0x02 0x09>;
   interrupt-controller;
   compatible = "sifive,plic-1.0.0\0riscv,plic0";
   #address-cells = <0x00>;
   #interrupt-cells = <0x01>;
  };
```

## CLINT

```dts
  clint@2000000 {
   interrupts-extended = <0x02 0x03 0x02 0x07>;
   reg = <0x00 0x2000000 0x00 0x10000>;
   compatible = "sifive,clint0\0riscv,clint0";
  };
```

riscv64-unknown-elf-gcc -g -ffreestanding -O0 -Wl,--gc-sections \
    -nostartfiles -nostdlib -nodefaultlibs -Wl,-T,riscv64-virt.ld \
    crt0.s add.c

void f (void) __attribute__ ((interrupt ("user")));

```cpp
static void entry(void) __attribute__ ((interrupt ("machine")));
#pragma GCC push_options
// Force the alignment for mtvec.BASE.
#pragma GCC optimize ("align-functions=4")
    static void entry(void)  {
        // Jump into the function defined within the irq::handler class.
        handler::handler_entry();
    }
#pragma GCC pop_options
```

cfi-flash
base 0x20000000
size 0x2000000 32MB
"sector-length", 256 * kib
"width", 4
"device-width", 2
"id0", 0x89
"id1", 0x18
"id2", 0x00
"id3", 0x00
num block, size / sector len
