#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_codex() {
    update_npm_cli \
        "Codex CLI" \
        "codex" \
        "@openai/codex" \
        "codex --version 2>/dev/null | awk '{print \$2}'" \
        "npm install -g @openai/codex@latest"
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_codex
    print_summary
fi
