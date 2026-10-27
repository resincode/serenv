# serenv

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](VERSION)
[![OS - Alpine](https://img.shields.io/badge/OS-Alpine-blue?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![OS - Debian / Ubuntu](https://img.shields.io/badge/OS-Debian%20%2F%20Ubuntu-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![OS - Fedora](https://img.shields.io/badge/OS-Fedora-294172?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Shell - Zsh](https://img.shields.io/badge/Shell-Zsh-f1502f?logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![Multiplexer - Tmux](https://img.shields.io/badge/Multiplexer-Tmux-1BB91F?logo=tmux&logoColor=white)](https://github.com/tmux/tmux)
[![Theme - Catppuccin Mocha](https://img.shields.io/badge/Theme-Catppuccin%20Mocha-cba6f7?logo=catppuccin&logoColor=white)](https://github.com/catppuccin/tmux)
[![Prompt - Powerlevel10k](https://img.shields.io/badge/Prompt-Powerlevel10k-informational)](https://github.com/romkatv/powerlevel10k)
[![License - MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> **Server Environment Bootstrapper & Dotfiles** — Cepat, otomatis, konsisten, dan siap pakai untuk provisioning server Linux (VPS, Proxmox LXC container, atau bare-metal) dengan pengalaman shell modern.

---

## ⚡ Quickstart

Repositori ini berada di GitHub `resincode/serenv`. Pilih salah satu metode instalasi:

### Metode A: SSH Key / Agent Forwarding (Direkomendasikan)
Hubungkan ke server baru dengan SSH agent forwarding (`-A`):
```bash
# Hubungkan dari mesin lokal
ssh -A user@target-server

# Di dalam server target:
git clone git@github.com:resincode/serenv.git ~/.serenv && bash ~/.serenv/setup.sh
```

### Metode B: GitHub CLI / Personal Access Token
Jika server telah diautentikasi dengan `gh` atau token GitHub:
```bash
SERENV_REPO_URL="https://<TOKEN>@github.com/resincode/serenv.git" \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/resincode/serenv/main/install.sh?token=<RAW_TOKEN>)"
```

Atau instalasi langsung publik (bila repositori bersifat public):
```bash
curl -fsSL https://raw.githubusercontent.com/resincode/serenv/main/install.sh | bash
```

---

## 🖥️ Layout Status Bar Tmux

Status bar Tmux dikonfigurasi di sisi atas (`top`) dengan komposisi modul yang seimbang dan simetris antara sisi kiri dan kanan, serta daftar tab window di posisi tengah (`centre`):

```text
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│ [session] [app] [dir] [uptime]      [ 1:main ] [ 2:code* ]            [cpu] [ram] [disk]  │
│ └───────── status-left ─────────┘   └─ status-justify centre ─┘   └───── status-right ──┘ │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

| Bagian | Posisi | Modul & Keterangan |
|---|---|---|
| **`status-left`** | Kiri atas (4 modul) | • **Session**: `#S · user@host` (identitas sesi aktif)<br>• **App**: ` <proc>` (indikator proses/aplikasi aktif di pane)<br>• **Dir**: ` <path>` (direktori kerja saat ini)<br>• **Uptime**: `󰔟 <duration>` (waktu aktif kontainer/server) |
| **`status-justify`** | Tengah (`centre`) | • **Window Tabs**: Daftar tab window aktif/inaktif dengan style rounded pill Catppuccin Mocha dan indikator zoom `[Z]`. |
| **`status-right`** | Kanan atas (3 modul) | • **CPU**: `󰊚 <%>` (persentase utilisasi CPU tanpa bar)<br>• **RAM**: `󰘚 ■■■□□ <used>` (gauge memori terhadap limit cgroup container)<br>• **Disk**: `󰋊 <used>/<total> GB` (storage terpakai/total dalam GB tanpa bar) |
---

## ✨ Fitur Utama

### 1. Tmux Catppuccin Mocha + Cgroup v2 Container Vitals
- **Status Bar Seimbang**: Penataan 4 modul informasi di kiri, tab window di tengah (`centre`), dan 4 modul metrik di kanan.
- **Container-Aware Vitals**: Status bar membaca metrik langsung dari cgroup v2 container (bukan statistik host node Proxmox):
  - **CPU Gauge**: Visual gauge 5-segmen (`■□□□□`) + persentase penggunaan cgroup (`/sys/fs/cgroup/cpu.stat`).
  - **RAM Gauge**: Visual gauge memori terpakai terhadap limit cgroup container (`cgroup.memory.max`).
  - **Disk Gauge**: Visual gauge kapasitas storage root filesystem terhadap kuota disk.
  - **Uptime**: Durasi aktif container dari `/proc/uptime`.
- **Fitur Terminal Modern**:
  - **OSC 8 Hyperlinks**: Tautan URL di terminal dapat langsung diklik (`set -as terminal-features ',*:hyperlinks'`).
  - **OSC 52 Clipboard**: Copy-paste langsung terhubung ke clipboard terminal lokal, bahkan melalui sesi SSH headless bertingkat.
- **TPM (Tmux Plugin Manager)**: Otomatis mengelola plugin esensial:
  - `tmux-sensible` (opsi standar yang aman)
  - `tmux-resurrect` & `tmux-continuum` (simpan & pulihkan sesi otomatis setiap 15 menit)
  - `tmux-yank` (OSC52 clipboard integration)
  - `catppuccin/tmux` (tema Mocha dengan rounded pills)
  - `tmux-which-key` (menu popup panduan keybinding)
- **Ergonomi Keyboard**:
  - Prefix `Ctrl-a` (ergonomis dan cepat).
  - Split horizontal `|` dan vertikal `-` (otomatis mempertahankan path direktori saat ini).
  - Navigasi pane intuitif ala Vim (`h`, `j`, `k`, `l` atau `Alt+h/j/k/l`).

### 2. Zsh + Powerlevel10k High-Contrast Pastel Prompt
- **Desain 2-Baris**: Baris pertama memuat path direktori dan status Git terperinci; baris kedua khusus input command.
- **Palet Pastel Kontras Tinggi**: Cyan, magenta, dan soft yellow untuk keterbacaan optimal di berbagai terminal emulator.
- **Transient Prompt**: Membersihkan riwayat visual prompt saat menekan Enter, menjaga scrollback terminal tetap bersih.
- **Execution Timer**: Otomatis menampilkan durasi eksekusi untuk perintah yang memakan waktu >3 detik.
- **Zinit Plugin Ecosystem**:
  - `fast-syntax-highlighting` (highlighting sintaks perintah seketika).
  - `zsh-autosuggestions` (auto-complete cerdas berdasarkan riwayat shell).
  - `zsh-completions` & `fzf-tab` (menu completion interaktif dengan pencarian fuzzy).
  - `zsh-z` (lompat ke direktori favorit dengan cepat).

### 3. Otomasi Auto-Attach Tmux saat SSH
- Saat login ke sesi interaktif via SSH, Zsh secara cerdas melakukan atomic attach ke sesi Tmux bernama `metra2` (atau membuat sesi baru bila belum ada).
- Proteksi nesting mencegah sesi Tmux bertumpuk di dalam sesi Tmux yang sudah aktif, dan sesi non-interaktif tidak akan memicu Tmux.
### 4. Modular Local Overrides & Safe Backup
- **Safe Deployment**: Setiap file konfigurasi lama di `$HOME` yang akan ditimpa otomatis dicadangkan ke `$HOME/.backup-serenv-<timestamp>/`.
- **Local Overrides**:
  - `~/.zshrc.local`: Simpan variabel environment, alias, atau secret khusus mesin host.
  - `~/.tmux.conf.local`: Simpan custom keybinding atau konfigurasi khusus mesin host.

---

## 🛠️ Opsi & Flag Setup

`install.sh` meneruskan seluruh argumen CLI langsung ke `setup.sh`:

```bash
# Cek versi serenv
bash setup.sh --version

# Jalankan setup tanpa menginstall paket sistem (hanya deploy dotfiles & plugins)
bash setup.sh --skip-packages

# Lewati instalasi tema Powerlevel10k
bash setup.sh --skip-p10k

# Lewati instalasi plugin manager Zinit
bash setup.sh --skip-zinit

# Lewati instalasi TPM dan plugin tmux
bash setup.sh --skip-tpm

# Tampilkan bantuan
bash setup.sh --help
```

---

## 📂 Struktur Repositori

```text
serenv/
├── VERSION                     # Berkas tracking versi semver (v1.1.0)
├── install.sh                  # Entry point bootstrap remote (curl | bash)
├── setup.sh                    # Skrip provisioning lokal & modular
├── README.md                   # Dokumentasi publik repositori
├── SERENV.md                   # Dokumentasi teknis & arsitektur internal
├── AGENTS.md                   # Panduan & boundary kerja agen AI
├── .gitignore                  # Filter berkas build/backup
└── dotfiles/
    ├── tmux.conf               # Konfigurasi Tmux + Catppuccin + Centered Vitals
    ├── zshrc                   # Konfigurasi Zsh + Zinit + SSH Auto-attach
    ├── zshenv                  # Environment awal Zsh
    ├── p10k.zsh                # Konfigurasi tema Powerlevel10k 2-baris pastel
    ├── zshrc-omp-addon         # Ekstensi penunjang environment omp
    ├── config/
    │   └── omp/config.json     # Konfigurasi runner omp
    └── local/
        └── bin/
            └── status-vitals   # Daemon cgroup v2 status parser (CPU/RAM/Disk/Uptime)
```

---

## 🚀 Deployment ke Server Baru

```bash
# Clone via SSH di server target
git clone git@github.com:resincode/serenv.git ~/.serenv

# Jalankan instalasi penuh
bash ~/.serenv/setup.sh

# Atau instalasi tanpa paket distro (jika user non-root/tanpa sudo)
bash ~/.serenv/setup.sh --skip-packages
```

---

## 📄 Lisensi
[MIT License](LICENSE) — Bebas digunakan dan dimodifikasi untuk kebutuhan server pribadi maupun tim Anda.
