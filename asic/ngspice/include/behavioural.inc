* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* Behavioural building blocks (codes as Volts: 1 V == 1 code unit)

.subckt code_to_current Iout Vcode
Bsrc Iout 0 I='V(Vcode)*I_step_eff'
.ends code_to_current

.subckt current_to_code Vcode Iin
Rsh Vcode 0 1
Bsrc 0 Vcode I='V(Iin)/I_step_eff'
.ends current_to_code

.subckt summer3 Vz Va Vb Vc
Bsum Vz 0 V='V(Va)+V(Vb)+V(Vc)'
.ends summer3

* Classify leading digit d in {0,1,2,3} as voltage on Vd (0..3 V)
.subckt classify_digit Vd Vz
B0 Vd 0 V='(V(Vz)<Vth1)?0:((V(Vz)<Vth2)?1:((V(Vz)<Vth3)?2:3))'
.ends classify_digit

.subckt residue_step Vz_next Vz Vd
* z_next = 4*(z - d*P)
Bres Vz_next 0 V='4*(V(Vz)-V(Vd)*P_v)'
.ends residue_step

* Accumulator inject: if en>0.5 add inc to Vy
.subckt accum_inject Vy Vy_prev inc en
Bacc Vy 0 V='V(Vy_prev)+((V(en)>0.5)?V(inc):0)'
.ends accum_inject
