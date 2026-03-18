# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal collection of utility scripts for system administration, environment setup, and automation. There is no build system, test suite, or package manager — scripts are standalone and run directly.

## Repository Structure

- **sdk/** — SDK/tool upgrade scripts (Go, Hugo, Telepresence) and Fedora system initialization. These target Linux (amd64) and use `/usr/local/` install paths with `sudo`.
- **container/** — Docker/Podman helpers:
  - `docker-compose/` — Compose files for services (Postgres, MongoDB, Kafka, etc.)
  - `run/` — One-liner container launch scripts (using podman)
  - `update_image/` — Scripts to pull latest versions of all local container images (Docker and Podman variants in both Python and Bash)
- **vps/** — VPS provisioning and management: Vultr API client (`vultr.py`), v2ray setup, frp tunneling, cost calculator
- **download/** — Web scrapers/downloaders (wallpaper downloader, URL batch downloader)
- **file/** — File manipulation utilities (batch git pull, file collection, text replacement)
- **update_code_sdk.sh** — Updates AI coding CLIs (Claude Code, Codex, Gemini CLI, OpenCode)

## Conventions

- Shell scripts use `#!/bin/bash` or `#!/usr/bin/bash`; run with `bash <script>.sh` or `chmod +x` then execute directly
- Python scripts use `python3`; some require external packages (`requests`, `Pillow`, `lxml`)
- Upgrade scripts follow a common pattern: fetch latest version from upstream, compare with installed version, download and replace if newer
- Container run scripts use `podman` rather than `docker`
- Scripts are Linux-focused (amd64); some paths and package managers (dnf) are Fedora-specific
