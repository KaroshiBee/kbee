-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Kbee.BaseN
import Mathlib

namespace Kbee

open Finset

/-- The all-ones mask equals the geometric sum of powers. -/
lemma R_eq_sum_pow (N W : ℕ) (hN : 2 ≤ N) :
    R N W = ∑ k ∈ range W, N ^ k := by
  dsimp [R]
  exact (Nat.geomSum_eq hN W).symm

/-- Each binary-format digit contributes at most its place value. -/
lemma digit_le_pow (N W : ℕ) (x : ℕ → ℕ) (h_valid : isValidInput N W x) {k : ℕ} (hk : k < W) :
    x k * N ^ k ≤ N ^ k := by
  rcases h_valid k hk with h | h
  · rw [h, zero_mul]; exact Nat.zero_le _
  · rw [h, one_mul]

/-- Valid inputs are bounded by the all-ones mask. -/
lemma val_le_R {N W : ℕ} (hN : N > 2) (x : ℕ → ℕ) (h_valid : isValidInput N W x) :
    val N W x ≤ R N W := by
  have hN' : 2 ≤ N := Nat.le_of_lt hN
  dsimp [val, R]
  calc
    ∑ k ∈ range W, x k * N ^ k
        ≤ ∑ k ∈ range W, N ^ k := by
          gcongr with k hk
          exact digit_le_pow N W x h_valid (mem_range.mp hk)
    _ = R N W := (R_eq_sum_pow N W hN').symm

/-- `(N - 1)` divides the all-ones numerator. -/
lemma sub_one_dvd_pow_sub_one (N W : ℕ) : N - 1 ∣ N ^ W - 1 :=
  Nat.sub_one_dvd_pow_sub_one N W

/-- Multiplying the mask by `N - 1` yields `N^W - 1`. -/
lemma mul_R (N W : ℕ) (_hN : 2 ≤ N) :
    (N - 1) * R N W = N ^ W - 1 := by
  dsimp [R]
  exact Nat.mul_div_cancel' (sub_one_dvd_pow_sub_one N W)

/-- Digitwise complement expands over the place-value sum. -/
lemma sum_complement_digits (N W : ℕ) (x : ℕ → ℕ)
    (h_valid : isValidInput N W x) :
    (∑ k ∈ range W, N ^ k) - ∑ k ∈ range W, x k * N ^ k =
      ∑ k ∈ range W, (1 - x k) * N ^ k := by
  rw [← sum_tsub_distrib]
  · refine sum_congr rfl ?_
    intro k hk
    have hk' := mem_range.mp hk
    rcases h_valid k hk' with hx | hx
    · simp [hx]
    · simp [hx]
  · intro k hk
    exact digit_le_pow N W x h_valid (mem_range.mp hk)

/-- NOT is digitwise complement in place-value form. -/
lemma not_correctness {N W : ℕ} (hN : N > 2) (_hW : W ≥ 1) (x : ℕ → ℕ)
    (h_valid : isValidInput N W x) :
    not_op N W x = ∑ k ∈ range W, (1 - x k) * N ^ k := by
  have hN' : 2 ≤ N := Nat.le_of_lt hN
  dsimp [not_op, val]
  rw [R_eq_sum_pow N W hN', sum_complement_digits N W x h_valid]

/-- Reindex a digit-weighted sum by digit position. -/
lemma sum_digits_reindex {N : ℕ} (t : ℕ) (f : ℕ → ℕ) :
    ∑ i ∈ range t, f i * N ^ (t - 1 - i) =
      ∑ k ∈ range t, f (t - 1 - k) * N ^ k := by
  rw [← sum_range_reflect (fun j => f j * N ^ (t - 1 - j)) t]
  refine sum_congr rfl fun k hk => by
    have hk' := mem_range.mp hk
    congr 1
    rw [show t - 1 - (t - 1 - k) = k by omega]

/-- Shift-and-add recurrence builds a weighted digit sum. -/
lemma acc_seq_eq_sum {N : ℕ} (out_d : ℕ → ℕ) (d_seq : ℕ → ℕ) :
    ∀ t, acc_seq N out_d d_seq t =
      ∑ k ∈ range t, out_d (d_seq (t - 1 - k)) * N ^ k := by
  intro t
  rw [← sum_digits_reindex t (fun i => out_d (d_seq i))]
  induction t with
  | zero => simp [acc_seq]
  | succ t ih =>
    dsimp [acc_seq, acc_step]
    rw [ih, sum_range_succ, Nat.sub_self, pow_zero, mul_one]
    have hsum : N * ∑ i ∈ range t, out_d (d_seq i) * N ^ (t - 1 - i) =
        ∑ x ∈ range t, out_d (d_seq x) * N ^ (t - x) := by
      rw [mul_sum]
      refine sum_congr rfl fun i hi => by
        have hi' := mem_range.mp hi
        calc
          N * (out_d (d_seq i) * N ^ (t - 1 - i))
              = out_d (d_seq i) * (N * N ^ (t - 1 - i)) := by ring
          _ = out_d (d_seq i) * N ^ (t - i) := by
            congr 1
            rw [show N ^ (t - i) = N ^ ((t - 1 - i) + 1) by congr 1; omega, pow_succ, mul_comm]
    linarith

/-- Place-value encoding of per-column digit sums. -/
def columnSum (N W : ℕ) (s : ℕ → ℕ) : ℕ :=
  ∑ k ∈ range W, s k * N ^ k

lemma columnSum_eq_inputs {N W : ℕ} (xs : ℕ → ℕ → ℕ) (M : ℕ)
    (_hM : M = N - 1) :
    columnSum N W (fun k => s xs k M) = ∑ i ∈ range M, val N W (xs i) := by
  dsimp [columnSum, s, val]
  rw [sum_comm]
  refine sum_congr rfl ?_
  intro k hk
  rw [sum_mul]

lemma z_bound {N W : ℕ} (hN : N > 2) (_hW : W ≥ 1) (xs : ℕ → ℕ → ℕ) (M : ℕ)
    (hM : M = N - 1) (h_valid : ∀ i < M, isValidInput N W (xs i)) :
    (∑ i ∈ range M, val N W (xs i)) < N ^ W := by
  have hN' : 2 ≤ N := Nat.le_of_lt hN
  have hMpos : 0 < M := by
    rw [hM]
    omega
  calc
    ∑ i ∈ range M, val N W (xs i)
        ≤ ∑ _i ∈ range M, R N W := by
          gcongr with i hi
          exact val_le_R hN (xs i) (h_valid i (mem_range.mp hi))
    _ = M * R N W := by simp [sum_const]
    _ = (N - 1) * R N W := by rw [hM]
    _ = N ^ W - 1 := mul_R N W hN'
    _ < N ^ W := by
      simpa [Nat.succ_eq_add_one, Nat.sub_add_cancel (Nat.one_le_pow W N (by omega))] using
        Nat.lt_succ_self (N ^ W - 1)

lemma accumulator_correctness {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1)
    (out_d : ℕ → ℕ) (d_seq : ℕ → ℕ) :
    acc_seq N out_d d_seq W =
      ∑ k ∈ range W, out_d (d_seq (W - 1 - k)) * N ^ k := by
  simpa using acc_seq_eq_sum (N := N) out_d d_seq W

/-- Carry-free column sum equals the sum of operand values and stays below `N^W`. -/
lemma carry_free_sum {N W : ℕ} (hN : N > 2) (hW : W ≥ 1) (xs : ℕ → ℕ → ℕ) (M : ℕ)
    (hM : M = N - 1) (h_valid : ∀ i < M, isValidInput N W (xs i)) :
    columnSum N W (fun k => s xs k M) = ∑ i ∈ range M, val N W (xs i) ∧
      columnSum N W (fun k => s xs k M) < N ^ W := by
  constructor
  · exact columnSum_eq_inputs xs M hM
  · rw [columnSum_eq_inputs xs M hM]
    exact z_bound hN hW xs M hM h_valid

end Kbee
