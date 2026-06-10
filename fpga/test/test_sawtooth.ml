(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open OUnit2

let test_wrap_period _ctx =
  let t = Pause_sim.create () in
  Pause_sim.wait_wrap t;
  for i = 1 to Params.m do
    Pause_sim.step t;
    assert_equal i (Pause_sim.saw_phase t)
  done;
  Pause_sim.step t;
  assert_equal 0 (Pause_sim.saw_phase t)

let () =
  run_test_tt_main ("sawtooth" >::: [ "wrap_period" >:: test_wrap_period ])
