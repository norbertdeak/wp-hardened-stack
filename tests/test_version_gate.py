"""Unit tests for the version gate. No network, no Docker."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "lib"))

import version_gate as vg  # noqa: E402


class VersionGateTests(unittest.TestCase):
    def setUp(self):
        self.baseline = json.loads((ROOT / "config" / "security-baseline.json").read_text())

    def test_version_tuple(self):
        self.assertEqual(vg.vtuple("8.3.11"), (8, 3, 11))
        self.assertEqual(vg.vtuple("11.4"), (11, 4))
        self.assertGreater(vg.vtuple("8.3.10"), vg.vtuple("8.3.9"))

    def test_below_baseline_is_raised(self):
        r = vg.decide("php", "8.2.20", self.baseline, online=False)
        self.assertEqual(r["verdict"], "RAISED")
        self.assertEqual(r["target"], self.baseline["php"]["min"])

    def test_at_baseline_is_ok(self):
        r = vg.decide("php", self.baseline["php"]["min"], self.baseline, online=False)
        self.assertEqual(r["verdict"], "OK")

    def test_parse_env_ignores_comments(self):
        env = vg.parse_env("# c\nPHP_VERSION=8.3\n\nREDIS_VERSION=7.4\n")
        self.assertEqual(env, {"PHP_VERSION": "8.3", "REDIS_VERSION": "7.4"})


if __name__ == "__main__":
    unittest.main()
