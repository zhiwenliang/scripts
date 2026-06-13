# Interactive Update TUI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `update/tui.sh`, a pure-bash interactive checkbox menu that runs any subset of the existing update scripts and prints the shared summary.

**Architecture:** One new script wraps the existing ones (Approach A from the spec). Function-style scripts (`claude_code.sh`, `codex.sh`, …, `hermes.sh`) are sourced with the existing `AI_TOOLS_LIB_ONLY=1` guard; `golang.sh` and `hugo.sh` run as subprocesses because they exit inline and cannot be sourced. A menu table at the top of the script is the single place to add future tools.

**Tech Stack:** Bash only (`read -rsn1`, ANSI escapes). No new dependencies. Spec: `docs/superpowers/specs/2026-06-13-update-tui-design.md`.

**Note on TDD:** This repo has no test suite by design (see AGENTS.md: "syntax checks and safe dry-runs as the baseline"). Verification is `bash -n`, `shellcheck` if installed, and scripted/manual behavior checks instead of unit tests.

---

### Task 1: Create `update/tui.sh`

**Files:**
- Create: `update/tui.sh`

- [ ] **Step 1: Write the script**

Create `update/tui.sh` with exactly this content:

```bash
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

    show_cursor
    echo ""
    run_selected
}

main "$@"
```

Implementation notes for the engineer:

- `((cursor -= 1))` as a bare statement returns exit status 1 when the result
  is 0, which kills a `set -e` script. That is why movement uses
  `if ((...)); then cursor=$((cursor - 1)); fi` — assignments always return 0.
  Do not "simplify" this back to `((cursor > 0)) && ((cursor -= 1))`.
- `read -rsn1` returns an empty string for Enter — that is the `'')` case.
  Arrow keys arrive as ESC + `[A`/`[B`; the `-t 0.1` follow-up read times out
  (non-zero status) when the user pressed bare ESC, hence `|| true`.
- `hermes.sh` already uses the `AI_TOOLS_LIB_ONLY` guard even though
  `ai_tools.sh` does not source it; sourcing it here is safe.
- The `EXIT` trap restores the terminal cursor on every exit path including
  Ctrl-C and `q`.

- [ ] **Step 2: Syntax check**

Run: `bash -n update/tui.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Shellcheck (if installed)**

Run: `command -v shellcheck >/dev/null && shellcheck update/tui.sh || echo "shellcheck not installed"`
Expected: no errors. Info-level notes about sourcing non-constant paths
(SC1091) are acceptable; the repo's other scripts have the same pattern.

- [ ] **Step 4: Verify the non-TTY guard**

Run: `echo "" | bash update/tui.sh; echo "exit=$?"`
Expected output:

```
update/tui.sh needs an interactive terminal.
For non-interactive updates, run: bash update/ai_tools.sh
exit=1
```

- [ ] **Step 5: Verify sourcing and menu definitions load cleanly**

Run: `bash -c 'source update/lib/common.sh; AI_TOOLS_LIB_ONLY=1; for f in claude_code codex copilot gemini hermes opencode openspec pi spec_kit uipro; do source "update/${f}.sh"; done; declare -F update_claude_code update_codex update_copilot update_gemini update_hermes update_opencode update_openspec update_pi update_spec_kit update_uipro'`
Expected: ten `declare -f update_...` lines, exit 0. This confirms every
`func:` runner in `MENU_ITEMS` names a real function.

- [ ] **Step 6: Commit**

```bash
git add update/tui.sh
git commit -m "add interactive TUI for update scripts"
```

### Task 2: Interactive verification (requires a real terminal)

**Files:** none (manual testing)

The agent cannot drive a TTY; ask the user to run these in their terminal,
or run them yourself if you have an interactive terminal available.

- [ ] **Step 1: Navigation and quit**

Run: `bash update/tui.sh`
Check: arrow keys and `j`/`k` move the highlight; cursor stops at the top
and bottom (no wrap); `q` prints `Aborted.` and exits with the terminal
cursor visible again.

- [ ] **Step 2: Nothing selected**

Run: `bash update/tui.sh`, press Enter immediately.
Expected: prints `Nothing selected.` and exits 0.

- [ ] **Step 3: Toggle-all and a real update**

Run: `bash update/tui.sh`, press `a` (all items show `[x]`), press `a`
again (all clear), select one cheap tool (e.g. OpenSpec) with space, press
Enter.
Expected: that tool's usual check/update output, then the standard
`Summary: N updated, N skipped, N failed` block.

- [ ] **Step 4: Subprocess path**

Run: `bash update/tui.sh`, select only Hugo, press Enter.
Expected: hugo.sh output runs inline; on success the summary counts it as
updated (even if hugo was already up to date — accepted wrinkle per spec).

### Task 3: Document the new entry point

**Files:**
- Modify: `AGENTS.md` (Build, Test, and Development Commands section)

- [ ] **Step 1: Add the run command**

In the first code block of the "Build, Test, and Development Commands"
section, add a line after `bash update/ai_tools.sh`:

```bash
bash update/tui.sh
```

- [ ] **Step 2: Add the syntax-check command**

In the second code block (the `bash -n` list), add after the
`bash -n update/ai_tools.sh` line:

```bash
bash -n update/tui.sh
```

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "document update/tui.sh in repository guidelines"
```
