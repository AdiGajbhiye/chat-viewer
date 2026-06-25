import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/state/retrieval.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            // Bottom-aligned so the popup menu (opens "under") has room.
            body: Align(
              alignment: Alignment.topCenter,
              child: RetrievalScopeSelector(),
            ),
          ),
        ),
      );

  testWidgets('reflects the provider: shows the current scope label',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container));
    // Default is project.
    expect(find.text('Project'), findsOneWidget);

    // Flipping the provider re-renders the pill.
    container.read(retrievalScopeProvider.notifier).set(RetrievalScope.session);
    await tester.pump();
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Project'), findsNothing);
  });

  testWidgets('selecting a scope from the menu updates the provider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container));
    expect(container.read(retrievalScopeProvider), RetrievalScope.project);

    // Open the popup menu and pick "All projects".
    await tester.tap(find.byType(RetrievalScopeSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All projects').last);
    await tester.pumpAndSettle();

    expect(container.read(retrievalScopeProvider), RetrievalScope.all);
    // The pill now shows the new selection.
    expect(find.text('All projects'), findsOneWidget);
  });
}
