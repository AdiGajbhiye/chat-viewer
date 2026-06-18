import '../data/import/export_models.dart';
import 'paired_turn.dart';

/// Turn-pairing algorithm (DESIGN.md §2): converts the export's tree of
/// *messages* into a tree of *turns*.
///
/// Rules implemented:
/// 1. Children index is built from `parent` pointers (the export's own
///    `children` arrays may be null); siblings are ordered by message
///    `create_time`, then id, for determinism.
/// 2. A turn starts at a `user` message and absorbs the contiguous descendant
///    chain of assistant messages. `thoughts`/`reasoning_recap` fold into
///    `thoughtsMd`; `text`/`multimodal_text` assistant messages form the
///    response (multiple ones are concatenated so nothing is lost).
/// 3. The next `user` descendant starts a child turn.
/// 4. Forks. A node with N>1 *response* (assistant) children is a
///    regenerated-response fork: the prompt is folded into each branch,
///    yielding N complete sibling turns (same prompt, differing response)
///    that share the prompt's parent — so no prompt-only or response-only
///    cells are produced. A node with N>1 *user* children is an
///    edited-prompt fork: each child already pairs into a full turn, and
///    they become siblings.
/// 5. System/blank nodes are transparent; an assistant message that does not
///    follow a user prompt becomes a turn with an empty prompt.
PairedConversation pairTurns(ExportConversation conversation) {
  final mapping = conversation.mapping;
  final warnings = <String>[];
  var messageCount = 0;
  for (final node in mapping.values) {
    if (node.message != null) messageCount++;
  }

  // 1. Children index from parent pointers; deterministic sibling order.
  final childrenOf = <String, List<ExportNode>>{};
  final roots = <ExportNode>[];
  for (final node in mapping.values) {
    final parent = node.parentId;
    if (parent == null || !mapping.containsKey(parent)) {
      roots.add(node);
    } else {
      (childrenOf[parent] ??= []).add(node);
    }
  }
  int order(ExportNode a, ExportNode b) {
    final ta = a.message?.createTime;
    final tb = b.message?.createTime;
    if (ta != null && tb != null && ta != tb) return ta.compareTo(tb);
    if (ta == null && tb != null) return 1;
    if (ta != null && tb == null) return -1;
    return a.id.compareTo(b.id);
  }

  for (final children in childrenOf.values) {
    children.sort(order);
  }
  roots.sort(order);

  List<ExportNode> children(ExportNode n) => childrenOf[n.id] ?? const [];

  final turns = <PairedTurn>[];
  final turnIdOfNode = <String, String>{};

  // Render each message once (warnings are appended on first render only).
  final renderCache = <String, _RenderedContent>{};
  _RenderedContent render(ExportMessage m, String nodeId) =>
      renderCache[nodeId] ??= _renderContent(m, warnings, conversation.id);

  bool isTransparent(ExportNode node) {
    final m = node.message;
    if (m == null) return true;
    if (m.role == 'system') return true;
    final rendered = render(m, node.id);
    return rendered.text.isEmpty && rendered.assets.isEmpty;
  }

  // Appends [node]'s rendered content to [acc] and records node → turn.
  void consumeInto(ExportNode node, _Acc acc, String turnId) {
    acc.rawNodes.add(node.raw);
    turnIdOfNode[node.id] = turnId;
    final m = node.message;
    if (m == null) return;
    acc.createTime ??= m.createTime;
    final isPromptSide = m.role == 'user';
    if (!isPromptSide) acc.modelSlug ??= m.modelSlug;
    final rendered = render(m, node.id);
    if (rendered.isThought) {
      if (rendered.text.isNotEmpty) acc.thoughtParts.add(rendered.text);
    } else if (rendered.text.isNotEmpty) {
      (isPromptSide ? acc.promptParts : acc.responseParts).add(rendered.text);
    }
    for (final a in rendered.assets) {
      acc.assets.add(
        TurnAssetRef(
          kind: isPromptSide ? 'prompt' : 'response',
          pointerId: a.pointerId,
          width: a.width,
          height: a.height,
        ),
      );
    }
  }

  // Consumes [start] and its contiguous single-child chain of non-user
  // messages into [acc] under [turnId], recording consumed ids in [consumed].
  // Returns the tail node (stops at a fork or the next user message, rule 3).
  ExportNode absorbChain(
    ExportNode start,
    _Acc acc,
    String turnId,
    List<String> consumed,
  ) {
    consumeInto(start, acc, turnId);
    consumed.add(start.id);
    var cur = start;
    while (true) {
      final kids = children(cur);
      if (kids.length != 1) break;
      final next = kids.single;
      final m = next.message;
      if (m != null && m.role == 'user' && !isTransparent(next)) break;
      consumeInto(next, acc, turnId);
      consumed.add(next.id);
      cur = next;
    }
    return cur;
  }

  void addTurn(_Acc acc, String id, String? parentTurnId) {
    turns.add(
      PairedTurn(
        id: id,
        parentTurnId: parentTurnId,
        promptMd: acc.promptParts.join('\n\n'),
        responseMd: acc.responseParts.join('\n\n'),
        thoughtsMd:
            acc.thoughtParts.isEmpty ? null : acc.thoughtParts.join('\n\n'),
        modelSlug: acc.modelSlug,
        createTime: acc.createTime,
        assets: acc.assets,
        rawNodes: acc.rawNodes,
      ),
    );
  }

  // Skips transparent nodes, then starts a turn (rule 5). Declared `late`
  // because it is mutually recursive with [buildTurn].
  late final void Function(ExportNode node, String? parentTurnId) descend;

  // Builds the turn starting at [start]; recurses into child turns. When
  // [inherited] is given (a folded regenerated-response branch), its prompt
  // and any response prefix seed this turn so the branch is a complete cell
  // carrying the shared prompt — even through nested forks.
  void buildTurn(ExportNode start, String? parentTurnId, [_Acc? inherited]) {
    final acc = inherited?.clone() ?? _Acc();
    // A folded branch takes the response's create_time for active-path
    // ordering; the shared prompt time would tie regen siblings.
    if (inherited != null) {
      acc.createTime = start.message?.createTime ?? acc.createTime;
    }
    final prefixIds = <String>[];
    // 2. Absorb the prompt + its contiguous single-child response chain.
    final cur = absorbChain(start, acc, start.id, prefixIds);

    final responseForks = children(cur)
        .where((k) => !isTransparent(k) && k.message?.role != 'user')
        .toList();

    // 4. Response (assistant) branches at the tail: fold the prompt — and any
    // response prefix absorbed so far — into each branch, so every cell is a
    // complete prompt+response with no prompt-only/response-only halves. ≥2
    // branches are regenerated responses → full sibling turns sharing
    // [parentTurnId]; a single branch (its siblings being transparent/user
    // nodes that broke the absorb chain) just pulls the response into this
    // turn. The recursive call carries the prompt down through nested forks.
    // Remaining children (follow-up prompts, transparent nodes) hang off the
    // displayed (latest) branch.
    if (responseForks.isNotEmpty) {
      final responseForkIds = {for (final b in responseForks) b.id};
      // Children are pre-sorted; the latest branch is displayed, so the
      // dissolved prompt node resolves there for current_node.
      final activeId = responseForks.last.id;
      for (final id in prefixIds) {
        turnIdOfNode[id] = activeId;
      }
      for (final branch in responseForks) {
        buildTurn(branch, parentTurnId, acc);
      }
      for (final kid in children(cur)) {
        if (!responseForkIds.contains(kid.id)) descend(kid, activeId);
      }
      return;
    }

    addTurn(acc, start.id, parentTurnId);
    // Every child of the chain tail begins a child turn (or is descended
    // through, if transparent).
    for (final kid in children(cur)) {
      descend(kid, start.id);
    }
  }

  descend = (ExportNode node, String? parentTurnId) {
    if (isTransparent(node)) {
      turnIdOfNode[node.id] = parentTurnId ?? '';
      for (final kid in children(node)) {
        descend(kid, parentTurnId);
      }
      return;
    }
    buildTurn(node, parentTurnId);
  };

  for (final root in roots) {
    descend(root, null);
  }

  // Backfill any response-only cell (empty prompt) the fold couldn't reach —
  // regen continuations buried behind transparent nodes at a deep fork — by
  // inheriting the nearest prompt-bearing ancestor's prompt (and prompt-side
  // assets). Genuine orphans (assistant chains with no prompt upstream) keep
  // their empty prompt and render one-sided.
  final turnById = {for (final t in turns) t.id: t};
  for (var i = 0; i < turns.length; i++) {
    final t = turns[i];
    if (t.promptMd.isNotEmpty) continue;
    final seen = <String>{t.id};
    var anc = t.parentTurnId == null ? null : turnById[t.parentTurnId];
    while (anc != null && anc.promptMd.isEmpty && seen.add(anc.id)) {
      anc = anc.parentTurnId == null ? null : turnById[anc.parentTurnId];
    }
    if (anc == null || anc.promptMd.isEmpty) continue;
    turns[i] = t.copyWith(
      promptMd: anc.promptMd,
      assets: [...anc.assets.where((a) => a.kind == 'prompt'), ...t.assets],
    );
  }

  String? currentTurnId;
  final currentNode = conversation.currentNode;
  if (currentNode != null) {
    final mapped = turnIdOfNode[currentNode];
    currentTurnId = (mapped != null && mapped.isNotEmpty) ? mapped : null;
  }

  return PairedConversation(
    turns: turns,
    currentTurnId: currentTurnId,
    messageCount: messageCount,
    warnings: warnings,
  );
}

