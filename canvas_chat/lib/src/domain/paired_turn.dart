/// Output of the turn-pairing algorithm (DESIGN.md §2): one canvas node.
class PairedTurn {
  PairedTurn({
    required this.id,
    required this.parentTurnId,
    required this.promptMd,
    required this.responseMd,
    required this.thoughtsMd,
    required this.modelSlug,
    required this.createTime,
    required this.assets,
    required this.rawNodes,
  });

  /// Id of the turn's starting message node (the user prompt node, or the
  /// first assistant node for prompt-less turns).
  final String id;

  /// Parent turn in the turn tree; null for root turns.
  final String? parentTurnId;

  final String promptMd;
  final String responseMd;

  /// Folded `thoughts` / `reasoning_recap` content, if any.
  final String? thoughtsMd;

  final String? modelSlug;

  /// Seconds since epoch (export native unit); null when absent.
  final double? createTime;

  final List<TurnAssetRef> assets;

  /// The original mapping nodes absorbed by this turn, in chain order, for
  /// lossless re-derivation (`raw_json` column).
  final List<Map<String, dynamic>> rawNodes;

  PairedTurn copyWith({String? promptMd, List<TurnAssetRef>? assets}) =>
      PairedTurn(
        id: id,
        parentTurnId: parentTurnId,
        promptMd: promptMd ?? this.promptMd,
        responseMd: responseMd,
        thoughtsMd: thoughtsMd,
        modelSlug: modelSlug,
        createTime: createTime,
        assets: assets ?? this.assets,
        rawNodes: rawNodes,
      );
}

/// Reference to an asset (image upload/generation) used by a turn.
class TurnAssetRef {
  TurnAssetRef({
    required this.kind,
    required this.pointerId,
    required this.width,
    required this.height,
  });

  /// 'prompt' or 'response' (which side of the turn referenced it).
  final String kind;

  /// `asset_pointer` with its scheme stripped, e.g. `file-abc` or
  /// `file_0000…` — matches `<pointerId>.dat` in the export.
  final String pointerId;

  final int? width;
  final int? height;
}

/// Result of pairing one conversation.
class PairedConversation {
  PairedConversation({
    required this.turns,
    required this.currentTurnId,
    required this.messageCount,
    required this.warnings,
  });

  final List<PairedTurn> turns;

  /// Turn containing the export's `current_node`, if resolvable.
  final String? currentTurnId;

  /// Number of message-bearing mapping nodes seen (for import accounting).
  final int messageCount;

  final List<String> warnings;
}
