(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Hardcaml
open Hardcaml.Cyclesim

module Sim =
  Cyclesim.With_interface (Kbee_cell.Iface_in) (Kbee_cell.Iface_out)

let unsigned_of_bits b = Bits.to_int b

let run_cell ~x ~y =
  let sim = Sim.create Kbee_cell.create in
  let inputs = inputs sim in
  let outputs = outputs sim in
  let w = Params.phase_bits in
  inputs.clear := Bits.vdd;
  cycle sim;
  inputs.clear := Bits.gnd;
  inputs.x := Bits.of_int ~width:w x;
  inputs.y := Bits.of_int ~width:w y;
  inputs.start := Bits.gnd;
  cycle sim;
  inputs.start := Bits.vdd;
  cycle sim;
  inputs.start := Bits.gnd;
  let rec spin n =
    if n = 0 then failwith "Kbee_cell simulation timeout"
    else (
      cycle sim;
      if Bits.to_bool !(outputs.done_) then ()
      else spin (n - 1))
  in
  spin 50_000_000;
  ( unsigned_of_bits !(outputs.a_nor)
  , unsigned_of_bits !(outputs.a_xor)
  , unsigned_of_bits !(outputs.a_and) )
;;
