* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Quantised code -> current (encoding linearity bench)
.include ../include/params.inc
.include ../include/behavioural.inc

.subckt kbee_dac Iout Vcode
Xdc Iout Vcode code_to_current
.ends kbee_dac
