#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${ROOT_DIR}/bin"
STEAMCMD_DIR="${ROOT_DIR}/tools/steamcmd"

mkdir -p "${BIN_DIR}" "${STEAMCMD_DIR}"

SYSTEM_STEAMCMD="$(command -v steamcmd || true)"
if [[ -n "${SYSTEM_STEAMCMD}" && "${SYSTEM_STEAMCMD}" != "${BIN_DIR}/steamcmd" ]]; then
    echo "Found system steamcmd: ${SYSTEM_STEAMCMD}"
    ln -sf "${SYSTEM_STEAMCMD}" "${BIN_DIR}/steamcmd"
    exit 0
fi


if [[ -f "${STEAMCMD_DIR}/steamcmd.sh" ]]; then
    echo "steamcmd already installed in ${STEAMCMD_DIR}"
else
    echo "Downloading steamcmd portable archive..."
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -zxvf - -C "${STEAMCMD_DIR}"
fi

cat << 'EOF' > "${BIN_DIR}/steamcmd"
#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "${ROOT_DIR}/tools/steamcmd/steamcmd.sh" "$@"
EOF
chmod +x "${BIN_DIR}/steamcmd"
echo "steamcmd installed successfully."
