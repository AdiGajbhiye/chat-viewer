# Implementation Progress

State file for unattended milestone-by-milestone implementation of
[DESIGN.md](DESIGN.md). Each work session: read DESIGN.md fully, read this
file, check `git log`, then implement the **first milestone below that is not
`done`** — that one milestone only, nothing beyond it.

## How to work (rules for the implementing agent)

1. The Flutter project lives in `canvas_chat/` (create it on M1 with
   `flutter create canvas_chat --platforms=android,macos --org com.ludonaira`).
2. Test fixture: the real export in `chatgpt_data/` (gitignored — never commit
   it, never modify it). Tests may read it directly by absolute path.
3. Definition of done for every milestone:
   - `flutter analyze` clean (no errors; justify any suppressed warnings)
   - `flutter test` passes
   - milestone's acceptance criteria below met
   - committed with message `M<n>: <summary>` (one or more commits)
   - this file updated: status flipped, Log entry appended
4. If blocked, set status to `blocked` with a short reason in the Log and stop
   — do not start the next milestone.
5. Do not redesign. If DESIGN.md is ambiguous, choose the smallest reasonable
   interpretation and note the choice in the Log.

## Milestones

| # | Milestone | Status | Acceptance criteria |
|---|---|---|---|
| M1 | Import + data layer | todo | Importer parses the real export from a zip or folder: 1,594 conversations / 12,185 messages, turn pairing per DESIGN.md §2, drift schema per §4, assets copied + renamed. Tests cover: counts match, all 4 content types handled, forks produce multiple child turns, asset resolution, idempotent re-import. |
| M2 | Conversation list + bare read mode | todo | App launches on macOS. Sidebar lists imported conversations (sorted by update_time). Selecting one opens a minimal read mode: full prompt+response markdown, ↑/↓ walks the active path. Import triggered from UI with progress. |
| M3 | Navigate mode (canvas) | todo | Grid/lane layout per DESIGN.md §6: uniform collapsed cards (query + meta), quick-button strip, edges with active-path emphasis, pan/zoom, viewport culling, arrow-key/button selection, minimap. |
| M4 | Read mode integration | todo | Maximize/tap → read mode (full-screen Android, overlay macOS), hero transition, ↑↓←→ traversal with branch breadcrumb, minimize returns centered, mode/focus/viewport persisted per conversation (canvas_state). |
| M5 | Polish | todo | FTS search over prompts/responses, image/PDF assets render, macOS menu + shortcuts, Android back behavior, import warnings UI, app icon optional. |

Statuses: `todo` → `in_progress` → `done` (or `blocked`).

## Log

<!-- newest first: date · milestone · what was done / decisions / blockers -->
- 2026-06-10 · setup · Repo initialized, DESIGN.md committed, PROGRESS.md created. No code yet.
