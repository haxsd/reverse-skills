#!/usr/bin/env python3
"""Thin read-only case reviewer for haxsd/reverse-skills v0.3.0."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


FINAL_STATUSES = ("answered", "partially-answered", "unresolved")


def review_questions(root: Path) -> dict | None:
    """Check work/<case>/questions.md entries carry a final status.

    Entries are "## ..." headings (HTML comments, e.g. the case-init example, are ignored).
    Returns None when the file is absent; otherwise a summary with warnings.
    """
    path = root / "questions.md"
    if not path.is_file():
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    entries: list[tuple[str, str]] = []
    title = None
    body: list[str] = []
    for line in text.splitlines():
        m = re.match(r"^##\s+(.*\S)\s*$", line)
        if m:
            if title is not None:
                entries.append((title, "\n".join(body)))
            title, body = m.group(1), []
        elif title is not None:
            body.append(line)
    if title is not None:
        entries.append((title, "\n".join(body)))

    summary: dict = {"entries": len(entries), "counts": {}, "warnings": []}
    for title, body_text in entries:
        m = re.search(r"^\s*[-*]?\s*status:\s*([A-Za-z_-]+)", body_text, flags=re.M | re.I)
        status = m.group(1).lower() if m else ""
        key = status or "missing"
        summary["counts"][key] = summary["counts"].get(key, 0) + 1
        if not status:
            summary["warnings"].append(f"questions.md: '{title}' has no status (need one of {'/'.join(FINAL_STATUSES)})")
        elif status == "unanswered":
            summary["warnings"].append(f"questions.md: '{title}' is still unanswered (not finished)")
        elif status not in FINAL_STATUSES:
            summary["warnings"].append(f"questions.md: '{title}' has unknown status '{status}' (need one of {'/'.join(FINAL_STATUSES)})")
    return summary


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
    questions = review_questions(root)
    if questions is not None:
        report["questions"] = {"entries": questions["entries"], "counts": questions["counts"]}
        if questions["warnings"]:
            report.setdefault("warnings", []).extend(questions["warnings"])
            if args.strict:
                report["ok"] = False
                report["problems"].append("questions.md has entries without a final status (--strict)")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    for w in report.get("warnings", []):
        print(f"WARNING: {w}", file=sys.stderr)
    if args.strict and not report["ok"]:
        return 2
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
