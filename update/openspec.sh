#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_openspec() {
    update_npm_cli \
        "OpenSpec" \
        "openspec" \
        "@fission-ai/openspec" \
        "openspec --version" \
        "npm install -g @fission-ai/openspec@latest"
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_openspec
    print_summary
fi
