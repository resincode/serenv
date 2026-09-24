# SERENV — Setup Server Personal (tmux + zsh + SSH)

Reproducible setup untuk server personal yang diakses via SSH. Repo ini berisi:

- **`dotfiles/`** — snapshot konfigurasi live (`~/.tmux.conf`, `~/.zshrc`, dsb.). Config live TIDAK di-symlink ke sini; snapshot diambil manual (lihat Provenance).
- **`setup.sh`** — provisioning server baru: install paket inti + deploy dotfiles + install plugin tmux (TPM).
- **`AGENTS.md`** — panduan singkat untuk agent yang bekerja di repo ini.

Bahasa dokumentasi: Indonesia.

---

## 1. Arsitektur

```
Alacritty (mesin lokal)
  └─ tmux LOKAL (outer)              ← wajib set-clipboard on (lihat OSC52)
       └─ ssh ke server
            └─ tmux SERVER "resmote"  ← auto-attach saat SSH
                 └─ zsh (prompt p10k)
```

Server target: **Alpine Linux headless** (tanpa X display), zsh 5.9, tmux 3.5a. Karena headless, **`xclip` tidak berfungsi** (tidak ada DISPLAY) — clipboard lewat **OSC52**.

Penting: **prompt yang terlihat adalah Powerlevel10k, BUKAN Oh My Posh.** Binary `op` tidak terpasang di server, jadi blok OMP di `.zshenv`/`.zshrc-omp-addon` tidak aktif. (`~/.zshrc-omp-addon` dan `~/.config/omp/config.json` hanyalah arsip referensi.)

---

## 2. Tmux (`dotfiles/tmux.conf`)

