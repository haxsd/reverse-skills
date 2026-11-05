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
  printf '%s\n' "- primary_skill: TBD-after-route"
  printf '%s\n' "- project_root: $PROJECT_ROOT"
  printf '%s\n' "- skill_root: $ROOT"
  printf '%s\n' "- hint: $HINT" ""
  printf '%s\n' "## auth"
  printf '%s\n' "- status: $AUTH_STATUS"
  printf '%s\n' "- basis: $AUTH_BASIS"
  printf '%s\n' "- evidence_of_auth: $EVIDENCE"
  printf '%s\n' "- MUST NOT proceed if status != granted" ""
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
} > "$CASE_DIR/scope.md"

READY=false
[[ "$AUTH_STATUS" == "granted" ]] && READY=true
printf 'ROOT=%s\n' "$ROOT"
printf 'CASE_DIR=%s\n' "$CASE_DIR"
printf 'auth.status=%s\n' "$AUTH_STATUS"
printf 'ready_for_act=%s\n' "$READY"
if [[ "$READY" != true ]]; then
  echo "STOP: auth.status is not granted — docs/routing only until granted or offline-sample preset." >&2
  exit 0
fi
