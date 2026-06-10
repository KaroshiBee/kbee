(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Hardcaml
open Signal
open Params

module I_pre = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    }
  [@@deriving sexp_of]

  let map t ~f = { clock = f t.clock; clear = f t.clear }

  let iter t ~f =
    f t.clock;
    f t.clear

  let iter2 a b ~f =
    f a.clock b.clock;
    f a.clear b.clear

  let map2 a b ~f = { clock = f a.clock b.clock; clear = f a.clear b.clear }
  let to_list t = [ t.clock; t.clear ]
  let port_names_and_widths = { clock = ("clock", 1); clear = ("clear", 1) }
end

module O_pre = struct
  type 'a t =
    { phase : 'a
    ; wrap : 'a
    }
  [@@deriving sexp_of]

  let map t ~f = { phase = f t.phase; wrap = f t.wrap }

  let iter t ~f =
    f t.phase;
    f t.wrap

  let iter2 a b ~f =
    f a.phase b.phase;
    f a.wrap b.wrap

  let map2 a b ~f = { phase = f a.phase b.phase; wrap = f a.wrap b.wrap }
  let to_list t = [ t.phase; t.wrap ]
  let port_names_and_widths = { phase = ("phase", phase_bits); wrap = ("wrap", 1) }
end

module Iface_in = struct
  include Interface.Make (I_pre)
  type 'a t = 'a I_pre.t
end

module Iface_out = struct
  include Interface.Make (O_pre)
  type 'a t = 'a O_pre.t
end

let create ({ clock; clear } : Signal.t I_pre.t) =
  let spec = Reg_spec.create ~clock ~clear () in
  let m_const = of_int ~width:phase_bits m in
  let w = width m_const in
  let phase =
    reg_fb spec ~width:w ~f:(fun q ->
      let inc = q +:. 1 in
      mux2 (q ==: m_const) (zero w) inc)
  in
  let wrap = phase ==: zero w in
  ({ phase; wrap } : Signal.t O_pre.t)
;;

include Circuit.With_interface (Iface_in) (Iface_out)
