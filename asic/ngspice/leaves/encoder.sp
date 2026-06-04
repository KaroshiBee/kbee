* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
.include ../include/params.inc
.include ../include/behavioural.inc

.subckt kbee_encoder Vcode Iin
Xen Vcode Iin current_to_code
.ends kbee_encoder
