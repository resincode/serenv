#!/usr/bin/env bash
# ============================================================================
# SERENV install — Remote Bootstrap Entry Point
# One-liner: curl -fsSL https://raw.githubusercontent.com/resincode/serenv/main/install.sh | bash
#
# Environment Variables:
#   SERENV_REPO_URL   URL git repository serenv (default: git@github.com:resincode/serenv.git)
#   SERENV_DIR        Direktori target clone (default: $HOME/.serenv)
#
# Arguments: diteruskan langsung ke setup.sh (misal: --skip-packages, --skip-tpm)
# ============================================================================
set -euo pipefail

SERENV_DIR="${SERENV_DIR:-$HOME/.serenv}"
SERENV_REPO_URL="${SERENV_REPO_URL:-git@github.com:resincode/serenv.git}"

say()  { printf '\033[1;32m[serenv-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[serenv-install]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[serenv-install]\033[0m %s\n' "$*" >&2; exit 1; }

maybe_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        echo ""
    elif command -v sudo >/dev/null 2>&1; then
        echo "sudo"
    else
        echo ""
    fi
}

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

ensure_prerequisites() {
    local missing=()
    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v curl >/dev/null 2>&1 || missing+=("curl")

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi

    local pkg sudo
    pkg="$(detect_pkg_manager)"
    sudo="$(maybe_sudo)"

    say "Prasyarat belum lengkap (${missing[*]}). Menginstall via $pkg..."
    case "$pkg" in
        apk)
            $sudo apk add "${missing[@]}"
            ;;
        apt)
            $sudo apt-get update
            $sudo apt-get install -y "${missing[@]}"
            ;;
        dnf)
            $sudo dnf install -y "${missing[@]}"
            ;;
        *)
            die "Tidak dapat menginstall prasyarat secara otomatis (${missing[*]}). Silakan install manual lalu ulangi."
            ;;
    esac
}

bootstrap_repo() {
    if [ -d "$SERENV_DIR/.git" ]; then
        say "Mengupdate repositori yang sudah ada di $SERENV_DIR..."
        git -C "$SERENV_DIR" pull --ff-only || warn "Gagal fast-forward pull di $SERENV_DIR, melanjutkan dengan versi lokal yang ada."
    elif [ -d "$SERENV_DIR" ]; then
        say "Direktori $SERENV_DIR sudah ada (bukan repo git). Melanjutkan eksekusi setup.sh..."
    else
        say "Melakukan clone $SERENV_REPO_URL ke $SERENV_DIR..."
        if ! git clone --depth=1 "$SERENV_REPO_URL" "$SERENV_DIR"; then
            echo
            warn "Gagal melakukan clone dari $SERENV_REPO_URL."
            warn "Karena repository ini bersifat PRIVATE, pastikan:"
            warn "  1. SSH key GitHub sudah terpasang (atau gunakan agent forwarding: ssh -A user@server)"
            warn "  2. Atau tentukan Personal Access Token (PAT) via SERENV_REPO_URL:"
            warn "     SERENV_REPO_URL=https://<TOKEN>@github.com/resincode/serenv.git bash -c \"\$(curl -fsSL ...)\""
            die "Clone gagal."
        fi
    fi
}

main() {
    say "Memulai bootstrap serenv..."
    ensure_prerequisites
    bootstrap_repo

    if [ ! -f "$SERENV_DIR/setup.sh" ]; then
        die "setup.sh tidak ditemukan di $SERENV_DIR"
    fi

    say "Menjalankan setup.sh..."
    bash "$SERENV_DIR/setup.sh" "$@"
}

main "$@"
