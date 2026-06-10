// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<int> createTime = GeneratedColumn<int>(
    'create_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updateTimeMeta = const VerificationMeta(
    'updateTime',
  );
  @override
  late final GeneratedColumn<int> updateTime = GeneratedColumn<int>(
    'update_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isStarredMeta = const VerificationMeta(
    'isStarred',
  );
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
    'is_starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultModelSlugMeta = const VerificationMeta(
    'defaultModelSlug',
  );
  @override
  late final GeneratedColumn<String> defaultModelSlug = GeneratedColumn<String>(
    'default_model_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentTurnIdMeta = const VerificationMeta(
    'currentTurnId',
  );
  @override
  late final GeneratedColumn<String> currentTurnId = GeneratedColumn<String>(
    'current_turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createTime,
    updateTime,
    isArchived,
    isStarred,
    defaultModelSlug,
    currentTurnId,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    }
    if (data.containsKey('update_time')) {
      context.handle(
        _updateTimeMeta,
        updateTime.isAcceptableOrUnknown(data['update_time']!, _updateTimeMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_starred')) {
      context.handle(
        _isStarredMeta,
        isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta),
      );
    }
    if (data.containsKey('default_model_slug')) {
      context.handle(
        _defaultModelSlugMeta,
        defaultModelSlug.isAcceptableOrUnknown(
          data['default_model_slug']!,
          _defaultModelSlugMeta,
        ),
      );
    }
    if (data.containsKey('current_turn_id')) {
      context.handle(
        _currentTurnIdMeta,
        currentTurnId.isAcceptableOrUnknown(
          data['current_turn_id']!,
          _currentTurnIdMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_time'],
      ),
      updateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_time'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isStarred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starred'],
      )!,
      defaultModelSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_model_slug'],
      ),
      currentTurnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_turn_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  /// Export conversation id.
  final String id;
  final String title;

  /// Milliseconds since epoch (export floats are converted on import).
  final int? createTime;
  final int? updateTime;
  final bool isArchived;
  final bool isStarred;
  final String? defaultModelSlug;

  /// Derived from the export's `current_node`.
  final String? currentTurnId;

  /// Importer plugin id, e.g. 'chatgpt_export'.
  final String source;
  const Conversation({
    required this.id,
    required this.title,
    this.createTime,
    this.updateTime,
    required this.isArchived,
    required this.isStarred,
    this.defaultModelSlug,
    this.currentTurnId,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(createTime);
    }
    if (!nullToAbsent || updateTime != null) {
      map['update_time'] = Variable<int>(updateTime);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_starred'] = Variable<bool>(isStarred);
    if (!nullToAbsent || defaultModelSlug != null) {
      map['default_model_slug'] = Variable<String>(defaultModelSlug);
    }
    if (!nullToAbsent || currentTurnId != null) {
      map['current_turn_id'] = Variable<String>(currentTurnId);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
      updateTime: updateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(updateTime),
      isArchived: Value(isArchived),
      isStarred: Value(isStarred),
      defaultModelSlug: defaultModelSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultModelSlug),
      currentTurnId: currentTurnId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentTurnId),
      source: Value(source),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createTime: serializer.fromJson<int?>(json['createTime']),
      updateTime: serializer.fromJson<int?>(json['updateTime']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      defaultModelSlug: serializer.fromJson<String?>(json['defaultModelSlug']),
      currentTurnId: serializer.fromJson<String?>(json['currentTurnId']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createTime': serializer.toJson<int?>(createTime),
      'updateTime': serializer.toJson<int?>(updateTime),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isStarred': serializer.toJson<bool>(isStarred),
      'defaultModelSlug': serializer.toJson<String?>(defaultModelSlug),
      'currentTurnId': serializer.toJson<String?>(currentTurnId),
      'source': serializer.toJson<String>(source),
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    Value<int?> createTime = const Value.absent(),
    Value<int?> updateTime = const Value.absent(),
    bool? isArchived,
    bool? isStarred,
    Value<String?> defaultModelSlug = const Value.absent(),
    Value<String?> currentTurnId = const Value.absent(),
    String? source,
  }) => Conversation(
    id: id ?? this.id,
    title: title ?? this.title,
    createTime: createTime.present ? createTime.value : this.createTime,
    updateTime: updateTime.present ? updateTime.value : this.updateTime,
    isArchived: isArchived ?? this.isArchived,
    isStarred: isStarred ?? this.isStarred,
    defaultModelSlug: defaultModelSlug.present
        ? defaultModelSlug.value
        : this.defaultModelSlug,
    currentTurnId: currentTurnId.present
        ? currentTurnId.value
        : this.currentTurnId,
    source: source ?? this.source,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      updateTime: data.updateTime.present
          ? data.updateTime.value
          : this.updateTime,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      defaultModelSlug: data.defaultModelSlug.present
          ? data.defaultModelSlug.value
          : this.defaultModelSlug,
      currentTurnId: data.currentTurnId.present
          ? data.currentTurnId.value
          : this.currentTurnId,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime, ')
          ..write('isArchived: $isArchived, ')
          ..write('isStarred: $isStarred, ')
          ..write('defaultModelSlug: $defaultModelSlug, ')
          ..write('currentTurnId: $currentTurnId, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createTime,
    updateTime,
    isArchived,
    isStarred,
    defaultModelSlug,
    currentTurnId,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.createTime == this.createTime &&
          other.updateTime == this.updateTime &&
          other.isArchived == this.isArchived &&
          other.isStarred == this.isStarred &&
          other.defaultModelSlug == this.defaultModelSlug &&
          other.currentTurnId == this.currentTurnId &&
          other.source == this.source);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> title;
  final Value<int?> createTime;
  final Value<int?> updateTime;
  final Value<bool> isArchived;
  final Value<bool> isStarred;
  final Value<String?> defaultModelSlug;
  final Value<String?> currentTurnId;
  final Value<String> source;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.defaultModelSlug = const Value.absent(),
    this.currentTurnId = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.defaultModelSlug = const Value.absent(),
    this.currentTurnId = const Value.absent(),
    required String source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? createTime,
    Expression<int>? updateTime,
    Expression<bool>? isArchived,
    Expression<bool>? isStarred,
    Expression<String>? defaultModelSlug,
    Expression<String>? currentTurnId,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createTime != null) 'create_time': createTime,
      if (updateTime != null) 'update_time': updateTime,
      if (isArchived != null) 'is_archived': isArchived,
      if (isStarred != null) 'is_starred': isStarred,
      if (defaultModelSlug != null) 'default_model_slug': defaultModelSlug,
      if (currentTurnId != null) 'current_turn_id': currentTurnId,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int?>? createTime,
    Value<int?>? updateTime,
    Value<bool>? isArchived,
    Value<bool>? isStarred,
    Value<String?>? defaultModelSlug,
    Value<String?>? currentTurnId,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      isArchived: isArchived ?? this.isArchived,
      isStarred: isStarred ?? this.isStarred,
      defaultModelSlug: defaultModelSlug ?? this.defaultModelSlug,
      currentTurnId: currentTurnId ?? this.currentTurnId,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(createTime.value);
    }
    if (updateTime.present) {
      map['update_time'] = Variable<int>(updateTime.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (defaultModelSlug.present) {
      map['default_model_slug'] = Variable<String>(defaultModelSlug.value);
    }
    if (currentTurnId.present) {
      map['current_turn_id'] = Variable<String>(currentTurnId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime, ')
          ..write('isArchived: $isArchived, ')
          ..write('isStarred: $isStarred, ')
          ..write('defaultModelSlug: $defaultModelSlug, ')
          ..write('currentTurnId: $currentTurnId, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TurnsTable extends Turns with TableInfo<$TurnsTable, Turn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id)',
    ),
  );
  static const VerificationMeta _parentTurnIdMeta = const VerificationMeta(
    'parentTurnId',
  );
  @override
  late final GeneratedColumn<String> parentTurnId = GeneratedColumn<String>(
    'parent_turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptMdMeta = const VerificationMeta(
    'promptMd',
  );
  @override
  late final GeneratedColumn<String> promptMd = GeneratedColumn<String>(
    'prompt_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _responseMdMeta = const VerificationMeta(
    'responseMd',
  );
  @override
  late final GeneratedColumn<String> responseMd = GeneratedColumn<String>(
    'response_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _thoughtsMdMeta = const VerificationMeta(
    'thoughtsMd',
  );
  @override
  late final GeneratedColumn<String> thoughtsMd = GeneratedColumn<String>(
    'thoughts_md',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelSlugMeta = const VerificationMeta(
    'modelSlug',
  );
  @override
  late final GeneratedColumn<String> modelSlug = GeneratedColumn<String>(
    'model_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<int> createTime = GeneratedColumn<int>(
    'create_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    parentTurnId,
    promptMd,
    responseMd,
    thoughtsMd,
    modelSlug,
    createTime,
    rawJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turns';
  @override
  VerificationContext validateIntegrity(
    Insertable<Turn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('parent_turn_id')) {
      context.handle(
        _parentTurnIdMeta,
        parentTurnId.isAcceptableOrUnknown(
          data['parent_turn_id']!,
          _parentTurnIdMeta,
        ),
      );
    }
    if (data.containsKey('prompt_md')) {
      context.handle(
        _promptMdMeta,
        promptMd.isAcceptableOrUnknown(data['prompt_md']!, _promptMdMeta),
      );
    }
    if (data.containsKey('response_md')) {
      context.handle(
        _responseMdMeta,
        responseMd.isAcceptableOrUnknown(data['response_md']!, _responseMdMeta),
      );
    }
    if (data.containsKey('thoughts_md')) {
      context.handle(
        _thoughtsMdMeta,
        thoughtsMd.isAcceptableOrUnknown(data['thoughts_md']!, _thoughtsMdMeta),
      );
    }
    if (data.containsKey('model_slug')) {
      context.handle(
        _modelSlugMeta,
        modelSlug.isAcceptableOrUnknown(data['model_slug']!, _modelSlugMeta),
      );
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Turn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Turn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      parentTurnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_turn_id'],
      ),
      promptMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_md'],
      )!,
      responseMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_md'],
      )!,
      thoughtsMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thoughts_md'],
      ),
      modelSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_slug'],
      ),
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_time'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
    );
  }

  @override
  $TurnsTable createAlias(String alias) {
    return $TurnsTable(attachedDatabase, alias);
  }
}

