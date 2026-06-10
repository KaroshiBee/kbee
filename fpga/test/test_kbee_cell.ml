(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Base
open OUnit2

let csv_path = "../../../../data/kbee-w8-refs.csv"

let parse_row line =
  let cols = String.split line ~on:',' in
  Int.of_string (List.nth_exn cols 2),
  Int.of_string (List.nth_exn cols 3),
  Int.of_string (List.nth_exn cols 30),
  Int.of_string (List.nth_exn cols 31),
  Int.of_string (List.nth_exn cols 32)

let test_pause_sim_csv _ctx =
  let ic = Stdlib.open_in csv_path in
  (try
     ignore (Stdlib.input_line ic);
     let row = ref 0 in
     (try
        while true do
          let line = Stdlib.input_line ic in
          let x, y, nor, xor, and_ = parse_row line in
          let sn, sx, sa = Pause_sim.run_cell ~x ~y () in
          assert_equal ~printer:Int.to_string nor sn
            ~msg:(Printf.sprintf "row %d nor" !row);
          assert_equal ~printer:Int.to_string xor sx
            ~msg:(Printf.sprintf "row %d xor" !row);
          assert_equal ~printer:Int.to_string and_ sa
            ~msg:(Printf.sprintf "row %d and" !row);
          Int.incr row
        done
      with
      | End_of_file -> ())
   with
   exn ->
     Stdlib.close_in_noerr ic;
     raise exn);
  Stdlib.close_in ic

let test_hardcaml_corners _ctx =
  let cases =
    [ (0, 0, 3280, 0, 0)
    ; (3280, 3280, 0, 0, 3280)
    ; (1, 1, 3279, 0, 1)
    ; (100, 200, 3007, 246, 27)
    ]
  in
  List.iter cases ~f:(fun (x, y, nor, xor, and_) ->
    let sn, sx, sa = Sim_util.run_cell ~x ~y in
    assert_equal nor sn;
    assert_equal xor sx;
    assert_equal and_ sa)

let test_hardcaml_vs_pause_sim _ctx =
  for x = 0 to 64 do
    for y = 0 to 64 do
      let ref_n, ref_x, ref_a = Pause_sim.run_cell ~x ~y () in
      let hw_n, hw_x, hw_a = Sim_util.run_cell ~x ~y in
      assert_equal ref_n hw_n;
      assert_equal ref_x hw_x;
      assert_equal ref_a hw_a
    done
  done

let () =
  run_test_tt_main
    ("kbee_cell"
     >::: [ "pause_sim_csv" >:: test_pause_sim_csv
          ; "hardcaml_corners" >:: test_hardcaml_corners
          ; "hardcaml_vs_sim" >:: test_hardcaml_vs_pause_sim
          ])
