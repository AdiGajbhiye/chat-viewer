import 'package:canvas_chat/src/domain/paired_turn.dart';
import 'package:flutter_test/flutter_test.dart';

PairedTurn sample() => PairedTurn(
      id: 'turn-1',
      parentTurnId: 'turn-0',
      promptMd: 'original prompt',
      responseMd: 'the response',
      thoughtsMd: 'folded thoughts',
      modelSlug: 'gpt-4o',
      createTime: 1234.5,
      assets: [
        TurnAssetRef(kind: 'prompt', pointerId: 'file-a', width: 10, height: 20),
      ],
      rawNodes: const [
        {'id': 'n0'},
        {'id': 'n1'},
      ],
    );

void main() {
  group('PairedTurn.copyWith', () {
    test('no overrides preserves every field, sharing list references', () {
      final original = sample();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.parentTurnId, original.parentTurnId);
      expect(copy.promptMd, original.promptMd);
      expect(copy.responseMd, original.responseMd);
      expect(copy.thoughtsMd, original.thoughtsMd);
      expect(copy.modelSlug, original.modelSlug);
      expect(copy.createTime, original.createTime);
      // copyWith forwards the same backing lists — it is not a deep clone.
      expect(identical(copy.assets, original.assets), isTrue);
      expect(identical(copy.rawNodes, original.rawNodes), isTrue);
    });

    test('overriding promptMd leaves response, thoughts and raw nodes intact', () {
      // The prompt-backfill path in turn pairing relies on this: rewriting the
      // prompt must not silently drop the absorbed response or raw nodes.
      final copy = sample().copyWith(promptMd: 'backfilled prompt');
      expect(copy.promptMd, 'backfilled prompt');
      expect(copy.responseMd, 'the response');
      expect(copy.thoughtsMd, 'folded thoughts');
      expect(copy.rawNodes, hasLength(2));
      expect(identical(copy.assets, sample().assets), isFalse); // fresh sample
      expect(copy.assets, hasLength(1));
    });

    test('overriding assets keeps the prompt', () {
      final original = sample();
      final newAssets = [
        TurnAssetRef(kind: 'response', pointerId: 'file-b', width: 1, height: 1),
      ];
      final copy = original.copyWith(assets: newAssets);
      expect(identical(copy.assets, newAssets), isTrue);
      expect(copy.promptMd, original.promptMd);
      expect(copy.rawNodes, original.rawNodes);
    });
  });
}
