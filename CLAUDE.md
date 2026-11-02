## 1. Invariants (never relaxed, any context)

1. **English only.** Code, identifiers, comments, commits, docs, UI copy, and error strings MUST be in English.

2. **Secrets are untouchable.** `.devcontainer/.env.dev` MUST NEVER be copied into any output, or committed. Credentials of any kind (passwords, tokens, cookies, API keys, session IDs) MUST NEVER be collected, stored, or transmitted. If a task needs a secret, ask the user to place it in `.env.dev` and reference it by env-var name only.

3. **No proprietary data.** APKs, extracted game assets, raw player data, and any Pokémon UNITE binary MUST NOT be committed, uploaded, or copied into the repo. Only tools, source, approved JSON, and docs belong here.

4. **Privacy is the default.** Nothing leaves the contributor's machine unless the user takes an explicit action in the GUI, and the exact payload is shown before that action. Auto-upload, background sync, telemetry, and silent retries are forbidden.

5. **Generated files are off-limits for hand-edits.**
   - `graphify-out/` → rebuild with `graphify update .`
   - `project_dump.md` → regenerate with `python utility_scripts/concat_project.py`
   - `.root-home/` → managed by `.devcontainer/script.sh`
   - `utility_scripts/` → tooling, not application code; edit only when the task explicitly concerns tooling.

6. **Electron stays hardened.** See §4. Non-negotiable.

7. **No client-generated SQL.** Contribution packages are JSON; the backend owns every database write. See §5.

8. **Container environment.** This workspace runs inside a Docker container, so the Docker CLI is not available. Do not run `docker` or `docker compose` commands without explicit user permission.

---

## 2. Project state

### 2.1 Exists in the repository

- `apps/desktop/` — Electron app (CommonJS main process; no bundler)
  - `src/main/index.js`
  - `src/renderer/index.html` (UI + mock backend inline)
  - `src/renderer/styles/main.css` (empty placeholder)
- `.devcontainer/` — dev environment config (Xvfb + noVNC, patchright)
- `requirements/prod.txt`, `requirements/dev.txt`
- `CLAUDE.md`, `README.md`, `tree.md`

### 2.2 Does NOT exist — do not invent paths for these without asking

- `backend/python/` — planned; no `pyproject.toml`, no package
- `packages/schemas/` — planned; no JSON schemas
- `apps/desktop/src/preload/` — referenced by `main/index.js` but absent; therefore `window.electronAPI` is `undefined` and the renderer uses its mock backend. This is expected, not a bug.
- `apps/desktop/src/renderer/scripts/app.js` — empty placeholder; renderer logic currently lives inline in `index.html`
- Discord login / DM flow — planned
- Windows one-click installer — target, not implemented

### 2.3 Source of truth

Filesystem > `tree.md`. `tree.md` is aspirational; if it disagrees with the files, the files win.

Project context: this is an independent community preservation effort, not affiliated with Revival Games, Nintendo, The Pokémon Company, Tencent, or TiMi.

---

## 3. Commands

| Task                         | Command                                                                | cwd            |
| ---------------------------- | ---------------------------------------------------------------------- | -------------- |
| Install desktop deps         | `npm install`                                                          | `apps/desktop` |
| Run the app                  | `npm start`                                                            | `apps/desktop` |
| Lint Python                  | `ruff check .`                                                         | repo root      |
| Format Python                | `black .`                                                              | repo root      |
| Run Python tests             | `pytest`                                                               | repo root      |
| Refresh knowledge graph      | `graphify update .`                                                    | repo root      |
| Query knowledge graph        | `graphify query "<question>"`                                          | repo root      |
| Trace a relationship         | `graphify path "<A>" "<B>"`                                            | repo root      |
| Explain a concept            | `graphify explain "<concept>"`                                         | repo root      |

Not yet runnable (do not attempt): anything requiring `backend/python/` or `packages/schemas/`.

---

## 4. Electron security (MUST)

- `webPreferences.contextIsolation` MUST be `true`.
- `webPreferences.nodeIntegration` MUST be `false`.
- Preload MUST expose named methods via `contextBridge.exposeInMainWorld` only. `require`, `process`, `ipcRenderer`, and any Node module MUST NOT be exposed to the renderer.
- The main process MUST validate every IPC payload from the renderer before acting on it.
- The main process MUST NOT execute shell strings built from renderer input. Use `execFile` / `spawn` with an argument array.
- Any file path, URL, or shell argument that originates in the renderer MUST be validated and, where applicable, allow-listed before use.

---

## 5. Data and schema (MUST)

- Contribution packages are structured JSON. Client-generated SQL is forbidden.
- Every package MUST include these fields: `game_version` (string), `collected_at` (ISO 8601 UTC), `tool_version` (string), `consent` (`"accepted"` or `"rejected"`).
- JSON keys MUST be `snake_case`.
- Every inbound submission MUST pass a Pydantic model validation at the backend boundary before any write.
- All SQL MUST be parameterized. The backend owns every database write.
- Rejected or invalid submissions MUST stay local and MUST surface the reason in the GUI. Silent retry, silent discard, and silent correction are forbidden.
- Player data MUST be anonymized before it appears in any submitted package.

---

## 6. Conventions

**JavaScript**

- Main process: CommonJS (`require`). Do not introduce ESM piecemeal; migrate the whole app in one commit or not at all.
- Renderer: no Node APIs, no `require`, no `process`.
- Move inline renderer logic into `apps/desktop/src/renderer/scripts/app.js` before the inline `<script>` exceeds 300 lines. Until then, inline is fine.
- The renderer MUST keep working when `window.electronAPI === undefined` (mock backend path). Do not remove `createMockBackend()`.

**Python** (once `backend/python/` exists)

- Type hints on every public function and class attribute.
- `ruff` and `black` are mandatory.
- Pydantic models at every boundary (HTTP, IPC, file read).
- Async via FastAPI + `pytest-asyncio`.

**Comments**

- Explain _why_, not _what_. Omit if self-evident.

---

## 7. Graphify

A knowledge graph lives at `graphify-out/`. It is gitignored and rewritten in full on every build — a large diff in a PR is expected; do not flag it as churn or suggest skipping the rebuild.

- Before your first `grep`, `search`, or source-file read for a codebase question, run `graphify query "<question>"`. Read raw files only for lines the graph or an earlier read has already located.
- For relationships use `graphify path "<A>" "<B>"`; for focused concepts use `graphify explain "<concept>"`.
- If `graphify-out/wiki/index.md` exists, use it for navigation instead of raw source browsing.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .`.

---

## 8. Agent working rules

### Before acting

- Read the file you will modify, plus its tests if they exist.
- If you plan to describe a feature as implemented, verify the file exists. `tree.md` is not verification.
- If a task requires a path from §2.2, ask before creating it.

### While acting

- Comply with §1 at every step. Invariants are not relaxable, not even "temporarily".
- Do not weaken §4.
- Do not add network egress beyond what the user triggers (§1.4).
- Do not edit §1.5 paths unless the task explicitly concerns them.

### After modifying code

- Run `graphify update .` (§7).
- If Python files changed: run `ruff check .` and `black .`.
- If a dependency was added: update the matching `requirements/*.txt` in the same change.

### Conflict resolution

- Filesystem wins on **what exists**. This file wins on **what is allowed**.
- If either contradicts a direct user instruction, ask the user.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
