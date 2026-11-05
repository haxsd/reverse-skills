#!/usr/bin/env bash
# Wrapper: registry tool check (shared implementation: check_tools.py)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 required (not found in PATH)" >&2
  exit 2
fi
exec python3 "$HERE/check_tools.py" "$@"
