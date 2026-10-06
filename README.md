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

## Namecheap Dynamic DNS

The updater sets `valheim.vsyrakis.dev` and `factorio.vsyrakis.dev` to the same detected public IPv4. It needs Python 3 (standard library only). HTTPS requests have a 20-second timeout; provider errors cause a nonzero exit even if HTTP succeeds. Failed updates retry on the next timer run.

In Namecheap, manage `vsyrakis.dev` → **Advanced DNS**:

1. Enable **Dynamic DNS** and copy its **Dynamic DNS Password** (not your account password or general API key).
2. Create **A+Dynamic DNS** records for hosts `valheim` and `factorio`.
3. Put the password in `ddns_password` in `config/namecheap-ddns.json`. This ignored file is created locally with owner-only permissions. On a fresh clone, create it with `install -m 600 config/namecheap-ddns.json.example config/namecheap-ddns.json`.

Namecheap DDNS requires BasicDNS, PremiumDNS, or FreeDNS nameservers. See the official [setup instructions](https://www.namecheap.com/support/knowledgebase/article.aspx/36/11/how-do-i-start-using-dynamic-dns/) and [update protocol](https://www.namecheap.com/support/knowledgebase/article.aspx/29/11/how-to-dynamically-update-the-hosts-ip-with-an-https-request/).

```sh
mise run ddns:check    # Validate local credentials; no network requests
mise run ddns:update   # Update both hostnames now
mise run ddns:enable   # Install user units, update now, then every five minutes
mise run ddns:status
mise run ddns:disable
```

The credential can also come from `NAMECHEAP_DDNS_PASSWORD`; the unattended timer uses the JSON file. Keep the user manager running after logout with `loginctl enable-linger "$USER"`.

For direct or cron use (no mise activation needed):

```sh
python3 /absolute/path/to/game-server/scripts/namecheap_ddns.py
# Optional explicit public IPv4:
python3 scripts/namecheap_ddns.py --ip YOUR_PUBLIC_IPV4
```

Example crontab entry; replace the checkout path and use either cron or the timer:

```cron
*/5 * * * * /usr/bin/python3 /absolute/path/to/game-server/scripts/namecheap_ddns.py
```

Public IPv4 detection uses `https://api.ipify.org`. DNS updates do not configure router forwarding: forward UDP 34197 for Factorio and the Valheim ports to this machine. Connect using `factorio.vsyrakis.dev:34197` or `valheim.vsyrakis.dev:2456` once DNS propagates.
