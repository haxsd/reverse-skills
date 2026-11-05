#!/usr/bin/env python3
"""Thin read-only case reviewer for haxsd/reverse-skills v0.1.0."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Review a reverse-skills case directory")
    p.add_argument("case_root", help="path to work/<case>")
    p.add_argument("--verify-hashes", action="store_true", help="accepted for CLI compat; no-op in thin stub")
    p.add_argument("--strict", action="store_true")
    args = p.parse_args(argv)
    root = Path(args.case_root)
    report = {"ok": True, "case": str(root), "problems": []}
    if not root.is_dir():
        report["ok"] = False
        report["problems"].append("case root missing")
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 2
    scope = root / "scope.md"
    if not scope.is_file():
        report["ok"] = False
        report["problems"].append("scope.md missing")
    else:
        text = scope.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"status:\s*(\w+)", text)
        status = m.group(1) if m else "unknown"
        report["auth.status"] = status
        if status != "granted":
            report["ok"] = False
            report["problems"].append("auth.status is not granted")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if args.strict and not report["ok"]:
        return 2
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
