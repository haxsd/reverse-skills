# reverse-skills

Lean reverse-engineering **agent skills**: auth/scope gates, routing, triage, and one Android/APK end-to-end playbook.

Install: `git clone https://github.com/haxsd/reverse-skills.git` → `$HOME/tools/reverse-skills` (set `REVERSE_SKILL_ROOT`).

Hot path: `RULES.md` → `master-route.*` → `case-init.*` → `check-tools.*` → PRIMARY skill. Scripts honor `REVERSE_SKILL_ROOT` (else repo root).

First batch: `triage`, `android-apk`. No pentest payloads / EDR bypass. Upstream credits in `ATTRIBUTION.md` / `NOTICE`.
