#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALHEIM_DIR="${ROOT_DIR}/servers/valheim"
STEAMCMD="${ROOT_DIR}/bin/steamcmd"

if [[ ! -x "${STEAMCMD}" ]]; then
    if command -v steamcmd >/dev/null 2>&1; then
        STEAMCMD="$(command -v steamcmd)"
    else
        echo "steamcmd not found, running install-steamcmd.sh..."
        bash "${ROOT_DIR}/scripts/install-steamcmd.sh"
    fi
fi

mkdir -p "${VALHEIM_DIR}"

echo "Installing/Updating Valheim Dedicated Server (AppID 896660)..."
"${STEAMCMD}" +force_install_dir "${VALHEIM_DIR}" +login anonymous +app_info_update 1 +app_update 896660 validate +quit


echo "Valheim server installed/updated successfully at ${VALHEIM_DIR}."
