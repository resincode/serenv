# serenv

[![OS - Alpine](https://img.shields.io/badge/OS-Alpine-blue?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![OS - Debian / Ubuntu](https://img.shields.io/badge/OS-Debian%20%2F%20Ubuntu-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![OS - Fedora](https://img.shields.io/badge/OS-Fedora-294172?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Shell - Zsh](https://img.shields.io/badge/Shell-Zsh-f1502f?logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![Multiplexer - Tmux](https://img.shields.io/badge/Multiplexer-Tmux-1BB91F?logo=tmux&logoColor=white)](https://github.com/tmux/tmux)
[![Theme - Catppuccin Mocha](https://img.shields.io/badge/Theme-Catppuccin%20Mocha-cba6f7?logo=catppuccin&logoColor=white)](https://github.com/catppuccin/tmux)
[![Prompt - Powerlevel10k](https://img.shields.io/badge/Prompt-Powerlevel10k-informational)](https://github.com/romkatv/powerlevel10k)

> **Server Environment Bootstrapper & Dotfiles** — Cepat, otomatis, indah, dan siap pakai untuk provisioning server Linux (VPS, container Proxmox/LXC, atau bare-metal).

---

## ⚡ Quickstart

Karena repositori ini bersifat **Private**, pastikan server target memiliki akses ke GitHub:

### Metode A: Menggunakan SSH Key / Agent Forwarding (Direkomendasikan)
Saat menghubungkan ke server baru dari mesin lokal Anda:
```bash
# Hubungkan dengan SSH agent forwarding aktif (-A)
ssh -A user@target-server

# Di dalam server, clone dan jalankan setup:
git clone git@github.com:resincode/serenv.git ~/.serenv && bash ~/.serenv/setup.sh
```

### Metode B: Menggunakan GitHub CLI / Token
Jika server telah diautentikasi dengan `gh auth login` atau memiliki Personal Access Token (PAT):
```bash
SERENV_REPO_URL="https://<TOKEN>@github.com/resincode/serenv.git" bash -c "$(curl -fsSL https://raw.githubusercontent.com/resincode/serenv/main/install.sh?token=<RAW_TOKEN>)"
```

Atau bila repositori diubah menjadi public di masa mendatang:
```bash
curl -fsSL https://raw.githubusercontent.com/resincode/serenv/main/install.sh | bash
```

---

## ✨ Fitur Utama

### 1. Tmux Catppuccin Mocha + Cgroup v2 Container Vitals
- **Status Bar Modern**: Menggunakan palet Catppuccin Mocha yang elegan dengan ikon Nerd Font.
- **Container-Aware Vitals**: Status bar menampilkan statistik akurat dari cgroup v2 container (bukan statistik host node):
  - **CPU Bar**: Visual gauge 5-segmen (`■□□□□`) + persentase penggunaan cgroup.
  - **RAM Bar**: Visual gauge memori terpakai terhadap limit cgroup container (`cgroup.memory.max`).
  - **Disk Bar**: Visual gauge kapasitas storage root filesystem.
  - **Uptime**: Durasi aktif container.
  - **App & Dir**: Nama proses yang sedang aktif dan direktori saat ini.
  - **Datetime**: Format waktu ringkas.
- **TPM (Tmux Plugin Manager)**: Otomatis meng-clone dan menginstall plugin esensial (`sensible`, `resurrect`, `continuum`, `yank`, `catppuccin`, `which-key`).
- **Ergonomi Keyboard**:
  - Prefix `Ctrl-a` (nyaman dan cepat).
  - Split horizontal `|` dan vertikal `-`.
  - Navigasi pane intuitif ala Vim (`h`, `j`, `k`, `l`).
  - Integrasi OSC52 clipboard untuk copy-paste lintas sesi SSH.

### 2. Zsh + Powerlevel10k High-Contrast Pastel Prompt
- **Desain 2-Baris**: Baris pertama memuat konteks path dan status Git; baris kedua khusus input command.
- **Palet Pastel Kontras Tinggi**: Cyan, magenta, dan soft yellow untuk keterbacaan optimal pada tema gelap.
- **Transient Prompt**: Membersihkan history visual prompt saat menekan Enter, menjaga scrollback tetap rapi.
- **Command Execution Time**: Otomatis menampilkan durasi eksekusi untuk proses yang berjalan lama (>3s).
- **Zinit Plugin Manager**: Otomatis mengunduh plugin Zsh unggulan:
  - `fast-syntax-highlighting` (pewarnaan sintaks cepat dan responsif).
  - `zsh-autosuggestions` (saran auto-complete cerdas bergaya fish).
  - `zsh-completions` & `fzf-tab` (pencarian completion interaktif dengan fuzzy finder).
  - `zsh-z` (navigasi direktori cepat).

### 3. Otomasi Auto-Attach Tmux saat SSH
- Saat login via SSH ke server interaktif (TTY), Zsh secara cerdas melakukan atomic attach ke sesi Tmux bernama `resmote` (atau membuat sesi baru bila belum ada).
- Dilengkapi proteksi nesting agar sesi Tmux di dalam sesi Tmux tidak saling bertumpuk.

### 4. Modular Local Overrides & Safe Backup
- **Safe Deployment**: Setiap file konfigurasi lama di `$HOME` yang akan ditimpa otomatis dicadangkan ke direktori `$HOME/.backup-serenv-<timestamp>/`.
- **Local Overrides**:
  - `~/.zshrc.local`: Simpan variabel environment, alias, atau secret khusus host.
  - `~/.tmux.conf.local`: Simpan custom keybindings atau opsi tmux khusus mesin lokal.

---

## 🛠️ Opsi & Flag Setup

`install.sh` meneruskan seluruh argumen CLI langsung ke `setup.sh`:

```bash
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

```
serenv/
├── install.sh                  # Entry point bootstrap remote (curl | bash)
├── setup.sh                    # Skrip provisioning lokal & modular
├── README.md                   # Dokumentasi publik repo
├── SERENV.md                   # Dokumentasi arsitektur internal
├── AGENTS.md                   # Guidelines kepemilikan & izin akses agen AI
├── .gitignore                  # Filter berkas build/backup
└── dotfiles/
    ├── tmux.conf               # Konfigurasi Tmux + Catppuccin + Vitals
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

Repositori ini dihosting secara private di `resincode/serenv`:

```bash
# Clone via SSH di server target
git clone git@github.com:resincode/serenv.git ~/.serenv

# Jalankan instalasi
bash ~/.serenv/setup.sh

# Atau dengan opsi spesifik
bash ~/.serenv/setup.sh --skip-packages
```
---

## 📄 Lisensi
MIT License — Bebas digunakan dan dimodifikasi untuk kebutuhan server pribadi maupun tim Anda.
