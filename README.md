# Pokémon UNITE Community Data Preservation

An open-source, community-driven initiative to preserve Pokémon UNITE's game data, player progress, and history.

## Purpose

Pokémon UNITE is approaching its shutdown. This project aims to help the community preserve as much of the game and its history as possible through collaborative data collection and documentation.

The initiative is independent of Revival Games and is intended to complement its server development efforts.

This project is not affiliated with Nintendo, The Pokémon Company, Tencent, or TiMi Studio Group.

## Core Principles

- **Open source:** Transparent tools and workflows that the community can inspect and contribute to.
- **Community-driven:** Players, developers, and competitive communities can participate.
- **Privacy first:** Contributors decide whether to share their collected data.
- **Reproducibility:** A standardized environment makes data collection consistent and accessible.
- **Data integrity:** Contributions should be validated before entering the shared database.

## Project Scope

- Back up as many game files as possible (APK)
- Back up assets (if users agree)
- Back up player datas
- Create a global database of contributors to help data migration
The exact collection scope and data schema remain open for discussion.

## Contribution Workflow

The proposed workflow is:

1. The contributor connects its phone to the pc
2. The tools collect and organize the available data thought the ADB tool.
3. A contribution package is generated.
4. The contributor reviews the information through a GUI.
5. The contributor explicitly approves or rejects the submission.
6. Approved contributions are sent to the backend. (<- litteral humans)
7. The backend validates and processes the data before adding it to the shared database.

Users should never need direct database access or be required to edit or execute SQL statements.

**Preferred approach:** use structured contribution data, such as JSON, rather than executable SQL generated on the client. The backend should handle database operations.

## Data Storage

The current proposal includes a shared community database.

SQLite has been suggested as a possible solution, but the final database technology has not yet been decided.

The collection tools and APK remain on the contributor's local device. APKs and proprietary game assets should not be uploaded to this public repository.

## Privacy and Security

This tool **won't upload anything by default.** It is primarily meant to decentralize the game preservation and have as much fallback options as possible.

If you choose to, the only data uploaded are informations about your profile. This will help create a database of players if data migration is implemented in the Revival project.
The data uploaded is only the SQL query used to populate the database with your profile, no other data leaves your PC.

- Participation and data submission must be voluntary.
- Contributors should only submit data they own or are authorized to share.
- We do not collect passwords, authentication tokens, session cookies, or other credentials.
- Avoid exposing personal information belonging to other players.
- Contributions must be reviewed before submission.
- The backend must validate incoming data.
- Collection methods must be reviewed to avoid unnecessary security or platform risks.

## Development Environment

We aim to provide a standardized, reproducible development environment using:

- Docker and Docker Compose.
- VS Code Dev Containers.
- Recommended VS Code extensions.
- Android emulator support.
- Setup scripts and beginner-friendly documentation.

The goal is to make participation accessible to developers with different levels of experience.

### Architecture Overview

