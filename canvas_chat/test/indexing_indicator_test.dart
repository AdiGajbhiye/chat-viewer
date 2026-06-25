import 'package:canvas_chat/src/state/indexing.dart';
import 'package:canvas_chat/src/ui/canvas/indexing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: IndexingIndicator(conversationId: 'c1'),
          ),
        ),
      );

  testWidgets('shows while indexing and hides once indexed', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(indexingProgressProvider.notifier);

    // Nothing yet → indicator absent.
    await tester.pumpWidget(host(container));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Indexing'), findsNothing);

    // State == indexing → the "Indexing N/M…" chip appears.
    notifier.update(
      'c1',
      const IndexingProgress(state: IndexState.indexing, done: 1, total: 4),
    );
    await tester.pump();
    expect(find.text('Indexing 1/4…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // State == indexed → the chip disappears.
    notifier.update(
      'c1',
      const IndexingProgress(state: IndexState.indexed, done: 4, total: 4),
    );
    await tester.pump();
    expect(find.textContaining('Indexing'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ignores progress for a different conversation', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(indexingProgressProvider.notifier).update(
          'other',
          const IndexingProgress(state: IndexState.indexing, done: 2, total: 5),
        );
    await tester.pumpWidget(host(container));
    await tester.pump();
    // The indicator is bound to 'c1', so 'other' indexing must not show.
    expect(find.textContaining('Indexing'), findsNothing);
  });
}
