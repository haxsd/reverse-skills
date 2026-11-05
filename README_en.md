# reverse-skills

Lean reverse-engineering **agent skills**: auth/scope gates, routing, triage, Android/APK, JS deobfuscation/param chains, and native ELF/PE/Mach-O deep analysis.

Install: `git clone https://github.com/haxsd/reverse-skills.git` → `$HOME/tools/reverse-skills` (set `REVERSE_SKILL_ROOT`).

Hot path: `RULES.md` → `master-route.*` → `case-init.*` → `check-tools.*` → PRIMARY skill. Scripts honor `REVERSE_SKILL_ROOT` (else repo root).

Modules: `triage`, `android-apk`, `js-reverse`, `binary-reverse` (v0.2.0). No pentest payloads / EDR bypass. Upstream credits in `ATTRIBUTION.md` / `NOTICE`.
