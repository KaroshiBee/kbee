-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Kbee.BaseN
import Kbee.Helpers
import Kbee.Residue
import Mathlib

namespace Kbee

open Finset

lemma nor_gate_binary (d : ℕ) : nor_gate d = 0 ∨ nor_gate d = 1 := by
  dsimp [nor_gate]
  split <;> simp

lemma and_gate_binary (d M : ℕ) : and_gate d M = 0 ∨ and_gate d M = 1 := by
  dsimp [and_gate]
  split <;> simp

lemma xor_gate_binary (d : ℕ) : xor_gate d = 0 ∨ xor_gate d = 1 := by
  dsimp [xor_gate]
  split <;> simp

lemma xnor_gate_binary (d : ℕ) : xnor_gate d = 0 ∨ xnor_gate d = 1 := by
  dsimp [xnor_gate]
  split <;> simp

/-- Residue-extracted digits used as accumulator inputs. -/
def extracted_digits (N W : ℕ) (z_0 : ℕ) : ℕ → ℕ :=
  fun t => d_t N W (residue_seq N W z_0 t)

/-- Generic gate accumulator: place-value output equals digitwise gate applied to column sums. -/
lemma gate_accumulator_correctness {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (z_0 : ℕ)
    (hz : z_0 = columnSum N W (fun k => s xs k M)) (out_d : ℕ → ℕ) :
    acc_seq N out_d (extracted_digits N W z_0) W =
      val N W (fun k => out_d (s xs k M)) := by
  rw [accumulator_correctness hN hW out_d (extracted_digits N W z_0)]
  refine sum_congr rfl fun k hk => ?_
  congr 1
  have hk' := mem_range.mp hk
  have hkle : k ≤ W - 1 := by omega
  have ht : W - 1 - k < W := by omega
  rw [extracted_digits]
  rw [(residue_extraction_correctness hN hW xs M hM h_valid z_0 hz (W - 1 - k) ht).1]
  congr 1
  rw [Nat.sub_sub_self hkle]

lemma nor_accumulator_correctness {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (z_0 : ℕ)
    (hz : z_0 = columnSum N W (fun k => s xs k M)) :
    acc_seq N nor_gate (extracted_digits N W z_0) W =
      val N W (fun k => nor_gate (s xs k M)) :=
  gate_accumulator_correctness hN hW xs M hM h_valid z_0 hz nor_gate

lemma and_accumulator_correctness {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (z_0 : ℕ)
    (hz : z_0 = columnSum N W (fun k => s xs k M)) :
    acc_seq N (fun d => and_gate d M) (extracted_digits N W z_0) W =
      val N W (fun k => and_gate (s xs k M) M) :=
  gate_accumulator_correctness hN hW xs M hM h_valid z_0 hz (fun d => and_gate d M)

lemma xor_accumulator_correctness {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (z_0 : ℕ)
    (hz : z_0 = columnSum N W (fun k => s xs k M)) :
    acc_seq N xor_gate (extracted_digits N W z_0) W =
      val N W (fun k => xor_gate (s xs k M)) :=
  gate_accumulator_correctness hN hW xs M hM h_valid z_0 hz xor_gate

lemma xnor_accumulator_correctness {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (z_0 : ℕ)
    (hz : z_0 = columnSum N W (fun k => s xs k M)) :
    acc_seq N xnor_gate (extracted_digits N W z_0) W =
      val N W (fun k => xnor_gate (s xs k M)) :=
  gate_accumulator_correctness hN hW xs M hM h_valid z_0 hz xnor_gate

lemma nor_output_valid {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (_hM : M = N - 1)
    (_h_valid : ∀ i < M, isValidInput N W (xs i)) :
    isValidInput N W (fun k => nor_gate (s xs k M)) := by
  intro k hk
  exact nor_gate_binary (s xs k M)

lemma and_output_valid {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (_hM : M = N - 1)
    (_h_valid : ∀ i < M, isValidInput N W (xs i)) :
    isValidInput N W (fun k => and_gate (s xs k M) M) := by
  intro k hk
  exact and_gate_binary (s xs k M) M

lemma xor_output_valid {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (_hM : M = N - 1)
    (_h_valid : ∀ i < M, isValidInput N W (xs i)) :
    isValidInput N W (fun k => xor_gate (s xs k M)) := by
  intro k hk
  exact xor_gate_binary (s xs k M)

lemma xnor_output_valid {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (_hM : M = N - 1)
    (_h_valid : ∀ i < M, isValidInput N W (xs i)) :
    isValidInput N W (fun k => xnor_gate (s xs k M)) := by
  intro k hk
  exact xnor_gate_binary (s xs k M)

end Kbee
