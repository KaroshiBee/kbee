(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Lag

let pause_add_ref x y =
  let t = Pause_sim.create () in
  Pause_sim.wait_wrap t;
  Pause_sim.pause_add_xy t x y;
  Pause_sim.sample_residue t

let pause_triple_ref z =
  let t = Pause_sim.create () in
  Pause_sim.setup_residue_lag t z;
  ignore (Pause_sim.pause_triple_residue t);
  Pause_sim.sample_residue t

let oracle_residue_via_triple z =
  let digit = classify z in
  oracle_residue_step z digit, pause_triple_ref z
