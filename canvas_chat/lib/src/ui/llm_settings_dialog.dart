import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/llm/openai_compatible_provider.dart';
import '../state/branching.dart';

/// LLM connection settings (DESIGN.md §9 "Live chat") for the
/// OpenAI-compatible provider: base URL, API key, model and an optional system
/// prompt. Saving persists via [LlmConfigNotifier.set] and the live backend
/// swaps in immediately; an empty key falls back to the offline stub.
Future<void> showLlmSettingsDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const LlmSettingsDialog(),
    );

/// A one-tap connection preset that fills the base URL + a sensible model.
class _Preset {
  const _Preset(this.label, this.baseUrl, this.model);

  final String label;
  final String baseUrl;
  final String model;
}

const _presets = [
  _Preset('OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini'),
  _Preset('OpenRouter', 'https://openrouter.ai/api/v1', 'openai/gpt-4o-mini'),
  _Preset('Ollama', 'http://localhost:11434/v1', 'llama3.2'),
];

class LlmSettingsDialog extends ConsumerStatefulWidget {
  const LlmSettingsDialog({super.key});

  @override
  ConsumerState<LlmSettingsDialog> createState() => _LlmSettingsDialogState();
}

class _LlmSettingsDialogState extends ConsumerState<LlmSettingsDialog> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late final TextEditingController _systemPrompt;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final config = ref.read(llmConfigProvider);
    _baseUrl = TextEditingController(text: config.baseUrl);
    _apiKey = TextEditingController(text: config.apiKey);
    _model = TextEditingController(text: config.model);
    _systemPrompt = TextEditingController(text: config.systemPrompt ?? '');
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _systemPrompt.dispose();
    super.dispose();
  }

  LlmConfig get _draft => LlmConfig(
        baseUrl: _baseUrl.text,
        apiKey: _apiKey.text,
        model: _model.text,
        systemPrompt: _systemPrompt.text,
      );

  void _applyPreset(_Preset preset) {
    _baseUrl.text = preset.baseUrl;
    // Only fill the model if the user hasn't already typed their own.
    if (_model.text.trim().isEmpty) _model.text = preset.model;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final configured = _draft.isConfigured;
    await ref.read(llmConfigProvider.notifier).set(_draft);
    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(configured
          ? 'Saved — live model connected.'
          : 'Saved — no key set; using the offline stub.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Model settings'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in _presets)
                    ActionChip(
                      label: Text(preset.label),
                      onPressed: () => _applyPreset(preset),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.openai.com/v1',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKey,
                obscureText: _obscureKey,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'API key',
                  hintText: 'sk-…  (leave blank for a local Ollama)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: _obscureKey ? 'Show' : 'Hide',
                    icon: Icon(_obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stored in plain text in this app’s local preferences.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _model,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'gpt-4o-mini',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _systemPrompt,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'System prompt (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: Listenable.merge([_baseUrl, _apiKey, _model]),
                builder: (context, _) {
                  final ok = _draft.isConfigured;
                  final color =
                      ok ? theme.colorScheme.primary : theme.colorScheme.outline;
                  return Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle_outline : Icons.info_outline,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ok
                              ? 'Live model will be used.'
                              : 'No usable key — branches use the offline stub.',
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: color),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
