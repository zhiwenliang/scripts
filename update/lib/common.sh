#!/bin/bash

# Shared utilities for AI tool update scripts

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

success_count="${success_count:-0}"
fail_count="${fail_count:-0}"
skip_count="${skip_count:-0}"
failed_tools=("${failed_tools[@]+"${failed_tools[@]}"}")
skipped_tools=("${skipped_tools[@]+"${skipped_tools[@]}"}")

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

fetch_latest_github_release_version() {
    local repo="$1"
    local release_url

    release_url="$(
        curl -fsSLI -o /dev/null -w '%{url_effective}' \
            "https://github.com/${repo}/releases/latest"
    )"

    sed -E 's#.*/tag/v?([^/]+)$#\1#' <<<"$release_url"
}

update_npm_cli() {
    local name="$1"
    local command_name="$2"
    local package_name="$3"
    local current_cmd="$4"
    local install_cmd="$5"
    local latest_version
    local current_version="not installed"

    log_step "Checking" "$name"
    latest_version="$(normalize_version "$(npm view "$package_name" version --silent)")"

    if command -v "$command_name" >/dev/null 2>&1; then
        current_version="$(normalize_version "$(eval "$current_cmd")")"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$latest_version"; then
        log_ok "$name is already up to date"
        track_skip "$name"
        echo ""
        return
    fi

    log_step "Updating" "$name"
    if eval "$install_cmd"; then
        log_ok "$name is now at $(normalize_version "$(eval "$current_cmd")")"
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
