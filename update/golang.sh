#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Detect the host OS and architecture before downloading, so the platform
# string matches the running system instead of assuming linux/amd64.
GO_OS="$(uname -s)"
case "$GO_OS" in
    Linux) GO_OS="linux" ;;
    Darwin) GO_OS="darwin" ;;
    *)
        echo "Unsupported operating system: $GO_OS" >&2
        exit 1
        ;;
esac

GO_ARCH="$(uname -m)"
case "$GO_ARCH" in
    x86_64 | amd64) GO_ARCH="amd64" ;;
    aarch64 | arm64) GO_ARCH="arm64" ;;
    armv6l | armv7l | arm) GO_ARCH="armv6l" ;;
    i386 | i686) GO_ARCH="386" ;;
    ppc64le) GO_ARCH="ppc64le" ;;
    s390x) GO_ARCH="s390x" ;;
    riscv64) GO_ARCH="riscv64" ;;
    *)
        echo "Unsupported architecture: $GO_ARCH" >&2
        exit 1
        ;;
esac

GO_PLATFORM="${GO_OS}-${GO_ARCH}"
echo "Detected platform: ${GO_PLATFORM}"

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

    archive_path="$(find . -maxdepth 1 -type f -name "go*.${GO_PLATFORM}.tar.gz" | sort -V | tail -n1)"
    if [[ -z "${archive_path}" ]]; then
        echo "No local Go archive found matching go*.${GO_PLATFORM}.tar.gz"
        exit 1
    fi

    archive_name="$(basename "$archive_path")"
    archive_version="$(normalize_version "${archive_name%".${GO_PLATFORM}.tar.gz"}")"

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
