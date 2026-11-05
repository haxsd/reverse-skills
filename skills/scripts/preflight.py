#!/usr/bin/env python3
"""Local package completeness check for reverse-skills itself."""
from __future__ import annotations
import json, os
from pathlib import Path

REQUIRED = [
    "RULES.md",
    "RULES_zh.md",
    "skills/MASTER-ROUTING.md",
    "skills/registry.json",
    "skills/scripts/master-route.ps1",
    "skills/scripts/master-route.sh",
    "skills/scripts/case-init.ps1",
    "skills/scripts/case-init.sh",
    "skills/case-review/scripts/review_case.py",
    "skills/triage/SKILL.md",
    "skills/android-apk/SKILL.md",
]

def main():
    root = Path(__file__).resolve().parents[2]
    missing = [r for r in REQUIRED if not (root / r).exists()]
    print(json.dumps({"ok": not missing, "root": str(root), "missing": missing}, ensure_ascii=False, indent=2))
    return 0 if not missing else 2

if __name__ == "__main__":
    raise SystemExit(main())
