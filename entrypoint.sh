#!/usr/bin/env bash
set -euo pipefail

HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
USERNAME="vibe-user"
HOMEDIR="/home/${USERNAME}"

if ! getent group "$HOST_GID" >/dev/null 2>&1; then
    groupadd -g "$HOST_GID" vibe
fi

if ! getent passwd "$HOST_UID" >/dev/null 2>&1; then
    useradd -u "$HOST_UID" -g "$HOST_GID" -d "$HOMEDIR" -s /bin/bash -M "$USERNAME"
    mkdir -p "$HOMEDIR"
    cp -rn /etc/skel/. "$HOMEDIR/" 2>/dev/null || true
    chown "$HOST_UID:$HOST_GID" "$HOMEDIR"
fi

HOMEDIR=$(getent passwd "$HOST_UID" | cut -d: -f6)

chown "$HOST_UID:$HOST_GID" /workspace 2>/dev/null || true
if [ -d "${HOMEDIR}/.vibe" ]; then
    chown -R "$HOST_UID:$HOST_GID" "${HOMEDIR}/.vibe" || \
        echo "warning: failed to chown ${HOMEDIR}/.vibe to ${HOST_UID}:${HOST_GID}" >&2
fi

export HOME="$HOMEDIR"
export VIBE_HOME="${HOMEDIR}/.vibe"
export PATH="/usr/local/bin:${PATH}"

exec gosu "$HOST_UID:$HOST_GID" "$@"
