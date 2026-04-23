#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_gemini() {
    update_npm_cli \
        "Gemini CLI" \
        "gemini" \
        "@google/gemini-cli" \
        "gemini --version | head -n1" \
        "npm install -g @google/gemini-cli@latest"
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_gemini
    print_summary
fi
