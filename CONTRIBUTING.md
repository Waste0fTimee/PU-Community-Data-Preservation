# Contributing

PU-CDP is an independent community data-preservation project. It is not
affiliated with Nintendo, The Pokémon Company, Tencent, TiMi, or Revival Games.

Read [README.md](README.md) for the project's goals, data principles, and
privacy rules before you start.

## Ground rules

- **English only** in code, comments, UI copy, docs, and commits.
- **Nothing leaves a contributor's machine** without an explicit GUI action that
  shows the payload first. Details: README → Privacy and Security.
- **Never commit credentials** (`.devcontainer/.env.dev` is local-only), APKs,
  extracted game assets, or raw player data.
- **Contribution packages are JSON.** Clients must not generate SQL; the
  backend owns every database write.

## Where help is needed

- Data collection and validation.
- Android development and emulator setup.
- Unity research and game data analysis.
- Database schema and backend development.
- GUI and developer tooling.
- Documentation and tutorials.
- Competitive gameplay knowledge and data verification.

## Run the full environment (dev container)

This is the development setup, and it works on Windows and Linux. End-user
collection follows the platform split in the README: native on Windows, Docker
Compose on Linux.

You need Docker, VS Code, and the Dev Containers extension.

1. Clone the repository and open the folder in VS Code.
2. Create your local environment file and fill in any values you need:
   ```bash
   cp .devcontainer/.env.example .devcontainer/.env.dev
   ```
   `.env.dev` is gitignored. Keep it that way.
3. Run **Dev Containers: Reopen in Container**.
   The image builds and `.devcontainer/script.sh` runs on start: it configures
   NVM, Git identity, graphify, the browser runtime, and launches Electron.
4. Open the desktop:
   - Browser (noVNC): http://localhost:6081/vnc.html?autoconnect=true&resize=scale
   - Native VNC client: `localhost:5901` (loopback only, no password)

Ports forwarded by `devcontainer.json`: `8001` (API, planned), `5174` (Vite,
planned), `5901` (VNC), `6081` (noVNC). There is no backend yet; the full
environment today is the VNC desktop plus the Electron shell.

## Run the Electron app

Inside the container:

```bash
.devcontainer/electron.sh            # start (or restart) the app
.devcontainer/electron.sh --install  # reinstall dependencies first
```

The app autostarts on container boot. Set `ENABLE_ELECTRON=false` in
`.devcontainer/.env.dev` to disable that.

On a normal desktop (Node 22.12+):

```bash
cd apps/desktop
npm install
npm start
```

The renderer currently runs against `createMockBackend()` because there is no
preload script yet. Keep that fallback working — the app must not crash when
`window.electronAPI` is undefined. The container runs as root, so the launcher
adds `--no-sandbox`; never ship that flag.

## Project layout

| Path | What it is |
| --- | --- |
| `apps/desktop/` | Electron app: main process + renderer |
| `.devcontainer/` | Dev environment, VNC, Electron launcher |
| `requirements/` | Python dependencies (backend is planned) |
| `backend/python/`, `packages/schemas/` | Not implemented yet |

## Making changes

- Branch from `main`; keep pull requests focused.
- Preserve Electron hardening: `contextIsolation: true`,
  `nodeIntegration: false`, preload via `contextBridge` only, validate every
  IPC payload, and never build shell strings from renderer input.
- Contribution packages are `snake_case` JSON and must include `game_version`,
  `collected_at`, `tool_version`, and `consent`. Anonymize player data.
- Explain *why* in comments, not *what*.

## Before opening a pull request

- Start the app and smoke-test the screen you changed.
- If Python code exists, run `ruff check .`, `black .`, and `pytest`.
- Run `graphify update .` after changing code (the graph is generated and
  gitignored; a large diff is expected).
- Update `requirements/*.txt` in the same change when adding a dependency.
- Confirm your diff contains no secrets, proprietary data, or build artifacts.

In the pull request, say what changed, why, and how you tested it.

## Current status

Only the Electron shell exists. The FastAPI backend, JSON schemas, preload
bridge, and submission flow are planned but not implemented. Open an issue
before starting work on those so the design can be agreed first.
