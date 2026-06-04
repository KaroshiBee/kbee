# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
import unittest
import numpy as np
from hypothesis import given, strategies as st

import kbee as v

inputs = lambda width: st.integers(min_value=0, max_value=(2**width) - 1).map(
    lambda x: v.from_base3(v.to_baseN(x, 2, width))
)


class TestToBaseN(unittest.TestCase):
    @given(
        st.integers(min_value=0, max_value=(2**16) - 1),
        st.integers(min_value=2, max_value=5),
    )
    def test_round_trip(self, n, base):
        xs = v.to_baseN(n, base, bitwidth=16)
        y = np.sum([d * (base**i) for i, d in enumerate(xs[::-1])])
        self.assertEqual(n, y)


class TestKbeeMethods(unittest.TestCase):
    def setUp(self):
        self.g04 = v.Gates2Inputs.make4Bit()
        self.g16 = v.Gates2Inputs.make16Bit()
        self.g32 = v.Gates2Inputs.make32Bit()

    @staticmethod
    def _doit(g, n, m):
        gg = g.norandxor(n, m)
        _, z1 = gg["z1"]
        _, z2 = gg["z2"]
        _, z1NORz2 = gg["nor"]
        _, z1XORz2 = gg["xor"]
        _, z1ANDz2 = gg["and"]
        np.testing.assert_array_equal(
            np.logical_not(np.logical_or(z1, z2)).astype(int), z1NORz2
        )
        np.testing.assert_array_equal(np.logical_xor(z1, z2).astype(int), z1XORz2)
        np.testing.assert_array_equal(np.logical_and(z1, z2).astype(int), z1ANDz2)

        # NOR is universal - can make a NAND gate
        # [ ( A NOR A ) NOR ( B NOR B ) ] NOR
        # [ ( A NOR A ) NOR ( B NOR B ) ]
        nNORn, _ = g.norandxor(n, n)["nor"]
        mNORm, _ = g.norandxor(m, m)["nor"]
        nnNORmm, _ = g.norandxor(nNORn, mNORm)["nor"]
        _, z1NANDz2 = g.norandxor(nnNORmm, nnNORmm)["nor"]
        np.testing.assert_array_equal(
            np.logical_not(np.logical_and(z1, z2)).astype(int), z1NANDz2
        )

    @given(inputs(4), inputs(4))
    def test_4Bit(self, n, m):
        self._doit(self.g04, n, m)

    @given(inputs(16), inputs(16))
    def test_16Bit(self, n, m):
        self._doit(self.g16, n, m)

    @given(inputs(32), inputs(32))
    def test_32Bit(self, n, m):
        self._doit(self.g32, n, m)


if __name__ == "__main__":
    unittest.main()