/// Mutable accumulator for one turn's content during pairing. Cloned to share
/// a prompt prefix across regenerated-response sibling branches (rule 4).
class _Acc {
  final List<String> promptParts = [];
  final List<String> responseParts = [];
  final List<String> thoughtParts = [];
  final List<TurnAssetRef> assets = [];
  final List<Map<String, dynamic>> rawNodes = [];
  String? modelSlug;
  double? createTime;

  _Acc clone() => _Acc()
    ..promptParts.addAll(promptParts)
    ..responseParts.addAll(responseParts)
    ..thoughtParts.addAll(thoughtParts)
    ..assets.addAll(assets)
    ..rawNodes.addAll(rawNodes)
    ..modelSlug = modelSlug
    ..createTime = createTime;
}

class _RenderedContent {
  _RenderedContent(this.text, this.assets, {this.isThought = false});

  final String text;
  final List<TurnAssetRef> assets;

  /// True for `thoughts` / `reasoning_recap` content that folds into the
  /// turn's collapsible extras instead of the response.
  final bool isThought;
}

/// Strips the URI scheme from an `asset_pointer`
/// (`sediment://file_x`, `file-service://file-y` → `file_x`, `file-y`).
String assetPointerId(String pointer) {
  final i = pointer.indexOf('://');
  return i < 0 ? pointer : pointer.substring(i + 3);
}

