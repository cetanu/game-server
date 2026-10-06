#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups/factorio"
SOURCE_DIR="${ROOT_DIR}/servers/factorio/saves"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

mkdir -p "${BACKUP_DIR}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
    echo "Warning: Factorio saves directory ${SOURCE_DIR} does not exist yet. Nothing to back up."
    exit 0
fi

ARCHIVE="${BACKUP_DIR}/factorio_backup_${TIMESTAMP}.tar.gz"
echo "Backing up Factorio saves to ${ARCHIVE}..."
tar -czf "${ARCHIVE}" -C "${SOURCE_DIR}" .

# Retain backups from last 7 days
find "${BACKUP_DIR}" -name "factorio_backup_*.tar.gz" -mtime +7 -delete

echo "Factorio backup complete: ${ARCHIVE}"
