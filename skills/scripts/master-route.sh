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

route_from_hint() {
  # Shared rules: skills/scripts/route-rules.tsv (same file as master-route.* / case-init.ps1).
  # Priority: android > js (incl. Electron/ASAR) > packaged runtime → triage first > binary > default triage
  # Prints "PRIMARY<TAB>REASON"; first matching rule wins, case-insensitive.
  local rules="$1" hint_lc primary reason re
  hint_lc=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
  if [[ ! -f "$rules" ]]; then
    echo "ERROR: routing rules missing: $rules" >&2
    return 2
  fi
  while IFS=$'\t' read -r primary reason re || [[ -n "$primary" ]]; do
    [[ -z "$primary" || "$primary" == \#* || -z "$re" ]] && continue
    if printf '%s' "$hint_lc" | grep -Eqi -e "$re"; then
      printf '%s\t%s\n' "$primary" "$reason"
      return 0
    fi
  done < "$rules"
  printf '%s\t%s\n' 'skills/triage/' 'default triage for unknown/general sample'
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
ROUTE="$(route_from_hint "$ROOT/skills/scripts/route-rules.tsv" "$HINT")" || exit $?
PRIMARY="${ROUTE%%$'\t'*}"
REASON="${ROUTE#*$'\t'}"

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
