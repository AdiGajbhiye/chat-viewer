import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../data/db/database.dart';
import '../../state/providers.dart';
import '../../state/wiki.dart';

/// The generated, **read-only** project wiki (DESIGN.md §10). Notion/Obsidian-
/// style: the project's topics (from connected-component clustering over the
/// soft-edge graph), an all-entities index and an all-facts list, with entity
/// names hyperlinked to per-entity backlink pages and every fact/proposition
/// click-through-able to its source turn (via `fact_sources` / `turn_entities`).
///
/// Opened as a full-screen route over the home screen for [projectId] (the
/// selected conversation's project, defaulting to 'default'). Read-only — no
/// editing here; a later edit would flow back as a commit (out of scope).
class WikiScreen extends ConsumerWidget {
  const WikiScreen({super.key, required this.projectId});

  final String projectId;

  /// Pushes the wiki as a full-screen route. Click-through to a source turn
  /// pops back to the home screen, selects the turn's conversation and asks its
  /// canvas to open the reader on the turn (via [wikiNavRequestProvider]).
  static Future<void> open(BuildContext context, String projectId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WikiScreen(projectId: projectId),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wikiOverviewProvider(projectId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Wiki'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: switch (async) {
        AsyncData(:final value) => _Overview(overview: value),
        AsyncError(:final error) =>
          Center(child: Text('Failed to build the wiki:\n$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Centers + caps the wiki content to a comfortable reading width, mirroring the
/// reader's capped column.
class _ReadingColumn extends StatelessWidget {
  const _ReadingColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: child,
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final WikiOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (overview.topics.isEmpty &&
        overview.entities.isEmpty &&
        overview.facts.isEmpty) {
      return const _EmptyWiki();
    }
    return ListView(
      children: [
        _ReadingColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overview.topics.isNotEmpty) ...[
                _SectionHeader(
                  'Topics',
                  subtitle: 'Clustered across branches by association',
                ),
                for (final topic in overview.topics)
                  _TopicCard(topic: topic),
                const SizedBox(height: 24),
              ],
              _SectionHeader('Entities', subtitle: '${overview.entities.length}'),
              if (overview.entities.isEmpty)
                Text('No entities extracted yet.',
                    style: theme.textTheme.bodyMedium)
              else
                _EntityIndex(entities: overview.entities),
              const SizedBox(height: 24),
              _SectionHeader('Facts', subtitle: '${overview.facts.length}'),
              if (overview.facts.isEmpty)
                Text('No facts committed yet.',
                    style: theme.textTheme.bodyMedium)
              else
                for (final fact in overview.facts)
                  _FactTile(
                    fact: fact,
                    sourceTurnIds:
                        overview.factSourceTurnIds[fact.id] ?? const [],
                  ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                subtitle!,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final WikiTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(topic.title, style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  '${topic.turnIds.length} turns',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            if (topic.entities.isNotEmpty) ...[
              const SizedBox(height: 10),
              _EntityChips(entities: topic.entities),
            ],
            if (topic.facts.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final fact in topic.facts)
                _FactTile(fact: fact, sourceTurnIds: const [], compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// The all-entities index: a wrap of hyperlinked entity chips, most-mentioned
/// first.
class _EntityIndex extends StatelessWidget {
  const _EntityIndex({required this.entities});

  final List<WikiEntityRef> entities;

  @override
  Widget build(BuildContext context) {
    return _EntityChips(entities: entities, showCounts: true);
  }
}

/// A wrap of entity chips; each navigates to its entity page (Obsidian-style
/// hyperlinks). Optionally shows the mention count.
class _EntityChips extends StatelessWidget {
  const _EntityChips({required this.entities, this.showCounts = false});

  final List<WikiEntityRef> entities;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entity in entities)
          ActionChip(
            avatar: const Icon(Icons.link, size: 16),
            label: Text(
              showCounts
                  ? '${entity.name} · ${entity.mentionCount}'
                  : entity.name,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _EntityPageScreen(entityId: entity.id),
              ),
            ),
          ),
      ],
    );
  }
}

/// One fact rendered as content, with a click-through to its source turn(s).
/// [compact] drops the leading icon/padding for embedding inside a topic card;
/// [sourceTurnIds] is the provenance — when empty (e.g. a topic-embedded fact),
/// the provenance is resolved lazily on tap.
class _FactTile extends ConsumerWidget {
  const _FactTile({
    required this.fact,
    required this.sourceTurnIds,
    this.compact = false,
  });

  final Fact fact;
  final List<String> sourceTurnIds;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: scheme.onSurface);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Icon(Icons.push_pin_outlined,
                  size: 16, color: scheme.primary),
            ),
          ],
          Expanded(child: GptMarkdown(fact.factText, style: style)),
          const SizedBox(width: 8),
          _SourceButton(fact: fact, sourceTurnIds: sourceTurnIds),
        ],
      ),
    );
  }
}

