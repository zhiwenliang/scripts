#!/bin/bash
set -euo pipefail

# ============================================================================
# Ubuntu Development Environment Bootstrap Script
# Supports: Ubuntu and Ubuntu-based distributions with apt
# Usage: sudo is requested per-command; do NOT run the whole script as root.
# ============================================================================

info()  { printf '\n\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
warn()  { printf '\n\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }

command_exists() { command -v "$1" &>/dev/null; }

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO_ID="${ID,,}"
else
    echo "Cannot detect distro: /etc/os-release not found" >&2
    exit 1
fi

case "$DISTRO_ID" in
    ubuntu|debian|linuxmint|pop)
        PKG_UPDATE='sudo apt update && sudo apt upgrade -y'
        PKG_INSTALL='sudo apt install -y'
        ;;
    *)
        echo "This script is for Ubuntu-family systems. Detected: $DISTRO_ID" >&2
        exit 1
        ;;
esac

info "Detected distro: $DISTRO_ID"

info "Updating system packages"
eval "$PKG_UPDATE"

info "Installing base packages"
COMMON_PKGS=(
    git curl wget zip unzip tar
    gcc g++ make cmake gdb
    vim tmux
    meld wireshark
    libreoffice calibre
    cups ffmpeg
    software-properties-common
    apt-transport-https
    ca-certificates
    gnupg
    lsb-release
    build-essential
    pkg-config
    npm
)
$PKG_INSTALL "${COMMON_PKGS[@]}"

info "Configuring git"
git config --global user.name "zhiwen"
git config --global user.email "zhiwen_liang@outlook.com"
git config --global core.autocrlf false
git config --global init.defaultBranch main
ok "Git configured"

info "Installing Go"
if command_exists go; then
    ok "Go already installed: $(go version)"
else
    GO_LATEST=$(curl -fsSL 'https://go.dev/dl/?mode=json' | grep -oP '"version":\s*"go\K[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | tr -d '"')
    GO_TAR="go${GO_LATEST}.linux-amd64.tar.gz"
    curl -fsSL "https://go.dev/dl/${GO_TAR}" -o "/tmp/${GO_TAR}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "/tmp/${GO_TAR}"
    rm -f "/tmp/${GO_TAR}"

    if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    ok "Go $(go version) installed"
fi

info "Installing Rust"
if command_exists rustc; then
    ok "Rust already installed: $(rustc --version)"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    ok "Rust $(rustc --version) installed"
fi

info "Installing Java ecosystem via SDKMAN"
if [[ -d "$HOME/.sdkman" ]]; then
    ok "SDKMAN already installed"
else
    curl -fsSL "https://get.sdkman.io" | bash
fi

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

sdk install java < /dev/null || true
sdk install maven < /dev/null || true
sdk install mvnd < /dev/null || true
sdk install gradle < /dev/null || true
ok "Java ecosystem ready"

info "Installing Node.js via nvm"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
ok "Node $(node --version) installed"

info "Installing Miniconda"
if command_exists conda; then
    ok "Conda already installed: $(conda --version)"
else
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
    rm -f /tmp/miniconda.sh
    "$HOME/miniconda3/bin/conda" init bash
    ok "Miniconda installed at ~/miniconda3"
fi

info "Installing container tools"
$PKG_INSTALL podman
if ! command_exists docker; then
    curl -fsSL https://get.docker.com | sh
fi
sudo usermod -aG docker "$USER" 2>/dev/null || true
ok "Container tools installed (re-login for docker group)"

info "Installing Kubernetes tools"
if ! command_exists kubectl; then
    KUBECTL_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl" -o /tmp/kubectl
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
fi
ok "kubectl $(kubectl version --client --short 2>/dev/null || echo 'installed')"

if ! command_exists helm; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
ok "helm installed"

info "Installing CLI productivity tools"
$PKG_INSTALL zsh fzf ripgrep bat fd-find jq htop direnv

if ! command_exists eza; then
    EZA_VER=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VER}/eza_x86_64-unknown-linux-gnu.tar.gz" -o /tmp/eza.tar.gz
    sudo tar -C /usr/local/bin -xzf /tmp/eza.tar.gz
    rm -f /tmp/eza.tar.gz
fi

if ! command_exists lazygit; then
    LG_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" -o /tmp/lazygit.tar.gz
    sudo tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit
    rm -f /tmp/lazygit.tar.gz
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if ! grep -q 'direnv hook' ~/.bashrc; then
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
fi
ok "CLI tools installed"

