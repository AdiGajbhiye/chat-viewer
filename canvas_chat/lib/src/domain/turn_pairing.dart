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
/// 4. A node with N>1 children produces N child turns (fork), whether the
///    fork is mid-turn (regenerated response) or at the prompt (edited
///    prompt).
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

  // Skips transparent nodes, then starts a turn (rule 5). Declared as a
  // `late` variable because it is mutually recursive with `buildTurn`.
  late final void Function(ExportNode node, String? parentTurnId) descend;

  // Builds the turn starting at [start]; recurses into child turns.
  void buildTurn(ExportNode start, String? parentTurnId) {
    final promptParts = <String>[];
    final responseParts = <String>[];
    final thoughtParts = <String>[];
    final assets = <TurnAssetRef>[];
    final rawNodes = <Map<String, dynamic>>[];
    String? modelSlug;
    double? createTime;

    void consume(ExportNode node) {
      rawNodes.add(node.raw);
      turnIdOfNode[node.id] = start.id;
      final m = node.message;
      if (m == null) return;
      createTime ??= m.createTime;
      final isPromptSide = m.role == 'user';
      if (!isPromptSide) modelSlug ??= m.modelSlug;
      final rendered = render(m, node.id);
      if (rendered.isThought) {
        if (rendered.text.isNotEmpty) thoughtParts.add(rendered.text);
      } else if (rendered.text.isNotEmpty) {
        (isPromptSide ? promptParts : responseParts).add(rendered.text);
      }
      for (final a in rendered.assets) {
        assets.add(
          TurnAssetRef(
            kind: isPromptSide ? 'prompt' : 'response',
            pointerId: a.pointerId,
            width: a.width,
            height: a.height,
          ),
        );
      }
    }

    consume(start);

    // 2. Absorb the contiguous single-child chain of non-user messages.
    var cur = start;
    while (true) {
      final kids = children(cur);
      if (kids.length != 1) break;
      final next = kids.single;
      final m = next.message;
      if (m != null && m.role == 'user' && !isTransparent(next)) {
        break; // rule 3: next user descendant starts a child turn
      }
      consume(next);
      cur = next;
    }

    turns.add(
      PairedTurn(
        id: start.id,
        parentTurnId: parentTurnId,
        promptMd: promptParts.join('\n\n'),
        responseMd: responseParts.join('\n\n'),
        thoughtsMd: thoughtParts.isEmpty ? null : thoughtParts.join('\n\n'),
        modelSlug: modelSlug,
        createTime: createTime,
        assets: assets,
        rawNodes: rawNodes,
      ),
    );

    // 4. Every child of the chain tail begins a child turn (or is descended
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
