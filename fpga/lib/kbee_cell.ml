(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Copyright (c) 2026 Karoshibee LTD *)

open Hardcaml
open Signal
open Always
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

module O_pre = struct
  type 'a t =
      { busy : 'a
      ; done_ : 'a
      ; a_nor : 'a
      ; a_xor : 'a
      ; a_and : 'a
      }
    [@@deriving sexp_of]

    let map t ~f =
      { busy = f t.busy
      ; done_ = f t.done_
      ; a_nor = f t.a_nor
      ; a_xor = f t.a_xor
      ; a_and = f t.a_and
      }

    let iter t ~f =
      f t.busy;
      f t.done_;
      f t.a_nor;
      f t.a_xor;
      f t.a_and

    let iter2 a b ~f =
      f a.busy b.busy;
      f a.done_ b.done_;
      f a.a_nor b.a_nor;
      f a.a_xor b.a_xor;
      f a.a_and b.a_and

    let map2 a b ~f =
      { busy = f a.busy b.busy
      ; done_ = f a.done_ b.done_
      ; a_nor = f a.a_nor b.a_nor
      ; a_xor = f a.a_xor b.a_xor
      ; a_and = f a.a_and b.a_and
      }

    let to_list t = [ t.busy; t.done_; t.a_nor; t.a_xor; t.a_and ]

    let port_names_and_widths =
      { busy = ("busy", 1)
      ; done_ = ("done_", 1)
      ; a_nor = ("a_nor", phase_bits)
      ; a_xor = ("a_xor", phase_bits)
      ; a_and = ("a_and", phase_bits)
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

let u n = of_int ~width:phase_bits n

let add_mod a b =
  let sum = (gnd @: a) +: (gnd @: b) in
  let p_ext = gnd @: u p in
  let modded = mux2 (sum >=: p_ext) (sum -: p_ext) sum in
  select modded 12 0

let create (inputs : Signal.t I_pre.t) =
  let clock = inputs.clock in
  let clear = inputs.clear in
  let start = inputs.start in
  let x = inputs.x in
  let y = inputs.y in
  let spec = Reg_spec.create ~clock ~clear () in
  let saw = Sawtooth.create { clock; clear } in
  let residue_enable = wire 1 in
  let _residue =
    Pausable_sampler.create
      { clock; clear; phase = saw.phase; enable = residue_enable }
  in
  let one_n_w = u one_n in
  let two_n_w = u two_n in
  let state = Variable.reg ~width:4 spec in
  let tick = Variable.reg ~width:3 spec in
  let countdown = Variable.reg ~width:phase_bits spec in
  let residue_z = Variable.reg ~width:phase_bits spec in
  let v_lat = Variable.reg ~width:phase_bits spec in
  let a_nor = Variable.reg ~width:phase_bits spec in
  let a_xor = Variable.reg ~width:phase_bits spec in
  let a_and = Variable.reg ~width:phase_bits spec in
  let state_sig = state.value in
  let tick_sig = tick.value in
  let countdown_sig = countdown.value in
  let residue_z_sig = residue_z.value in
  let v_lat_sig = v_lat.value in
  let a_nor_sig = a_nor.value in
  let a_xor_sig = a_xor.value in
  let a_and_sig = a_and.value in
  let is_nor = v_lat_sig <: one_n_w in
  let is_xor = (v_lat_sig >=: one_n_w) &: (v_lat_sig <: two_n_w) in
  let is_and = v_lat_sig >=: two_n_w in
  let inc_for_tick =
    mux tick_sig (List.map (fun v -> u v) (Array.to_list inc_schedule))
  in
  let start_d = reg spec ~enable:vdd start in
  let go = start &: ~:start_d in
  let st_idle = state_sig ==:. 0 in
  let st_wait = state_sig ==:. 1 in
  let st_px = state_sig ==:. 2 in
  let st_py = state_sig ==:. 3 in
  let st_sample = state_sig ==:. 4 in
  let st_pacc = state_sig ==:. 5 in
  let st_pt1 = state_sig ==:. 6 in
  let st_pt2 = state_sig ==:. 7 in
  let st_done = state_sig ==:. 8 in
  let cd0 = countdown_sig ==: zero phase_bits in
  let residue_unpaused = st_wait &: ~:(saw.wrap) in
  assign residue_enable residue_unpaused;
  compile
    [ when_
        go
        [ state <--. 1
        ; tick <--. 0
        ; residue_z <--. 0
        ; a_nor <--. 0
        ; a_xor <--. 0
        ; a_and <--. 0
        ]
    ; when_
        st_wait
        [ if_ saw.wrap [ state <--. 2; countdown <-- x ] [] ]
    ; when_
        st_px
        [ if_ cd0
            [ state <--. 3
            ; countdown <-- y
            ; residue_z <-- add_mod residue_z_sig x
            ]
            [ countdown <-- countdown_sig -:. 1 ]
        ]
    ; when_
        st_py
        [ if_ cd0
            [ state <--. 4
            ; tick <--. 0
            ; residue_z <-- add_mod residue_z_sig y
            ]
            [ countdown <-- countdown_sig -:. 1 ]
        ]
    ; when_
        st_sample
        [ v_lat <-- residue_z_sig
        ; state <--. 5
        ; countdown <-- inc_for_tick
        ]
    ; when_
        st_pacc
        [ if_ cd0
            [ state <--. 6
            ; countdown <-- v_lat_sig
            ; if_ is_nor [ a_nor <-- a_nor_sig +: inc_for_tick ] []
            ; if_ is_xor [ a_xor <-- a_xor_sig +: inc_for_tick ] []
            ; if_ is_and [ a_and <-- a_and_sig +: inc_for_tick ] []
            ]
            [ countdown <-- countdown_sig -:. 1 ]
        ]
    ; when_
        st_pt1
        [ if_ cd0
            [ state <--. 7
            ; countdown <-- v_lat_sig
            ; residue_z <-- add_mod residue_z_sig v_lat_sig
            ]
            [ countdown <-- countdown_sig -:. 1 ]
        ]
    ; when_
        st_pt2
        [ if_ cd0
            [ if_ (tick_sig ==:. 7)
                [ state <--. 8
                ; residue_z <-- add_mod residue_z_sig v_lat_sig
                ]
                [ state <--. 4
                ; tick <-- tick_sig +:. 1
                ; residue_z <-- add_mod residue_z_sig v_lat_sig
                ]
            ]
            [ countdown <-- countdown_sig -:. 1 ]
        ]
    ];
  let busy = ~:st_idle &: ~:st_done in
  ({ busy
   ; done_ = st_done
   ; a_nor = a_nor_sig
   ; a_xor = a_xor_sig
   ; a_and = a_and_sig
   }
    : Signal.t O_pre.t)
;;

include Circuit.With_interface (Iface_in) (Iface_out)
