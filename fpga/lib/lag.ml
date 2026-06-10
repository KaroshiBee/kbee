(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Params

(** Pure-OCaml lag arithmetic (reference for tests and oracle stepping). *)

let lag_mod (saw : int) (ptr : int) : int =
  let d = saw - ptr in
  if d >= 0 then d else d + p

let classify (v : int) : [`Nor | `Xor | `And] =
  if v < one_n then `Nor
  else if v < two_n then `Xor
  else `And

let oracle_residue_step (z : int) (digit : [`Nor | `Xor | `And]) : int =
  match digit with
  | `Nor -> 3 * z
  | `Xor -> 3 * (z - one_n)
  | `And -> 3 * (z - two_n)

let pause_triple_ref (z : int) = (z + z + z) mod p

let norandxor_codes (x : int) (y : int) : int * int * int =
  let nor = ref 0 in
  let xor = ref 0 in
  let and_ = ref 0 in
  let z = ref (x + y) in
  let inc = ref one_n in
  for _ = 0 to w - 1 do
    let v = !z in
    (match classify v with
     | `Nor -> nor := !nor + !inc
     | `Xor -> xor := !xor + !inc
     | `And -> and_ := !and_ + !inc);
    z := pause_triple_ref v;
    inc := !inc / 3
  done;
  (!nor, !xor, !and_)
