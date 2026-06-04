# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
import unittest

import numpy as np
from hypothesis import given, strategies as st

import kbee as v

bin4 = st.integers(min_value=0, max_value=15)
ui_in = st.integers(min_value=0, max_value=15)


class TestGates3InputsBase4(unittest.TestCase):
    def setUp(self):
        self.g = v.Gates3InputsBase4.make4Bit()

    def test_residue_terminates(self):
        trace = self.g.residue_trace(85, 85, 85)
        self.assertEqual(trace["z4"], 0)
        self.assertEqual(trace["digit_0"], 3)

    def test_P_and_bounds(self):
        self.assertEqual(int(self.g.P), 64)
        self.assertEqual(int(self.g.cutoff), 85)
        self.assertEqual(int(self.g.z_max), 255)

    def test_corners_nor_c_zero(self):
        # a=1111_4, b=0000_4, c=0 -> z has leading digit 0 at MSB
        a = 85
        b = 0
        c = 0
        y_cell = self.g.eval_cell(self.g.MODE_NOR, a, b, c)["y"]
        y_fab = self.g.eval_fabric(self.g.MODE_NOR, a, b, c)["y"]
        self.assertEqual(y_cell, y_fab)
        self.assertEqual(v.Gates3InputsBase4.code_to_bin4(y_cell), (~15) & 0xF)

    def test_invalid_not_c_sentinel(self):
        with self.assertRaises(ValueError):
            self.g.eval_cell(self.g.MODE_NOT_C, 0, 0, int(v.BASE4_SENTINEL_C))

    def test_constants(self):
        self.assertEqual(self.g.eval_cell(self.g.MODE_CONST_ZERO, 0, 0, 0)["y"], 0)
        self.assertEqual(self.g.eval_cell(self.g.MODE_CONST_STEP, 0, 0, 0)["y"], 1)
        self.assertEqual(self.g.eval_cell(self.g.MODE_CONST_FULL, 0, 0, 0)["y"], 255)

    @given(bin4, bin4, ui_in)
    def test_logic_fabric_eq_cell_when_c_zero(self, a_bin, b_bin, ui):
        if ui > self.g.MODE_XNOR:
            return
        a = int(v.Gates3InputsBase4.bin4_to_code(a_bin))
        b = int(v.Gates3InputsBase4.bin4_to_code(b_bin))
        self.assertTrue(self.g.fabric_matches_cell(ui, a, b, 0))
        self.assertEqual(
            self.g.eval_fabric(ui, a, b, 0)["y"],
            self.g.eval_cell(ui, a, b, 0)["y"],
        )

    @given(bin4, bin4, ui_in)
    def test_pass_and_not_modes(self, a_bin, b_bin, ui):
        if ui < self.g.MODE_NOT_A or ui > self.g.MODE_PASS_C:
            return
        a = int(v.Gates3InputsBase4.bin4_to_code(a_bin))
        b = int(v.Gates3InputsBase4.bin4_to_code(b_bin))
        c = 0
        self.assertEqual(
            self.g.eval_fabric(ui, a, b, c)["y"],
            self.g.eval_cell(ui, a, b, c)["y"],
        )


if __name__ == "__main__":
    unittest.main()
