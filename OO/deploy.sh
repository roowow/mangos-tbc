#!/bin/bash
#
# Deploy script: pull latest source, rebuild, reinstall, swap in the renamed
# binary, and gracefully restart the running server.
#
# All paths are hardcoded absolute paths (see CMANGOS_DIR below), so this can
# be invoked from any working directory, e.g.:
#   bash /home/rogical/cmangos/mangos-tbc/OO/deploy.sh
#   bash ~/cmangos/mangos-tbc/OO/deploy.sh
#
# Mirrors the manual steps:
#   cd cmangos/mangos-tbc && git pull
#   cd ../build && make install
#   cd ../run/bin && mv mangosd cangosd
#   cd ../.. && ./wowadmin.sh wrestart
#
# Uses a bare `git pull`, relying on each checkout's already-configured
# upstream tracking branch - so this works unmodified regardless of what the
# remote happens to be named on a given server (roowow, origin, etc.).

set -euo pipefail

# Hardcoded absolute paths so this script can be run from any working
# directory (bash /path/to/deploy.sh, a cron job, etc.) without relying on
# where the script file itself happens to live.
CMANGOS_DIR="/home/rogical/cmangos"
MANGOS_TBC_DIR="$CMANGOS_DIR/mangos-tbc"
BUILD_DIR="$CMANGOS_DIR/build"
BIN_DIR="$CMANGOS_DIR/run/bin"
LOG_DIR="$CMANGOS_DIR/run/logs"
WOWADMIN="$CMANGOS_DIR/wowadmin.sh"

WSRV_BIN_ORG="mangosd"
WSRV_BIN="mangosd"

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

echo ">>> Clearing old logs in $LOG_DIR ..."
rm -f "$LOG_DIR"/*.log

echo ">>> Restarting server via wowadmin.sh ..."
cd "$CMANGOS_DIR"
if [[ ! -x "$WOWADMIN" ]]; then
    echo ">>> ERROR: $WOWADMIN not found or not executable, binary was updated but server was NOT restarted." >&2
    exit 1
fi
./wowadmin.sh wrestart

echo ">>> Deploy done."
