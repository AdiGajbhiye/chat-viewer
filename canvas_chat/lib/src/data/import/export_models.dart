/// Thin typed wrappers over the raw ChatGPT export JSON.
///
/// The export format is unversioned and changes over time, so these wrappers
/// are deliberately tolerant: every accessor null-checks, unknown fields are
/// preserved in [raw], and nothing here throws on missing data.
library;

double? _asDouble(Object? v) => switch (v) {
      num n => n.toDouble(),
      _ => null,
    };

/// One conversation object from a `conversations-*.json` shard.
class ExportConversation {
  ExportConversation(this.raw);

  final Map<String, dynamic> raw;

  String get id => (raw['id'] ?? raw['conversation_id'] ?? '') as String;
  String get title => (raw['title'] as String?) ?? '';
  double? get createTime => _asDouble(raw['create_time']);
  double? get updateTime => _asDouble(raw['update_time']);
  String? get currentNode => raw['current_node'] as String?;
  bool get isArchived => raw['is_archived'] == true;
  bool get isStarred => raw['is_starred'] == true;
  String? get defaultModelSlug => raw['default_model_slug'] as String?;

  Map<String, ExportNode> get mapping {
    final m = raw['mapping'];
    if (m is! Map) return const {};
    return {
      for (final e in m.entries)
        if (e.value is Map)
          e.key as String:
              ExportNode((e.value as Map).cast<String, dynamic>()),
    };
  }
}

/// One node in a conversation's `mapping` tree.
class ExportNode {
  ExportNode(this.raw);

  final Map<String, dynamic> raw;

  String get id => (raw['id'] as String?) ?? '';
  String? get parentId => raw['parent'] as String?;
  ExportMessage? get message {
    final m = raw['message'];
    if (m is! Map) return null;
    return ExportMessage(m.cast<String, dynamic>());
  }
}

/// The `message` payload of a mapping node.
class ExportMessage {
  ExportMessage(this.raw);

  final Map<String, dynamic> raw;

  String get id => (raw['id'] as String?) ?? '';

  String get role {
    final author = raw['author'];
    if (author is Map) return (author['role'] as String?) ?? '';
    return '';
  }

  double? get createTime => _asDouble(raw['create_time']);

  Map<String, dynamic> get content {
    final c = raw['content'];
    if (c is! Map) return const {};
    return c.cast<String, dynamic>();
  }

  String get contentType => (content['content_type'] as String?) ?? '';

  Map<String, dynamic> get metadata {
    final m = raw['metadata'];
    if (m is! Map) return const {};
    return m.cast<String, dynamic>();
  }

  String? get modelSlug => metadata['model_slug'] as String?;
}
