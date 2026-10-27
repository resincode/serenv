#!/usr/bin/env bash
# ============================================================================
# SERENV setup — provisioning server personal (tmux + zsh + SSH)
# Repo: ~/Developments/serenv  |  Docs: SERENV.md
#
# Fungsi:
#   1. Deteksi distro (apk/apt/dnf) + install paket inti (zsh tmux git fzf curl)
#   2. Deploy dotfiles ke $HOME (file lama di-backup)
#   3. Auto-install tema Powerlevel10k (~/.powerlevel10k)
#   4. Auto-install plugin manager Zinit (~/.local/share/zinit/zinit.git)
#   5. Clone TPM + install plugin tmux (sensible, resurrect, continuum, yank,
#      catppuccin, which-key)
#   6. Deploy template local override (~/.zshrc.local, ~/.tmux.conf.local)
#
# Penggunaan:
#   bash setup.sh                     # full (butuh sudo/net)
#   bash setup.sh --skip-packages     # lewati install paket sistem
#   bash setup.sh --skip-p10k         # lewati clone Powerlevel10k
#   bash setup.sh --skip-zinit        # lewati clone Zinit
#   bash setup.sh --skip-tpm          # lewati clone TPM + plugin tmux
#   bash setup.sh --help
#
# Peringatan: menulis ke $HOME. Jalankan di server baru, bukan server aktif.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.1.0")"
SKIP_PACKAGES=0
SKIP_P10K=0
SKIP_ZINIT=0
SKIP_TPM=0

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --skip-packages) SKIP_PACKAGES=1 ;;
        --skip-p10k)     SKIP_P10K=1 ;;
        --skip-zinit)    SKIP_ZINIT=1 ;;
        --skip-tpm)      SKIP_TPM=1 ;;
        --version|-v)    echo "serenv v$VERSION"; exit 0 ;;
        --help|-h)       usage ;;
        *) echo "Argumen tidak dikenal: $arg"; usage ;;
    esac
done

say()  { printf '\033[1;32m[serenv]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[serenv]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[serenv]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Deteksi distro / package manager
# ---------------------------------------------------------------------------
detect_pkg_manager() {
    if [ -f /etc/alpine-release ]; then
        echo "apk"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

maybe_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        echo ""
    elif command -v sudo >/dev/null 2>&1; then
        echo "sudo"
    else
        echo ""
    fi
}

install_core_packages() {
    local pkg="$1" sudo="$(maybe_sudo)"
    say "Install paket inti ($pkg): zsh tmux git fzf curl"
    case "$pkg" in
        apk)
            $sudo apk add zsh tmux git fzf curl zsh-vcs
            ;;
        apt)
            $sudo apt-get update
            $sudo apt-get install -y zsh tmux git fzf curl
            ;;
        dnf)
            $sudo dnf install -y zsh tmux git fzf curl
            ;;
        *)
            die "Package manager tidak dikenali. Install manual: zsh, tmux, git, fzf, curl."
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Deploy dotfiles dengan backup & template local override
# ---------------------------------------------------------------------------
deploy_dotfiles() {
    local backup_dir="$HOME/.backup-serenv-$(date +%Y%m%d-%H%M%S)"
    local src dest

    deploy_file() {
        src="$1"; dest="$2"
        if [ ! -f "$src" ]; then
            warn "Lewati (tidak ada di repo): $src"
            return
        fi
        if [ -e "$dest" ]; then
            mkdir -p "$backup_dir"
            cp -a "$dest" "$backup_dir/"
            warn "Backup $dest -> $backup_dir/"
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        say "Deploy $dest"
    }

    deploy_template() {
        local dest="$1" content="$2"
        if [ ! -f "$dest" ]; then
            mkdir -p "$(dirname "$dest")"
            printf '%s\n' "$content" > "$dest"
            say "Deploy template $dest"
        fi
    }

    deploy_file "$DOTFILES_DIR/tmux.conf"            "$HOME/.tmux.conf"
    deploy_file "$DOTFILES_DIR/zshrc"                "$HOME/.zshrc"
    deploy_file "$DOTFILES_DIR/zshenv"               "$HOME/.zshenv"
    deploy_file "$DOTFILES_DIR/p10k.zsh"             "$HOME/.p10k.zsh"
    deploy_file "$DOTFILES_DIR/local/bin/status-vitals" "$HOME/.local/bin/status-vitals"
    chmod +x "$HOME/.local/bin/status-vitals" 2>/dev/null || true
    deploy_file "$DOTFILES_DIR/zshrc-omp-addon"      "$HOME/.zshrc-omp-addon"
    deploy_file "$DOTFILES_DIR/config/omp/config.json" "$HOME/.config/omp/config.json"
    deploy_file "$DOTFILES_DIR/omp/models.yml"       "$HOME/.omp/agent/models.yml"

    deploy_template "$HOME/.zshrc.local" "# ~/.zshrc.local — Host-specific environment and alias overrides for zsh"$'\n'"# Put machine-specific tokens, paths, or secrets here."
    deploy_template "$HOME/.tmux.conf.local" "# ~/.tmux.conf.local — Host-specific tmux keybindings and configuration overrides"$'\n'"# Put machine-specific tmux options here."
    deploy_template "$HOME/.env" "# ~/.env — Secret keys and environment variables (loaded automatically by ~/.zshenv)"$'\n'"# API_KEY_MIDAS="$'\n'"# API_KEY_DPROUTER="
}

