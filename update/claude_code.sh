#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_claude_code() {
    local name="Claude Code"
    local latest_version
    local current_version="not installed"
    local action="Installing"
    local action_lc="install"

    log_step "Checking" "$name"
    latest_version="$(normalize_version "$(npm view @anthropic-ai/claude-code version --silent)")"

    if command -v claude >/dev/null 2>&1; then
        current_version="$(normalize_version "$(claude --version | awk '{print $1}')")"
        action="Updating"
        action_lc="update"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$latest_version"; then
        log_ok "$name is already up to date"
        track_skip "$name"
        echo ""
        return
    fi

    log_step "$action" "$name via the official installer"

    if curl -fsSL https://claude.ai/install.sh | bash; then
        log_ok "$name is now at $(normalize_version "$(claude --version | awk '{print $1}')")"
        track_success
    else
        log_fail "$name $action_lc failed"
        track_failure "$name"
    fi

    echo ""
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_claude_code
    print_summary
fi
