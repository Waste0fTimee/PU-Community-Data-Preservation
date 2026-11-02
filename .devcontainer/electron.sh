#!/usr/bin/env bash
# ── Electron Dev Launcher ────────────────────────────────────────────────────
# Installs desktop dependencies on first run and starts the Electron app on the
# container's Xvfb display, so the window can be inspected through noVNC.
#
# Usage: .devcontainer/electron.sh [--install] [app arguments...]
#   --install   Reinstall apps/desktop dependencies before launching.
#
# VNC access: http://localhost:6081/vnc.html (ports are defined in start-vnc.sh).
# -----------------------------------------------------------------------------
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/apps/desktop"
ELECTRON_BIN="${APP_DIR}/node_modules/.bin/electron"

INSTALL=false
if [ "${1:-}" = "--install" ]; then
    INSTALL=true
    shift
fi

# The app renders on the virtual display, not on the host: start the stack when
# it is not already running.
export DISPLAY="${DISPLAY:-:3}"
if ! pgrep -f "Xvfb.*${DISPLAY}" >/dev/null 2>&1; then
    echo "--> No X server on ${DISPLAY}; starting Xvfb + VNC..."
    if [ -x /usr/local/bin/start-vnc.sh ]; then
        /usr/local/bin/start-vnc.sh
    elif [ -x "${ROOT_DIR}/.devcontainer/start-vnc.sh" ]; then
        "${ROOT_DIR}/.devcontainer/start-vnc.sh"
    else
        echo "❌ ERROR: start-vnc.sh not found; cannot start the display."
        exit 1
    fi
fi

# Electron 45 declares Node >=22.12.0. Its bundled runtime still starts on the
# image's Node 20, so this is a warning rather than a hard stop.
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "${NODE_MAJOR}" -lt 22 ]; then
    echo "⚠️  Notice: Node ${NODE_MAJOR} detected; Electron 45 declares Node >=22.12.0."
fi

if [ "${INSTALL}" = true ] || [ ! -d "${APP_DIR}/node_modules/electron" ]; then
    echo "--> Installing desktop dependencies..."
    npm --prefix "${APP_DIR}" install --no-audit --no-fund
fi

# Electron downloads its binary lazily on first use; force the download now so
# the launch below does not stall behind it.
if [ ! -x "${APP_DIR}/node_modules/electron/dist/electron" ]; then
    echo "--> Downloading Electron binary..."
    node "${APP_DIR}/node_modules/electron/install.js"
fi

# Chromium's sandbox cannot run as root, which is the container's user. This is
# acceptable for a dev container only; never ship --no-sandbox.
ELECTRON_FLAGS=(--disable-gpu --disable-dev-shm-usage)
if [ "$(id -u)" -eq 0 ]; then
    ELECTRON_FLAGS+=(--no-sandbox)
fi

echo "--> Starting Electron on display ${DISPLAY}..."
exec "${ELECTRON_BIN}" "${ELECTRON_FLAGS[@]}" "${APP_DIR}" "$@"