info "Installing extra dev tools"
if ! command_exists gh; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi
ok "gh (GitHub CLI) installed"

if ! command_exists bun; then
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi
ok "Bun installed"

if ! command_exists deno; then
    curl -fsSL https://deno.land/install.sh | sh
    if ! grep -q '.deno/bin' ~/.bashrc; then
        echo 'export PATH="$HOME/.deno/bin:$PATH"' >> ~/.bashrc
    fi
    export PATH="$HOME/.deno/bin:$PATH"
fi
ok "Deno installed"

if ! command_exists just; then
    JUST_VER=$(curl -fsSL https://api.github.com/repos/casey/just/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VER}/just-${JUST_VER}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/just.tar.gz
    sudo tar -C /usr/local/bin -xzf /tmp/just.tar.gz just
    rm -f /tmp/just.tar.gz
fi
ok "just installed"

if ! command_exists protoc; then
    PROTOC_VER=$(curl -fsSL https://api.github.com/repos/protocolbuffers/protobuf/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VER}/protoc-${PROTOC_VER}-linux-x86_64.zip" -o /tmp/protoc.zip
    sudo unzip -o /tmp/protoc.zip -d /usr/local bin/protoc 'include/*'
    rm -f /tmp/protoc.zip
fi
ok "protoc installed"

if ! command_exists xh; then
    XH_VER=$(curl -fsSL https://api.github.com/repos/ducaale/xh/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -fsSL "https://github.com/ducaale/xh/releases/download/v${XH_VER}/xh-v${XH_VER}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/xh.tar.gz
    tar -xzf /tmp/xh.tar.gz -C /tmp
    sudo install -m 0755 "/tmp/xh-v${XH_VER}-x86_64-unknown-linux-musl/xh" /usr/local/bin/xh
    rm -rf /tmp/xh*
fi
ok "xh (httpie-compatible HTTP client) installed"

info "Installing JetBrains Mono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ! ls "$FONT_DIR"/JetBrainsMonoNerd* &>/dev/null; then
    NERD_VER=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VER}/JetBrainsMono.tar.xz" -o /tmp/JetBrainsMono.tar.xz
    tar -xJf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    fc-cache -fv "$FONT_DIR"
    rm -f /tmp/JetBrainsMono.tar.xz
fi
ok "JetBrains Mono Nerd Font installed"

info "Installing VS Code"
if command_exists code; then
    ok "VS Code already installed"
else
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt update
    sudo apt install -y code
    ok "VS Code installed"
fi

info "Installing Google Chrome"
if command_exists google-chrome-stable || command_exists google-chrome; then
    ok "Chrome already installed"
else
    curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/chrome.deb
    sudo apt install -y /tmp/chrome.deb
    rm -f /tmp/chrome.deb
    ok "Chrome installed"
fi

info "Installing Flatpak apps"
if ! command_exists flatpak; then
    $PKG_INSTALL flatpak
fi
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.telegram.desktop || true
flatpak install -y flathub com.obsidian.Obsidian || true
flatpak install -y flathub org.videolan.VLC || true
flatpak install -y flathub com.getpostman.Postman || true
flatpak install -y flathub com.bitwarden.desktop || true
flatpak install -y flathub com.obsproject.Studio || true
flatpak install -y flathub org.gimp.GIMP || true
flatpak install -y flathub com.jgraph.drawio.desktop || true
ok "Flatpak apps installed"

info "Installing AI coding CLIs"
if command_exists claude; then
    ok "Claude Code already installed"
else
    curl -fsSL https://claude.ai/install.sh | bash
    ok "Claude Code installed"
fi

if command_exists codex; then
    ok "Codex CLI already installed"
else
    npm i -g @openai/codex@latest
    ok "Codex CLI installed"
fi

if command_exists gemini; then
    ok "Gemini CLI already installed"
else
    npm i -g @google/gemini-cli@latest
    ok "Gemini CLI installed"
fi

if command_exists opencode; then
    ok "OpenCode already installed"
else
    curl -fsSL https://opencode.ai/install | bash
    ok "OpenCode installed"
fi

if command_exists openclaw; then
    ok "OpenClaw already installed"
else
    warn "OpenClaw is not installed. Install it manually if needed."
fi

ok "Ubuntu bootstrap complete"
info "Restart your shell or run: source ~/.bashrc"
