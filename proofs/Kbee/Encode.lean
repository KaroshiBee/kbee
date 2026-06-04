-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Kbee.BaseN
import Kbee.Helpers
import Mathlib

namespace Kbee

/-- MSB-first digit table: index `0` is the most significant digit. -/
def digitMSB8 (ds : Fin 8 → ℕ) (k : ℕ) : ℕ :=
  if hk : k < 8 then ds ⟨8 - 1 - k, by omega⟩ else 0

/-- Two `{0,1}` inputs as per-position digit functions. -/
def xsPair (x y : Fin 8 → ℕ) : ℕ → ℕ → ℕ
  | 0, k => digitMSB8 x k
  | 1, k => digitMSB8 y k
  | _, _ => 0

/-- Three `{0,1}` inputs (base-4 doc example). -/
def xsTriple (a b c : Fin 8 → ℕ) : ℕ → ℕ → ℕ
  | 0, k => digitMSB8 a k
  | 1, k => digitMSB8 b k
  | 2, k => digitMSB8 c k
  | _, _ => 0

def valMSB8 (N : ℕ) (ds : Fin 8 → ℕ) : ℕ :=
  val N 8 (digitMSB8 ds)

def columnSumPair (N : ℕ) (x y : Fin 8 → ℕ) : ℕ :=
  columnSum N 8 (fun k => s (xsPair x y) k 2)

def columnSumTriple (N : ℕ) (a b c : Fin 8 → ℕ) : ℕ :=
  columnSum N 8 (fun k => s (xsTriple a b c) k 3)

def gateColumnVal (N W M : ℕ) (xs : ℕ → ℕ → ℕ) (gate : ℕ → ℕ) : ℕ :=
  val N W (fun k => gate (s xs k M))

def norColumnVal (xs : ℕ → ℕ → ℕ) (M : ℕ) : ℕ :=
  gateColumnVal 3 8 M xs nor_gate

def andColumnVal (xs : ℕ → ℕ → ℕ) (M : ℕ) : ℕ :=
  val 3 8 (fun k => and_gate (s xs k M) M)

def xorColumnVal (xs : ℕ → ℕ → ℕ) (M : ℕ) : ℕ :=
  gateColumnVal 3 8 M xs xor_gate

def xnorColumnVal (xs : ℕ → ℕ → ℕ) (M : ℕ) : ℕ :=
  gateColumnVal 3 8 M xs xnor_gate

def norColumnVal4 (xs : ℕ → ℕ → ℕ) : ℕ :=
  gateColumnVal 4 8 3 xs nor_gate

def andColumnVal4 (xs : ℕ → ℕ → ℕ) : ℕ :=
  val 4 8 (fun k => and_gate (s xs k 3) 3)

def xorColumnVal4 (xs : ℕ → ℕ → ℕ) : ℕ :=
  gateColumnVal 4 8 3 xs xor_gate

def xnorColumnVal4 (xs : ℕ → ℕ → ℕ) : ℕ :=
  gateColumnVal 4 8 3 xs xnor_gate

end Kbee
