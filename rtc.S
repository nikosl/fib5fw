// Copyright 2024 Nikos Leivadaris <nikosleiv@gmail.com>.
// SPDX-License-Identifier: MIT

/**
~~~
  rtc@101000 {
   interrupts = <0x0b>;
   interrupt-parent = <0x03>;
   reg = <0x00 0x101000 0x00 0x1000>;
   compatible = "google,goldfish-rtc";
  };
  ~~~
*/

.equ RTC_BASE, 0x101000

#define RTC_TIME_LOW            0x00
#define RTC_TIME_HIGH           0x04
#define RTC_ALARM_LOW           0x08
#define RTC_ALARM_HIGH          0x0c
#define RTC_IRQ_ENABLED         0x10
#define RTC_CLEAR_ALARM         0x14
#define RTC_ALARM_STATUS        0x18
#define RTC_CLEAR_INTERRUPT     0x1c