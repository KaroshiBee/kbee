(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

(** Cycle-sim harness for {!Kbee_system} — not oracle code. *)

open Hardcaml
open Hardcaml.Cyclesim

module Sim =
  Cyclesim.With_interface (Kbee_system.Iface_in) (Kbee_system.Iface_out)

let unsigned_of_bits b = Bits.to_int b

let wait_done outputs field ~sim ~timeout =
  let rec spin n =
    if n = 0 then failwith "Kbee_system simulation timeout"
    else (
      cycle sim;
      if Bits.to_bool !(field outputs) then ()
      else spin (n - 1))
  in
  spin timeout

let run_two_cells ~x0 ~y0 ~x1 ~y1 =
  let sim = Sim.create Kbee_system.create in
  let inputs = inputs sim in
  let outputs = outputs sim in
  let w = Params.phase_bits in
  inputs.clear := Bits.vdd;
  cycle sim;
  inputs.clear := Bits.gnd;
  inputs.c0_x := Bits.of_int ~width:w x0;
  inputs.c0_y := Bits.of_int ~width:w y0;
  inputs.c1_x := Bits.of_int ~width:w x1;
  inputs.c1_y := Bits.of_int ~width:w y1;
  inputs.c0_start := Bits.gnd;
  inputs.c1_start := Bits.gnd;
  cycle sim;
  inputs.c0_start := Bits.vdd;
  cycle sim;
  inputs.c0_start := Bits.gnd;
  wait_done outputs (fun o -> o.c0_done_) ~sim ~timeout:50_000_000;
  inputs.c1_start := Bits.vdd;
  cycle sim;
  inputs.c1_start := Bits.gnd;
  wait_done outputs (fun o -> o.c1_done_) ~sim ~timeout:50_000_000;
  ( ( unsigned_of_bits !(outputs.c0_a_nor)
    , unsigned_of_bits !(outputs.c0_a_xor)
    , unsigned_of_bits !(outputs.c0_a_and) )
  , ( unsigned_of_bits !(outputs.c1_a_nor)
    , unsigned_of_bits !(outputs.c1_a_xor)
    , unsigned_of_bits !(outputs.c1_a_and) ) )
;;
