(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Oracle_lag

(** ORACLE — test helpers over {!Oracle_pause_sim}. *)

let pause_add_ref x y =
  let t = Oracle_pause_sim.create () in
  Oracle_pause_sim.wait_wrap t;
  Oracle_pause_sim.pause_add_xy t x y;
  Oracle_pause_sim.sample_residue t

let pause_triple_ref z =
  let t = Oracle_pause_sim.create () in
  Oracle_pause_sim.setup_residue_lag t z;
  ignore (Oracle_pause_sim.pause_triple_residue t);
  Oracle_pause_sim.sample_residue t

let oracle_residue_via_triple z =
  let digit = classify z in
  oracle_residue_step z digit, pause_triple_ref z