_RenderedContent _renderContent(
  ExportMessage message,
  List<String> warnings,
  String conversationId,
) {
  final content = message.content;
  switch (message.contentType) {
    case 'text':
    case 'multimodal_text':
      final texts = <String>[];
      final assets = <TurnAssetRef>[];
      final parts = content['parts'];
      if (parts is List) {
        for (final part in parts) {
          if (part is String) {
            if (part.isNotEmpty) texts.add(part);
          } else if (part is Map) {
            final partType = part['content_type'] as String?;
            switch (partType) {
              case 'image_asset_pointer':
                final pointer = part['asset_pointer'] as String?;
                if (pointer == null || pointer.isEmpty) {
                  warnings.add(
                    '$conversationId: image part without asset_pointer',
                  );
                  break;
                }
                final id = assetPointerId(pointer);
                assets.add(
                  TurnAssetRef(
                    kind: 'response', // re-tagged by the caller per role
                    pointerId: id,
                    width: (part['width'] as num?)?.toInt(),
                    height: (part['height'] as num?)?.toInt(),
                  ),
                );
                texts.add('![image](asset://$id)');
              case 'audio_transcription':
                final t = part['text'] as String?;
                if (t != null && t.isNotEmpty) texts.add(t);
              default:
                texts.add('*[unsupported content: ${partType ?? 'unknown'}]*');
            }
          }
        }
      }
      return _RenderedContent(texts.join('\n\n'), assets);
    case 'thoughts':
      final pieces = <String>[];
      final thoughts = content['thoughts'];
      if (thoughts is List) {
        for (final t in thoughts) {
          if (t is! Map) continue;
          final summary = t['summary'] as String?;
          final body = t['content'] as String?;
          if (summary != null && summary.isNotEmpty) pieces.add('**$summary**');
          if (body != null && body.isNotEmpty) pieces.add(body);
        }
      }
      return _RenderedContent(pieces.join('\n\n'), const [], isThought: true);
    case 'reasoning_recap':
      final recap = content['content'] as String?;
      return _RenderedContent(recap ?? '', const [], isThought: true);
    default:
      // Unknown content type: placeholder text, raw JSON is kept in raw_json.
      warnings.add(
        '$conversationId: unsupported content_type '
        '"${message.contentType}" (message ${message.id})',
      );
      return _RenderedContent(
        '*[unsupported content: ${message.contentType}]*',
        const [],
      );
  }
}
