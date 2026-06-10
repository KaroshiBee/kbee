(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

(** Shared W=8 constants (oracle and HardCaml). *)

let w = 8
let m = 6560 (* 3^8 - 1 *)
let p = 6561 (* one sawtooth period *)
let one_n = 2187 (* 3^7 *)
let two_n = 4374 (* 2 * 3^7 *)
let cutoff = 3280 (* max operand code *)
let phase_bits = 13

let inc_schedule =
  [| 2187; 729; 243; 81; 27; 9; 3; 1 |]
