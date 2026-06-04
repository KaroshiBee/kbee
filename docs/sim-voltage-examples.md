# Simulation voltage examples (V_range = 1.2 V)

Handy expected sequences when isolating SumDiff / residue paths in AD2. Codes
are base-3; voltages use `V = code / 3^n * V_range` with `n` trits.

## Four-trit downward (oneOrTwo = 1.2 V, isTwo = 0 V)

| Code | Voltage |
|------|---------|
| 1111₃ (40) | 0.592593 V |
| 1110₃ (39) | 0.577778 V |
| 1100₃ (36) | 0.533333 V |
| 1000₃ (27) | 0.400000 V |

Single-step examples: 0001₃ → 14.815 mV, 0010₃ → 44.444 mV, 0100₃ → 133.333 mV,
1000₃ → 400.000 mV.

## Four-trit downward (isTwo = 1.2 V, subtract term 2.4 V)

| Code | Voltage |
|------|---------|
| 2222₃ (80) | 1.185185 V |
| 2220₃ (78) | 1.155556 V |
| 2200₃ (72) | 1.066667 V |
| 2000₃ (54) | 0.800000 V |

Drive `Input1 = z`, `oneOrTwo = 1.2 V`, and the `isTwo` column above for the
branch under test.
