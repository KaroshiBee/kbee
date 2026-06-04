-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Copyright (c) 2026 Karoshibee LTD
import Kbee.BaseN
import Kbee.Helpers
import Mathlib

namespace Kbee

open Finset

/-- Partial column-sum over the lowest `W - t` digit positions. -/
def partialColumnSum (N W t : ℕ) (s : ℕ → ℕ) : ℕ :=
  ∑ k ∈ range (W - t), s k * N ^ (k + t)

lemma partialColumnSum_zero (N W : ℕ) (s : ℕ → ℕ) :
    partialColumnSum N W 0 s = columnSum N W s := by
  rfl

lemma partialColumnSum_factor (N W t : ℕ) (s : ℕ → ℕ) :
    partialColumnSum N W t s = N ^ t * ∑ k ∈ range (W - t), s k * N ^ k := by
  dsimp [partialColumnSum]
  calc
    ∑ k ∈ range (W - t), s k * N ^ (k + t)
        = ∑ k ∈ range (W - t), s k * N ^ k * N ^ t := by
          refine sum_congr rfl fun k _ => by rw [pow_add, mul_assoc]
    _ = (∑ k ∈ range (W - t), s k * N ^ k) * N ^ t := by rw [sum_mul]
    _ = N ^ t * ∑ k ∈ range (W - t), s k * N ^ k := by rw [mul_comm]

