#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

mkdir -p "${SYSTEMD_USER_DIR}"

echo "Symlinking systemd service & timer units into ${SYSTEMD_USER_DIR}..."
ln -sf "${ROOT_DIR}/systemd/factorio.service" "${SYSTEMD_USER_DIR}/factorio.service"
ln -sf "${ROOT_DIR}/systemd/valheim.service" "${SYSTEMD_USER_DIR}/valheim.service"
ln -sf "${ROOT_DIR}/systemd/game-backup.service" "${SYSTEMD_USER_DIR}/game-backup.service"
ln -sf "${ROOT_DIR}/systemd/game-backup.timer" "${SYSTEMD_USER_DIR}/game-backup.timer"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

echo "Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "Enabling game-backup.timer..."
systemctl --user enable --now game-backup.timer

echo "Systemd installation complete."
echo "To enable and start Factorio:"
echo "  systemctl --user enable --now factorio.service"
echo "To enable and start Valheim:"
echo "  systemctl --user enable --now valheim.service"
