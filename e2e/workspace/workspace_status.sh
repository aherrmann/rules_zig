#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
STATUS_SCRIPT="$SCRIPT_DIR/../../workspace_status.sh"
[[ -f "$STATUS_SCRIPT" ]] && exec "$STATUS_SCRIPT"
