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
| M2 | Conversation list + bare read mode | done | App launches on macOS. Sidebar lists imported conversations (sorted by update_time). Selecting one opens a minimal read mode: full prompt+response markdown, ↑/↓ walks the active path. Import triggered from UI with progress. |
| M3 | Navigate mode (canvas) | done | Grid/lane layout per DESIGN.md §6: uniform collapsed cards (query + meta), quick-button strip, edges with active-path emphasis, pan/zoom, viewport culling, arrow-key/button selection, minimap. |
| M4 | Read mode integration | done | Maximize/tap → read mode (full-screen Android, overlay macOS), hero transition, ↑↓←→ traversal with branch breadcrumb, minimize returns centered, mode/focus/viewport persisted per conversation (canvas_state). |
| M5 | Polish | done | FTS search over prompts/responses, image/PDF assets render, macOS menu + shortcuts, Android back behavior, import warnings UI, app icon optional. |

Statuses: `todo` → `in_progress` → `done` (or `blocked`).

## Log

<!-- newest first: date · milestone · what was done / decisions / blockers -->
- 2026-06-20 · post-M5 feature · Read-mode response chunking + a per-chunk
  toolbar that forks branches — the first slice of DESIGN.md §9 "Live chat",
  built to stay fully offline. The assistant response is split into block-level
  chunks (`domain/markdown_blocks.dart`: paragraphs/lists/headings split on
  blank lines, fenced code kept intact so a fence is never broken into invalid
  markdown); each text chunk gets a subtle highlight while active and a
  top-right toolbar that fades in on hover (long-press on touch) — Ask AI /
  Explain / Expand / Copy. Ask/Explain/Expand fork a *child* turn off the read
  turn via `BranchService` (`state/branching.dart`); the grid layout already
  drops an additional child into a fresh right-hand lane, so it reads as a
  horizontal branch, and the reader glides onto it. Answers come from a
  pluggable `LlmProvider` (`data/llm/llm_provider.dart`) whose default
  `StubLlmProvider` is fully offline (no network/API key) — the exact seam §9
  calls for; the response streams into the row (drift re-emits → live UI).
  Authored turns use an `<conv>:authored-<ts>-<seq>` id namespace and
  `raw_json={"authored":true}`. `flutter analyze` clean, 130 tests pass (9 new:
  6 markdown-block + 3 branch-service); a macOS integration test
  (`integration_test/chunk_toolbar_test.dart`) drives hover→Explain→branch and
  screenshots it (build/chunk_shots/), verified on the real engine. Decisions:
  - Offline stub + provider-agnostic seam (user's call): keeps the app's
    offline/no-API-key invariant while building the whole chunk→toolbar→branch
    UX; a real provider drops in behind `llmProviderProvider`.
  - "Horizontal branch" = a child turn (a follow-up question *is* a child); it
    lays out horizontally whenever the source turn already has a continuation,
    and straight down when the source was a leaf (the only sensible placement).
  - Chunk toolbars stay mounted (opacity + IgnorePointer gated) so hover
    in/out can fade; `branchFrom` returns `(id, done)` so the UI focuses the
    new branch immediately while the answer streams (tests await `done`).
- 2026-06-11 · post-M5 fix · Import failed in the real app (worked in all
  tests): drift's `computeWithDatabase` closure was inlined in
  `runImportInBackground`, and the Dart VM's shared per-scope closure context
  dragged the caller's `onProgress` (capturing the Riverpod controller) into
  the isolate spawn message → "Illegal argument in isolate message: object is
  unsendable - _Future". Fixed by building the computation in a top-level
  function whose only captures are two strings and a SendPort. Regression
  test added (onProgress capturing an unsendable, fails on old code); import
  failures now also debugPrint with stack. Verified end-to-end in the running
  macOS app via UI automation: 1,594 conversations imported.
- 2026-06-11 · M5 · Done — all milestones complete. Sidebar search: an FTS5
  query over `turns_fts` (prompt/response) grouped to conversations by best
  rank, unioned with case-insensitive title matching (title hits first,
  newest first, then content hits by rank, dedup'd);
  `AppDatabase.ftsMatchQuery` quotes each whitespace-separated term as a
  `"term"*` prefix query so FTS5 operators in user input are inert. Asset
  rendering: read mode splits markdown on the importer's
  `![image](asset://<pointerId>)` markers and resolves each against the
  turn's `turn_assets` rows (pointer id = copied file's basename) — images
  render via `Image.file` (decode-failure errorBuilder), placeholder rows
  (path='') and unresolved pointers show an "Image not included in the
  export" tile, and non-image extensions get an attachment tile (defensive:
  the export's PDF/txt are attachment-only, never pointer-referenced, so no
  rows exist for them — graceful = nothing to render, nothing crashes).
  macOS: `PlatformMenuBar` (Canvas Chat ▸ Quit, File ▸ Import Export
  Zip/Folder + Import Warnings, Edit ▸ Find ⌘F) plus an in-app ⌘F
  CallbackShortcut focusing the sidebar search field (works while the
  canvas has focus); canvas/read shortcuts from M3/M4 unchanged. Android:
  read-mode swipe-to-advance — drag-overscroll accumulated past the
  transcript's top/bottom edge (≥64 px on release) moves focus to the
  previous/next turn; normal scrolling never overscrolls so it is
  unaffected; back already pops the read route (PopupRoute). Import
  warnings UI: success snackbar gains a Details action and the sidebar
  import menu a "Last import warnings…" item, both opening a dialog over
  the latest `imports` row's warnings_json. `flutter analyze` clean,
  72 tests pass (57 kept + 9 search unit/db tests + 6 M5 widget tests),
  `flutter build macos --debug` succeeds. Decisions:
  - App icon left as the Flutter default (explicitly optional in the
    acceptance criteria).
  - Search results are a one-shot query per keystroke (not a live stream):
    cheap at this scale and avoids re-running FTS on every import insert.
  - Navigate-mode cards still show the prompt's raw text (markers and all)
    — only read mode resolves assets; the 2-line collapsed preview isn't
    worth an asset lookup per card.
  - No View ▸ Zoom-to-fit menu item: it would need menu→canvas plumbing for
    a shortcut (`f`) the focused canvas already handles.
  - Test fixture's `.dat` asset is now a real 1×1 PNG (`kTinyPngBytes`) so
    the rendered image can actually decode; the M1 byte-equality assertion
    was updated to match the new bytes.
