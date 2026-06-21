#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

HUGO_REPO="gohugoio/hugo"

current_hugo_version() {
    hugo version | awk '{print $2}'
}

install_hugo_release() {
    local version="$1"
    local archive_name="hugo_extended_${version}_linux-amd64.tar.gz"
    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT

    log_step "Downloading" "$archive_name"
    curl -fsSL "https://github.com/${HUGO_REPO}/releases/download/v${version}/${archive_name}" \
        -o "${temp_dir}/${archive_name}"

    log_step "Installing" "hugo binary"
    tar -C "$temp_dir" -xzf "${temp_dir}/${archive_name}" hugo
    sudo install -m 0755 "${temp_dir}/hugo" /usr/local/bin/hugo
    log_ok "hugo is now at $(normalize_version "$(current_hugo_version)")"
}

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
    exit 0
fi

install_hugo_release "$latest_version"
