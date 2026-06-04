* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
.include ../include/behavioural.inc

.subckt kbee_residue_stage Vz_next Vz Vd
Xrs Vz_next Vz Vd residue_step
.ends kbee_residue_stage
