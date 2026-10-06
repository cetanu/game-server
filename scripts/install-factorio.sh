#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FACTORIO_DIR="${ROOT_DIR}/servers/factorio"

mkdir -p "${FACTORIO_DIR}" "${FACTORIO_DIR}/saves" "${FACTORIO_DIR}/config"

echo "Downloading Factorio headless Linux server (stable)..."
TMP_TAR="$(mktemp /tmp/factorio_headless_XXXXXX.tar.xz)"
curl -L -o "${TMP_TAR}" "https://factorio.com/get-download/stable/headless/linux64"

echo "Extracting Factorio..."
tar -xJf "${TMP_TAR}" --strip-components=1 -C "${FACTORIO_DIR}"
rm -f "${TMP_TAR}"

# Create default server-settings.json if none exists
if [[ ! -f "${FACTORIO_DIR}/config/server-settings.json" ]]; then
    if [[ -f "${FACTORIO_DIR}/data/server-settings.example.json" ]]; then
        cp "${FACTORIO_DIR}/data/server-settings.example.json" "${FACTORIO_DIR}/config/server-settings.json"
        echo "Created initial config at ${FACTORIO_DIR}/config/server-settings.json"
    fi
fi

# Create default save if none exists
if [[ ! -f "${FACTORIO_DIR}/saves/world.zip" ]]; then
    echo "Creating initial world save 'world.zip'..."
    "${FACTORIO_DIR}/bin/x64/factorio" --create "${FACTORIO_DIR}/saves/world.zip"
fi

echo "Factorio server installed successfully at ${FACTORIO_DIR}."
