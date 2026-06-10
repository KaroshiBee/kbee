(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Base
open OUnit2

let test_pause_add_corners _ctx =
  List.iter
    [ (0, 0); (1, 1); (100, 200); (3280, 3280); (3280, 0); (0, 3280) ]
    ~f:(fun (x, y) ->
      assert_equal (x + y) (Pause_primitives.pause_add_ref x y))

let test_pause_triple_ranges _ctx =
  let check z expected =
    assert_equal expected (Pause_primitives.pause_triple_ref z)
  in
  check 100 (Int.rem 300 Params.p);
  check 2186 (Int.rem 6558 Params.p);
  check 2187 0;
  check 3000 (Int.rem (3 * (3000 - Params.one_n)) Params.p);
  check 5000 (Int.rem (3 * (5000 - Params.two_n)) Params.p);
  check 6560 (Int.rem (3 * (6560 - Params.two_n)) Params.p)

let test_triple_matches_oracle _ctx =
  for z = 0 to Params.m do
    let oracle, triple = Pause_primitives.oracle_residue_via_triple z in
    assert_equal oracle triple
  done

let () =
  run_test_tt_main
    ("pause"
     >::: [ "pause_add" >:: test_pause_add_corners
          ; "pause_triple" >:: test_pause_triple_ranges
          ; "triple_oracle" >:: test_triple_matches_oracle
          ])
