-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Mathlib

namespace Kbee

def P (N W : ℕ) : ℕ := N ^ (W - 1)

def R (N W : ℕ) : ℕ := (N ^ W - 1) / (N - 1)

def val (N W : ℕ) (x : ℕ → ℕ) : ℕ :=
  ∑ k ∈ Finset.range W, x k * N ^ k

def isValidInput (_N W : ℕ) (x : ℕ → ℕ) : Prop :=
  ∀ k, k < W → x k = 0 ∨ x k = 1

def s (xs : ℕ → ℕ → ℕ) (k : ℕ) (M : ℕ) : ℕ :=
  ∑ i ∈ Finset.range M, xs i k

def d_t (N W : ℕ) (z : ℕ) : ℕ := z / P N W

def next_z (N W : ℕ) (z : ℕ) : ℕ := N * z - d_t N W z * N ^ W

def acc_step (N : ℕ) (A out_d : ℕ) : ℕ := N * A + out_d

def nor_gate (d : ℕ) : ℕ := if d = 0 then 1 else 0
def and_gate (d M : ℕ) : ℕ := if d = M then 1 else 0
def xor_gate (d : ℕ) : ℕ := if d % 2 = 1 then 1 else 0
def xnor_gate (d : ℕ) : ℕ := if d % 2 = 0 then 1 else 0

def not_op (N W : ℕ) (x : ℕ → ℕ) : ℕ := R N W - val N W x

def residue_seq (N W : ℕ) (z_0 : ℕ) : ℕ → ℕ
  | 0 => z_0
  | t + 1 => next_z N W (residue_seq N W z_0 t)

def acc_seq (N : ℕ) (out_d : ℕ → ℕ) (d_seq : ℕ → ℕ) : ℕ → ℕ
  | 0 => 0
  | t + 1 => acc_step N (acc_seq N out_d d_seq t) (out_d (d_seq t))

lemma s_bound {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1) (xs : ℕ → ℕ → ℕ) (k M : ℕ)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (hk : k < W) :
    s xs k M ≤ M := by
  dsimp [s]
  induction M with
  | zero => simp
  | succ M ih =>
    rw [Finset.sum_range_succ]
    have h1 : xs M k ≤ 1 := by
      cases h_valid M (Nat.lt_succ_self M) k hk with
      | inl h => rw [h]; exact Nat.zero_le 1
      | inr h => rw [h]
    have h_valid_M : ∀ i < M, isValidInput N W (xs i) :=
      fun i hi => h_valid i (Nat.lt_trans hi (Nat.lt_succ_self M))
    have ih' := ih h_valid_M
    linarith

lemma output_constraint_closure {N W : ℕ} (_hN : N > 2) (_hW : W ≥ 1)
    (out_d : ℕ → ℕ) (d_seq : ℕ → ℕ) (h_out : ∀ d, out_d d = 0 ∨ out_d d = 1) :
    isValidInput N W (fun k => out_d (d_seq (W - 1 - k))) := by
  intro k hk
  exact h_out (d_seq (W - 1 - k))

end Kbee
