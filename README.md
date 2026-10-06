# Dedicated Game Servers Manager

This repository uses [`mise`](https://mise.jdx.dev/) to bootstrap, install, and manage headless game servers (**Factorio** and **Valheim**), with process lifecycle management and automated world backups driven by **systemd user units**.

## Prerequisites

- `mise` installed (`curl https://mise.run | sh` or already in `~/.local/bin/mise`)
- SteamCMD dependencies (installed automatically or via system package `steamcmd`)
- To allow user systemd services to persist without an active login session:
  ```bash
  loginctl enable-linger $USER
  ```

---

## Directory Structure

```
├── mise.toml                   # Mise task definitions
├── config/
│   └── valheim.env             # Valheim server name, password, port, etc.
├── scripts/
│   ├── install-steamcmd.sh     # Portable SteamCMD downloader
│   ├── install-valheim.sh      # SteamCMD runner to download Valheim AppID 896660
│   ├── install-factorio.sh     # Downloads headless Factorio tarball & creates initial save
│   ├── start-valheim.sh        # Startup script for Valheim
│   ├── backup-valheim.sh       # Backs up ~/.config/unity3d/IronGate/Valheim/worlds_local
│   ├── backup-factorio.sh      # Backs up servers/factorio/saves
│   └── install-systemd.sh      # Symlinks services into ~/.config/systemd/user and starts timer
├── systemd/
│   ├── factorio.service        # Systemd unit for Factorio
│   ├── valheim.service         # Systemd unit for Valheim
│   ├── game-backup.service     # Systemd oneshot unit executing `mise run backup:all`
│   └── game-backup.timer       # Systemd hourly timer for backups
└── backups/                    # Auto-generated backup tarballs (.tar.gz)
```

---

## Quickstart

### 1. Install & Bootstrap Servers via `mise`

```bash
# Install both Factorio and Valheim
mise run install:all

# Or install individually:
mise run install:factorio
mise run install:valheim
```

### 2. Configure Your Game Servers

- **Valheim:** Edit [`config/valheim.env`](file:///home/vsyrakis/Documents/game-server/config/valheim.env) to set `SERVER_NAME`, `SERVER_PASS`, and `SERVER_WORLD`.
- **Factorio:** Server settings are located in [`servers/factorio/config/server-settings.json`](file:///home/vsyrakis/Documents/game-server/servers/factorio/config/server-settings.json).

### 3. Install Systemd Services

#### Option A: Hardened System Services with Dedicated Users (Recommended)
This runs the servers under isolated non-login users (`factorio` and `valheim`) with kernel sandboxing (`ProtectHome=read-only`, `NoNewPrivileges=true`, `PrivateTmp=true`):

```bash
mise run systemd:setup-system
```

Start and enable at boot:
```bash
sudo systemctl enable --now factorio.service
sudo systemctl enable --now valheim.service

# Check status:
sudo systemctl status factorio.service
sudo systemctl status valheim.service
```

#### Option B: User Session Units
If you prefer running as your personal user session:
```bash
mise run systemd:install-user
systemctl --user enable --now factorio.service
systemctl --user enable --now valheim.service
```

systemctl --user status valheim.service
systemctl --user list-timers
```

---

## Backups

Backups run automatically every hour via `game-backup.timer`, retaining 7 days of archives in `backups/factorio/` and `backups/valheim/`.

To trigger backups manually on-demand:
```bash
mise run backup:all
# or
mise run backup:factorio
mise run backup:valheim
```

---

## System Tuning & Ports

Refer to [TUNING.md](file:///home/vsyrakis/Documents/game-server/TUNING.md) for CPU governor scaling configuration and UDP firewall port forwarding instructions.