- 2026-06-11 · M4 · Done. Read mode integrated with the canvas. Card tap or
  ⊕ pushes a `ReadModeRoute` (custom `PopupRoute`) that grows hero-style
  from the cell's on-screen rect — full-screen on Android
  (`defaultTargetPlatform`), centered ~85% overlay over the dimmed canvas
  elsewhere; the canvas keeps its viewport underneath. `ReadOverlay`
  (rewritten `read_view.dart`, reusing M2's turn body + markdown rendering)
  traverses via the grid-layout neighbors: ↑/↓ transcript along the lane,
  ←/→ across branches at the same depth with a "⑂ Branch i of n" breadcrumb
  (cells sharing the focused row, left→right by lane). Esc / ⊖ / barrier tap
  pops; the canvas then re-centers on the node just read and persists
  mode='navigate'. `canvas_state` is now live: focused_turn_id + mode +
  viewport (scale & canvas-space center as JSON, robust to window-size
  changes) upserted on focus/mode changes, debounced 300 ms for pan/zoom
  with a dispose-time flush, restored on open (including auto-reopening
  read mode where the user left off; importer's keep-while-focus-exists
  policy was already in place since M1). `flutter analyze` clean, 57 tests
  pass (52 kept — one updated: maximize is now enabled — + 5 new M4 widget
  tests), `flutter build macos --debug` succeeds. Decisions:
  - Card body tap = maximize (DESIGN.md §6 "Tap a node … → read mode");
    NodeCard's now-dead `onSelect` was removed — selection moves only via
    arrows/quick-buttons, or implicitly by entering read mode.
  - `conversationPathProvider`/`ConversationPath` (M2) deleted; the overlay
    reads the same `conversationGraphProvider` as the canvas, so read-mode
    ↑/↓ follows the *layout's* lane semantics (active-path rule at forks).
  - Persisted state is best-effort: writes are fire-and-forget with errors
    swallowed, and a corrupt/missing viewport_json falls back to the M3
    default (1:1 centered on the focused turn).
  - canvasStateProvider is a one-shot FutureProvider (not a stream) so the
    canvas's own writes can't feed back into rebuilds.
  - Read-mode focus changes are mirrored into the canvas selection via a
    callback while the route is up, so pop centering needs no result value.
  - The reverse (minimize) transition shrinks toward the *originally*
    tapped cell even if focus moved while reading — visually fine at 220 ms
    since the canvas immediately re-centers; revisit only if it grates.
  - Android swipe-up/down-to-advance from DESIGN.md §6 is left to M5
    (Android input polish) — it isn't in M4's acceptance criteria.
  - Widget-test gotchas for M5: `defaultTargetPlatform` in widget tests is
    *android* — tests asserting desktop presentation must set
    `debugDefaultTargetPlatformOverride = TargetPlatform.macOS` and reset
    it inline (try/finally), because the binding verifies foundation vars
    *before* tearDown callbacks run. The 300 ms persistence debounce is
    deliberately below the canvas tests' standard ≥350 ms post-tap pump.
- 2026-06-10 · M3 · Done. Navigate-mode canvas replaces the detail pane.
  Grid layout engine (`lib/src/domain/grid_layout.dart`): pure function of
  the turn tree — active path (reused from `active_path.dart`) in lane 0,
  each additional fork branch claims the nearest free lane to the right at
  its fork row (interval-based occupancy so non-overlapping branches reuse
  lanes), per-cell up/down/left/right neighbor ids per DESIGN.md §6
  semantics. Canvas (`lib/src/ui/canvas/`): hand-rolled viewport
  (translate+scale `ChangeNotifier`), drag/pinch pan-zoom, Cmd/Ctrl+scroll
  zoom, plain scroll pan, double-tap / `f` fit, exact viewport culling of
  uniform 260×112 cards, one `CustomPainter` for all edges (rounded elbows,
  active path emphasized, others dimmed), quick-button strip on every card,
  tappable minimap with viewport rect. `flutter analyze` clean, 52 tests
  pass (8 new grid-layout unit tests), `flutter build macos --debug`
  succeeds. Decisions:
  - Minimize/maximize buttons render disabled: read mode integration is M4;
    in navigate mode the arrows move the *selection* (kept on-screen via a
    minimal ensure-visible pan).
  - Initial viewport = 1:1 centered on the conversation's current turn (not
    fit-to-content): long chats open readable at their latest turn, and it
    makes culling real from frame one. Viewport persistence is M4.
  - Within a non-active branch, the latest sibling continues the branch's
    lane at a sub-fork (same "latest wins" rule as active-path extension);
    unreachable turns from corrupt cycles are parked in fresh lanes so
    everything stays visible.
  - Lane continuity means every lane index < laneCount holds ≥1 cell, so
    left/right neighbors always resolve in adjacent lanes.
  - Layout runs synchronously in the provider (pure O(n), ≤ a few hundred
    turns per conversation) — the isolate from DESIGN.md §3 isn't warranted
    yet.
  - M2's read-mode widget tests were retired with the detail pane (ReadView
    itself is untouched and returns as the M4 overlay); canvas widget tests
    now cover open-on-current-turn, fit, fork badges, arrow/button
    selection + disabled-at-edge buttons, culling on a 40-turn chat, and
    minimap jumps.
  - Widget-test gotcha for M4: the canvas GestureDetector listens for
    double taps, so single taps inside it (cards, minimap) sit in the
    gesture arena for ~300 ms — pump ≥350 ms after `tester.tap` before
    asserting.
