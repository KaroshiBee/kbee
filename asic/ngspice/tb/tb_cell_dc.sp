* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Cell vs fabric equivalence bench (same ui_mode, codes)
.include ../include/params.inc
.include ../cell/kbee_cell.sp

.param a_code=5 b_code=10 c_code=0 ui_mode=4

Va Va 0 DC {a_code}
Vb Vb 0 DC {b_code}
Vc Vc 0 DC {c_code}
Xfab Vyf Va Vb Vc kbee_reference_fabric ui_mode=4
Xcell Vyc Va Vb Vc kbee_cell ui_mode=4

.control
op
print V(Vyf) V(Vyc)
.endc
