(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Base
open OUnit2

let test_sum_exhaustive _ctx =
  for x = 0 to Params.cutoff do
    for y = 0 to Params.cutoff do
      assert_equal (x + y) (Pause_primitives.pause_add_ref x y)
    done
  done

let () = run_test_tt_main ("kbee_sum" >::: [ "exhaustive" >:: test_sum_exhaustive ])
