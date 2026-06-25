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
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<int> lastMessageAt = GeneratedColumn<int>(
    'last_message_at',
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
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _indexStateMeta = const VerificationMeta(
    'indexState',
  );
  @override
  late final GeneratedColumn<int> indexState = GeneratedColumn<int>(
    'index_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<int> indexedAt = GeneratedColumn<int>(
    'indexed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createTime,
    updateTime,
    lastMessageAt,
    isArchived,
    isStarred,
    defaultModelSlug,
    currentTurnId,
    source,
    projectId,
    indexState,
    indexedAt,
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
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
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
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('index_state')) {
      context.handle(
        _indexStateMeta,
        indexState.isAcceptableOrUnknown(data['index_state']!, _indexStateMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
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
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_at'],
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
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      indexState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}index_state'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indexed_at'],
      ),
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

  /// Milliseconds since epoch of the conversation's most recent message
  /// (`MAX` of its turns' `create_time`). The export's `update_time` is bumped
  /// by server-side touches unrelated to messages — a bulk migration can stamp
  /// a years-old conversation as "today" — so it is unreliable for "when did
  /// this happen". This derived value drives sidebar ordering and the shown
  /// date instead; NULL when no turn carries a timestamp.
  final int? lastMessageAt;
  final bool isArchived;
  final bool isStarred;
  final String? defaultModelSlug;

  /// Derived from the export's `current_node`.
  final String? currentTurnId;

  /// Importer plugin id, e.g. 'chatgpt_export'.
  final String source;

  /// Project tier (DESIGN.md §10). Conceptual FK to `projects.id`; defaults to
  /// the single 'default' project created by migration v3.
  final String projectId;

  /// Lazy-index state machine (DESIGN.md §10):
  /// 0=notIndexed 1=indexing 2=indexed 3=stale.
  final int indexState;

  /// Milliseconds since epoch the conversation was last indexed; NULL until
  /// indexed.
  final int? indexedAt;
  const Conversation({
    required this.id,
    required this.title,
    this.createTime,
    this.updateTime,
    this.lastMessageAt,
    required this.isArchived,
    required this.isStarred,
    this.defaultModelSlug,
    this.currentTurnId,
    required this.source,
    required this.projectId,
    required this.indexState,
    this.indexedAt,
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
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<int>(lastMessageAt);
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
    map['project_id'] = Variable<String>(projectId);
    map['index_state'] = Variable<int>(indexState);
    if (!nullToAbsent || indexedAt != null) {
      map['indexed_at'] = Variable<int>(indexedAt);
    }
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
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      isArchived: Value(isArchived),
      isStarred: Value(isStarred),
      defaultModelSlug: defaultModelSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultModelSlug),
      currentTurnId: currentTurnId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentTurnId),
      source: Value(source),
      projectId: Value(projectId),
      indexState: Value(indexState),
      indexedAt: indexedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(indexedAt),
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
      lastMessageAt: serializer.fromJson<int?>(json['lastMessageAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      defaultModelSlug: serializer.fromJson<String?>(json['defaultModelSlug']),
      currentTurnId: serializer.fromJson<String?>(json['currentTurnId']),
      source: serializer.fromJson<String>(json['source']),
      projectId: serializer.fromJson<String>(json['projectId']),
      indexState: serializer.fromJson<int>(json['indexState']),
      indexedAt: serializer.fromJson<int?>(json['indexedAt']),
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
      'lastMessageAt': serializer.toJson<int?>(lastMessageAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isStarred': serializer.toJson<bool>(isStarred),
      'defaultModelSlug': serializer.toJson<String?>(defaultModelSlug),
      'currentTurnId': serializer.toJson<String?>(currentTurnId),
      'source': serializer.toJson<String>(source),
      'projectId': serializer.toJson<String>(projectId),
      'indexState': serializer.toJson<int>(indexState),
      'indexedAt': serializer.toJson<int?>(indexedAt),
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    Value<int?> createTime = const Value.absent(),
    Value<int?> updateTime = const Value.absent(),
    Value<int?> lastMessageAt = const Value.absent(),
    bool? isArchived,
    bool? isStarred,
    Value<String?> defaultModelSlug = const Value.absent(),
    Value<String?> currentTurnId = const Value.absent(),
    String? source,
    String? projectId,
    int? indexState,
    Value<int?> indexedAt = const Value.absent(),
  }) => Conversation(
    id: id ?? this.id,
    title: title ?? this.title,
    createTime: createTime.present ? createTime.value : this.createTime,
    updateTime: updateTime.present ? updateTime.value : this.updateTime,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    isArchived: isArchived ?? this.isArchived,
    isStarred: isStarred ?? this.isStarred,
    defaultModelSlug: defaultModelSlug.present
        ? defaultModelSlug.value
        : this.defaultModelSlug,
    currentTurnId: currentTurnId.present
        ? currentTurnId.value
        : this.currentTurnId,
    source: source ?? this.source,
    projectId: projectId ?? this.projectId,
    indexState: indexState ?? this.indexState,
    indexedAt: indexedAt.present ? indexedAt.value : this.indexedAt,
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
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
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
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      indexState: data.indexState.present
          ? data.indexState.value
          : this.indexState,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isStarred: $isStarred, ')
          ..write('defaultModelSlug: $defaultModelSlug, ')
          ..write('currentTurnId: $currentTurnId, ')
          ..write('source: $source, ')
          ..write('projectId: $projectId, ')
          ..write('indexState: $indexState, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createTime,
    updateTime,
    lastMessageAt,
    isArchived,
    isStarred,
    defaultModelSlug,
    currentTurnId,
    source,
    projectId,
    indexState,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.createTime == this.createTime &&
          other.updateTime == this.updateTime &&
          other.lastMessageAt == this.lastMessageAt &&
          other.isArchived == this.isArchived &&
          other.isStarred == this.isStarred &&
          other.defaultModelSlug == this.defaultModelSlug &&
          other.currentTurnId == this.currentTurnId &&
          other.source == this.source &&
          other.projectId == this.projectId &&
          other.indexState == this.indexState &&
          other.indexedAt == this.indexedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> title;
  final Value<int?> createTime;
  final Value<int?> updateTime;
  final Value<int?> lastMessageAt;
  final Value<bool> isArchived;
  final Value<bool> isStarred;
  final Value<String?> defaultModelSlug;
  final Value<String?> currentTurnId;
  final Value<String> source;
  final Value<String> projectId;
  final Value<int> indexState;
  final Value<int?> indexedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.defaultModelSlug = const Value.absent(),
    this.currentTurnId = const Value.absent(),
    this.source = const Value.absent(),
    this.projectId = const Value.absent(),
    this.indexState = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.defaultModelSlug = const Value.absent(),
    this.currentTurnId = const Value.absent(),
    required String source,
    this.projectId = const Value.absent(),
    this.indexState = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? createTime,
    Expression<int>? updateTime,
    Expression<int>? lastMessageAt,
    Expression<bool>? isArchived,
    Expression<bool>? isStarred,
    Expression<String>? defaultModelSlug,
    Expression<String>? currentTurnId,
    Expression<String>? source,
    Expression<String>? projectId,
    Expression<int>? indexState,
    Expression<int>? indexedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createTime != null) 'create_time': createTime,
      if (updateTime != null) 'update_time': updateTime,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (isStarred != null) 'is_starred': isStarred,
      if (defaultModelSlug != null) 'default_model_slug': defaultModelSlug,
      if (currentTurnId != null) 'current_turn_id': currentTurnId,
      if (source != null) 'source': source,
      if (projectId != null) 'project_id': projectId,
      if (indexState != null) 'index_state': indexState,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int?>? createTime,
    Value<int?>? updateTime,
    Value<int?>? lastMessageAt,
    Value<bool>? isArchived,
    Value<bool>? isStarred,
    Value<String?>? defaultModelSlug,
    Value<String?>? currentTurnId,
    Value<String>? source,
    Value<String>? projectId,
    Value<int>? indexState,
    Value<int?>? indexedAt,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isArchived: isArchived ?? this.isArchived,
      isStarred: isStarred ?? this.isStarred,
      defaultModelSlug: defaultModelSlug ?? this.defaultModelSlug,
      currentTurnId: currentTurnId ?? this.currentTurnId,
      source: source ?? this.source,
      projectId: projectId ?? this.projectId,
      indexState: indexState ?? this.indexState,
      indexedAt: indexedAt ?? this.indexedAt,
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
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<int>(lastMessageAt.value);
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
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (indexState.present) {
      map['index_state'] = Variable<int>(indexState.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<int>(indexedAt.value);
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
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isStarred: $isStarred, ')
          ..write('defaultModelSlug: $defaultModelSlug, ')
          ..write('currentTurnId: $currentTurnId, ')
          ..write('source: $source, ')
          ..write('projectId: $projectId, ')
          ..write('indexState: $indexState, ')
          ..write('indexedAt: $indexedAt, ')
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
  /// `<conversation_id>:<node_id>` where `node_id` is the turn's starting
  /// message node. The conversation prefix is required because real exports
  /// contain server-side conversation copies that reuse node ids.
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

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;

  /// Milliseconds since epoch.
  final int? createdAt;
  const Project({required this.id, required this.name, this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    Value<int?> createdAt = const Value.absent(),
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? createdAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PropositionsTable extends Propositions
    with TableInfo<$PropositionsTable, Proposition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PropositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _propTextMeta = const VerificationMeta(
    'propText',
  );
  @override
  late final GeneratedColumn<String> propText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aspectMeta = const VerificationMeta('aspect');
  @override
  late final GeneratedColumn<String> aspect = GeneratedColumn<String>(
    'aspect',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingModelMeta = const VerificationMeta(
    'embeddingModel',
  );
  @override
  late final GeneratedColumn<String> embeddingModel = GeneratedColumn<String>(
    'embedding_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    turnId,
    conversationId,
    projectId,
    propText,
    aspect,
    embedding,
    embeddingModel,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'propositions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Proposition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
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
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _propTextMeta,
        propText.isAcceptableOrUnknown(data['text']!, _propTextMeta),
      );
    } else if (isInserting) {
      context.missing(_propTextMeta);
    }
    if (data.containsKey('aspect')) {
      context.handle(
        _aspectMeta,
        aspect.isAcceptableOrUnknown(data['aspect']!, _aspectMeta),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('embedding_model')) {
      context.handle(
        _embeddingModelMeta,
        embeddingModel.isAcceptableOrUnknown(
          data['embedding_model']!,
          _embeddingModelMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Proposition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Proposition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      propText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      aspect: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aspect'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
      embeddingModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_model'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $PropositionsTable createAlias(String alias) {
    return $PropositionsTable(attachedDatabase, alias);
  }
}

class Proposition extends DataClass implements Insertable<Proposition> {
  final String id;
  final String turnId;
  final String conversationId;
  final String projectId;

  /// The proposition statement. DB column is `text` (DESIGN.md §10); the getter
  /// is renamed because drift reserves a bare `text` getter for its column
  /// builder.
  final String propText;

  /// Open-vocab aspect tag (not fixed buckets).
  final String? aspect;

  /// float32[] little-endian.
  final Uint8List? embedding;
  final String? embeddingModel;

  /// Milliseconds since epoch.
  final int? createdAt;
  const Proposition({
    required this.id,
    required this.turnId,
    required this.conversationId,
    required this.projectId,
    required this.propText,
    this.aspect,
    this.embedding,
    this.embeddingModel,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['turn_id'] = Variable<String>(turnId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['project_id'] = Variable<String>(projectId);
    map['text'] = Variable<String>(propText);
    if (!nullToAbsent || aspect != null) {
      map['aspect'] = Variable<String>(aspect);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    if (!nullToAbsent || embeddingModel != null) {
      map['embedding_model'] = Variable<String>(embeddingModel);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  PropositionsCompanion toCompanion(bool nullToAbsent) {
    return PropositionsCompanion(
      id: Value(id),
      turnId: Value(turnId),
      conversationId: Value(conversationId),
      projectId: Value(projectId),
      propText: Value(propText),
      aspect: aspect == null && nullToAbsent
          ? const Value.absent()
          : Value(aspect),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      embeddingModel: embeddingModel == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingModel),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Proposition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Proposition(
      id: serializer.fromJson<String>(json['id']),
      turnId: serializer.fromJson<String>(json['turnId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      propText: serializer.fromJson<String>(json['propText']),
      aspect: serializer.fromJson<String?>(json['aspect']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
      embeddingModel: serializer.fromJson<String?>(json['embeddingModel']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'turnId': serializer.toJson<String>(turnId),
      'conversationId': serializer.toJson<String>(conversationId),
      'projectId': serializer.toJson<String>(projectId),
      'propText': serializer.toJson<String>(propText),
      'aspect': serializer.toJson<String?>(aspect),
      'embedding': serializer.toJson<Uint8List?>(embedding),
      'embeddingModel': serializer.toJson<String?>(embeddingModel),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  Proposition copyWith({
    String? id,
    String? turnId,
    String? conversationId,
    String? projectId,
    String? propText,
    Value<String?> aspect = const Value.absent(),
    Value<Uint8List?> embedding = const Value.absent(),
    Value<String?> embeddingModel = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
  }) => Proposition(
    id: id ?? this.id,
    turnId: turnId ?? this.turnId,
    conversationId: conversationId ?? this.conversationId,
    projectId: projectId ?? this.projectId,
    propText: propText ?? this.propText,
    aspect: aspect.present ? aspect.value : this.aspect,
    embedding: embedding.present ? embedding.value : this.embedding,
    embeddingModel: embeddingModel.present
        ? embeddingModel.value
        : this.embeddingModel,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Proposition copyWithCompanion(PropositionsCompanion data) {
    return Proposition(
      id: data.id.present ? data.id.value : this.id,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      propText: data.propText.present ? data.propText.value : this.propText,
      aspect: data.aspect.present ? data.aspect.value : this.aspect,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      embeddingModel: data.embeddingModel.present
          ? data.embeddingModel.value
          : this.embeddingModel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Proposition(')
          ..write('id: $id, ')
          ..write('turnId: $turnId, ')
          ..write('conversationId: $conversationId, ')
          ..write('projectId: $projectId, ')
          ..write('propText: $propText, ')
          ..write('aspect: $aspect, ')
          ..write('embedding: $embedding, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    turnId,
    conversationId,
    projectId,
    propText,
    aspect,
    $driftBlobEquality.hash(embedding),
    embeddingModel,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Proposition &&
          other.id == this.id &&
          other.turnId == this.turnId &&
          other.conversationId == this.conversationId &&
          other.projectId == this.projectId &&
          other.propText == this.propText &&
          other.aspect == this.aspect &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.embeddingModel == this.embeddingModel &&
          other.createdAt == this.createdAt);
}

class PropositionsCompanion extends UpdateCompanion<Proposition> {
  final Value<String> id;
  final Value<String> turnId;
  final Value<String> conversationId;
  final Value<String> projectId;
  final Value<String> propText;
  final Value<String?> aspect;
  final Value<Uint8List?> embedding;
  final Value<String?> embeddingModel;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const PropositionsCompanion({
    this.id = const Value.absent(),
    this.turnId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.propText = const Value.absent(),
    this.aspect = const Value.absent(),
    this.embedding = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PropositionsCompanion.insert({
    required String id,
    required String turnId,
    required String conversationId,
    required String projectId,
    required String propText,
    this.aspect = const Value.absent(),
    this.embedding = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       turnId = Value(turnId),
       conversationId = Value(conversationId),
       projectId = Value(projectId),
       propText = Value(propText);
  static Insertable<Proposition> custom({
    Expression<String>? id,
    Expression<String>? turnId,
    Expression<String>? conversationId,
    Expression<String>? projectId,
    Expression<String>? propText,
    Expression<String>? aspect,
    Expression<Uint8List>? embedding,
    Expression<String>? embeddingModel,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (turnId != null) 'turn_id': turnId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (projectId != null) 'project_id': projectId,
      if (propText != null) 'text': propText,
      if (aspect != null) 'aspect': aspect,
      if (embedding != null) 'embedding': embedding,
      if (embeddingModel != null) 'embedding_model': embeddingModel,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PropositionsCompanion copyWith({
    Value<String>? id,
    Value<String>? turnId,
    Value<String>? conversationId,
    Value<String>? projectId,
    Value<String>? propText,
    Value<String?>? aspect,
    Value<Uint8List?>? embedding,
    Value<String?>? embeddingModel,
    Value<int?>? createdAt,
    Value<int>? rowid,
  }) {
    return PropositionsCompanion(
      id: id ?? this.id,
      turnId: turnId ?? this.turnId,
      conversationId: conversationId ?? this.conversationId,
      projectId: projectId ?? this.projectId,
      propText: propText ?? this.propText,
      aspect: aspect ?? this.aspect,
      embedding: embedding ?? this.embedding,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (propText.present) {
      map['text'] = Variable<String>(propText.value);
    }
    if (aspect.present) {
      map['aspect'] = Variable<String>(aspect.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (embeddingModel.present) {
      map['embedding_model'] = Variable<String>(embeddingModel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PropositionsCompanion(')
          ..write('id: $id, ')
          ..write('turnId: $turnId, ')
          ..write('conversationId: $conversationId, ')
          ..write('projectId: $projectId, ')
          ..write('propText: $propText, ')
          ..write('aspect: $aspect, ')
          ..write('embedding: $embedding, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitiesTable extends Entities with TableInfo<$EntitiesTable, Entity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedMeta = const VerificationMeta(
    'normalized',
  );
  @override
  late final GeneratedColumn<String> normalized = GeneratedColumn<String>(
    'normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, projectId, name, normalized];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized')) {
      context.handle(
        _normalizedMeta,
        normalized.isAcceptableOrUnknown(data['normalized']!, _normalizedMeta),
      );
    } else if (isInserting) {
      context.missing(_normalizedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized'],
      )!,
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class Entity extends DataClass implements Insertable<Entity> {
  final String id;
  final String projectId;
  final String name;
  final String normalized;
  const Entity({
    required this.id,
    required this.projectId,
    required this.name,
    required this.normalized,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['normalized'] = Variable<String>(normalized);
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      normalized: Value(normalized),
    );
  }

  factory Entity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entity(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      normalized: serializer.fromJson<String>(json['normalized']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'normalized': serializer.toJson<String>(normalized),
    };
  }

  Entity copyWith({
    String? id,
    String? projectId,
    String? name,
    String? normalized,
  }) => Entity(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    normalized: normalized ?? this.normalized,
  );
  Entity copyWithCompanion(EntitiesCompanion data) {
    return Entity(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      normalized: data.normalized.present
          ? data.normalized.value
          : this.normalized,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entity(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('normalized: $normalized')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, name, normalized);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entity &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.normalized == this.normalized);
}

class EntitiesCompanion extends UpdateCompanion<Entity> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> normalized;
  final Value<int> rowid;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.normalized = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitiesCompanion.insert({
    required String id,
    required String projectId,
    required String name,
    required String normalized,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       normalized = Value(normalized);
  static Insertable<Entity> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? normalized,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (normalized != null) 'normalized': normalized,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? normalized,
    Value<int>? rowid,
  }) {
    return EntitiesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      normalized: normalized ?? this.normalized,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalized.present) {
      map['normalized'] = Variable<String>(normalized.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('normalized: $normalized, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TurnEntitiesTable extends TurnEntities
    with TableInfo<$TurnEntitiesTable, TurnEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entities (id)',
    ),
  );
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
  @override
  List<GeneratedColumn> get $columns => [entityId, turnId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turn_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<TurnEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  TurnEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TurnEntity(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      )!,
    );
  }

  @override
  $TurnEntitiesTable createAlias(String alias) {
    return $TurnEntitiesTable(attachedDatabase, alias);
  }
}

class TurnEntity extends DataClass implements Insertable<TurnEntity> {
  final String entityId;
  final String turnId;
  const TurnEntity({required this.entityId, required this.turnId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['turn_id'] = Variable<String>(turnId);
    return map;
  }

  TurnEntitiesCompanion toCompanion(bool nullToAbsent) {
    return TurnEntitiesCompanion(
      entityId: Value(entityId),
      turnId: Value(turnId),
    );
  }

  factory TurnEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TurnEntity(
      entityId: serializer.fromJson<String>(json['entityId']),
      turnId: serializer.fromJson<String>(json['turnId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityId': serializer.toJson<String>(entityId),
      'turnId': serializer.toJson<String>(turnId),
    };
  }

  TurnEntity copyWith({String? entityId, String? turnId}) => TurnEntity(
    entityId: entityId ?? this.entityId,
    turnId: turnId ?? this.turnId,
  );
  TurnEntity copyWithCompanion(TurnEntitiesCompanion data) {
    return TurnEntity(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TurnEntity(')
          ..write('entityId: $entityId, ')
          ..write('turnId: $turnId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityId, turnId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TurnEntity &&
          other.entityId == this.entityId &&
          other.turnId == this.turnId);
}

class TurnEntitiesCompanion extends UpdateCompanion<TurnEntity> {
  final Value<String> entityId;
  final Value<String> turnId;
  final Value<int> rowid;
  const TurnEntitiesCompanion({
    this.entityId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TurnEntitiesCompanion.insert({
    required String entityId,
    required String turnId,
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId),
       turnId = Value(turnId);
  static Insertable<TurnEntity> custom({
    Expression<String>? entityId,
    Expression<String>? turnId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (turnId != null) 'turn_id': turnId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TurnEntitiesCompanion copyWith({
    Value<String>? entityId,
    Value<String>? turnId,
    Value<int>? rowid,
  }) {
    return TurnEntitiesCompanion(
      entityId: entityId ?? this.entityId,
      turnId: turnId ?? this.turnId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnEntitiesCompanion(')
          ..write('entityId: $entityId, ')
          ..write('turnId: $turnId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SoftEdgesTable extends SoftEdges
    with TableInfo<$SoftEdgesTable, SoftEdge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoftEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromTurnIdMeta = const VerificationMeta(
    'fromTurnId',
  );
  @override
  late final GeneratedColumn<String> fromTurnId = GeneratedColumn<String>(
    'from_turn_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toTurnIdMeta = const VerificationMeta(
    'toTurnId',
  );
  @override
  late final GeneratedColumn<String> toTurnId = GeneratedColumn<String>(
    'to_turn_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fromTurnId,
    toTurnId,
    kind,
    weight,
    projectId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soft_edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<SoftEdge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_turn_id')) {
      context.handle(
        _fromTurnIdMeta,
        fromTurnId.isAcceptableOrUnknown(
          data['from_turn_id']!,
          _fromTurnIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromTurnIdMeta);
    }
    if (data.containsKey('to_turn_id')) {
      context.handle(
        _toTurnIdMeta,
        toTurnId.isAcceptableOrUnknown(data['to_turn_id']!, _toTurnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toTurnIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SoftEdge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoftEdge(
      fromTurnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_turn_id'],
      )!,
      toTurnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_turn_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
    );
  }

  @override
  $SoftEdgesTable createAlias(String alias) {
    return $SoftEdgesTable(attachedDatabase, alias);
  }
}

class SoftEdge extends DataClass implements Insertable<SoftEdge> {
  final String fromTurnId;
  final String toTurnId;
  final String kind;
  final double weight;
  final String projectId;
  const SoftEdge({
    required this.fromTurnId,
    required this.toTurnId,
    required this.kind,
    required this.weight,
    required this.projectId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_turn_id'] = Variable<String>(fromTurnId);
    map['to_turn_id'] = Variable<String>(toTurnId);
    map['kind'] = Variable<String>(kind);
    map['weight'] = Variable<double>(weight);
    map['project_id'] = Variable<String>(projectId);
    return map;
  }

  SoftEdgesCompanion toCompanion(bool nullToAbsent) {
    return SoftEdgesCompanion(
      fromTurnId: Value(fromTurnId),
      toTurnId: Value(toTurnId),
      kind: Value(kind),
      weight: Value(weight),
      projectId: Value(projectId),
    );
  }

  factory SoftEdge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoftEdge(
      fromTurnId: serializer.fromJson<String>(json['fromTurnId']),
      toTurnId: serializer.fromJson<String>(json['toTurnId']),
      kind: serializer.fromJson<String>(json['kind']),
      weight: serializer.fromJson<double>(json['weight']),
      projectId: serializer.fromJson<String>(json['projectId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromTurnId': serializer.toJson<String>(fromTurnId),
      'toTurnId': serializer.toJson<String>(toTurnId),
      'kind': serializer.toJson<String>(kind),
      'weight': serializer.toJson<double>(weight),
      'projectId': serializer.toJson<String>(projectId),
    };
  }

  SoftEdge copyWith({
    String? fromTurnId,
    String? toTurnId,
    String? kind,
    double? weight,
    String? projectId,
  }) => SoftEdge(
    fromTurnId: fromTurnId ?? this.fromTurnId,
    toTurnId: toTurnId ?? this.toTurnId,
    kind: kind ?? this.kind,
    weight: weight ?? this.weight,
    projectId: projectId ?? this.projectId,
  );
  SoftEdge copyWithCompanion(SoftEdgesCompanion data) {
    return SoftEdge(
      fromTurnId: data.fromTurnId.present
          ? data.fromTurnId.value
          : this.fromTurnId,
      toTurnId: data.toTurnId.present ? data.toTurnId.value : this.toTurnId,
      kind: data.kind.present ? data.kind.value : this.kind,
      weight: data.weight.present ? data.weight.value : this.weight,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoftEdge(')
          ..write('fromTurnId: $fromTurnId, ')
          ..write('toTurnId: $toTurnId, ')
          ..write('kind: $kind, ')
          ..write('weight: $weight, ')
          ..write('projectId: $projectId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(fromTurnId, toTurnId, kind, weight, projectId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoftEdge &&
          other.fromTurnId == this.fromTurnId &&
          other.toTurnId == this.toTurnId &&
          other.kind == this.kind &&
          other.weight == this.weight &&
          other.projectId == this.projectId);
}

class SoftEdgesCompanion extends UpdateCompanion<SoftEdge> {
  final Value<String> fromTurnId;
  final Value<String> toTurnId;
  final Value<String> kind;
  final Value<double> weight;
  final Value<String> projectId;
  final Value<int> rowid;
  const SoftEdgesCompanion({
    this.fromTurnId = const Value.absent(),
    this.toTurnId = const Value.absent(),
    this.kind = const Value.absent(),
    this.weight = const Value.absent(),
    this.projectId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoftEdgesCompanion.insert({
    required String fromTurnId,
    required String toTurnId,
    required String kind,
    required double weight,
    required String projectId,
    this.rowid = const Value.absent(),
  }) : fromTurnId = Value(fromTurnId),
       toTurnId = Value(toTurnId),
       kind = Value(kind),
       weight = Value(weight),
       projectId = Value(projectId);
  static Insertable<SoftEdge> custom({
    Expression<String>? fromTurnId,
    Expression<String>? toTurnId,
    Expression<String>? kind,
    Expression<double>? weight,
    Expression<String>? projectId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromTurnId != null) 'from_turn_id': fromTurnId,
      if (toTurnId != null) 'to_turn_id': toTurnId,
      if (kind != null) 'kind': kind,
      if (weight != null) 'weight': weight,
      if (projectId != null) 'project_id': projectId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoftEdgesCompanion copyWith({
    Value<String>? fromTurnId,
    Value<String>? toTurnId,
    Value<String>? kind,
    Value<double>? weight,
    Value<String>? projectId,
    Value<int>? rowid,
  }) {
    return SoftEdgesCompanion(
      fromTurnId: fromTurnId ?? this.fromTurnId,
      toTurnId: toTurnId ?? this.toTurnId,
      kind: kind ?? this.kind,
      weight: weight ?? this.weight,
      projectId: projectId ?? this.projectId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromTurnId.present) {
      map['from_turn_id'] = Variable<String>(fromTurnId.value);
    }
    if (toTurnId.present) {
      map['to_turn_id'] = Variable<String>(toTurnId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoftEdgesCompanion(')
          ..write('fromTurnId: $fromTurnId, ')
          ..write('toTurnId: $toTurnId, ')
          ..write('kind: $kind, ')
          ..write('weight: $weight, ')
          ..write('projectId: $projectId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FactsTable extends Facts with TableInfo<$FactsTable, Fact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _factTextMeta = const VerificationMeta(
    'factText',
  );
  @override
  late final GeneratedColumn<String> factText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersedesIdMeta = const VerificationMeta(
    'supersedesId',
  );
  @override
  late final GeneratedColumn<String> supersedesId = GeneratedColumn<String>(
    'supersedes_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    conversationId,
    factText,
    status,
    supersedesId,
    embedding,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'facts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _factTextMeta,
        factText.isAcceptableOrUnknown(data['text']!, _factTextMeta),
      );
    } else if (isInserting) {
      context.missing(_factTextMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('supersedes_id')) {
      context.handle(
        _supersedesIdMeta,
        supersedesId.isAcceptableOrUnknown(
          data['supersedes_id']!,
          _supersedesIdMeta,
        ),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      ),
      factText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      supersedesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supersedes_id'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $FactsTable createAlias(String alias) {
    return $FactsTable(attachedDatabase, alias);
  }
}

class Fact extends DataClass implements Insertable<Fact> {
  final String id;
  final String projectId;
  final String? conversationId;

  /// The committed statement. DB column is `text` (DESIGN.md §10); the getter is
  /// renamed because drift reserves a bare `text` getter for its column builder.
  final String factText;
  final String status;
  final String? supersedesId;

  /// float32[] little-endian.
  final Uint8List? embedding;

  /// Milliseconds since epoch.
  final int? createdAt;
  const Fact({
    required this.id,
    required this.projectId,
    this.conversationId,
    required this.factText,
    required this.status,
    this.supersedesId,
    this.embedding,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    map['text'] = Variable<String>(factText);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || supersedesId != null) {
      map['supersedes_id'] = Variable<String>(supersedesId);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  FactsCompanion toCompanion(bool nullToAbsent) {
    return FactsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      factText: Value(factText),
      status: Value(status),
      supersedesId: supersedesId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersedesId),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Fact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fact(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      conversationId: serializer.fromJson<String?>(json['conversationId']),
      factText: serializer.fromJson<String>(json['factText']),
      status: serializer.fromJson<String>(json['status']),
      supersedesId: serializer.fromJson<String?>(json['supersedesId']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'conversationId': serializer.toJson<String?>(conversationId),
      'factText': serializer.toJson<String>(factText),
      'status': serializer.toJson<String>(status),
      'supersedesId': serializer.toJson<String?>(supersedesId),
      'embedding': serializer.toJson<Uint8List?>(embedding),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  Fact copyWith({
    String? id,
    String? projectId,
    Value<String?> conversationId = const Value.absent(),
    String? factText,
    String? status,
    Value<String?> supersedesId = const Value.absent(),
    Value<Uint8List?> embedding = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
  }) => Fact(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    conversationId: conversationId.present
        ? conversationId.value
        : this.conversationId,
    factText: factText ?? this.factText,
    status: status ?? this.status,
    supersedesId: supersedesId.present ? supersedesId.value : this.supersedesId,
    embedding: embedding.present ? embedding.value : this.embedding,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Fact copyWithCompanion(FactsCompanion data) {
    return Fact(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      factText: data.factText.present ? data.factText.value : this.factText,
      status: data.status.present ? data.status.value : this.status,
      supersedesId: data.supersedesId.present
          ? data.supersedesId.value
          : this.supersedesId,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fact(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('conversationId: $conversationId, ')
          ..write('factText: $factText, ')
          ..write('status: $status, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('embedding: $embedding, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    conversationId,
    factText,
    status,
    supersedesId,
    $driftBlobEquality.hash(embedding),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fact &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.conversationId == this.conversationId &&
          other.factText == this.factText &&
          other.status == this.status &&
          other.supersedesId == this.supersedesId &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.createdAt == this.createdAt);
}

class FactsCompanion extends UpdateCompanion<Fact> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> conversationId;
  final Value<String> factText;
  final Value<String> status;
  final Value<String?> supersedesId;
  final Value<Uint8List?> embedding;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const FactsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.factText = const Value.absent(),
    this.status = const Value.absent(),
    this.supersedesId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FactsCompanion.insert({
    required String id,
    required String projectId,
    this.conversationId = const Value.absent(),
    required String factText,
    required String status,
    this.supersedesId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       factText = Value(factText),
       status = Value(status);
  static Insertable<Fact> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? conversationId,
    Expression<String>? factText,
    Expression<String>? status,
    Expression<String>? supersedesId,
    Expression<Uint8List>? embedding,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (factText != null) 'text': factText,
      if (status != null) 'status': status,
      if (supersedesId != null) 'supersedes_id': supersedesId,
      if (embedding != null) 'embedding': embedding,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FactsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String?>? conversationId,
    Value<String>? factText,
    Value<String>? status,
    Value<String?>? supersedesId,
    Value<Uint8List?>? embedding,
    Value<int?>? createdAt,
    Value<int>? rowid,
  }) {
    return FactsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      conversationId: conversationId ?? this.conversationId,
      factText: factText ?? this.factText,
      status: status ?? this.status,
      supersedesId: supersedesId ?? this.supersedesId,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (factText.present) {
      map['text'] = Variable<String>(factText.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (supersedesId.present) {
      map['supersedes_id'] = Variable<String>(supersedesId.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FactsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('conversationId: $conversationId, ')
          ..write('factText: $factText, ')
          ..write('status: $status, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('embedding: $embedding, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FactSourcesTable extends FactSources
    with TableInfo<$FactSourcesTable, FactSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FactSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _factIdMeta = const VerificationMeta('factId');
  @override
  late final GeneratedColumn<String> factId = GeneratedColumn<String>(
    'fact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES facts (id)',
    ),
  );
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
  @override
  List<GeneratedColumn> get $columns => [factId, turnId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fact_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<FactSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fact_id')) {
      context.handle(
        _factIdMeta,
        factId.isAcceptableOrUnknown(data['fact_id']!, _factIdMeta),
      );
    } else if (isInserting) {
      context.missing(_factIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  FactSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FactSource(
      factId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fact_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      )!,
    );
  }

  @override
  $FactSourcesTable createAlias(String alias) {
    return $FactSourcesTable(attachedDatabase, alias);
  }
}

class FactSource extends DataClass implements Insertable<FactSource> {
  final String factId;
  final String turnId;
  const FactSource({required this.factId, required this.turnId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fact_id'] = Variable<String>(factId);
    map['turn_id'] = Variable<String>(turnId);
    return map;
  }

  FactSourcesCompanion toCompanion(bool nullToAbsent) {
    return FactSourcesCompanion(factId: Value(factId), turnId: Value(turnId));
  }

  factory FactSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FactSource(
      factId: serializer.fromJson<String>(json['factId']),
      turnId: serializer.fromJson<String>(json['turnId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'factId': serializer.toJson<String>(factId),
      'turnId': serializer.toJson<String>(turnId),
    };
  }

  FactSource copyWith({String? factId, String? turnId}) =>
      FactSource(factId: factId ?? this.factId, turnId: turnId ?? this.turnId);
  FactSource copyWithCompanion(FactSourcesCompanion data) {
    return FactSource(
      factId: data.factId.present ? data.factId.value : this.factId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FactSource(')
          ..write('factId: $factId, ')
          ..write('turnId: $turnId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(factId, turnId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FactSource &&
          other.factId == this.factId &&
          other.turnId == this.turnId);
}

class FactSourcesCompanion extends UpdateCompanion<FactSource> {
  final Value<String> factId;
  final Value<String> turnId;
  final Value<int> rowid;
  const FactSourcesCompanion({
    this.factId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FactSourcesCompanion.insert({
    required String factId,
    required String turnId,
    this.rowid = const Value.absent(),
  }) : factId = Value(factId),
       turnId = Value(turnId);
  static Insertable<FactSource> custom({
    Expression<String>? factId,
    Expression<String>? turnId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (factId != null) 'fact_id': factId,
      if (turnId != null) 'turn_id': turnId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FactSourcesCompanion copyWith({
    Value<String>? factId,
    Value<String>? turnId,
    Value<int>? rowid,
  }) {
    return FactSourcesCompanion(
      factId: factId ?? this.factId,
      turnId: turnId ?? this.turnId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (factId.present) {
      map['fact_id'] = Variable<String>(factId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FactSourcesCompanion(')
          ..write('factId: $factId, ')
          ..write('turnId: $turnId, ')
          ..write('rowid: $rowid')
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
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $PropositionsTable propositions = $PropositionsTable(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $TurnEntitiesTable turnEntities = $TurnEntitiesTable(this);
  late final $SoftEdgesTable softEdges = $SoftEdgesTable(this);
  late final $FactsTable facts = $FactsTable(this);
  late final $FactSourcesTable factSources = $FactSourcesTable(this);
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
    projects,
    propositions,
    entities,
    turnEntities,
    softEdges,
    facts,
    factSources,
  ];
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String> title,
      Value<int?> createTime,
      Value<int?> updateTime,
      Value<int?> lastMessageAt,
      Value<bool> isArchived,
      Value<bool> isStarred,
      Value<String?> defaultModelSlug,
      Value<String?> currentTurnId,
      required String source,
      Value<String> projectId,
      Value<int> indexState,
      Value<int?> indexedAt,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int?> createTime,
      Value<int?> updateTime,
      Value<int?> lastMessageAt,
      Value<bool> isArchived,
      Value<bool> isStarred,
      Value<String?> defaultModelSlug,
      Value<String?> currentTurnId,
      Value<String> source,
      Value<String> projectId,
      Value<int> indexState,
      Value<int?> indexedAt,
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

  ColumnFilters<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
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

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexState => $composableBuilder(
    column: $table.indexState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
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

  ColumnOrderings<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
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

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexState => $composableBuilder(
    column: $table.indexState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
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

  GeneratedColumn<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
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

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get indexState => $composableBuilder(
    column: $table.indexState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

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
                Value<int?> lastMessageAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String?> defaultModelSlug = const Value.absent(),
                Value<String?> currentTurnId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<int> indexState = const Value.absent(),
                Value<int?> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                createTime: createTime,
                updateTime: updateTime,
                lastMessageAt: lastMessageAt,
                isArchived: isArchived,
                isStarred: isStarred,
                defaultModelSlug: defaultModelSlug,
                currentTurnId: currentTurnId,
                source: source,
                projectId: projectId,
                indexState: indexState,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                Value<int?> updateTime = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String?> defaultModelSlug = const Value.absent(),
                Value<String?> currentTurnId = const Value.absent(),
                required String source,
                Value<String> projectId = const Value.absent(),
                Value<int> indexState = const Value.absent(),
                Value<int?> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                createTime: createTime,
                updateTime: updateTime,
                lastMessageAt: lastMessageAt,
                isArchived: isArchived,
                isStarred: isStarred,
                defaultModelSlug: defaultModelSlug,
                currentTurnId: currentTurnId,
                source: source,
                projectId: projectId,
                indexState: indexState,
                indexedAt: indexedAt,
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

  static MultiTypedResultKey<$PropositionsTable, List<Proposition>>
  _propositionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.propositions,
    aliasName: $_aliasNameGenerator(db.turns.id, db.propositions.turnId),
  );

  $$PropositionsTableProcessedTableManager get propositionsRefs {
    final manager = $$PropositionsTableTableManager(
      $_db,
      $_db.propositions,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_propositionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TurnEntitiesTable, List<TurnEntity>>
  _turnEntitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.turnEntities,
    aliasName: $_aliasNameGenerator(db.turns.id, db.turnEntities.turnId),
  );

  $$TurnEntitiesTableProcessedTableManager get turnEntitiesRefs {
    final manager = $$TurnEntitiesTableTableManager(
      $_db,
      $_db.turnEntities,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_turnEntitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FactSourcesTable, List<FactSource>>
  _factSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.factSources,
    aliasName: $_aliasNameGenerator(db.turns.id, db.factSources.turnId),
  );

  $$FactSourcesTableProcessedTableManager get factSourcesRefs {
    final manager = $$FactSourcesTableTableManager(
      $_db,
      $_db.factSources,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_factSourcesRefsTable($_db));
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

  Expression<bool> propositionsRefs(
    Expression<bool> Function($$PropositionsTableFilterComposer f) f,
  ) {
    final $$PropositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.propositions,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropositionsTableFilterComposer(
            $db: $db,
            $table: $db.propositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> turnEntitiesRefs(
    Expression<bool> Function($$TurnEntitiesTableFilterComposer f) f,
  ) {
    final $$TurnEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turnEntities,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.turnEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> factSourcesRefs(
    Expression<bool> Function($$FactSourcesTableFilterComposer f) f,
  ) {
    final $$FactSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.factSources,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactSourcesTableFilterComposer(
            $db: $db,
            $table: $db.factSources,
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

  Expression<T> propositionsRefs<T extends Object>(
    Expression<T> Function($$PropositionsTableAnnotationComposer a) f,
  ) {
    final $$PropositionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.propositions,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropositionsTableAnnotationComposer(
            $db: $db,
            $table: $db.propositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> turnEntitiesRefs<T extends Object>(
    Expression<T> Function($$TurnEntitiesTableAnnotationComposer a) f,
  ) {
    final $$TurnEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turnEntities,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.turnEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> factSourcesRefs<T extends Object>(
    Expression<T> Function($$FactSourcesTableAnnotationComposer a) f,
  ) {
    final $$FactSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.factSources,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.factSources,
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
          PrefetchHooks Function({
            bool conversationId,
            bool turnAssetsRefs,
            bool propositionsRefs,
            bool turnEntitiesRefs,
            bool factSourcesRefs,
          })
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
              ({
                conversationId = false,
                turnAssetsRefs = false,
                propositionsRefs = false,
                turnEntitiesRefs = false,
                factSourcesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (turnAssetsRefs) db.turnAssets,
                    if (propositionsRefs) db.propositions,
                    if (turnEntitiesRefs) db.turnEntities,
                    if (factSourcesRefs) db.factSources,
                  ],
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
                      if (propositionsRefs)
                        await $_getPrefetchedData<
                          Turn,
                          $TurnsTable,
                          Proposition
                        >(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._propositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).propositionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.turnId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (turnEntitiesRefs)
                        await $_getPrefetchedData<
                          Turn,
                          $TurnsTable,
                          TurnEntity
                        >(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._turnEntitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).turnEntitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.turnId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (factSourcesRefs)
                        await $_getPrefetchedData<
                          Turn,
                          $TurnsTable,
                          FactSource
                        >(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._factSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).factSourcesRefs,
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
      PrefetchHooks Function({
        bool conversationId,
        bool turnAssetsRefs,
        bool propositionsRefs,
        bool turnEntitiesRefs,
        bool factSourcesRefs,
      })
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
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      Value<String> name,
      Value<int?> createdAt,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> createdAt,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$PropositionsTableCreateCompanionBuilder =
    PropositionsCompanion Function({
      required String id,
      required String turnId,
      required String conversationId,
      required String projectId,
      required String propText,
      Value<String?> aspect,
      Value<Uint8List?> embedding,
      Value<String?> embeddingModel,
      Value<int?> createdAt,
      Value<int> rowid,
    });
typedef $$PropositionsTableUpdateCompanionBuilder =
    PropositionsCompanion Function({
      Value<String> id,
      Value<String> turnId,
      Value<String> conversationId,
      Value<String> projectId,
      Value<String> propText,
      Value<String?> aspect,
      Value<Uint8List?> embedding,
      Value<String?> embeddingModel,
      Value<int?> createdAt,
      Value<int> rowid,
    });

final class $$PropositionsTableReferences
    extends BaseReferences<_$AppDatabase, $PropositionsTable, Proposition> {
  $$PropositionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.propositions.turnId, db.turns.id),
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

class $$PropositionsTableFilterComposer
    extends Composer<_$AppDatabase, $PropositionsTable> {
  $$PropositionsTableFilterComposer({
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

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get propText => $composableBuilder(
    column: $table.propText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aspect => $composableBuilder(
    column: $table.aspect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$PropositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PropositionsTable> {
  $$PropositionsTableOrderingComposer({
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

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get propText => $composableBuilder(
    column: $table.propText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aspect => $composableBuilder(
    column: $table.aspect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$PropositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PropositionsTable> {
  $$PropositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get propText =>
      $composableBuilder(column: $table.propText, builder: (column) => column);

  GeneratedColumn<String> get aspect =>
      $composableBuilder(column: $table.aspect, builder: (column) => column);

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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

class $$PropositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PropositionsTable,
          Proposition,
          $$PropositionsTableFilterComposer,
          $$PropositionsTableOrderingComposer,
          $$PropositionsTableAnnotationComposer,
          $$PropositionsTableCreateCompanionBuilder,
          $$PropositionsTableUpdateCompanionBuilder,
          (Proposition, $$PropositionsTableReferences),
          Proposition,
          PrefetchHooks Function({bool turnId})
        > {
  $$PropositionsTableTableManager(_$AppDatabase db, $PropositionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PropositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PropositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PropositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> turnId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> propText = const Value.absent(),
                Value<String?> aspect = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropositionsCompanion(
                id: id,
                turnId: turnId,
                conversationId: conversationId,
                projectId: projectId,
                propText: propText,
                aspect: aspect,
                embedding: embedding,
                embeddingModel: embeddingModel,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String turnId,
                required String conversationId,
                required String projectId,
                required String propText,
                Value<String?> aspect = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropositionsCompanion.insert(
                id: id,
                turnId: turnId,
                conversationId: conversationId,
                projectId: projectId,
                propText: propText,
                aspect: aspect,
                embedding: embedding,
                embeddingModel: embeddingModel,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PropositionsTableReferences(db, table, e),
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
                                referencedTable: $$PropositionsTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$PropositionsTableReferences
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

typedef $$PropositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PropositionsTable,
      Proposition,
      $$PropositionsTableFilterComposer,
      $$PropositionsTableOrderingComposer,
      $$PropositionsTableAnnotationComposer,
      $$PropositionsTableCreateCompanionBuilder,
      $$PropositionsTableUpdateCompanionBuilder,
      (Proposition, $$PropositionsTableReferences),
      Proposition,
      PrefetchHooks Function({bool turnId})
    >;
typedef $$EntitiesTableCreateCompanionBuilder =
    EntitiesCompanion Function({
      required String id,
      required String projectId,
      required String name,
      required String normalized,
      Value<int> rowid,
    });
typedef $$EntitiesTableUpdateCompanionBuilder =
    EntitiesCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> name,
      Value<String> normalized,
      Value<int> rowid,
    });

final class $$EntitiesTableReferences
    extends BaseReferences<_$AppDatabase, $EntitiesTable, Entity> {
  $$EntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TurnEntitiesTable, List<TurnEntity>>
  _turnEntitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.turnEntities,
    aliasName: $_aliasNameGenerator(db.entities.id, db.turnEntities.entityId),
  );

  $$TurnEntitiesTableProcessedTableManager get turnEntitiesRefs {
    final manager = $$TurnEntitiesTableTableManager(
      $_db,
      $_db.turnEntities,
    ).filter((f) => f.entityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_turnEntitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
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

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> turnEntitiesRefs(
    Expression<bool> Function($$TurnEntitiesTableFilterComposer f) f,
  ) {
    final $$TurnEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turnEntities,
      getReferencedColumn: (t) => t.entityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.turnEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
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

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => column,
  );

  Expression<T> turnEntitiesRefs<T extends Object>(
    Expression<T> Function($$TurnEntitiesTableAnnotationComposer a) f,
  ) {
    final $$TurnEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turnEntities,
      getReferencedColumn: (t) => t.entityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.turnEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitiesTable,
          Entity,
          $$EntitiesTableFilterComposer,
          $$EntitiesTableOrderingComposer,
          $$EntitiesTableAnnotationComposer,
          $$EntitiesTableCreateCompanionBuilder,
          $$EntitiesTableUpdateCompanionBuilder,
          (Entity, $$EntitiesTableReferences),
          Entity,
          PrefetchHooks Function({bool turnEntitiesRefs})
        > {
  $$EntitiesTableTableManager(_$AppDatabase db, $EntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalized = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion(
                id: id,
                projectId: projectId,
                name: name,
                normalized: normalized,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String name,
                required String normalized,
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                normalized: normalized,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({turnEntitiesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (turnEntitiesRefs) db.turnEntities],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (turnEntitiesRefs)
                    await $_getPrefetchedData<
                      Entity,
                      $EntitiesTable,
                      TurnEntity
                    >(
                      currentTable: table,
                      referencedTable: $$EntitiesTableReferences
                          ._turnEntitiesRefsTable(db),
                      managerFromTypedResult: (p0) => $$EntitiesTableReferences(
                        db,
                        table,
                        p0,
                      ).turnEntitiesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.entityId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitiesTable,
      Entity,
      $$EntitiesTableFilterComposer,
      $$EntitiesTableOrderingComposer,
      $$EntitiesTableAnnotationComposer,
      $$EntitiesTableCreateCompanionBuilder,
      $$EntitiesTableUpdateCompanionBuilder,
      (Entity, $$EntitiesTableReferences),
      Entity,
      PrefetchHooks Function({bool turnEntitiesRefs})
    >;
typedef $$TurnEntitiesTableCreateCompanionBuilder =
    TurnEntitiesCompanion Function({
      required String entityId,
      required String turnId,
      Value<int> rowid,
    });
typedef $$TurnEntitiesTableUpdateCompanionBuilder =
    TurnEntitiesCompanion Function({
      Value<String> entityId,
      Value<String> turnId,
      Value<int> rowid,
    });

final class $$TurnEntitiesTableReferences
    extends BaseReferences<_$AppDatabase, $TurnEntitiesTable, TurnEntity> {
  $$TurnEntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntitiesTable _entityIdTable(_$AppDatabase db) =>
      db.entities.createAlias(
        $_aliasNameGenerator(db.turnEntities.entityId, db.entities.id),
      );

  $$EntitiesTableProcessedTableManager get entityId {
    final $_column = $_itemColumn<String>('entity_id')!;

    final manager = $$EntitiesTableTableManager(
      $_db,
      $_db.entities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.turnEntities.turnId, db.turns.id),
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

class $$TurnEntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $TurnEntitiesTable> {
  $$TurnEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntitiesTableFilterComposer get entityId {
    final $$EntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableFilterComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$TurnEntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnEntitiesTable> {
  $$TurnEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntitiesTableOrderingComposer get entityId {
    final $$EntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$TurnEntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnEntitiesTable> {
  $$TurnEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntitiesTableAnnotationComposer get entityId {
    final $$EntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$TurnEntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TurnEntitiesTable,
          TurnEntity,
          $$TurnEntitiesTableFilterComposer,
          $$TurnEntitiesTableOrderingComposer,
          $$TurnEntitiesTableAnnotationComposer,
          $$TurnEntitiesTableCreateCompanionBuilder,
          $$TurnEntitiesTableUpdateCompanionBuilder,
          (TurnEntity, $$TurnEntitiesTableReferences),
          TurnEntity,
          PrefetchHooks Function({bool entityId, bool turnId})
        > {
  $$TurnEntitiesTableTableManager(_$AppDatabase db, $TurnEntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> turnId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurnEntitiesCompanion(
                entityId: entityId,
                turnId: turnId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                required String turnId,
                Value<int> rowid = const Value.absent(),
              }) => TurnEntitiesCompanion.insert(
                entityId: entityId,
                turnId: turnId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TurnEntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entityId = false, turnId = false}) {
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
                    if (entityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entityId,
                                referencedTable: $$TurnEntitiesTableReferences
                                    ._entityIdTable(db),
                                referencedColumn: $$TurnEntitiesTableReferences
                                    ._entityIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable: $$TurnEntitiesTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$TurnEntitiesTableReferences
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

typedef $$TurnEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TurnEntitiesTable,
      TurnEntity,
      $$TurnEntitiesTableFilterComposer,
      $$TurnEntitiesTableOrderingComposer,
      $$TurnEntitiesTableAnnotationComposer,
      $$TurnEntitiesTableCreateCompanionBuilder,
      $$TurnEntitiesTableUpdateCompanionBuilder,
      (TurnEntity, $$TurnEntitiesTableReferences),
      TurnEntity,
      PrefetchHooks Function({bool entityId, bool turnId})
    >;
typedef $$SoftEdgesTableCreateCompanionBuilder =
    SoftEdgesCompanion Function({
      required String fromTurnId,
      required String toTurnId,
      required String kind,
      required double weight,
      required String projectId,
      Value<int> rowid,
    });
typedef $$SoftEdgesTableUpdateCompanionBuilder =
    SoftEdgesCompanion Function({
      Value<String> fromTurnId,
      Value<String> toTurnId,
      Value<String> kind,
      Value<double> weight,
      Value<String> projectId,
      Value<int> rowid,
    });

class $$SoftEdgesTableFilterComposer
    extends Composer<_$AppDatabase, $SoftEdgesTable> {
  $$SoftEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fromTurnId => $composableBuilder(
    column: $table.fromTurnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toTurnId => $composableBuilder(
    column: $table.toTurnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SoftEdgesTableOrderingComposer
    extends Composer<_$AppDatabase, $SoftEdgesTable> {
  $$SoftEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fromTurnId => $composableBuilder(
    column: $table.fromTurnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toTurnId => $composableBuilder(
    column: $table.toTurnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SoftEdgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoftEdgesTable> {
  $$SoftEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fromTurnId => $composableBuilder(
    column: $table.fromTurnId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toTurnId =>
      $composableBuilder(column: $table.toTurnId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);
}

class $$SoftEdgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SoftEdgesTable,
          SoftEdge,
          $$SoftEdgesTableFilterComposer,
          $$SoftEdgesTableOrderingComposer,
          $$SoftEdgesTableAnnotationComposer,
          $$SoftEdgesTableCreateCompanionBuilder,
          $$SoftEdgesTableUpdateCompanionBuilder,
          (SoftEdge, BaseReferences<_$AppDatabase, $SoftEdgesTable, SoftEdge>),
          SoftEdge,
          PrefetchHooks Function()
        > {
  $$SoftEdgesTableTableManager(_$AppDatabase db, $SoftEdgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoftEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SoftEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoftEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fromTurnId = const Value.absent(),
                Value<String> toTurnId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SoftEdgesCompanion(
                fromTurnId: fromTurnId,
                toTurnId: toTurnId,
                kind: kind,
                weight: weight,
                projectId: projectId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromTurnId,
                required String toTurnId,
                required String kind,
                required double weight,
                required String projectId,
                Value<int> rowid = const Value.absent(),
              }) => SoftEdgesCompanion.insert(
                fromTurnId: fromTurnId,
                toTurnId: toTurnId,
                kind: kind,
                weight: weight,
                projectId: projectId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SoftEdgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SoftEdgesTable,
      SoftEdge,
      $$SoftEdgesTableFilterComposer,
      $$SoftEdgesTableOrderingComposer,
      $$SoftEdgesTableAnnotationComposer,
      $$SoftEdgesTableCreateCompanionBuilder,
      $$SoftEdgesTableUpdateCompanionBuilder,
      (SoftEdge, BaseReferences<_$AppDatabase, $SoftEdgesTable, SoftEdge>),
      SoftEdge,
      PrefetchHooks Function()
    >;
typedef $$FactsTableCreateCompanionBuilder =
    FactsCompanion Function({
      required String id,
      required String projectId,
      Value<String?> conversationId,
      required String factText,
      required String status,
      Value<String?> supersedesId,
      Value<Uint8List?> embedding,
      Value<int?> createdAt,
      Value<int> rowid,
    });
typedef $$FactsTableUpdateCompanionBuilder =
    FactsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String?> conversationId,
      Value<String> factText,
      Value<String> status,
      Value<String?> supersedesId,
      Value<Uint8List?> embedding,
      Value<int?> createdAt,
      Value<int> rowid,
    });

final class $$FactsTableReferences
    extends BaseReferences<_$AppDatabase, $FactsTable, Fact> {
  $$FactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FactSourcesTable, List<FactSource>>
  _factSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.factSources,
    aliasName: $_aliasNameGenerator(db.facts.id, db.factSources.factId),
  );

  $$FactSourcesTableProcessedTableManager get factSourcesRefs {
    final manager = $$FactSourcesTableTableManager(
      $_db,
      $_db.factSources,
    ).filter((f) => f.factId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_factSourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FactsTableFilterComposer extends Composer<_$AppDatabase, $FactsTable> {
  $$FactsTableFilterComposer({
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

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get factText => $composableBuilder(
    column: $table.factText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> factSourcesRefs(
    Expression<bool> Function($$FactSourcesTableFilterComposer f) f,
  ) {
    final $$FactSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.factSources,
      getReferencedColumn: (t) => t.factId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactSourcesTableFilterComposer(
            $db: $db,
            $table: $db.factSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FactsTableOrderingComposer
    extends Composer<_$AppDatabase, $FactsTable> {
  $$FactsTableOrderingComposer({
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

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get factText => $composableBuilder(
    column: $table.factText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FactsTable> {
  $$FactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get factText =>
      $composableBuilder(column: $table.factText, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> factSourcesRefs<T extends Object>(
    Expression<T> Function($$FactSourcesTableAnnotationComposer a) f,
  ) {
    final $$FactSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.factSources,
      getReferencedColumn: (t) => t.factId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.factSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FactsTable,
          Fact,
          $$FactsTableFilterComposer,
          $$FactsTableOrderingComposer,
          $$FactsTableAnnotationComposer,
          $$FactsTableCreateCompanionBuilder,
          $$FactsTableUpdateCompanionBuilder,
          (Fact, $$FactsTableReferences),
          Fact,
          PrefetchHooks Function({bool factSourcesRefs})
        > {
  $$FactsTableTableManager(_$AppDatabase db, $FactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<String> factText = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FactsCompanion(
                id: id,
                projectId: projectId,
                conversationId: conversationId,
                factText: factText,
                status: status,
                supersedesId: supersedesId,
                embedding: embedding,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                Value<String?> conversationId = const Value.absent(),
                required String factText,
                required String status,
                Value<String?> supersedesId = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FactsCompanion.insert(
                id: id,
                projectId: projectId,
                conversationId: conversationId,
                factText: factText,
                status: status,
                supersedesId: supersedesId,
                embedding: embedding,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$FactsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({factSourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (factSourcesRefs) db.factSources],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (factSourcesRefs)
                    await $_getPrefetchedData<Fact, $FactsTable, FactSource>(
                      currentTable: table,
                      referencedTable: $$FactsTableReferences
                          ._factSourcesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FactsTableReferences(db, table, p0).factSourcesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.factId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FactsTable,
      Fact,
      $$FactsTableFilterComposer,
      $$FactsTableOrderingComposer,
      $$FactsTableAnnotationComposer,
      $$FactsTableCreateCompanionBuilder,
      $$FactsTableUpdateCompanionBuilder,
      (Fact, $$FactsTableReferences),
      Fact,
      PrefetchHooks Function({bool factSourcesRefs})
    >;
typedef $$FactSourcesTableCreateCompanionBuilder =
    FactSourcesCompanion Function({
      required String factId,
      required String turnId,
      Value<int> rowid,
    });
typedef $$FactSourcesTableUpdateCompanionBuilder =
    FactSourcesCompanion Function({
      Value<String> factId,
      Value<String> turnId,
      Value<int> rowid,
    });

final class $$FactSourcesTableReferences
    extends BaseReferences<_$AppDatabase, $FactSourcesTable, FactSource> {
  $$FactSourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FactsTable _factIdTable(_$AppDatabase db) => db.facts.createAlias(
    $_aliasNameGenerator(db.factSources.factId, db.facts.id),
  );

  $$FactsTableProcessedTableManager get factId {
    final $_column = $_itemColumn<String>('fact_id')!;

    final manager = $$FactsTableTableManager(
      $_db,
      $_db.facts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_factIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.factSources.turnId, db.turns.id),
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

class $$FactSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $FactSourcesTable> {
  $$FactSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FactsTableFilterComposer get factId {
    final $$FactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.factId,
      referencedTable: $db.facts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactsTableFilterComposer(
            $db: $db,
            $table: $db.facts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$FactSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $FactSourcesTable> {
  $$FactSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FactsTableOrderingComposer get factId {
    final $$FactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.factId,
      referencedTable: $db.facts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactsTableOrderingComposer(
            $db: $db,
            $table: $db.facts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$FactSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FactSourcesTable> {
  $$FactSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FactsTableAnnotationComposer get factId {
    final $$FactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.factId,
      referencedTable: $db.facts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FactsTableAnnotationComposer(
            $db: $db,
            $table: $db.facts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$FactSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FactSourcesTable,
          FactSource,
          $$FactSourcesTableFilterComposer,
          $$FactSourcesTableOrderingComposer,
          $$FactSourcesTableAnnotationComposer,
          $$FactSourcesTableCreateCompanionBuilder,
          $$FactSourcesTableUpdateCompanionBuilder,
          (FactSource, $$FactSourcesTableReferences),
          FactSource,
          PrefetchHooks Function({bool factId, bool turnId})
        > {
  $$FactSourcesTableTableManager(_$AppDatabase db, $FactSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FactSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FactSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FactSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> factId = const Value.absent(),
                Value<String> turnId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FactSourcesCompanion(
                factId: factId,
                turnId: turnId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String factId,
                required String turnId,
                Value<int> rowid = const Value.absent(),
              }) => FactSourcesCompanion.insert(
                factId: factId,
                turnId: turnId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FactSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({factId = false, turnId = false}) {
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
                    if (factId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.factId,
                                referencedTable: $$FactSourcesTableReferences
                                    ._factIdTable(db),
                                referencedColumn: $$FactSourcesTableReferences
                                    ._factIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable: $$FactSourcesTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$FactSourcesTableReferences
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

typedef $$FactSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FactSourcesTable,
      FactSource,
      $$FactSourcesTableFilterComposer,
      $$FactSourcesTableOrderingComposer,
      $$FactSourcesTableAnnotationComposer,
      $$FactSourcesTableCreateCompanionBuilder,
      $$FactSourcesTableUpdateCompanionBuilder,
      (FactSource, $$FactSourcesTableReferences),
      FactSource,
      PrefetchHooks Function({bool factId, bool turnId})
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
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$PropositionsTableTableManager get propositions =>
      $$PropositionsTableTableManager(_db, _db.propositions);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$TurnEntitiesTableTableManager get turnEntities =>
      $$TurnEntitiesTableTableManager(_db, _db.turnEntities);
  $$SoftEdgesTableTableManager get softEdges =>
      $$SoftEdgesTableTableManager(_db, _db.softEdges);
  $$FactsTableTableManager get facts =>
      $$FactsTableTableManager(_db, _db.facts);
  $$FactSourcesTableTableManager get factSources =>
      $$FactSourcesTableTableManager(_db, _db.factSources);
}
