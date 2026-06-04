* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Three-input code summer (voltage domain codes)
.include ../include/params.inc
.include ../include/behavioural.inc

.subckt kbee_summer Vz Va Vb Vc
Xsum Vz Va Vb Vc summer3
.ends kbee_summer
