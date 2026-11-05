#!/usr/bin/env bash
# Thin case-init for haxsd/reverse-skills — auth gate aware
set -euo pipefail
HINT="" CASE_NAME="" PRESET="" SAMPLE="" PROJECT_ROOT="$(pwd -P)"
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
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$HINT" && -n "$CASE_NAME" ]] || { echo "need --hint and --case-name" >&2; exit 2; }

case "$PRESET" in
  offline-sample|own-sample|local-sample)
    AUTH_STATUS="granted"
    AUTH_BASIS="own_system"
    NETWORK="offline"
    EVIDENCE="${EVIDENCE:-preset:offline-sample (owner-operated local file)}"
    if [[ -n "$SAMPLE" ]]; then
      [[ -f "$SAMPLE" ]] || { echo "sample not found: $SAMPLE" >&2; exit 2; }
      SAMPLE="$(cd "$(dirname "$SAMPLE")" && pwd -P)/$(basename "$SAMPLE")"
    else
      echo "offline-sample preset requires --sample" >&2; exit 2
    fi
    ;;
  ctf-public|ctf)
    AUTH_STATUS="granted"
    AUTH_BASIS="ctf_public"
    NETWORK="${NETWORK:-lab_only}"
    EVIDENCE="${EVIDENCE:-preset:ctf-public}"
    ;;
  "") ;;
  *) echo "unknown preset: $PRESET" >&2; exit 2 ;;
esac

CASE_DIR="$PROJECT_ROOT/work/$CASE_NAME"
mkdir -p "$CASE_DIR/evidence" "$CASE_DIR/timeline"
TS=$(date -Iseconds 2>/dev/null || date)
ASSETS=""
[[ -n "$SAMPLE" ]] && ASSETS="- $SAMPLE"

cat > "$CASE_DIR/scope.md" <<EOF
# Case Scope

## meta
- case_id: $CASE_NAME
- created: $TS
- primary_skill: TBD-after-route
- project_root: $PROJECT_ROOT
- hint: $HINT

## auth
- status: $AUTH_STATUS
- basis: $AUTH_BASIS
- evidence_of_auth: $EVIDENCE
- MUST NOT proceed if status != granted

## in_scope
- assets:
$ASSETS
- surfaces: []
- activities: [reverse, report]

## out_of_scope
- assets: []
- activities: [unauthorized_scan, credential_theft, persistence, edr_bypass]

## network_profile
- mode: $NETWORK
- notes: offline = static local only

## deliverables
- report: true
- timeline: true
EOF

READY=false
[[ "$AUTH_STATUS" == "granted" ]] && READY=true
printf 'CASE_DIR=%s\n' "$CASE_DIR"
printf 'auth.status=%s\n' "$AUTH_STATUS"
printf 'ready_for_act=%s\n' "$READY"
if [[ "$READY" != true ]]; then
  echo "STOP: auth.status is not granted — docs/routing only until granted or offline-sample preset." >&2
  exit 0
fi
