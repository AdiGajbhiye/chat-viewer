import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/openai_compatible_embedding_provider.dart';
import 'package:canvas_chat/src/state/branching.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test('defaults to the offline stub when nothing is saved', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    final config = container.read(embeddingConfigProvider);
    expect(config.baseUrl, 'https://api.openai.com/v1');
    expect(config.model, 'text-embedding-3-small');
    expect(config.isConfigured, isFalse);
    expect(
      container.read(embeddingProviderProvider),
      isA<StubEmbeddingProvider>(),
    );
  });

  test('set() normalizes, persists, and swaps in the live provider', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await container.read(embeddingConfigProvider.notifier).set(
          const EmbeddingConfig(
            apiKey: '  sk-live  ', // surrounding whitespace
            model: 'text-embedding-3-large',
          ),
        );

    final config = container.read(embeddingConfigProvider);
    expect(config.apiKey, 'sk-live');
    expect(
      container.read(embeddingProviderProvider),
      isA<OpenAiCompatibleEmbeddingProvider>(),
    );
  });

  test('shares the host prefs keys with the chat config', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    // Saving an embedding host writes the shared `llm.baseUrl`/`llm.apiKey`,
    // so the chat config reads the same host back.
    await container.read(embeddingConfigProvider.notifier).set(
          const EmbeddingConfig(apiKey: 'sk-shared', model: 'emb'),
        );

    expect(container.read(llmConfigProvider).apiKey, 'sk-shared');
  });
}
