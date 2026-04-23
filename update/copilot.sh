#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_copilot() {
    update_npm_cli \
        "GitHub Copilot CLI" \
        "copilot" \
        "@github/copilot" \
        "copilot version 2>/dev/null | grep -Eo '[0-9]+(\\.[0-9]+)+' | head -n1" \
        "npm_config_ignore_scripts=false npm install -g @github/copilot@latest"
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_copilot
    print_summary
fi
