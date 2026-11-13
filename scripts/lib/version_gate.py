#!/usr/bin/env python3
"""Version gate: fail closed when a pinned runtime is known to be unsafe.

Two sources of truth, in order:
  1. endoflife.date (live) — the latest patch for the active cycle
  2. config/security-baseline.json (offline fallback)

Exit codes: 0 = all pins acceptable, 1 = at least one pin was raised, 2 = cannot decide.
The `--write` flag rewrites config/versions.env with the safe pins.
"""
from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE = ROOT / "config" / "security-baseline.json"
VERSIONS = ROOT / "config" / "versions.env"

PRODUCTS = {
    "php": "php",
    "nginx": "nginx",
    "mariadb": "mariadb",
    "redis": "redis",
    "wordpress": "wordpress",
}


def parse_env(text: str) -> dict[str, str]:
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip()
    return out


def vtuple(v: str) -> tuple[int, ...]:
    """'8.3.11' -> (8, 3, 11). Non-numeric suffixes are dropped."""
    nums = re.findall(r"\d+", v)
    return tuple(int(n) for n in nums) if nums else (0,)


def latest_patch(product: str, cycle: str, timeout: float = 5.0) -> str | None:
    """Ask endoflife.date for the newest release of a cycle."""
    url = f"https://endoflife.date/api/{product}.json"
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            rows = json.load(r)
    except (urllib.error.URLError, TimeoutError, ValueError):
        return None
    for row in rows:
        if str(row.get("cycle")) == str(cycle):
            return row.get("latest")
    return None


def decide(product: str, pinned: str, baseline: dict, online: bool) -> dict:
    """Return {pinned, target, verdict, reason}."""
    entry = baseline.get(product, {})
    minimum = entry.get("min", "0")
    parts = pinned.split(".")
    cycle = ".".join(parts[:2]) if len(parts) >= 2 else parts[0]
    target = pinned
    reasons = []

    if vtuple(pinned) < vtuple(minimum):
        target = minimum
        reasons.append(f"pin {pinned} < baseline {minimum}")

    if online:
        found = latest_patch(PRODUCTS[product], cycle)
        if found and vtuple(found) > vtuple(target):
            target = found
            reasons.append(f"newer patch in the {cycle} cycle: {found}")

    if vtuple(target) > vtuple(pinned):
        return {
            "pinned": pinned,
            "target": target,
            "verdict": "RAISED",
            "reason": "; ".join(reasons) or "security baseline",
        }
    return {"pinned": pinned, "target": pinned, "verdict": "OK", "reason": "at or above baseline"}


def main(argv: list[str]) -> int:
    write = "--write" in argv
    online = "--offline" not in argv

    baseline = json.loads(BASELINE.read_text())
    env = parse_env(VERSIONS.read_text())

    rows, raised = [], 0
    for product in PRODUCTS:
        key = f"{product.upper()}_VERSION"
        pinned = env.get(key)
        if not pinned:
            print(f"  ?  {product:<10} nem pinnelve ({key})")
            continue
        res = decide(product, pinned, baseline, online)
        rows.append((product, res))
        if res["verdict"] != "OK":
            raised += 1

    width = max(len(r[0]) for r in rows) if rows else 8
    print(f"{'component'.ljust(width)}  {'pinned':<10} {'target':<10} verdict")
    print("-" * (width + 36))
    for product, res in rows:
        print(f"{product.ljust(width)}  {res['pinned']:<10} {res['target']:<10} {res['verdict']}  ({res['reason']})")

    if raised and write:
        for product, res in rows:
            if res["verdict"] != "OK":
                env[f"{product.upper()}_VERSION"] = res["target"]
        VERSIONS.write_text(
            "# Rewritten by scripts/lib/version_gate.py — pins raised to a safe patch level.\n"
            + "".join(f"{k}={v}\n" for k, v in env.items())
        )
        print(f"\n→ config/versions.env frissítve ({raised} pin emelve).")

    if raised and not write:
        print("\n✗ A build nem indul: emeld a pineket (`make gate WRITE=1`).")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
