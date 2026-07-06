#!/bin/bash
#
# Deploy script: pull latest source, rebuild, reinstall, swap in the renamed
# binary, and gracefully restart the running server.
#
# Usage:
#   ./deploy.sh
#
# Mirrors the manual steps:
#   cd cmangos/mangos-tbc && git pull
#   cd ../build && make install
#   cd ../run/bin && mv mangosd cangosd
#   cd ../.. && ./wowadmin.sh wrestart

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

MANGOS_TBC_DIR="$THIS_DIR"
CMANGOS_DIR="$(cd "$MANGOS_TBC_DIR/.." && pwd -P)"
BUILD_DIR="$CMANGOS_DIR/build"
BIN_DIR="$CMANGOS_DIR/run/bin"
WOWADMIN="$CMANGOS_DIR/wowadmin.sh"

WSRV_BIN_ORG="mangosd"
WSRV_BIN="cangosd"

MAKE_JOBS="${MAKE_JOBS:-$(nproc)}"

echo ">>> Pulling latest source in $MANGOS_TBC_DIR ..."
cd "$MANGOS_TBC_DIR"
git pull

echo ">>> Building and installing (make install -j$MAKE_JOBS) in $BUILD_DIR ..."
cd "$BUILD_DIR"
make install -j"$MAKE_JOBS"

echo ">>> Swapping in freshly built binary as $WSRV_BIN ..."
cd "$BIN_DIR"
if [[ ! -f "$WSRV_BIN_ORG" ]]; then
    echo ">>> ERROR: $BIN_DIR/$WSRV_BIN_ORG not found after install, aborting before touching the running server." >&2
    exit 1
fi
mv -f "$WSRV_BIN_ORG" "$WSRV_BIN"

echo ">>> Restarting server via wowadmin.sh ..."
cd "$CMANGOS_DIR"
if [[ ! -x "$WOWADMIN" ]]; then
    echo ">>> ERROR: $WOWADMIN not found or not executable, binary was updated but server was NOT restarted." >&2
    exit 1
fi
./wowadmin.sh wrestart

echo ">>> Deploy done."
