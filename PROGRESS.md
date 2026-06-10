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
| M1 | Import + data layer | done | Importer parses the real export from a zip or folder: 1,594 conversations / 12,185 messages, turn pairing per DESIGN.md §2, drift schema per §4, assets copied + renamed. Tests cover: counts match, all 4 content types handled, forks produce multiple child turns, asset resolution, idempotent re-import. |
| M2 | Conversation list + bare read mode | todo | App launches on macOS. Sidebar lists imported conversations (sorted by update_time). Selecting one opens a minimal read mode: full prompt+response markdown, ↑/↓ walks the active path. Import triggered from UI with progress. |
| M3 | Navigate mode (canvas) | todo | Grid/lane layout per DESIGN.md §6: uniform collapsed cards (query + meta), quick-button strip, edges with active-path emphasis, pan/zoom, viewport culling, arrow-key/button selection, minimap. |
| M4 | Read mode integration | todo | Maximize/tap → read mode (full-screen Android, overlay macOS), hero transition, ↑↓←→ traversal with branch breadcrumb, minimize returns centered, mode/focus/viewport persisted per conversation (canvas_state). |
| M5 | Polish | todo | FTS search over prompts/responses, image/PDF assets render, macOS menu + shortcuts, Android back behavior, import warnings UI, app icon optional. |

Statuses: `todo` → `in_progress` → `done` (or `blocked`).

## Log

<!-- newest first: date · milestone · what was done / decisions / blockers -->
- 2026-06-10 · M1 · Done. Importer (folder + zip), turn pairing, drift schema,
  31 tests passing incl. goldens vs the real export (1,594 convs / 12,185
  msgs / 6,075 turns / 258 fork parents / 45 assets copied, 3 missing →
  placeholder rows). Decisions:
  - `turns.id` is `<conversation_id>:<node_id>`, not the bare node id: the
    real export contains a server-side conversation copy ("Make
    LensCodeSegment JSON Serializable") that reuses node ids across two
    conversation ids, so bare node ids collide as a global PK. Node id is
    recoverable as the suffix; `pairTurns` itself still uses pure node ids.
  - Multiple consecutive assistant `text`/`multimodal_text` messages in one
    turn are concatenated ("\n\n") into `response_md` rather than keeping
    only the final one — lossless, and `raw_json` keeps the originals.
  - Timestamps stored as INT milliseconds since epoch (export uses float
    seconds).
  - Image parts leave a `![image](asset://<pointerId>)` marker in the
    markdown; `audio_transcription` parts contribute their text; other part
    types (audio/video pointers) render an "unsupported content"
    placeholder. Only `image_asset_pointer` assets are copied; the export's
    PDF/txt are attachment-only (never referenced by a pointer) and are left
    for M5 attachment handling.
  - Blank (no text, no assets) and `system` messages are transparent
    everywhere, not just leading — covers the blank-user-then-assistant
    degenerate chains in the real export.
  - FTS5 is an external-content table synced by triggers; FTS works under
    `flutter test` on macOS system SQLite.
  - Import runs as a plain async API (progress callback); wiring it into an
    isolate is deferred to M2 where the UI needs it.
  - Branch-density answer for §11: 258 fork parents across 6,075 turns
    (~300 of 1,594 conversations contain a fork).
- 2026-06-10 · setup · Repo initialized, DESIGN.md committed, PROGRESS.md created. No code yet.
