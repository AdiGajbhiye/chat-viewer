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

  group('fork folding — no empty halves', () {
    PairedConversation pair(String id, List<Map<String, dynamic>> nodes,
            {String? current}) =>
        pairTurns(ExportConversation(
            conversation(id: id, currentNode: current, nodes: nodes)));
    Map<String, dynamic> usr(String id, String parent, String text, double t) =>
        node(id,
            parent: parent,
            message: message(id, role: 'user', parts: [text], time: t));
    Map<String, dynamic> ast(String id, String parent, String text, double t) =>
        node(id,
            parent: parent,
            message: message(id, role: 'assistant', parts: [text], time: t));
    // A transparent node (system role) that breaks the absorb chain.
    Map<String, dynamic> sys(String id, String parent, double t) => node(id,
        parent: parent,
        message: message(id, role: 'system', parts: ['ctx'], time: t));

    void expectNoEmptyHalves(PairedConversation p) {
      for (final t in p.turns) {
        expect(t.promptMd, isNotEmpty, reason: '${t.id} has empty prompt');
        expect(t.responseMd, isNotEmpty, reason: '${t.id} has empty response');
      }
    }

    test('single response split by a transparent sibling merges into one cell',
        () {
      final p = pair('A', current: 'a', [
        node('root'),
        usr('u', 'root', 'ask', 1),
        ast('a', 'u', 'answer', 2),
        sys('blank', 'u', 3), // breaks the absorb chain but is transparent
      ]);
      expect(p.turns, hasLength(1));
      expect(p.turns.single.id, 'a'); // prompt node dissolved into the response
      expect(p.turns.single.promptMd, 'ask');
      expect(p.turns.single.responseMd, 'answer');
    });

    test('regen mid-conversation folds the prompt into full siblings', () {
      final p = pair('C', current: 'b2', [
        node('root'),
        usr('u1', 'root', 'q1', 1),
        ast('a1', 'u1', 'ans1', 2),
        usr('u2', 'a1', 'q2', 3),
        ast('b1', 'u2', 'ans2a', 4),
        ast('b2', 'u2', 'ans2b', 5),
      ]);
      expect(p.turns.any((t) => t.id == 'u2'), isFalse); // prompt dissolved
      expect((turnById(p, 'b1').promptMd, turnById(p, 'b1').responseMd),
          ('q2', 'ans2a'));
      expect((turnById(p, 'b2').promptMd, turnById(p, 'b2').responseMd),
          ('q2', 'ans2b'));
      // Siblings hang off the first (q1/ans1) turn.
      expect(turnById(p, 'b1').parentTurnId, 'u1');
      expect(turnById(p, 'b2').parentTurnId, 'u1');
      expect(turnById(p, 'u1').responseMd, 'ans1');
      expectNoEmptyHalves(p);
    });

    test('nested regen carries the prompt down through both fork levels', () {
      final p = pair('D', current: 'd2', [
        node('root'),
        usr('u', 'root', 'q', 1),
        ast('a1', 'u', 'ans1', 2),
        ast('a2', 'u', 'ans2', 3),
        ast('d1', 'a2', 'cont-a', 4),
        ast('d2', 'a2', 'cont-b', 5),
      ]);
      expect(p.turns.any((t) => t.id == 'a2'), isFalse); // inner prompt dissolved
      expect(p.turns.map((t) => t.id).toSet(), {'a1', 'd1', 'd2'});
      for (final t in p.turns) {
        expect(t.promptMd, 'q'); // every branch carries the shared prompt
      }
      expect(turnById(p, 'a1').responseMd, 'ans1');
      expect(turnById(p, 'd1').responseMd, contains('ans2'));
      expect(turnById(p, 'd1').responseMd, contains('cont-a'));
      expect(turnById(p, 'd2').responseMd, contains('cont-b'));
    });

    test('response buried behind a transparent node is backfilled', () {
      final p = pair('E', current: 'a2', [
        node('root'),
        usr('u', 'root', 'q', 1),
        ast('a1', 'u', 'ans', 2),
        sys('t', 'u', 3), // transparent fork sibling…
        ast('a2', 't', 'buried', 4), // …hiding a regenerated response
      ]);
      final a2 = turnById(p, 'a2');
      expect(a2.promptMd, 'q'); // inherited from nearest prompt-bearing ancestor
      expect(a2.responseMd, 'buried');
      expect(a2.parentTurnId, 'a1');
      expectNoEmptyHalves(p);
    });

    test('genuine orphan assistant keeps its empty prompt — nothing to inherit',
        () {
      final p = pair('F', current: 'a', [
        node('root'),
        ast('a', 'root', 'hi', 1),
      ]);
      expect(p.turns.single.promptMd, isEmpty);
      expect(p.turns.single.responseMd, 'hi');
    });

    test('trailing prompt with no response renders one-sided', () {
      final p = pair('G', current: 'u', [
        node('root'),
        usr('u', 'root', 'hello', 1),
      ]);
      expect(p.turns.single.promptMd, 'hello');
      expect(p.turns.single.responseMd, isEmpty);
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
