import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/llm_provider.dart';
import 'package:canvas_chat/src/data/llm/openai_compatible_provider.dart'
    show LlmException;
import 'package:canvas_chat/src/data/llm/proposition_extractor.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [LlmProvider] that yields a fixed payload (optionally chunked) so the
/// [LlmPropositionExtractor]'s collect + parse can be tested without a model.
class _FixedProvider implements LlmProvider {
  _FixedProvider(this.chunks);
  _FixedProvider.whole(String payload) : chunks = [payload];

  final List<String> chunks;

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
  }) async* {
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

/// Builds a detached [Turn] (no DB) for feeding an extractor.
Turn _turn({
  String id = 't1',
  String prompt = '',
  String response = '',
}) =>
    Turn(
      id: id,
      conversationId: 'c1',
      promptMd: prompt,
      responseMd: response,
      rawJson: '{}',
    );

void main() {
  group('StubPropositionExtractor', () {
    const extractor = StubPropositionExtractor();

    test('is deterministic: same turn → identical extraction across calls',
        () async {
      final turn = _turn(
        prompt: 'How do I use Postgres?',
        response: 'Install Postgres. It is a database. '
            'Run `createdb mydb` to start.',
      );
      final a = await extractor.extract(turn);
      final b = await extractor.extract(turn);

      expect(a.propositions.length, b.propositions.length);
      for (var i = 0; i < a.propositions.length; i++) {
        expect(a.propositions[i].text, b.propositions[i].text);
        expect(a.propositions[i].aspect, b.propositions[i].aspect);
        expect(a.propositions[i].entities, b.propositions[i].entities);
      }
    });

    test('produces ≥1 and ≤5 non-empty propositions', () async {
      final turn = _turn(
        response: 'One. Two. Three. Four. Five. Six. Seven. Eight.',
      );
      final out = await extractor.extract(turn);
      expect(out.propositions.length, inInclusiveRange(1, 5));
      for (final p in out.propositions) {
        expect(p.text.trim(), isNotEmpty);
      }
    });

    test('caps at maxPropositions and preserves source order', () async {
      const small = StubPropositionExtractor(maxPropositions: 2);
      final out = await small.extract(
        _turn(response: 'Alpha here. Beta here. Gamma here.'),
      );
      expect(out.propositions.length, 2);
      expect(out.propositions[0].text, 'Alpha here.');
      expect(out.propositions[1].text, 'Beta here.');
    });

    test('falls back to the prompt when the response is empty', () async {
      final out = await extractor.extract(_turn(prompt: 'What is drift?'));
      expect(out.propositions, isNotEmpty);
      expect(out.propositions.first.text, 'What is drift?');
    });

    test('pulls stable entities: code spans, quotes, capitalized words',
        () async {
      final out = await extractor.extract(
        _turn(response: 'Use `psql` to query the "users" table in Postgres.'),
      );
      final entities = out.propositions.single.entities;
      expect(entities, containsAll(['psql', 'users', 'Postgres']));
      // Same turn again → same entity list (stability).
      final again = await extractor.extract(
        _turn(response: 'Use `psql` to query the "users" table in Postgres.'),
      );
      expect(again.propositions.single.entities, entities);
    });

    test('assigns a deterministic aspect tag per segment shape', () async {
      final out = await extractor.extract(
        _turn(
          response: 'What is this? '
              'SQLite is a database. '
              'Run the migration now.',
        ),
      );
      final byText = {for (final p in out.propositions) p.text: p.aspect};
      expect(byText['What is this?'], 'question');
      expect(byText['SQLite is a database.'], 'definition');
      expect(byText['Run the migration now.'], 'instruction');
    });

    test('empty turn → no propositions', () async {
      final out = await extractor.extract(_turn());
      expect(out.propositions, isEmpty);
    });
  });

  group('LlmPropositionExtractor', () {
    const json =
        '[{"text":"Postgres is a relational database.","aspect":"definition",'
        '"entities":["Postgres"]},'
        '{"text":"Run createdb to make a database.","aspect":"instruction",'
        '"entities":["createdb"]}]';

    void expectParsed(TurnExtraction out) {
      expect(out.propositions.length, 2);
      expect(out.propositions[0].text, 'Postgres is a relational database.');
      expect(out.propositions[0].aspect, 'definition');
      expect(out.propositions[0].entities, ['Postgres']);
      expect(out.propositions[1].text, 'Run createdb to make a database.');
      expect(out.propositions[1].entities, ['createdb']);
    }

    test('parses a plain JSON array', () async {
      final extractor = LlmPropositionExtractor(_FixedProvider.whole(json));
      expectParsed(await extractor.extract(_turn(prompt: 'q')));
    });

    test('tolerates a ```json fenced block', () async {
      final fenced = '```json\n$json\n```';
      final extractor = LlmPropositionExtractor(_FixedProvider.whole(fenced));
      expectParsed(await extractor.extract(_turn(prompt: 'q')));
    });

    test('tolerates leading + trailing prose', () async {
      final prose = 'Sure! Here are the propositions:\n\n$json\n\nLet me '
          'know if you need more.';
      final extractor = LlmPropositionExtractor(_FixedProvider.whole(prose));
      expectParsed(await extractor.extract(_turn(prompt: 'q')));
    });

    test('accumulates a chunked stream before parsing', () async {
      final mid = json.length ~/ 2;
      final extractor = LlmPropositionExtractor(
        _FixedProvider([json.substring(0, mid), json.substring(mid)]),
      );
      expectParsed(await extractor.extract(_turn(prompt: 'q')));
    });

    test('skips array elements without a non-empty text', () async {
      final extractor = LlmPropositionExtractor(
        _FixedProvider.whole(
          '[{"text":"kept","aspect":"x"},{"text":""},{"no":"text"},"bare"]',
        ),
      );
      final out = await extractor.extract(_turn(prompt: 'q'));
      expect(out.propositions.map((p) => p.text), ['kept']);
    });

    test('throws LlmException when no JSON array is present', () async {
      final extractor = LlmPropositionExtractor(
        _FixedProvider.whole('I could not extract anything.'),
      );
      expect(
        () => extractor.extract(_turn(prompt: 'q')),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws LlmException on malformed JSON', () async {
      final extractor = LlmPropositionExtractor(
        _FixedProvider.whole('[{"text": "oops" '), // unterminated
      );
      expect(
        () => extractor.extract(_turn(prompt: 'q')),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('persistTurnExtraction', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.into(db.conversations).insert(
            ConversationsCompanion.insert(id: 'c1', source: 'test'),
          );
      await db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: 'c1:t1',
              conversationId: 'c1',
              rawJson: '{}',
            ),
          );
      await db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: 'c1:t2',
              conversationId: 'c1',
              rawJson: '{}',
            ),
          );
    });
    tearDown(() => db.close());

    const extraction = TurnExtraction(
      propositions: [
        ExtractedProposition(
          text: 'Postgres is a database.',
          aspect: 'definition',
          entities: ['Postgres'],
        ),
        ExtractedProposition(
          text: 'It runs on a server.',
          aspect: 'statement',
          entities: ['Postgres'], // same entity → one row, one link
        ),
      ],
    );

    test('writes propositions, entities, and links', () async {
      await db.persistTurnExtraction(
        turnId: 'c1:t1',
        conversationId: 'c1',
        projectId: 'default',
        extraction: extraction,
      );

      final props = await (db.select(db.propositions)
            ..where((p) => p.turnId.equals('c1:t1')))
          .get();
      expect(props.length, 2);
      expect(
        props.map((p) => p.propText),
        containsAll(['Postgres is a database.', 'It runs on a server.']),
      );
      expect(props.every((p) => p.conversationId == 'c1'), isTrue);
      expect(props.every((p) => p.projectId == 'default'), isTrue);
      expect(props.every((p) => p.embedding == null), isTrue);

      final entities = await db.select(db.entities).get();
      expect(entities.length, 1, reason: 'two surfaces of one entity dedup');
      expect(entities.single.normalized, 'postgres');
      expect(entities.single.projectId, 'default');

      final links = await (db.select(db.turnEntities)
            ..where((te) => te.turnId.equals('c1:t1')))
          .get();
      expect(links.length, 1);
      expect(links.single.entityId, entities.single.id);
    });

    test('reuses an existing entity row across turns (dedup by project+norm)',
        () async {
      await db.persistTurnExtraction(
        turnId: 'c1:t1',
        conversationId: 'c1',
        projectId: 'default',
        extraction: extraction,
      );
      final firstEntityId = (await db.select(db.entities).get()).single.id;

      await db.persistTurnExtraction(
        turnId: 'c1:t2',
        conversationId: 'c1',
        projectId: 'default',
        extraction: const TurnExtraction(
          propositions: [
            ExtractedProposition(text: 'Postgres scales well.',
                entities: ['postgres']), // different surface, same normalized
          ],
        ),
      );

      final entities = await db.select(db.entities).get();
      expect(entities.length, 1, reason: 'entity reused, not duplicated');
      expect(entities.single.id, firstEntityId);

      // Both turns link to the one shared entity.
      final t2Links = await (db.select(db.turnEntities)
            ..where((te) => te.turnId.equals('c1:t2')))
          .get();
      expect(t2Links.single.entityId, firstEntityId);
    });

    test('re-running for the same turn replaces (no duplicates)', () async {
      await db.persistTurnExtraction(
        turnId: 'c1:t1',
        conversationId: 'c1',
        projectId: 'default',
        extraction: extraction,
      );
      // Re-index the same turn with a different extraction.
      await db.persistTurnExtraction(
        turnId: 'c1:t1',
        conversationId: 'c1',
        projectId: 'default',
        extraction: const TurnExtraction(
          propositions: [
            ExtractedProposition(text: 'Only one now.', entities: ['SQLite']),
          ],
        ),
      );

      final props = await (db.select(db.propositions)
            ..where((p) => p.turnId.equals('c1:t1')))
          .get();
      expect(props.length, 1, reason: 'old propositions cleared');
      expect(props.single.propText, 'Only one now.');

      final links = await (db.select(db.turnEntities)
            ..where((te) => te.turnId.equals('c1:t1')))
          .get();
      expect(links.length, 1);

      // Old (Postgres) entity row survives — it may be shared — but the stale
      // link to it is gone; only the new (SQLite) link remains.
      final entities = await db.select(db.entities).get();
      expect(
        entities.map((e) => e.normalized),
        containsAll(['postgres', 'sqlite']),
      );
      final linkedEntity =
          entities.firstWhere((e) => e.id == links.single.entityId);
      expect(linkedEntity.normalized, 'sqlite');
    });

    test('stores supplied embeddings (decode round-trips) with model',
        () async {
      final embeddings = [
        [0.5, -0.25, 0.125],
        [1.0, 0.0, -1.0],
      ];
      await db.persistTurnExtraction(
        turnId: 'c1:t1',
        conversationId: 'c1',
        projectId: 'default',
        extraction: extraction,
        embeddings: embeddings,
        embeddingModel: 'stub-3',
      );

      final props = await (db.select(db.propositions)
            ..where((p) => p.turnId.equals('c1:t1'))
            ..orderBy([(p) => OrderingTerm.asc(p.id)]))
          .get();
      expect(props.length, 2);
      for (var i = 0; i < props.length; i++) {
        expect(props[i].embeddingModel, 'stub-3');
        expect(props[i].embedding, isNotNull);
        expect(decodeEmbedding(props[i].embedding!), embeddings[i]);
      }
    });

    test('rejects an embeddings/propositions length mismatch', () async {
      expect(
        () => db.persistTurnExtraction(
          turnId: 'c1:t1',
          conversationId: 'c1',
          projectId: 'default',
          extraction: extraction,
          embeddings: const [
            [0.1, 0.2],
          ], // 1 vector, 2 propositions
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
