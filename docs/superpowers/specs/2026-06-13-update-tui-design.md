# Interactive Update TUI — Design

**Date:** 2026-06-13
**Status:** Approved

## Goal

Provide a single interactive entry point for the update scripts in `update/`:
a pure-bash checkbox menu where the user picks which tools to update, then
the selected updates run sequentially and end with the shared summary.

## Decisions

- **Interaction model:** pick tools first, then update. No upfront version
  checks, no live dashboard.
- **Scope:** all update scripts — the AI tools run by `ai_tools.sh`
  (Claude Code, Codex, Copilot, Gemini, OpenCode, OpenSpec, Pi, Spec Kit,
  UIPro), plus Hermes Agent, Go, and Hugo.
- **Implementation:** pure bash (`read -rsn1` + ANSI escapes). No new
  dependencies (no fzf, gum, whiptail).
- **Structure (Approach A — wrap, don't refactor):** a new `update/tui.sh`
  wraps the existing scripts. Function-style scripts are sourced; inline
  scripts run as subprocesses. No existing script is modified, and
  `ai_tools.sh` remains the non-interactive batch path.

## File

`update/tui.sh`, run as `bash update/tui.sh`. Bash with `set -euo pipefail`,
4-space indentation, lowercase snake_case functions, matching repo style.

## Menu definition

A single table at the top of the script maps each menu label to a runner:

| Label        | Runner                              |
|--------------|-------------------------------------|
| Claude Code  | sourced function `update_claude_code` |
| Codex        | sourced function `update_codex`     |
| Copilot      | sourced function `update_copilot`   |
| Gemini       | sourced function `update_gemini`    |
| OpenCode     | sourced function `update_opencode`  |
| OpenSpec     | sourced function `update_openspec`  |
| Pi           | sourced function `update_pi`        |
| Spec Kit     | sourced function `update_spec_kit`  |
| UIPro        | sourced function `update_uipro`     |
| Hermes Agent | sourced function `update_hermes`    |
| Go           | subprocess `bash golang.sh`         |
| Hugo         | subprocess `bash hugo.sh`           |

Sourced scripts are loaded with `AI_TOOLS_LIB_ONLY=1`, the existing guard
pattern. `golang.sh` and `hugo.sh` cannot be sourced (inline `exit`
statements, an `EXIT` trap, and a source-time arch check), so they run as
subprocesses. Adding a future tool means adding one table line.

## Menu interaction

- Requires a TTY: if stdin is not a terminal, print a hint to use
  `bash update/ai_tools.sh` and exit 1.
- Renders the checkbox list in place using ANSI escape codes (cursor-up and
  reprint). No alternate screen, no ncurses.
- Keys: `↑`/`↓` or `j`/`k` move the cursor, `space` toggles the current
  item, `a` toggles all, `enter` confirms, `q` quits without running.
- All items start unselected.
- The terminal cursor is hidden while the menu is displayed and restored by
  an `EXIT` trap, so Ctrl-C does not leave the terminal in a broken state.

## Execution

- On enter, clear the menu and run selected tools sequentially in menu
  order.
- Sourced functions handle their own logging and call
  `track_success`/`track_skip`/`track_failure` from `lib/common.sh`.
- Subprocess entries run under an `if bash "$SCRIPT_DIR/<script>"` guard so
  a failure does not abort the TUI; exit 0 → `track_success`, non-zero →
  `track_failure`.
- Known wrinkle (accepted): `golang.sh` and `hugo.sh` exit 0 for both
  "updated" and "already up to date", so they count as "updated" in the
  summary even when skipped. Fixable later by migrating them to the
  function pattern; the menu table does not change.
- After all selected tools run, call `print_summary`.
- Enter with nothing selected prints "Nothing selected." and exits 0.

## Error handling

- `set -euo pipefail` at the top; individual tool failures are contained
  (functions track their own failures; subprocesses run under `if`).
- The `EXIT` trap restores the cursor on any exit path.

## Testing

- `bash -n update/tui.sh` for syntax.
- Manual run: navigation, toggle, toggle-all, quit without running,
  nothing-selected case, non-TTY guard (`echo | bash update/tui.sh`), and
  at least one real update path.
