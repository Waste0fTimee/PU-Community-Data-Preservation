PU-Community-Data-Preservation/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
│
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
│       └── ci.yml
│
├── apps/
│   └── desktop/
│       ├── package.json
│       ├── electron-builder.yml
│       │
│       ├── src/
│       │   ├── main/
│       │   │   ├── index.js
│       │   │   ├── ipc/
│       │   │   │   └── backup.js
│       │   │   ├── services/
│       │   │   │   ├── adb.js
│       │   │   │   ├── backend.js
│       │   │   │   └── backup.js
│       │   │   └── security/
│       │   │       └── permissions.js
│       │   │
│       │   ├── preload/
│       │   │   └── index.js
│       │   │
│       │   └── renderer/
│       │       ├── index.html
│       │       ├── styles/
│       │       │   ├── main.css
│       │       │   └── components.css
│       │       ├── scripts/
│       │       │   ├── app.js
│       │       │   └── components/
│       │       └── assets/
│       │
│       └── tests/
│           ├── main/
│           └── renderer/
│
├── backend/
│   └── python/
│       ├── pyproject.toml
│       ├── uv.lock
│       ├── src/
│       │   └── pu_preservation/
│       │       ├── __init__.py
│       │       ├── cli.py
│       │       ├── collectors/
│       │       ├── extractors/
│       │       ├── validators/
│       │       └── exporters/
│       └── tests/
│
├── packages/
│   └── schemas/
│       ├── account.schema.json
│       ├── backup.schema.json
│       └── README.md
│
├── scripts/
│   ├── setup-dev.sh
│   └── package-app.sh
│
├── docs/
│   ├── architecture.md
│   ├── data-format.md
│   └── development.md
│
├── .gitignore
├── .editorconfig
├── package.json
├── pnpm-workspace.yaml
├── README.md
└── LICENSE