# Canvas Chat — Design Doc

A Flutter app that visualizes ChatGPT conversation history as a node graph on a
pannable/zoomable canvas, instead of a linear chat transcript.

**Status:** Draft v3 · 2026-06-25
**Platforms:** Android, macOS (Flutter desktop)
**Project location:** `canvas_chat/` in this folder (export data in `chatgpt_data/` stays as test fixture)
**Scope for v1:** Viewer-only. Import the official ChatGPT data export and explore
it on canvas. No live LLM chat yet (the architecture must not preclude it — see
[Future work](#9-future-work)).
**Phase 2 (built · M6–M9):** evolves the viewer into a research / exploration
workspace — retrieval-assembled context for continuing long, forked sessions, a
curated facts/decisions layer, and a generated project wiki. See §10.

---

## 1. Concept

### Node = one turn

A **node** on the canvas is a single *turn*: one user prompt plus the assistant
response(s) to it. A linear conversation renders as a vertical chain of turn-nodes
connected by edges. When a prompt was edited or a response regenerated, the parent
node has multiple children — the chain forks into a new column.

### Views

A conversation has two views, switched by an icons-only toggle pinned
bottom-right (graph · read) that stays visible in both. The graph is the
backdrop; the reader floats over it as an inset card (no pushed route), so a
margin of canvas stays visible around the reader and the toggle stays put. The
current view is remembered per conversation in `canvas_state.mode`, but the
reader is never *auto-restored* — opening a conversation always lands on the
graph.

- **Graph mode** — the broad canvas (the map). Nodes are collapsed to just the
  user query, laid out on a fixed grid (rows = turn order, columns = branch
  lanes), so the shape of the conversation and its forks is visible at a glance.
- **Read mode** — the conversation as a full-screen pager, one turn at a time:
  full prompt + response markdown, collapsible reasoning. ↑/↓ (arrows, buttons,
  or a vertical swipe past the transcript edge) page parent/child along the
  branch; ←/→ (arrows, buttons, or a horizontal swipe) page across branches at
  the same depth, with a directional slide and a "branch i of n" breadcrumb. A
  turn taller than the screen scrolls; only an edge overscroll pages, so reading
  never fights paging. The axes never mix — no diagonal paging.

Tapping a node (or the bottom-right **read** toggle) opens the reader on that
turn; the **graph** toggle (or Esc) drops back to the graph centered on the
turn just read. The focused turn is shared, so switching views keeps your place.

```
 NAVIGATE (grid of collapsed nodes)         READ (one node maximized)
 lane 0          lane 1                  ┌──────────────────────────────┐
 ┌────────────┐                          │            ⑂ 1/2   ↑ ↓ ← →   │
 │"explain X" │                          ├──────────────────────────────┤
 │            │                          │ ▸ "shorter pls"              │
 └─────┬──────┘                          │──────────────────────────────│
 ┌─────┴──────┐  ┌────────────┐          │ Sure — X in one line:        │
 │"shorter pls│──│"compare X  │          │ X is …                       │
 └─────┬──────┘  │ with Y"    │          │                              │
 ┌─────┴──────┐  └────────────┘          │ ```code …```                 │
 │"thanks, now│                          │ (scrolls)            [▣ ☰]   │
 │ apply to…" │                          │                              │
 └────────────┘                          └──────────────────────────────┘
```

A node card is just the user query and a meta line; tapping it opens read mode.
The read header carries the branch breadcrumb/counter and the **go to node
above / below / left / right** arrows (move the reading focus). The view toggle
(**▣ graph · ☰ read**) is pinned bottom-right in both views.

### One canvas per conversation

The app opens to a sidebar listing all imported conversations (title, date,
search). Selecting one opens its canvas. With ~1,600 conversations averaging
~8 messages each, a per-conversation canvas stays readable without
clustering/level-of-detail heroics; a "show everything" universe view is
explicitly out of scope for v1.

### Goals

- Import the full ChatGPT export (sharded `conversations-*.json` + assets) losslessly.
- Make edit/regeneration branches — invisible in ChatGPT's UI — a first-class visual.
- Smooth pan/zoom on a mid-range Android phone and on macOS.
- Fully offline and private: no network access in v1 at all.

### Non-goals (v1)

- Live chatting, API keys, any LLM calls.
- Sync between devices; each device imports the export itself.
- Editing message content; canvas layout (node positions) is the only mutable state.
- Importing other formats (Claude exports, OpenAI API logs…) — keep the importer
  pluggable but build only the ChatGPT-export adapter.

---

## 2. Source data (what we're importing)

Verified against the real export in `chatgpt_data/` (87 MB, created 2026-06-09):

| Input | Content |
|---|---|
| `conversations-000…015.json` | 16 shards, one logical array of 1,594 conversation objects, 12,185 messages, 2023-05 → 2026-06 |
| `file-*.dat`, `file_0000…*.dat` | 47 assets: PNG/JPEG images, 1 PDF, 1 text file (extension stripped to `.dat`) |
| `conversation_asset_file_names.json` | `.dat` name → original filename |
| `export_manifest.json` | shard list; use it to discover shards instead of hardcoding names |
| `user.json`, `user_settings.json`, `shared_conversations.json`, `library_files.json`, `chat.html` | ignored in v1 |

Conversation structure (fields we consume):

```
Conversation { id, title, create_time, update_time, current_node,
               is_archived, is_starred, default_model_slug,
               mapping: { node_id: { id, parent, message? } } }

message.author.role   ∈ { user, assistant }            (in this export)
message.content.content_type ∈
    text             (11,861)  parts: [String]
    multimodal_text  (68)      parts: [String | image_asset_pointer{asset_pointer, width, height, …}]
    thoughts         (142)     reasoning traces
    reasoning_recap  (114)     one-line reasoning summary
message.metadata: model_slug, parent_id, attachments, …
```

Importer hardening (the export format is unversioned and changes over time):

- Nodes carry only `parent` pointers — build a children index, find roots
  (nodes whose parent is missing/system root), then traverse.
- Tolerate unknown `content_type`s (render a "unsupported content" placeholder,
  keep the raw JSON), unknown roles (e.g. `tool`/`system` appear in other
  people's exports), and missing/null timestamps.
- `current_node` marks the branch ChatGPT displayed last — use it to highlight
  the "active" path on canvas.

### Turn-pairing algorithm

The export is a tree of *messages*; the canvas wants a tree of *turns*.

1. Build children index; walk depth-first from the root.
2. A turn starts at a `user` message and absorbs the contiguous descendant chain
   of `assistant` messages (`thoughts` and `reasoning_recap` fold into the turn
   as collapsible extras; the final `text`/`multimodal_text` message is the
   turn's response).
3. The next `user` descendant starts a child turn.
4. Forks. A node with N>1 *response* (assistant) children is a regenerated
   response: the prompt is folded into each branch, yielding N complete
   sibling turns (same prompt, differing response) that share the prompt's
   parent — no prompt-only or response-only cells. A node with N>1 *user*
   children is an edited prompt: each child already pairs into a full turn,
   and they become siblings. Either way the alternatives are siblings,
   drawn side by side and joined by a horizontal sibling edge (§6).
5. Degenerate cases: leading system/blank nodes are skipped; an assistant
   message with no user parent (rare) becomes a one-sided turn with an empty
   prompt — these genuine one-sided cells are rendered as-is.

The pairing is deterministic and recomputable, so we persist *turns* and can
re-derive them from raw data if the algorithm improves (see `raw_json` below).

---

## 3. Architecture

```
┌────────────────────────────────────────────────────────┐
│ UI (Flutter)                                           │
│   ConversationList │ CanvasView │ NodeCard │ Minimap   │
├────────────────────────────────────────────────────────┤
│ State (Riverpod)                                       │
│   importController · canvasController(viewport,        │
│   selection, layout) · conversationProviders           │
├────────────────────────────────────────────────────────┤
│ Domain                                                 │
│   Turn graph model · layout engine · turn-pairing      │
├────────────────────────────────────────────────────────┤
│ Data                                                   │
│   drift/SQLite · asset store (app dir) · importer      │
│   (isolate) · [future: LlmProvider interface]          │
└────────────────────────────────────────────────────────┘
```

- **State management:** Riverpod. Canvas interaction state (viewport transform,
  drag) lives in plain `ValueNotifier`s/`ChangeNotifier` inside the canvas widget
  for 60 fps updates; Riverpod holds document-level state.
- **Everything heavy off the UI thread:** import parsing, turn pairing, and
  initial layout run in isolates.

---

## 4. Storage

SQLite via **drift** (type-safe, isolate-friendly, works on Android + macOS).
Assets are copied into the app documents dir (`assets/<file_id>` with original
extension restored); DB stores paths, not blobs.

```sql
conversations(
  id TEXT PK,            -- export conversation id
  title TEXT, create_time INT, update_time INT,
  is_archived BOOL, is_starred BOOL,
  default_model_slug TEXT,
  current_turn_id TEXT,  -- derived from current_node
  source TEXT            -- 'chatgpt_export' (importer plugin id)
)

turns(
  id TEXT PK,            -- id of the turn's user message node
  conversation_id TEXT FK,
  parent_turn_id TEXT NULL,        -- tree edge; NULL = root turn
  prompt_md TEXT, response_md TEXT,
  thoughts_md TEXT NULL,           -- collapsed reasoning, if any
  model_slug TEXT NULL,
  create_time INT,
  raw_json TEXT          -- original message nodes, for lossless re-derivation
)

turn_assets(turn_id FK, kind TEXT/*prompt|response*/, path TEXT,
            original_name TEXT, width INT, height INT)

canvas_state(conversation_id PK, viewport_json TEXT,
             mode TEXT,             -- 'navigate' | 'read'
             focused_turn_id TEXT)  -- resume where the user left off

imports(id PK, started_at, finished_at, source_path,
        conversations INT, turns INT, warnings_json TEXT)
```

Indexes on `turns(conversation_id)` and FTS5 table over
`turns(prompt_md, response_md)` for search.

Re-import policy: matching `conversation.id`s are replaced (export is the source
of truth for content); `canvas_state` survives when its `focused_turn_id` still
exists. Grid positions are never stored — layout is a pure function of the turn
tree, recomputed on open.

---

## 5. Import pipeline

1. User picks the export **zip or extracted folder** (`file_picker`;
   on Android also accept content-URIs).
2. Isolate: read `export_manifest.json` → shard list; parse shards one at a
   time (each ≤ ~6 MB, fine to `jsonDecode` whole; never hold all 16 decoded
   at once).
3. Per conversation: build message tree → run turn pairing → batch-insert.
4. Copy referenced assets; resolve `asset_pointer` → `.dat` file → original
   name/extension via `conversation_asset_file_names.json`. Missing assets get a
   placeholder record, not a failure.
5. Stream progress to UI (x/1594, warnings list). Import is resumable-by-rerun:
   it's idempotent per conversation.

Target: full 87 MB import in well under a minute on a phone.

---

## 6. Canvas

### Grid layout

Conversations are basically linear with occasional forks, so nodes sit on a
fixed grid — no free-form positioning, no force-directed layout:

- **Row = turn order** (depth in the turn tree). **Column = branch lane.**
- Lane assignment, git-graph style: walk the active path (derived from
  `current_node`) first — it occupies lane 0, one row per turn. At a fork, each
  additional child branch claims the nearest free lane to the right, starting
  at its fork row; the whole branch continues downward in that lane.
- Collapsed nodes are **uniform size** (fixed width × height), so cell → pixel
  mapping is trivial and layout is a pure function of the tree: deterministic,
  recomputed on open, never persisted.
- Edges: a vertical line within a lane connects a turn to the child that
  continues it; a horizontal sibling edge across a row joins a fork's
  alternatives (the vertical edge runs only into the active branch). Active
  path emphasized, other lanes dimmed.

The grid also gives navigation exact semantics: **above/below** = parent/child
in the same lane (following the edge), **left/right** = the node in the
adjacent lane nearest to the current row (sibling branches).

### Navigate mode

- All nodes collapsed: the card shows the user query (first ~2 lines) only.
- Pan (drag / two-finger scroll), zoom (pinch / Cmd+scroll), double-tap or `f`
  to fit. Viewport-culled: only visible cells build widgets.
- Minimap (bottom-right, desktop always / mobile on-zoom) painted from grid
  cells — cheap because layout is just cells.
- Tap a node → read mode for that node (or the bottom-right **read** toggle
  opens it on the current selection).

### Read mode

- The focused node maximized: full prompt + full response, scrollable, with
  markdown, LaTeX, syntax-highlighted code (copy button), and images.
  `thoughts`/`reasoning_recap` behind a 🧠 toggle. The transcript keeps a
  comfortable reading width (capped + centered) on a wide pane.
- An inset card floating over the graph (same on every platform), not a pushed
  route — so the map stays visible around it and the bottom-right toggle stays
  put. Tapping the exposed canvas (or the graph toggle / Esc) returns to the map.
- The read header carries the branch breadcrumb/counter and the reading-focus
  arrows; **↑/↓** walk the conversation like a transcript (this *is* the linear
  reading experience — no separate transcript view needed), **←/→** jump across
  branches at the same depth.
- The **graph** toggle (or Esc) returns to the graph centered on the node just
  read.
- Arrow keys mirror the header arrows; a vertical swipe past the transcript edge
  pages up/down and a horizontal swipe pages across branches (all platforms).

### Node card

```
  navigate mode card (uniform size)
┌──────────────────────────────┐
│ ▸ user query, max 8 lines…   │
│                              │
│ ⏱ Mar 12 · ◇ gpt-4o · ⑂2    │   meta: time, model, fork count
└──────────────────────────────┘
```

- The card is just the user query (the assistant reply is read mode only) plus
  the meta line. It carries no buttons: tapping the card enters read mode, and
  selection moves via arrow keys / tapping cells.
- Exactly **two node states**: collapsed card (navigate) and maximized (read
  mode). No in-between "preview" size — the grid stays uniform.
- Markdown via `gpt_markdown` (handles ChatGPT-flavored markdown + LaTeX well;
  fallback `flutter_markdown` if it disappoints).

### Rendering approach

Custom canvas, not a package:

- Pan/zoom via `Listener` + `GestureDetector` driving a `Matrix4`
  (programmatic viewport control needed for minimap, center-on-node, and the
  navigate↔read transition, which `InteractiveViewer` makes awkward).
- Edges in a single `CustomPainter` below the node layer.
- Nodes are real widgets positioned by a `CustomMultiChildLayout`-style
  delegate using the grid; uniform cells make culling exact.
- Read mode is an inset card layered over the graph in a `Stack` (no pushed
  route), behind a faint tap-to-dismiss scrim, so the map stays visible around
  it and keeps its viewport; the graph is focus-excluded while reading so arrow
  keys reach the reader. Within the reader, turns slide directionally as the
  focus pages.

Evaluated alternatives: `graphview` (layout too rigid), flutter_flow-style node
editors (free-form, wrong model). A fixed grid + two modes is small enough to
own.

### Performance

The canvas is **redraw-on-tick**: pan, zoom and the nav-glide all call
`CanvasViewport.notifyListeners()` → the `ListenableBuilder` around
`_buildCanvas()` rebuilds *and* repaints the whole node layer every frame (no
`RepaintBoundary` anywhere), so cost scales with visible-card count — which is
what makes a large, fitted graph stutter.

Profiled on real macOS/Impeller (debug frame times are meaningless) with the
harness at `integration_test/perf_pan_test.dart` + `test_driver/perf_driver.dart`
(`flutter drive --profile --driver=test_driver/perf_driver.dart
--target=integration_test/perf_pan_test.dart -d macos` →
`build/perf/*.timeline_summary.json`). Panning a ~440-node graph fitted to ~180
cards is **UI-thread (build) bound**:

- Frame build worst **51 ms** (≈20 fps), 2 of 8 frames over the 16 ms budget,
  plus 22.9 ms of GC.
- **~1,378 `Dart_StringToUTF8`/paint** — each `NodeCard` re-runs the
  `_collapseWhitespace(stripChatMarkers(promptMd))` RegExp and re-shapes its
  text every frame though nothing changed (`node_card.dart`).
- **~181 `Canvas::saveLayer`/paint** — the `Opacity(0.6)` dim per off-path card;
  cheap at fit-zoom but `saveLayer` cost grows with pixel area at normal zoom.

Fixes, by impact (✓ = landed):

1. ✓ Build the node layer once and pass it as the `ListenableBuilder` child, so
   only the viewport `Transform` rebuilds per tick; each card and the edge
   painter sit behind a `RepaintBoundary`, and the cull keeps a half-viewport
   pre-build margin (refreshed only when the view nears its edge). A pan now
   re-composites instead of rebuild+repaint — **worst frame build 51 → 7.7 ms,
   avg 12.8 → 2.5 ms, missed frames 2/8 → 0/15, UI GC 22.9 → 0.4 ms**.
2. ✓ Drop `Opacity`, folding the dim into the card colors — removes the per-card
   offscreen layer: `saveLayer`/paint 181 → 0, raster avg ~9 → 1.3 ms.
3. (deferred) Precompute the collapsed prompt string off the frame path — now
   low-value: decoupling already cut per-frame UI GC to ~0, so the per-frame
   regex no longer matters; worth doing only for code clarity.
4. ✓ Isolate `EdgePainter` behind a `RepaintBoundary` with a stable cull rect
   (folded into fix 1) — it no longer repaints during a pan.

**Read mode** has a separate per-navigation cost: paging to a turn lays out its
incoming markdown. The transcript is a lazy `ListView` (`read_view.dart`) with
the response chunks flattened into it, so a long turn lays out only its on-screen
chunks instead of the whole thing up front. Same-data trace on tall (4-section)
turns, eager → lazy: worst frame build 61 → 38 ms, UI GC 14 → 6 ms (the residual
first-open spike is one-time engine/font warmup).

### Sidebar / home

- Conversation list: virtualized, sorted by `update_time`, FTS search over
  titles + content, star/archive filters (data already in export).
- macOS: persistent `NavigationSplitView`-style two-pane. Android: list is the
  home screen, canvas is a pushed route.

---

## 7. Platform specifics

| Concern | Android | macOS |
|---|---|---|
| File pick | SAF content-URI; copy zip to cache before reading | sandboxed open panel; needs `com.apple.security.files.user-selected.read-only` entitlement |
| Input | touch: pinch/drag, long-press = node menu | trackpad pinch + scroll, hover states, keyboard shortcuts, right-click menu |
| Window | single activity | resizable; restore window + last conversation |
| Min versions | API 24+ | macOS 12+ |

Flutter 3.3x stable, Material 3, one codebase, platform checks only at the
input/file-access seams listed above.

---

## 8. Packages (proposed)

| Need | Package |
|---|---|
| DB | `drift` + `sqlite3_flutter_libs` |
| State | `flutter_riverpod` |
| Markdown | `gpt_markdown` (fallback `flutter_markdown`) |
| File picking | `file_picker` |
| Zip | `archive` (stream from zip without full extraction) |
| Code highlighting | `flutter_highlight` |
| Paths | `path_provider` |

No canvas/graph package — custom, per §6.

---

## 9. Future work (designed-for, not built)

- **Live chat / retrieval-assembled context:** `LlmProvider` interface
  (`sendTurn(List<Turn> path) → Stream<Delta>`); forking = start a new child turn
  from any node. Sending the full root-path as context is the v1 stub — Phase 2
  replaces it with retrieval (§10). OpenAI-API-key provider first.
- **Multi-provider** (Anthropic, Ollama) behind the same interface; `source`
  column already namespaces imported vs. authored content.
- **Cross-conversation / cross-session:** retrieval and the project wiki span
  sessions within a Project (§10); a Project tier above Conversation replaces the
  earlier "curated boards" sketch.
- **Sync:** the DB is the unit of sync; file-based sync (synced folder) before
  any backend.
- **Other importers:** Claude export adapter behind the same importer interface.

## 10. Phase 2 — Retrieval & the design-doc layer

Phase 2 turns the viewer into a **research / exploration workspace**: you keep
working a long, heavily-forked session and the app distills it into a condensed,
high-signal design doc. The existing turn graph, importer and storage stay as-is.
Built and shipped as milestones M6–M9 (see PROGRESS.md); the new UI is verified on
the real macOS/Impeller engine (`integration_test/phase2_visual_test.dart`).

The driving constraint: continuing a long session can't fit the whole history in
the context window — and for a drifting, multi-topic research conversation the
full root→parent path isn't even the *right* context. The graph edges encode turn
*order*, not *topic*; topic is latent. So context is **retrieved**, not walked.
Frequent forks are assumed the norm (the real export already has them).

### Two layers

- **Layer 1 — raw conversation graph** (built): every turn, messy, branching,
  exploratory. The source of truth for *what was said*.
- **Layer 2 — committed facts / decisions** (new): canonical statements a user
  *commits* from a turn, each with provenance back to its source turn(s) and a
  `supersedes` link. The source of truth for *what was decided*.

Layer 2 is the keystone — three planned features collapse into it: the **commit**
action writes it; retrieval **boosts** it (authoritative, and supersession fixes
"latest decision vs. most-similar match"); the **wiki** is a view over it.

### Context assembly (replaces the full-ancestry send in `BranchService`)

`BranchService` today sends the full root→parent path to `LlmProvider.generate`.
Phase 2 swaps that one call site for a retrieval-assembled context:

1. **Rewrite** the new prompt into a standalone query using the last 1–2 turns
   (coref resolution — "make that faster" → "optimize the k-NN query"). This is
   load-bearing: drift makes follow-ups content-free, so raw-prompt retrieval
   fails exactly when it's needed. The "few query prompts" idea lives here as
   multi-query expansion.
2. **Retrieve** hybrid: dense (proposition embeddings) + sparse (the existing
   `turns_fts` FTS5 — free) + facts (boosted). Scope filter = branch | session |
   project | all.
3. **Score** = α·similarity + β·recency + γ·branch-proximity + ε·committed-boost
   − δ·diverged-sibling. Branch terms derive from `parent_turn_id` +
   `current_turn_id` (same inputs as the grid) — no new storage. In the no-fork
   linear case branch-proximity ≈ recency; it only adds signal once forks exist.
4. **Assemble**: persona + last 1–2 turns verbatim + retrieved items (MMR-deduped,
   propositions expanded to their turns) + the new prompt. Each retrieved item is
   **tagged {branch, committed?}** so the model separates tentative cross-branch
   claims from settled ones — exploration produces contradictions ("Postgres" in
   one branch, "SQLite" in another) and flat context would silently merge them.

There is **no hard ancestor inclusion** — only the last 1–2 turns are kept
verbatim (for flow and as the rewriter's input); everything else earns its place
by retrieval.

### Proposition index (per turn, multi-representation)

Indexing a turn yields ~5 **atomic, standalone, coref-resolved propositions**
(each meaningful out of context), not one summary. The win is granularity: a turn
touching three topics produces three separately-retrievable vectors, so a query
about topic #2 matches even when #1/#3 dominate — which is exactly what serves the
"explores several topics at once" case. Each proposition carries an **open-vocab
aspect tag** (not fixed buckets like eng/biz/mktg — those don't generalize),
entities and keywords. Generate with a little parent context so isolated nodes
("yes, do that") don't summarize to noise. Retrieve on propositions, expand to the
full turn ("small-to-big").

### Soft edges

Precomputed at index time, persisted, rendered as a canvas layer:

- **semantic** — k-NN over proposition embeddings (top-k + threshold, not O(n²)).
- **entity** — turns sharing entities (interpretable; also the wiki's backbone).
- **crossSession** — the same machinery across the session boundary.

Symmetric; stored once canonicalized `from < to`. Query-time relevance is the same
mechanism with the live query as the probe.

### Project scope + lazy indexing

The index is **project-scoped in shape** (a new Project tier above Conversation;
everything carries `project_id`, so retrieval can range across the project) but
**lazily populated** — indexing the whole export up front is too costly. On
**session open**, enqueue indexing for that conversation if not already indexed;
the job walks its turns **active-path-first** (retrieval works before the whole
session finishes), batching extraction + embedding calls.
`conversations.index_state` drives the machine (notIndexed → indexing → indexed →
stale); re-embed only when the embedding model changes.

Consequences to design around:
- **Cross-session retrieval only sees already-opened sessions** until an idle-time
  background backfill exists. Don't market project search as "your whole project"
  before then.
- **First open of a long session has a cost / latency spike** (one extraction call
  per turn, batched). Active-path-first + an on-canvas indexing indicator hides
  most of it.

### Schema additions (drift migration v3)

New tables + columns; reuses FTS5 (sparse retrieval) and clones the `LlmProvider`
pattern for an `EmbeddingProvider`.

```sql
projects(id PK, name, created_at)
-- conversations: + project_id (FK, default 'default'),
--                + index_state INT, + indexed_at INT

propositions(
  id PK, turn_id FK, conversation_id, project_id,   -- ids denormalized for scope filter
  text, aspect TEXT NULL,                           -- open-vocab tag
  embedding BLOB, embedding_model TEXT)             -- float32[]; model id for re-embed invalidation

entities(id PK, project_id, name, normalized)
turn_entities(entity_id FK, turn_id FK)             -- m:n → entity edges + wiki backlinks

soft_edges(from_turn_id, to_turn_id, kind TEXT,     -- 'semantic'|'entity'|'crossSession'
           weight REAL, project_id)                 -- symmetric, from < to

facts(                                              -- Layer 2
  id PK, project_id, conversation_id NULL,          -- NULL conv = project-wide; set = pinned to a session
  text, status TEXT,                                -- 'active'|'superseded'
  supersedes_id NULL, embedding BLOB, created_at)
fact_sources(fact_id FK, turn_id FK)                -- provenance → wiki drill-down
```

Vectors: store as BLOB, brute-force cosine in Dart for v1 — lazy indexing keeps
the working set (opened sessions) small enough. Move to `sqlite-vec` only when a
project outgrows memory.

### Deferred UI over this schema (no further migrations)

- **Commit action** — promote a proposition / selected span into `facts` +
  `fact_sources`.
- **Project wiki** (Notion / Obsidian-style) — entities as hyperlinked pages,
  facts as content, `fact_sources` for click-through to the source turn;
  connective prose via GraphRAG-style *topical* clustering (topics cross branches
  — don't cluster by fork structure). Generated read-only first; any edits flow
  back as commits.
- **Cross-session scope toggle** + the idle-time index backfill.

## 11. Milestones

1. **M1 Import:** parser + turn pairing + drift schema; CLI-ish debug screen
   showing imported counts. Golden tests against the real export (1,594 convs,
   12,185 msgs, all 4 content types, asset resolution).
2. **M2 Read:** conversation list + a bare read mode (full turn view with
   ↑/↓ only) — proves the data layer before taking on canvas risk.
3. **M3 Navigate mode:** grid/lane layout, collapsed node cards with
   quick-button strip, edges, active-path highlight, pan/zoom, selection +
   arrow navigation, minimap.
4. **M4 Read mode:** maximized node view, ↑↓←→ traversal with branch
   breadcrumb, navigate↔read transition, persisted mode/focus/viewport.
5. **M5 Polish:** FTS search, images/PDF assets, macOS shortcuts + menus,
   Android back/deep-link to conversation, import warnings UI.

### Phase 2 (done — shipped as M6.1–M9.3; see PROGRESS.md)

6. **M6 Index foundation:** drift migration v3 (Project tier + new tables);
   `EmbeddingProvider` interface beside `LlmProvider`; proposition + entity
   extraction. No behavior change — schema + services only.
7. **M7 Lazy indexer:** index-on-open, active-path-first, on-canvas progress, the
   `index_state` machine.
8. **M8 Retrieval:** query rewrite → hybrid + fork-aware retrieval → context
   assembly, swapped into `BranchService`; soft-edge precompute + canvas layer.
9. **M9 Facts & wiki:** commit action over `facts`/`fact_sources`; generated
   project wiki; cross-session scope + backfill.

## 12. Open questions

- Branch density: does this account's history actually contain many forks?
  (Worth measuring during M1 — it determines how often lanes ≥ 1 appear and
  how much the ←/→ buttons get used.)
- Long conversations in navigate mode: with uniform cells, a 200-turn chat is
  a very tall lane — is plain scrolling enough, or do we need a jump-to-row
  scrubber? Decide after M3 dogfooding.
- `thoughts` content: render verbatim (can be long) or only `reasoning_recap`?

### Phase 2

- Proposition extraction is an LLM call per turn — cost/quality vs. batching, and
  whether a smaller/local model suffices for extraction + embedding.
- Surfacing cross-branch contradictions in the UI (the tag is in context; what
  does the *user* see?).
- Wiki: generated-read-only vs. editable-flows-back-as-commits — decide before M9.
- When to (re)compute soft edges: on each new turn, on session close, or on commit?
- Embedding backend: bundle a local model vs. require an API key — the latter
  breaks the fully-offline promise, so make it opt-in per project.
