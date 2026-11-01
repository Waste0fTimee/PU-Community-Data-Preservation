#!/usr/bin/env bash
# ── Desktop Display & VNC Startup Script ─────────────────────────────────────
# Starts the X11 virtual display (Xvfb), x11vnc server, and noVNC web proxy.
# All process output streams directly to stdout/stderr in real-time so any
# failure or error is immediately visible on screen.
# -----------------------------------------------------------------------------
set -e

DISPLAY_NUM="${DISPLAY:-:3}"
VNC_PORT="5901"
NOVNC_PORT="6081"

echo "=========================================================================="
echo "🖥️  STARTING DESKTOP ENVIRONMENT & VNC SERVICES"
echo "=========================================================================="

# ── 1. Start Xvfb (Virtual Framebuffer Display) ──────────────────────────────
echo "--> Starting Xvfb on display ${DISPLAY_NUM} (1920x1080x24)..."

# Terminate existing Xvfb process on the configured display if present
if pgrep -f "Xvfb.*${DISPLAY_NUM}" >/dev/null 2>&1; then
    echo "  Notice: Existing Xvfb instance detected. Terminating..."
    pkill -f "Xvfb.*${DISPLAY_NUM}" || true
    sleep 1
fi

# Launch Xvfb in the background while keeping stdout/stderr attached
Xvfb ${DISPLAY_NUM} -screen 0 1920x1080x24 -ac &
XVFB_PID=$!
sleep 1

# Verify Xvfb process execution
if pgrep -f "Xvfb.*${DISPLAY_NUM}" >/dev/null 2>&1; then
    echo "  ✅ Xvfb active on display ${DISPLAY_NUM} (PID ${XVFB_PID})"
else
    echo "  ❌ ERROR: Failed to start Xvfb on display ${DISPLAY_NUM}!"
    exit 1
fi

# ── 2. Start x11vnc (Expose X11 Display via VNC Protocol) ────────────────────
echo "--> Starting x11vnc server on port ${VNC_PORT}..."

# Terminate existing x11vnc instance if present
if pgrep -f "x11vnc.*${VNC_PORT}" >/dev/null 2>&1; then
    echo "  Notice: Existing x11vnc instance detected. Terminating..."
    pkill -f "x11vnc.*${VNC_PORT}" || true
    sleep 1
fi

# Launch x11vnc server sharing the configured display
x11vnc -display ${DISPLAY_NUM} -forever -shared -rfbport ${VNC_PORT} -nopw &
sleep 2

# Verify VNC port binding
VNC_STARTED=false
for i in 1 2 3; do
    if lsof -i:${VNC_PORT} >/dev/null 2>&1 || grep -q "00000000:170D" /proc/net/tcp 2>/dev/null; then
        VNC_STARTED=true
        break
    fi
    sleep 1
done

if [ "$VNC_STARTED" = true ]; then
    echo "  ✅ x11vnc active and listening on port ${VNC_PORT}"
else
    echo "  ❌ ERROR: x11vnc failed to bind to port ${VNC_PORT}!"
    exit 1
fi

# ── 3. Start noVNC (Browser-based Web VNC Proxy) ─────────────────────────────
echo "--> Starting noVNC proxy on port ${NOVNC_PORT}..."

# Terminate existing websockify/noVNC process on the noVNC port
if pgrep -f "websockify.*${NOVNC_PORT}" >/dev/null 2>&1; then
    echo "  Notice: Existing websockify instance detected. Terminating..."
    pkill -f "websockify.*${NOVNC_PORT}" || true
    sleep 1
fi

# Detect system noVNC launcher utility
NOVNC_LAUNCHER=""
if command -v /usr/share/novnc/utils/novnc_proxy &>/dev/null; then
    NOVNC_LAUNCHER="/usr/share/novnc/utils/novnc_proxy"
elif command -v /opt/noVNC/utils/novnc_proxy &>/dev/null; then
    NOVNC_LAUNCHER="/opt/noVNC/utils/novnc_proxy"
elif command -v websockify &>/dev/null; then
    NOVNC_LAUNCHER="websockify"
fi

if [ -z "$NOVNC_LAUNCHER" ]; then
    echo "  ❌ ERROR: No noVNC proxy or websockify binary found in system PATH!"
    exit 1
fi

# Launch noVNC proxy
if [ "$NOVNC_LAUNCHER" = "websockify" ]; then
    websockify --web /usr/share/novnc ${NOVNC_PORT} 0.0.0.0:${VNC_PORT} &
else
    "$NOVNC_LAUNCHER" --vnc 0.0.0.0:${VNC_PORT} --listen ${NOVNC_PORT} &
fi

sleep 2

# Verify noVNC port binding
NOVNC_STARTED=false
for i in 1 2 3; do
    if lsof -i:${NOVNC_PORT} >/dev/null 2>&1 || grep -q "00000000:17C1" /proc/net/tcp 2>/dev/null; then
        NOVNC_STARTED=true
        break
    fi
    sleep 1
done

if [ "$NOVNC_STARTED" = true ]; then
    echo "  ✅ noVNC active and listening on port ${NOVNC_PORT}"
else
    echo "  ❌ ERROR: noVNC failed to bind to port ${NOVNC_PORT}!"
    exit 1
fi

echo "=========================================================================="
echo "✅ VNC STACK OPERATIONAL"
echo "   - Virtual Display: ${DISPLAY_NUM}"
echo "   - VNC Native Port: ${VNC_PORT}"
echo "   - noVNC Web Port:  ${NOVNC_PORT}"
echo "=========================================================================="