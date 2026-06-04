* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Combinational 4-stage residue fabric + mode-selected accumulator (voltage codes)
.include ../include/params.inc
.include ../include/behavioural.inc

* Predicate voltage Ven ~1 when digit d (Vd) should contribute for ui_mode
* ui_mode: 0 AND, 1 NAND, 2 NOR, 3 OR, 4 XOR, 5 XNOR (logic); unary uses bypass
.subckt fabric_enable Ven Vd Vc params: ui_mode=2
Bpred Ven 0 V='(ui_mode==2)*(abs(V(Vd))<0.1)+(ui_mode==0)*((V(Vc)<0.1)*(abs(V(Vd)-2)<0.1)+(V(Vc)>=0.1)*(abs(V(Vd)-3)<0.1))+(ui_mode==1)*((V(Vc)<0.1)*(abs(V(Vd)-2)>0.1)+(V(Vc)>=0.1)*(abs(V(Vd)-3)>0.1))+(ui_mode==4)*((abs(V(Vd)-1)<0.1)+(abs(V(Vd)-3)<0.1))+(ui_mode==5)*((abs(V(Vd))<0.1)+(abs(V(Vd)-2)<0.1))+(ui_mode==3)*(V(Vd)>0.1)'
.ends fabric_enable

.subckt kbee_reference_fabric Vy Va Vb Vc params: ui_mode=2
Xsum Vz Va Vb Vc summer3

* stage 0
Xcl0 Vd0 Vz classify_digit
Xen0 Ven0 Vd0 Vc fabric_enable ui_mode={ui_mode}
Binc0 Vinc0 0 V='P_v'
Bvy0 Vy0 0 V='((V(Ven0)>0.5)?V(Vinc0):0)'
Xrs0 Vz1 Vz Vd0 residue_step

* stage 1
Xcl1 Vd1 Vz1 classify_digit
Xen1 Ven1 Vd1 Vc fabric_enable ui_mode={ui_mode}
Binc1 Vinc1 0 V='P_v/4'
Bvy1 Vy1 0 V='V(Vy0)+((V(Ven1)>0.5)?V(Vinc1):0)'
Xrs1 Vz2 Vz1 Vd1 residue_step

* stage 2
Xcl2 Vd2 Vz2 classify_digit
Xen2 Ven2 Vd2 Vc fabric_enable ui_mode={ui_mode}
Binc2 Vinc2 0 V='P_v/16'
Bvy2 Vy2 0 V='V(Vy1)+((V(Ven2)>0.5)?V(Vinc2):0)'
Xrs2 Vz3 Vz2 Vd2 residue_step

* stage 3
Xcl3 Vd3 Vz3 classify_digit
Xen3 Ven3 Vd3 Vc fabric_enable ui_mode={ui_mode}
Binc3 Vinc3 0 V='P_v/64'
Bvy3 Vy3 0 V='V(Vy2)+((V(Ven3)>0.5)?V(Vinc3):0)'
Xrs3 Vz4 Vz3 Vd3 residue_step

* final code output
Bout Vy 0 V='V(Vy3)'
.ends kbee_reference_fabric