| Bagian | Isi |
|---|---|
| Prefix | `C-a` (bukan C-b) |
| Terminal | `tmux-256color`, override `xterm-256color:RGB` |
| Clipboard | `set -g set-clipboard on` → OSC52 ke terminal (lihat Known Issues #3) |
| Mouse | `on` |
| History | 50000 baris |
| Penomoran | window & pane mulai dari 1, renumber otomatis |
| Reload | `prefix + r` → `source-file ~/.tmux.conf` |

### Keybindings

- Splits: `prefix + |` (vertikal), `prefix + -` (horizontal), tetap di direktori sama
- Navigasi pane: `prefix + h/j/k/l`, juga `Alt+h/j/k/l` tanpa prefix
- Resize: `prefix + H/J/K/L` (repeatable)
- Window: `Alt+←/→`, `Alt+,`/`Alt+.`
- Session: `prefix + S` (choose-session), `prefix + N` (new-session)
- Copy mode vi: `prefix + Enter` masuk, `v` mulai seleksi, `C-v` rectangle, `y` yank, `Esc` keluar, `H`/`L` awal/akhir baris

### Plugin (via TPM)

```
tmux-plugins/tpm                (manager)
tmux-plugins/tmux-sensible
tmux-plugins/tmux-resurrect     (restore sesi; capture pane contents; strategi nvim/vim)
tmux-plugins/tmux-continuum     (auto-save 15 menit + restore saat start)
tmux-plugins/tmux-yank          (copy clipboard; @override_copy_command 'cat' — OSC52 ditangani tmux, BUKAN xclip)
catppuccin/tmux#v2.1.2          (tema, flavor mocha)
alexwforsythe/tmux-which-key    (menu prefix)
```

### Tema catppuccin — status bar

```tmux
set -g status-position top
set -g status-left-length  100
set -g status-right-length 250
set -g status-left  "#{E:@catppuccin_status_session} "
set -g status-right "#{E:@catppuccin_status_application}#{E:@catppuccin_status_directory}#{E:@catppuccin_status_load}#{E:@catppuccin_status_ram}#{E:@catppuccin_status_disk}#{E:@catppuccin_status_uptime}#{E:@catppuccin_status_date_time}"
```

- **Status-left**: Menggabungkan nama session tmux aktif dengan user dan hostname container (`@catppuccin_session_text " #S · #(whoami)@#H"`).
- **Status-right**: Tersusun berurutan dari kiri ke kanan:
  1. `application`: nama perintah/aplikasi aktif di pane (maroon pill)
  2. `directory`: path direktori aktif (rosewater pill)
  3. `load`: utilisasi CPU riil container dari cgroup v2 (`/sys/fs/cgroup/cpu.stat`) dengan visual indicator bar (peach pill)
  4. `ram`: indicator bar pemakaian memori terhadap batas limit 4G container (mauve pill)
  5. `disk`: indicator bar pemakaian storage terhadap batas limit 25G container (teal pill)
  6. `uptime`: uptime riil container dari `/proc/uptime` (sapphire pill)
  7. `date_time`: jam & tanggal di posisi paling kanan (sapphire pill)
- **Script pembantu**: `~/.local/bin/status-vitals` yang mengekstrak metrik container secara akurat tanpa membaca metrik host Proxmox.

**WAJIB pakai `#{E:@catppuccin_status_...}` (dengan `E:`).** Tanpa `E:`, tmux memasukkan nilai option tanpa re-expand format di dalamnya → teks literal seperti `@catppuccin_session_text` muncul di header (lihat Known Issues #4).

Plugin catppuccin harus terpasang di `~/.tmux/plugins/catppuccin` (nama direktori sesuai `@plugin`). Clone yang salah nama (mis. `plugins/tmux`) terbukti bikin masalah.
---

## 3. Zsh

### `~/.zshrc` (snapshot: `dotfiles/zshrc`)

Urutan section:

1. **Auto-attach tmux saat SSH** (lihat §4)
2. **Environment**: `TERM=xterm-256color`, history 10000, PATH
3. **History setopts**: append, extended, dedup, share
4. **Completion**: `compinit` + zstyle menu/matcher/list-colors
5. **Bindings** emacs + ekstra (`^w`, `^u`, `^k`, dst.)
6. **Aliases**: `ls`/`ll`/`la`/`l`/`tree` (exa/eza), `cat` (bat), `grep` (rg), `clip`/`paste` (xclip — **tidak berfungsi di headless**, pakai OSC52), `top` (htop), git singkat, omp helpers
7. **Fungsi**: `mkcd`, `show_path`, `extract`, `backup`, `gst`/`gac`, `sysinfo`, markdown helpers (`md`, `docs`, `docsearch`)
8. **vcs_info** + PS1: Disederhanakan karena prompt utama dikelola sepenuhnya oleh Powerlevel10k (`source ~/.p10k.zsh`).
9. **Powerlevel10k**: Memuat tema jika `~/.powerlevel10k` ada, lalu secara eksplisit me-source `~/.p10k.zsh`.
10. **zinit** (jika `~/.local/share/zinit/zinit.git/zinit.zsh` ada): fast-syntax-highlighting, zsh-autosuggestions, zsh-completions, fzf-tab, zsh-z
11. **fzf key bindings** — `source <(fzf --zsh)` **hanya jika TTY interaktif** (lihat Known Issues #1)
12. `FZF_DEFAULT_OPTS`, `ZSH_HIGHLIGHT_STYLES`, `LS_COLORS`

Semua blok opsional di-guard `if`, jadi config aman walau tool-nya belum terpasang.

### `~/.zshenv` (snapshot: `dotfiles/zshenv`)

- PATH ke `~/.local/bin`, `OMP_MODEL` (default `claude-haiku-4-5`)
- Inisialisasi Oh My Posh — **tidak aktif** (`command -v op` gagal; prompt tetap p10k)

### `~/.p10k.zsh` (snapshot: `dotfiles/p10k.zsh`)

Konfigurasi Powerlevel10k tema Classic Powerline 2-baris dengan palet pastel kontras tinggi:
- **Baris 1**: Direktori (`dir`) + git status (`vcs`), diakhiri segitiga solid `` (`\uE0B0`). Informasi `user@host` sengaja ditiadakan dari prompt agar ringkas, karena sudah tampil permanen di status-left tmux.
- **Baris 2**: Hanya prompt symbol `❯` (tanpa bingkai kotak `╭─╰─`).
- **Pemisah subsegmen**: Segitiga tipis `` (`\uE0B1`) dan `` (`\uE0B3`) warna slate `#6c7086`.
- **Background**: Unified dark bar Catppuccin Surface0 (`#313244`).
- **Fitur tambahan**: Execution time indicator (`>= 1s`) dan transient prompt (`same-dir`).

### `~/.local/bin/status-vitals` (snapshot: `dotfiles/local/bin/status-vitals`)

Script pembantu status bar tmux untuk membaca metrik container LXC secara riil:
- `status-vitals cpu` → CPU % aktual container dari `/sys/fs/cgroup/cpu.stat` (cgroup v2 delta).
- `status-vitals ram` → Indicator bar memori terhadap limit container 4 GB dari `/proc/meminfo`.
- `status-vitals disk` → Indicator bar disk terhadap limit storage container 25 GB.
- `status-vitals uptime` → Durasi uptime riil container dari `/proc/uptime`.

### `~/.zshrc-omp-addon` + `~/.config/omp/config.json`

Arsip legacy Oh My Posh. Tidak dipakai di server (op tidak terpasang).
---

## 4. Integrasi SSH → tmux

Dua mekanisme yang membuat sesi nyambung :

1. **Auto-attach saat SSH** (di `.zshrc`, paling atas):

```zsh
if [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
    exec tmux attach 2>/dev/null || exec tmux new-session -s resmote
fi
```

   Efek: login SSH langsung masuk (atau membuat) session tmux `resmote`, tanpa nested saat sudah di dalam tmux.

2. **Auto-restore saat server start** (tmux-continuum): `@continuum-restore on` — sesi/window/pane (dan pane contents) dipulihkan dari save terakhir (interval 15 menit) oleh tmux-resurrect.

---

## 5. Setup server baru (`setup.sh`)

```bash
bash setup.sh            # atau chmod +x && ./setup.sh
```

Yang dilakukan:

1. **Deteksi distro** (apk / apt / dnf) → install paket inti: `zsh tmux git fzf` (pakai sudo bila perlu).
2. **Deploy dotfiles** ke `$HOME`; file yang sudah ada di-backup dulu ke `~/.backup-serenv-<timestamp>/`.
3. **Clone TPM** + jalankan `install_plugins.sh` → semua plugin tmux (sensible, resurrect, continuum, yank, catppuccin, which-key) langsung terpasang. Catatan: script ini menyalakan tmux server (detached) di socket; wajar.
4. **Output catatan akhir** langkah manual yang tersisa.

Flag: `--skip-packages` (tanpa install paket), `--skip-tpm` (tanpa clone/install plugin).

**Peringatan:** setup.sh menulis ke `$HOME` — jalankan di server baru, bukan di server yang sedang dipakai tanpa persiapan.

### Langkah manual setelah setup (opsional vs wajib)

| Tool | Perintah | Status |
|---|---|---|
| `zsh-vcs` (Alpine) | `sudo apk add zsh-vcs` | **WAJIB di Alpine** — tanpa ini `vcs_info` error tiap prompt (Known Issues #2) |
| bat, eza, ripgrep | `apk add bat eza ripgrep` / `apt install bat exa ripgrep` / `dnf install bat eza ripgrep` | opsional (dipakai alias) |
| powerlevel10k | `git clone --depth=1 https://github.com/romkatv/powerlevel10k ~/.powerlevel10k` | opsional (prompt) |
| zinit + plugin zsh | `git clone --depth=1 https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git` | opsional |
| OSC52 sisi LOKAL | `set -g set-clipboard on` di `~/.tmux.conf` mesin lokal + `tmux kill-server` | **WAJIB bila tmux di lokal** (Known Issues #3) |
| OMP (Oh My Posh) | `shsetupdoc/scripts/run-all.sh` (reference) | tidak aktif di server |

---

## 6. Known Issues & Fix (hasil temuan langsung)

1. **fzf `--zsh` error di shell non-TTY**: `(eval):1: can't change option: zle`. Sebab: fzf me-restore opsi shell termasuk `zle`, gagal saat zle tak aktif. Fix (sudah di `.zshrc`): guard `source <(fzf --zsh)` dengan `[[ -t 0 ]] && [[ -o interactive ]]`.

2. **`vcs_info: function definition file not found` (Alpine)**: paket `zsh` Alpine tidak menyertakan modul VCS_Info. Fix: `sudo apk add zsh-vcs` (menyediakan `/usr/share/zsh/5.9/functions/VCS_Info/`).

3. **Autocopy clipboard di headless**: `xclip` dipilih tmux-yank karena ada di PATH, tapi gagal (`Can't open display`) karena tidak ada DISPLAY. Fix: jalur **OSC52** — `set-clipboard on` di server + `@override_copy_command 'cat'` (tmux yang kirim OSC52, bukan xclip) + `set-clipboard on` di **setiap layer tmux** (termasuk tmux lokal di mesin kamu; layer luar default `external` justru menelan OSC52). Terminal klien (Alacritty ≥ 0.13) perlu `[terminal] osc52 = "OnlyCopy"` (default).

4. **Literal `@catppuccin_session_text` di header**: terjadi saat `status-left/right` kehilangan `#{E:...}`. Nilai `@catppuccin_status_session` berisi format bertingkat (`#{E:@catppuccin_session_text}`); tanpa `E:` di referensi luar format itu tidak di-expand dan tampil mentah. Fix: pastikan status bar memakai `#{E:@catppuccin_status_...}`, jangan pernah menghapus `E:`.

5. **Clone catppuccin salah nama**: harus di `~/.tmux/plugins/catppuccin`. TPM memakai fallback URL `https://git::@github.com/<plugin>` saat clone gagal — ini sumber remote aneh `git::@`. Pastikan instalasi lewat TPM (`prefix + I`) atau setup.sh, bukan clone manual ke folder lain.

---

## 7. Provenance (snapshot dotfiles)

| File repo | Sumber live | Diambil |
|---|---|---|
| `dotfiles/tmux.conf` | `~/.tmux.conf` | 2026-09-24 |
| `dotfiles/zshrc` | `~/.zshrc` | 2026-09-24 |
| `dotfiles/zshenv` | `~/.zshenv` | 2026-09-22 |
| `dotfiles/p10k.zsh` | `~/.p10k.zsh` | 2026-09-24 |
| `dotfiles/local/bin/status-vitals` | `~/.local/bin/status-vitals` | 2026-09-24 |
| `dotfiles/zshrc-omp-addon` | `~/.zshrc-omp-addon` | 2026-09-22 |
| `dotfiles/config/omp/config.json` | `~/.config/omp/config.json` | 2026-09-22 |
Snapshot adalah salinan; config live di `~` tetap sumber yang dipakai. Kalau config live berubah dan ingin diarsipkan, perbarui snapshot.