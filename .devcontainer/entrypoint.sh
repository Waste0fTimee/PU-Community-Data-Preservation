#!/usr/bin/env bash
# ── Container Orchestration Entrypoint ───────────────────────────────────────
# Runs when Docker launches the container.
# Starts the VNC desktop stack in real time, displaying all status messages and
# errors on screen. The tun2socks block below is currently disabled.
# -----------------------------------------------------------------------------
set -e

echo "=========================================================================="
echo "🚀 INITIALIZING CONTAINER BACKGROUND DAEMONS"
echo "=========================================================================="

# ── 1. Launch X11 & VNC Graphical Display Stack ──────────────────────────────
if [ -x "/usr/local/bin/start-vnc.sh" ]; then
    echo "--> Executing /usr/local/bin/start-vnc.sh..."
    /usr/local/bin/start-vnc.sh
else
    echo "❌ ERROR: /usr/local/bin/start-vnc.sh not found or missing executable permissions!"
    exit 1
fi

echo ""

# ── 2. Configure Network Proxy Tunneling (tun2socks) ─────────────────────────
# TUN_SCRIPT="/workspace/.devcontainer/tun2socks.sh"
# if [ ! -f "$TUN_SCRIPT" ]; then
#     TUN_SCRIPT=".devcontainer/tun2socks.sh"
# fi

# if [ -f "$TUN_SCRIPT" ]; then
#     echo "--> Executing $TUN_SCRIPT..."
#     bash "$TUN_SCRIPT"
# else
#     echo "⚠️ Notice: tun2socks.sh script not found at expected path. Skipping network tunnel."
# fi

echo ""
echo "=========================================================================="
echo "✅ CONTAINER DAEMONS INITIALIZED. Handing execution to CMD: $@"
echo "=========================================================================="

# ── 3. Pass Control to Container Command (sleep infinity) ────────────────────
exec "$@"