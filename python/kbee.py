#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD

import numpy as np


def pad_left_zeros(arr, new_length):
    """Pads a NumPy array with zeros on the left to reach a specified length.

    Args:
        arr: The input NumPy array.
        new_length: The desired length of the padded array.

    Returns:
        A new NumPy array with zeros padded on the left. If the original
        array's length is already greater than or equal to new_length, the
        original array is returned unchanged.
    """
    current_length = arr.shape[-1]  # Get the length of the last dimension
    if current_length >= new_length:
        return arr
    padding_width = new_length - current_length
    padding = [(0, 0)] * (arr.ndim - 1) + [(padding_width, 0)]
    padded_arr = np.pad(arr, padding, mode="constant")
    return padded_arr


def to_baseN(n, base, bitwidth):
    """Converts a non-negative integer to its base-N representation as a NumPy array.

    Args:
        n: A non-negative integer.
        base: the base >= 2
        bitwidth: width of the resulting number

    Returns:
        A NumPy array of integers representing the base-N digits (least significant digit last).
        Returns [0,...,0] if the input is 0.
    """
    if n < 0:
        raise ValueError(f"input `n` must be non-negative, got {n}")
    if base < 2:
        raise ValueError(f"input `base` must be >=2, got {base}")
    if bitwidth < 4:
        raise ValueError(f"input `bitwidth` must be >=4, got {bitwidth}")

    if n == 0:
        return np.int64(np.zeros(bitwidth))

    digits = []
    while n > 0:
        digits.append(n % base)
        n //= base
    return pad_left_zeros(np.array(digits[::-1]), bitwidth)


def from_base3(xs):
    return np.int64(np.sum([x * np.power(3, i) for i, x in enumerate(xs[::-1])]))


def from_baseN_digits(digits_msb, base: int) -> np.int64:
    """Decode MSB-first base-N digits to integer."""
    acc = np.int64(0)
    for d in digits_msb:
        acc = acc * base + np.int64(d)
    return acc


def digits_msb(n: int, base: int, width: int) -> list[int]:
    """Base-`base` digits of `n`, MSB first, width-wide."""
    return [int(d) for d in to_baseN(int(n), base, width)]


# Reserved 2-input sentinel for base-4 ASIC (pass 2 masking); oracle only.
BASE4_SENTINEL_C = np.int64(sum(2 * (4**i) for i in range(4)))  # 2222_4 = 170


