#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

fetch_latest_opencode_version() {
    fetch_latest_github_release_version "sst/opencode"
}

run_opencode_installer() {
    local version="$1"

    curl -fsSL https://opencode.ai/install | "${INSTALLER_SHELL:-bash}" -s -- --version "$version"
}

update_opencode() {
    local name="OpenCode"
    local latest_version
    local current_version="not installed"

    log_step "Checking" "$name"
    latest_version="$(normalize_version "$(fetch_latest_opencode_version)")"

    if command -v opencode >/dev/null 2>&1; then
        current_version="$(normalize_version "$(opencode --version | awk '{print $1}')")"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$latest_version"; then
        log_ok "$name is already up to date"
        track_skip "$name"
        echo ""
        return
    fi

    log_step "Updating" "$name via the official installer"
    if run_opencode_installer "$latest_version"; then
        log_ok "$name is now at $(normalize_version "$(opencode --version | awk '{print $1}')")"
        track_success
    else
        log_fail "$name update failed"
        track_failure "$name"
    fi

    echo ""
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_opencode
    print_summary
fi
