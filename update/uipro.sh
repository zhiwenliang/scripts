#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_uipro() {
    update_npm_cli \
        "UI-UX Pro Max CLI" \
        "uipro" \
        "uipro-cli" \
        "npm list -g uipro-cli --depth=0 2>/dev/null | grep uipro-cli@ | sed 's/.*@//'" \
        "npm install -g uipro-cli@latest"
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_uipro
    print_summary
fi
