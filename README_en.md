# reverse-skills

Lean reverse-engineering **agent skills**: auth/scope gates, routing, triage, Android/APK, JS deobfuscation/param chains (including desktop Electron/ASAR), and native ELF/PE/Mach-O deep analysis.

Install: `git clone https://github.com/haxsd/reverse-skills.git` → `$HOME/tools/reverse-skills` (set `REVERSE_SKILL_ROOT`).

Hot path: `RULES.md` → `master-route.*` → `case-init.*` → `check-tools.*` → PRIMARY skill. Scripts honor `REVERSE_SKILL_ROOT` (else repo root). If a complete source tree is already in hand, read the source first. Broad work starts with `work/<case>/questions.md`.

Modules: `triage`, `android-apk`, `js-reverse`, `binary-reverse` (v0.3.0). Packaged runtimes (PyInstaller, Bun/Deno compile, NativeAOT, Go) are triaged to the real application layer before deep work. No pentest payloads / EDR bypass. If [REA](https://github.com/morluto/rea) (`npx rea-agents`) is already installed, it may be used as an optional execution backend; it is not required and is not vendored. Upstream credits in `ATTRIBUTION.md` / `NOTICE`.
