# Implementation Progress

Changelog for [Canvas Chat](DESIGN.md). Milestones **M1–M5 are complete**; work
since is post-M5 features, fixes and reviews. Newest first.

Conventions: keep `flutter analyze` clean and `flutter test` green; record
non-obvious decisions and test gotchas in the log (git holds the detail).

## Milestones (all done)

M1 Import + data layer · M2 Conversation list + read mode · M3 Navigate canvas ·
M4 Read-mode integration · M5 Polish (FTS search, asset rendering, macOS menu +
shortcuts, Android input, import warnings).

## Log

- 2026-06-21 · perf review · Real-engine profile trace of the "not smooth with
  many nodes" report. Root cause: the canvas redraws on every viewport tick —
  the node layer is rebuilt **and** repainted per frame with no `RepaintBoundary`
  — so cost scales with visible cards (pan worst frame 51 ms; ~1,378
  `Dart_StringToUTF8` + ~181 `Opacity` `saveLayer` per paint). Findings + ranked
  fixes in DESIGN.md §6 "Performance"; **not yet applied**. Reusable harness
  added: `integration_test/perf_pan_test.dart` + `test_driver/perf_driver.dart`
  (`flutter drive --profile … → build/perf/*.timeline_summary.json`).
- 2026-06-20 · post-M5 · Read-mode response chunking + a per-chunk
  Ask/Explain/Expand/Copy toolbar that forks a child turn (first slice of §9,
  fully offline behind `StubLlmProvider`/`llmProviderProvider`). Core:
  `domain/markdown_blocks.dart`, `state/branching.dart`; integration test
  screenshots hover→Explain→branch.
- 2026-06-11 · fix · Import isolate crash — a shared closure scope dragged an
  unsendable `_Future` into the spawn message; fixed with a top-level compute
  function capturing only strings + a SendPort. Regression test added.
- 2026-06-11 · M5 done · FTS5 search over titles + prompt/response, read-mode
  image/attachment rendering, `PlatformMenuBar` + ⌘F, Android
  overscroll-to-advance, import-warnings dialog.
- 2026-06-10 · M4 done · Read mode integrated with the canvas: hero overlay
  (full-screen on Android), grid-neighbor traversal with a branch breadcrumb,
  per-conversation `canvas_state` (mode/focus/viewport) persisted and restored.
- 2026-06-10 · M3 done · Navigate canvas: pure grid/lane layout, hand-rolled
  pan/zoom viewport, exact culling of uniform cells, one edge `CustomPainter`,
  tappable minimap.
- 2026-06-10 · M2 done · Two-pane home, conversation list (live during import),
  bare read mode (markdown + active-path walk), background-isolate import with a
  progress banner.
- 2026-06-10 · M1 done · Importer (zip/folder) + turn pairing + drift schema;
  goldens vs the real export (1,594 convs / 12,185 msgs / 6,075 turns). Key
  decision: `turns.id = <conversation_id>:<node_id>` so reused node ids across
  conversations don't collide on the global PK.
