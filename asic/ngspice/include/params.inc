* SPDX-License-Identifier: CERN-OHL-W-2.0-or-later
* Copyright (c) 2026 Karoshibee LTD
* KBee ASIC pass-1 — include after .param from deck
.param k_scale=1 I_step=50n P_code=64 N_W=256
.param I_step_eff='I_step*k_scale'
.param P_v='P_code'
.param Vth1='P_v'
.param Vth2='2*P_v'
.param Vth3='3*P_v'
