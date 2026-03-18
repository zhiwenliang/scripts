#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
fail_count=0
failed_tools=()

update_tool() {
    local name="$1"
    shift
    echo -e "${YELLOW}[Updating]${NC} $name..."
    if "$@" 2>&1; then
        echo -e "${GREEN}[OK]${NC} $name updated successfully"
        ((success_count++))
    else
        echo -e "${RED}[FAIL]${NC} $name update failed"
        ((fail_count++))
        failed_tools+=("$name")
    fi
    echo ""
}

update_tool_pipe() {
    local name="$1"
    local url="$2"
    echo -e "${YELLOW}[Updating]${NC} $name..."
    if curl -fsSL "$url" | bash 2>&1; then
        echo -e "${GREEN}[OK]${NC} $name updated successfully"
        ((success_count++))
    else
        echo -e "${RED}[FAIL]${NC} $name update failed"
        ((fail_count++))
        failed_tools+=("$name")
    fi
    echo ""
}

echo "========================================"
echo "  AI Coding CLI Updater"
echo "========================================"
echo ""

update_tool_pipe "Claude Code" "https://claude.ai/install.sh"
update_tool "Codex CLI" npm i -g @openai/codex@latest
update_tool "Gemini CLI" npm i -g @google/gemini-cli@latest
update_tool_pipe "OpenCode" "https://opencode.ai/install"

echo "========================================"
echo "  Summary: ${success_count} succeeded, ${fail_count} failed"
if [ ${fail_count} -gt 0 ]; then
    echo -e "  ${RED}Failed: ${failed_tools[*]}${NC}"
fi
echo "========================================"
