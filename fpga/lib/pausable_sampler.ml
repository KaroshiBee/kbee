(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

(** HardCaml — pausable sampler / lag (synthesizable). *)

open Hardcaml
open Signal
open Params

module I_pre = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; phase : 'a
    ; enable : 'a
    }
  [@@deriving sexp_of]

  let map t ~f =
    { clock = f t.clock
    ; clear = f t.clear
    ; phase = f t.phase
    ; enable = f t.enable
    }

  let iter t ~f =
    f t.clock;
    f t.clear;
    f t.phase;
    f t.enable

  let iter2 a b ~f =
    f a.clock b.clock;
    f a.clear b.clear;
    f a.phase b.phase;
    f a.enable b.enable

  let map2 a b ~f =
    { clock = f a.clock b.clock
    ; clear = f a.clear b.clear
    ; phase = f a.phase b.phase
    ; enable = f a.enable b.enable
    }

  let to_list t = [ t.clock; t.clear; t.phase; t.enable ]

  let port_names_and_widths =
    { clock = ("clock", 1)
    ; clear = ("clear", 1)
    ; phase = ("phase", phase_bits)
    ; enable = ("enable", 1)
    }
end

module O_pre = struct
  type 'a t = { lag : 'a } [@@deriving sexp_of]
  let map t ~f = { lag = f t.lag }
  let iter t ~f = f t.lag
  let iter2 a b ~f = f a.lag b.lag
  let map2 a b ~f = { lag = f a.lag b.lag }
  let to_list t = [ t.lag ]
  let port_names_and_widths = { lag = ("lag", phase_bits) }
end

module Iface_in = struct
  include Interface.Make (I_pre)
  type 'a t = 'a I_pre.t
end

module Iface_out = struct
  include Interface.Make (O_pre)
  type 'a t = 'a O_pre.t
end

let create ({ clock; clear; phase; enable } : Signal.t I_pre.t) =
  let spec = Reg_spec.create ~clock ~clear () in
  let ptr = reg_fb spec ~width:phase_bits ~f:(fun q -> mux2 enable phase q) in
  let saw_lt_ptr = phase <: ptr in
  let lag_if_ge = phase -: ptr in
  let m_const = of_int ~width:phase_bits m in
  let lag_if_lt = phase +:(m_const -: ptr) +:. 1 in
  let lag = mux2 saw_lt_ptr lag_if_lt lag_if_ge in
  ({ lag } : Signal.t O_pre.t)
;;

include Circuit.With_interface (Iface_in) (Iface_out)
