import 'package:canvas_chat/src/data/llm/llm_provider.dart';
import 'package:canvas_chat/src/data/llm/openai_compatible_provider.dart';
import 'package:canvas_chat/src/state/branching.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/llm_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('defaults to the OpenAI seed and the offline stub when nothing is saved',
      () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    final config = container.read(llmConfigProvider);
    expect(config.baseUrl, 'https://api.openai.com/v1');
    expect(config.apiKey, isEmpty);
    expect(config.isConfigured, isFalse);
    expect(container.read(llmProviderProvider), isA<StubLlmProvider>());
  });

  test('set() normalizes, persists, and swaps in the live provider', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await container.read(llmConfigProvider.notifier).set(const LlmConfig(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: '  sk-live  ', // surrounding whitespace
          model: 'gpt-4o',
          systemPrompt: '   ', // blank → dropped
        ));

    final config = container.read(llmConfigProvider);
    expect(config.apiKey, 'sk-live');
    expect(config.systemPrompt, isNull);
    expect(container.read(llmProviderProvider), isA<OpenAiCompatibleProvider>());
  });

  test('saved values are read back by a fresh container', () async {
    final first = await makeContainer();
    await first.read(llmConfigProvider.notifier).set(
          const LlmConfig(apiKey: 'sk-persist', model: 'gpt-4o-mini'),
        );
    first.dispose();

    // A new container reloads from the same (persisted) prefs store.
    final second = await makeContainer();
    addTearDown(second.dispose);
    expect(second.read(llmConfigProvider).apiKey, 'sk-persist');
  });

  testWidgets('the settings dialog saves entered values and swaps the backend',
      (tester) async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLlmSettingsDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Model settings'), findsOneWidget);

    // Fields render in order: base URL, API key, model, system prompt.
    await tester.enterText(find.byType(TextField).at(1), 'sk-widget');
    await tester.enterText(find.byType(TextField).at(2), 'gpt-4o');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog closed, config persisted, and the live provider is now active.
    expect(find.text('Model settings'), findsNothing);
    expect(container.read(llmConfigProvider).apiKey, 'sk-widget');
    expect(container.read(llmConfigProvider).model, 'gpt-4o');
    expect(container.read(llmProviderProvider), isA<OpenAiCompatibleProvider>());
  });
}
