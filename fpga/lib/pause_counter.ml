(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

(** Pause-for-n countdown helper used by the top-level cell FSM. *)

type t =
  { mutable remaining : int
  ; mutable busy : bool
  }

let idle () = { remaining = 0; busy = false }

let start t n =
  t.remaining <- n;
  t.busy <- true

let tick t =
  if t.busy then (
    if t.remaining <= 0 then t.busy <- false
    else t.remaining <- t.remaining - 1)

let is_done t = t.busy && t.remaining <= 0
let is_busy t = t.busy
