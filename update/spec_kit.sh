#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

fetch_latest_speckit_version() {
    fetch_latest_github_release_version "github/spec-kit"
}

update_spec_kit() {
    local name="Spec-Kit"
    local latest_version
    local current_version="not installed"

    log_step "Checking" "$name"

    if ! command -v uv >/dev/null 2>&1; then
        log_fail "uv is not installed (required for $name)"
        track_failure "$name"
        echo ""
        return
    fi

    latest_version="$(normalize_version "$(fetch_latest_speckit_version)")"

    if command -v specify >/dev/null 2>&1; then
        current_version="$(normalize_version "$(uv tool list 2>/dev/null | grep '^specify-cli' | awk '{print $2}')")"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$latest_version"; then
        log_ok "$name is already up to date"
        track_skip "$name"
        echo ""
        return
    fi

    if command -v specify >/dev/null 2>&1; then
        log_step "Updating" "$name"
        if uv tool install specify-cli --from "git+https://github.com/github/spec-kit.git@v${latest_version}" --force; then
            log_ok "$name is now at $(normalize_version "$(uv tool list 2>/dev/null | grep '^specify-cli' | awk '{print $2}')")"
            track_success
        else
            log_fail "$name update failed"
            track_failure "$name"
        fi
    else
        log_step "Installing" "$name"
        if uv tool install specify-cli --from "git+https://github.com/github/spec-kit.git@v${latest_version}"; then
            log_ok "$name installed successfully"
            track_success
        else
            log_fail "$name install failed"
            track_failure "$name"
        fi
    fi

    echo ""
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_spec_kit
    print_summary
fi
