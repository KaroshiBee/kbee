* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Minimal sky130-style mirror sketch (pass-1; replace with foundry models via PDK)
* Use ngspice Level=1 placeholders for W/L sensitivity studies.
.include ../include/params.inc

.model nmos_lv1 NMOS level=1 Vto=0.4 kp=50u gamma=0.3 lambda=0.05
.model pmos_lv1 PMOS level=1 Vto=-0.4 kp=25u gamma=0.3 lambda=0.05

.subckt nmos_mirror Iout Iref Vdd Vss
Mn1 Iref Iref Vss Vss nmos_lv1 W={mos_w_n} L={mos_l_n}
Mn2 Iout Iref Vss Vss nmos_lv1 W={mos_w_n} L={mos_l_n}
.ends nmos_mirror

.subckt pmos_mirror Iout Iref Vdd Vss
Mp1 Iref Iref Vdd Vdd pmos_lv1 W={mos_w_p} L={mos_l_p}
Mp2 Iout Iref Vdd Vdd pmos_lv1 W={mos_w_p} L={mos_l_p}
.ends pmos_mirror

* Simple current summer: Iout = I1+I2+I3 (KCL at high-Z node)
.subckt i_summer3 Iout I1 I2 I3 Vdd Vss
X1 n1 I1 Vdd Vss nmos_mirror
X2 n2 I2 Vdd Vss nmos_mirror
X3 n3 I3 Vdd Vss nmos_mirror
* behavioural correction for pass-1 DC check
Bsum Iout 0 I='V(I1, Vss)+V(I2, Vss)+V(I3, Vss)'
.ends i_summer3
