#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

update_hermes() {
    local name="Hermes Agent"
    local current_version="not installed"
    local action="Installing"

    log_step "Checking" "$name"

    if command -v hermes >/dev/null 2>&1; then
        current_version="$(hermes --version 2>/dev/null | head -n1 | grep -oE 'v[0-9]+(\.[0-9]+)*' || echo "unknown")"
        action="Updating"
    fi

    echo "Current version: ${current_version}"

    if [[ "$current_version" == "not installed" ]]; then
        log_step "$action" "$name via official installer"
        if curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash; then
            local new_version
            new_version="$(hermes --version 2>/dev/null | head -n1 | grep -oE 'v[0-9]+(\.[0-9]+)*' || echo "unknown")"
            log_ok "$name is now at ${new_version}"
            track_success
        else
            log_fail "$name installation failed"
            track_failure "$name"
        fi
    else
        log_step "$action" "$name"
        # --yes: never block on interactive prompts (config migration / stash
        # restore). A bare `hermes update` can sit forever waiting on stdin,
        # which looks like a hang. The heavy phase is a silent `npm install`
        # of the JS workspace; it emits no output but is not stuck.
        if hermes update --yes; then
            local new_version
            new_version="$(hermes --version 2>/dev/null | head -n1 | grep -oE 'v[0-9]+(\.[0-9]+)*' || echo "unknown")"
            log_ok "$name is now at ${new_version}"
            track_success
        else
            log_fail "$name update failed"
            track_failure "$name"
        fi
    fi

    echo ""
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_hermes
    print_summary
fi
