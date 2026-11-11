#!/usr/bin/env python3
"""Check registry.json prerequisites. Honest degrade — never silent."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def resolve_root() -> Path:
    raw = os.environ.get("REVERSE_SKILL_ROOT", "").strip()
    if raw:
        candidate = Path(raw).expanduser().resolve()
        if candidate.is_dir() and (candidate / "skills" / "registry.json").is_file():
            return candidate
        print(f"ERROR: REVERSE_SKILL_ROOT is set but invalid: {candidate}", file=sys.stderr)
        raise SystemExit(2)
    here = Path(__file__).resolve().parent
    candidate = here.parents[1]
    if (candidate / "skills" / "registry.json").is_file():
        return candidate
    print("ERROR: cannot resolve skill root; set REVERSE_SKILL_ROOT", file=sys.stderr)
    raise SystemExit(2)


def tool_present(tool: str, check_argv: list[str]) -> tuple[bool, str]:
    if shutil.which(tool) is None and (not check_argv or shutil.which(check_argv[0]) is None):
        return False, ""
    cmd = list(check_argv) if check_argv else [tool, "--version"]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=8)
        out = (p.stdout or p.stderr or "").strip().splitlines()
        ver = out[0] if out else "present"
        return True, ver[:120]
    except Exception:
        return True, "present"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Check reverse-skills registry tool prerequisites")
    ap.add_argument("--skill", default="all", help="skill id or 'all'")
    args = ap.parse_args(argv)

    root = resolve_root()
    reg_path = root / "skills" / "registry.json"
    if not reg_path.is_file():
        print(f"ERROR: registry missing: {reg_path}", file=sys.stderr)
        return 2

    data = json.loads(reg_path.read_text(encoding="utf-8"))
    skills = data.get("skills") or {}
    skill_filter = args.skill
    if skill_filter != "all":
        if skill_filter not in skills:
            print(f"ERROR: unknown skill id: {skill_filter}", file=sys.stderr)
            print(f"KNOWN={','.join(sorted(skills))}", file=sys.stderr)
            return 2
        skills = {skill_filter: skills[skill_filter]}

    print(f"ROOT={root}")
    print(f"SKILL_FILTER={skill_filter}")

    missing_required: list[str] = []
    any_missing_optional = False

    for sid, meta in skills.items():
        prereqs = meta.get("prerequisites") or []
        print(f"SKILL={sid}")
        if not prereqs:
            print("NOTE=no prerequisites listed in registry")
            continue
        for item in prereqs:
            tool = item.get("tool") or "?"
            optional = bool(item.get("optional"))
            check = item.get("check") or [tool, "--version"]
            ok, detail = tool_present(tool, list(check))
            status = "ok" if ok else "missing"
            req = "false" if optional else "true"
            line = f"TOOL={tool} STATUS={status} REQUIRED={req} SKILL={sid}"
            if ok and detail:
                line += f" DETAIL={detail}"
            print(line)
            if not ok and not optional:
                missing_required.append(f"{sid}:{tool}")
            if not ok and optional:
                any_missing_optional = True
                print(f"DEGRADE_OPTIONAL={sid}:{tool}")

    # Optional REA backend (MASTER-ROUTING «可选执行后端»): never a dependency, never affects exit code.
    rea_hits = [f"{name}={shutil.which(name)}" for name in ("rea", "rea-agents") if shutil.which(name)]
    if rea_hits:
        print(f"NOTE=optional REA detected ({', '.join(rea_hits)}); may be used as optional execution backend, not required")

    if missing_required:
        for m in missing_required:
            print(f"MISSING_REQUIRED={m}")
        print("DEGRADED=true")
        print(
            "HINT=Install missing required tools or continue with documented static-only degrade; "
            "do not invent tool output.",
            file=sys.stderr,
        )
        return 1

    print("DEGRADED=false" if not any_missing_optional else "DEGRADED=optional-only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