- 2026-06-10 · M2 · Done. Two-pane home (sidebar 320px + detail), conversation
  list sorted by update_time desc (drift stream query, live during import),
  bare read mode (prompt/response via gpt_markdown, collapsible Reasoning
  tile, ↑/↓ buttons + arrow keys walk the active path, "n / m" position
  indicator), import zip/folder from a sidebar menu (file_picker) running in
  a background isolate (drift computeWithDatabase) with a progress banner.
  `flutter analyze` clean, 43 tests pass, `flutter build macos --debug`
  succeeds. Decisions:
  - Active path = ancestors of `current_turn_id` extended down to a leaf,
    picking the most recently created sibling at each fork (matches ChatGPT
    showing the latest edit/regeneration); guards for dangling parents and
    cycles in corrupt data. Lives in `lib/src/domain/active_path.dart`.
  - Read mode replaces the detail pane (no overlay/hero yet — that is M4);
    image markers in markdown render as a textual "[image attachment]"
    placeholder so `asset://` URIs never hit the network (assets render
    in M5).
  - macOS entitlements gained `files.user-selected.read-only` for the open
    panel (DESIGN.md §7).
  - Why previous sessions saw `flutter test` hang forever: widget tests did
    real file I/O + import inside testWidgets' FakeAsync zone (deadlock —
    fixed with `tester.runAsync`), and drift's stream-close schedules a
    zero-duration timer when ProviderScope is disposed, which deadlocked
    `db.close()` in tearDown. Each widget test now unmounts the app and
    pumps 1ms so that timer fires inside the test. Keep both patterns for
    M3/M4 widget tests, and never run `flutter test` without a timeout.
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
