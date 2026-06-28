#!/usr/bin/env python3
import importlib.util
import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "copilot_byok_async.py"

spec = importlib.util.spec_from_file_location("copilot_byok_async", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


class ResultExtractionTest(unittest.TestCase):
    def test_extracts_first_complete_result_block(self):
        text = """before
BEGIN_RESULT
real result
END_RESULT
after BEGIN_RESULT
wrong
END_RESULT
"""
        self.assertEqual(module.extract_result_text(text), "real result")

    def test_missing_end_returns_text_after_begin_marker(self):
        text = "prefix\nBEGIN_RESULT\npartial result\nstill useful"
        self.assertEqual(module.extract_result_text(text), "partial result\nstill useful")

    def test_without_markers_returns_trimmed_stdout(self):
        self.assertEqual(module.extract_result_text("  plain output\n"), "plain output")

    def test_iso_preserves_epoch_zero(self):
        self.assertEqual(module.iso(0.0), "1970-01-01T00:00:00Z")


if __name__ == "__main__":
    unittest.main()
