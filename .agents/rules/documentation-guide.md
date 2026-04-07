---
description: "Guidelines on how the project documentation should be structured, updated, and extended."
trigger: always_on
---

# Documentation Guide

This homelab project follows a structured documentation approach that ensures a clean, maintainable, and highly readable knowledge base. Whenever you create or modify documentation, adhere to the following rules:

## 1. The README is the Entry Point
The `README.md` file at the root of the repository is the single source of truth for the project's high-level state. It must always include:
- **Project Header & Motivation**: What the project is and its design philosophy.
- **Architecture at a Glance**: A high-level Mermaid diagram and node summary.
- **Features & Implementation Status**: A unified table tracking main capabilities with status badges (✅ Done, 🚧 Partial/In Progress, 🔲 Planned).
- **Master To-Do List**: The *only* place where pending tasks and research items are tracked.
- **Repository Structure**: A tree view of the repository.
- **Documentation Index**: A table linking to all detailed documents in the `docs/` folder.

## 2. Centralized To-Do Lists
- **Rule**: NEVER put tracking checklists, open questions, or "TODOs" in individual documents inside the `docs/` folder.
- **Action**: All actionable tasks, whether Research or Implementation, must be centralized in the **Master To-Do List** inside the `README.md` file.

## 3. Topic-Based Documents (`docs/`)
- Organize detailed documentation by **topic** (e.g., `deployment.md`, `backup.md`, `monitoring.md`), rather than creating documents centered around specific nodes or container stacks (e.g., avoid `infra-node.md` or `services-stack.md`).
- Node placement and service mappings belong in `docs/architecture.md`.

## 4. Descriptive Filenames
- Use descriptive, hyphen-separated markdown filenames (e.g., `proxmox-setup.md`, `home-assistant.md`).
- **Do not** use numbering prefixes (e.g., avoid `01-architecture.md` or `02-backup.md`).

## 5. Consistent Document Formatting
Every file in the `docs/` directory must follow a consistent structure:
1. **Title**: An `H1` describing the topic cleanly. Do not include the `.md` extension or arbitrary prefixes in the text.
2. **Overview**: A brief introductory paragraph detailing the scope and current implementation state of the topic.
3. **Content**: Clean, focused, procedural information. Use setup guides instead of tracking checklists.
4. **Cross-Links**: Use standard relative markdown links to connect related documents where applicable (e.g., `[Architecture](architecture.md)`).

## 6. Documenting Services
- New end-user services should be added to the unified services table in `docs/services.md`.
- Ensure the table maintains the specific format: `| Service | Type | Status |`.
- Infrastructure services (like Homepage or ZeroByte) should be mapped appropriately in the Node Details section of `docs/architecture.md`.

## 7. Adding New Documents
If a new major topic emerges that requires its own document:
1. Create it in the `docs/` directory following the rules above.
2. Link to it from relevant existing documentation where topics overlap.
3. Add a new row to the **Documentation Index** table at the bottom of the `README.md`.
