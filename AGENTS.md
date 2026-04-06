# Repository Guidelines

## Project Structure & Module Organization
This repository is a small collection of standalone Linux utility scripts and config files. Group initialization scripts under [`init/`](/home/alpha/scripts/init), for example [`init_fedora.sh`](/home/alpha/scripts/init/init_fedora.sh) and [`init_ubuntu.sh`](/home/alpha/scripts/init/init_ubuntu.sh). Group update automation under [`update/`](/home/alpha/scripts/update), for example [`update_ai_tools.sh`](/home/alpha/scripts/update/update_ai_tools.sh), [`update_coding_cli.sh`](/home/alpha/scripts/update/update_coding_cli.sh), [`update_golang.sh`](/home/alpha/scripts/update/update_golang.sh), and [`update_hugo.sh`](/home/alpha/scripts/update/update_hugo.sh). Store related assets in focused subdirectories: `clash/` for Mihomo YAML configs and `openclaw/` for project-specific notes such as `skill_clawhub.md`.

## Build, Test, and Development Commands
There is no package build step. Run scripts directly with Bash:

```bash
bash init/init_fedora.sh
bash init/init_ubuntu.sh
bash update/update_ai_tools.sh
bash update/update_coding_cli.sh
bash update/update_golang.sh
```

Validate shell syntax before committing:

```bash
bash -n init/init_fedora.sh
bash -n init/init_ubuntu.sh
bash -n update/update_ai_tools.sh
bash -n update/update_coding_cli.sh
bash -n update/update_golang.sh
bash -n update/update_hugo.sh
```

If `shellcheck` is installed locally, use `shellcheck *.sh clash/*.yaml` only where it applies to the file type.

## Coding Style & Naming Conventions
Use Bash for shell automation, start files with `#!/bin/bash`, and prefer `set -euo pipefail` in scripts that modify system state. Follow the existing style: 4-space indentation, uppercase names for environment-like variables (`DISTRO_ID`, `PKG_INSTALL`), and lowercase snake_case for functions (`detect_distro`, `update_tool`). Name scripts descriptively with verb-led snake_case, for example `update/update_hugo.sh`.

## Testing Guidelines
This repository does not have an automated test suite. Contributors should treat syntax checks and safe dry-runs as the baseline. For scripts that download or install software, test only the affected path and document assumptions in the PR. For config changes under `clash/`, verify YAML parses cleanly in the target tool before merging.

## Commit & Pull Request Guidelines
Keep commit subjects short, imperative, and scoped to one change, matching recent history such as `update clawhub skill` or `Refactor init/init_fedora.sh for enhanced logging and error handling`. Prefer one logical script or config change per commit. PRs should include:

- What changed and why
- Any commands used for validation
- Target OS or tool assumptions
- Screenshots only when a change affects rendered docs or UI output

## Security & Configuration Tips
Do not commit secrets, tokens, or machine-specific credentials. Scripts in this repo often use `sudo`, `/usr/local`, network downloads, and package managers; keep URLs official and avoid silent privilege escalation.
