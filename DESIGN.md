# Canvas Chat — Design Doc

A Flutter app that visualizes ChatGPT conversation history as a node graph on a
pannable/zoomable canvas, instead of a linear chat transcript.

**Status:** Draft v2 · 2026-06-10
**Platforms:** Android, macOS (Flutter desktop)
**Project location:** `canvas_chat/` in this folder (export data in `chatgpt_data/` stays as test fixture)
**Scope for v1:** Viewer-only. Import the official ChatGPT data export and explore
it on canvas. No live LLM chat yet (the architecture must not preclude it — see
[Future work](#9-future-work)).

---

## 1. Concept

### Node = one turn

A **node** on the canvas is a single *turn*: one user prompt plus the assistant
response(s) to it. A linear conversation renders as a vertical chain of turn-nodes
connected by edges. When a prompt was edited or a response regenerated, the parent
node has multiple children — the chain forks into a new column.

### Two modes

The UI has exactly two modes per conversation:

- **Navigate mode** — the broad canvas. Nodes are collapsed to just the user
  query, laid out on a fixed grid (rows = turn order, columns = branch lanes),
  so the shape of the conversation and its forks is visible at a glance.
- **Read mode** — one node maximized: the full prompt and response, scrollable,
  with markdown/images/code. Arrow buttons move focus to the adjacent node
  while staying in read mode; minimizing drops back to navigate mode centered
  on that node.

```
 NAVIGATE (grid of collapsed nodes)         READ (one node maximized)
 lane 0          lane 1                  ┌──────────────────────────────┐
 ┌────────────┐                          │ ⊖ ⊕   ↑ ↓ ← →               │
 │⊖⊕ ↑↓←→     │                          ├──────────────────────────────┤
 │"explain X" │                          │ ▸ "shorter pls"              │
 └─────┬──────┘                          │──────────────────────────────│
 ┌─────┴──────┐  ┌────────────┐          │ Sure — X in one line:        │
 │"shorter pls│──│"compare X  │          │ X is …                       │
 └─────┬──────┘  │ with Y"    │          │                              │
 ┌─────┴──────┐  └────────────┘          │ ```code …```                 │
 │"thanks, now│                          │ (scrolls)                    │
 │ apply to…" │                          │                              │
 └────────────┘                          └──────────────────────────────┘
```

Every node shows a quick-button strip on top: **minimize**, **maximize**
(enter read mode), and **go to node above / below / left / right** (grid
navigation).

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
4. A message node with N>1 children produces N child turns → a fork.
   Forks can occur mid-turn (regenerated response) or at the prompt
   (edited prompt); both render the same way: multiple outgoing edges.
5. Degenerate cases: leading system/blank nodes are skipped; an assistant
   message with no user parent (rare) becomes a turn with an empty prompt.

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
- Edges: vertical line within a lane; rounded elbow into the fork's lane.
  Active path emphasized, other lanes dimmed.

The grid also gives navigation exact semantics: **above/below** = parent/child
in the same lane (following the edge), **left/right** = the node in the
adjacent lane nearest to the current row (sibling branches).

### Navigate mode

- All nodes collapsed: the card shows the user query (first ~2 lines) only.
- Pan (drag / two-finger scroll), zoom (pinch / Cmd+scroll), double-tap or `f`
  to fit. Viewport-culled: only visible cells build widgets.
- Minimap (bottom-right, desktop always / mobile on-zoom) painted from grid
  cells — cheap because layout is just cells.
- Tap a node (or its **maximize** button) → read mode for that node.

### Read mode

- The focused node maximized: full prompt + full response, scrollable, with
  markdown, LaTeX, syntax-highlighted code (copy button), and images.
  `thoughts`/`reasoning_recap` behind a 🧠 toggle.
- Presentation is platform-specific: **full-screen route on Android** (phones
  need every pixel), **centered overlay (~85%) over the dimmed canvas on
  macOS** (desktop keeps spatial context).
- The quick-button strip stays on top; **↑/↓** walk the conversation like a
  transcript (this *is* the linear reading experience — no separate transcript
  view needed), **←/→** jump across branches at the same depth, with a brief
  breadcrumb showing which branch you're on.
- **Minimize** (or Esc / back) returns to navigate mode with the canvas
  centered on the node just read.
- macOS: arrow keys mirror the buttons; Android: swipe up/down also advances.

### Node card & quick buttons

```
  navigate mode card (uniform size)
┌──────────────────────────────┐
│ ⊖ ⊕            ↑ ↓ ← →      │   quick-button strip
│──────────────────────────────│
│ ▸ user query, max 2 lines…   │
│ ⏱ Mar 12 · ◇ gpt-4o · ⑂2    │   meta: time, model, fork count
└──────────────────────────────┘
```

- Quick-button strip (both modes): **⊖ minimize** · **⊕ maximize** ·
  **↑ ↓ ← →** go to neighbor. Buttons for nonexistent neighbors are disabled.
  In navigate mode the arrows move the *selection* (and scroll it into view);
  in read mode they move the *reading focus*.
- Exactly **two node states**: collapsed card (navigate) and maximized (read
  mode). Maximize on a collapsed card enters read mode; minimize is a no-op in
  navigate mode (shown disabled) and exits read mode. No in-between
  "preview" size — the grid stays uniform.
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
- Read mode is a route with a hero-style transition from the cell (full-screen
  page on Android, overlay dialog on macOS); the canvas underneath keeps its
  viewport.

Evaluated alternatives: `graphview` (layout too rigid), flutter_flow-style node
editors (free-form, wrong model). A fixed grid + two modes is small enough to
own.

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

- **Live chat:** `LlmProvider` interface (`sendTurn(List<Turn> path) → Stream<Delta>`);
  forking = start a new child turn from any node and send its root-path as
  context. OpenAI-API-key provider first. The turn tree already models this; only
  a `pending` turn state and a composer UI are missing.
- **Multi-provider** (Anthropic, Ollama) behind the same interface; `source`
  column already namespaces imported vs. authored content.
- **Cross-conversation canvases:** user-curated boards referencing turns from
  multiple conversations (`canvas` table + membership table).
- **Sync:** the DB is the unit of sync; file-based sync (synced folder) before
  any backend.
- **Other importers:** Claude export adapter behind the same importer interface.

## 10. Milestones

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

## 11. Open questions

- Branch density: does this account's history actually contain many forks?
  (Worth measuring during M1 — it determines how often lanes ≥ 1 appear and
  how much the ←/→ buttons get used.)
- Long conversations in navigate mode: with uniform cells, a 200-turn chat is
  a very tall lane — is plain scrolling enough, or do we need a jump-to-row
  scrubber? Decide after M3 dogfooding.
- `thoughts` content: render verbatim (can be long) or only `reasoning_recap`?