class Turn extends DataClass implements Insertable<Turn> {
  /// Id of the turn's starting message node.
  final String id;
  final String conversationId;

  /// Tree edge; NULL = root turn.
  final String? parentTurnId;
  final String promptMd;
  final String responseMd;

  /// Collapsed reasoning, if any.
  final String? thoughtsMd;
  final String? modelSlug;

  /// Milliseconds since epoch.
  final int? createTime;

  /// Original message nodes, for lossless re-derivation.
  final String rawJson;
  const Turn({
    required this.id,
    required this.conversationId,
    this.parentTurnId,
    required this.promptMd,
    required this.responseMd,
    this.thoughtsMd,
    this.modelSlug,
    this.createTime,
    required this.rawJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || parentTurnId != null) {
      map['parent_turn_id'] = Variable<String>(parentTurnId);
    }
    map['prompt_md'] = Variable<String>(promptMd);
    map['response_md'] = Variable<String>(responseMd);
    if (!nullToAbsent || thoughtsMd != null) {
      map['thoughts_md'] = Variable<String>(thoughtsMd);
    }
    if (!nullToAbsent || modelSlug != null) {
      map['model_slug'] = Variable<String>(modelSlug);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(createTime);
    }
    map['raw_json'] = Variable<String>(rawJson);
    return map;
  }

