#!/bin/bash

# Shared utilities for AI tool update scripts

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

success_count="${success_count:-0}"
fail_count="${fail_count:-0}"
skip_count="${skip_count:-0}"
failed_tools=("${failed_tools[@]+"${failed_tools[@]}"}")
skipped_tools=("${skipped_tools[@]+"${skipped_tools[@]}"}")

log_step() {
    echo -e "${YELLOW}[$1]${NC} $2"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

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

track_success() {
    ((success_count += 1))
}

track_skip() {
    skipped_tools+=("$1")
    ((skip_count += 1))
}

track_failure() {
    failed_tools+=("$1")
    ((fail_count += 1))
}

fetch_latest_github_release_version() {
    local repo="$1"
    local release_url

    release_url="$(
        curl -fsSLI -o /dev/null -w '%{url_effective}' \
            "https://github.com/${repo}/releases/latest"
    )"

    sed -E 's#.*/tag/v?([^/]+)$#\1#' <<<"$release_url"
}

path_contains_dir() {
    local needle="$1"
    local entry
    local -a path_entries

    IFS=':' read -r -a path_entries <<<"$PATH"
    for entry in "${path_entries[@]}"; do
        [[ "$entry" == "$needle" ]] && return 0
    done

    return 1
}

resolve_path() {
    local path="$1"
    local target
    local target_dir
    local seen=0

    while [[ -L "$path" && "$seen" -lt 10 ]]; do
        target="$(readlink "$path")"
        if [[ "$target" != /* ]]; then
            target_dir="$(cd "$(dirname "$path")" && cd "$(dirname "$target")" && pwd)"
            path="${target_dir}/$(basename "$target")"
        else
            path="$target"
        fi
        ((seen += 1))
    done

    echo "$path"
}

resolve_one_symlink() {
    local path="$1"
    local target
    local target_dir

    if [[ ! -L "$path" ]]; then
        echo "$path"
        return 0
    fi

    target="$(readlink "$path")"
    if [[ "$target" != /* ]]; then
        target_dir="$(cd "$(dirname "$path")" && cd "$(dirname "$target")" && pwd)"
        echo "${target_dir}/$(basename "$target")"
    else
        echo "$target"
    fi
}

npm_prefix_from_command_path() {
    local command_path="$1"
    local command_dir
    local linked_path
    local linked_dir

    command_dir="$(dirname "$command_path")"

    if [[ "$(basename "$command_dir")" == "bin" ]]; then
        if [[ -L "$command_path" ]]; then
            linked_path="$(resolve_one_symlink "$command_path")"
            linked_dir="$(dirname "$linked_path")"
            if [[ "$(basename "$linked_dir")" == "bin" && "$linked_path" != */lib/node_modules/* ]]; then
                dirname "$linked_dir"
                return 0
            fi
        fi
        dirname "$command_dir"
        return 0
    fi

    return 1
}

find_npm_cli_shim_dir() {
    if [[ -n "${NPM_CLI_SHIM_DIR:-}" ]]; then
        echo "$NPM_CLI_SHIM_DIR"
        return 0
    fi

    if path_contains_dir "${HOME}/.local/bin"; then
        echo "${HOME}/.local/bin"
        return 0
    fi

    if path_contains_dir "${HOME}/.npm-global/bin"; then
        echo "${HOME}/.npm-global/bin"
        return 0
    fi

    return 1
}

ensure_npm_cli_on_path() {
    local command_name="$1"
    local target_prefix="$2"
    local target_bin="${target_prefix}/bin/${command_name}"
    local prefix_bin="${target_prefix}/bin"
    local current_path=""
    local resolved_target_bin
    local shim_dir
    local shim_path

    if [[ ! -e "$target_bin" && ! -L "$target_bin" ]]; then
        echo "Expected npm binary was not created: ${target_bin}" >&2
        return 1
    fi

    resolved_target_bin="$(resolve_path "$target_bin")"
    if command -v "$command_name" >/dev/null 2>&1; then
        current_path="$(resolve_path "$(command -v "$command_name")")"
        if [[ "$current_path" == "$target_bin" || "$current_path" == "$resolved_target_bin" ]]; then
            return 0
        fi
    fi

    if ! shim_dir="$(find_npm_cli_shim_dir)"; then
        echo "No on-PATH user bin directory found for ${command_name}; add ${prefix_bin} to PATH" >&2
        return 1
    fi

    mkdir -p "$shim_dir"
    shim_path="${shim_dir}/${command_name}"
    if [[ "$shim_path" == "$target_bin" ]]; then
        echo "${target_bin} is on PATH but is masked by ${current_path:-another command}" >&2
        return 1
    fi

    if [[ -e "$shim_path" || -L "$shim_path" ]]; then
        if [[ ! -L "$shim_path" ]]; then
            echo "Cannot replace existing non-symlink: ${shim_path}" >&2
            return 1
        fi
        ln -sfn "$target_bin" "$shim_path"
    else
        ln -s "$target_bin" "$shim_path"
    fi

    echo "Shim path:       ${shim_path}"
}

run_with_npm_prefix_bin() {
    local target_prefix="$1"
    local command="$2"

    (
        PATH="${target_prefix}/bin:${PATH}"
        eval "$command"
    )
}

update_npm_cli() {
    local name="$1"
    local command_name="$2"
    local package_name="$3"
    local current_cmd="$4"
    local install_cmd="$5"
    local latest_version
    local current_version="not installed"
    local command_path=""
    local command_prefix=""
    local latest_version_raw
    local managed_command_path=""
    local managed_current_version=""
    local managed_command_exists=0
    local npm_prefix
    local target_prefix=""
    local had_npm_config_prefix="${npm_config_prefix+x}"
    local previous_npm_config_prefix="${npm_config_prefix-}"

    log_step "Checking" "$name"
    if ! latest_version_raw="$(npm view "$package_name" version --silent)"; then
        log_fail "$name latest version lookup failed"
        track_failure "$name"
        echo ""
        return
    fi
    latest_version="$(normalize_version "$latest_version_raw")"
    if [[ -z "$latest_version" ]]; then
        log_fail "$name latest version lookup failed"
        track_failure "$name"
        echo ""
        return
    fi
    npm_prefix="$(npm config get prefix)"
    target_prefix="$npm_prefix"

    if command -v "$command_name" >/dev/null 2>&1; then
        current_version="$(normalize_version "$(eval "$current_cmd")")"
        command_path="$(command -v "$command_name")"
        # Only treat normal */bin/<command> paths as npm prefixes. App bundles
        # such as /Applications/Codex.app/... are command providers, not npm
        # install prefixes.
        if command_prefix="$(npm_prefix_from_command_path "$command_path")"; then
            target_prefix="$command_prefix"
        fi
    fi

    managed_command_path="${target_prefix}/bin/${command_name}"
    if [[ -e "$managed_command_path" || -L "$managed_command_path" ]]; then
        managed_command_exists=1
        managed_current_version="$(normalize_version "$(run_with_npm_prefix_bin "$target_prefix" "$current_cmd")")"
        current_version="$managed_current_version"
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"

    if [[ "$managed_command_exists" == "1" ]] && ! version_lt "$current_version" "$latest_version"; then
        if ! ensure_npm_cli_on_path "$command_name" "$target_prefix"; then
            log_fail "$name is installed but is not available on PATH"
            track_failure "$name"
            echo ""
            return
        fi
        log_ok "$name is already up to date"
        track_skip "$name"
        echo ""
        return
    fi

    log_step "Updating" "$name"
    echo "Install prefix:  ${target_prefix}"
    export npm_config_prefix="$target_prefix"
    if eval "$install_cmd"; then
        if ensure_npm_cli_on_path "$command_name" "$target_prefix"; then
            log_ok "$name is now at $(normalize_version "$(run_with_npm_prefix_bin "$target_prefix" "$current_cmd")")"
            track_success
        else
            log_fail "$name installed but is not available on PATH"
            track_failure "$name"
        fi
    else
        log_fail "$name update failed"
        track_failure "$name"
    fi
    if [[ -n "$had_npm_config_prefix" ]]; then
        export npm_config_prefix="$previous_npm_config_prefix"
    else
        unset npm_config_prefix
    fi

    echo ""
}

print_summary() {
    echo "========================================"
    echo "  Summary: ${success_count} updated, ${skip_count} skipped, ${fail_count} failed"
    if [[ ${skip_count} -gt 0 ]]; then
        echo -e "  ${YELLOW}Skipped:${NC} ${skipped_tools[*]}"
    fi
    if [[ ${fail_count} -gt 0 ]]; then
        echo -e "  ${RED}Failed:${NC} ${failed_tools[*]}"
    fi
    echo "========================================"
}
