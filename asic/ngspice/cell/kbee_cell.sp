* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Atomic cell wrapper — same core as reference_fabric (pass 1: mask tied off)
.include ../fabric/reference_fabric.sp

.subckt kbee_cell Vy Va Vb Vc params: ui_mode=2
Xfab Vy Va Vb Vc kbee_reference_fabric ui_mode={ui_mode}
.ends kbee_cell
