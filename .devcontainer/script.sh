#!/usr/bin/env bash
# ── postStart Workspace Setup Script ────────────────────────────────────────
# Executes during VS Code's postStart phase.
# Configures NVM, Git identity, Claude Code state persistence, graphify
# integration, repository skills, and the patchright browser runtime.
# -----------------------------------------------------------------------------
set -e

# ── 1. Load NVM Environment ──────────────────────────────────────────────────
# Ensures Node.js is available in this shell session.
export NVM_DIR="/root/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
fi

# ── 2. Configure Git Directory Safety & Identity ─────────────────────────────
echo "🔧 Configuring Git user identity..."
git config --global --add safe.directory /workspace

if [ -n "$GITHUB_USER" ]; then
    git config --global --replace-all user.name "$GITHUB_USER"
fi
if [ -n "$GITHUB_EMAIL" ]; then
    git config --global --replace-all user.email "$GITHUB_EMAIL"
fi


# ── 3. Claude Code Persistence Setup ─────────────────────────────────────────
# Symlinks Claude CLI state to persistent host mount (/root/config_backup)
# so state survives container rebuilds.
echo "🔧 Setting up Claude Code state persistence..."
LOCAL_BACKUP="/root/config_backup"
CLAUDE_DIR="/root/.claude"
CLAUDE_CONFIG="/root/.claude.json"

mkdir -p "$LOCAL_BACKUP/.claude"

# Preserve existing configuration directory if present
if [ -d "$CLAUDE_DIR" ] && [ ! -L "$CLAUDE_DIR" ]; then
    cp -r "$CLAUDE_DIR/." "$LOCAL_BACKUP/.claude/"
    rm -rf "$CLAUDE_DIR"
fi
ln -sfn "$LOCAL_BACKUP/.claude" "$CLAUDE_DIR"

# Initialize and link configuration JSON
if [ ! -f "$LOCAL_BACKUP/.claude.json" ]; then
    echo "{}" > "$LOCAL_BACKUP/.claude.json"
fi
if [ -f "$CLAUDE_CONFIG" ] && [ ! -L "$CLAUDE_CONFIG" ]; then
    rm -f "$CLAUDE_CONFIG"
fi
ln -sfn "$LOCAL_BACKUP/.claude.json" "$CLAUDE_CONFIG"
echo "✅ Claude Code state persistence active."


# ── 4. Graphify Knowledge Graph Integration ──────────────────────────────────
echo "🔧 Registering graphify integration with Claude..."
graphify claude install || true

# ── 5. Install Repository Skills for Claude Code ─────────────────────────────
# Skills versioned under .devcontainer/skills/ are symlinked into Claude's
# personal skills directory so their /<skill> commands resolve on a fresh
# container. Symlinks (not copies) keep the repo copy canonical: edits take
# effect without re-running this script, and skills stay reviewable in git.
# Idempotent — `ln -sfn` overwrites an existing link.
if [ -d "/workspace/.devcontainer/skills" ]; then
    echo "🔧 Installing repository skills for Claude Code..."
    mkdir -p "$CLAUDE_DIR/skills"
    for skill_dir in /workspace/.devcontainer/skills/*/; do
        [ -f "${skill_dir}SKILL.md" ] || continue
        skill_name="$(basename "$skill_dir")"
        ln -sfn "${skill_dir%/}" "$CLAUDE_DIR/skills/$skill_name"
        echo "   ✅ $skill_name"
    done
fi


# ── 6. E2E Browser Runtime (patchright / Playwright Chromium) ────────────────
# The e2e suite (`pytest -m e2e`) drives a real patched Chromium. The browsers
# are downloaded into $PLAYWRIGHT_BROWSERS_PATH (/opt/pw-browsers), which lives
# in the container's writable layer — so a recreated container loses them and
# every e2e test errors with "Executable doesn't exist at .../chrome-linux64/
# chrome". Provision them here so the suite is runnable straight after postStart.
# Idempotent (skipped when the build is already present) and non-fatal: a failed
# download must not abort the rest of this script.
if command -v patchright >/dev/null 2>&1; then
    BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/root/.cache/ms-playwright}"
    if ls "$BROWSERS_PATH"/chromium-*/chrome-linux64/chrome >/dev/null 2>&1; then
        echo "✅ patchright Chromium already installed."
    else
        echo "🔧 Installing patchright Chromium for the e2e suite..."
        patchright install chromium \
            || echo "⚠️  patchright install failed. Run 'patchright install chromium' before the e2e suite."
    fi
fi

# ── 7. Electron Desktop App ──────────────────────────────────────────────────
# The window renders on the Xvfb display started by start-vnc.sh, so it is
# visible over noVNC as soon as it launches. Set ENABLE_ELECTRON=false in
# .env.dev to boot the container without the app.
# Never install dependencies here: a container start must not depend on the
# network. A missing install is reported instead.
if [ "${ENABLE_ELECTRON:-true}" = "true" ]; then
    if [ ! -x "/workspace/apps/desktop/node_modules/electron/dist/electron" ]; then
        echo "⚠️  Electron is not installed. Run .devcontainer/electron.sh --install."
    elif pgrep -x electron >/dev/null 2>&1; then
        echo "✅ Electron already running."
    else
        echo "🔧 Starting Electron desktop app (visible over noVNC)..."
        nohup /workspace/.devcontainer/electron.sh > /tmp/electron-dev.log 2>&1 &
    fi
fi

echo "✅ Post-start workspace setup complete."