lemma innerSum_lt_pow {N W t : ℕ} (hN : N > 2) (s : ℕ → ℕ)
    (hs : ∀ k, k < W → s k ≤ N - 1) (ht : t < W) :
    ∑ k ∈ range (W - t), s k * N ^ k < N ^ (W - t) := by
  have hsum :
      ∑ k ∈ range (W - t), s k * N ^ k ≤ ∑ k ∈ range (W - t), (N - 1) * N ^ k := by
    apply sum_le_sum
    intro k hk
    exact Nat.mul_le_mul_right _ (hs k (by have := mem_range.mp hk; omega))
  have hgeom :
      ∑ k ∈ range (W - t), (N - 1) * N ^ k = N ^ (W - t) - 1 := by
    have hN' : 2 ≤ N := Nat.le_of_lt hN
    calc
      ∑ k ∈ range (W - t), (N - 1) * N ^ k
          = (N - 1) * ∑ k ∈ range (W - t), N ^ k := by rw [← mul_sum]
      _ = (N - 1) * R N (W - t) := by rw [R_eq_sum_pow N (W - t) hN']
      _ = N ^ (W - t) - 1 := mul_R N (W - t) hN'
  have hle : ∑ k ∈ range (W - t), s k * N ^ k ≤ N ^ (W - t) - 1 := by
    calc
      _ ≤ ∑ k ∈ range (W - t), (N - 1) * N ^ k := hsum
      _ = N ^ (W - t) - 1 := hgeom
  have hpred : (N ^ (W - t) - 1).succ = N ^ (W - t) :=
    Nat.sub_add_cancel (Nat.one_le_pow (W - t) N (by omega))
  rw [← hpred]
  exact Nat.lt_succ_of_le hle

lemma partialColumnSum_lt_pow {N W t : ℕ} (hN : N > 2) (_hW : W ≥ 1) (s : ℕ → ℕ)
    (hs : ∀ k, k < W → s k ≤ N - 1) (ht : t ≤ W) :
    partialColumnSum N W t s < N ^ W := by
  by_cases hwt : W - t = 0
  · have : t = W := by omega
    subst this
    dsimp [partialColumnSum]
    simp only [tsub_self, range_zero, sum_empty]
    exact Nat.pow_pos (by omega : 0 < N)
  · rw [partialColumnSum_factor]
    have hbound : ∑ k ∈ range (W - t), s k * N ^ k < N ^ (W - t) :=
      innerSum_lt_pow (t := t) hN s hs (by omega)
    calc
      N ^ t * ∑ k ∈ range (W - t), s k * N ^ k
          < N ^ t * N ^ (W - t) :=
        Nat.mul_lt_mul_of_pos_left hbound (Nat.pow_pos (by omega : 0 < N))
      _ = N ^ W := by rw [← pow_add, show t + (W - t) = W by omega]

lemma innerSum_split (N W t : ℕ) (s : ℕ → ℕ) (ht : t < W) :
    ∑ k ∈ range (W - t), s k * N ^ k =
      s (W - t - 1) * N ^ (W - t - 1) +
        ∑ k ∈ range (W - t - 1), s k * N ^ k := by
  rw [show W - t = Nat.succ (W - t - 1) by omega, sum_range_succ]
  ac_rfl

lemma innerSum_div_pow {N W t : ℕ} (hN : N > 2) (s : ℕ → ℕ)
    (hs : ∀ k, k < W → s k ≤ N - 1) (ht : t < W) :
    (∑ k ∈ range (W - t), s k * N ^ k) / N ^ (W - t - 1) = s (W - t - 1) := by
  set S := ∑ k ∈ range (W - t), s k * N ^ k
  set D := N ^ (W - t - 1)
  have hNpos : 0 < N := by omega
  have hsplit := innerSum_split N W t s ht
  have hrest : ∑ k ∈ range (W - t - 1), s k * N ^ k < D := by
    by_cases hw : W - t - 1 = 0
    · simp only [hw, range_zero, sum_empty]
      rw [show D = 1 from by dsimp [D]; rw [hw, Nat.pow_zero]]
      exact Nat.zero_lt_one
    · have ht' : t + 1 < W := by omega
      exact innerSum_lt_pow (t := t + 1) hN s hs ht'
  have hDpos : 0 < D := Nat.pow_pos hNpos
  unfold S D
  rw [hsplit]
  rw [show s (W - t - 1) * N ^ (W - t - 1) = N ^ (W - t - 1) * s (W - t - 1) from mul_comm _ _]
  rw [add_comm (_ * s (W - t - 1)), Nat.add_mul_div_left _ _ hDpos]
  rw [Nat.div_eq_of_lt hrest, zero_add]

lemma leading_digit_of_partial_sum {N W t : ℕ} (hN : N > 2) (_hW : W ≥ 1) (s : ℕ → ℕ)
    (hs : ∀ k, k < W → s k ≤ N - 1) (ht : t < W) (_hwt : W - t ≥ 1) :
    d_t N W (partialColumnSum N W t s) = s (W - 1 - t) := by
  dsimp [d_t, P]
  rw [partialColumnSum_factor]
  have hpow : N ^ (W - 1) = N ^ t * N ^ (W - t - 1) := by
    rw [← pow_add, show t + (W - t - 1) = W - 1 by omega]
  rw [hpow]
  have hinner := innerSum_div_pow hN s hs ht
  calc
    (N ^ t * ∑ k ∈ range (W - t), s k * N ^ k) / (N ^ t * N ^ (W - t - 1))
        = (∑ k ∈ range (W - t), s k * N ^ k) / N ^ (W - t - 1) := by
          rw [Nat.mul_div_mul_left _ _ (Nat.pow_pos (by omega : 0 < N))]
    _ = s (W - 1 - t) := by rw [hinner]; congr 1; omega

lemma residue_step {N W t : ℕ} (hN : N > 2) (hW : W ≥ 1) (s : ℕ → ℕ)
    (hs : ∀ k, k < W → s k ≤ N - 1) (ht : t < W) :
    next_z N W (partialColumnSum N W t s) = partialColumnSum N W (t + 1) s := by
  set S := ∑ k ∈ range (W - t), s k * N ^ k
  have hsplit := innerSum_split N W t s ht
  have hfactor := partialColumnSum_factor N W t s
  have hdigit : (N ^ t * S) / N ^ (W - 1) = s (W - 1 - t) := by
    dsimp [d_t, P]
    rw [← hfactor]
    exact leading_digit_of_partial_sum hN hW s hs ht (by omega)
  have hidx : W - 1 - t = W - t - 1 := by omega
  calc
    next_z N W (partialColumnSum N W t s)
        = N * (N ^ t * S) - (N ^ t * S) / N ^ (W - 1) * N ^ W := by
          dsimp [next_z, d_t, P]
          rw [hfactor]
    _ = N * (N ^ t * S) - s (W - 1 - t) * N ^ W := by
          rw [hdigit]
    _ = N ^ (t + 1) * S - s (W - 1 - t) * N ^ W := by
          congr 1
          ring
    _ = N ^ (t + 1) * S - s (W - t - 1) * N ^ W := by
          congr 1
          rw [hidx]
    _ = N ^ (t + 1) * (s (W - t - 1) * N ^ (W - t - 1) +
          ∑ k ∈ range (W - t - 1), s k * N ^ k) - s (W - t - 1) * N ^ W := by
          rw [show S = _ from hsplit, mul_add]
    _ = N ^ (t + 1) * ∑ k ∈ range (W - t - 1), s k * N ^ k := by
          have hcancel :
              N ^ (t + 1) * (s (W - t - 1) * N ^ (W - t - 1)) = s (W - t - 1) * N ^ W := by
            calc
              N ^ (t + 1) * (s (W - t - 1) * N ^ (W - t - 1))
                  = s (W - t - 1) * (N ^ (t + 1) * N ^ (W - t - 1)) := by ring
              _ = s (W - t - 1) * N ^ W := by
                  rw [← pow_add, show t + 1 + (W - t - 1) = W by omega]
          rw [mul_add, hcancel]
          omega
    _ = partialColumnSum N W (t + 1) s := by
          dsimp [partialColumnSum]
          have hrange : W - (t + 1) = W - t - 1 := Nat.sub_add_eq W t 1
          rw [mul_sum, show range (W - (t + 1)) = range (W - t - 1) from congr_arg range hrange]
          refine sum_congr rfl fun k _ => ?_
          calc
            N ^ (t + 1) * (s k * N ^ k) = s k * (N ^ k * N ^ (t + 1)) := by ring
            _ = s k * N ^ (k + (t + 1)) := by rw [← pow_add]

lemma residue_invariant {N W : ℕ} (hN : N > 2) (hW : W ≥ 1) (s : ℕ → ℕ)
    (hs : ∀ k, k < W → s k ≤ N - 1) (z_0 : ℕ)
    (hz : z_0 = columnSum N W s) :
    ∀ t, t ≤ W →
      residue_seq N W z_0 t = partialColumnSum N W t s := by
  intro t ht
  induction t with
  | zero =>
    dsimp [residue_seq]
    rw [partialColumnSum_zero, hz]
  | succ t ih =>
    have ht' : t < W := by omega
    rw [residue_seq, ih (by omega), residue_step hN hW s hs ht']

lemma s_le_N_sub_one {N W : ℕ} (hN : N > 2) (hW : W ≥ 1) (xs : ℕ → ℕ → ℕ) (M : ℕ)
    (hM : M = N - 1) (h_valid : ∀ i < M, isValidInput N W (xs i)) (k : ℕ) (hk : k < W) :
    s xs k M ≤ N - 1 := by
  calc
    s xs k M ≤ M := s_bound hN hW xs k M h_valid hk
    _ = N - 1 := hM

lemma residue_extraction_correctness {N W : ℕ} (hN : N > 2) (hW : W ≥ 1)
    (xs : ℕ → ℕ → ℕ) (M : ℕ) (hM : M = N - 1)
    (h_valid : ∀ i < M, isValidInput N W (xs i)) (z_0 : ℕ)
    (hz : z_0 = columnSum N W (fun k => s xs k M)) (t : ℕ) (ht : t < W) :
    d_t N W (residue_seq N W z_0 t) = s xs (W - 1 - t) M ∧
      residue_seq N W z_0 (t + 1) < N ^ W := by
  let sfun k := s xs k M
  have hs : ∀ k, k < W → sfun k ≤ N - 1 :=
    fun k hk => s_le_N_sub_one hN hW xs M hM h_valid k hk
  have hinvar := residue_invariant hN hW sfun hs z_0 hz t (Nat.le_of_lt ht)
  have hdigit := leading_digit_of_partial_sum hN hW sfun hs ht (by omega)
  have hlt := partialColumnSum_lt_pow (t := t + 1) hN hW sfun hs (by omega)
  have hnext := residue_invariant hN hW sfun hs z_0 hz (t + 1) (by omega)
  constructor
  · rw [hinvar, hdigit]
  · rw [hnext]; exact hlt

end Kbee
