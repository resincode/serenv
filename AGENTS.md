# AGENTS.md — SERENV

Panduan untuk agent (atau manusia) yang bekerja di repo ini.

## Apa ini

Setup server personal yang reproducible: **tmux + zsh + integrasi SSH**, untuk server Alpine headless yang diakses lewat SSH. Repo berisi dokumentasi (`SERENV.md`), installer (`setup.sh`), dan snapshot config (`dotfiles/`).

## Cara pakai

1. **Baca `SERENV.md` dulu** — arsitektur, detail tmux/zsh, known issues, langkah setup. Dokumen ini sumber kebenaran utama.
2. Mau provisioning server baru → `bash setup.sh` (deteksi distro apk/apt/dnf; install inti `zsh tmux git fzf`; deploy dotfiles dengan backup; install plugin tmux via TPM).
3. Mau bantu fix/diagnosa → baca Known Issues di `SERENV.md` §6; banyak masalah sudah terdokumentasi dengan solusinya.

## Fakta penting (jangan salah asumsi)

- **Prompt = Powerlevel10k, BUKAN Oh My Posh.** Binary `op` tidak terpasang di server; blok OMP di `.zshenv`/`.zshrc-omp-addon` tidak aktif. `.zshrc-omp-addon` dan `.config/omp/config.json` hanya arsip.
- **`dotfiles/` = snapshot, bukan symlink.** Config live di `~/.tmux.conf`, `~/.zshrc`, `~/.zshenv`. Jangan menganggap edit di repo otomatis nyentuh live. Jika config live berubah dan layak diarsipkan, perbarui snapshot + tabel Provenance di `SERENV.md` §7.
- **Headless**: tidak ada X display → `xclip` pasti gagal. Clipboard via OSC52. Set `set-clipboard on` di SEMUA layer tmux (server + mesin lokal). Jangan "perbaiki" dengan memasang xclip display.
- **fzf `--zsh`** di `.zshrc` sengaja di-guard `[[ -t 0 ]]` — jangan dihapus (Known Issues #1).
- **catppuccin** wajib terpasang di `~/.tmux/plugins/catppuccin`; status bar wajib `#{E:@catppuccin_status_...}` (jangan hapus `E:`, Known Issues #4).
- **Alpine**: `zsh-vcs` wajib untuk vcs_info (Known Issues #2).

## Aturan kerja di repo ini

- Jangan ubah config live di `~` tanpa izin pemilik.
- Jangan jalankan `setup.sh` pada server yang sedang dipakai (menulis ke `$HOME`); gunakan di server baru, atau uji dengan `HOME` sementara + `--skip-packages --skip-tpm`.
- Jangan commit history shell, secret, atau file pribadi.
- Dokumentasi dan komentar script: Bahasa Indonesia (konvensi repo).
- Script: bash + `set -euo pipefail`, idempotent, deteksi distro.