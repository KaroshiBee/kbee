(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Params
open Oracle_lag

(** ORACLE — cycle-accurate pause machine (plain OCaml reference model).
    Checked against {!Oracle_lag} and [data/kbee-w8-refs.csv]; not HardCaml. *)

type sampler =
  { mutable ptr : int
  ; mutable paused : bool
  }

type t =
  { mutable saw : int
  ; residue : sampler
  ; nor : sampler
  ; xor : sampler
  ; and_ : sampler
  ; mutable residue_z : int
  ; mutable a_nor : int
  ; mutable a_xor : int
  ; mutable a_and : int
  }

let sampler () = { ptr = 0; paused = true }

let create () =
  { saw = 0
  ; residue = sampler ()
  ; nor = sampler ()
  ; xor = sampler ()
  ; and_ = sampler ()
  ; residue_z = 0
  ; a_nor = 0
  ; a_xor = 0
  ; a_and = 0
  }

let saw_phase t = t.saw

let lag_mod_s saw ptr =
  let d = saw - ptr in
  if d >= 0 then d else d + p

let lag_s t s = lag_mod_s t.saw s.ptr

let tick_saw t =
  if t.saw = m then t.saw <- 0 else t.saw <- t.saw + 1

let at_wrap t = t.saw = 0

let step_aux_samplers t =
  if not t.nor.paused then t.nor.ptr <- t.saw;
  if not t.xor.paused then t.xor.ptr <- t.saw;
  if not t.and_.paused then t.and_.ptr <- t.saw

let hold_residue_z t =
  t.residue.ptr <- (t.saw - t.residue_z + p) mod p

let step t =
  tick_saw t;
  step_aux_samplers t;
  hold_residue_z t

let wait_wrap t =
  while not (at_wrap t) do
    step t
  done;
  t.residue.ptr <- 0;
  t.nor.ptr <- 0;
  t.xor.ptr <- 0;
  t.and_.ptr <- 0;
  t.residue.paused <- true;
  t.nor.paused <- true;
  t.xor.paused <- true;
  t.and_.paused <- true;
  t.residue_z <- 0;
  t.a_nor <- 0;
  t.a_xor <- 0;
  t.a_and <- 0

let pause_sampler_for t s n =
  s.paused <- true;
  for _ = 1 to n do
    step t
  done

let pause_residue_for t n =
  t.residue.paused <- true;
  let ptr0 = (t.saw - t.residue_z + p) mod p in
  t.residue.ptr <- ptr0;
  for _ = 1 to n do
    tick_saw t;
    step_aux_samplers t
  done;
  t.residue_z <- (t.residue_z + n) mod p;
  hold_residue_z t

let pause_add_xy t a b =
  pause_residue_for t a;
  pause_residue_for t b

let sample_residue t = t.residue_z

let setup_residue_lag t z =
  t.saw <- z;
  t.residue_z <- z;
  t.residue.ptr <- 0;
  t.residue.paused <- true

let pause_triple_residue t =
  let v = t.residue_z in
  pause_residue_for t v;
  pause_residue_for t v;
  t.residue_z

let accum_pause t digit inc =
  let s =
    match digit with
    | `Nor -> t.nor
    | `Xor -> t.xor
    | `And -> t.and_
  in
  pause_sampler_for t s inc;
  (match digit with
   | `Nor -> t.a_nor <- t.a_nor + inc
   | `Xor -> t.a_xor <- t.a_xor + inc
   | `And -> t.a_and <- t.a_and + inc)

let run_cell ~x ~y () =
  let t = create () in
  wait_wrap t;
  pause_add_xy t x y;
  for k = 0 to w - 1 do
    let v = sample_residue t in
    let digit = classify v in
    accum_pause t digit inc_schedule.(k);
    ignore (pause_triple_residue t)
  done;
  t.a_nor, t.a_xor, t.a_and
