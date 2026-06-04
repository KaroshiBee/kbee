* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* DC bench: compare fabric Vy to expected (NOR mode, c=0 corner)
.include ../include/params.inc
.include ../fabric/reference_fabric.sp

.param a_code=85 b_code=0 c_code=0 ui_mode=2

Va Va 0 DC {a_code}
Vb Vb 0 DC {b_code}
Vc Vc 0 DC {c_code}

Xfab Vy Va Vb Vc kbee_reference_fabric ui_mode=2

.control
op
print V(Vy) V(Va)+V(Vb)+V(Vc)
.endc
