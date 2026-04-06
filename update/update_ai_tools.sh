#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

success_count=0
fail_count=0
skip_count=0
failed_tools=()
skipped_tools=()

log_step() {
    echo -e "${YELLOW}[$1]${NC} $2"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

normalize_version() {
    local version="$1"
    version="${version#v}"
    version="${version#go}"
    echo "${version%%[^0-9.]*}"
}

version_lt() {
    local left="$1"
    local right="$2"
    [[ "$(printf '%s\n%s\n' "$left" "$right" | sort -V | head -n1)" == "$left" && "$left" != "$right" ]]
}

track_success() {
    ((success_count += 1))
}

track_skip() {
    skipped_tools+=("$1")
    ((skip_count += 1))
}

track_failure() {
    failed_tools+=("$1")
    ((fail_count += 1))
}

fetch_latest_openclaw_version() {
    npm view openclaw version --silent
}

current_openclaw_version() {
    openclaw --version | awk '{print $2}'
}

install_openclaw() {
    curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
}

update_openclaw_command() {
    openclaw update --yes
}

update_openclaw() {
    local name="OpenClaw"
    local latest_version
    local current_version

    log_step "Checking" "$name"
    latest_version="$(normalize_version "$(fetch_latest_openclaw_version)")"

    if command -v openclaw >/dev/null 2>&1; then
        current_version="$(normalize_version "$(current_openclaw_version)")"
        echo "Current version: ${current_version}"
        echo "Latest version:  ${latest_version}"

        if ! version_lt "$current_version" "$latest_version"; then
            log_ok "$name is already up to date"
            track_skip "$name"
            echo ""
            return
        fi

        log_step "Updating" "$name with openclaw update"
    else
        echo "Current version: not installed"
        echo "Latest version:  ${latest_version}"
        log_step "Installing" "$name via the official installer"
    fi

    if {
        if command -v openclaw >/dev/null 2>&1; then
            update_openclaw_command
        else
            install_openclaw
        fi
    }; then
        log_ok "$name is now at $(normalize_version "$(current_openclaw_version)")"
        track_success
    else
        log_fail "$name update failed"
        track_failure "$name"
    fi

    echo ""
}

print_summary() {
    echo "========================================"
    echo "  Summary: ${success_count} updated, ${skip_count} skipped, ${fail_count} failed"
    if [[ ${skip_count} -gt 0 ]]; then
        echo -e "  ${YELLOW}Skipped:${NC} ${skipped_tools[*]}"
    fi
    if [[ ${fail_count} -gt 0 ]]; then
        echo -e "  ${RED}Failed:${NC} ${failed_tools[*]}"
    fi
    echo "========================================"
}

echo "========================================"
echo "  AI Tools Updater"
echo "========================================"
echo ""

update_openclaw
print_summary