/// The provenance click-through: opens the fact's source turn in the reader.
/// Resolves the source turn(s) lazily when not pre-supplied.
class _SourceButton extends ConsumerWidget {
  const _SourceButton({required this.fact, required this.sourceTurnIds});

  final Fact fact;
  final List<String> sourceTurnIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Open source turn',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.open_in_new, size: 18),
      onPressed: () async {
        final wiki = ref.read(wikiServiceProvider);
        final turns = sourceTurnIds.isNotEmpty
            ? sourceTurnIds
            : await wiki.factSources(fact.id);
        if (turns.isEmpty || !context.mounted) return;
        await openTurnFromWiki(context, ref, turns.first);
      },
    );
  }
}

/// The per-entity detail page: facts + proposition snippets that backlink to
/// the entity, each click-through-able to its source turn.
class _EntityPageScreen extends ConsumerWidget {
  const _EntityPageScreen({required this.entityId});

  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entityPageProvider(entityId));
    return Scaffold(
      appBar: AppBar(
        title: switch (async) {
          AsyncData(value: final page?) => Text(page.entity.name),
          _ => const Text('Entity'),
        },
      ),
      body: switch (async) {
        AsyncData(value: final page?) => _EntityPageBody(page: page),
        AsyncData() => const Center(child: Text('Entity no longer exists.')),
        AsyncError(:final error) =>
          Center(child: Text('Failed to load entity:\n$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EntityPageBody extends StatelessWidget {
  const _EntityPageBody({required this.page});

  final WikiEntityPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurface);
    return ListView(
      children: [
        _ReadingColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mentioned in ${page.mentionTurnIds.length} '
                'turn${page.mentionTurnIds.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 16),
              _SectionHeader('Facts', subtitle: '${page.facts.length}'),
              if (page.facts.isEmpty)
                Text('No committed facts mention this entity.', style: style)
              else
                for (final backlink in page.facts)
                  _FactTile(
                    fact: backlink.fact,
                    sourceTurnIds: backlink.sourceTurnIds,
                  ),
              const SizedBox(height: 24),
              _SectionHeader('Mentions', subtitle: '${page.propositions.length}'),
              if (page.propositions.isEmpty)
                Text('No proposition snippets recorded.', style: style)
              else
                for (final prop in page.propositions)
                  _PropositionTile(proposition: prop),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

/// One proposition snippet (the "what was said" backlink) with a click-through
/// to its source turn.
class _PropositionTile extends ConsumerWidget {
  const _PropositionTile({required this.proposition});

  final Proposition proposition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.notes, size: 16, color: scheme.outline),
          ),
          Expanded(child: GptMarkdown(proposition.propText, style: style)),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Open source turn',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: () =>
                openTurnFromWiki(context, ref, proposition.turnId),
          ),
        ],
      ),
    );
  }
}

class _EmptyWiki extends StatelessWidget {
  const _EmptyWiki();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Nothing in the wiki yet.\n\n'
          'Open conversations to index them, and commit facts from read '
          'mode — entities, topics and facts will appear here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Click-through from the wiki to a source [turnId]: resolves the turn's
/// conversation, pops back to the home screen, selects that conversation, and
/// publishes a [WikiNavRequest] so the conversation's [CanvasView] opens the
/// reader on the turn. Reuses the existing selection + reader mechanism — no new
/// routing. A no-op when the turn can't be resolved (e.g. re-import dropped it).
Future<void> openTurnFromWiki(
  BuildContext context,
  WidgetRef ref,
  String turnId,
) async {
  final conversationId =
      await ref.read(wikiServiceProvider).conversationOfTurn(turnId);
  if (conversationId == null) return;
  if (!context.mounted) return;
  // Publish the request first, then select the conversation, then pop the wiki
  // route(s): the CanvasView is (re)built on selection and consumes the pending
  // request on its next build.
  ref.read(wikiNavRequestProvider.notifier).set(
        WikiNavRequest(conversationId: conversationId, turnId: turnId),
      );
  ref.read(selectedConversationIdProvider.notifier).select(conversationId);
  // Pop back to the home screen (the wiki may be several pages deep).
  Navigator.of(context).popUntil((route) => route.isFirst);
}
