# Dedicated game servers

Mise manages installation, configuration, startup, and backups for Factorio and Valheim. Commands live in `mise.toml` and run from the checkout root.

## Quickstart

Install [mise](https://mise.jdx.dev/), plus `curl`, `tar`, and the Linux 32-bit libc libraries required by SteamCMD. Copy the configuration before running tasks:

```sh
cp config/valheim.env.example config/valheim.env
mise trust
mise run install:all
```

Edit `config/valheim.env` to choose the Valheim name, world, and password (at least five characters; cannot appear in the server name). Mise loads this as dotenv data. Valheim saves default to `servers/valheim/saves`; set `SERVER_SAVEDIR` to reuse existing worlds. Relative save paths resolve against the checkout root. If migrating from the old system services, copy any worlds from `/var/opt/valheim-saves` before starting the same world in the new directory.

Edit `servers/factorio/config/server-settings.json` for Factorio. Public listing requires Factorio account credentials; for a private server, set `visibility.public` to `false`. Installation preserves existing settings and `saves/world.zip`.

```sh
mise run start:factorio
mise run start:valheim
# Or run both together:
mise run start
```

These run in the foreground. Press Ctrl-C to stop cleanly. Startup does not download updates; stop the server before running `install:factorio` or `install:valheim`. Server directories and saves must be writable by your account.

## Optional background services

The user services call the same mise tasks. Service tasks preserve existing session bus settings and otherwise connect to `/run/user/<your UID>/bus`, so they also work in shells without the session variables. Their installation renders the current checkout path and mise executable into systemd units:

```sh
mise run systemd:install-user
systemctl --user enable --now factorio.service valheim.service
mise run service:status
mise run service:stop
mise run service:start
```

To keep user services running after logout, use `loginctl enable-linger "$USER"`. If moving the checkout or mise executable, rerun `systemd:install-user`. This task also enables the hourly backup timer.

The previous root-level services used dedicated users that could not traverse the home directory. Before switching, disable those old units to prevent duplicate servers at boot:

```sh
sudo systemctl disable --now factorio.service valheim.service
```

## Backups

```sh
mise run backup:all
mise run backup:factorio
mise run backup:valheim
```

Archives go into `backups/<game>/`, retaining seven days. Valheim startup and backup use the same save directory. Live archives may capture files while they change; stop the servers first when you need a consistent snapshot.

Downloaded binaries, settings, worlds, and backups are ignored by Git. See [TUNING.md](TUNING.md) for ports and optional host tuning.
