#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

test_update_npm_cli_exposes_managed_bin_when_external_command_masks_it() {
    local tmp_dir stub_bin app_bin npm_prefix shim_bin install_prefix

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

    stub_bin="${tmp_dir}/stub-bin"
    app_bin="${tmp_dir}/FakeCodex.app/Contents/Resources"
    npm_prefix="${tmp_dir}/npm-prefix"
    shim_bin="${tmp_dir}/local-bin"

    mkdir -p "$stub_bin" "$app_bin" "${npm_prefix}/bin" "$shim_bin"

    cat >"${stub_bin}/npm" <<EOF
#!/bin/bash
set -euo pipefail

case "\$1 \$2 \$3" in
    "view fake-package version")
        echo "2.0.0"
        ;;
    "config get prefix")
        echo "${npm_prefix}"
        ;;
    "install -g fake-package@latest")
        install_prefix="\${npm_config_prefix:-${npm_prefix}}"
        printf '%s\n' "\$install_prefix" >>"${tmp_dir}/install-prefixes"
        mkdir -p "\${install_prefix}/bin" "\${install_prefix}/lib/node_modules/fake-package/bin"
        cat >"\${install_prefix}/lib/node_modules/fake-package/bin/fakecodex.js" <<'TOOL'
#!/bin/bash
echo "fakecodex 2.0.0"
TOOL
        chmod +x "\${install_prefix}/lib/node_modules/fake-package/bin/fakecodex.js"
        ln -sfn "../lib/node_modules/fake-package/bin/fakecodex.js" "\${install_prefix}/bin/fakecodex"
        ;;
    *)
        echo "unexpected npm call: \$*" >&2
        exit 2
        ;;
esac
EOF
    chmod +x "${stub_bin}/npm"

    cat >"${app_bin}/fakecodex" <<'EOF'
#!/bin/bash
echo "fakecodex 2.0.0"
EOF
    chmod +x "${app_bin}/fakecodex"

    PATH="${shim_bin}:${stub_bin}:${app_bin}:${npm_prefix}/bin:/usr/bin:/bin" \
    NPM_CLI_SHIM_DIR="${shim_bin}" \
        update_npm_cli \
            "Fake Codex" \
            "fakecodex" \
            "fake-package" \
            "fakecodex --version | awk '{print \$2}'" \
            "npm install -g fake-package@latest"

    [[ -L "${shim_bin}/fakecodex" ]] || fail "expected shim at ${shim_bin}/fakecodex"
    [[ "$(readlink "${shim_bin}/fakecodex")" == "${npm_prefix}/bin/fakecodex" ]] || fail "shim points to wrong target"

    install_prefix="$(cat "${tmp_dir}/install-prefixes")"
    [[ "$install_prefix" == "${npm_prefix}" ]] || fail "expected npm_config_prefix=${npm_prefix}, got ${install_prefix}"

    PATH="${shim_bin}:${stub_bin}:${app_bin}:${npm_prefix}/bin:/usr/bin:/bin" \
    NPM_CLI_SHIM_DIR="${shim_bin}" \
        update_npm_cli \
            "Fake Codex" \
            "fakecodex" \
            "fake-package" \
            "fakecodex --version | awk '{print \$2}'" \
            "npm install -g fake-package@latest"

    [[ "$(wc -l <"${tmp_dir}/install-prefixes" | tr -d '[:space:]')" == "1" ]] || fail "expected second run to skip install"

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_uipro_uses_install_for_missing_package() {
    local tmp_dir install_command

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

    (
        AI_TOOLS_LIB_ONLY=1
        source "${SCRIPT_DIR}/uipro.sh"

        update_npm_cli() {
            printf '%s\n' "$5" >"${tmp_dir}/install-command"
        }

        update_uipro
    )

    install_command="$(cat "${tmp_dir}/install-command")"
    [[ "$install_command" == "npm install -g uipro-cli@latest" ]] || fail "expected UIPro install command, got ${install_command}"

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_update_npm_cli_fails_when_latest_lookup_fails() {
    local tmp_dir stub_bin external_prefix output_file

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

    stub_bin="${tmp_dir}/stub-bin"
    external_prefix="${tmp_dir}/external-prefix"
    output_file="${tmp_dir}/output"

    mkdir -p "$stub_bin" "${external_prefix}/bin"

    cat >"${stub_bin}/npm" <<EOF
#!/bin/bash
set -euo pipefail

case "\$1 \$2 \$3" in
    "view fake-package version")
        exit 42
        ;;
    "config get prefix")
        echo "${tmp_dir}/npm-prefix"
        ;;
    "install -g fake-package@latest")
        echo "install should not run after latest lookup failure" >&2
        exit 99
        ;;
    *)
        echo "unexpected npm call: \$*" >&2
        exit 2
        ;;
esac
EOF
    chmod +x "${stub_bin}/npm"

    cat >"${external_prefix}/bin/fakecli" <<'EOF'
