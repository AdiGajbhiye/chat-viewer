import 'package:canvas_chat/src/data/import/export_models.dart';
import 'package:canvas_chat/src/domain/paired_turn.dart';
import 'package:canvas_chat/src/domain/turn_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/synthetic_export.dart';

PairedTurn turnById(PairedConversation paired, String id) =>
    paired.turns.singleWhere((t) => t.id == id);

void main() {
  group('linear conversation', () {
    final paired = pairTurns(ExportConversation(linearConversation()));

    test('produces a chain of three turns', () {
      expect(paired.turns.map((t) => t.id), ['u1', 'u2', 'u3']);
      expect(turnById(paired, 'u1').parentTurnId, isNull);
      expect(turnById(paired, 'u2').parentTurnId, 'u1');
      expect(turnById(paired, 'u3').parentTurnId, 'u2');
    });

    test('counts all message-bearing nodes', () {
      expect(paired.messageCount, 8);
    });

    test('folds thoughts and reasoning_recap into thoughtsMd', () {
      final turn = turnById(paired, 'u1');
      expect(turn.promptMd, 'hello quantum entanglement');
      expect(turn.responseMd, 'spooky action at a distance');
      expect(turn.thoughtsMd, contains('Pondering'));
      expect(turn.thoughtsMd, contains('deep thought trace'));
      expect(turn.thoughtsMd, contains('Thought for 3 seconds'));
      expect(turn.modelSlug, 'o4-mini');
    });

    test('multimodal turn collects asset refs and markers', () {
      final turn = turnById(paired, 'u2');
      expect(turn.promptMd, contains('look at these'));
      expect(turn.promptMd, contains('![image](asset://file_present)'));
      expect(turn.assets, hasLength(2));
      expect(
        turn.assets.map((a) => a.pointerId),
        containsAll(['file_present', 'file_gone']),
      );
      expect(turn.assets.every((a) => a.kind == 'prompt'), isTrue);
      final missing =
          turn.assets.singleWhere((a) => a.pointerId == 'file_gone');
      expect(missing.width, 7);
      expect(missing.height, 9);
    });

    test('unknown content type becomes a placeholder and a warning', () {
      final turn = turnById(paired, 'u3');
      expect(turn.promptMd, '*[unsupported content: mystery_widget]*');
      expect(
        paired.warnings,
        anyElement(contains('mystery_widget')),
      );
    });

    test('current_node resolves to the turn that absorbed it', () {
      // current_node a3 is the response tail of turn u1.
      expect(paired.currentTurnId, 'u1');
    });

    test('raw nodes are preserved per turn', () {
      expect(
        turnById(paired, 'u1').rawNodes.map((n) => n['id']),
        ['u1', 'a1', 'a2', 'a3'],
      );
    });
  });

  group('forks', () {
    final paired = pairTurns(ExportConversation(forkedConversation()));

    test('regenerated-response fork folds the prompt into full sibling turns',
        () {
      // The shared prompt node (f-u1) is dissolved — no prompt-only cell.
      expect(paired.turns.any((t) => t.id == 'f-u1'), isFalse);
      final a1 = turnById(paired, 'f-a1');
      final a2 = turnById(paired, 'f-a2');
      // Each branch carries the duplicated prompt + its own response.
      expect(a1.promptMd, 'regenerate me');
      expect(a1.responseMd, 'first answer');
      expect(a2.promptMd, 'regenerate me');
      expect(a2.responseMd, 'second answer');
      // Siblings: they share the prompt's parent (here the root → null).
      expect(a1.parentTurnId, isNull);
      expect(a2.parentTurnId, isNull);
    });

    test('folded branch keeps both prompt and response raw nodes', () {
      expect(
        turnById(paired, 'f-a1').rawNodes.map((n) => n['id']),
        ['f-u1', 'f-a1'],
      );
    });

    test('regen siblings take the response create_time for ordering', () {
      expect(turnById(paired, 'f-a1').createTime, 1710000001);
      expect(turnById(paired, 'f-a2').createTime, 1710000002);
    });

    test('edited prompt produces sibling child turns', () {
      final edits =
          paired.turns.where((t) => t.parentTurnId == 'f-a2').toList();
      expect(edits.map((t) => t.id), ['f-u3a', 'f-u3b']);
    });

    test('follow-up under one regeneration chains normally', () {
      expect(turnById(paired, 'f-u2').parentTurnId, 'f-a1');
    });

    test('current_node on a leaf maps to its own turn', () {
      expect(paired.currentTurnId, 'f-u3b');
    });
  });

  group('degenerate cases', () {
    test('leading system/blank nodes are skipped; assistant-first turn has '
        'an empty prompt', () {
      final paired =
          pairTurns(ExportConversation(assistantRootConversation()));
      expect(paired.turns, hasLength(1));
      final turn = paired.turns.single;
      expect(turn.id, 'ar-a1');
      expect(turn.parentTurnId, isNull);
      expect(turn.promptMd, isEmpty);
      expect(turn.responseMd, 'I speak first');
    });

    test('empty mapping yields no turns', () {
      final paired = pairTurns(
        ExportConversation(conversation(id: 'empty', nodes: [node('root')])),
      );
      expect(paired.turns, isEmpty);
      expect(paired.messageCount, 0);
    });
  });
}
