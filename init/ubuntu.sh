#!/bin/bash
set -euo pipefail

# Compatibility entrypoint for Ubuntu-family systems. The shared Linux
# bootstrap handles Fedora and Ubuntu/Debian variants in one place.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/fedora.sh" "$@"
