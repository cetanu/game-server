#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo/root to configure system users and /etc/systemd/system units."
    echo "Usage: sudo bash scripts/setup-systemd-system.sh"
    exit 1
fi

echo "==> Creating dedicated system users (if not present)..."
id -u factorio &>/dev/null || useradd -r -s /usr/bin/nologin factorio
id -u valheim &>/dev/null || useradd -r -s /usr/bin/nologin valheim

echo "==> Setting up dedicated Valheim save directory..."
mkdir -p /var/opt/valheim-saves
chown -R valheim:valheim /var/opt/valheim-saves
chmod 750 /var/opt/valheim-saves

# Update config/valheim.env with SERVER_SAVEDIR if not set
if ! grep -q "SERVER_SAVEDIR" "${ROOT_DIR}/config/valheim.env"; then
    echo 'SERVER_SAVEDIR="/var/opt/valheim-saves"' >> "${ROOT_DIR}/config/valheim.env"
fi

echo "==> Setting folder permissions for servers..."
# Ensure factorio and valheim users can read/write their server directories
chown -R factorio:factorio "${ROOT_DIR}/servers/factorio"
chown -R valheim:valheim "${ROOT_DIR}/servers/valheim"

# Allow traverse permissions so isolated users can access the game server repo
chmod a+rx "${ROOT_DIR}"
chmod a+rx "${ROOT_DIR}/servers"
chmod a+rx "${ROOT_DIR}/scripts"

echo "==> Installing systemd service units to /etc/systemd/system/..."
cp "${ROOT_DIR}/systemd/system/factorio.service" /etc/systemd/system/factorio.service
cp "${ROOT_DIR}/systemd/system/valheim.service" /etc/systemd/system/valheim.service

echo "==> Reloading systemd daemon..."
systemctl daemon-reload

echo "=========================================================="
echo "Setup complete! You can now manage services with sudo systemctl:"
echo "  sudo systemctl enable --now factorio.service"
echo "  sudo systemctl enable --now valheim.service"
echo "  sudo systemctl status factorio.service"
echo "  sudo systemctl status valheim.service"
echo "=========================================================="
