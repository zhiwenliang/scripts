#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

CODEX_INSTALLER_URL="https://chatgpt.com/codex/install.sh"

fetch_latest_codex_version() {
    fetch_latest_github_release_version "openai/codex" | sed -E 's/^rust-v//'
}

current_codex_version() {
    codex --version 2>/dev/null | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n1
}

run_codex_installer() {
    curl -fsSL "$CODEX_INSTALLER_URL" | bash
}

update_codex() {
    local name="Codex CLI"
    local latest_version
    local latest_version_raw
    local current_version="not installed"

    log_step "Checking" "$name"
    if ! latest_version_raw="$(fetch_latest_codex_version)"; then
        log_fail "$name latest version lookup failed"
        track_failure "$name"
        echo ""
        return
    fi
    latest_version="$(normalize_version "$latest_version_raw")"
    if [[ -z "$latest_version" ]]; then
        log_fail "$name latest version lookup failed"
        track_failure "$name"
        echo ""
        return
    fi

    if command -v codex >/dev/null 2>&1; then
        current_version="$(normalize_version "$(current_codex_version)")"
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
    if run_codex_installer; then
        log_ok "$name is now at $(normalize_version "$(current_codex_version)")"
        track_success
    else
        log_fail "$name update failed"
        track_failure "$name"
    fi

    echo ""
}

if [[ "${AI_TOOLS_LIB_ONLY:-0}" != "1" ]]; then
    update_codex
    print_summary
fi
