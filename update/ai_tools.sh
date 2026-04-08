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

update_claude_code() {
    local name="Claude Code"
    local latest_version
    local current_version="not installed"

    log_step "Checking" "$name"
    latest_version="$(normalize_version "$(npm view @anthropic-ai/claude-code version --silent)")"

    if command -v claude >/dev/null 2>&1; then
        current_version="$(normalize_version "$(claude --version | awk '{print $1}')")"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$latest_version"; then
        log_ok "$name is already up to date"
        track_skip "$name"
        echo ""
        return
    fi

    if command -v claude >/dev/null 2>&1; then
        log_step "Updating" "$name with claude update"
        if claude update; then
            log_ok "$name is now at $(normalize_version "$(claude --version | awk '{print $1}')")"
            track_success
        else
            log_fail "$name update failed"
            track_failure "$name"
        fi
    else
        log_step "Installing" "$name via the official installer"
        if curl -fsSL https://claude.ai/install.sh | bash; then
            log_ok "$name installed successfully"
            track_success
        else
            log_fail "$name install failed"
            track_failure "$name"
        fi
    fi

    echo ""
}

fetch_latest_opencode_version() {
    local response
    response="$(curl -fsSL https://api.github.com/repos/sst/opencode/releases/latest)"
    echo "$response" | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/'
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
    if curl -fsSL https://opencode.ai/install | bash; then
        log_ok "$name is now at $(normalize_version "$(opencode --version | awk '{print $1}')")"
        track_success
    else
        log_fail "$name update failed"
        track_failure "$name"
    fi

    echo ""
}

fetch_latest_speckit_version() {
    local response
    response="$(curl -fsSL https://api.github.com/repos/github/spec-kit/tags)"
    echo "$response" | grep -m1 '"name"' | sed -E 's/.*"v?([^"]+)".*/\1/'
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

update_claude_code
update_npm_cli \
    "Codex CLI" \
    "codex" \
    "@openai/codex" \
    "codex --version 2>/dev/null | awk '{print \$2}'" \
    "npm install -g @openai/codex@latest"
update_npm_cli \
    "Gemini CLI" \
    "gemini" \
    "@google/gemini-cli" \
    "gemini --version | head -n1" \
    "npm install -g @google/gemini-cli@latest"
update_opencode
update_npm_cli \
    "OpenSpec" \
    "openspec" \
    "@fission-ai/openspec" \
    "openspec --version" \
    "npm install -g @fission-ai/openspec@latest"
update_spec_kit

print_summary
