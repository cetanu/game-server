#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALHEIM_DIR="${ROOT_DIR}/servers/valheim"
ENV_FILE="${ROOT_DIR}/config/valheim.env"

if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
fi

SERVER_NAME="${SERVER_NAME:-My Valheim Server}"
SERVER_PORT="${SERVER_PORT:-2456}"
SERVER_WORLD="${SERVER_WORLD:-Dedicated}"
SERVER_PASS="${SERVER_PASS:-Secret123}"
SERVER_PUBLIC="${SERVER_PUBLIC:-1}"

export templdpath="${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="${VALHEIM_DIR}/linux64:${LD_LIBRARY_PATH:-}"
export SteamAppId="896660"

cd "${VALHEIM_DIR}"

SAVEDIR_ARG=()
if [[ -n "${SERVER_SAVEDIR:-}" ]]; then
    SAVEDIR_ARG=("-savedir" "${SERVER_SAVEDIR}")
fi

exec ./valheim_server.x86_64 \
    -name "${SERVER_NAME}" \
    -port "${SERVER_PORT}" \
    -world "${SERVER_WORLD}" \
    -password "${SERVER_PASS}" \
    -public "${SERVER_PUBLIC}" \
    "${SAVEDIR_ARG[@]}"

