#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

AI_TOOLS_LIB_ONLY=1
source "${SCRIPT_DIR}/claude_code.sh"
source "${SCRIPT_DIR}/codex.sh"
source "${SCRIPT_DIR}/copilot.sh"
source "${SCRIPT_DIR}/gemini.sh"
source "${SCRIPT_DIR}/opencode.sh"
source "${SCRIPT_DIR}/openspec.sh"
source "${SCRIPT_DIR}/spec_kit.sh"

main() {
    echo "========================================"
    echo "  AI Tools Updater"
    echo "========================================"
    echo ""

    update_claude_code
    update_codex
    update_copilot
    update_gemini
    update_opencode
    update_openspec
    update_spec_kit

    print_summary
}

main "$@"