```mermaid
flowchart TB

    subgraph ENV["🧑 User Environment"]
        direction TB

        subgraph PC["🖥️ Player's PC"]
            direction TB

            GUI["GUI Application<br/><i>Electron / Tauri / TBD</i>"]

            subgraph DOCKER["🐳 Docker Compose Environment"]
                direction TB

                COLLECTOR["PU-CDP<br/>Data Collector"]
                ADB["ADB<br/>Android Debug Bridge"]
                DEPS["Required Dependencies"]

                COLLECTOR --> DEPS
                COLLECTOR --> ADB
            end

            APK["📦 APK Files<br/><i>Local only</i>"]
            ASSETS["🎨 Game Assets<br/><i>Local only</i>"]
            SQLQ["🔍 SQL Query<br/><i>Extract from APK</i>"]

            GUI -->|"Controls"| COLLECTOR
            APK --> COLLECTOR
            ASSETS --> COLLECTOR
            APK --> SQLQ
        end

        PHONE["📱 Android Device<br/>Pokémon UNITE"]

        PHONE <-->|"🔌 USB connection"| ADB
    end

    subgraph SERVER["🏠 Home Server / Our PCs"]
        direction TB

        INTEGRITY["✅ Data Integrity<br/>Verification"]
        CHECK{"Integrity<br/>passed?"}

        INTEGRITY --> CHECK
    end

    subgraph GITHUB["🌐 Layer 3 — GitHub Community Data Repo"]
        direction TB

        PUSH["📤 User Pushes<br/>Approved JSON"]
        REPO[("PU-Community-Data-Preservation<br/>Public JSON Archive<br/>Versioned Files")]

        PUSH --> REPO
    end

    REJECT["⚠️ Rejected<br/><i>Fix &amp; retry</i>"]

    SQLQ -->|"Raw data sent<br/>for verification"| INTEGRITY
    CHECK -->|"❌ Fail"| REJECT
    CHECK -->|"✅ Pass — push enabled"| PUSH

    %% ===== STYLES =====
    classDef envStyle fill:#020617,stroke:#475569,stroke-width:3px,color:#f1f5f9
    classDef pcStyle fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#e2e8f0
    classDef dockerStyle fill:#0f172a,stroke:#22d3ee,stroke-width:2px,stroke-dasharray: 6 4,color:#e2e8f0
    classDef guiStyle fill:#7c3aed,stroke:#a78bfa,stroke-width:2px,color:#ffffff
    classDef serviceStyle fill:#0891b2,stroke:#67e8f9,stroke-width:2px,color:#ffffff
    classDef depStyle fill:#0e7490,stroke:#22d3ee,stroke-width:1.5px,color:#e0f2fe
    classDef fileStyle fill:#334155,stroke:#94a3b8,stroke-width:1.5px,stroke-dasharray: 4 3,color:#cbd5e1
    classDef phoneStyle fill:#be123c,stroke:#fb7185,stroke-width:2px,color:#ffffff
    classDef sqlStyle fill:#d97706,stroke:#fbbf24,stroke-width:2px,color:#ffffff
    classDef serverStyle fill:#052e16,stroke:#22c55e,stroke-width:3px,color:#dcfce7
    classDef integrityStyle fill:#15803d,stroke:#4ade80,stroke-width:2px,color:#ffffff
    classDef checkStyle fill:#1e3a8a,stroke:#60a5fa,stroke-width:2px,color:#ffffff
    classDef githubStyle fill:#1e1b4b,stroke:#818cf8,stroke-width:3px,color:#e0e7ff
    classDef pushStyle fill:#4338ca,stroke:#a5b4fc,stroke-width:2px,color:#ffffff
    classDef repoStyle fill:#3730a3,stroke:#c7d2fe,stroke-width:2px,color:#eef2ff
    classDef rejectStyle fill:#7f1d1d,stroke:#f87171,stroke-width:2px,color:#fecaca

    class ENV envStyle
    class PC pcStyle
    class DOCKER dockerStyle
    class GUI guiStyle
    class COLLECTOR,ADB serviceStyle
    class DEPS depStyle
    class APK,ASSETS fileStyle
    class PHONE phoneStyle
    class SQLQ sqlStyle
    class SERVER serverStyle
    class INTEGRITY integrityStyle
    class CHECK checkStyle
    class GITHUB githubStyle
    class PUSH pushStyle
    class REPO repoStyle
    class REJECT rejectStyle
```

### User Story

```
As a Pokémon UNITE player, I want a one-click installer for Windows that sets everything up automatically, with minimal user involvement. I should only need to enable Developer Mode on my Android device and connect it via USB.

To log in, I should use my Discord account and be a member of the Pokémon UNITE Revival server.

The application should have a very simple interface with just a few buttons. The main one should be Start Process. Once clicked, I can watch the program create a complete backup of my account data in the application's folder.

When the backup is complete, the app should ask whether I want to validate my data and submit it to the community repository.

Finally, I should receive a Discord DM confirming that the process was successful, along with a link to my file in the repository.
```

## How to Contribute

Contributions are welcome in areas such as:

- Data collection and validation.
- Android development and emulator setup.
- Unity research and game data analysis.
- Database schema and backend development.
- GUI and developer tooling.
- Documentation and tutorials.
- Competitive gameplay knowledge and data verification.

## Open Questions

The following decisions still need community discussion:

- Which data should be prioritized?
- What collection methods should be supported?
- What should the contribution data schema look like?
- Which database technology should we use?
- How should player data be anonymized and protected?
- How should game versions and historical changes be tracked?

## Relationship with Revival Games

This initiative is separate from Revival Games' server development.

Its purpose is to organize community data preservation and provide useful documentation and tools that may support future preservation efforts.

## Disclaimer

This is an independent community project. Pokémon UNITE and all associated intellectual property belong to their respective owners.

## Closing

**Preserving the game, its history, and the community that made it special.**
