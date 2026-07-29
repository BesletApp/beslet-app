// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WisdomNotesTable extends WisdomNotes
    with TableInfo<$WisdomNotesTable, WisdomNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WisdomNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, bookId, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wisdom_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WisdomNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WisdomNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WisdomNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WisdomNotesTable createAlias(String alias) {
    return $WisdomNotesTable(attachedDatabase, alias);
  }
}

class WisdomNote extends DataClass implements Insertable<WisdomNote> {
  final String id;
  final String bookId;
  final String note;
  final String createdAt;
  const WisdomNote({
    required this.id,
    required this.bookId,
    required this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WisdomNotesCompanion toCompanion(bool nullToAbsent) {
    return WisdomNotesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory WisdomNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WisdomNote(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  WisdomNote copyWith({
    String? id,
    String? bookId,
    String? note,
    String? createdAt,
  }) => WisdomNote(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  WisdomNote copyWithCompanion(WisdomNotesCompanion data) {
    return WisdomNote(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WisdomNote(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WisdomNote &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class WisdomNotesCompanion extends UpdateCompanion<WisdomNote> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> note;
  final Value<String> createdAt;
  final Value<int> rowid;
  const WisdomNotesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WisdomNotesCompanion.insert({
    required String id,
    required String bookId,
    required String note,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       note = Value(note),
       createdAt = Value(createdAt);
  static Insertable<WisdomNote> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WisdomNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? note,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return WisdomNotesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      note: note ?? this.note,
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
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WisdomNotesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioCacheTable extends AudioCache
    with TableInfo<$AudioCacheTable, AudioCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(0),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: Constant(false),
  );
  static const VerificationMeta _planRelevantUntilMeta = const VerificationMeta(
    'planRelevantUntil',
  );
  @override
  late final GeneratedColumn<DateTime> planRelevantUntil =
      GeneratedColumn<DateTime>(
        'plan_relevant_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    chapter,
    language,
    localPath,
    sizeBytes,
    downloadedAt,
    lastPlayedAt,
    playCount,
    isPinned,
    planRelevantUntil,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('plan_relevant_until')) {
      context.handle(
        _planRelevantUntilMeta,
        planRelevantUntil.isAcceptableOrUnknown(
          data['plan_relevant_until']!,
          _planRelevantUntilMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      planRelevantUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}plan_relevant_until'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $AudioCacheTable createAlias(String alias) {
    return $AudioCacheTable(attachedDatabase, alias);
  }
}

class AudioCacheData extends DataClass implements Insertable<AudioCacheData> {
  final String id;
  final String bookId;
  final int chapter;
  final String language;
  final String localPath;
  final int sizeBytes;
  final DateTime downloadedAt;
  final DateTime? lastPlayedAt;
  final int playCount;
  final bool isPinned;
  final DateTime? planRelevantUntil;
  final String status;
  const AudioCacheData({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.language,
    required this.localPath,
    required this.sizeBytes,
    required this.downloadedAt,
    this.lastPlayedAt,
    required this.playCount,
    required this.isPinned,
    this.planRelevantUntil,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['chapter'] = Variable<int>(chapter);
    map['language'] = Variable<String>(language);
    map['local_path'] = Variable<String>(localPath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['play_count'] = Variable<int>(playCount);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || planRelevantUntil != null) {
      map['plan_relevant_until'] = Variable<DateTime>(planRelevantUntil);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  AudioCacheCompanion toCompanion(bool nullToAbsent) {
    return AudioCacheCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapter: Value(chapter),
      language: Value(language),
      localPath: Value(localPath),
      sizeBytes: Value(sizeBytes),
      downloadedAt: Value(downloadedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      playCount: Value(playCount),
      isPinned: Value(isPinned),
      planRelevantUntil: planRelevantUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(planRelevantUntil),
      status: Value(status),
    );
  }

  factory AudioCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioCacheData(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapter: serializer.fromJson<int>(json['chapter']),
      language: serializer.fromJson<String>(json['language']),
      localPath: serializer.fromJson<String>(json['localPath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      playCount: serializer.fromJson<int>(json['playCount']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      planRelevantUntil: serializer.fromJson<DateTime?>(
        json['planRelevantUntil'],
      ),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'chapter': serializer.toJson<int>(chapter),
      'language': serializer.toJson<String>(language),
      'localPath': serializer.toJson<String>(localPath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'playCount': serializer.toJson<int>(playCount),
      'isPinned': serializer.toJson<bool>(isPinned),
      'planRelevantUntil': serializer.toJson<DateTime?>(planRelevantUntil),
      'status': serializer.toJson<String>(status),
    };
  }

  AudioCacheData copyWith({
    String? id,
    String? bookId,
    int? chapter,
    String? language,
    String? localPath,
    int? sizeBytes,
    DateTime? downloadedAt,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    int? playCount,
    bool? isPinned,
    Value<DateTime?> planRelevantUntil = const Value.absent(),
    String? status,
  }) => AudioCacheData(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    chapter: chapter ?? this.chapter,
    language: language ?? this.language,
    localPath: localPath ?? this.localPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    playCount: playCount ?? this.playCount,
    isPinned: isPinned ?? this.isPinned,
    planRelevantUntil: planRelevantUntil.present
        ? planRelevantUntil.value
        : this.planRelevantUntil,
    status: status ?? this.status,
  );
  AudioCacheData copyWithCompanion(AudioCacheCompanion data) {
    return AudioCacheData(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      language: data.language.present ? data.language.value : this.language,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      planRelevantUntil: data.planRelevantUntil.present
          ? data.planRelevantUntil.value
          : this.planRelevantUntil,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheData(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('language: $language, ')
          ..write('localPath: $localPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('planRelevantUntil: $planRelevantUntil, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    chapter,
    language,
    localPath,
    sizeBytes,
    downloadedAt,
    lastPlayedAt,
    playCount,
    isPinned,
    planRelevantUntil,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioCacheData &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapter == this.chapter &&
          other.language == this.language &&
          other.localPath == this.localPath &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.playCount == this.playCount &&
          other.isPinned == this.isPinned &&
          other.planRelevantUntil == this.planRelevantUntil &&
          other.status == this.status);
}

class AudioCacheCompanion extends UpdateCompanion<AudioCacheData> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<int> chapter;
  final Value<String> language;
  final Value<String> localPath;
  final Value<int> sizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> playCount;
  final Value<bool> isPinned;
  final Value<DateTime?> planRelevantUntil;
  final Value<String> status;
  final Value<int> rowid;
  const AudioCacheCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapter = const Value.absent(),
    this.language = const Value.absent(),
    this.localPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.planRelevantUntil = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioCacheCompanion.insert({
    required String id,
    required String bookId,
    required int chapter,
    required String language,
    required String localPath,
    required int sizeBytes,
    required DateTime downloadedAt,
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.planRelevantUntil = const Value.absent(),
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       chapter = Value(chapter),
       language = Value(language),
       localPath = Value(localPath),
       sizeBytes = Value(sizeBytes),
       downloadedAt = Value(downloadedAt),
       status = Value(status);
  static Insertable<AudioCacheData> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<int>? chapter,
    Expression<String>? language,
    Expression<String>? localPath,
    Expression<int>? sizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? playCount,
    Expression<bool>? isPinned,
    Expression<DateTime>? planRelevantUntil,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapter != null) 'chapter': chapter,
      if (language != null) 'language': language,
      if (localPath != null) 'local_path': localPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (playCount != null) 'play_count': playCount,
      if (isPinned != null) 'is_pinned': isPinned,
      if (planRelevantUntil != null) 'plan_relevant_until': planRelevantUntil,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<int>? chapter,
    Value<String>? language,
    Value<String>? localPath,
    Value<int>? sizeBytes,
    Value<DateTime>? downloadedAt,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? playCount,
    Value<bool>? isPinned,
    Value<DateTime?>? planRelevantUntil,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return AudioCacheCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      language: language ?? this.language,
      localPath: localPath ?? this.localPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      isPinned: isPinned ?? this.isPinned,
      planRelevantUntil: planRelevantUntil ?? this.planRelevantUntil,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (planRelevantUntil.present) {
      map['plan_relevant_until'] = Variable<DateTime>(planRelevantUntil.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('language: $language, ')
          ..write('localPath: $localPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('planRelevantUntil: $planRelevantUntil, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WisdomNotesTable wisdomNotes = $WisdomNotesTable(this);
  late final $AudioCacheTable audioCache = $AudioCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wisdomNotes,
    audioCache,
  ];
}

typedef $$WisdomNotesTableCreateCompanionBuilder =
    WisdomNotesCompanion Function({
      required String id,
      required String bookId,
      required String note,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$WisdomNotesTableUpdateCompanionBuilder =
    WisdomNotesCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String> note,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$WisdomNotesTableFilterComposer
    extends Composer<_$AppDatabase, $WisdomNotesTable> {
  $$WisdomNotesTableFilterComposer({
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

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WisdomNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $WisdomNotesTable> {
  $$WisdomNotesTableOrderingComposer({
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

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WisdomNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WisdomNotesTable> {
  $$WisdomNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WisdomNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WisdomNotesTable,
          WisdomNote,
          $$WisdomNotesTableFilterComposer,
          $$WisdomNotesTableOrderingComposer,
          $$WisdomNotesTableAnnotationComposer,
          $$WisdomNotesTableCreateCompanionBuilder,
          $$WisdomNotesTableUpdateCompanionBuilder,
          (
            WisdomNote,
            BaseReferences<_$AppDatabase, $WisdomNotesTable, WisdomNote>,
          ),
          WisdomNote,
          PrefetchHooks Function()
        > {
  $$WisdomNotesTableTableManager(_$AppDatabase db, $WisdomNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WisdomNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WisdomNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WisdomNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WisdomNotesCompanion(
                id: id,
                bookId: bookId,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String note,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WisdomNotesCompanion.insert(
                id: id,
                bookId: bookId,
                note: note,
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

typedef $$WisdomNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WisdomNotesTable,
      WisdomNote,
      $$WisdomNotesTableFilterComposer,
      $$WisdomNotesTableOrderingComposer,
      $$WisdomNotesTableAnnotationComposer,
      $$WisdomNotesTableCreateCompanionBuilder,
      $$WisdomNotesTableUpdateCompanionBuilder,
      (
        WisdomNote,
        BaseReferences<_$AppDatabase, $WisdomNotesTable, WisdomNote>,
      ),
      WisdomNote,
      PrefetchHooks Function()
    >;
typedef $$AudioCacheTableCreateCompanionBuilder =
    AudioCacheCompanion Function({
      required String id,
      required String bookId,
      required int chapter,
      required String language,
      required String localPath,
      required int sizeBytes,
      required DateTime downloadedAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<bool> isPinned,
      Value<DateTime?> planRelevantUntil,
      required String status,
      Value<int> rowid,
    });
typedef $$AudioCacheTableUpdateCompanionBuilder =
    AudioCacheCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<int> chapter,
      Value<String> language,
      Value<String> localPath,
      Value<int> sizeBytes,
      Value<DateTime> downloadedAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<bool> isPinned,
      Value<DateTime?> planRelevantUntil,
      Value<String> status,
      Value<int> rowid,
    });

class $$AudioCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AudioCacheTable> {
  $$AudioCacheTableFilterComposer({
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

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get planRelevantUntil => $composableBuilder(
    column: $table.planRelevantUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioCacheTable> {
  $$AudioCacheTableOrderingComposer({
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

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get planRelevantUntil => $composableBuilder(
    column: $table.planRelevantUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioCacheTable> {
  $$AudioCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get planRelevantUntil => $composableBuilder(
    column: $table.planRelevantUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$AudioCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioCacheTable,
          AudioCacheData,
          $$AudioCacheTableFilterComposer,
          $$AudioCacheTableOrderingComposer,
          $$AudioCacheTableAnnotationComposer,
          $$AudioCacheTableCreateCompanionBuilder,
          $$AudioCacheTableUpdateCompanionBuilder,
          (
            AudioCacheData,
            BaseReferences<_$AppDatabase, $AudioCacheTable, AudioCacheData>,
          ),
          AudioCacheData,
          PrefetchHooks Function()
        > {
  $$AudioCacheTableTableManager(_$AppDatabase db, $AudioCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime?> planRelevantUntil = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioCacheCompanion(
                id: id,
                bookId: bookId,
                chapter: chapter,
                language: language,
                localPath: localPath,
                sizeBytes: sizeBytes,
                downloadedAt: downloadedAt,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                isPinned: isPinned,
                planRelevantUntil: planRelevantUntil,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required int chapter,
                required String language,
                required String localPath,
                required int sizeBytes,
                required DateTime downloadedAt,
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime?> planRelevantUntil = const Value.absent(),
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => AudioCacheCompanion.insert(
                id: id,
                bookId: bookId,
                chapter: chapter,
                language: language,
                localPath: localPath,
                sizeBytes: sizeBytes,
                downloadedAt: downloadedAt,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                isPinned: isPinned,
                planRelevantUntil: planRelevantUntil,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudioCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioCacheTable,
      AudioCacheData,
      $$AudioCacheTableFilterComposer,
      $$AudioCacheTableOrderingComposer,
      $$AudioCacheTableAnnotationComposer,
      $$AudioCacheTableCreateCompanionBuilder,
      $$AudioCacheTableUpdateCompanionBuilder,
      (
        AudioCacheData,
        BaseReferences<_$AppDatabase, $AudioCacheTable, AudioCacheData>,
      ),
      AudioCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WisdomNotesTableTableManager get wisdomNotes =>
      $$WisdomNotesTableTableManager(_db, _db.wisdomNotes);
  $$AudioCacheTableTableManager get audioCache =>
      $$AudioCacheTableTableManager(_db, _db.audioCache);
}
