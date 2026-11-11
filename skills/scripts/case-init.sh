#!/usr/bin/env bash
# Thin case-init for haxsd/reverse-skills — auth gate aware; bash ↔ pwsh aligned
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

HINT="" CASE_NAME="" PRESET="" SAMPLE="" PROJECT_ROOT=""
AUTH_STATUS="pending" AUTH_BASIS="unknown" NETWORK="lab_only" EVIDENCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hint|-Hint) HINT="${2:-}"; shift 2 ;;
    --case-name|-CaseName) CASE_NAME="${2:-}"; shift 2 ;;
    --preset|-Preset) PRESET="${2:-}"; shift 2 ;;
    --sample|-Sample) SAMPLE="${2:-}"; shift 2 ;;
    --project-root|-ProjectRoot) PROJECT_ROOT="${2:-}"; shift 2 ;;
    --auth-granted|-AuthGranted) AUTH_STATUS="granted"; shift ;;
    --network-profile|-NetworkProfile) NETWORK="${2:-}"; shift 2 ;;
    --auth-basis|-AuthBasis) AUTH_BASIS="${2:-}"; shift 2 ;;
    --evidence-of-auth|-EvidenceOfAuth) EVIDENCE="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: case-init.sh --hint TEXT --case-name NAME [--preset offline-sample --sample FILE]"
      echo "Env: REVERSE_SKILL_ROOT (optional)"
      exit 0 ;;
    *) echo "ERROR: Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$HINT" || -z "$CASE_NAME" ]]; then
  echo "ERROR: need --hint and --case-name" >&2
  exit 2
fi

ROOT="$(resolve_root)" || exit $?
ROUTE="$(route_from_hint "$ROOT/skills/scripts/route-rules.tsv" "$HINT")" || exit $?
PRIMARY="${ROUTE%%$'\t'*}"
PRIMARY_ABS="$ROOT/$PRIMARY"
SKILL_MD="${PRIMARY_ABS}SKILL.md"
if [[ ! -f "$SKILL_MD" ]]; then
  echo "ERROR: PRIMARY skill missing: $SKILL_MD" >&2
  exit 2
fi

if [[ -z "$PROJECT_ROOT" ]]; then
  PROJECT_ROOT="$(pwd -P)"
else
  [[ -d "$PROJECT_ROOT" ]] || { echo "ERROR: --project-root not a directory: $PROJECT_ROOT" >&2; exit 2; }
  PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd -P)"
fi

case "$PRESET" in
  offline-sample|own-sample|local-sample)
    AUTH_STATUS="granted"
    AUTH_BASIS="own_system"
    NETWORK="offline"
    EVIDENCE="${EVIDENCE:-preset:offline-sample (owner-operated local file)}"
    if [[ -z "$SAMPLE" ]]; then
      echo "ERROR: offline-sample preset requires --sample" >&2
      exit 2
    fi
    if [[ ! -f "$SAMPLE" ]]; then
      echo "ERROR: sample not found: $SAMPLE" >&2
      exit 2
    fi
    SAMPLE="$(cd "$(dirname "$SAMPLE")" && pwd -P)/$(basename "$SAMPLE")"
    ;;
  ctf-public|ctf)
    AUTH_STATUS="granted"
    AUTH_BASIS="ctf_public"
    NETWORK="${NETWORK:-lab_only}"
    EVIDENCE="${EVIDENCE:-preset:ctf-public}"
    ;;
  "") ;;
  *) echo "ERROR: unknown preset: $PRESET" >&2; exit 2 ;;
esac

CASE_DIR="$PROJECT_ROOT/work/$CASE_NAME"
mkdir -p "$CASE_DIR/evidence" "$CASE_DIR/timeline"
TS=$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
ASSETS=""
[[ -n "$SAMPLE" ]] && ASSETS="- $SAMPLE"

# LF-only scope.md for cross-platform agents
{
  printf '%s\n' "# Case Scope" ""
  printf '%s\n' "## meta"
  printf '%s\n' "- case_id: $CASE_NAME"
  printf '%s\n' "- created: $TS"
  printf '%s\n' "- primary_skill: $PRIMARY"
  printf '%s\n' "- project_root: $PROJECT_ROOT"
  printf '%s\n' "- skill_root: $ROOT"
  printf '%s\n' "- hint: $HINT" ""
  printf '%s\n' "## auth"
  printf '%s\n' "- status: $AUTH_STATUS"
  printf '%s\n' "- basis: $AUTH_BASIS"
  printf '%s\n' "- evidence_of_auth: $EVIDENCE"
  printf '%s\n' "- MUST NOT proceed if status != granted"
  printf '%s\n' "- 检查≠运行/抓包/附加/碰设备账号：获准检查样本不等于获准运行、抓网络、附加进程或触碰设备/账号；这些动作须单独写进 in_scope.activities（离开本地文件还需非 offline 的 network_profile）" ""
  printf '%s\n' "## in_scope"
  printf '%s\n' "- assets:"
  if [[ -n "$ASSETS" ]]; then printf '%s\n' "$ASSETS"; fi
  printf '%s\n' "- surfaces: []"
  printf '%s\n' "- activities: [reverse, report]" ""
  printf '%s\n' "## out_of_scope"
  printf '%s\n' "- assets: []"
  printf '%s\n' "- activities: [unauthorized_scan, credential_theft, persistence, edr_bypass]" ""
  printf '%s\n' "## network_profile"
  printf '%s\n' "- mode: $NETWORK"
  printf '%s\n' "- notes: offline = static local only" ""
  printf '%s\n' "## deliverables"
  printf '%s\n' "- report: true"
  printf '%s\n' "- timeline: true"
  printf '%s\n' "- questions: true"
} > "$CASE_DIR/scope.md"

# questions.md template (kept if it already exists — it holds case work)
if [[ ! -f "$CASE_DIR/questions.md" ]]; then
  {
    printf '%s\n' '# Questions'
    printf '%s\n' ""
    printf '%s\n' '<!--'
    printf '%s\n' '大任务（覆盖多个功能或子系统）先在这里列问题，以及每条需要什么证据；见 skills/core/evidence-labels.md。'
    printf '%s\n' '每条一个 "## Q<n>: <问题>" 小节，新条目默认 status: unanswered。'
    printf '%s\n' '收尾时每条必须改成且只能是其一：answered（已回答） / partially-answered（部分回答） / unresolved（未解决）。'
    printf '%s\n' '有界否定写成「在范围 X 内未找到」，不能写成「不存在」。review_case.py 会核对状态（--strict 时缺状态或仍为 unanswered 判失败）。'
    printf '%s\n' ""
    printf '%s\n' '示例：'
    printf '%s\n' '## Q1: <问题>'
    printf '%s\n' '- evidence_needed: <需要什么证据>'
    printf '%s\n' '- status: unanswered'
    printf '%s\n' '- answer: <结论 + 证据标签，或有界否定>'
    printf '%s\n' '-->'
  } > "$CASE_DIR/questions.md"
fi

READY=false
[[ "$AUTH_STATUS" == "granted" ]] && READY=true
printf 'ROOT=%s\n' "$ROOT"
printf 'PRIMARY=%s\n' "$PRIMARY"
printf 'CASE_DIR=%s\n' "$CASE_DIR"
printf 'auth.status=%s\n' "$AUTH_STATUS"
printf 'ready_for_act=%s\n' "$READY"
if [[ "$READY" != true ]]; then
  echo "STOP: auth.status is not granted — docs/routing only until granted or offline-sample preset." >&2
  exit 0
fi
