#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

HUGO_REPO="gohugoio/hugo"

hugo_release_arch() {
    local machine="${1:-$(uname -m)}"

    case "$machine" in
        x86_64 | amd64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *)
            echo "Unsupported architecture for Hugo release: $machine" >&2
            return 1
            ;;
    esac
}

current_hugo_version() {
    hugo version | awk '{print $2}'
}

install_hugo_release() {
    local version="$1"
    local release_arch
    local archive_name
    local temp_dir

    release_arch="$(hugo_release_arch)"
    archive_name="hugo_extended_${version}_linux-${release_arch}.tar.gz"

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    log_step "Downloading" "$archive_name"
    curl -fsSL "https://github.com/${HUGO_REPO}/releases/download/v${version}/${archive_name}" \
        -o "${temp_dir}/${archive_name}"

    log_step "Installing" "hugo binary"
    tar -C "$temp_dir" -xzf "${temp_dir}/${archive_name}" hugo
    sudo install -m 0755 "${temp_dir}/hugo" /usr/local/bin/hugo
    log_ok "hugo is now at $(normalize_version "$(current_hugo_version)")"
}

update_hugo() {
    log_step "Checking" "hugo"
    latest_version="$(normalize_version "$(fetch_latest_github_release_version "$HUGO_REPO")")"

    if command -v hugo >/dev/null 2>&1; then
        current_version="$(normalize_version "$(current_hugo_version)")"
    else
        current_version="not installed"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$latest_version"; then
        log_ok "hugo is already up to date"
        return 0
    fi

    install_hugo_release "$latest_version"
}

if [[ "${UPDATE_LIB_ONLY:-0}" != "1" ]]; then
    update_hugo
fi
