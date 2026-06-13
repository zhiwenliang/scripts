#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

AI_TOOLS_LIB_ONLY=1
source "${SCRIPT_DIR}/claude_code.sh"
source "${SCRIPT_DIR}/codex.sh"
source "${SCRIPT_DIR}/copilot.sh"
source "${SCRIPT_DIR}/gemini.sh"
source "${SCRIPT_DIR}/hermes.sh"
source "${SCRIPT_DIR}/opencode.sh"
source "${SCRIPT_DIR}/openspec.sh"
source "${SCRIPT_DIR}/pi.sh"
source "${SCRIPT_DIR}/spec_kit.sh"
source "${SCRIPT_DIR}/uipro.sh"

# Menu table: "Label|runner". func:<name> calls a sourced update function;
# script:<file> runs as a subprocess because those scripts exit inline and
# cannot be sourced.
MENU_ITEMS=(
    "Claude Code|func:update_claude_code"
    "Codex|func:update_codex"
    "Copilot|func:update_copilot"
    "Gemini|func:update_gemini"
    "OpenCode|func:update_opencode"
    "OpenSpec|func:update_openspec"
    "Pi|func:update_pi"
    "Spec Kit|func:update_spec_kit"
    "UIPro|func:update_uipro"
    "Hermes Agent|func:update_hermes"
    "Go|script:golang.sh"
    "Hugo|script:hugo.sh"
)

cursor=0
selected=()
for _ in "${MENU_ITEMS[@]}"; do
    selected+=(0)
done

show_cursor() {
    printf '\033[?25h'
}

hide_cursor() {
    printf '\033[?25l'
}

draw_menu() {
    local i label marker line
    for i in "${!MENU_ITEMS[@]}"; do
        label="${MENU_ITEMS[$i]%%|*}"
        marker=" "
        [[ "${selected[$i]}" == "1" ]] && marker="x"
        line="  [${marker}] ${label}"
        if [[ "$i" -eq "$cursor" ]]; then
            printf '\033[7m> [%s] %s\033[0m\033[K\n' "$marker" "$label"
        else
            printf '%s\033[K\n' "$line"
        fi
    done
}

redraw_menu() {
    printf '\033[%dA' "${#MENU_ITEMS[@]}"
    draw_menu
}

move_up() {
    if ((cursor > 0)); then
        cursor=$((cursor - 1))
    fi
}

move_down() {
    if ((cursor < ${#MENU_ITEMS[@]} - 1)); then
        cursor=$((cursor + 1))
    fi
}

toggle_current() {
    selected[cursor]=$((1 - selected[cursor]))
}

toggle_all() {
    local i target=0
    for i in "${!selected[@]}"; do
        if [[ "${selected[$i]}" == "0" ]]; then
            target=1
            break
        fi
    done
    for i in "${!selected[@]}"; do
        selected[$i]="$target"
    done
}

run_script() {
    local name="$1"
    local script="$2"

    log_step "Running" "$name"
    if bash "${SCRIPT_DIR}/${script}"; then
        log_ok "$name script finished"
        track_success
    else
        log_fail "$name script failed"
        track_failure "$name"
    fi
    echo ""
}

run_selected() {
    local i label runner any=0

    for i in "${!MENU_ITEMS[@]}"; do
        if [[ "${selected[$i]}" == "1" ]]; then
            any=1
            break
        fi
    done

    if [[ "$any" == "0" ]]; then
        echo "Nothing selected."
        exit 0
    fi

    for i in "${!MENU_ITEMS[@]}"; do
        [[ "${selected[$i]}" == "1" ]] || continue
        label="${MENU_ITEMS[$i]%%|*}"
        runner="${MENU_ITEMS[$i]#*|}"
        case "$runner" in
            func:*) "${runner#func:}" ;;
            script:*) run_script "$label" "${runner#script:}" ;;
        esac
    done

    print_summary
}

main() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        echo "update/tui.sh needs an interactive terminal." >&2
        echo "For non-interactive updates, run: bash update/ai_tools.sh" >&2
        exit 1
    fi

    echo "========================================"
    echo "  Interactive Updater"
    echo "========================================"
    echo "  <space> toggle  <a> all  <enter> run  <q> quit"
    echo ""

    hide_cursor
    trap show_cursor EXIT
    draw_menu

    local key rest
    while true; do
        IFS= read -rsn1 key || break
        case "$key" in
            $'\x1b')
                rest=""
                IFS= read -rsn2 -t 0.1 rest || true
                case "$rest" in
                    '[A') move_up ;;
                    '[B') move_down ;;
                esac
                ;;
            k) move_up ;;
            j) move_down ;;
            ' ') toggle_current ;;
            a) toggle_all ;;
            q)
                echo "Aborted."
                exit 0
                ;;
            '') break ;;
        esac
        redraw_menu
    done

    printf '\033[%dA\033[J' "${#MENU_ITEMS[@]}"
    show_cursor
    run_selected
}

main "$@"