# ---------------------------------------------------------------------------
# Powerlevel10k theme
# ---------------------------------------------------------------------------
install_p10k() {
    local p10k_dir="$HOME/.powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        say "Clone Powerlevel10k ke $p10k_dir"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k "$p10k_dir"
    else
        say "Powerlevel10k sudah ada: $p10k_dir"
    fi
}

# ---------------------------------------------------------------------------
# Zinit plugin manager
# ---------------------------------------------------------------------------
install_zinit() {
    local zinit_dir="$HOME/.local/share/zinit/zinit.git"
    if [ ! -d "$zinit_dir" ]; then
        say "Clone Zinit ke $zinit_dir"
        mkdir -p "$(dirname "$zinit_dir")"
        git clone --depth=1 https://github.com/zdharma-continuum/zinit "$zinit_dir"
    else
        say "Zinit sudah ada: $zinit_dir"
    fi
}

# ---------------------------------------------------------------------------
# TPM + plugin tmux
# ---------------------------------------------------------------------------
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [ ! -d "$tpm_dir" ]; then
        say "Clone TPM ke $tpm_dir"
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    else
        say "TPM sudah ada: $tpm_dir"
    fi

    say "Install plugin tmux via TPM (menyalakan tmux server detached)"
    "$tpm_dir/scripts/install_plugins.sh"
}

# ---------------------------------------------------------------------------
# Catatan akhir
# ---------------------------------------------------------------------------
print_notes() {
    local pkg="$1"
    echo
    say "Setup selesai! Komponen serenv terkonfigurasi:"
    echo "  ✓ Dotfiles (.tmux.conf, .zshrc, .p10k.zsh, .zshenv, status-vitals)"
    echo "  ✓ Powerlevel10k prompt (~/.powerlevel10k)"
    echo "  ✓ Zinit plugin manager (~/.local/share/zinit)"
    echo "  ✓ TPM + tmux plugins (~/.tmux/plugins/)"
    echo "  ✓ Local override templates (~/.zshrc.local, ~/.tmux.conf.local)"
    echo
    echo "Langkah opsional / catatan tambahan:"
    echo "  [Opsional] Tools modern CLI yang kompatibel dengan alias .zshrc:"
    echo "      $pkg: bat eza/exa ripgrep"
    echo
    echo "  [Opsional] Host-specific configuration:"
    echo "      Edit ~/.zshrc.local dan ~/.tmux.conf.local sesuai kebutuhan server ini."
    echo
    echo "  [Tip Clipboard OSC52 bila tmux di mesin lokal]:"
    echo "      Pastikan terminal klien mendukung OSC52 (misal Alacritty >= 0.13, Ghostty, iTerm2)."
    echo
    echo "Silakan buka terminal baru atau restart shell untuk mengaktifkan perubahan:"
    echo "      exec zsh"
    echo
}

# ---------------------------------------------------------------------------
main() {
    say "SERENV v${VERSION} — Memulai provisioning server personal..."
    local pkg
    pkg="$(detect_pkg_manager)"
    say "Distro terdeteksi: ${pkg:-unknown}"

    if [ "$SKIP_PACKAGES" -eq 1 ]; then
        warn "--skip-packages: lewati install paket"
    else
        install_core_packages "$pkg"
    fi

    deploy_dotfiles

    if [ "$SKIP_P10K" -eq 1 ]; then
        warn "--skip-p10k: lewati clone Powerlevel10k"
    else
        install_p10k
    fi

    if [ "$SKIP_ZINIT" -eq 1 ]; then
        warn "--skip-zinit: lewati clone Zinit"
    else
        install_zinit
    fi

    if [ "$SKIP_TPM" -eq 1 ]; then
        warn "--skip-tpm: lewati clone TPM + install plugin"
    else
        install_tpm
    fi

    print_notes "$pkg"
}
main "$@"
