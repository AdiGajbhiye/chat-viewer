# Implementation Progress

Changelog for [Canvas Chat](DESIGN.md). Milestones **M1–M5 are complete**; work
since is post-M5 features, fixes and reviews, plus **Phase 2** design (DESIGN.md
§10), not yet built. Newest first.

Conventions: keep `flutter analyze` clean and `flutter test` green; record
non-obvious decisions and test gotchas in the log (git holds the detail).

## Milestones (all done)

M1 Import + data layer · M2 Conversation list + read mode · M3 Navigate canvas ·
M4 Read-mode integration · M5 Polish (FTS search, asset rendering, macOS menu +
shortcuts, Android input, import warnings).

## Log

- 2026-06-25 · M7 · lazy indexer (DESIGN.md §10) — index-on-open, active-path-first.
  `ConversationIndexer` (`state/indexing.dart`) loads a conversation's turns,
  orders them **active-path-first** (pure `indexOrder` = `activePath` first, then
  off-path turns by create_time/id — tested directly), then per turn
  `extract(parentContext: ancestors) → embed(texts) → persistTurnExtraction(...,
  embeddingModel)`, one batched embed call per turn, awaiting `Future.delayed
  (Duration.zero)` between turns so a long session doesn't jank the UI thread (an
  isolate is avoided — the work is await-driven I/O and riverpod providers/HTTP
  don't cross isolates). Drives the `index_state` machine
  (notIndexed→indexing→indexed; `indexed_at` stamped on success); a conversation
  left at `indexing` (prior crash) re-runs safely since persist is idempotent per
  turn. **Double-start guard**: a process-wide in-flight set claimed
  *synchronously* before the first await, so two overlapping opens never
  double-process. **Staleness**: `markStaleIfModelChanged` flips an `indexed`
  conversation whose stored `embedding_model` ≠ the current provider `modelId` to
  `stale`, and the trigger re-indexes (full-project re-embed is M9.3). Offline-safe
  (stub extractor/embedder by default; zero-turn conversations complete cleanly to
  indexed). Progress exposed via `indexingProgressProvider`
  (`Map<convId, IndexingProgress{state,done,total}>`, mirrors
  `generatingTurnsProvider`); on-canvas `IndexingIndicator` chip (top-left) shows
  "Indexing N/M…" while `indexing`, hides when `indexed`. **Trigger**: a
  post-frame `triggerIndexOnOpen(ref, id)` in `CanvasView.initState` (fresh
  instance per conversation, keyed by id), fire-and-forget so it never blocks
  first paint. It stays green against existing widget tests — which don't override
  `sharedPreferencesProvider` (the indexer's extractor/embedder providers need it)
  — by catching the resulting `StateError` and no-opping; an `indexingEnabled
  Provider` (default true) also lets a test disable it outright. analyze clean; 14
  new tests (indexOrder ordering, happy-path persist+embed+state, end-to-end
  active-path-first via a recording extractor, double-start guard, zero-turn,
  already-indexed no-op, staleness re-index + same-model-not-stale, progress
  transitions, indicator show/hide/scoping), 215 total pass.
- 2026-06-25 · M6.3 · proposition + entity extraction (DESIGN.md §10) — the
  `PropositionExtractor` interface (`extract(Turn, {parentContext}) →
  TurnExtraction` of ~5 atomic, standalone, coref-resolved props, each with an
  open-vocab aspect + raw entity strings). Two impls cloning the stub-vs-real
  pattern: `StubPropositionExtractor` (default, fully offline, deterministic
  sentence/line segmentation capped at 5, shape-based aspect tag, naive entities
  from `code`/"quoted"/Capitalized tokens — stable arithmetic, no `hashCode`) and
  `LlmPropositionExtractor` (wraps an `LlmProvider`, asks for STRICT JSON,
  collects the stream, parses robustly through ```json fences + leading/trailing
  prose by slicing the outermost balanced array, throws `LlmException` on failure).
  `propositionExtractorProvider` resolves stub vs LLM off `llmConfigProvider`.
  Persistence: `AppDatabase.persistTurnExtraction(...)` — transactional,
  idempotent for re-index (clears the turn's prior propositions + turn_entities
  first, never deletes shared entities), upserts entities deduped by
  `(projectId, normalized)`, accepts optional same-order embeddings encoded via
  `encodeEmbedding` with an `embeddingModel`. Strictly additive — nothing calls it
  yet (the indexer wires it). analyze clean + 19 tests (stub determinism/cap/
  entities/aspect, LLM plain/fenced/prose/chunked/error parsing, persistence
  write/dedup/re-index-replace/embedding round-trip).
- 2026-06-25 · M6.2 · embedding layer (DESIGN.md §10) — the `EmbeddingProvider`
  interface (clones the `LlmProvider` pattern): `embed(List<String>)` batch,
  order-preserving, one vector per input, plus a `modelId` to stamp
  `propositions.embedding_model`. Two impls: `StubEmbeddingProvider` (default,
  fully offline, deterministic same-text→same-vector FNV-1a token hashing into a
  fixed 256-dim L2-normalized vector, `modelId` `stub-256`) and
  `OpenAiCompatibleEmbeddingProvider` (POSTs the batch as `input` to
  `/embeddings`, parses `data[].embedding`, reuses the chat host plumbing +
  `LlmException`). `embeddingConfigProvider`/`embeddingProviderProvider` resolve
  stub vs live exactly like `llmConfigProvider`/`llmProviderProvider` (stub when
  unconfigured/offline), reusing `llm.baseUrl`/`llm.apiKey` and adding
  `embedding.model`. New `embedding_math.dart` centralizes the float32-LE codec
  (`encodeEmbedding`/`decodeEmbedding`, round-trippable) + `cosineSimilarity`
  (zero-norm/length-guarded). Strictly additive — nothing calls these yet.
  analyze clean; 26 new tests (stub determinism/dim/L2-norm, codec round-trip,
  cosine, OpenAI batching + provider resolution), 184 pass.
- 2026-06-25 · M6.1 · drift migration v3 — the Phase-2 schema foundation
  (DESIGN.md §10), schema only, no behavior change (nothing reads the new
  tables yet). Adds the Project tier (`projects`) plus
  `propositions`/`entities`/`turn_entities`/`soft_edges`/`facts`/`fact_sources`,
  and three `conversations` columns (`project_id` default 'default',
  `index_state` default 0=notIndexed, `indexed_at`). Embedding columns are raw
  BLOB (float32 LE encoded later). v2→v3 is additive: creates the tables, adds
  the columns, seeds the single 'default' project, backfills every existing
  conversation to it, and the same indexes/seed run on `onCreate` so fresh and
  migrated DBs match. `propositions.text`/`facts.text` keep that SQL column name
  via `.named('text')` (getters `propText`/`factText` — drift reserves a bare
  `text` getter). schemaVersion 2→3. Hand-written migration test
  (`migration_v3_test.dart`) builds a populated v2 DB, upgrades it, and asserts
  new tables/columns, the default project, and survived+backfilled rows. analyze
  clean; 158 tests pass.
- 2026-06-25 · design · Phase 2 architecture (DESIGN.md §10) — design only,
  nothing built. Continuing a long, forked session retrieves context instead of
  walking the full ancestry: per-turn proposition index (≈5 atomic, coref-resolved
  embedded propositions + entities), hybrid retrieval (dense + existing `turns_fts`
  + boosted facts) with fork-aware scoring derived from `parent_turn_id`/
  `current_turn_id` (no new storage), soft edges, and a Layer-2 facts/decisions
  table (commit + supersede + provenance) that the future wiki is a view over.
  Index is project-scoped in shape but **lazily** populated on session open,
  active-path-first. Schema lands as drift migration v3 (Project tier, plus
  `propositions`/`entities`/`turn_entities`/`soft_edges`/`facts`/`fact_sources`);
  reuses the `LlmProvider` pattern for an `EmbeddingProvider`; swaps the
  full-ancestry send in `BranchService` for retrieval. Build order M6–M9. Open
  questions (extraction cost, contradiction UI, wiki read-only vs. editable,
  soft-edge recompute trigger, local vs. API embeddings) in DESIGN.md §12.
- 2026-06-21 · perf fix · read-mode lazy transcript. The reader rendered the
  whole turn eagerly (a `SingleChildScrollView` + Column of every response
  chunk), so paging to a long turn laid it all out at once — the arrow-key hitch
  in big conversations. The transcript is now a lazy `ListView` with the chunks
  flattened into it (`read_view.dart`), laying out only the on-screen chunks.
  Trace (same tall 4-section turns), eager → lazy: worst frame build 61 → 38 ms,
  UI GC 14 → 6 ms; steady-state ~2 ms. analyze clean; widget + chunk-toolbar +
  read-mode integration tests pass. (Also fixed a pre-existing chunk_toolbar_test
  bug — it didn't override `sharedPreferencesProvider`, so the fork path threw.
  reader_view_test fails identically on committed code — a macOS "Failed to
  foreground app" env flake — so unrelated to this change.)
- 2026-06-21 · perf fix · node-layer decouple (the big one). Edges + each card
  are built once behind a `RepaintBoundary` and passed as the `ListenableBuilder`
  child, so only the viewport `Transform` rebuilds per pan/zoom tick; culling is
  kept, with a half-viewport pre-build margin refreshed only when the view nears
  its edge. A pan is now a re-composite, not a rebuild+repaint. Trace (fitted
  ~440-node pan): worst frame build 51 → 7.7 ms, avg 12.8 → 2.5 ms, missed frames
  2/8 → 0/15, UI GC 22.9 → 0.4 ms; raster 1.3 ms. Subsumes the planned
  EdgePainter-isolation fix; the precompute-prompt-string fix is now deferred (GC
  already ~0). One culling widget-test updated for the pre-build margin; analyze
  clean, 156 tests pass.
- 2026-06-21 · perf fix 1/4 · Node cards no longer wrap in `Opacity(0.6)`; the
  off-path dim is folded into opaque colors (lerp toward the canvas backdrop) so
  there's no offscreen `saveLayer` per card. Trace (fitted ~440-node pan):
  `saveLayer`/paint 181 → 0, raster avg ~9 → 2.4 ms; analyze clean, 156 tests
  pass.
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
