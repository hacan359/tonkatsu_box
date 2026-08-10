#!/bin/bash
set -e

# Files in the bind-mounted data dir belong to the host user, not root —
# otherwise the owner cannot edit keys.json or delete a backup copy.
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$TONKATSU_DATA_DIR"
  # -R only on a mismatch: the covers cache grows large and a full pass on
  # every boot would slow the start for nothing.
  if [ "$(stat -c '%u:%g' "$TONKATSU_DATA_DIR")" != "$PUID:$PGID" ]; then
    chown -R "$PUID:$PGID" "$TONKATSU_DATA_DIR"
  fi
  exec setpriv --reuid="$PUID" --regid="$PGID" --clear-groups \
    /opt/tonkatsu/bin/server "$@"
fi

exec /opt/tonkatsu/bin/server "$@"
