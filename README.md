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

Set `SERVER_CROSSPLAY=1` in `config/valheim.env` to use the crossplay relay, including for Steam clients. After changing it, restart the Valheim service. Relay connections use the join code from the logs or the public address; LAN/loopback addresses are unsupported. Set it to `0` for the Steam backend.

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

## Valheim administration

```sh
mise run valheim:join-code   # Current service run only; codes can change after restart
mise run valheim:seed        # Read-only; supports legacy .fwl and completed .fwl2 saves
mise run valheim:status
mise run valheim:logs
mise run valheim:start
mise run valheim:stop        # Clean shutdown saves the world
mise run valheim:restart
mise run backup:valheim
```

To grant admin access, join the server and press **F2** to find your exact **Platform User ID**. With crossplay it may be `PlayFab_...`; use the displayed ID rather than assuming it is your Steam ID. Then:

```sh
mise run valheim:admin:add Steam_76561198000000000
mise run valheim:admins
mise run valheim:admin:remove Steam_76561198000000000
```

The commands update `adminlist.txt` in the same save directory as the running server. Reconnect after changes; restart Valheim if permissions are not picked up. They do not edit the player allowlist.

For in-game administration, put `-console` in your Steam Valheim launch options, restart the client, join, and press **F5**. Use `kick PLAYERNAME`, `ban PLAYERNAME`, `unban PLAYERNAME`, and `banned`. Type `help` for the commands available in your game version. Administrator status does not enable every single-player cheat on a dedicated server.

`bannedlist.txt` and `permittedlist.txt` also live in the configured save directory. Each uses one exact Platform User ID per line. A nonempty permitted list excludes everyone not listed, so add an allowlist only when you intend to restrict server access. See the [official admin instructions](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/).

The world seed is read from the selected world's metadata, not its name. Changing `SERVER_WORLD` selects a different world; it does not set the seed. To use a chosen seed, create that world in the client and move its complete save to the stopped server, backing up the existing world first.
