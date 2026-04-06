#!/bin/bash

set -euo pipefail

GO_PLATFORM="linux-amd64"

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

fetch_latest_go_version() {
    curl -fsSL https://go.dev/VERSION?m=text | head -n1
}

current_go_version() {
    go version | awk '{print $3}'
}

install_go_archive() {
    local archive_path="$1"

    echo "Installing from archive: ${archive_path}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$archive_path"
    echo "Installed version: $(go version | awk '{print $3}')"
}

install_latest_go() {
    local latest_version="$1"
    local archive_name="${latest_version}.${GO_PLATFORM}.tar.gz"
    local temp_dir

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    echo "Downloading ${archive_name}"
    curl -fsSL "https://go.dev/dl/${archive_name}" -o "${temp_dir}/${archive_name}"
    install_go_archive "${temp_dir}/${archive_name}"
}

upgrade_offline() {
    local archive_path
    local archive_name
    local archive_version
    local current_version="not installed"

    archive_path="$(find . -maxdepth 1 -type f -name 'go*.linux-amd64.tar.gz' | sort -V | tail -n1)"
    if [[ -z "${archive_path}" ]]; then
        echo "No local Go archive found matching go*.linux-amd64.tar.gz"
        exit 1
    fi

    archive_name="$(basename "$archive_path")"
    archive_version="$(normalize_version "${archive_name%.linux-amd64.tar.gz}")"

    if command -v go >/dev/null 2>&1; then
        current_version="$(normalize_version "$(current_go_version)")"
    fi

    echo "Current version: ${current_version}"
    echo "Archive version: ${archive_version}"

    if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version" "$archive_version"; then
        echo "Go is already up to date for the provided archive."
        exit 0
    fi

    install_go_archive "$archive_path"
}

if [[ "${1:-}" == "offline" ]]; then
    upgrade_offline
    exit 0
fi

latest_version="$(fetch_latest_go_version)"
latest_version_normalized="$(normalize_version "$latest_version")"

if command -v go >/dev/null 2>&1; then
    current_version="$(current_go_version)"
    current_version_normalized="$(normalize_version "$current_version")"
else
    current_version="not installed"
    current_version_normalized=""
fi

echo "Current version: ${current_version}"
echo "Latest version:  ${latest_version}"

if [[ "$current_version" != "not installed" ]] && ! version_lt "$current_version_normalized" "$latest_version_normalized"; then
    echo "Go is already up to date."
    exit 0
fi

install_latest_go "$latest_version"
