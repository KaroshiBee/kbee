(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

(** HardCaml — two kbee cells on one master sawtooth (synthesizable).

    Each cell has independent start / operand ports; both share the same
    free-running phase counter. Extend by duplicating cell ports and
    {!cell_on_bus} calls. *)

open Hardcaml
open Params

module Cell_in = struct
  type 'a t =
    { start : 'a
    ; x : 'a
    ; y : 'a
    }
  [@@deriving sexp_of]

  let map t ~f = { start = f t.start; x = f t.x; y = f t.y }

  let iter t ~f =
    f t.start;
    f t.x;
    f t.y

  let iter2 a b ~f =
    f a.start b.start;
    f a.x b.x;
    f a.y b.y

  let map2 a b ~f =
    { start = f a.start b.start; x = f a.x b.x; y = f a.y b.y }
end

module I_pre = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; c0_start : 'a
    ; c0_x : 'a
    ; c0_y : 'a
    ; c1_start : 'a
    ; c1_x : 'a
    ; c1_y : 'a
    }
  [@@deriving sexp_of]

  let map t ~f =
    { clock = f t.clock
    ; clear = f t.clear
    ; c0_start = f t.c0_start
    ; c0_x = f t.c0_x
    ; c0_y = f t.c0_y
    ; c1_start = f t.c1_start
    ; c1_x = f t.c1_x
    ; c1_y = f t.c1_y
    }

  let iter t ~f =
    f t.clock;
    f t.clear;
    f t.c0_start;
    f t.c0_x;
    f t.c0_y;
    f t.c1_start;
    f t.c1_x;
    f t.c1_y

  let iter2 a b ~f =
    f a.clock b.clock;
    f a.clear b.clear;
    f a.c0_start b.c0_start;
    f a.c0_x b.c0_x;
    f a.c0_y b.c0_y;
    f a.c1_start b.c1_start;
    f a.c1_x b.c1_x;
    f a.c1_y b.c1_y

  let map2 a b ~f =
    { clock = f a.clock b.clock
    ; clear = f a.clear b.clear
    ; c0_start = f a.c0_start b.c0_start
    ; c0_x = f a.c0_x b.c0_x
    ; c0_y = f a.c0_y b.c0_y
    ; c1_start = f a.c1_start b.c1_start
    ; c1_x = f a.c1_x b.c1_x
    ; c1_y = f a.c1_y b.c1_y
    }

  let to_list t =
    [ t.clock
    ; t.clear
    ; t.c0_start
    ; t.c0_x
    ; t.c0_y
    ; t.c1_start
    ; t.c1_x
    ; t.c1_y
    ]

  let port_names_and_widths =
    { clock = ("clock", 1)
    ; clear = ("clear", 1)
    ; c0_start = ("c0_start", 1)
    ; c0_x = ("c0_x", phase_bits)
    ; c0_y = ("c0_y", phase_bits)
    ; c1_start = ("c1_start", 1)
    ; c1_x = ("c1_x", phase_bits)
    ; c1_y = ("c1_y", phase_bits)
    }
end