class Gates3InputsBase4:
    """Base-4, W=4, three-input KBee ASIC oracle (N=4, M=3).

    Provides:
    - ``eval_cell``: polymorphic modes per asic/docs/summary.md
    - ``eval_fabric``: combinational MSB-first residue on z=A+B+C
    - ``residue_trace``: per-stage digits and residues for Ngspice benches
    """

    _BASE = 4
    MODE_AND = 0x0
    MODE_NAND = 0x1
    MODE_NOR = 0x2
    MODE_OR = 0x3
    MODE_XOR = 0x4
    MODE_XNOR = 0x5
    MODE_NOT_A = 0x6
    MODE_NOT_B = 0x7
    MODE_NOT_C = 0x8
    MODE_PASS_A = 0x9
    MODE_PASS_B = 0xA
    MODE_PASS_C = 0xB
    MODE_CONST_ZERO = 0xC
    MODE_CONST_STEP = 0xD
    MODE_CONST_FULL = 0xE
    MODE_CLEAR = 0xF

    def __init__(self, bitwidth: int = 4):
        if bitwidth != 4:
            raise ValueError("Gates3InputsBase4 is fixed at W=4 for pass 1")
        self.W = np.int64(bitwidth)
        self.P = np.int64(self._BASE ** (bitwidth - 1))  # 64
        self.N_W = np.int64(self._BASE**bitwidth)  # 256
        self.cutoff = np.int64((self._BASE**bitwidth - 1) // (self._BASE - 1))  # 85
        self.z_max = np.int64(3 * self.cutoff)  # 255

    @classmethod
    def make4Bit(cls):
        return cls(4)

    @staticmethod
    def bin4_to_code(bin4: int) -> np.int64:
        """4-bit binary int -> base-4 code with digits in {0, 1} only."""
        if bin4 < 0 or bin4 > 15:
            raise ValueError(f"bin4 must be 0..15, got {bin4}")
        return from_baseN_digits([(bin4 >> (3 - k)) & 1 for k in range(4)], 4)

    @staticmethod
    def code_to_bin4(code: int) -> int:
        """Base-4 code with digits in {0,1} -> 4-bit binary int."""
        ds = digits_msb(int(code), 4, 4)
        out = 0
        for d in ds:
            if d not in (0, 1):
                raise ValueError(f"code {code} is not binary-format")
            out = (out << 1) | d
        return out

    def _mask_all_ones(self) -> np.int64:
        return self.cutoff  # 1111_4

    def not_binary_format(self, x: int) -> np.int64:
        return self._mask_all_ones() - np.int64(x)

    def _check_operand(self, name: str, v: int) -> None:
        if v < 0 or v > self.cutoff:
            raise ValueError(f"{name} must be 0 <= {name} <= {self.cutoff}, got {v}")

    def _check_z(self, z: int) -> None:
        if z < 0 or z > self.z_max:
            raise ValueError(f"z must be 0 <= z <= {self.z_max}, got {z}")

    @staticmethod
    def _check_mode(ui_in: int) -> int:
        if ui_in < 0 or ui_in > 0xF:
            raise ValueError(f"ui_in must be 0..15, got {ui_in}")
        return int(ui_in)

    def classify_digit(self, z: int) -> int:
        """Leading base-4 digit d of residue z (MSB position)."""
        self._check_z(z)
        if z < self.P:
            return 0
        if z < 2 * self.P:
            return 1
        if z < 3 * self.P:
            return 2
        return 3

    def residue_step(self, z: int) -> tuple[int, int]:
        """One MSB-first residue step: (digit d, z_next)."""
        d = self.classify_digit(z)
        z_next = self._BASE * (z - d * self.P)
        return d, int(z_next)

    def residue_trace(self, a: int, b: int, c: int) -> dict:
        """Full 4-stage residue trace for z = a + b + c."""
        self._check_operand("a", a)
        self._check_operand("b", b)
        self._check_operand("c", c)
        z = int(a) + int(b) + int(c)
        self._check_z(z)
        digits: list[int] = []
        residues: list[int] = []
        z_curr = z
        for _ in range(int(self.W)):
            d, z_next = self.residue_step(z_curr)
            digits.append(d)
            residues.append(z_next)
            z_curr = z_next
        if z_curr != 0:
            raise ValueError(f"residue did not terminate: last z={z_curr}")
        return {
            "a": a,
            "b": b,
            "c": c,
            "z": z,
            "digit_0": digits[0],
            "digit_1": digits[1],
            "digit_2": digits[2],
            "digit_3": digits[3],
            "z1": residues[0],
            "z2": residues[1],
            "z3": residues[2],
            "z4": residues[3],
        }

    def _fabric_predicate(self, ui_in: int, d: int, c: int) -> bool:
        """Whether digit d contributes to Y accumulator for fabric path."""
        c_zero = int(c) == 0
        if ui_in == self.MODE_NOR:
            return d == 0
        if ui_in == self.MODE_AND:
            return d == 3 if not c_zero else d == 2
        if ui_in == self.MODE_XOR:
            return (d % 2) == 1
        if ui_in == self.MODE_XNOR:
            return (d % 2) == 0
        if ui_in == self.MODE_OR:
            return d >= 1 if c_zero else d in (1, 2, 3)
        if ui_in == self.MODE_NAND:
            if c_zero:
                return d != 2
            return d != 3
        return False

    def eval_fabric(self, ui_in: int, a: int, b: int, c: int) -> dict:
        """Combinational residue unfold + mode-selected accumulator -> Y."""
        ui_in = self._check_mode(ui_in)
        self._check_operand("a", a)
        self._check_operand("b", b)
        self._check_operand("c", c)
        if ui_in == self.MODE_CLEAR:
            return {"y": 0, "fabric": True, "cleared": True}
        if ui_in >= self.MODE_CONST_ZERO:
            return self._eval_constants(ui_in) | {"fabric": True}
        if ui_in >= self.MODE_NOT_A:
            out = self.eval_cell(ui_in, a, b, c)
            out["fabric"] = True
            return out

        z = int(a) + int(b) + int(c)
        self._check_z(z)
        y = np.int64(0)
        inc = self.P
        z_curr = z
        trace_digits: list[int] = []
        for i in range(int(self.W)):
            d, z_next = self.residue_step(z_curr)
            trace_digits.append(d)
            if self._fabric_predicate(ui_in, d, c):
                y += inc
            inc = np.int64(inc // self._BASE)
            z_curr = z_next
        return {
            "y": int(y),
            "y_digits": to_baseN(int(y), 4, int(self.W)),
            "z": z,
            "digits": trace_digits,
            "fabric": True,
        }

    def _eval_constants(self, ui_in: int) -> dict:
        if ui_in == self.MODE_CONST_ZERO:
            return {"y": 0}
        if ui_in == self.MODE_CONST_STEP:
            return {"y": 1}  # one unit code = 50 nA nominal
        if ui_in == self.MODE_CONST_FULL:
            return {"y": int(self.N_W - 1)}  # 255 = 3333_4
        if ui_in == self.MODE_CLEAR:
            return {"y": 0, "cleared": True}
        raise ValueError(f"not a constant mode: {ui_in:#x}")

    def _eval_logic_digit(self, ui_in: int, ak: int, bk: int) -> int:
        if ui_in == self.MODE_AND:
            return 1 if ak and bk else 0
        if ui_in == self.MODE_NAND:
            return 0 if ak and bk else 1
        if ui_in == self.MODE_NOR:
            return 1 if not ak and not bk else 0
        if ui_in == self.MODE_OR:
            return 1 if ak or bk else 0
        if ui_in == self.MODE_XOR:
            return 1 if ak != bk else 0
        if ui_in == self.MODE_XNOR:
            return 1 if ak == bk else 0
        raise ValueError(f"not a 2-input logic mode: {ui_in:#x}")

    def eval_cell(self, ui_in: int, a: int, b: int, c: int) -> dict:
        """Polymorphic cell output Y per asic/docs/summary.md (pass 1: no C mask)."""
        ui_in = self._check_mode(ui_in)
        self._check_operand("a", a)
        self._check_operand("b", b)
        self._check_operand("c", c)

        if ui_in == self.MODE_NOT_C and int(c) == BASE4_SENTINEL_C:
            raise ValueError("invalid operand: NOT(C) with C=2222_4 sentinel")

        if ui_in <= self.MODE_XNOR:
            da = digits_msb(int(a), 4, 4)
            db = digits_msb(int(b), 4, 4)
            out_digits = [self._eval_logic_digit(ui_in, da[k], db[k]) for k in range(4)]
            y = from_baseN_digits(out_digits, 4)
            return {"y": int(y), "y_digits": to_baseN(int(y), 4, 4), "cell": True}

        if ui_in == self.MODE_NOT_A:
            y = self.not_binary_format(int(a))
            return {"y": int(y), "y_digits": to_baseN(int(y), 4, 4), "cell": True}
        if ui_in == self.MODE_NOT_B:
            y = self.not_binary_format(int(b))
            return {"y": int(y), "y_digits": to_baseN(int(y), 4, 4), "cell": True}
        if ui_in == self.MODE_NOT_C:
            y = self.not_binary_format(int(c))
            return {"y": int(y), "y_digits": to_baseN(int(y), 4, 4), "cell": True}
        if ui_in == self.MODE_PASS_A:
            return {"y": int(a), "y_digits": to_baseN(int(a), 4, 4), "cell": True}
        if ui_in == self.MODE_PASS_B:
            return {"y": int(b), "y_digits": to_baseN(int(b), 4, 4), "cell": True}
        if ui_in == self.MODE_PASS_C:
            return {"y": int(c), "y_digits": to_baseN(int(c), 4, 4), "cell": True}

        return self._eval_constants(ui_in) | {"cell": True}

    def eval(
        self, ui_in: int, a: int, b: int, c: int, *, use_fabric: bool = False
    ) -> dict:
        if use_fabric:
            return self.eval_fabric(ui_in, a, b, c)
        return self.eval_cell(ui_in, a, b, c)

    def fabric_matches_cell(self, ui_in: int, a: int, b: int, c: int) -> bool:
        """True when residue fabric and cell agree (logic modes need C=0)."""
        ui_in = self._check_mode(ui_in)
        if ui_in <= self.MODE_XNOR and int(c) != 0:
            return False
        if ui_in >= self.MODE_NOT_A:
            return int(self.eval_fabric(ui_in, a, b, c)["y"]) == int(
                self.eval_cell(ui_in, a, b, c)["y"]
            )
        try:
            yf = int(self.eval_fabric(ui_in, a, b, c)["y"])
            yc = int(self.eval_cell(ui_in, a, b, c)["y"])
        except ValueError:
            return False
        return yf == yc


class Gates2Inputs:
    """A logic gate collection (NOR, XOR, AND) for two inputs."""

    # NOTE for two inputs we want to be in base 3
    _BASE = 3

    def __init__(self, bitwidth):
        if bitwidth < 4:
            raise ValueError(f"bitwidth must be bigger than 4, got {bitwidth}")

        # NOTE we want that 3 of these is the max, we do it this way because we want to know the internal cutoffs too
        N = np.int64(np.power(self._BASE, bitwidth - 1))
        self.one_N = N
        self.two_N = np.int64(2 * N)
        self.three_N = np.int64(3 * N)
        self.W = np.int64(bitwidth)

        # NOTE this is the number [1,1,1,....,1]
        self.cutoff = np.int64(
            np.sum([np.power(self._BASE, i) for i in range(bitwidth)])
        )

    @classmethod
    def make32Bit(cls):
        return cls(32)

    @classmethod
    def make16Bit(cls):
        return cls(16)

    @classmethod
    def make4Bit(cls):
        return cls(4)

    def norandxor(self, z1, z2):
        if z1 < 0 or z1 > self.cutoff:
            raise ValueError(f"z1 must be 0 <= z1 <= {self.cutoff}, got {z1}")
        if z2 < 0 or z2 > self.cutoff:
            raise ValueError(f"z2 must be 0 <= z2 <= {self.cutoff}, got {z2}")

        # mod 3N check - at this point, and given the input constraints,
        # the biggest number z can be is [2,2,2,....,2] so we are good
        z = z1 + z2
        gates = {"z1": z1, "z2": z2, "nor": 0, "xor": 0, "and": 0}
        inc = self.one_N
        for i in range(self.W):
            if i == self.W - 1 and inc != 1:
                raise ValueError(f"Expected last inc to be 1, got {inc}")
            if z < self.one_N:
                # print(f"{i}> z is {z}, inc is {inc}, NOR")
                gates["nor"] += inc
                # mod 3N - dont need to worry for this triad
                z = self._BASE * z
            elif z < self.two_N:
                # print(f"{i}> z is {z}, inc is {inc}, XOR")
                gates["xor"] += inc
                # mod 3N - shift back one and multiply
                z = self._BASE * (z - self.one_N)
            elif z < self.three_N:
                # print(f"{i}> z is {z}, inc is {inc}, AND")
                gates["and"] += inc
                # mod 3N - shift back two and multiply
                z = self._BASE * (z - self.two_N)
            else:
                # NOTE could not bother with this clause and end in third triad
                raise ValueError(f"Something has gone wrong: {z}")
            # NOTE most significant bit is first, so inc gets smaller
            inc = np.int64(inc / self._BASE)

        return {ky: (vl, to_baseN(vl, 3, self.W)) for ky, vl in gates.items()}
