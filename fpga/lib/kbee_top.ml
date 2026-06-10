(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

(** HardCaml — one kbee cell on a dedicated master sawtooth (synthesizable).

    Convenience wrapper when the chip has only one cell. For several cells use
    {!Kbee_system} instead. *)

open Hardcaml
open Params

module I_pre = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; x : 'a
    ; y : 'a
    }
  [@@deriving sexp_of]

  let map t ~f =
    { clock = f t.clock
    ; clear = f t.clear
    ; start = f t.start
    ; x = f t.x
    ; y = f t.y
    }

  let iter t ~f =
    f t.clock;
    f t.clear;
    f t.start;
    f t.x;
    f t.y

  let iter2 a b ~f =
    f a.clock b.clock;
    f a.clear b.clear;
    f a.start b.start;
    f a.x b.x;
    f a.y b.y

  let map2 a b ~f =
    { clock = f a.clock b.clock
    ; clear = f a.clear b.clear
    ; start = f a.start b.start
    ; x = f a.x b.x
    ; y = f a.y b.y
    }

  let to_list t = [ t.clock; t.clear; t.start; t.x; t.y ]

  let port_names_and_widths =
    { clock = ("clock", 1)
    ; clear = ("clear", 1)
    ; start = ("start", 1)
    ; x = ("x", phase_bits)
    ; y = ("y", phase_bits)
    }
end

module O_pre = Kbee_cell.O_pre

module Iface_in = struct
  include Interface.Make (I_pre)
  type 'a t = 'a I_pre.t
end

module Iface_out = struct
  include Interface.Make (O_pre)
  type 'a t = 'a O_pre.t
end

let create (inputs : Signal.t I_pre.t) =
  let saw = Sawtooth.create { clock = inputs.clock; clear = inputs.clear } in
  Kbee_cell.create
    { clock = inputs.clock
    ; clear = inputs.clear
    ; phase = saw.phase
    ; wrap = saw.wrap
    ; start = inputs.start
    ; x = inputs.x
    ; y = inputs.y
    }
;;

include Circuit.With_interface (Iface_in) (Iface_out)
