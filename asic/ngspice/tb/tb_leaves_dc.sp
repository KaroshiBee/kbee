* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Leaf cell smoke tests
.include ../include/params.inc
.include ../leaves/summer.sp
.include ../leaves/comparator.sp

Va Va 0 DC 15
Vb Vb 0 DC 0
Vc Vc 0 DC 0
Xsum Vz Va Vb Vc kbee_summer
Xcl Vd Vz kbee_classify

.control
op
print V(Vz) V(Vd)
.endc