  TurnsCompanion toCompanion(bool nullToAbsent) {
    return TurnsCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      parentTurnId: parentTurnId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTurnId),
      promptMd: Value(promptMd),
      responseMd: Value(responseMd),
      thoughtsMd: thoughtsMd == null && nullToAbsent
          ? const Value.absent()
          : Value(thoughtsMd),
      modelSlug: modelSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(modelSlug),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
      rawJson: Value(rawJson),
    );
  }

  factory Turn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Turn(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      parentTurnId: serializer.fromJson<String?>(json['parentTurnId']),
      promptMd: serializer.fromJson<String>(json['promptMd']),
      responseMd: serializer.fromJson<String>(json['responseMd']),
      thoughtsMd: serializer.fromJson<String?>(json['thoughtsMd']),
      modelSlug: serializer.fromJson<String?>(json['modelSlug']),
      createTime: serializer.fromJson<int?>(json['createTime']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'parentTurnId': serializer.toJson<String?>(parentTurnId),
      'promptMd': serializer.toJson<String>(promptMd),
      'responseMd': serializer.toJson<String>(responseMd),
      'thoughtsMd': serializer.toJson<String?>(thoughtsMd),
      'modelSlug': serializer.toJson<String?>(modelSlug),
      'createTime': serializer.toJson<int?>(createTime),
      'rawJson': serializer.toJson<String>(rawJson),
    };
  }

  Turn copyWith({
    String? id,
    String? conversationId,
    Value<String?> parentTurnId = const Value.absent(),
    String? promptMd,
    String? responseMd,
    Value<String?> thoughtsMd = const Value.absent(),
    Value<String?> modelSlug = const Value.absent(),
    Value<int?> createTime = const Value.absent(),
    String? rawJson,
  }) => Turn(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    parentTurnId: parentTurnId.present ? parentTurnId.value : this.parentTurnId,
    promptMd: promptMd ?? this.promptMd,
    responseMd: responseMd ?? this.responseMd,
    thoughtsMd: thoughtsMd.present ? thoughtsMd.value : this.thoughtsMd,
    modelSlug: modelSlug.present ? modelSlug.value : this.modelSlug,
    createTime: createTime.present ? createTime.value : this.createTime,
    rawJson: rawJson ?? this.rawJson,
  );
  Turn copyWithCompanion(TurnsCompanion data) {
    return Turn(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      parentTurnId: data.parentTurnId.present
          ? data.parentTurnId.value
          : this.parentTurnId,
      promptMd: data.promptMd.present ? data.promptMd.value : this.promptMd,
      responseMd: data.responseMd.present
          ? data.responseMd.value
          : this.responseMd,
      thoughtsMd: data.thoughtsMd.present
          ? data.thoughtsMd.value
          : this.thoughtsMd,
      modelSlug: data.modelSlug.present ? data.modelSlug.value : this.modelSlug,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Turn(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('parentTurnId: $parentTurnId, ')
          ..write('promptMd: $promptMd, ')
          ..write('responseMd: $responseMd, ')
          ..write('thoughtsMd: $thoughtsMd, ')
          ..write('modelSlug: $modelSlug, ')
          ..write('createTime: $createTime, ')
          ..write('rawJson: $rawJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    parentTurnId,
    promptMd,
    responseMd,
    thoughtsMd,
    modelSlug,
    createTime,
    rawJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Turn &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.parentTurnId == this.parentTurnId &&
          other.promptMd == this.promptMd &&
          other.responseMd == this.responseMd &&
          other.thoughtsMd == this.thoughtsMd &&
          other.modelSlug == this.modelSlug &&
          other.createTime == this.createTime &&
          other.rawJson == this.rawJson);
}

class TurnsCompanion extends UpdateCompanion<Turn> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String?> parentTurnId;
  final Value<String> promptMd;
  final Value<String> responseMd;
  final Value<String?> thoughtsMd;
  final Value<String?> modelSlug;
  final Value<int?> createTime;
  final Value<String> rawJson;
  final Value<int> rowid;
  const TurnsCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.parentTurnId = const Value.absent(),
    this.promptMd = const Value.absent(),
    this.responseMd = const Value.absent(),
    this.thoughtsMd = const Value.absent(),
    this.modelSlug = const Value.absent(),
    this.createTime = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TurnsCompanion.insert({
    required String id,
    required String conversationId,
    this.parentTurnId = const Value.absent(),
    this.promptMd = const Value.absent(),
    this.responseMd = const Value.absent(),
    this.thoughtsMd = const Value.absent(),
    this.modelSlug = const Value.absent(),
    this.createTime = const Value.absent(),
    required String rawJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       rawJson = Value(rawJson);
  static Insertable<Turn> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? parentTurnId,
    Expression<String>? promptMd,
    Expression<String>? responseMd,
    Expression<String>? thoughtsMd,
    Expression<String>? modelSlug,
    Expression<int>? createTime,
    Expression<String>? rawJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (parentTurnId != null) 'parent_turn_id': parentTurnId,
      if (promptMd != null) 'prompt_md': promptMd,
      if (responseMd != null) 'response_md': responseMd,
      if (thoughtsMd != null) 'thoughts_md': thoughtsMd,
      if (modelSlug != null) 'model_slug': modelSlug,
      if (createTime != null) 'create_time': createTime,
      if (rawJson != null) 'raw_json': rawJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TurnsCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String?>? parentTurnId,
    Value<String>? promptMd,
    Value<String>? responseMd,
    Value<String?>? thoughtsMd,
    Value<String?>? modelSlug,
    Value<int?>? createTime,
    Value<String>? rawJson,
    Value<int>? rowid,
  }) {
    return TurnsCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      parentTurnId: parentTurnId ?? this.parentTurnId,
      promptMd: promptMd ?? this.promptMd,
      responseMd: responseMd ?? this.responseMd,
      thoughtsMd: thoughtsMd ?? this.thoughtsMd,
      modelSlug: modelSlug ?? this.modelSlug,
      createTime: createTime ?? this.createTime,
      rawJson: rawJson ?? this.rawJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (parentTurnId.present) {
      map['parent_turn_id'] = Variable<String>(parentTurnId.value);
    }
    if (promptMd.present) {
      map['prompt_md'] = Variable<String>(promptMd.value);
    }
    if (responseMd.present) {
      map['response_md'] = Variable<String>(responseMd.value);
    }
    if (thoughtsMd.present) {
      map['thoughts_md'] = Variable<String>(thoughtsMd.value);
    }
    if (modelSlug.present) {
      map['model_slug'] = Variable<String>(modelSlug.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(createTime.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnsCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('parentTurnId: $parentTurnId, ')
          ..write('promptMd: $promptMd, ')
          ..write('responseMd: $responseMd, ')
          ..write('thoughtsMd: $thoughtsMd, ')
          ..write('modelSlug: $modelSlug, ')
          ..write('createTime: $createTime, ')
          ..write('rawJson: $rawJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TurnAssetsTable extends TurnAssets
    with TableInfo<$TurnAssetsTable, TurnAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  @override
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES turns (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    turnId,
    kind,
    path,
    originalName,
    width,
    height,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turn_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TurnAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  TurnAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TurnAsset(
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
    );
  }

  @override
  $TurnAssetsTable createAlias(String alias) {
    return $TurnAssetsTable(attachedDatabase, alias);
  }
}

class TurnAsset extends DataClass implements Insertable<TurnAsset> {
  final String turnId;

  /// 'prompt' | 'response'.
  final String kind;

  /// Absolute path of the copied asset; '' when the asset was missing from
  /// the export.
  final String path;
  final String? originalName;
  final int? width;
  final int? height;
  const TurnAsset({
    required this.turnId,
    required this.kind,
    required this.path,
    this.originalName,
    this.width,
    this.height,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['turn_id'] = Variable<String>(turnId);
    map['kind'] = Variable<String>(kind);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || originalName != null) {
      map['original_name'] = Variable<String>(originalName);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    return map;
  }

  TurnAssetsCompanion toCompanion(bool nullToAbsent) {
    return TurnAssetsCompanion(
      turnId: Value(turnId),
      kind: Value(kind),
      path: Value(path),
      originalName: originalName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalName),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
    );
  }

  factory TurnAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TurnAsset(
      turnId: serializer.fromJson<String>(json['turnId']),
      kind: serializer.fromJson<String>(json['kind']),
      path: serializer.fromJson<String>(json['path']),
      originalName: serializer.fromJson<String?>(json['originalName']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'turnId': serializer.toJson<String>(turnId),
      'kind': serializer.toJson<String>(kind),
      'path': serializer.toJson<String>(path),
      'originalName': serializer.toJson<String?>(originalName),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
    };
  }

  TurnAsset copyWith({
    String? turnId,
    String? kind,
    String? path,
    Value<String?> originalName = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
  }) => TurnAsset(
    turnId: turnId ?? this.turnId,
    kind: kind ?? this.kind,
    path: path ?? this.path,
    originalName: originalName.present ? originalName.value : this.originalName,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
  );
  TurnAsset copyWithCompanion(TurnAssetsCompanion data) {
    return TurnAsset(
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      kind: data.kind.present ? data.kind.value : this.kind,
      path: data.path.present ? data.path.value : this.path,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TurnAsset(')
          ..write('turnId: $turnId, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('originalName: $originalName, ')
          ..write('width: $width, ')
          ..write('height: $height')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(turnId, kind, path, originalName, width, height);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TurnAsset &&
          other.turnId == this.turnId &&
          other.kind == this.kind &&
          other.path == this.path &&
          other.originalName == this.originalName &&
          other.width == this.width &&
          other.height == this.height);
}

class TurnAssetsCompanion extends UpdateCompanion<TurnAsset> {
  final Value<String> turnId;
  final Value<String> kind;
  final Value<String> path;
  final Value<String?> originalName;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int> rowid;
  const TurnAssetsCompanion({
    this.turnId = const Value.absent(),
    this.kind = const Value.absent(),
    this.path = const Value.absent(),
    this.originalName = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TurnAssetsCompanion.insert({
    required String turnId,
    required String kind,
    required String path,
    this.originalName = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : turnId = Value(turnId),
       kind = Value(kind),
       path = Value(path);
  static Insertable<TurnAsset> custom({
    Expression<String>? turnId,
    Expression<String>? kind,
    Expression<String>? path,
    Expression<String>? originalName,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (turnId != null) 'turn_id': turnId,
      if (kind != null) 'kind': kind,
      if (path != null) 'path': path,
      if (originalName != null) 'original_name': originalName,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TurnAssetsCompanion copyWith({
    Value<String>? turnId,
    Value<String>? kind,
    Value<String>? path,
    Value<String?>? originalName,
    Value<int?>? width,
    Value<int?>? height,
    Value<int>? rowid,
  }) {
    return TurnAssetsCompanion(
      turnId: turnId ?? this.turnId,
      kind: kind ?? this.kind,
      path: path ?? this.path,
      originalName: originalName ?? this.originalName,
      width: width ?? this.width,
      height: height ?? this.height,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnAssetsCompanion(')
          ..write('turnId: $turnId, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('originalName: $originalName, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasStatesTable extends CanvasStates
    with TableInfo<$CanvasStatesTable, CanvasState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewportJsonMeta = const VerificationMeta(
    'viewportJson',
  );
  @override
  late final GeneratedColumn<String> viewportJson = GeneratedColumn<String>(
    'viewport_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('navigate'),
  );
  static const VerificationMeta _focusedTurnIdMeta = const VerificationMeta(
    'focusedTurnId',
  );
  @override
  late final GeneratedColumn<String> focusedTurnId = GeneratedColumn<String>(
    'focused_turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    conversationId,
    viewportJson,
    mode,
    focusedTurnId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('viewport_json')) {
      context.handle(
        _viewportJsonMeta,
        viewportJson.isAcceptableOrUnknown(
          data['viewport_json']!,
          _viewportJsonMeta,
        ),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('focused_turn_id')) {
      context.handle(
        _focusedTurnIdMeta,
        focusedTurnId.isAcceptableOrUnknown(
          data['focused_turn_id']!,
          _focusedTurnIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  CanvasState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasState(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      viewportJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}viewport_json'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      focusedTurnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}focused_turn_id'],
      ),
    );
  }

  @override
  $CanvasStatesTable createAlias(String alias) {
    return $CanvasStatesTable(attachedDatabase, alias);
  }
}

class CanvasState extends DataClass implements Insertable<CanvasState> {
  final String conversationId;
  final String? viewportJson;

  /// 'navigate' | 'read'.
  final String mode;
  final String? focusedTurnId;
  const CanvasState({
    required this.conversationId,
    this.viewportJson,
    required this.mode,
    this.focusedTurnId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || viewportJson != null) {
      map['viewport_json'] = Variable<String>(viewportJson);
    }
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || focusedTurnId != null) {
      map['focused_turn_id'] = Variable<String>(focusedTurnId);
    }
    return map;
  }

  CanvasStatesCompanion toCompanion(bool nullToAbsent) {
    return CanvasStatesCompanion(
      conversationId: Value(conversationId),
      viewportJson: viewportJson == null && nullToAbsent
          ? const Value.absent()
          : Value(viewportJson),
      mode: Value(mode),
      focusedTurnId: focusedTurnId == null && nullToAbsent
          ? const Value.absent()
          : Value(focusedTurnId),
    );
  }

  factory CanvasState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasState(
      conversationId: serializer.fromJson<String>(json['conversationId']),
      viewportJson: serializer.fromJson<String?>(json['viewportJson']),
      mode: serializer.fromJson<String>(json['mode']),
      focusedTurnId: serializer.fromJson<String?>(json['focusedTurnId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<String>(conversationId),
      'viewportJson': serializer.toJson<String?>(viewportJson),
      'mode': serializer.toJson<String>(mode),
      'focusedTurnId': serializer.toJson<String?>(focusedTurnId),
    };
  }

  CanvasState copyWith({
    String? conversationId,
    Value<String?> viewportJson = const Value.absent(),
    String? mode,
    Value<String?> focusedTurnId = const Value.absent(),
  }) => CanvasState(
    conversationId: conversationId ?? this.conversationId,
    viewportJson: viewportJson.present ? viewportJson.value : this.viewportJson,
    mode: mode ?? this.mode,
    focusedTurnId: focusedTurnId.present
        ? focusedTurnId.value
        : this.focusedTurnId,
  );
  CanvasState copyWithCompanion(CanvasStatesCompanion data) {
    return CanvasState(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      viewportJson: data.viewportJson.present
          ? data.viewportJson.value
          : this.viewportJson,
      mode: data.mode.present ? data.mode.value : this.mode,
      focusedTurnId: data.focusedTurnId.present
          ? data.focusedTurnId.value
          : this.focusedTurnId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasState(')
          ..write('conversationId: $conversationId, ')
          ..write('viewportJson: $viewportJson, ')
          ..write('mode: $mode, ')
          ..write('focusedTurnId: $focusedTurnId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(conversationId, viewportJson, mode, focusedTurnId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasState &&
          other.conversationId == this.conversationId &&
          other.viewportJson == this.viewportJson &&
          other.mode == this.mode &&
          other.focusedTurnId == this.focusedTurnId);
}

class CanvasStatesCompanion extends UpdateCompanion<CanvasState> {
  final Value<String> conversationId;
  final Value<String?> viewportJson;
  final Value<String> mode;
  final Value<String?> focusedTurnId;
  final Value<int> rowid;
  const CanvasStatesCompanion({
    this.conversationId = const Value.absent(),
    this.viewportJson = const Value.absent(),
    this.mode = const Value.absent(),
    this.focusedTurnId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasStatesCompanion.insert({
    required String conversationId,
    this.viewportJson = const Value.absent(),
    this.mode = const Value.absent(),
    this.focusedTurnId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId);
  static Insertable<CanvasState> custom({
    Expression<String>? conversationId,
    Expression<String>? viewportJson,
    Expression<String>? mode,
    Expression<String>? focusedTurnId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (viewportJson != null) 'viewport_json': viewportJson,
      if (mode != null) 'mode': mode,
      if (focusedTurnId != null) 'focused_turn_id': focusedTurnId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasStatesCompanion copyWith({
    Value<String>? conversationId,
    Value<String?>? viewportJson,
    Value<String>? mode,
    Value<String?>? focusedTurnId,
    Value<int>? rowid,
  }) {
    return CanvasStatesCompanion(
      conversationId: conversationId ?? this.conversationId,
      viewportJson: viewportJson ?? this.viewportJson,
      mode: mode ?? this.mode,
      focusedTurnId: focusedTurnId ?? this.focusedTurnId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (viewportJson.present) {
      map['viewport_json'] = Variable<String>(viewportJson.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (focusedTurnId.present) {
      map['focused_turn_id'] = Variable<String>(focusedTurnId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasStatesCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('viewportJson: $viewportJson, ')
          ..write('mode: $mode, ')
          ..write('focusedTurnId: $focusedTurnId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportsTable extends Imports with TableInfo<$ImportsTable, Import> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationsMeta = const VerificationMeta(
    'conversations',
  );
  @override
  late final GeneratedColumn<int> conversations = GeneratedColumn<int>(
    'conversations',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _turnsMeta = const VerificationMeta('turns');
  @override
  late final GeneratedColumn<int> turns = GeneratedColumn<int>(
    'turns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _warningsJsonMeta = const VerificationMeta(
    'warningsJson',
  );
  @override
  late final GeneratedColumn<String> warningsJson = GeneratedColumn<String>(
    'warnings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    finishedAt,
    sourcePath,
    conversations,
    turns,
    warningsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Import> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    if (data.containsKey('conversations')) {
      context.handle(
        _conversationsMeta,
        conversations.isAcceptableOrUnknown(
          data['conversations']!,
          _conversationsMeta,
        ),
      );
    }
    if (data.containsKey('turns')) {
      context.handle(
        _turnsMeta,
        turns.isAcceptableOrUnknown(data['turns']!, _turnsMeta),
      );
    }
    if (data.containsKey('warnings_json')) {
      context.handle(
        _warningsJsonMeta,
        warningsJson.isAcceptableOrUnknown(
          data['warnings_json']!,
          _warningsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Import map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Import(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
      conversations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversations'],
      )!,
      turns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turns'],
      )!,
      warningsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings_json'],
      )!,
    );
  }

  @override
  $ImportsTable createAlias(String alias) {
    return $ImportsTable(attachedDatabase, alias);
  }
}

class Import extends DataClass implements Insertable<Import> {
  final int id;
  final int startedAt;
  final int? finishedAt;
  final String sourcePath;
  final int conversations;
  final int turns;
  final String warningsJson;
  const Import({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.sourcePath,
    required this.conversations,
    required this.turns,
    required this.warningsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    map['source_path'] = Variable<String>(sourcePath);
    map['conversations'] = Variable<int>(conversations);
    map['turns'] = Variable<int>(turns);
    map['warnings_json'] = Variable<String>(warningsJson);
    return map;
  }

  ImportsCompanion toCompanion(bool nullToAbsent) {
    return ImportsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      sourcePath: Value(sourcePath),
      conversations: Value(conversations),
      turns: Value(turns),
      warningsJson: Value(warningsJson),
    );
  }

  factory Import.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Import(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
      conversations: serializer.fromJson<int>(json['conversations']),
      turns: serializer.fromJson<int>(json['turns']),
      warningsJson: serializer.fromJson<String>(json['warningsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'sourcePath': serializer.toJson<String>(sourcePath),
      'conversations': serializer.toJson<int>(conversations),
      'turns': serializer.toJson<int>(turns),
      'warningsJson': serializer.toJson<String>(warningsJson),
    };
  }

  Import copyWith({
    int? id,
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
    String? sourcePath,
    int? conversations,
    int? turns,
    String? warningsJson,
  }) => Import(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    sourcePath: sourcePath ?? this.sourcePath,
    conversations: conversations ?? this.conversations,
    turns: turns ?? this.turns,
    warningsJson: warningsJson ?? this.warningsJson,
  );
  Import copyWithCompanion(ImportsCompanion data) {
    return Import(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      conversations: data.conversations.present
          ? data.conversations.value
          : this.conversations,
      turns: data.turns.present ? data.turns.value : this.turns,
      warningsJson: data.warningsJson.present
          ? data.warningsJson.value
          : this.warningsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Import(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('conversations: $conversations, ')
          ..write('turns: $turns, ')
          ..write('warningsJson: $warningsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    finishedAt,
    sourcePath,
    conversations,
    turns,
    warningsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Import &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.sourcePath == this.sourcePath &&
          other.conversations == this.conversations &&
          other.turns == this.turns &&
          other.warningsJson == this.warningsJson);
}

class ImportsCompanion extends UpdateCompanion<Import> {
  final Value<int> id;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<String> sourcePath;
  final Value<int> conversations;
  final Value<int> turns;
  final Value<String> warningsJson;
  const ImportsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.conversations = const Value.absent(),
    this.turns = const Value.absent(),
    this.warningsJson = const Value.absent(),
  });
  ImportsCompanion.insert({
    this.id = const Value.absent(),
    required int startedAt,
    this.finishedAt = const Value.absent(),
    required String sourcePath,
    this.conversations = const Value.absent(),
    this.turns = const Value.absent(),
    this.warningsJson = const Value.absent(),
  }) : startedAt = Value(startedAt),
       sourcePath = Value(sourcePath);
  static Insertable<Import> custom({
    Expression<int>? id,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<String>? sourcePath,
    Expression<int>? conversations,
    Expression<int>? turns,
    Expression<String>? warningsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (sourcePath != null) 'source_path': sourcePath,
      if (conversations != null) 'conversations': conversations,
      if (turns != null) 'turns': turns,
      if (warningsJson != null) 'warnings_json': warningsJson,
    });
  }

  ImportsCompanion copyWith({
    Value<int>? id,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<String>? sourcePath,
    Value<int>? conversations,
    Value<int>? turns,
    Value<String>? warningsJson,
  }) {
    return ImportsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      sourcePath: sourcePath ?? this.sourcePath,
      conversations: conversations ?? this.conversations,
      turns: turns ?? this.turns,
      warningsJson: warningsJson ?? this.warningsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (conversations.present) {
      map['conversations'] = Variable<int>(conversations.value);
    }
    if (turns.present) {
      map['turns'] = Variable<int>(turns.value);
    }
    if (warningsJson.present) {
      map['warnings_json'] = Variable<String>(warningsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('conversations: $conversations, ')
          ..write('turns: $turns, ')
          ..write('warningsJson: $warningsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $TurnsTable turns = $TurnsTable(this);
  late final $TurnAssetsTable turnAssets = $TurnAssetsTable(this);
  late final $CanvasStatesTable canvasStates = $CanvasStatesTable(this);
  late final $ImportsTable imports = $ImportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    turns,
    turnAssets,
    canvasStates,
    imports,
  ];
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String> title,
      Value<int?> createTime,
      Value<int?> updateTime,
      Value<bool> isArchived,
      Value<bool> isStarred,
      Value<String?> defaultModelSlug,
      Value<String?> currentTurnId,
      required String source,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int?> createTime,
      Value<int?> updateTime,
      Value<bool> isArchived,
      Value<bool> isStarred,
      Value<String?> defaultModelSlug,
      Value<String?> currentTurnId,
      Value<String> source,
      Value<int> rowid,
    });

final class $$ConversationsTableReferences
    extends BaseReferences<_$AppDatabase, $ConversationsTable, Conversation> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TurnsTable, List<Turn>> _turnsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.turns,
    aliasName: $_aliasNameGenerator(
      db.conversations.id,
      db.turns.conversationId,
    ),
  );

  $$TurnsTableProcessedTableManager get turnsRefs {
    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_turnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultModelSlug => $composableBuilder(
    column: $table.defaultModelSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentTurnId => $composableBuilder(
    column: $table.currentTurnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> turnsRefs(
    Expression<bool> Function($$TurnsTableFilterComposer f) f,
  ) {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultModelSlug => $composableBuilder(
    column: $table.defaultModelSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentTurnId => $composableBuilder(
    column: $table.currentTurnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<String> get defaultModelSlug => $composableBuilder(
    column: $table.defaultModelSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentTurnId => $composableBuilder(
    column: $table.currentTurnId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> turnsRefs<T extends Object>(
    Expression<T> Function($$TurnsTableAnnotationComposer a) f,
  ) {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (Conversation, $$ConversationsTableReferences),
          Conversation,
          PrefetchHooks Function({bool turnsRefs})
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                Value<int?> updateTime = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String?> defaultModelSlug = const Value.absent(),
                Value<String?> currentTurnId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                createTime: createTime,
                updateTime: updateTime,
                isArchived: isArchived,
                isStarred: isStarred,
                defaultModelSlug: defaultModelSlug,
                currentTurnId: currentTurnId,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                Value<int?> updateTime = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String?> defaultModelSlug = const Value.absent(),
                Value<String?> currentTurnId = const Value.absent(),
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                createTime: createTime,
                updateTime: updateTime,
                isArchived: isArchived,
                isStarred: isStarred,
                defaultModelSlug: defaultModelSlug,
                currentTurnId: currentTurnId,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({turnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (turnsRefs) db.turns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (turnsRefs)
                    await $_getPrefetchedData<
                      Conversation,
                      $ConversationsTable,
                      Turn
                    >(
                      currentTable: table,
                      referencedTable: $$ConversationsTableReferences
                          ._turnsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConversationsTableReferences(
                            db,
                            table,
                            p0,
                          ).turnsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.conversationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (Conversation, $$ConversationsTableReferences),
      Conversation,
      PrefetchHooks Function({bool turnsRefs})
    >;
typedef $$TurnsTableCreateCompanionBuilder =
    TurnsCompanion Function({
      required String id,
      required String conversationId,
      Value<String?> parentTurnId,
      Value<String> promptMd,
      Value<String> responseMd,
      Value<String?> thoughtsMd,
      Value<String?> modelSlug,
      Value<int?> createTime,
      required String rawJson,
      Value<int> rowid,
    });
typedef $$TurnsTableUpdateCompanionBuilder =
    TurnsCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String?> parentTurnId,
      Value<String> promptMd,
      Value<String> responseMd,
      Value<String?> thoughtsMd,
      Value<String?> modelSlug,
      Value<int?> createTime,
      Value<String> rawJson,
      Value<int> rowid,
    });

final class $$TurnsTableReferences
    extends BaseReferences<_$AppDatabase, $TurnsTable, Turn> {
  $$TurnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias(
        $_aliasNameGenerator(db.turns.conversationId, db.conversations.id),
      );

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TurnAssetsTable, List<TurnAsset>>
  _turnAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.turnAssets,
    aliasName: $_aliasNameGenerator(db.turns.id, db.turnAssets.turnId),
  );

  $$TurnAssetsTableProcessedTableManager get turnAssetsRefs {
    final manager = $$TurnAssetsTableTableManager(
      $_db,
      $_db.turnAssets,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_turnAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TurnsTableFilterComposer extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTurnId => $composableBuilder(
    column: $table.parentTurnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptMd => $composableBuilder(
    column: $table.promptMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseMd => $composableBuilder(
    column: $table.responseMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thoughtsMd => $composableBuilder(
    column: $table.thoughtsMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelSlug => $composableBuilder(
    column: $table.modelSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> turnAssetsRefs(
    Expression<bool> Function($$TurnAssetsTableFilterComposer f) f,
  ) {
    final $$TurnAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turnAssets,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnAssetsTableFilterComposer(
            $db: $db,
            $table: $db.turnAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTurnId => $composableBuilder(
    column: $table.parentTurnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptMd => $composableBuilder(
    column: $table.promptMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseMd => $composableBuilder(
    column: $table.responseMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thoughtsMd => $composableBuilder(
    column: $table.thoughtsMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelSlug => $composableBuilder(
    column: $table.modelSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TurnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentTurnId => $composableBuilder(
    column: $table.parentTurnId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get promptMd =>
      $composableBuilder(column: $table.promptMd, builder: (column) => column);

  GeneratedColumn<String> get responseMd => $composableBuilder(
    column: $table.responseMd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thoughtsMd => $composableBuilder(
    column: $table.thoughtsMd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelSlug =>
      $composableBuilder(column: $table.modelSlug, builder: (column) => column);

  GeneratedColumn<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> turnAssetsRefs<T extends Object>(
    Expression<T> Function($$TurnAssetsTableAnnotationComposer a) f,
  ) {
    final $$TurnAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turnAssets,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.turnAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TurnsTable,
          Turn,
          $$TurnsTableFilterComposer,
          $$TurnsTableOrderingComposer,
          $$TurnsTableAnnotationComposer,
          $$TurnsTableCreateCompanionBuilder,
          $$TurnsTableUpdateCompanionBuilder,
          (Turn, $$TurnsTableReferences),
          Turn,
          PrefetchHooks Function({bool conversationId, bool turnAssetsRefs})
        > {
  $$TurnsTableTableManager(_$AppDatabase db, $TurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String?> parentTurnId = const Value.absent(),
                Value<String> promptMd = const Value.absent(),
                Value<String> responseMd = const Value.absent(),
                Value<String?> thoughtsMd = const Value.absent(),
                Value<String?> modelSlug = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurnsCompanion(
                id: id,
                conversationId: conversationId,
                parentTurnId: parentTurnId,
                promptMd: promptMd,
                responseMd: responseMd,
                thoughtsMd: thoughtsMd,
                modelSlug: modelSlug,
                createTime: createTime,
                rawJson: rawJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                Value<String?> parentTurnId = const Value.absent(),
                Value<String> promptMd = const Value.absent(),
                Value<String> responseMd = const Value.absent(),
                Value<String?> thoughtsMd = const Value.absent(),
                Value<String?> modelSlug = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                required String rawJson,
                Value<int> rowid = const Value.absent(),
              }) => TurnsCompanion.insert(
                id: id,
                conversationId: conversationId,
                parentTurnId: parentTurnId,
                promptMd: promptMd,
                responseMd: responseMd,
                thoughtsMd: thoughtsMd,
                modelSlug: modelSlug,
                createTime: createTime,
                rawJson: rawJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TurnsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationId = false, turnAssetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (turnAssetsRefs) db.turnAssets],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (conversationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.conversationId,
                                    referencedTable: $$TurnsTableReferences
                                        ._conversationIdTable(db),
                                    referencedColumn: $$TurnsTableReferences
                                        ._conversationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (turnAssetsRefs)
                        await $_getPrefetchedData<Turn, $TurnsTable, TurnAsset>(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._turnAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).turnAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.turnId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TurnsTable,
      Turn,
      $$TurnsTableFilterComposer,
      $$TurnsTableOrderingComposer,
      $$TurnsTableAnnotationComposer,
      $$TurnsTableCreateCompanionBuilder,
      $$TurnsTableUpdateCompanionBuilder,
      (Turn, $$TurnsTableReferences),
      Turn,
      PrefetchHooks Function({bool conversationId, bool turnAssetsRefs})
    >;
typedef $$TurnAssetsTableCreateCompanionBuilder =
    TurnAssetsCompanion Function({
      required String turnId,
      required String kind,
      required String path,
      Value<String?> originalName,
      Value<int?> width,
      Value<int?> height,
      Value<int> rowid,
    });
typedef $$TurnAssetsTableUpdateCompanionBuilder =
    TurnAssetsCompanion Function({
      Value<String> turnId,
      Value<String> kind,
      Value<String> path,
      Value<String?> originalName,
      Value<int?> width,
      Value<int?> height,
      Value<int> rowid,
    });

final class $$TurnAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $TurnAssetsTable, TurnAsset> {
  $$TurnAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.turnAssets.turnId, db.turns.id),
  );

  $$TurnsTableProcessedTableManager get turnId {
    final $_column = $_itemColumn<String>('turn_id')!;

    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_turnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TurnAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $TurnAssetsTable> {
  $$TurnAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  $$TurnsTableFilterComposer get turnId {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TurnAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnAssetsTable> {
  $$TurnAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  $$TurnsTableOrderingComposer get turnId {
    final $$TurnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableOrderingComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TurnAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnAssetsTable> {
  $$TurnAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  $$TurnsTableAnnotationComposer get turnId {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TurnAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TurnAssetsTable,
          TurnAsset,
          $$TurnAssetsTableFilterComposer,
          $$TurnAssetsTableOrderingComposer,
          $$TurnAssetsTableAnnotationComposer,
          $$TurnAssetsTableCreateCompanionBuilder,
          $$TurnAssetsTableUpdateCompanionBuilder,
          (TurnAsset, $$TurnAssetsTableReferences),
          TurnAsset,
          PrefetchHooks Function({bool turnId})
        > {
  $$TurnAssetsTableTableManager(_$AppDatabase db, $TurnAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> turnId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurnAssetsCompanion(
                turnId: turnId,
                kind: kind,
                path: path,
                originalName: originalName,
                width: width,
                height: height,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String turnId,
                required String kind,
                required String path,
                Value<String?> originalName = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurnAssetsCompanion.insert(
                turnId: turnId,
                kind: kind,
                path: path,
                originalName: originalName,
                width: width,
                height: height,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TurnAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({turnId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable: $$TurnAssetsTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$TurnAssetsTableReferences
                                    ._turnIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TurnAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TurnAssetsTable,
      TurnAsset,
      $$TurnAssetsTableFilterComposer,
      $$TurnAssetsTableOrderingComposer,
      $$TurnAssetsTableAnnotationComposer,
      $$TurnAssetsTableCreateCompanionBuilder,
      $$TurnAssetsTableUpdateCompanionBuilder,
      (TurnAsset, $$TurnAssetsTableReferences),
      TurnAsset,
      PrefetchHooks Function({bool turnId})
    >;
typedef $$CanvasStatesTableCreateCompanionBuilder =
    CanvasStatesCompanion Function({
      required String conversationId,
      Value<String?> viewportJson,
      Value<String> mode,
      Value<String?> focusedTurnId,
      Value<int> rowid,
    });
typedef $$CanvasStatesTableUpdateCompanionBuilder =
    CanvasStatesCompanion Function({
      Value<String> conversationId,
      Value<String?> viewportJson,
      Value<String> mode,
      Value<String?> focusedTurnId,
      Value<int> rowid,
    });

class $$CanvasStatesTableFilterComposer
    extends Composer<_$AppDatabase, $CanvasStatesTable> {
  $$CanvasStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewportJson => $composableBuilder(
    column: $table.viewportJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get focusedTurnId => $composableBuilder(
    column: $table.focusedTurnId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CanvasStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CanvasStatesTable> {
  $$CanvasStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewportJson => $composableBuilder(
    column: $table.viewportJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get focusedTurnId => $composableBuilder(
    column: $table.focusedTurnId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CanvasStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CanvasStatesTable> {
  $$CanvasStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get viewportJson => $composableBuilder(
    column: $table.viewportJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get focusedTurnId => $composableBuilder(
    column: $table.focusedTurnId,
    builder: (column) => column,
  );
}

class $$CanvasStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CanvasStatesTable,
          CanvasState,
          $$CanvasStatesTableFilterComposer,
          $$CanvasStatesTableOrderingComposer,
          $$CanvasStatesTableAnnotationComposer,
          $$CanvasStatesTableCreateCompanionBuilder,
          $$CanvasStatesTableUpdateCompanionBuilder,
          (
            CanvasState,
            BaseReferences<_$AppDatabase, $CanvasStatesTable, CanvasState>,
          ),
          CanvasState,
          PrefetchHooks Function()
        > {
  $$CanvasStatesTableTableManager(_$AppDatabase db, $CanvasStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversationId = const Value.absent(),
                Value<String?> viewportJson = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> focusedTurnId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasStatesCompanion(
                conversationId: conversationId,
                viewportJson: viewportJson,
                mode: mode,
                focusedTurnId: focusedTurnId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversationId,
                Value<String?> viewportJson = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> focusedTurnId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasStatesCompanion.insert(
                conversationId: conversationId,
                viewportJson: viewportJson,
                mode: mode,
                focusedTurnId: focusedTurnId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CanvasStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CanvasStatesTable,
      CanvasState,
      $$CanvasStatesTableFilterComposer,
      $$CanvasStatesTableOrderingComposer,
      $$CanvasStatesTableAnnotationComposer,
      $$CanvasStatesTableCreateCompanionBuilder,
      $$CanvasStatesTableUpdateCompanionBuilder,
      (
        CanvasState,
        BaseReferences<_$AppDatabase, $CanvasStatesTable, CanvasState>,
      ),
      CanvasState,
      PrefetchHooks Function()
    >;
typedef $$ImportsTableCreateCompanionBuilder =
    ImportsCompanion Function({
      Value<int> id,
      required int startedAt,
      Value<int?> finishedAt,
      required String sourcePath,
      Value<int> conversations,
      Value<int> turns,
      Value<String> warningsJson,
    });
typedef $$ImportsTableUpdateCompanionBuilder =
    ImportsCompanion Function({
      Value<int> id,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<String> sourcePath,
      Value<int> conversations,
      Value<int> turns,
      Value<String> warningsJson,
    });

class $$ImportsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conversations => $composableBuilder(
    column: $table.conversations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get turns => $composableBuilder(
    column: $table.turns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conversations => $composableBuilder(
    column: $table.conversations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turns => $composableBuilder(
    column: $table.turns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get conversations => $composableBuilder(
    column: $table.conversations,
    builder: (column) => column,
  );

  GeneratedColumn<int> get turns =>
      $composableBuilder(column: $table.turns, builder: (column) => column);

  GeneratedColumn<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => column,
  );
}

class $$ImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportsTable,
          Import,
          $$ImportsTableFilterComposer,
          $$ImportsTableOrderingComposer,
          $$ImportsTableAnnotationComposer,
          $$ImportsTableCreateCompanionBuilder,
          $$ImportsTableUpdateCompanionBuilder,
          (Import, BaseReferences<_$AppDatabase, $ImportsTable, Import>),
          Import,
          PrefetchHooks Function()
        > {
  $$ImportsTableTableManager(_$AppDatabase db, $ImportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
                Value<int> conversations = const Value.absent(),
                Value<int> turns = const Value.absent(),
                Value<String> warningsJson = const Value.absent(),
              }) => ImportsCompanion(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                sourcePath: sourcePath,
                conversations: conversations,
                turns: turns,
                warningsJson: warningsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startedAt,
                Value<int?> finishedAt = const Value.absent(),
                required String sourcePath,
                Value<int> conversations = const Value.absent(),
                Value<int> turns = const Value.absent(),
                Value<String> warningsJson = const Value.absent(),
              }) => ImportsCompanion.insert(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                sourcePath: sourcePath,
                conversations: conversations,
                turns: turns,
                warningsJson: warningsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportsTable,
      Import,
      $$ImportsTableFilterComposer,
      $$ImportsTableOrderingComposer,
      $$ImportsTableAnnotationComposer,
      $$ImportsTableCreateCompanionBuilder,
      $$ImportsTableUpdateCompanionBuilder,
      (Import, BaseReferences<_$AppDatabase, $ImportsTable, Import>),
      Import,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db, _db.turns);
  $$TurnAssetsTableTableManager get turnAssets =>
      $$TurnAssetsTableTableManager(_db, _db.turnAssets);
  $$CanvasStatesTableTableManager get canvasStates =>
      $$CanvasStatesTableTableManager(_db, _db.canvasStates);
  $$ImportsTableTableManager get imports =>
      $$ImportsTableTableManager(_db, _db.imports);
}