#!/bin/bash
echo "fakecli 1.0.0"
EOF
    chmod +x "${external_prefix}/bin/fakecli"

    (
        success_count=0
        fail_count=0
        skip_count=0
        failed_tools=()
        skipped_tools=()

        PATH="${stub_bin}:${external_prefix}/bin:/usr/bin:/bin" \
            update_npm_cli \
                "Fake CLI" \
                "fakecli" \
                "fake-package" \
                "fakecli --version | awk '{print \$2}'" \
                "npm install -g fake-package@latest" >"$output_file" 2>&1

        [[ "$fail_count" == "1" ]] || fail "expected npm lookup failure to be tracked"
        grep -q "Fake CLI latest version lookup failed" "$output_file" || fail "expected latest lookup failure message"
        ! grep -q "install should not run" "$output_file" || fail "install ran after latest lookup failure"
    )

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_opencode_fails_when_latest_release_lookup_fails() {
    local tmp_dir output_file

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN
    output_file="${tmp_dir}/output"

    (
        AI_TOOLS_LIB_ONLY=1
        source "${SCRIPT_DIR}/opencode.sh"

        success_count=0
        fail_count=0
        skip_count=0
        failed_tools=()
        skipped_tools=()

        fetch_latest_opencode_version() {
            return 28
        }

        opencode() {
            echo "1.17.11"
        }

        run_opencode_installer() {
            echo "installer should not run after latest lookup failure" >&2
            return 99
        }

        update_opencode >"$output_file" 2>&1

        [[ "$fail_count" == "1" ]] || fail "expected OpenCode lookup failure to be tracked"
        grep -q "OpenCode latest version lookup failed" "$output_file" || fail "expected OpenCode lookup failure message"
        ! grep -q "installer should not run" "$output_file" || fail "installer ran after OpenCode lookup failure"
    )

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_spec_kit_fails_when_latest_release_lookup_fails() {
    local tmp_dir output_file

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN
    output_file="${tmp_dir}/output"

    (
        AI_TOOLS_LIB_ONLY=1
        source "${SCRIPT_DIR}/spec_kit.sh"

        success_count=0
        fail_count=0
        skip_count=0
        failed_tools=()
        skipped_tools=()

        fetch_latest_speckit_version() {
            return 28
        }

        uv() {
            if [[ "${1:-} ${2:-}" == "tool list" ]]; then
                echo "specify-cli 0.11.9"
                return 0
            fi
            echo "uv install should not run after latest lookup failure" >&2
            return 99
        }

        specify() {
            :
        }

        update_spec_kit >"$output_file" 2>&1

        [[ "$fail_count" == "1" ]] || fail "expected Spec-Kit lookup failure to be tracked"
        grep -q "Spec-Kit latest version lookup failed" "$output_file" || fail "expected Spec-Kit lookup failure message"
        ! grep -q "uv install should not run" "$output_file" || fail "uv install ran after Spec-Kit lookup failure"
    )

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_tui_help_loads_all_menu_sources() {
    bash "${SCRIPT_DIR}/tui.sh" --help >/dev/null
}

test_removed_hermes_and_openclaw_without_removing_opencode() {
    local repo_root
    local openclaw_script

    repo_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
    openclaw_script="$(find "${SCRIPT_DIR}" -maxdepth 1 -type f -iname '*openclaw*' -print -quit)"

    [[ ! -e "${SCRIPT_DIR}/hermes.sh" ]] || fail "Hermes update script still exists"
    [[ -z "$openclaw_script" ]] || fail "OpenClaw update script still exists: ${openclaw_script}"
    [[ -e "${SCRIPT_DIR}/opencode.sh" ]] || fail "OpenCode update script was removed"

    grep -q 'source "${SCRIPT_DIR}/opencode.sh"' "${repo_root}/update/ai_tools.sh" || fail "AI tools updater should source OpenCode"
    grep -q 'update_opencode' "${repo_root}/update/ai_tools.sh" || fail "AI tools updater should run OpenCode"
    grep -q 'source "${SCRIPT_DIR}/opencode.sh"' "${repo_root}/update/tui.sh" || fail "TUI should source OpenCode"
    grep -q 'OpenCode|func:update_opencode' "${repo_root}/update/tui.sh" || fail "TUI should offer OpenCode"

    ! grep -R -E 'hermes|Hermes|OpenClaw|Open Claw' \
        "${repo_root}/update/ai_tools.sh" \
        "${repo_root}/update/tui.sh" || fail "removed updater is still referenced"
}

test_opencode_uses_current_repo_slug() {
    local tmp_dir repo latest_version

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

    (
        AI_TOOLS_LIB_ONLY=1
        source "${SCRIPT_DIR}/opencode.sh"

        fetch_latest_github_release_version() {
            printf '%s\n' "$1" >"${tmp_dir}/repo"
            printf '%s\n' "v1.2.3"
        }

        fetch_latest_opencode_version >"${tmp_dir}/latest-version"
    )

    repo="$(cat "${tmp_dir}/repo")"
    [[ "$repo" == "anomalyco/opencode" ]] || fail "expected anomalyco/opencode, got ${repo}"

    latest_version="$(cat "${tmp_dir}/latest-version")"
    [[ "$latest_version" == "v1.2.3" ]] || fail "expected v1.2.3, got ${latest_version}"

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_codex_uses_official_release_tag() {
    local tmp_dir repo latest_version

    tmp_dir="$(mktemp -d)"
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

    (
        AI_TOOLS_LIB_ONLY=1
        source "${SCRIPT_DIR}/codex.sh"

        fetch_latest_github_release_version() {
            printf '%s\n' "$1" >"${tmp_dir}/repo"
            printf '%s\n' "rust-v0.142.4"
        }

        fetch_latest_codex_version >"${tmp_dir}/latest-version"
    )

    repo="$(cat "${tmp_dir}/repo")"
    [[ "$repo" == "openai/codex" ]] || fail "expected openai/codex, got ${repo}"

    latest_version="$(cat "${tmp_dir}/latest-version")"
    [[ "$latest_version" == "0.142.4" ]] || fail "expected 0.142.4, got ${latest_version}"

    trap - RETURN
    rm -rf "$tmp_dir"
}

test_codex_installers_use_documented_non_interactive_mode() {
    local repo_root

    repo_root="$(cd "${SCRIPT_DIR}/.." && pwd)"

    grep -q 'curl -fsSL "$CODEX_INSTALLER_URL" | CODEX_NON_INTERACTIVE=1 sh' "${SCRIPT_DIR}/codex.sh" \
        || fail "Codex updater should use the documented non-interactive installer mode"
    grep -q 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh' "${repo_root}/init/fedora.sh" \
        || fail "Linux bootstrap should use the documented non-interactive Codex installer mode"
}

test_hugo_uses_detected_linux_arch() {
    grep -q 'hugo_release_arch' "${SCRIPT_DIR}/hugo.sh" || fail "expected Hugo updater to detect release architecture"
    ! grep -q 'hugo_extended_.*linux-amd64' "${SCRIPT_DIR}/hugo.sh" || fail "Hugo updater still hard-codes linux-amd64"
}

test_init_scripts_avoid_stale_linux_assets() {
    local repo_root

    repo_root="$(cd "${SCRIPT_DIR}/.." && pwd)"

    grep -q 'exec bash "${SCRIPT_DIR}/fedora.sh"' "${repo_root}/init/ubuntu.sh" || fail "Ubuntu bootstrap should delegate to shared Linux bootstrap"
    grep -q 'detect_machine_arch' "${repo_root}/init/fedora.sh" || fail "shared bootstrap should detect machine architecture"
    ! grep -q 'lazygit_.*Linux_x86_64' "${repo_root}/init/fedora.sh" || fail "lazygit asset name still uses stale Linux_x86_64 casing"
    ! grep -q 'bin/linux/amd64/kubectl' "${repo_root}/init/fedora.sh" || fail "kubectl download still hard-codes amd64"
    ! grep -q 'kubectl version --client --short' "${repo_root}/init/fedora.sh" || fail "kubectl output still uses removed --short flag"
    ! grep -q '@openai/codex@latest' "${repo_root}/init/fedora.sh" || fail "bootstrap still uses stale npm Codex installer"
    ! grep -qi 'openclaw' "${repo_root}/init/fedora.sh" || fail "bootstrap still contains OpenClaw"
}

test_removed_gemini_cli_updater() {
    local repo_root

    repo_root="$(cd "${SCRIPT_DIR}/.." && pwd)"

    [[ ! -e "${SCRIPT_DIR}/gemini.sh" ]] || fail "Gemini update script still exists"
    ! grep -E 'gemini|Gemini|@google/gemini-cli' \
        "${repo_root}/init/fedora.sh" \
        "${repo_root}/init/ubuntu.sh" \
        "${repo_root}/update/ai_tools.sh" \
        "${repo_root}/update/tui.sh" || fail "Gemini CLI updater is still referenced"
}

main() {
    test_update_npm_cli_exposes_managed_bin_when_external_command_masks_it
    test_uipro_uses_install_for_missing_package
    test_update_npm_cli_fails_when_latest_lookup_fails
    test_opencode_fails_when_latest_release_lookup_fails
    test_spec_kit_fails_when_latest_release_lookup_fails
    test_tui_help_loads_all_menu_sources
    test_removed_hermes_and_openclaw_without_removing_opencode
    test_opencode_uses_current_repo_slug
    test_codex_uses_official_release_tag
    test_codex_installers_use_documented_non_interactive_mode
    test_hugo_uses_detected_linux_arch
    test_init_scripts_avoid_stale_linux_assets
    test_removed_gemini_cli_updater
    echo "All update script tests passed."
}

main "$@"
