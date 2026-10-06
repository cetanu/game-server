#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups/valheim"
ENV_FILE="${ROOT_DIR}/config/valheim.env"
if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
fi

SOURCE_DIR="${SERVER_SAVEDIR:-${HOME}/.config/unity3d/IronGate/Valheim/worlds_local}"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

mkdir -p "${BACKUP_DIR}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
    # In case savedir points to parent containing worlds_local
    if [[ -d "${SOURCE_DIR}/worlds_local" ]]; then
        SOURCE_DIR="${SOURCE_DIR}/worlds_local"
    else
        echo "Warning: Valheim world save directory ${SOURCE_DIR} does not exist yet. Nothing to back up."
        exit 0
    fi
fi


ARCHIVE="${BACKUP_DIR}/valheim_backup_${TIMESTAMP}.tar.gz"
echo "Backing up Valheim saves to ${ARCHIVE}..."
tar -czf "${ARCHIVE}" -C "${SOURCE_DIR}" .

# Retain backups from last 7 days (or keep 14 most recent)
find "${BACKUP_DIR}" -name "valheim_backup_*.tar.gz" -mtime +7 -delete

echo "Valheim backup complete: ${ARCHIVE}"
