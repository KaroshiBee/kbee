-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Kbee.Algorithm
import Kbee.Encode
import Mathlib

namespace Kbee.Examples

open Kbee

/-! ## §5.1 — base-3, `W = 8` bounds -/

example : R 3 8 = 3280 := by decide
example : 3 ^ 8 = 6561 := by decide
example : P 3 8 = 2187 := by decide

/-! ## §5.4 — concrete two-input example (`10011100₃`, `11010010₃`) -/

/-- MSB-first digits for `x = 10011100₃` (doc §5.4). -/
def doc534_x : Fin 8 → ℕ := ![1, 0, 0, 1, 1, 1, 0, 0]

/-- MSB-first digits for `y = 11010010₃`. -/
def doc534_y : Fin 8 → ℕ := ![1, 1, 0, 1, 0, 0, 1, 0]

def doc534_xs : ℕ → ℕ → ℕ := xsPair doc534_x doc534_y

example : valMSB8 3 doc534_x = 2304 := by decide
example : valMSB8 3 doc534_y = 3000 := by decide
example : columnSumPair 3 doc534_x doc534_y = 5304 := by decide
example : columnSumPair 3 doc534_x doc534_y < 3 ^ 8 := by decide

/-- Gate outputs as place-value codes (doc §5.4 MSB-first strings). -/
example : norColumnVal doc534_xs 2 = 244 := by decide
example : xorColumnVal doc534_xs 2 = 768 := by decide
example : andColumnVal doc534_xs 2 = 2268 := by decide
example : xnorColumnVal doc534_xs 2 = 2512 := by decide

/-- §5.3 one-hot invariant: `nor + xor + and = 11111111₃ = 3280`. -/
example :
    norColumnVal doc534_xs 2 + xorColumnVal doc534_xs 2 + andColumnVal doc534_xs 2 = 3280 := by
  decide

/-! ## Reference CSV corners — `(x_bin, y_bin) = (0, 0)` and `(255, 255)` -/

def cornerZero : Fin 8 → ℕ := ![0, 0, 0, 0, 0, 0, 0, 0]
def cornerOnes : Fin 8 → ℕ := ![1, 1, 1, 1, 1, 1, 1, 1]

def cornerZero_xs : ℕ → ℕ → ℕ := xsPair cornerZero cornerZero
def cornerOnes_xs : ℕ → ℕ → ℕ := xsPair cornerOnes cornerOnes

example : columnSumPair 3 cornerZero cornerZero = 0 := by decide
example : norColumnVal cornerZero_xs 2 = 3280 := by decide
example : xorColumnVal cornerZero_xs 2 = 0 := by decide
example : andColumnVal cornerZero_xs 2 = 0 := by decide

example : valMSB8 3 cornerOnes = 3280 := by decide
example : columnSumPair 3 cornerOnes cornerOnes = 6560 := by decide
example : norColumnVal cornerOnes_xs 2 = 0 := by decide
example : xorColumnVal cornerOnes_xs 2 = 0 := by decide
example : andColumnVal cornerOnes_xs 2 = 3280 := by decide

/-! ## §6.1 — base-4 bounds -/

example : R 4 8 = 21845 := by decide
example : 4 ^ 8 = 65536 := by decide

/-! ## §6.4 — concrete three-input example -/

def doc644_a : Fin 8 → ℕ := ![1, 0, 0, 1, 1, 1, 0, 0]
def doc644_b : Fin 8 → ℕ := ![1, 1, 0, 1, 0, 0, 1, 0]
def doc644_c : Fin 8 → ℕ := ![1, 0, 0, 0, 1, 0, 1, 0]

def doc644_xs : ℕ → ℕ → ℕ := xsTriple doc644_a doc644_b doc644_c

example : valMSB8 4 doc644_a = 16720 := by decide
example : valMSB8 4 doc644_b = 20740 := by decide
example : valMSB8 4 doc644_c = 16452 := by decide
example : columnSumTriple 4 doc644_a doc644_b doc644_c = 53912 := by decide
example : columnSumTriple 4 doc644_a doc644_b doc644_c < 4 ^ 8 := by decide

example : norColumnVal4 doc644_xs = 1025 := by decide
example : xorColumnVal4 doc644_xs = 20496 := by decide
example : andColumnVal4 doc644_xs = 16384 := by decide
example : xnorColumnVal4 doc644_xs = 1349 := by decide

/-! ## Algorithm theorems on doc §5.4 inputs -/

private def validPairInputs (x y : Fin 8 → ℕ) : Prop :=
  ∀ i < 2, isValidInput 3 8 (fun k => xsPair x y i k)

private lemma validPairInputs_of (x y : Fin 8 → ℕ)
    (h : ∀ i : Fin 2, ∀ k : Fin 8, xsPair x y i k = 0 ∨ xsPair x y i k = 1) :
    validPairInputs x y := by
  intro i hi k hk
  exact h ⟨i, hi⟩ ⟨k, hk⟩

private lemma validPairInputs_doc534 : validPairInputs doc534_x doc534_y := by
  refine validPairInputs_of _ _ ?_
  intro i k
  fin_cases i <;> fin_cases k <;>
    simp [xsPair, digitMSB8, doc534_x, doc534_y]

example : validPairInputs doc534_x doc534_y :=
  validPairInputs_doc534

example :
    acc_seq 3 nor_gate (extracted_digits 3 8 (columnSumPair 3 doc534_x doc534_y)) 8 =
      val 3 8 (fun k => nor_gate (s doc534_xs k 2)) := by
  have h_valid : ∀ i < 2, isValidInput 3 8 (fun k => doc534_xs i k) := by
    intro i hi k hk
    simpa [doc534_xs] using validPairInputs_doc534 i hi k hk
  have hz : columnSumPair 3 doc534_x doc534_y =
      columnSum 3 8 (fun k => s doc534_xs k 2) := rfl
  exact nor_accumulator_correctness (by decide) (by decide) doc534_xs 2 rfl h_valid _ hz

end Kbee.Examples
