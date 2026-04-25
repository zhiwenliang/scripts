#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

HUGO_REPO="gohugoio/hugo"
HUGO_ARCHIVE_PATTERN="hugo_extended_%s_linux-amd64.tar.gz"

fetch_latest_hugo_version() {
    curl -fsSL "https://api.github.com/repos/${HUGO_REPO}/releases/latest" \
        | grep -m1 '"tag_name"' \
        | sed -E 's/.*"v?([^"]+)".*/\1/'
}

current_hugo_version() {
    hugo version | awk '{print $2}'
}

install_hugo_release() {
    local version="$1"
    local archive_name
    local temp_dir

    archive_name="$(printf "$HUGO_ARCHIVE_PATTERN" "$version")"
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    echo "Downloading ${archive_name}"
    curl -fsSL "https://github.com/${HUGO_REPO}/releases/download/v${version}/${archive_name}" \
        -o "${temp_dir}/${archive_name}"

    echo "Extracting hugo binary"
    tar -C "$temp_dir" -xzf "${temp_dir}/${archive_name}" hugo
    sudo install -m 0755 "${temp_dir}/hugo" /usr/local/bin/hugo
    echo "Installed version: $(normalize_version "$(current_hugo_version)")"
}

latest_version="$(fetch_latest_hugo_version)"
latest_version_normalized="$(normalize_version "$latest_version")"

if command -v hugo >/dev/null 2>&1; then
    current_version="$(current_hugo_version)"
    current_version_normalized="$(normalize_version "$current_version")"
else
    current_version="not installed"
    current_version_normalized=""
fi

echo "Current version: ${current_version}"
echo "Latest version:  v${latest_version}"

if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version_normalized" "$latest_version_normalized"; then
    echo "Hugo is already up to date."
    exit 0
fi

install_hugo_release "$latest_version"
