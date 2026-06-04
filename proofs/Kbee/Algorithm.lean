-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Kbee.BaseN
import Kbee.Helpers
import Kbee.Residue
import Kbee.Gates
import Mathlib

namespace Kbee

open Finset

/-- Full NOR path: carry-free sum, MSB-first digit extraction, binary output digits. -/
theorem nor_algorithm {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) :
    let z_0 := columnSum N W (fun k => s xs k M)
    acc_seq N nor_gate (extracted_digits N W z_0) W =
      val N W (fun k => nor_gate (s xs k M)) ∧
      isValidInput N W (fun k => nor_gate (s xs k M)) ∧
      z_0 = ∑ i ∈ range M, val N W (xs i) ∧ z_0 < N ^ W := by
  intro z_0
  have hz : z_0 = columnSum N W (fun k => s xs k M) := rfl
  refine ⟨?_, ?_, ?_⟩
  · exact nor_accumulator_correctness hN hW xs M hM h_valid z_0 hz
  · exact nor_output_valid hN hW xs M hM h_valid
  · exact carry_free_sum hN hW xs M hM h_valid

theorem and_algorithm {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) :
    let z_0 := columnSum N W (fun k => s xs k M)
    acc_seq N (fun d => and_gate d M) (extracted_digits N W z_0) W =
      val N W (fun k => and_gate (s xs k M) M) ∧
      isValidInput N W (fun k => and_gate (s xs k M) M) ∧
      z_0 = ∑ i ∈ range M, val N W (xs i) ∧ z_0 < N ^ W := by
  intro z_0
  have hz : z_0 = columnSum N W (fun k => s xs k M) := rfl
  refine ⟨?_, ?_, ?_⟩
  · exact and_accumulator_correctness hN hW xs M hM h_valid z_0 hz
  · exact and_output_valid hN hW xs M hM h_valid
  · exact carry_free_sum hN hW xs M hM h_valid

theorem xor_algorithm {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) :
    let z_0 := columnSum N W (fun k => s xs k M)
    acc_seq N xor_gate (extracted_digits N W z_0) W =
      val N W (fun k => xor_gate (s xs k M)) ∧
      isValidInput N W (fun k => xor_gate (s xs k M)) ∧
      z_0 = ∑ i ∈ range M, val N W (xs i) ∧ z_0 < N ^ W := by
  intro z_0
  have hz : z_0 = columnSum N W (fun k => s xs k M) := rfl
  refine ⟨?_, ?_, ?_⟩
  · exact xor_accumulator_correctness hN hW xs M hM h_valid z_0 hz
  · exact xor_output_valid hN hW xs M hM h_valid
  · exact carry_free_sum hN hW xs M hM h_valid

theorem xnor_algorithm {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) :
    let z_0 := columnSum N W (fun k => s xs k M)
    acc_seq N xnor_gate (extracted_digits N W z_0) W =
      val N W (fun k => xnor_gate (s xs k M)) ∧
      isValidInput N W (fun k => xnor_gate (s xs k M)) ∧
      z_0 = ∑ i ∈ range M, val N W (xs i) ∧ z_0 < N ^ W := by
  intro z_0
  have hz : z_0 = columnSum N W (fun k => s xs k M) := rfl
  refine ⟨?_, ?_, ?_⟩
  · exact xnor_accumulator_correctness hN hW xs M hM h_valid z_0 hz
  · exact xnor_output_valid hN hW xs M hM h_valid
  · exact carry_free_sum hN hW xs M hM h_valid

end Kbee
