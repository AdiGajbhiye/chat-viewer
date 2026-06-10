/// Builders for synthetic ChatGPT-export JSON used across tests.
library;

import 'dart:convert';
import 'dart:io';

/// A valid 1×1 transparent PNG — the fixture asset's bytes, so M5 image
/// rendering can actually decode what the importer copied.
const kTinyPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
];

/// A mapping node. [message] may be null (e.g. the synthetic root).
Map<String, dynamic> node(
  String id, {
  String? parent,
  Map<String, dynamic>? message,
}) =>
    {'id': id, 'parent': parent, 'children': null, 'message': message};

Map<String, dynamic> message(
  String id, {
  required String role,
  String contentType = 'text',
  List<Object?> parts = const [],
  Map<String, dynamic>? content,
  double? time,
  String? modelSlug,
}) =>
    {
      'id': id,
      'author': {'role': role},
      'create_time': time,
      'content': content ?? {'content_type': contentType, 'parts': parts},
      'metadata': {'model_slug': ?modelSlug},
    };

Map<String, dynamic> imagePart(
  String pointer, {
  int width = 100,
  int height = 50,
}) =>
    {
      'content_type': 'image_asset_pointer',
      'asset_pointer': pointer,
      'width': width,
      'height': height,
    };

Map<String, dynamic> conversation({
  required String id,
  String title = 'untitled',
  double? createTime,
  double? updateTime,
  String? currentNode,
  bool isArchived = false,
  bool? isStarred,
  String? defaultModelSlug,
  required List<Map<String, dynamic>> nodes,
}) =>
    {
      'id': id,
      'conversation_id': id,
      'title': title,
      'create_time': createTime,
      'update_time': updateTime,
      'current_node': currentNode,
      'is_archived': isArchived,
      'is_starred': isStarred,
      'default_model_slug': defaultModelSlug,
      'mapping': {for (final n in nodes) n['id'] as String: n},
    };

/// Linear conversation with thoughts/recap, a multimodal turn referencing
/// [presentPointer] and [missingPointer], and an unknown content type.
Map<String, dynamic> linearConversation({
  String id = 'conv-linear',
  String presentPointer = 'sediment://file_present',
  String missingPointer = 'sediment://file_gone',
}) =>
    conversation(
      id: id,
      title: 'Linear chat',
      createTime: 1700000000.5,
      updateTime: 1700000400.5,
      currentNode: 'a3',
      defaultModelSlug: 'gpt-4o',
      nodes: [
        node('root'),
        node('u1',
            parent: 'root',
            message: message('u1',
                role: 'user',
                parts: ['hello quantum entanglement'],
                time: 1700000000.5)),
        node('a1',
            parent: 'u1',
            message: message('a1',
                role: 'assistant',
                content: {
                  'content_type': 'thoughts',
                  'thoughts': [
                    {'summary': 'Pondering', 'content': 'deep thought trace'},
                  ],
                },
                time: 1700000001,
                modelSlug: 'o4-mini')),
        node('a2',
            parent: 'a1',
            message: message('a2',
                role: 'assistant',
                content: {
                  'content_type': 'reasoning_recap',
                  'content': 'Thought for 3 seconds',
                },
                time: 1700000002,
                modelSlug: 'o4-mini')),
        node('a3',
            parent: 'a2',
            message: message('a3',
                role: 'assistant',
                parts: ['spooky action at a distance'],
                time: 1700000003,
                modelSlug: 'o4-mini')),
        node('u2',
            parent: 'a3',
            message: message('u2',
                role: 'user',
                contentType: 'multimodal_text',
                parts: [
                  'look at these',
                  imagePart(presentPointer),
                  imagePart(missingPointer, width: 7, height: 9),
                ],
                time: 1700000100)),
        node('a4',
            parent: 'u2',
            message: message('a4',
                role: 'assistant',
                parts: ['nice images'],
                time: 1700000101,
                modelSlug: 'gpt-4o')),
        node('u3',
            parent: 'a4',
            message: message('u3',
                role: 'user',
                content: {'content_type': 'mystery_widget', 'data': 42},
                time: 1700000200)),
        node('a5',
            parent: 'u3',
            message: message('a5',
                role: 'assistant',
                parts: ['placeholder ack'],
                time: 1700000201,
                modelSlug: 'gpt-4o')),
      ],
    );

/// Conversation with a mid-turn fork (regenerated response at f-u1) and a
/// prompt fork (edited prompt under f-a2).
///
/// Node ids are prefixed `f-` because `turns.id` is a global primary key
/// (real exports use UUIDs).
Map<String, dynamic> forkedConversation({String id = 'conv-forked'}) =>
    conversation(
      id: id,
      title: 'Forked chat',
      createTime: 1710000000,
      updateTime: 1710000900,
      currentNode: 'f-u3b',
      nodes: [
        node('f-root'),
        node('f-u1',
            parent: 'f-root',
            message: message('f-u1',
                role: 'user', parts: ['regenerate me'], time: 1710000000)),
        node('f-a1',
            parent: 'f-u1',
            message: message('f-a1',
                role: 'assistant',
                parts: ['first answer'],
                time: 1710000001,
                modelSlug: 'gpt-4o')),
        node('f-a2',
            parent: 'f-u1',
            message: message('f-a2',
                role: 'assistant',
                parts: ['second answer'],
                time: 1710000002,
                modelSlug: 'gpt-4o')),
        node('f-u2',
            parent: 'f-a1',
            message: message('f-u2',
                role: 'user', parts: ['follow up'], time: 1710000100)),
        node('f-u3a',
            parent: 'f-a2',
            message: message('f-u3a',
                role: 'user', parts: ['edited v1'], time: 1710000200)),
        node('f-u3b',
            parent: 'f-a2',
            message: message('f-u3b',
                role: 'user', parts: ['edited v2'], time: 1710000300)),
      ],
    );

/// Conversation whose first content node is an assistant message, preceded
/// by a system message and a blank user message (both transparent).
Map<String, dynamic> assistantRootConversation({String id = 'conv-aroot'}) =>
    conversation(
      id: id,
      title: 'Assistant first',
      updateTime: 1720000000,
      nodes: [
        node('ar-root'),
        node('ar-sys',
            parent: 'ar-root',
            message: message('ar-sys', role: 'system', parts: ['context'])),
        node('ar-blank',
            parent: 'ar-sys',
            message: message('ar-blank', role: 'user', parts: [''])),
        node('ar-a1',
            parent: 'ar-blank',
            message: message('ar-a1',
                role: 'assistant',
                parts: ['I speak first'],
                time: 1720000001,
                modelSlug: 'gpt-4o')),
      ],
    );

/// Writes a complete synthetic export (manifest, one shard, asset name map,
/// one `.dat` asset) into [dir].
Future<void> writeSyntheticExport(
  Directory dir, {
  List<Map<String, dynamic>>? conversations,
}) async {
  await dir.create(recursive: true);
  final convs = conversations ??
      [linearConversation(), forkedConversation(), assistantRootConversation()];
  File('${dir.path}/conversations-000.json')
      .writeAsStringSync(jsonEncode(convs));
  File('${dir.path}/export_manifest.json').writeAsStringSync(jsonEncode({
    'logical_files': {
      'conversations.json': {
        'files': ['conversations-000.json'],
        'sharded': true,
      },
    },
    'version': 1,
  }));
  File('${dir.path}/conversation_asset_file_names.json')
      .writeAsStringSync(jsonEncode({'file_present.dat': 'pic.png'}));
  File('${dir.path}/file_present.dat').writeAsBytesSync(kTinyPngBytes);
}
