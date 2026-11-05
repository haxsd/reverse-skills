#!/usr/bin/env bash
# Thin master-route for haxsd/reverse-skills — bash ↔ pwsh aligned
set -euo pipefail

resolve_root() {
  local candidate=""
  if [[ -n "${REVERSE_SKILL_ROOT:-}" ]]; then
    candidate="${REVERSE_SKILL_ROOT}"
    if [[ -d "$candidate" && -f "$candidate/skills/registry.json" ]]; then
      (cd "$candidate" && pwd -P)
      return 0
    fi
    echo "ERROR: REVERSE_SKILL_ROOT is set but invalid: $candidate (need skills/registry.json)" >&2
    return 2
  fi
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  candidate="$(cd "$here/../.." && pwd -P)"
  if [[ -f "$candidate/skills/registry.json" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  echo "ERROR: cannot resolve skill root; set REVERSE_SKILL_ROOT or run from the cloned repo" >&2
  return 2
}

HINT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hint|-Hint) HINT="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: master-route.sh --hint <task>"
      echo "Env: REVERSE_SKILL_ROOT (optional; defaults to repo containing this script)"
      exit 0 ;;
    *)
      if [[ -z "$HINT" ]]; then HINT="$1"; shift; else echo "Unknown arg: $1" >&2; exit 2; fi
      ;;
  esac
done

if [[ -z "$HINT" ]]; then
  echo "ERROR: Usage: master-route.sh --hint <task>" >&2
  exit 2
fi

ROOT="$(resolve_root)" || exit $?
HINT_LC=$(printf '%s' "$HINT" | tr '[:upper:]' '[:lower:]')
PRIMARY="skills/triage/"
REASON="default triage for unknown/general sample"
# Priority: android-apk > js-reverse > binary-reverse > triage
if printf '%s' "$HINT_LC" | grep -Eqi 'apk|xapk|aar|android|jadx|smali|manifest|retrofit|okhttp|安卓|反编译apk'; then
  PRIMARY="skills/android-apk/"
  REASON="Android/APK keywords in hint"
elif printf '%s' "$HINT_LC" | grep -Eqi 'javascript|\bjs\b|webpack|obfuscator|sourcemap|解混淆|前端签名|加密参数|js逆向|deobfuscat|bundle\.js|\.mjs'; then
  PRIMARY="skills/js-reverse/"
  REASON="JS/deobfuscation/signing keywords in hint"
elif printf '%s' "$HINT_LC" | grep -Eqi 'ghidra|\bida\b|radare|rizin|反汇编|反编译|binary-reverse|\belf\b|mach-o|macho|\bpe\b|\.so\b|\.dll\b|\.exe\b|原生二进制'; then
  PRIMARY="skills/binary-reverse/"
  REASON="native binary deep-analysis keywords in hint"
fi

PRIMARY_ABS="$ROOT/$PRIMARY"
SKILL_MD="${PRIMARY_ABS}SKILL.md"
if [[ ! -f "$SKILL_MD" ]]; then
  echo "ERROR: PRIMARY skill missing: $SKILL_MD" >&2
  exit 2
fi

printf 'ROOT=%s\n' "$ROOT"
printf 'PRIMARY=%s\n' "$PRIMARY"
printf 'PRIMARY_ABS=%s\n' "$PRIMARY_ABS"
printf 'REASON=%s\n' "$REASON"
printf 'HINT=%s\n' "$HINT"
printf 'NEXT=Read %s after case-init scope is ready\n' "$SKILL_MD"
