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

- 2026-06-25 · M9.2 · generated read-only project wiki (DESIGN.md §10 "Project
  wiki … entities as hyperlinked pages, facts as content, `fact_sources` for
  click-through; topical clustering — topics cross branches"). **Data**:
  `WikiService` + `wikiServiceProvider` (`state/wiki.dart`, db + reuses
  `factsServiceProvider` for active-only facts). **Topical clustering is offline
  & deterministic**: connected components (union-find) over the project's
  `soft_edges` graph (semantic + entity + crossSession — REUSES M8.1, no
  k-means/LLM); turns linked by association land in one topic regardless of fork
  structure, which is the point. Determinism: edges fed in sorted order, the
  smaller root chosen as representative, components sorted size-desc then least
  turn id → same graph ⇒ same topics, same order. Components of ≥2 turns become
  topics; singletons stay in the all-entities/all-facts lists. `overview`
  (topics + entities-with-mention-counts + active facts, fact provenance
  pre-resolved), `entityPage` (Obsidian-style backlinks: the facts + proposition
  snippets + turns mentioning an entity), `entitiesForProject` (grouped
  `turn_entities` counts, stable order), `conversationOfTurn` for click-through.
  Providers `wikiOverviewProvider`/`entityPageProvider` (autoDispose.family).
  **UI** (`ui/wiki/wiki_view.dart`, read-only): `WikiScreen` full-screen route —
  overview (topics, all-entities index as hyperlinked chips, all-facts list;
  facts/props render via `gpt_markdown`) + per-entity page; entity chips
  navigate to entity pages; every fact/proposition carries an "open source turn"
  click-through. **Click-through reuses the existing reader/selection mechanism**
  (no new routing): tapping provenance publishes a `WikiNavRequest`
  (`wikiNavRequestProvider`), selects the turn's conversation, and pops to home;
  the matching `CanvasView` consumes the request post-frame via the existing
  `_enterRead(turnId)`, then clears it. **Entry points**: a sidebar app-bar
  "Project wiki" button (book icon) + a macOS **View ▸ Project Wiki…** menu item
  (⌘⇧K); both resolve the selected conversation's project (default 'default').
  Fully offline, no LLM prose (cluster-summaries deferred). analyze clean +
  **18 new tests** (14 data: clustering components/cross-branch/singletons/
  insertion-order-determinism/crossSession/topic-attachments, mention counts +
  ordering + project scope, entity backlinks, active-only facts excludes
  superseded, conversationOfTurn; 4 widget: overview renders topics+entities+
  facts, entity-chip → entity page, fact provenance click-through selects the
  source conversation + opens the reader, empty-wiki state); macOS-menu test
  updated for the new View menu. **291 tests** green. Visual verification
  deferred (project convention — goldens don't match macOS Impeller); the widget
  test is the gate.

- 2026-06-25 · M9.1 · commit action — promote text into the facts layer
  (DESIGN.md §10, Layer 2 "the keystone"). **Service**: `FactsService` +
  `factsServiceProvider` (`state/facts.dart`, depends on db + the offline-stub
  `embeddingProviderProvider`). `commitFact({text, sourceTurnIds, projectId,
  conversationId?, supersedesId?})` embeds the text (`encodeEmbedding`, no
  network), inserts an `active` fact (`status='active'`, `createdAt=now`,
  `conversationId` set = session-pinned, null = project-wide), and writes a
  `fact_sources` provenance row per source turn — all in **one transaction**.
  **Supersession**: when `supersedesId` is given, the prior fact flips to
  `superseded` and the new one chains its `supersedesId` to it. Query helpers
  for M9.2/M9.3 to reuse: `activeFactsForProject` / `activeFactsForConversation`
  (both exclude superseded; the conversation form returns session-pinned +
  project-wide) and `factSources(factId)`. **UI**: a **Commit as a fact**
  action (`ChunkAction.commit`, push-pin icon) added to the read-mode per-chunk
  toolbar in `ui/read_view.dart` alongside Ask/Explain/Expand/Copy; tapping it
  commits the chunk sourced from the focused turn (projectId + conversationId
  resolved from the turn's conversation) with a SnackBar ack, mirroring Copy's
  feedback. Supersession via the UI is deferred — a plain commit — but the
  **service** fully supports and tests it. Committed active facts already feed
  the retrieval boost (M8.2 reads `facts WHERE status='active'`); a test asserts
  a committed fact rides into the assembled context tagged `committed` and that
  superseding it removes it. analyze clean + **7 new tests** (6 service incl.
  embed round-trip / provenance / supersession-excludes / retrieval-integration,
  1 widget: the toolbar shows Commit and committing writes a sourced fact row).
  Visual verification deferred (project convention — goldens don't match macOS
  Impeller); the widget test is the gate.

- 2026-06-25 · M8.3 · soft-edge canvas layer (DESIGN.md §10 "Soft edges":
  "rendered as a canvas layer") — visualizes the precomputed `soft_edges` (M8.1),
  toggleable and **default off**. **Provider**:
  `softEdgesForConversationProvider` (FutureProvider.autoDispose.family by
  conversationId, `state/providers.dart`) — one-shot read of `soft_edges`
  keeping only the **renderable intra-conversation** edges (both endpoints turns
  in this conversation; `crossSession` and any dangling/out-of-conversation
  endpoint dropped — cross-canvas rendering is M9.3). **Painter**:
  `SoftEdgePainter` (`ui/canvas/soft_edge_painter.dart`) maps each edge's
  `from/toTurnId` to its two `GridCell` centres and draws a **bowed, dashed
  quadratic arc** (perpendicular control point, bow ∝ span, capped) so it reads
  as an associative link between distant cells, deliberately distinct from the
  solid structural edges. Visual encoding: **kind → colour** (semantic =
  `scheme.tertiary`, entity = `scheme.secondary`), **weight → alpha + width**
  (faint band `α 0.18–0.60`, width `1.2–3.0`) so it stays a faint overlay that
  never obscures card text. **Layer placement**: in `_buildNodeLayer`
  (`canvas_view.dart`) a `RepaintBoundary`+`CustomPaint` **just above the
  structural `EdgePainter`, below the node cards** — same decoupled-layer perf
  pattern (built once into the `ListenableBuilder` child, not rebuilt/repainted
  per pan/zoom tick; same `_builtCull` rect; painter culls edges outside the
  inflated visible rect, `shouldRepaint` only on layout/edges/cull/colour). **No
  `Opacity`** — color alpha only (prior perf fix preserved). **Toggle**:
  `SoftEdgesToggle` (graph-only, folded into the bottom-right controls cluster
  above the view switcher); state in ephemeral `showSoftEdgesProvider`
  (NotifierProvider<bool>, default false, no drift migration). **When off the
  layer does no work** — the edges provider isn't even watched/read. Fully
  offline (DB-only). **Tests** (+18: provider filtering incl. out-of-conv /
  dangling / crossSession exclusion; painter culling + missing-endpoint skip +
  `shouldRepaint`; widget tests for default-off, toggle on/off carrying the 2
  renderable edges, RepaintBoundary structure, graph-only toggle). `flutter
  analyze` clean; `flutter test` 266 green. **Real-backend visual verification
  deferred** — per project convention flutter_test/goldens don't match real
  macOS Impeller; a widget test is the gate, a release-build screenshot pass is
  deferred.

- 2026-06-25 · M8.2 · retrieval-assembled context replaces full-ancestry in
  `BranchService` (DESIGN.md §10) — the central Phase-2 behavioral change.
  **Query rewrite (step 1)**: `QueryRewriter` (`data/llm/query_rewriter.dart`),
  stub/LLM pattern. `StubQueryRewriter` = deterministic — augments the prompt
  with salient terms from the last turn (coref carry-over) and emits
  augmented+bare as multi-query; `LlmQueryRewriter` asks for a small JSON array,
  robust-parsed like `LlmPropositionExtractor`, **falls back to the bare prompt**
  (never throws). **Hybrid retrieval (step 2)** in `ContextAssembler`
  (`state/retrieval.dart`): dense (brute-force cosine of the query vectors vs
  `propositions.embedding`, best per turn) + sparse (`searchTurnIds` FTS,
  rank-derived similarity `0.9/(1+rank·0.5)`) + facts (cosine vs active
  `facts.embedding`, `+0.1` boost, surfaced via `fact_sources` as committed
  candidates carrying the fact text); union dedup by turn, capped at a
  `candidatePoolSize=40`. **Scope** param `{branch|session|project|all}`, default
  **project** (index is project-scoped; full toggle UI is M9.3). **Fork-aware
  scoring (step 3)**: pure `scoreCandidate(ScoringSignals, RetrievalWeights)` =
  `α·sim + β·recency + γ·branchProx + ε·committed − δ·divergedSibling`
  (α1.0/β0.3/γ0.3/ε0.25/δ0.4). recency = linear decay vs the current turn;
  branchProximity from `parent_turn_id` + `current_turn_id` (1 on active lineage
  / parent ancestry, `1/(1+hops)` decay, 0 cross-conversation) — no new storage;
  diverged-sibling = off both active lineage and parent ancestry within the
  conversation (soft penalty, never excluded). In the no-fork linear case
  branchProximity ≈ recency (noted in code). **MMR (step 4)**: pure `mmrSelect`,
  λ default **0.7**, redundancy = cosine of the candidates' proposition vectors;
  λ=1 pure relevance, λ=0 pure diversity. **Assembly (step 5)**: persona +
  **last 1–2 turns verbatim** (also the rewriter's input) + MMR-selected items
  (propositions expanded to their turn; a turn already in the tail is never
  re-surfaced) + the new prompt; each item tagged `{branch=conversationId,
  committed?}` in a synthesized **preamble**. **Tags reach the model without
  breaking the interface**: `LlmProvider.generate` gained an OPTIONAL
  `String? preamble` (default null) — `OpenAiCompatibleProvider` sends it as a
  second `system` message after the persona, `StubLlmProvider` ignores it; every
  existing call site is unaffected. **Swap**: `BranchService._stream` now runs
  the assembler (wired via `contextAssemblerProvider`/`queryRewriterProvider`)
  and sends `context: verbatim, preamble: tags` instead of `_ancestors(parent)`;
  the assembler is an OPTIONAL ctor dep, so a directly-constructed service still
  falls back to the v1 full-ancestry send. Offline-safe & deterministic under
  the stub embedder + FTS. Test reconciliation: the two provider-container
  branch tests now also override `sharedPreferencesProvider` (the assembler
  reads the LLM/embedding config) — they assert generating-state/failure, not
  ancestry, so unchanged in intent; `passes the root→parent context path`
  constructs the service WITHOUT an assembler and still asserts the fallback
  ancestry, so it stays as-is. Interface-required signature updates to test
  `LlmProvider` fakes (added `preamble`). analyze clean + 24 new tests (251
  total): rewriter determinism/JSON-parse, scoring per-term + weight tuning, MMR
  diversify/λ-extremes, retrieval union-dedup + scope filter, assembly
  verbatim/tags/no-dup/facts, and a stub-provider BranchService integration
  asserting verbatim tail (not full ancestry) + tagged preamble.
- 2026-06-25 · M8.1 · soft-edge precompute (DESIGN.md §10) — semantic k-NN over
  proposition embeddings + entity-overlap edges. `SoftEdgeComputer`
  (`state/soft_edges.dart`).`recomputeForConversation(id, {semanticK=5,
  semanticThreshold=0.5})` scopes to one conversation's turns. **Semantic**:
  turn-to-turn similarity = **max cosine over the cross-product** of the two
  turns' proposition vectors ("related at all" — survives multi-topic turns where
  a centroid dilutes); keeps each turn's **top-k** neighbours **≥ threshold**,
  unioning both directed nominations. **Entity**: turns sharing ≥1 entity (via
  `turn_entities`), weight = **Jaccard** of entity sets. Both canonicalized
  `from<to` (string compare), no self-edges; a pair qualifying as both stores two
  rows (distinct `kind`). **Idempotent**: deletes the semantic/entity edges
  incident to this conversation's turns before reinserting, in one transaction —
  re-open recomputes without dupes; `crossSession` rows untouched (M9.3). Chained
  off indexing: `triggerIndexOnOpen` now runs `recomputeForConversation` after
  `ensureIndexed` resolves (`softEdgeComputerProvider`, db-only so offline-safe),
  same fire-and-forget/test-no-op guards as M7. O(turns²) within one conversation
  only. Tests inject hand-crafted embedding BLOBs (stub vectors aren't
  semantic) — assert math/top-k/threshold/canonicalization/idempotency + an
  ensureIndexed→recompute integration. analyze clean + 12 tests (227 total).
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
