#!/usr/bin/env bash
# Thin master-route for haxsd/reverse-skills v0.1.0
set -euo pipefail
HINT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hint|-Hint) HINT="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: master-route.sh --hint <task>"; exit 0 ;;
    *) HINT="${HINT:-$1}"; shift ;;
  esac
done
HINT_LC=$(printf '%s' "$HINT" | tr '[:upper:]' '[:lower:]')
PRIMARY="skills/triage/"
REASON="default triage for unknown/general sample"
if printf '%s' "$HINT_LC" | grep -Eqi 'apk|xapk|aar|android|jadx|smali|manifest|retrofit|okhttp|安卓|反编译apk'; then
  PRIMARY="skills/android-apk/"
  REASON="Android/APK keywords in hint"
fi
printf 'PRIMARY=%s\n' "$PRIMARY"
printf 'REASON=%s\n' "$REASON"
printf 'HINT=%s\n' "$HINT"
printf 'NEXT=Read %sSKILL.md after case-init scope is ready\n' "$PRIMARY"