module O_pre = struct
  type 'a t =
    { c0_busy : 'a
    ; c0_done_ : 'a
    ; c0_a_nor : 'a
    ; c0_a_xor : 'a
    ; c0_a_and : 'a
    ; c1_busy : 'a
    ; c1_done_ : 'a
    ; c1_a_nor : 'a
    ; c1_a_xor : 'a
    ; c1_a_and : 'a
    }
  [@@deriving sexp_of]

  let map t ~f =
    { c0_busy = f t.c0_busy
    ; c0_done_ = f t.c0_done_
    ; c0_a_nor = f t.c0_a_nor
    ; c0_a_xor = f t.c0_a_xor
    ; c0_a_and = f t.c0_a_and
    ; c1_busy = f t.c1_busy
    ; c1_done_ = f t.c1_done_
    ; c1_a_nor = f t.c1_a_nor
    ; c1_a_xor = f t.c1_a_xor
    ; c1_a_and = f t.c1_a_and
    }

  let iter t ~f =
    f t.c0_busy;
    f t.c0_done_;
    f t.c0_a_nor;
    f t.c0_a_xor;
    f t.c0_a_and;
    f t.c1_busy;
    f t.c1_done_;
    f t.c1_a_nor;
    f t.c1_a_xor;
    f t.c1_a_and

  let iter2 a b ~f =
    f a.c0_busy b.c0_busy;
    f a.c0_done_ b.c0_done_;
    f a.c0_a_nor b.c0_a_nor;
    f a.c0_a_xor b.c0_a_xor;
    f a.c0_a_and b.c0_a_and;
    f a.c1_busy b.c1_busy;
    f a.c1_done_ b.c1_done_;
    f a.c1_a_nor b.c1_a_nor;
    f a.c1_a_xor b.c1_a_xor;
    f a.c1_a_and b.c1_a_and

  let map2 a b ~f =
    { c0_busy = f a.c0_busy b.c0_busy
    ; c0_done_ = f a.c0_done_ b.c0_done_
    ; c0_a_nor = f a.c0_a_nor b.c0_a_nor
    ; c0_a_xor = f a.c0_a_xor b.c0_a_xor
    ; c0_a_and = f a.c0_a_and b.c0_a_and
    ; c1_busy = f a.c1_busy b.c1_busy
    ; c1_done_ = f a.c1_done_ b.c1_done_
    ; c1_a_nor = f a.c1_a_nor b.c1_a_nor
    ; c1_a_xor = f a.c1_a_xor b.c1_a_xor
    ; c1_a_and = f a.c1_a_and b.c1_a_and
    }

  let to_list t =
    [ t.c0_busy
    ; t.c0_done_
    ; t.c0_a_nor
    ; t.c0_a_xor
    ; t.c0_a_and
    ; t.c1_busy
    ; t.c1_done_
    ; t.c1_a_nor
    ; t.c1_a_xor
    ; t.c1_a_and
    ]

  let port_names_and_widths =
    { c0_busy = ("c0_busy", 1)
    ; c0_done_ = ("c0_done_", 1)
    ; c0_a_nor = ("c0_a_nor", phase_bits)
    ; c0_a_xor = ("c0_a_xor", phase_bits)
    ; c0_a_and = ("c0_a_and", phase_bits)
    ; c1_busy = ("c1_busy", 1)
    ; c1_done_ = ("c1_done_", 1)
    ; c1_a_nor = ("c1_a_nor", phase_bits)
    ; c1_a_xor = ("c1_a_xor", phase_bits)
    ; c1_a_and = ("c1_a_and", phase_bits)
    }
end

module Iface_in = struct
  include Interface.Make (I_pre)
  type 'a t = 'a I_pre.t
end

module Iface_out = struct
  include Interface.Make (O_pre)
  type 'a t = 'a O_pre.t
end

let cell_on_bus ~clock ~clear ~phase ~wrap ({ start; x; y } : Signal.t Cell_in.t) =
  Kbee_cell.create { clock; clear; phase; wrap; start; x; y }
;;

let create (inputs : Signal.t I_pre.t) =
  let clock = inputs.clock in
  let clear = inputs.clear in
  let saw = Sawtooth.create { clock; clear } in
  let phase = saw.phase in
  let wrap = saw.wrap in
  let c0 =
    cell_on_bus ~clock ~clear ~phase ~wrap
      { start = inputs.c0_start; x = inputs.c0_x; y = inputs.c0_y }
  in
  let c1 =
    cell_on_bus ~clock ~clear ~phase ~wrap
      { start = inputs.c1_start; x = inputs.c1_x; y = inputs.c1_y }
  in
  ({ c0_busy = c0.busy
   ; c0_done_ = c0.done_
   ; c0_a_nor = c0.a_nor
   ; c0_a_xor = c0.a_xor
   ; c0_a_and = c0.a_and
   ; c1_busy = c1.busy
   ; c1_done_ = c1.done_
   ; c1_a_nor = c1.a_nor
   ; c1_a_xor = c1.a_xor
   ; c1_a_and = c1.a_and
   }
    : Signal.t O_pre.t)
;;

include Circuit.With_interface (Iface_in) (Iface_out)
