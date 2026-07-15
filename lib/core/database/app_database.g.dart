// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Friend'),
  );
  static const VerificationMeta _goalsMeta = const VerificationMeta('goals');
  @override
  late final GeneratedColumn<String> goals = GeneratedColumn<String>(
    'goals',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _onboardedMeta = const VerificationMeta(
    'onboarded',
  );
  @override
  late final GeneratedColumn<bool> onboarded = GeneratedColumn<bool>(
    'onboarded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _biblePlanMeta = const VerificationMeta(
    'biblePlan',
  );
  @override
  late final GeneratedColumn<String> biblePlan = GeneratedColumn<String>(
    'bible_plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('nt'),
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
  static const VerificationMeta _sabbathDayMeta = const VerificationMeta(
    'sabbathDay',
  );
  @override
  late final GeneratedColumn<int> sabbathDay = GeneratedColumn<int>(
    'sabbath_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    goals,
    onboarded,
    lang,
    biblePlan,
    createdAt,
    sabbathDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('goals')) {
      context.handle(
        _goalsMeta,
        goals.isAcceptableOrUnknown(data['goals']!, _goalsMeta),
      );
    }
    if (data.containsKey('onboarded')) {
      context.handle(
        _onboardedMeta,
        onboarded.isAcceptableOrUnknown(data['onboarded']!, _onboardedMeta),
      );
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('bible_plan')) {
      context.handle(
        _biblePlanMeta,
        biblePlan.isAcceptableOrUnknown(data['bible_plan']!, _biblePlanMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sabbath_day')) {
      context.handle(
        _sabbathDayMeta,
        sabbathDay.isAcceptableOrUnknown(data['sabbath_day']!, _sabbathDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      goals: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goals'],
      )!,
      onboarded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarded'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      biblePlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bible_plan'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      sabbathDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sabbath_day'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final String goals;
  final bool onboarded;
  final String lang;
  final String biblePlan;
  final String createdAt;
  final int sabbathDay;
  const User({
    required this.id,
    required this.name,
    required this.goals,
    required this.onboarded,
    required this.lang,
    required this.biblePlan,
    required this.createdAt,
    required this.sabbathDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['goals'] = Variable<String>(goals);
    map['onboarded'] = Variable<bool>(onboarded);
    map['lang'] = Variable<String>(lang);
    map['bible_plan'] = Variable<String>(biblePlan);
    map['created_at'] = Variable<String>(createdAt);
    map['sabbath_day'] = Variable<int>(sabbathDay);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      goals: Value(goals),
      onboarded: Value(onboarded),
      lang: Value(lang),
      biblePlan: Value(biblePlan),
      createdAt: Value(createdAt),
      sabbathDay: Value(sabbathDay),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      goals: serializer.fromJson<String>(json['goals']),
      onboarded: serializer.fromJson<bool>(json['onboarded']),
      lang: serializer.fromJson<String>(json['lang']),
      biblePlan: serializer.fromJson<String>(json['biblePlan']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      sabbathDay: serializer.fromJson<int>(json['sabbathDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'goals': serializer.toJson<String>(goals),
      'onboarded': serializer.toJson<bool>(onboarded),
      'lang': serializer.toJson<String>(lang),
      'biblePlan': serializer.toJson<String>(biblePlan),
      'createdAt': serializer.toJson<String>(createdAt),
      'sabbathDay': serializer.toJson<int>(sabbathDay),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? goals,
    bool? onboarded,
    String? lang,
    String? biblePlan,
    String? createdAt,
    int? sabbathDay,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    goals: goals ?? this.goals,
    onboarded: onboarded ?? this.onboarded,
    lang: lang ?? this.lang,
    biblePlan: biblePlan ?? this.biblePlan,
    createdAt: createdAt ?? this.createdAt,
    sabbathDay: sabbathDay ?? this.sabbathDay,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      goals: data.goals.present ? data.goals.value : this.goals,
      onboarded: data.onboarded.present ? data.onboarded.value : this.onboarded,
      lang: data.lang.present ? data.lang.value : this.lang,
      biblePlan: data.biblePlan.present ? data.biblePlan.value : this.biblePlan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sabbathDay: data.sabbathDay.present
          ? data.sabbathDay.value
          : this.sabbathDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('goals: $goals, ')
          ..write('onboarded: $onboarded, ')
          ..write('lang: $lang, ')
          ..write('biblePlan: $biblePlan, ')
          ..write('createdAt: $createdAt, ')
          ..write('sabbathDay: $sabbathDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    goals,
    onboarded,
    lang,
    biblePlan,
    createdAt,
    sabbathDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.goals == this.goals &&
          other.onboarded == this.onboarded &&
          other.lang == this.lang &&
          other.biblePlan == this.biblePlan &&
          other.createdAt == this.createdAt &&
          other.sabbathDay == this.sabbathDay);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> goals;
  final Value<bool> onboarded;
  final Value<String> lang;
  final Value<String> biblePlan;
  final Value<String> createdAt;
  final Value<int> sabbathDay;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.goals = const Value.absent(),
    this.onboarded = const Value.absent(),
    this.lang = const Value.absent(),
    this.biblePlan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sabbathDay = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.goals = const Value.absent(),
    this.onboarded = const Value.absent(),
    this.lang = const Value.absent(),
    this.biblePlan = const Value.absent(),
    required String createdAt,
    this.sabbathDay = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? goals,
    Expression<bool>? onboarded,
    Expression<String>? lang,
    Expression<String>? biblePlan,
    Expression<String>? createdAt,
    Expression<int>? sabbathDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (goals != null) 'goals': goals,
      if (onboarded != null) 'onboarded': onboarded,
      if (lang != null) 'lang': lang,
      if (biblePlan != null) 'bible_plan': biblePlan,
      if (createdAt != null) 'created_at': createdAt,
      if (sabbathDay != null) 'sabbath_day': sabbathDay,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? goals,
    Value<bool>? onboarded,
    Value<String>? lang,
    Value<String>? biblePlan,
    Value<String>? createdAt,
    Value<int>? sabbathDay,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      goals: goals ?? this.goals,
      onboarded: onboarded ?? this.onboarded,
      lang: lang ?? this.lang,
      biblePlan: biblePlan ?? this.biblePlan,
      createdAt: createdAt ?? this.createdAt,
      sabbathDay: sabbathDay ?? this.sabbathDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (goals.present) {
      map['goals'] = Variable<String>(goals.value);
    }
    if (onboarded.present) {
      map['onboarded'] = Variable<bool>(onboarded.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (biblePlan.present) {
      map['bible_plan'] = Variable<String>(biblePlan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (sabbathDay.present) {
      map['sabbath_day'] = Variable<int>(sabbathDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('goals: $goals, ')
          ..write('onboarded: $onboarded, ')
          ..write('lang: $lang, ')
          ..write('biblePlan: $biblePlan, ')
          ..write('createdAt: $createdAt, ')
          ..write('sabbathDay: $sabbathDay')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetCountMeta = const VerificationMeta(
    'targetCount',
  );
  @override
  late final GeneratedColumn<int> targetCount = GeneratedColumn<int>(
    'target_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    frequency,
    icon,
    targetCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
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
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('target_count')) {
      context.handle(
        _targetCountMeta,
        targetCount.isAcceptableOrUnknown(
          data['target_count']!,
          _targetCountMeta,
        ),
      );
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
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      targetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final String id;
  final String name;
  final String category;
  final String frequency;
  final String icon;
  final int targetCount;
  final String createdAt;
  const Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.frequency,
    required this.icon,
    required this.targetCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['frequency'] = Variable<String>(frequency);
    map['icon'] = Variable<String>(icon);
    map['target_count'] = Variable<int>(targetCount);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      frequency: Value(frequency),
      icon: Value(icon),
      targetCount: Value(targetCount),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      frequency: serializer.fromJson<String>(json['frequency']),
      icon: serializer.fromJson<String>(json['icon']),
      targetCount: serializer.fromJson<int>(json['targetCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'frequency': serializer.toJson<String>(frequency),
      'icon': serializer.toJson<String>(icon),
      'targetCount': serializer.toJson<int>(targetCount),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? category,
    String? frequency,
    String? icon,
    int? targetCount,
    String? createdAt,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    frequency: frequency ?? this.frequency,
    icon: icon ?? this.icon,
    targetCount: targetCount ?? this.targetCount,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      icon: data.icon.present ? data.icon.value : this.icon,
      targetCount: data.targetCount.present
          ? data.targetCount.value
          : this.targetCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('frequency: $frequency, ')
          ..write('icon: $icon, ')
          ..write('targetCount: $targetCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, frequency, icon, targetCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.frequency == this.frequency &&
          other.icon == this.icon &&
          other.targetCount == this.targetCount &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> frequency;
  final Value<String> icon;
  final Value<int> targetCount;
  final Value<String> createdAt;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.frequency = const Value.absent(),
    this.icon = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String name,
    required String category,
    required String frequency,
    required String icon,
    this.targetCount = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       frequency = Value(frequency),
       icon = Value(icon),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? frequency,
    Expression<String>? icon,
    Expression<int>? targetCount,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (frequency != null) 'frequency': frequency,
      if (icon != null) 'icon': icon,
      if (targetCount != null) 'target_count': targetCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? frequency,
    Value<String>? icon,
    Value<int>? targetCount,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      icon: icon ?? this.icon,
      targetCount: targetCount ?? this.targetCount,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (targetCount.present) {
      map['target_count'] = Variable<int>(targetCount.value);
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
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('frequency: $frequency, ')
          ..write('icon: $icon, ')
          ..write('targetCount: $targetCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionsTable extends Completions
    with TableInfo<$CompletionsTable, Completion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Completion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Completion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Completion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }
}

class Completion extends DataClass implements Insertable<Completion> {
  final int id;
  final String habitId;
  final String date;
  const Completion({
    required this.id,
    required this.habitId,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
    );
  }

  factory Completion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Completion(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
    };
  }

  Completion copyWith({int? id, String? habitId, String? date}) => Completion(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
  );
  Completion copyWithCompanion(CompletionsCompanion data) {
    return Completion(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Completion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date);
}

class CompletionsCompanion extends UpdateCompanion<Completion> {
  final Value<int> id;
  final Value<String> habitId;
  final Value<String> date;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
  });
  CompletionsCompanion.insert({
    this.id = const Value.absent(),
    required String habitId,
    required String date,
  }) : habitId = Value(habitId),
       date = Value(date);
  static Insertable<Completion> custom({
    Expression<int>? id,
    Expression<String>? habitId,
    Expression<String>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
    });
  }

  CompletionsCompanion copyWith({
    Value<int>? id,
    Value<String>? habitId,
    Value<String>? date,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $PrayerLogsTable extends PrayerLogs
    with TableInfo<$PrayerLogsTable, PrayerLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, minutes, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PrayerLogsTable createAlias(String alias) {
    return $PrayerLogsTable(attachedDatabase, alias);
  }
}

class PrayerLog extends DataClass implements Insertable<PrayerLog> {
  final String id;
  final String date;
  final int minutes;
  final String? note;
  const PrayerLog({
    required this.id,
    required this.date,
    required this.minutes,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['minutes'] = Variable<int>(minutes);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PrayerLogsCompanion toCompanion(bool nullToAbsent) {
    return PrayerLogsCompanion(
      id: Value(id),
      date: Value(date),
      minutes: Value(minutes),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PrayerLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerLog(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      minutes: serializer.fromJson<int>(json['minutes']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'minutes': serializer.toJson<int>(minutes),
      'note': serializer.toJson<String?>(note),
    };
  }

  PrayerLog copyWith({
    String? id,
    String? date,
    int? minutes,
    Value<String?> note = const Value.absent(),
  }) => PrayerLog(
    id: id ?? this.id,
    date: date ?? this.date,
    minutes: minutes ?? this.minutes,
    note: note.present ? note.value : this.note,
  );
  PrayerLog copyWithCompanion(PrayerLogsCompanion data) {
    return PrayerLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, minutes, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.minutes == this.minutes &&
          other.note == this.note);
}

class PrayerLogsCompanion extends UpdateCompanion<PrayerLog> {
  final Value<String> id;
  final Value<String> date;
  final Value<int> minutes;
  final Value<String?> note;
  final Value<int> rowid;
  const PrayerLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.minutes = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerLogsCompanion.insert({
    required String id,
    required String date,
    required int minutes,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       minutes = Value(minutes);
  static Insertable<PrayerLog> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<int>? minutes,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (minutes != null) 'minutes': minutes,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<int>? minutes,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return PrayerLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BibleReadsTable extends BibleReads
    with TableInfo<$BibleReadsTable, BibleRead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BibleReadsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    reference,
    note,
    durationMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_reads';
  @override
  VerificationContext validateIntegrity(
    Insertable<BibleRead> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BibleRead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BibleRead(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
    );
  }

  @override
  $BibleReadsTable createAlias(String alias) {
    return $BibleReadsTable(attachedDatabase, alias);
  }
}

class BibleRead extends DataClass implements Insertable<BibleRead> {
  final int id;
  final String date;
  final String reference;
  final String? note;
  final int durationMinutes;
  const BibleRead({
    required this.id,
    required this.date,
    required this.reference,
    this.note,
    required this.durationMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['reference'] = Variable<String>(reference);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['duration_minutes'] = Variable<int>(durationMinutes);
    return map;
  }

  BibleReadsCompanion toCompanion(bool nullToAbsent) {
    return BibleReadsCompanion(
      id: Value(id),
      date: Value(date),
      reference: Value(reference),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      durationMinutes: Value(durationMinutes),
    );
  }

  factory BibleRead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BibleRead(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      reference: serializer.fromJson<String>(json['reference']),
      note: serializer.fromJson<String?>(json['note']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'reference': serializer.toJson<String>(reference),
      'note': serializer.toJson<String?>(note),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
    };
  }

  BibleRead copyWith({
    int? id,
    String? date,
    String? reference,
    Value<String?> note = const Value.absent(),
    int? durationMinutes,
  }) => BibleRead(
    id: id ?? this.id,
    date: date ?? this.date,
    reference: reference ?? this.reference,
    note: note.present ? note.value : this.note,
    durationMinutes: durationMinutes ?? this.durationMinutes,
  );
  BibleRead copyWithCompanion(BibleReadsCompanion data) {
    return BibleRead(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      reference: data.reference.present ? data.reference.value : this.reference,
      note: data.note.present ? data.note.value : this.note,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BibleRead(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('reference: $reference, ')
          ..write('note: $note, ')
          ..write('durationMinutes: $durationMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, reference, note, durationMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BibleRead &&
          other.id == this.id &&
          other.date == this.date &&
          other.reference == this.reference &&
          other.note == this.note &&
          other.durationMinutes == this.durationMinutes);
}

class BibleReadsCompanion extends UpdateCompanion<BibleRead> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> reference;
  final Value<String?> note;
  final Value<int> durationMinutes;
  const BibleReadsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.reference = const Value.absent(),
    this.note = const Value.absent(),
    this.durationMinutes = const Value.absent(),
  });
  BibleReadsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String reference,
    this.note = const Value.absent(),
    this.durationMinutes = const Value.absent(),
  }) : date = Value(date),
       reference = Value(reference);
  static Insertable<BibleRead> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? reference,
    Expression<String>? note,
    Expression<int>? durationMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (reference != null) 'reference': reference,
      if (note != null) 'note': note,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
    });
  }

  BibleReadsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? reference,
    Value<String?>? note,
    Value<int>? durationMinutes,
  }) {
    return BibleReadsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      note: note ?? this.note,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BibleReadsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('reference: $reference, ')
          ..write('note: $note, ')
          ..write('durationMinutes: $durationMinutes')
          ..write(')'))
        .toString();
  }
}

class $SkillsTable extends Skills with TableInfo<$SkillsTable, Skill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillsTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMinutesMeta = const VerificationMeta(
    'targetMinutes',
  );
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
    'target_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
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
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    icon,
    targetMinutes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Skill> instance, {
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
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
        _targetMinutesMeta,
        targetMinutes.isAcceptableOrUnknown(
          data['target_minutes']!,
          _targetMinutesMeta,
        ),
      );
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
  Skill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Skill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      targetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_minutes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SkillsTable createAlias(String alias) {
    return $SkillsTable(attachedDatabase, alias);
  }
}

class Skill extends DataClass implements Insertable<Skill> {
  final String id;
  final String name;
  final String category;
  final String icon;
  final int targetMinutes;
  final String createdAt;
  const Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.targetMinutes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['icon'] = Variable<String>(icon);
    map['target_minutes'] = Variable<int>(targetMinutes);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SkillsCompanion toCompanion(bool nullToAbsent) {
    return SkillsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      icon: Value(icon),
      targetMinutes: Value(targetMinutes),
      createdAt: Value(createdAt),
    );
  }

  factory Skill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Skill(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      icon: serializer.fromJson<String>(json['icon']),
      targetMinutes: serializer.fromJson<int>(json['targetMinutes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'icon': serializer.toJson<String>(icon),
      'targetMinutes': serializer.toJson<int>(targetMinutes),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    String? icon,
    int? targetMinutes,
    String? createdAt,
  }) => Skill(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    icon: icon ?? this.icon,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    createdAt: createdAt ?? this.createdAt,
  );
  Skill copyWithCompanion(SkillsCompanion data) {
    return Skill(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      icon: data.icon.present ? data.icon.value : this.icon,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Skill(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('icon: $icon, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, icon, targetMinutes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Skill &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.icon == this.icon &&
          other.targetMinutes == this.targetMinutes &&
          other.createdAt == this.createdAt);
}

class SkillsCompanion extends UpdateCompanion<Skill> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> icon;
  final Value<int> targetMinutes;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SkillsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.icon = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillsCompanion.insert({
    required String id,
    required String name,
    required String category,
    required String icon,
    this.targetMinutes = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       icon = Value(icon),
       createdAt = Value(createdAt);
  static Insertable<Skill> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? icon,
    Expression<int>? targetMinutes,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (icon != null) 'icon': icon,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? icon,
    Value<int>? targetMinutes,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return SkillsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      targetMinutes: targetMinutes ?? this.targetMinutes,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
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
    return (StringBuffer('SkillsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('icon: $icon, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SkillSessionsTable extends SkillSessions
    with TableInfo<$SkillSessionsTable, SkillSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES skills (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, skillId, date, minutes, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skill_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkillSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SkillSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkillSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $SkillSessionsTable createAlias(String alias) {
    return $SkillSessionsTable(attachedDatabase, alias);
  }
}

class SkillSession extends DataClass implements Insertable<SkillSession> {
  final int id;
  final String skillId;
  final String date;
  final int minutes;
  final String? note;
  const SkillSession({
    required this.id,
    required this.skillId,
    required this.date,
    required this.minutes,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['skill_id'] = Variable<String>(skillId);
    map['date'] = Variable<String>(date);
    map['minutes'] = Variable<int>(minutes);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SkillSessionsCompanion toCompanion(bool nullToAbsent) {
    return SkillSessionsCompanion(
      id: Value(id),
      skillId: Value(skillId),
      date: Value(date),
      minutes: Value(minutes),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory SkillSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkillSession(
      id: serializer.fromJson<int>(json['id']),
      skillId: serializer.fromJson<String>(json['skillId']),
      date: serializer.fromJson<String>(json['date']),
      minutes: serializer.fromJson<int>(json['minutes']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'skillId': serializer.toJson<String>(skillId),
      'date': serializer.toJson<String>(date),
      'minutes': serializer.toJson<int>(minutes),
      'note': serializer.toJson<String?>(note),
    };
  }

  SkillSession copyWith({
    int? id,
    String? skillId,
    String? date,
    int? minutes,
    Value<String?> note = const Value.absent(),
  }) => SkillSession(
    id: id ?? this.id,
    skillId: skillId ?? this.skillId,
    date: date ?? this.date,
    minutes: minutes ?? this.minutes,
    note: note.present ? note.value : this.note,
  );
  SkillSession copyWithCompanion(SkillSessionsCompanion data) {
    return SkillSession(
      id: data.id.present ? data.id.value : this.id,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      date: data.date.present ? data.date.value : this.date,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkillSession(')
          ..write('id: $id, ')
          ..write('skillId: $skillId, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, skillId, date, minutes, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkillSession &&
          other.id == this.id &&
          other.skillId == this.skillId &&
          other.date == this.date &&
          other.minutes == this.minutes &&
          other.note == this.note);
}

class SkillSessionsCompanion extends UpdateCompanion<SkillSession> {
  final Value<int> id;
  final Value<String> skillId;
  final Value<String> date;
  final Value<int> minutes;
  final Value<String?> note;
  const SkillSessionsCompanion({
    this.id = const Value.absent(),
    this.skillId = const Value.absent(),
    this.date = const Value.absent(),
    this.minutes = const Value.absent(),
    this.note = const Value.absent(),
  });
  SkillSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String skillId,
    required String date,
    required int minutes,
    this.note = const Value.absent(),
  }) : skillId = Value(skillId),
       date = Value(date),
       minutes = Value(minutes);
  static Insertable<SkillSession> custom({
    Expression<int>? id,
    Expression<String>? skillId,
    Expression<String>? date,
    Expression<int>? minutes,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (skillId != null) 'skill_id': skillId,
      if (date != null) 'date': date,
      if (minutes != null) 'minutes': minutes,
      if (note != null) 'note': note,
    });
  }

  SkillSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? skillId,
    Value<String>? date,
    Value<int>? minutes,
    Value<String?>? note,
  }) {
    return SkillSessionsCompanion(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillSessionsCompanion(')
          ..write('id: $id, ')
          ..write('skillId: $skillId, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ReflectionsTable extends Reflections
    with TableInfo<$ReflectionsTable, Reflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _grewMeta = const VerificationMeta('grew');
  @override
  late final GeneratedColumn<String> grew = GeneratedColumn<String>(
    'grew',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slippedMeta = const VerificationMeta(
    'slipped',
  );
  @override
  late final GeneratedColumn<String> slipped = GeneratedColumn<String>(
    'slipped',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextFocusMeta = const VerificationMeta(
    'nextFocus',
  );
  @override
  late final GeneratedColumn<String> nextFocus = GeneratedColumn<String>(
    'next_focus',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [
    id,
    weekStart,
    grew,
    slipped,
    nextFocus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('grew')) {
      context.handle(
        _grewMeta,
        grew.isAcceptableOrUnknown(data['grew']!, _grewMeta),
      );
    }
    if (data.containsKey('slipped')) {
      context.handle(
        _slippedMeta,
        slipped.isAcceptableOrUnknown(data['slipped']!, _slippedMeta),
      );
    }
    if (data.containsKey('next_focus')) {
      context.handle(
        _nextFocusMeta,
        nextFocus.isAcceptableOrUnknown(data['next_focus']!, _nextFocusMeta),
      );
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
  Reflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reflection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      grew: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grew'],
      ),
      slipped: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slipped'],
      ),
      nextFocus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_focus'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReflectionsTable createAlias(String alias) {
    return $ReflectionsTable(attachedDatabase, alias);
  }
}

class Reflection extends DataClass implements Insertable<Reflection> {
  final String id;
  final String weekStart;
  final String? grew;
  final String? slipped;
  final String? nextFocus;
  final String createdAt;
  const Reflection({
    required this.id,
    required this.weekStart,
    this.grew,
    this.slipped,
    this.nextFocus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['week_start'] = Variable<String>(weekStart);
    if (!nullToAbsent || grew != null) {
      map['grew'] = Variable<String>(grew);
    }
    if (!nullToAbsent || slipped != null) {
      map['slipped'] = Variable<String>(slipped);
    }
    if (!nullToAbsent || nextFocus != null) {
      map['next_focus'] = Variable<String>(nextFocus);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ReflectionsCompanion toCompanion(bool nullToAbsent) {
    return ReflectionsCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      grew: grew == null && nullToAbsent ? const Value.absent() : Value(grew),
      slipped: slipped == null && nullToAbsent
          ? const Value.absent()
          : Value(slipped),
      nextFocus: nextFocus == null && nullToAbsent
          ? const Value.absent()
          : Value(nextFocus),
      createdAt: Value(createdAt),
    );
  }

  factory Reflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reflection(
      id: serializer.fromJson<String>(json['id']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      grew: serializer.fromJson<String?>(json['grew']),
      slipped: serializer.fromJson<String?>(json['slipped']),
      nextFocus: serializer.fromJson<String?>(json['nextFocus']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weekStart': serializer.toJson<String>(weekStart),
      'grew': serializer.toJson<String?>(grew),
      'slipped': serializer.toJson<String?>(slipped),
      'nextFocus': serializer.toJson<String?>(nextFocus),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Reflection copyWith({
    String? id,
    String? weekStart,
    Value<String?> grew = const Value.absent(),
    Value<String?> slipped = const Value.absent(),
    Value<String?> nextFocus = const Value.absent(),
    String? createdAt,
  }) => Reflection(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    grew: grew.present ? grew.value : this.grew,
    slipped: slipped.present ? slipped.value : this.slipped,
    nextFocus: nextFocus.present ? nextFocus.value : this.nextFocus,
    createdAt: createdAt ?? this.createdAt,
  );
  Reflection copyWithCompanion(ReflectionsCompanion data) {
    return Reflection(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      grew: data.grew.present ? data.grew.value : this.grew,
      slipped: data.slipped.present ? data.slipped.value : this.slipped,
      nextFocus: data.nextFocus.present ? data.nextFocus.value : this.nextFocus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reflection(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('grew: $grew, ')
          ..write('slipped: $slipped, ')
          ..write('nextFocus: $nextFocus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, weekStart, grew, slipped, nextFocus, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reflection &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.grew == this.grew &&
          other.slipped == this.slipped &&
          other.nextFocus == this.nextFocus &&
          other.createdAt == this.createdAt);
}

class ReflectionsCompanion extends UpdateCompanion<Reflection> {
  final Value<String> id;
  final Value<String> weekStart;
  final Value<String?> grew;
  final Value<String?> slipped;
  final Value<String?> nextFocus;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ReflectionsCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.grew = const Value.absent(),
    this.slipped = const Value.absent(),
    this.nextFocus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionsCompanion.insert({
    required String id,
    required String weekStart,
    this.grew = const Value.absent(),
    this.slipped = const Value.absent(),
    this.nextFocus = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weekStart = Value(weekStart),
       createdAt = Value(createdAt);
  static Insertable<Reflection> custom({
    Expression<String>? id,
    Expression<String>? weekStart,
    Expression<String>? grew,
    Expression<String>? slipped,
    Expression<String>? nextFocus,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (grew != null) 'grew': grew,
      if (slipped != null) 'slipped': slipped,
      if (nextFocus != null) 'next_focus': nextFocus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? weekStart,
    Value<String?>? grew,
    Value<String?>? slipped,
    Value<String?>? nextFocus,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ReflectionsCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      grew: grew ?? this.grew,
      slipped: slipped ?? this.slipped,
      nextFocus: nextFocus ?? this.nextFocus,
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
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (grew.present) {
      map['grew'] = Variable<String>(grew.value);
    }
    if (slipped.present) {
      map['slipped'] = Variable<String>(slipped.value);
    }
    if (nextFocus.present) {
      map['next_focus'] = Variable<String>(nextFocus.value);
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
    return (StringBuffer('ReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('grew: $grew, ')
          ..write('slipped: $slipped, ')
          ..write('nextFocus: $nextFocus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChallengesTable extends Challenges
    with TableInfo<$ChallengesTable, Challenge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengesTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _participantsMeta = const VerificationMeta(
    'participants',
  );
  @override
  late final GeneratedColumn<int> participants = GeneratedColumn<int>(
    'participants',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    type,
    durationDays,
    startDate,
    createdBy,
    participants,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'challenges';
  @override
  VerificationContext validateIntegrity(
    Insertable<Challenge> instance, {
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
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationDaysMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('participants')) {
      context.handle(
        _participantsMeta,
        participants.isAcceptableOrUnknown(
          data['participants']!,
          _participantsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Challenge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Challenge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      participants: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}participants'],
      )!,
    );
  }

  @override
  $ChallengesTable createAlias(String alias) {
    return $ChallengesTable(attachedDatabase, alias);
  }
}

class Challenge extends DataClass implements Insertable<Challenge> {
  final String id;
  final String title;
  final String description;
  final String type;
  final int durationDays;
  final String startDate;
  final String? createdBy;
  final int participants;
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.durationDays,
    required this.startDate,
    this.createdBy,
    required this.participants,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['duration_days'] = Variable<int>(durationDays);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['participants'] = Variable<int>(participants);
    return map;
  }

  ChallengesCompanion toCompanion(bool nullToAbsent) {
    return ChallengesCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      type: Value(type),
      durationDays: Value(durationDays),
      startDate: Value(startDate),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      participants: Value(participants),
    );
  }

  factory Challenge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Challenge(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      durationDays: serializer.fromJson<int>(json['durationDays']),
      startDate: serializer.fromJson<String>(json['startDate']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      participants: serializer.fromJson<int>(json['participants']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'durationDays': serializer.toJson<int>(durationDays),
      'startDate': serializer.toJson<String>(startDate),
      'createdBy': serializer.toJson<String?>(createdBy),
      'participants': serializer.toJson<int>(participants),
    };
  }

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? durationDays,
    String? startDate,
    Value<String?> createdBy = const Value.absent(),
    int? participants,
  }) => Challenge(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    durationDays: durationDays ?? this.durationDays,
    startDate: startDate ?? this.startDate,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    participants: participants ?? this.participants,
  );
  Challenge copyWithCompanion(ChallengesCompanion data) {
    return Challenge(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      participants: data.participants.present
          ? data.participants.value
          : this.participants,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Challenge(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('durationDays: $durationDays, ')
          ..write('startDate: $startDate, ')
          ..write('createdBy: $createdBy, ')
          ..write('participants: $participants')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    type,
    durationDays,
    startDate,
    createdBy,
    participants,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Challenge &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.durationDays == this.durationDays &&
          other.startDate == this.startDate &&
          other.createdBy == this.createdBy &&
          other.participants == this.participants);
}

class ChallengesCompanion extends UpdateCompanion<Challenge> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> type;
  final Value<int> durationDays;
  final Value<String> startDate;
  final Value<String?> createdBy;
  final Value<int> participants;
  final Value<int> rowid;
  const ChallengesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.startDate = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.participants = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChallengesCompanion.insert({
    required String id,
    required String title,
    required String description,
    required String type,
    required int durationDays,
    required String startDate,
    this.createdBy = const Value.absent(),
    this.participants = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       description = Value(description),
       type = Value(type),
       durationDays = Value(durationDays),
       startDate = Value(startDate);
  static Insertable<Challenge> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<int>? durationDays,
    Expression<String>? startDate,
    Expression<String>? createdBy,
    Expression<int>? participants,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (durationDays != null) 'duration_days': durationDays,
      if (startDate != null) 'start_date': startDate,
      if (createdBy != null) 'created_by': createdBy,
      if (participants != null) 'participants': participants,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChallengesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<String>? type,
    Value<int>? durationDays,
    Value<String>? startDate,
    Value<String?>? createdBy,
    Value<int>? participants,
    Value<int>? rowid,
  }) {
    return ChallengesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (participants.present) {
      map['participants'] = Variable<int>(participants.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('durationDays: $durationDays, ')
          ..write('startDate: $startDate, ')
          ..write('createdBy: $createdBy, ')
          ..write('participants: $participants, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChallengeParticipantsTable extends ChallengeParticipants
    with TableInfo<$ChallengeParticipantsTable, ChallengeParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengeParticipantsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _challengeIdMeta = const VerificationMeta(
    'challengeId',
  );
  @override
  late final GeneratedColumn<String> challengeId = GeneratedColumn<String>(
    'challenge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES challenges (id)',
    ),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedDateMeta = const VerificationMeta(
    'joinedDate',
  );
  @override
  late final GeneratedColumn<String> joinedDate = GeneratedColumn<String>(
    'joined_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    challengeId,
    userName,
    joinedDate,
    progress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'challenge_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChallengeParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('challenge_id')) {
      context.handle(
        _challengeIdMeta,
        challengeId.isAcceptableOrUnknown(
          data['challenge_id']!,
          _challengeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_challengeIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('joined_date')) {
      context.handle(
        _joinedDateMeta,
        joinedDate.isAcceptableOrUnknown(data['joined_date']!, _joinedDateMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedDateMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChallengeParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChallengeParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      challengeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge_id'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      )!,
      joinedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joined_date'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
    );
  }

  @override
  $ChallengeParticipantsTable createAlias(String alias) {
    return $ChallengeParticipantsTable(attachedDatabase, alias);
  }
}

class ChallengeParticipant extends DataClass
    implements Insertable<ChallengeParticipant> {
  final int id;
  final String challengeId;
  final String userName;
  final String joinedDate;
  final int progress;
  const ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userName,
    required this.joinedDate,
    required this.progress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['challenge_id'] = Variable<String>(challengeId);
    map['user_name'] = Variable<String>(userName);
    map['joined_date'] = Variable<String>(joinedDate);
    map['progress'] = Variable<int>(progress);
    return map;
  }

  ChallengeParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ChallengeParticipantsCompanion(
      id: Value(id),
      challengeId: Value(challengeId),
      userName: Value(userName),
      joinedDate: Value(joinedDate),
      progress: Value(progress),
    );
  }

  factory ChallengeParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChallengeParticipant(
      id: serializer.fromJson<int>(json['id']),
      challengeId: serializer.fromJson<String>(json['challengeId']),
      userName: serializer.fromJson<String>(json['userName']),
      joinedDate: serializer.fromJson<String>(json['joinedDate']),
      progress: serializer.fromJson<int>(json['progress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'challengeId': serializer.toJson<String>(challengeId),
      'userName': serializer.toJson<String>(userName),
      'joinedDate': serializer.toJson<String>(joinedDate),
      'progress': serializer.toJson<int>(progress),
    };
  }

  ChallengeParticipant copyWith({
    int? id,
    String? challengeId,
    String? userName,
    String? joinedDate,
    int? progress,
  }) => ChallengeParticipant(
    id: id ?? this.id,
    challengeId: challengeId ?? this.challengeId,
    userName: userName ?? this.userName,
    joinedDate: joinedDate ?? this.joinedDate,
    progress: progress ?? this.progress,
  );
  ChallengeParticipant copyWithCompanion(ChallengeParticipantsCompanion data) {
    return ChallengeParticipant(
      id: data.id.present ? data.id.value : this.id,
      challengeId: data.challengeId.present
          ? data.challengeId.value
          : this.challengeId,
      userName: data.userName.present ? data.userName.value : this.userName,
      joinedDate: data.joinedDate.present
          ? data.joinedDate.value
          : this.joinedDate,
      progress: data.progress.present ? data.progress.value : this.progress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeParticipant(')
          ..write('id: $id, ')
          ..write('challengeId: $challengeId, ')
          ..write('userName: $userName, ')
          ..write('joinedDate: $joinedDate, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, challengeId, userName, joinedDate, progress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeParticipant &&
          other.id == this.id &&
          other.challengeId == this.challengeId &&
          other.userName == this.userName &&
          other.joinedDate == this.joinedDate &&
          other.progress == this.progress);
}

class ChallengeParticipantsCompanion
    extends UpdateCompanion<ChallengeParticipant> {
  final Value<int> id;
  final Value<String> challengeId;
  final Value<String> userName;
  final Value<String> joinedDate;
  final Value<int> progress;
  const ChallengeParticipantsCompanion({
    this.id = const Value.absent(),
    this.challengeId = const Value.absent(),
    this.userName = const Value.absent(),
    this.joinedDate = const Value.absent(),
    this.progress = const Value.absent(),
  });
  ChallengeParticipantsCompanion.insert({
    this.id = const Value.absent(),
    required String challengeId,
    required String userName,
    required String joinedDate,
    this.progress = const Value.absent(),
  }) : challengeId = Value(challengeId),
       userName = Value(userName),
       joinedDate = Value(joinedDate);
  static Insertable<ChallengeParticipant> custom({
    Expression<int>? id,
    Expression<String>? challengeId,
    Expression<String>? userName,
    Expression<String>? joinedDate,
    Expression<int>? progress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (challengeId != null) 'challenge_id': challengeId,
      if (userName != null) 'user_name': userName,
      if (joinedDate != null) 'joined_date': joinedDate,
      if (progress != null) 'progress': progress,
    });
  }

  ChallengeParticipantsCompanion copyWith({
    Value<int>? id,
    Value<String>? challengeId,
    Value<String>? userName,
    Value<String>? joinedDate,
    Value<int>? progress,
  }) {
    return ChallengeParticipantsCompanion(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userName: userName ?? this.userName,
      joinedDate: joinedDate ?? this.joinedDate,
      progress: progress ?? this.progress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (challengeId.present) {
      map['challenge_id'] = Variable<String>(challengeId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (joinedDate.present) {
      map['joined_date'] = Variable<String>(joinedDate.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('challengeId: $challengeId, ')
          ..write('userName: $userName, ')
          ..write('joinedDate: $joinedDate, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }
}

class $FellowshipLogsTable extends FellowshipLogs
    with TableInfo<$FellowshipLogsTable, FellowshipLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FellowshipLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactNameMeta = const VerificationMeta(
    'contactName',
  );
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
    'contact_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _promptTypeMeta = const VerificationMeta(
    'promptType',
  );
  @override
  late final GeneratedColumn<int> promptType = GeneratedColumn<int>(
    'prompt_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    contactName,
    note,
    createdAt,
    promptType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fellowship_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FellowshipLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('contact_name')) {
      context.handle(
        _contactNameMeta,
        contactName.isAcceptableOrUnknown(
          data['contact_name']!,
          _contactNameMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('prompt_type')) {
      context.handle(
        _promptTypeMeta,
        promptType.isAcceptableOrUnknown(data['prompt_type']!, _promptTypeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FellowshipLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FellowshipLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      contactName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_name'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      promptType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_type'],
      )!,
    );
  }

  @override
  $FellowshipLogsTable createAlias(String alias) {
    return $FellowshipLogsTable(attachedDatabase, alias);
  }
}

class FellowshipLog extends DataClass implements Insertable<FellowshipLog> {
  final String id;
  final String date;
  final String? contactName;
  final String? note;
  final String createdAt;
  final int promptType;
  const FellowshipLog({
    required this.id,
    required this.date,
    this.contactName,
    this.note,
    required this.createdAt,
    required this.promptType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || contactName != null) {
      map['contact_name'] = Variable<String>(contactName);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['prompt_type'] = Variable<int>(promptType);
    return map;
  }

  FellowshipLogsCompanion toCompanion(bool nullToAbsent) {
    return FellowshipLogsCompanion(
      id: Value(id),
      date: Value(date),
      contactName: contactName == null && nullToAbsent
          ? const Value.absent()
          : Value(contactName),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      promptType: Value(promptType),
    );
  }

  factory FellowshipLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FellowshipLog(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      contactName: serializer.fromJson<String?>(json['contactName']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      promptType: serializer.fromJson<int>(json['promptType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'contactName': serializer.toJson<String?>(contactName),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
      'promptType': serializer.toJson<int>(promptType),
    };
  }

  FellowshipLog copyWith({
    String? id,
    String? date,
    Value<String?> contactName = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? createdAt,
    int? promptType,
  }) => FellowshipLog(
    id: id ?? this.id,
    date: date ?? this.date,
    contactName: contactName.present ? contactName.value : this.contactName,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    promptType: promptType ?? this.promptType,
  );
  FellowshipLog copyWithCompanion(FellowshipLogsCompanion data) {
    return FellowshipLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      contactName: data.contactName.present
          ? data.contactName.value
          : this.contactName,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      promptType: data.promptType.present
          ? data.promptType.value
          : this.promptType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FellowshipLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('contactName: $contactName, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('promptType: $promptType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, contactName, note, createdAt, promptType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FellowshipLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.contactName == this.contactName &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.promptType == this.promptType);
}

class FellowshipLogsCompanion extends UpdateCompanion<FellowshipLog> {
  final Value<String> id;
  final Value<String> date;
  final Value<String?> contactName;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<int> promptType;
  final Value<int> rowid;
  const FellowshipLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.contactName = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.promptType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FellowshipLogsCompanion.insert({
    required String id,
    required String date,
    this.contactName = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
    this.promptType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<FellowshipLog> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? contactName,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<int>? promptType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (contactName != null) 'contact_name': contactName,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (promptType != null) 'prompt_type': promptType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FellowshipLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String?>? contactName,
    Value<String?>? note,
    Value<String>? createdAt,
    Value<int>? promptType,
    Value<int>? rowid,
  }) {
    return FellowshipLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      contactName: contactName ?? this.contactName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      promptType: promptType ?? this.promptType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (promptType.present) {
      map['prompt_type'] = Variable<int>(promptType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FellowshipLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('contactName: $contactName, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('promptType: $promptType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyTimeLogsTable extends FamilyTimeLogs
    with TableInfo<$FamilyTimeLogsTable, FamilyTimeLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyTimeLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [id, date, hours, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_time_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyTimeLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
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
  FamilyTimeLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyTimeLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FamilyTimeLogsTable createAlias(String alias) {
    return $FamilyTimeLogsTable(attachedDatabase, alias);
  }
}

class FamilyTimeLog extends DataClass implements Insertable<FamilyTimeLog> {
  final String id;
  final String date;
  final double hours;
  final String? note;
  final String createdAt;
  const FamilyTimeLog({
    required this.id,
    required this.date,
    required this.hours,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['hours'] = Variable<double>(hours);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  FamilyTimeLogsCompanion toCompanion(bool nullToAbsent) {
    return FamilyTimeLogsCompanion(
      id: Value(id),
      date: Value(date),
      hours: Value(hours),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyTimeLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyTimeLog(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      hours: serializer.fromJson<double>(json['hours']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'hours': serializer.toJson<double>(hours),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  FamilyTimeLog copyWith({
    String? id,
    String? date,
    double? hours,
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => FamilyTimeLog(
    id: id ?? this.id,
    date: date ?? this.date,
    hours: hours ?? this.hours,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  FamilyTimeLog copyWithCompanion(FamilyTimeLogsCompanion data) {
    return FamilyTimeLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      hours: data.hours.present ? data.hours.value : this.hours,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyTimeLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('hours: $hours, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, hours, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyTimeLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.hours == this.hours &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class FamilyTimeLogsCompanion extends UpdateCompanion<FamilyTimeLog> {
  final Value<String> id;
  final Value<String> date;
  final Value<double> hours;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<int> rowid;
  const FamilyTimeLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.hours = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyTimeLogsCompanion.insert({
    required String id,
    required String date,
    required double hours,
    this.note = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       hours = Value(hours),
       createdAt = Value(createdAt);
  static Insertable<FamilyTimeLog> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<double>? hours,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (hours != null) 'hours': hours,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyTimeLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<double>? hours,
    Value<String?>? note,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return FamilyTimeLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      hours: hours ?? this.hours,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
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
    return (StringBuffer('FamilyTimeLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('hours: $hours, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<String> periodStart = GeneratedColumn<String>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAchievedMeta = const VerificationMeta(
    'isAchieved',
  );
  @override
  late final GeneratedColumn<bool> isAchieved = GeneratedColumn<bool>(
    'is_achieved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_achieved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  List<GeneratedColumn> get $columns => [
    id,
    title,
    type,
    periodStart,
    isAchieved,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
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
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('is_achieved')) {
      context.handle(
        _isAchievedMeta,
        isAchieved.isAcceptableOrUnknown(data['is_achieved']!, _isAchievedMeta),
      );
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
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_start'],
      )!,
      isAchieved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_achieved'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String title;
  final String type;
  final String periodStart;
  final bool isAchieved;
  final String createdAt;
  const Goal({
    required this.id,
    required this.title,
    required this.type,
    required this.periodStart,
    required this.isAchieved,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['period_start'] = Variable<String>(periodStart);
    map['is_achieved'] = Variable<bool>(isAchieved);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      periodStart: Value(periodStart),
      isAchieved: Value(isAchieved),
      createdAt: Value(createdAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      periodStart: serializer.fromJson<String>(json['periodStart']),
      isAchieved: serializer.fromJson<bool>(json['isAchieved']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'periodStart': serializer.toJson<String>(periodStart),
      'isAchieved': serializer.toJson<bool>(isAchieved),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Goal copyWith({
    String? id,
    String? title,
    String? type,
    String? periodStart,
    bool? isAchieved,
    String? createdAt,
  }) => Goal(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    periodStart: periodStart ?? this.periodStart,
    isAchieved: isAchieved ?? this.isAchieved,
    createdAt: createdAt ?? this.createdAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      isAchieved: data.isAchieved.present
          ? data.isAchieved.value
          : this.isAchieved,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('periodStart: $periodStart, ')
          ..write('isAchieved: $isAchieved, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, type, periodStart, isAchieved, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.periodStart == this.periodStart &&
          other.isAchieved == this.isAchieved &&
          other.createdAt == this.createdAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> type;
  final Value<String> periodStart;
  final Value<bool> isAchieved;
  final Value<String> createdAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.isAchieved = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String title,
    required String type,
    required String periodStart,
    this.isAchieved = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       type = Value(type),
       periodStart = Value(periodStart),
       createdAt = Value(createdAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? periodStart,
    Expression<bool>? isAchieved,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (periodStart != null) 'period_start': periodStart,
      if (isAchieved != null) 'is_achieved': isAchieved,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? type,
    Value<String>? periodStart,
    Value<bool>? isAchieved,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      periodStart: periodStart ?? this.periodStart,
      isAchieved: isAchieved ?? this.isAchieved,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<String>(periodStart.value);
    }
    if (isAchieved.present) {
      map['is_achieved'] = Variable<bool>(isAchieved.value);
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
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('periodStart: $periodStart, ')
          ..write('isAchieved: $isAchieved, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodoItemsTable extends TodoItems
    with TableInfo<$TodoItemsTable, TodoItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoItemsTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSkippedMeta = const VerificationMeta(
    'isSkipped',
  );
  @override
  late final GeneratedColumn<bool> isSkipped = GeneratedColumn<bool>(
    'is_skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  List<GeneratedColumn> get $columns => [
    id,
    title,
    date,
    isCompleted,
    completedAt,
    isSkipped,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoItem> instance, {
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
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_skipped')) {
      context.handle(
        _isSkippedMeta,
        isSkipped.isAcceptableOrUnknown(data['is_skipped']!, _isSkippedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
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
  TodoItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      isSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_skipped'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TodoItemsTable createAlias(String alias) {
    return $TodoItemsTable(attachedDatabase, alias);
  }
}

class TodoItem extends DataClass implements Insertable<TodoItem> {
  final String id;
  final String title;
  final String date;
  final bool isCompleted;
  final String? completedAt;
  final bool isSkipped;
  final int sortOrder;
  final String createdAt;
  const TodoItem({
    required this.id,
    required this.title,
    required this.date,
    required this.isCompleted,
    this.completedAt,
    required this.isSkipped,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<String>(date);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    map['is_skipped'] = Variable<bool>(isSkipped);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      isSkipped: Value(isSkipped),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory TodoItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItem(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<String>(json['date']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      isSkipped: serializer.fromJson<bool>(json['isSkipped']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<String>(date),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<String?>(completedAt),
      'isSkipped': serializer.toJson<bool>(isSkipped),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  TodoItem copyWith({
    String? id,
    String? title,
    String? date,
    bool? isCompleted,
    Value<String?> completedAt = const Value.absent(),
    bool? isSkipped,
    int? sortOrder,
    String? createdAt,
  }) => TodoItem(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    isSkipped: isSkipped ?? this.isSkipped,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  TodoItem copyWithCompanion(TodoItemsCompanion data) {
    return TodoItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      isSkipped: data.isSkipped.present ? data.isSkipped.value : this.isSkipped,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    isCompleted,
    completedAt,
    isSkipped,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.isSkipped == this.isSkipped &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class TodoItemsCompanion extends UpdateCompanion<TodoItem> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> date;
  final Value<bool> isCompleted;
  final Value<String?> completedAt;
  final Value<bool> isSkipped;
  final Value<int> sortOrder;
  final Value<String> createdAt;
  final Value<int> rowid;
  const TodoItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoItemsCompanion.insert({
    required String id,
    required String title,
    required String date,
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<TodoItem> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? date,
    Expression<bool>? isCompleted,
    Expression<String>? completedAt,
    Expression<bool>? isSkipped,
    Expression<int>? sortOrder,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (isSkipped != null) 'is_skipped': isSkipped,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? date,
    Value<bool>? isCompleted,
    Value<String?>? completedAt,
    Value<bool>? isSkipped,
    Value<int>? sortOrder,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return TodoItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isSkipped: isSkipped ?? this.isSkipped,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (isSkipped.present) {
      map['is_skipped'] = Variable<bool>(isSkipped.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReflectionsTable extends DailyReflections
    with TableInfo<$DailyReflectionsTable, DailyReflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
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
  List<GeneratedColumn> get $columns => [id, date, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
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
  DailyReflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReflection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyReflectionsTable createAlias(String alias) {
    return $DailyReflectionsTable(attachedDatabase, alias);
  }
}

class DailyReflection extends DataClass implements Insertable<DailyReflection> {
  final String id;
  final String date;
  final String content;
  final String createdAt;
  const DailyReflection({
    required this.id,
    required this.date,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DailyReflectionsCompanion toCompanion(bool nullToAbsent) {
    return DailyReflectionsCompanion(
      id: Value(id),
      date: Value(date),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory DailyReflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReflection(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DailyReflection copyWith({
    String? id,
    String? date,
    String? content,
    String? createdAt,
  }) => DailyReflection(
    id: id ?? this.id,
    date: date ?? this.date,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyReflection copyWithCompanion(DailyReflectionsCompanion data) {
    return DailyReflection(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReflection(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReflection &&
          other.id == this.id &&
          other.date == this.date &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class DailyReflectionsCompanion extends UpdateCompanion<DailyReflection> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> content;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DailyReflectionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReflectionsCompanion.insert({
    required String id,
    required String date,
    required String content,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<DailyReflection> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? content,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReflectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? content,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DailyReflectionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
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
    return (StringBuffer('DailyReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakLogTable extends StreakLog
    with TableInfo<$StreakLogTable, StreakLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _countedMeta = const VerificationMeta(
    'counted',
  );
  @override
  late final GeneratedColumn<bool> counted = GeneratedColumn<bool>(
    'counted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _freezeUsedMeta = const VerificationMeta(
    'freezeUsed',
  );
  @override
  late final GeneratedColumn<bool> freezeUsed = GeneratedColumn<bool>(
    'freeze_used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("freeze_used" IN (0, 1))',
    ),
  );
  static const VerificationMeta _anchorTypeMeta = const VerificationMeta(
    'anchorType',
  );
  @override
  late final GeneratedColumn<String> anchorType = GeneratedColumn<String>(
    'anchor_type',
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
  List<GeneratedColumn> get $columns => [
    id,
    date,
    counted,
    freezeUsed,
    anchorType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreakLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('counted')) {
      context.handle(
        _countedMeta,
        counted.isAcceptableOrUnknown(data['counted']!, _countedMeta),
      );
    } else if (isInserting) {
      context.missing(_countedMeta);
    }
    if (data.containsKey('freeze_used')) {
      context.handle(
        _freezeUsedMeta,
        freezeUsed.isAcceptableOrUnknown(data['freeze_used']!, _freezeUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_freezeUsedMeta);
    }
    if (data.containsKey('anchor_type')) {
      context.handle(
        _anchorTypeMeta,
        anchorType.isAcceptableOrUnknown(data['anchor_type']!, _anchorTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorTypeMeta);
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
  StreakLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      counted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counted'],
      )!,
      freezeUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}freeze_used'],
      )!,
      anchorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StreakLogTable createAlias(String alias) {
    return $StreakLogTable(attachedDatabase, alias);
  }
}

class StreakLogData extends DataClass implements Insertable<StreakLogData> {
  final String id;
  final String date;
  final bool counted;
  final bool freezeUsed;
  final String anchorType;
  final String createdAt;
  const StreakLogData({
    required this.id,
    required this.date,
    required this.counted,
    required this.freezeUsed,
    required this.anchorType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['counted'] = Variable<bool>(counted);
    map['freeze_used'] = Variable<bool>(freezeUsed);
    map['anchor_type'] = Variable<String>(anchorType);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  StreakLogCompanion toCompanion(bool nullToAbsent) {
    return StreakLogCompanion(
      id: Value(id),
      date: Value(date),
      counted: Value(counted),
      freezeUsed: Value(freezeUsed),
      anchorType: Value(anchorType),
      createdAt: Value(createdAt),
    );
  }

  factory StreakLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakLogData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      counted: serializer.fromJson<bool>(json['counted']),
      freezeUsed: serializer.fromJson<bool>(json['freezeUsed']),
      anchorType: serializer.fromJson<String>(json['anchorType']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'counted': serializer.toJson<bool>(counted),
      'freezeUsed': serializer.toJson<bool>(freezeUsed),
      'anchorType': serializer.toJson<String>(anchorType),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  StreakLogData copyWith({
    String? id,
    String? date,
    bool? counted,
    bool? freezeUsed,
    String? anchorType,
    String? createdAt,
  }) => StreakLogData(
    id: id ?? this.id,
    date: date ?? this.date,
    counted: counted ?? this.counted,
    freezeUsed: freezeUsed ?? this.freezeUsed,
    anchorType: anchorType ?? this.anchorType,
    createdAt: createdAt ?? this.createdAt,
  );
  StreakLogData copyWithCompanion(StreakLogCompanion data) {
    return StreakLogData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      counted: data.counted.present ? data.counted.value : this.counted,
      freezeUsed: data.freezeUsed.present
          ? data.freezeUsed.value
          : this.freezeUsed,
      anchorType: data.anchorType.present
          ? data.anchorType.value
          : this.anchorType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakLogData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('counted: $counted, ')
          ..write('freezeUsed: $freezeUsed, ')
          ..write('anchorType: $anchorType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, counted, freezeUsed, anchorType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakLogData &&
          other.id == this.id &&
          other.date == this.date &&
          other.counted == this.counted &&
          other.freezeUsed == this.freezeUsed &&
          other.anchorType == this.anchorType &&
          other.createdAt == this.createdAt);
}

class StreakLogCompanion extends UpdateCompanion<StreakLogData> {
  final Value<String> id;
  final Value<String> date;
  final Value<bool> counted;
  final Value<bool> freezeUsed;
  final Value<String> anchorType;
  final Value<String> createdAt;
  final Value<int> rowid;
  const StreakLogCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.counted = const Value.absent(),
    this.freezeUsed = const Value.absent(),
    this.anchorType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreakLogCompanion.insert({
    required String id,
    required String date,
    required bool counted,
    required bool freezeUsed,
    required String anchorType,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       counted = Value(counted),
       freezeUsed = Value(freezeUsed),
       anchorType = Value(anchorType),
       createdAt = Value(createdAt);
  static Insertable<StreakLogData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<bool>? counted,
    Expression<bool>? freezeUsed,
    Expression<String>? anchorType,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (counted != null) 'counted': counted,
      if (freezeUsed != null) 'freeze_used': freezeUsed,
      if (anchorType != null) 'anchor_type': anchorType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreakLogCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<bool>? counted,
    Value<bool>? freezeUsed,
    Value<String>? anchorType,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return StreakLogCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      counted: counted ?? this.counted,
      freezeUsed: freezeUsed ?? this.freezeUsed,
      anchorType: anchorType ?? this.anchorType,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (counted.present) {
      map['counted'] = Variable<bool>(counted.value);
    }
    if (freezeUsed.present) {
      map['freeze_used'] = Variable<bool>(freezeUsed.value);
    }
    if (anchorType.present) {
      map['anchor_type'] = Variable<String>(anchorType.value);
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
    return (StringBuffer('StreakLogCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('counted: $counted, ')
          ..write('freezeUsed: $freezeUsed, ')
          ..write('anchorType: $anchorType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakFrozenTable extends StreakFrozen
    with TableInfo<$StreakFrozenTable, StreakFrozenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakFrozenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestStreakMeta = const VerificationMeta(
    'bestStreak',
  );
  @override
  late final GeneratedColumn<int> bestStreak = GeneratedColumn<int>(
    'best_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAnchorDateMeta = const VerificationMeta(
    'lastAnchorDate',
  );
  @override
  late final GeneratedColumn<String> lastAnchorDate = GeneratedColumn<String>(
    'last_anchor_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brokenDateMeta = const VerificationMeta(
    'brokenDate',
  );
  @override
  late final GeneratedColumn<String> brokenDate = GeneratedColumn<String>(
    'broken_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freezesEarnedMeta = const VerificationMeta(
    'freezesEarned',
  );
  @override
  late final GeneratedColumn<int> freezesEarned = GeneratedColumn<int>(
    'freezes_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    count,
    bestStreak,
    lastAnchorDate,
    brokenDate,
    freezesEarned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_frozen';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreakFrozenData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('best_streak')) {
      context.handle(
        _bestStreakMeta,
        bestStreak.isAcceptableOrUnknown(data['best_streak']!, _bestStreakMeta),
      );
    } else if (isInserting) {
      context.missing(_bestStreakMeta);
    }
    if (data.containsKey('last_anchor_date')) {
      context.handle(
        _lastAnchorDateMeta,
        lastAnchorDate.isAcceptableOrUnknown(
          data['last_anchor_date']!,
          _lastAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('broken_date')) {
      context.handle(
        _brokenDateMeta,
        brokenDate.isAcceptableOrUnknown(data['broken_date']!, _brokenDateMeta),
      );
    }
    if (data.containsKey('freezes_earned')) {
      context.handle(
        _freezesEarnedMeta,
        freezesEarned.isAcceptableOrUnknown(
          data['freezes_earned']!,
          _freezesEarnedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_freezesEarnedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakFrozenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakFrozenData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      bestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_streak'],
      )!,
      lastAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_anchor_date'],
      ),
      brokenDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}broken_date'],
      ),
      freezesEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freezes_earned'],
      )!,
    );
  }

  @override
  $StreakFrozenTable createAlias(String alias) {
    return $StreakFrozenTable(attachedDatabase, alias);
  }
}

class StreakFrozenData extends DataClass
    implements Insertable<StreakFrozenData> {
  final String id;
  final int count;
  final int bestStreak;
  final String? lastAnchorDate;
  final String? brokenDate;
  final int freezesEarned;
  const StreakFrozenData({
    required this.id,
    required this.count,
    required this.bestStreak,
    this.lastAnchorDate,
    this.brokenDate,
    required this.freezesEarned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['count'] = Variable<int>(count);
    map['best_streak'] = Variable<int>(bestStreak);
    if (!nullToAbsent || lastAnchorDate != null) {
      map['last_anchor_date'] = Variable<String>(lastAnchorDate);
    }
    if (!nullToAbsent || brokenDate != null) {
      map['broken_date'] = Variable<String>(brokenDate);
    }
    map['freezes_earned'] = Variable<int>(freezesEarned);
    return map;
  }

  StreakFrozenCompanion toCompanion(bool nullToAbsent) {
    return StreakFrozenCompanion(
      id: Value(id),
      count: Value(count),
      bestStreak: Value(bestStreak),
      lastAnchorDate: lastAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAnchorDate),
      brokenDate: brokenDate == null && nullToAbsent
          ? const Value.absent()
          : Value(brokenDate),
      freezesEarned: Value(freezesEarned),
    );
  }

  factory StreakFrozenData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakFrozenData(
      id: serializer.fromJson<String>(json['id']),
      count: serializer.fromJson<int>(json['count']),
      bestStreak: serializer.fromJson<int>(json['bestStreak']),
      lastAnchorDate: serializer.fromJson<String?>(json['lastAnchorDate']),
      brokenDate: serializer.fromJson<String?>(json['brokenDate']),
      freezesEarned: serializer.fromJson<int>(json['freezesEarned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'count': serializer.toJson<int>(count),
      'bestStreak': serializer.toJson<int>(bestStreak),
      'lastAnchorDate': serializer.toJson<String?>(lastAnchorDate),
      'brokenDate': serializer.toJson<String?>(brokenDate),
      'freezesEarned': serializer.toJson<int>(freezesEarned),
    };
  }

  StreakFrozenData copyWith({
    String? id,
    int? count,
    int? bestStreak,
    Value<String?> lastAnchorDate = const Value.absent(),
    Value<String?> brokenDate = const Value.absent(),
    int? freezesEarned,
  }) => StreakFrozenData(
    id: id ?? this.id,
    count: count ?? this.count,
    bestStreak: bestStreak ?? this.bestStreak,
    lastAnchorDate: lastAnchorDate.present
        ? lastAnchorDate.value
        : this.lastAnchorDate,
    brokenDate: brokenDate.present ? brokenDate.value : this.brokenDate,
    freezesEarned: freezesEarned ?? this.freezesEarned,
  );
  StreakFrozenData copyWithCompanion(StreakFrozenCompanion data) {
    return StreakFrozenData(
      id: data.id.present ? data.id.value : this.id,
      count: data.count.present ? data.count.value : this.count,
      bestStreak: data.bestStreak.present
          ? data.bestStreak.value
          : this.bestStreak,
      lastAnchorDate: data.lastAnchorDate.present
          ? data.lastAnchorDate.value
          : this.lastAnchorDate,
      brokenDate: data.brokenDate.present
          ? data.brokenDate.value
          : this.brokenDate,
      freezesEarned: data.freezesEarned.present
          ? data.freezesEarned.value
          : this.freezesEarned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakFrozenData(')
          ..write('id: $id, ')
          ..write('count: $count, ')
          ..write('bestStreak: $bestStreak, ')
          ..write('lastAnchorDate: $lastAnchorDate, ')
          ..write('brokenDate: $brokenDate, ')
          ..write('freezesEarned: $freezesEarned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    count,
    bestStreak,
    lastAnchorDate,
    brokenDate,
    freezesEarned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakFrozenData &&
          other.id == this.id &&
          other.count == this.count &&
          other.bestStreak == this.bestStreak &&
          other.lastAnchorDate == this.lastAnchorDate &&
          other.brokenDate == this.brokenDate &&
          other.freezesEarned == this.freezesEarned);
}

class StreakFrozenCompanion extends UpdateCompanion<StreakFrozenData> {
  final Value<String> id;
  final Value<int> count;
  final Value<int> bestStreak;
  final Value<String?> lastAnchorDate;
  final Value<String?> brokenDate;
  final Value<int> freezesEarned;
  final Value<int> rowid;
  const StreakFrozenCompanion({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
    this.bestStreak = const Value.absent(),
    this.lastAnchorDate = const Value.absent(),
    this.brokenDate = const Value.absent(),
    this.freezesEarned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreakFrozenCompanion.insert({
    required String id,
    required int count,
    required int bestStreak,
    this.lastAnchorDate = const Value.absent(),
    this.brokenDate = const Value.absent(),
    required int freezesEarned,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       count = Value(count),
       bestStreak = Value(bestStreak),
       freezesEarned = Value(freezesEarned);
  static Insertable<StreakFrozenData> custom({
    Expression<String>? id,
    Expression<int>? count,
    Expression<int>? bestStreak,
    Expression<String>? lastAnchorDate,
    Expression<String>? brokenDate,
    Expression<int>? freezesEarned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (count != null) 'count': count,
      if (bestStreak != null) 'best_streak': bestStreak,
      if (lastAnchorDate != null) 'last_anchor_date': lastAnchorDate,
      if (brokenDate != null) 'broken_date': brokenDate,
      if (freezesEarned != null) 'freezes_earned': freezesEarned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreakFrozenCompanion copyWith({
    Value<String>? id,
    Value<int>? count,
    Value<int>? bestStreak,
    Value<String?>? lastAnchorDate,
    Value<String?>? brokenDate,
    Value<int>? freezesEarned,
    Value<int>? rowid,
  }) {
    return StreakFrozenCompanion(
      id: id ?? this.id,
      count: count ?? this.count,
      bestStreak: bestStreak ?? this.bestStreak,
      lastAnchorDate: lastAnchorDate ?? this.lastAnchorDate,
      brokenDate: brokenDate ?? this.brokenDate,
      freezesEarned: freezesEarned ?? this.freezesEarned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (bestStreak.present) {
      map['best_streak'] = Variable<int>(bestStreak.value);
    }
    if (lastAnchorDate.present) {
      map['last_anchor_date'] = Variable<String>(lastAnchorDate.value);
    }
    if (brokenDate.present) {
      map['broken_date'] = Variable<String>(brokenDate.value);
    }
    if (freezesEarned.present) {
      map['freezes_earned'] = Variable<int>(freezesEarned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakFrozenCompanion(')
          ..write('id: $id, ')
          ..write('count: $count, ')
          ..write('bestStreak: $bestStreak, ')
          ..write('lastAnchorDate: $lastAnchorDate, ')
          ..write('brokenDate: $brokenDate, ')
          ..write('freezesEarned: $freezesEarned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SoulLogTable extends SoulLog with TableInfo<$SoulLogTable, SoulLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoulLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [id, date, mood, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soul_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SoulLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
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
  SoulLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoulLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SoulLogTable createAlias(String alias) {
    return $SoulLogTable(attachedDatabase, alias);
  }
}

class SoulLogData extends DataClass implements Insertable<SoulLogData> {
  final String id;
  final String date;
  final int mood;
  final String? note;
  final String createdAt;
  const SoulLogData({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['mood'] = Variable<int>(mood);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SoulLogCompanion toCompanion(bool nullToAbsent) {
    return SoulLogCompanion(
      id: Value(id),
      date: Value(date),
      mood: Value(mood),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory SoulLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoulLogData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      mood: serializer.fromJson<int>(json['mood']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'mood': serializer.toJson<int>(mood),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SoulLogData copyWith({
    String? id,
    String? date,
    int? mood,
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => SoulLogData(
    id: id ?? this.id,
    date: date ?? this.date,
    mood: mood ?? this.mood,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  SoulLogData copyWithCompanion(SoulLogCompanion data) {
    return SoulLogData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mood: data.mood.present ? data.mood.value : this.mood,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoulLogData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, mood, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoulLogData &&
          other.id == this.id &&
          other.date == this.date &&
          other.mood == this.mood &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class SoulLogCompanion extends UpdateCompanion<SoulLogData> {
  final Value<String> id;
  final Value<String> date;
  final Value<int> mood;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SoulLogCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoulLogCompanion.insert({
    required String id,
    required String date,
    required int mood,
    this.note = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       mood = Value(mood),
       createdAt = Value(createdAt);
  static Insertable<SoulLogData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<int>? mood,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mood != null) 'mood': mood,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoulLogCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<int>? mood,
    Value<String?>? note,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return SoulLogCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
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
    return (StringBuffer('SoulLogCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BibleSessionsTable extends BibleSessions
    with TableInfo<$BibleSessionsTable, BibleSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BibleSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
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
  static const VerificationMeta _chapterStartMeta = const VerificationMeta(
    'chapterStart',
  );
  @override
  late final GeneratedColumn<int> chapterStart = GeneratedColumn<int>(
    'chapter_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterEndMeta = const VerificationMeta(
    'chapterEnd',
  );
  @override
  late final GeneratedColumn<int> chapterEnd = GeneratedColumn<int>(
    'chapter_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reflectionMeta = const VerificationMeta(
    'reflection',
  );
  @override
  late final GeneratedColumn<String> reflection = GeneratedColumn<String>(
    'reflection',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPlanReadingMeta = const VerificationMeta(
    'isPlanReading',
  );
  @override
  late final GeneratedColumn<bool> isPlanReading = GeneratedColumn<bool>(
    'is_plan_reading',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_plan_reading" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _planDayMeta = const VerificationMeta(
    'planDay',
  );
  @override
  late final GeneratedColumn<String> planDay = GeneratedColumn<String>(
    'plan_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [
    id,
    date,
    bookId,
    chapterStart,
    chapterEnd,
    durationMinutes,
    reflection,
    isPlanReading,
    planDay,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BibleSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_start')) {
      context.handle(
        _chapterStartMeta,
        chapterStart.isAcceptableOrUnknown(
          data['chapter_start']!,
          _chapterStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterStartMeta);
    }
    if (data.containsKey('chapter_end')) {
      context.handle(
        _chapterEndMeta,
        chapterEnd.isAcceptableOrUnknown(data['chapter_end']!, _chapterEndMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterEndMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('reflection')) {
      context.handle(
        _reflectionMeta,
        reflection.isAcceptableOrUnknown(data['reflection']!, _reflectionMeta),
      );
    }
    if (data.containsKey('is_plan_reading')) {
      context.handle(
        _isPlanReadingMeta,
        isPlanReading.isAcceptableOrUnknown(
          data['is_plan_reading']!,
          _isPlanReadingMeta,
        ),
      );
    }
    if (data.containsKey('plan_day')) {
      context.handle(
        _planDayMeta,
        planDay.isAcceptableOrUnknown(data['plan_day']!, _planDayMeta),
      );
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
  BibleSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BibleSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_start'],
      )!,
      chapterEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_end'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      reflection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection'],
      ),
      isPlanReading: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_plan_reading'],
      )!,
      planDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_day'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BibleSessionsTable createAlias(String alias) {
    return $BibleSessionsTable(attachedDatabase, alias);
  }
}

class BibleSession extends DataClass implements Insertable<BibleSession> {
  final String id;
  final String date;
  final String bookId;
  final int chapterStart;
  final int chapterEnd;
  final int durationMinutes;
  final String? reflection;
  final bool isPlanReading;
  final String? planDay;
  final String createdAt;
  const BibleSession({
    required this.id,
    required this.date,
    required this.bookId,
    required this.chapterStart,
    required this.chapterEnd,
    required this.durationMinutes,
    this.reflection,
    required this.isPlanReading,
    this.planDay,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['book_id'] = Variable<String>(bookId);
    map['chapter_start'] = Variable<int>(chapterStart);
    map['chapter_end'] = Variable<int>(chapterEnd);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    if (!nullToAbsent || reflection != null) {
      map['reflection'] = Variable<String>(reflection);
    }
    map['is_plan_reading'] = Variable<bool>(isPlanReading);
    if (!nullToAbsent || planDay != null) {
      map['plan_day'] = Variable<String>(planDay);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BibleSessionsCompanion toCompanion(bool nullToAbsent) {
    return BibleSessionsCompanion(
      id: Value(id),
      date: Value(date),
      bookId: Value(bookId),
      chapterStart: Value(chapterStart),
      chapterEnd: Value(chapterEnd),
      durationMinutes: Value(durationMinutes),
      reflection: reflection == null && nullToAbsent
          ? const Value.absent()
          : Value(reflection),
      isPlanReading: Value(isPlanReading),
      planDay: planDay == null && nullToAbsent
          ? const Value.absent()
          : Value(planDay),
      createdAt: Value(createdAt),
    );
  }

  factory BibleSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BibleSession(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterStart: serializer.fromJson<int>(json['chapterStart']),
      chapterEnd: serializer.fromJson<int>(json['chapterEnd']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      reflection: serializer.fromJson<String?>(json['reflection']),
      isPlanReading: serializer.fromJson<bool>(json['isPlanReading']),
      planDay: serializer.fromJson<String?>(json['planDay']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'bookId': serializer.toJson<String>(bookId),
      'chapterStart': serializer.toJson<int>(chapterStart),
      'chapterEnd': serializer.toJson<int>(chapterEnd),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'reflection': serializer.toJson<String?>(reflection),
      'isPlanReading': serializer.toJson<bool>(isPlanReading),
      'planDay': serializer.toJson<String?>(planDay),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  BibleSession copyWith({
    String? id,
    String? date,
    String? bookId,
    int? chapterStart,
    int? chapterEnd,
    int? durationMinutes,
    Value<String?> reflection = const Value.absent(),
    bool? isPlanReading,
    Value<String?> planDay = const Value.absent(),
    String? createdAt,
  }) => BibleSession(
    id: id ?? this.id,
    date: date ?? this.date,
    bookId: bookId ?? this.bookId,
    chapterStart: chapterStart ?? this.chapterStart,
    chapterEnd: chapterEnd ?? this.chapterEnd,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    reflection: reflection.present ? reflection.value : this.reflection,
    isPlanReading: isPlanReading ?? this.isPlanReading,
    planDay: planDay.present ? planDay.value : this.planDay,
    createdAt: createdAt ?? this.createdAt,
  );
  BibleSession copyWithCompanion(BibleSessionsCompanion data) {
    return BibleSession(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterStart: data.chapterStart.present
          ? data.chapterStart.value
          : this.chapterStart,
      chapterEnd: data.chapterEnd.present
          ? data.chapterEnd.value
          : this.chapterEnd,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      reflection: data.reflection.present
          ? data.reflection.value
          : this.reflection,
      isPlanReading: data.isPlanReading.present
          ? data.isPlanReading.value
          : this.isPlanReading,
      planDay: data.planDay.present ? data.planDay.value : this.planDay,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BibleSession(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('bookId: $bookId, ')
          ..write('chapterStart: $chapterStart, ')
          ..write('chapterEnd: $chapterEnd, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('reflection: $reflection, ')
          ..write('isPlanReading: $isPlanReading, ')
          ..write('planDay: $planDay, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    bookId,
    chapterStart,
    chapterEnd,
    durationMinutes,
    reflection,
    isPlanReading,
    planDay,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BibleSession &&
          other.id == this.id &&
          other.date == this.date &&
          other.bookId == this.bookId &&
          other.chapterStart == this.chapterStart &&
          other.chapterEnd == this.chapterEnd &&
          other.durationMinutes == this.durationMinutes &&
          other.reflection == this.reflection &&
          other.isPlanReading == this.isPlanReading &&
          other.planDay == this.planDay &&
          other.createdAt == this.createdAt);
}

class BibleSessionsCompanion extends UpdateCompanion<BibleSession> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> bookId;
  final Value<int> chapterStart;
  final Value<int> chapterEnd;
  final Value<int> durationMinutes;
  final Value<String?> reflection;
  final Value<bool> isPlanReading;
  final Value<String?> planDay;
  final Value<String> createdAt;
  final Value<int> rowid;
  const BibleSessionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterStart = const Value.absent(),
    this.chapterEnd = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.reflection = const Value.absent(),
    this.isPlanReading = const Value.absent(),
    this.planDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BibleSessionsCompanion.insert({
    required String id,
    required String date,
    required String bookId,
    required int chapterStart,
    required int chapterEnd,
    this.durationMinutes = const Value.absent(),
    this.reflection = const Value.absent(),
    this.isPlanReading = const Value.absent(),
    this.planDay = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       bookId = Value(bookId),
       chapterStart = Value(chapterStart),
       chapterEnd = Value(chapterEnd),
       createdAt = Value(createdAt);
  static Insertable<BibleSession> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? bookId,
    Expression<int>? chapterStart,
    Expression<int>? chapterEnd,
    Expression<int>? durationMinutes,
    Expression<String>? reflection,
    Expression<bool>? isPlanReading,
    Expression<String>? planDay,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (bookId != null) 'book_id': bookId,
      if (chapterStart != null) 'chapter_start': chapterStart,
      if (chapterEnd != null) 'chapter_end': chapterEnd,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (reflection != null) 'reflection': reflection,
      if (isPlanReading != null) 'is_plan_reading': isPlanReading,
      if (planDay != null) 'plan_day': planDay,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BibleSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? bookId,
    Value<int>? chapterStart,
    Value<int>? chapterEnd,
    Value<int>? durationMinutes,
    Value<String?>? reflection,
    Value<bool>? isPlanReading,
    Value<String?>? planDay,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return BibleSessionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      bookId: bookId ?? this.bookId,
      chapterStart: chapterStart ?? this.chapterStart,
      chapterEnd: chapterEnd ?? this.chapterEnd,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reflection: reflection ?? this.reflection,
      isPlanReading: isPlanReading ?? this.isPlanReading,
      planDay: planDay ?? this.planDay,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterStart.present) {
      map['chapter_start'] = Variable<int>(chapterStart.value);
    }
    if (chapterEnd.present) {
      map['chapter_end'] = Variable<int>(chapterEnd.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (reflection.present) {
      map['reflection'] = Variable<String>(reflection.value);
    }
    if (isPlanReading.present) {
      map['is_plan_reading'] = Variable<bool>(isPlanReading.value);
    }
    if (planDay.present) {
      map['plan_day'] = Variable<String>(planDay.value);
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
    return (StringBuffer('BibleSessionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('bookId: $bookId, ')
          ..write('chapterStart: $chapterStart, ')
          ..write('chapterEnd: $chapterEnd, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('reflection: $reflection, ')
          ..write('isPlanReading: $isPlanReading, ')
          ..write('planDay: $planDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingLoopsTable extends ReadingLoops
    with TableInfo<$ReadingLoopsTable, ReadingLoop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingLoopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startChapterMeta = const VerificationMeta(
    'startChapter',
  );
  @override
  late final GeneratedColumn<int> startChapter = GeneratedColumn<int>(
    'start_chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
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
  static const VerificationMeta _loopNumberMeta = const VerificationMeta(
    'loopNumber',
  );
  @override
  late final GeneratedColumn<int> loopNumber = GeneratedColumn<int>(
    'loop_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    duration,
    startChapter,
    startDate,
    status,
    loopNumber,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_loops';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingLoop> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('start_chapter')) {
      context.handle(
        _startChapterMeta,
        startChapter.isAcceptableOrUnknown(
          data['start_chapter']!,
          _startChapterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startChapterMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('loop_number')) {
      context.handle(
        _loopNumberMeta,
        loopNumber.isAcceptableOrUnknown(data['loop_number']!, _loopNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_loopNumberMeta);
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
  ReadingLoop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingLoop(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      startChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_chapter'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      loopNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loop_number'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingLoopsTable createAlias(String alias) {
    return $ReadingLoopsTable(attachedDatabase, alias);
  }
}

class ReadingLoop extends DataClass implements Insertable<ReadingLoop> {
  final String id;
  final String planId;
  final int duration;
  final int startChapter;
  final String startDate;
  final String status;
  final int loopNumber;
  final String createdAt;
  const ReadingLoop({
    required this.id,
    required this.planId,
    required this.duration,
    required this.startChapter,
    required this.startDate,
    required this.status,
    required this.loopNumber,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['duration'] = Variable<int>(duration);
    map['start_chapter'] = Variable<int>(startChapter);
    map['start_date'] = Variable<String>(startDate);
    map['status'] = Variable<String>(status);
    map['loop_number'] = Variable<int>(loopNumber);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ReadingLoopsCompanion toCompanion(bool nullToAbsent) {
    return ReadingLoopsCompanion(
      id: Value(id),
      planId: Value(planId),
      duration: Value(duration),
      startChapter: Value(startChapter),
      startDate: Value(startDate),
      status: Value(status),
      loopNumber: Value(loopNumber),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingLoop.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingLoop(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      duration: serializer.fromJson<int>(json['duration']),
      startChapter: serializer.fromJson<int>(json['startChapter']),
      startDate: serializer.fromJson<String>(json['startDate']),
      status: serializer.fromJson<String>(json['status']),
      loopNumber: serializer.fromJson<int>(json['loopNumber']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'duration': serializer.toJson<int>(duration),
      'startChapter': serializer.toJson<int>(startChapter),
      'startDate': serializer.toJson<String>(startDate),
      'status': serializer.toJson<String>(status),
      'loopNumber': serializer.toJson<int>(loopNumber),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ReadingLoop copyWith({
    String? id,
    String? planId,
    int? duration,
    int? startChapter,
    String? startDate,
    String? status,
    int? loopNumber,
    String? createdAt,
  }) => ReadingLoop(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    duration: duration ?? this.duration,
    startChapter: startChapter ?? this.startChapter,
    startDate: startDate ?? this.startDate,
    status: status ?? this.status,
    loopNumber: loopNumber ?? this.loopNumber,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingLoop copyWithCompanion(ReadingLoopsCompanion data) {
    return ReadingLoop(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      duration: data.duration.present ? data.duration.value : this.duration,
      startChapter: data.startChapter.present
          ? data.startChapter.value
          : this.startChapter,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      status: data.status.present ? data.status.value : this.status,
      loopNumber: data.loopNumber.present
          ? data.loopNumber.value
          : this.loopNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingLoop(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('duration: $duration, ')
          ..write('startChapter: $startChapter, ')
          ..write('startDate: $startDate, ')
          ..write('status: $status, ')
          ..write('loopNumber: $loopNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    duration,
    startChapter,
    startDate,
    status,
    loopNumber,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingLoop &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.duration == this.duration &&
          other.startChapter == this.startChapter &&
          other.startDate == this.startDate &&
          other.status == this.status &&
          other.loopNumber == this.loopNumber &&
          other.createdAt == this.createdAt);
}

class ReadingLoopsCompanion extends UpdateCompanion<ReadingLoop> {
  final Value<String> id;
  final Value<String> planId;
  final Value<int> duration;
  final Value<int> startChapter;
  final Value<String> startDate;
  final Value<String> status;
  final Value<int> loopNumber;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ReadingLoopsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.duration = const Value.absent(),
    this.startChapter = const Value.absent(),
    this.startDate = const Value.absent(),
    this.status = const Value.absent(),
    this.loopNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingLoopsCompanion.insert({
    required String id,
    required String planId,
    required int duration,
    required int startChapter,
    required String startDate,
    required String status,
    required int loopNumber,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       duration = Value(duration),
       startChapter = Value(startChapter),
       startDate = Value(startDate),
       status = Value(status),
       loopNumber = Value(loopNumber),
       createdAt = Value(createdAt);
  static Insertable<ReadingLoop> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? duration,
    Expression<int>? startChapter,
    Expression<String>? startDate,
    Expression<String>? status,
    Expression<int>? loopNumber,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (duration != null) 'duration': duration,
      if (startChapter != null) 'start_chapter': startChapter,
      if (startDate != null) 'start_date': startDate,
      if (status != null) 'status': status,
      if (loopNumber != null) 'loop_number': loopNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingLoopsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<int>? duration,
    Value<int>? startChapter,
    Value<String>? startDate,
    Value<String>? status,
    Value<int>? loopNumber,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ReadingLoopsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      duration: duration ?? this.duration,
      startChapter: startChapter ?? this.startChapter,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      loopNumber: loopNumber ?? this.loopNumber,
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
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (startChapter.present) {
      map['start_chapter'] = Variable<int>(startChapter.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (loopNumber.present) {
      map['loop_number'] = Variable<int>(loopNumber.value);
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
    return (StringBuffer('ReadingLoopsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('duration: $duration, ')
          ..write('startChapter: $startChapter, ')
          ..write('startDate: $startDate, ')
          ..write('status: $status, ')
          ..write('loopNumber: $loopNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $PrayerLogsTable prayerLogs = $PrayerLogsTable(this);
  late final $BibleReadsTable bibleReads = $BibleReadsTable(this);
  late final $SkillsTable skills = $SkillsTable(this);
  late final $SkillSessionsTable skillSessions = $SkillSessionsTable(this);
  late final $ReflectionsTable reflections = $ReflectionsTable(this);
  late final $ChallengesTable challenges = $ChallengesTable(this);
  late final $ChallengeParticipantsTable challengeParticipants =
      $ChallengeParticipantsTable(this);
  late final $FellowshipLogsTable fellowshipLogs = $FellowshipLogsTable(this);
  late final $FamilyTimeLogsTable familyTimeLogs = $FamilyTimeLogsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $TodoItemsTable todoItems = $TodoItemsTable(this);
  late final $DailyReflectionsTable dailyReflections = $DailyReflectionsTable(
    this,
  );
  late final $StreakLogTable streakLog = $StreakLogTable(this);
  late final $StreakFrozenTable streakFrozen = $StreakFrozenTable(this);
  late final $SoulLogTable soulLog = $SoulLogTable(this);
  late final $BibleSessionsTable bibleSessions = $BibleSessionsTable(this);
  late final $ReadingLoopsTable readingLoops = $ReadingLoopsTable(this);
  late final $WisdomNotesTable wisdomNotes = $WisdomNotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    habits,
    completions,
    prayerLogs,
    bibleReads,
    skills,
    skillSessions,
    reflections,
    challenges,
    challengeParticipants,
    fellowshipLogs,
    familyTimeLogs,
    goals,
    todoItems,
    dailyReflections,
    streakLog,
    streakFrozen,
    soulLog,
    bibleSessions,
    readingLoops,
    wisdomNotes,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> goals,
      Value<bool> onboarded,
      Value<String> lang,
      Value<String> biblePlan,
      required String createdAt,
      Value<int> sabbathDay,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> goals,
      Value<bool> onboarded,
      Value<String> lang,
      Value<String> biblePlan,
      Value<String> createdAt,
      Value<int> sabbathDay,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboarded => $composableBuilder(
    column: $table.onboarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biblePlan => $composableBuilder(
    column: $table.biblePlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sabbathDay => $composableBuilder(
    column: $table.sabbathDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboarded => $composableBuilder(
    column: $table.onboarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biblePlan => $composableBuilder(
    column: $table.biblePlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sabbathDay => $composableBuilder(
    column: $table.sabbathDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get goals =>
      $composableBuilder(column: $table.goals, builder: (column) => column);

  GeneratedColumn<bool> get onboarded =>
      $composableBuilder(column: $table.onboarded, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get biblePlan =>
      $composableBuilder(column: $table.biblePlan, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sabbathDay => $composableBuilder(
    column: $table.sabbathDay,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> goals = const Value.absent(),
                Value<bool> onboarded = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> biblePlan = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> sabbathDay = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                goals: goals,
                onboarded: onboarded,
                lang: lang,
                biblePlan: biblePlan,
                createdAt: createdAt,
                sabbathDay: sabbathDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> goals = const Value.absent(),
                Value<bool> onboarded = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> biblePlan = const Value.absent(),
                required String createdAt,
                Value<int> sabbathDay = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                goals: goals,
                onboarded: onboarded,
                lang: lang,
                biblePlan: biblePlan,
                createdAt: createdAt,
                sabbathDay: sabbathDay,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      required String id,
      required String name,
      required String category,
      required String frequency,
      required String icon,
      Value<int> targetCount,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<String> frequency,
      Value<String> icon,
      Value<int> targetCount,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CompletionsTable, List<Completion>>
  _completionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completions,
    aliasName: $_aliasNameGenerator(db.habits.id, db.completions.habitId),
  );

  $$CompletionsTableProcessedTableManager get completionsRefs {
    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_completionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> completionsRefs(
    Expression<bool> Function($$CompletionsTableFilterComposer f) f,
  ) {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> completionsRefs<T extends Object>(
    Expression<T> Function($$CompletionsTableAnnotationComposer a) f,
  ) {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({bool completionsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> targetCount = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                category: category,
                frequency: frequency,
                icon: icon,
                targetCount: targetCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required String frequency,
                required String icon,
                Value<int> targetCount = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                category: category,
                frequency: frequency,
                icon: icon,
                targetCount: targetCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HabitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({completionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (completionsRefs) db.completions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (completionsRefs)
                    await $_getPrefetchedData<Habit, $HabitsTable, Completion>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._completionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(
                        db,
                        table,
                        p0,
                      ).completionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool completionsRefs})
    >;
typedef $$CompletionsTableCreateCompanionBuilder =
    CompletionsCompanion Function({
      Value<int> id,
      required String habitId,
      required String date,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<int> id,
      Value<String> habitId,
      Value<String> date,
    });

final class $$CompletionsTableReferences
    extends BaseReferences<_$AppDatabase, $CompletionsTable, Completion> {
  $$CompletionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.completions.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletionsTable,
          Completion,
          $$CompletionsTableFilterComposer,
          $$CompletionsTableOrderingComposer,
          $$CompletionsTableAnnotationComposer,
          $$CompletionsTableCreateCompanionBuilder,
          $$CompletionsTableUpdateCompanionBuilder,
          (Completion, $$CompletionsTableReferences),
          Completion,
          PrefetchHooks Function({bool habitId})
        > {
  $$CompletionsTableTableManager(_$AppDatabase db, $CompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
              }) => CompletionsCompanion(id: id, habitId: habitId, date: date),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String habitId,
                required String date,
              }) => CompletionsCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
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
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$CompletionsTableReferences
                                    ._habitIdTable(db),
                                referencedColumn: $$CompletionsTableReferences
                                    ._habitIdTable(db)
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

typedef $$CompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletionsTable,
      Completion,
      $$CompletionsTableFilterComposer,
      $$CompletionsTableOrderingComposer,
      $$CompletionsTableAnnotationComposer,
      $$CompletionsTableCreateCompanionBuilder,
      $$CompletionsTableUpdateCompanionBuilder,
      (Completion, $$CompletionsTableReferences),
      Completion,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$PrayerLogsTableCreateCompanionBuilder =
    PrayerLogsCompanion Function({
      required String id,
      required String date,
      required int minutes,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$PrayerLogsTableUpdateCompanionBuilder =
    PrayerLogsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<int> minutes,
      Value<String?> note,
      Value<int> rowid,
    });

class $$PrayerLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerLogsTable> {
  $$PrayerLogsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerLogsTable> {
  $$PrayerLogsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerLogsTable> {
  $$PrayerLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$PrayerLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerLogsTable,
          PrayerLog,
          $$PrayerLogsTableFilterComposer,
          $$PrayerLogsTableOrderingComposer,
          $$PrayerLogsTableAnnotationComposer,
          $$PrayerLogsTableCreateCompanionBuilder,
          $$PrayerLogsTableUpdateCompanionBuilder,
          (
            PrayerLog,
            BaseReferences<_$AppDatabase, $PrayerLogsTable, PrayerLog>,
          ),
          PrayerLog,
          PrefetchHooks Function()
        > {
  $$PrayerLogsTableTableManager(_$AppDatabase db, $PrayerLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerLogsCompanion(
                id: id,
                date: date,
                minutes: minutes,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required int minutes,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerLogsCompanion.insert(
                id: id,
                date: date,
                minutes: minutes,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerLogsTable,
      PrayerLog,
      $$PrayerLogsTableFilterComposer,
      $$PrayerLogsTableOrderingComposer,
      $$PrayerLogsTableAnnotationComposer,
      $$PrayerLogsTableCreateCompanionBuilder,
      $$PrayerLogsTableUpdateCompanionBuilder,
      (PrayerLog, BaseReferences<_$AppDatabase, $PrayerLogsTable, PrayerLog>),
      PrayerLog,
      PrefetchHooks Function()
    >;
typedef $$BibleReadsTableCreateCompanionBuilder =
    BibleReadsCompanion Function({
      Value<int> id,
      required String date,
      required String reference,
      Value<String?> note,
      Value<int> durationMinutes,
    });
typedef $$BibleReadsTableUpdateCompanionBuilder =
    BibleReadsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> reference,
      Value<String?> note,
      Value<int> durationMinutes,
    });

class $$BibleReadsTableFilterComposer
    extends Composer<_$AppDatabase, $BibleReadsTable> {
  $$BibleReadsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BibleReadsTableOrderingComposer
    extends Composer<_$AppDatabase, $BibleReadsTable> {
  $$BibleReadsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BibleReadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BibleReadsTable> {
  $$BibleReadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );
}

class $$BibleReadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BibleReadsTable,
          BibleRead,
          $$BibleReadsTableFilterComposer,
          $$BibleReadsTableOrderingComposer,
          $$BibleReadsTableAnnotationComposer,
          $$BibleReadsTableCreateCompanionBuilder,
          $$BibleReadsTableUpdateCompanionBuilder,
          (
            BibleRead,
            BaseReferences<_$AppDatabase, $BibleReadsTable, BibleRead>,
          ),
          BibleRead,
          PrefetchHooks Function()
        > {
  $$BibleReadsTableTableManager(_$AppDatabase db, $BibleReadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BibleReadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BibleReadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BibleReadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
              }) => BibleReadsCompanion(
                id: id,
                date: date,
                reference: reference,
                note: note,
                durationMinutes: durationMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String reference,
                Value<String?> note = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
              }) => BibleReadsCompanion.insert(
                id: id,
                date: date,
                reference: reference,
                note: note,
                durationMinutes: durationMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BibleReadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BibleReadsTable,
      BibleRead,
      $$BibleReadsTableFilterComposer,
      $$BibleReadsTableOrderingComposer,
      $$BibleReadsTableAnnotationComposer,
      $$BibleReadsTableCreateCompanionBuilder,
      $$BibleReadsTableUpdateCompanionBuilder,
      (BibleRead, BaseReferences<_$AppDatabase, $BibleReadsTable, BibleRead>),
      BibleRead,
      PrefetchHooks Function()
    >;
typedef $$SkillsTableCreateCompanionBuilder =
    SkillsCompanion Function({
      required String id,
      required String name,
      required String category,
      required String icon,
      Value<int> targetMinutes,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$SkillsTableUpdateCompanionBuilder =
    SkillsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<String> icon,
      Value<int> targetMinutes,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$SkillsTableReferences
    extends BaseReferences<_$AppDatabase, $SkillsTable, Skill> {
  $$SkillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SkillSessionsTable, List<SkillSession>>
  _skillSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.skillSessions,
    aliasName: $_aliasNameGenerator(db.skills.id, db.skillSessions.skillId),
  );

  $$SkillSessionsTableProcessedTableManager get skillSessionsRefs {
    final manager = $$SkillSessionsTableTableManager(
      $_db,
      $_db.skillSessions,
    ).filter((f) => f.skillId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_skillSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SkillsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> skillSessionsRefs(
    Expression<bool> Function($$SkillSessionsTableFilterComposer f) f,
  ) {
    final $$SkillSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skillSessions,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillSessionsTableFilterComposer(
            $db: $db,
            $table: $db.skillSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SkillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> skillSessionsRefs<T extends Object>(
    Expression<T> Function($$SkillSessionsTableAnnotationComposer a) f,
  ) {
    final $$SkillSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skillSessions,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.skillSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillsTable,
          Skill,
          $$SkillsTableFilterComposer,
          $$SkillsTableOrderingComposer,
          $$SkillsTableAnnotationComposer,
          $$SkillsTableCreateCompanionBuilder,
          $$SkillsTableUpdateCompanionBuilder,
          (Skill, $$SkillsTableReferences),
          Skill,
          PrefetchHooks Function({bool skillSessionsRefs})
        > {
  $$SkillsTableTableManager(_$AppDatabase db, $SkillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> targetMinutes = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion(
                id: id,
                name: name,
                category: category,
                icon: icon,
                targetMinutes: targetMinutes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required String icon,
                Value<int> targetMinutes = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion.insert(
                id: id,
                name: name,
                category: category,
                icon: icon,
                targetMinutes: targetMinutes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SkillsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({skillSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (skillSessionsRefs) db.skillSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (skillSessionsRefs)
                    await $_getPrefetchedData<
                      Skill,
                      $SkillsTable,
                      SkillSession
                    >(
                      currentTable: table,
                      referencedTable: $$SkillsTableReferences
                          ._skillSessionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SkillsTableReferences(
                        db,
                        table,
                        p0,
                      ).skillSessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.skillId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SkillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillsTable,
      Skill,
      $$SkillsTableFilterComposer,
      $$SkillsTableOrderingComposer,
      $$SkillsTableAnnotationComposer,
      $$SkillsTableCreateCompanionBuilder,
      $$SkillsTableUpdateCompanionBuilder,
      (Skill, $$SkillsTableReferences),
      Skill,
      PrefetchHooks Function({bool skillSessionsRefs})
    >;
typedef $$SkillSessionsTableCreateCompanionBuilder =
    SkillSessionsCompanion Function({
      Value<int> id,
      required String skillId,
      required String date,
      required int minutes,
      Value<String?> note,
    });
typedef $$SkillSessionsTableUpdateCompanionBuilder =
    SkillSessionsCompanion Function({
      Value<int> id,
      Value<String> skillId,
      Value<String> date,
      Value<int> minutes,
      Value<String?> note,
    });

final class $$SkillSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SkillSessionsTable, SkillSession> {
  $$SkillSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SkillsTable _skillIdTable(_$AppDatabase db) => db.skills.createAlias(
    $_aliasNameGenerator(db.skillSessions.skillId, db.skills.id),
  );

  $$SkillsTableProcessedTableManager get skillId {
    final $_column = $_itemColumn<String>('skill_id')!;

    final manager = $$SkillsTableTableManager(
      $_db,
      $_db.skills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_skillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SkillSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillSessionsTable> {
  $$SkillSessionsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$SkillsTableFilterComposer get skillId {
    final $$SkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableFilterComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillSessionsTable> {
  $$SkillSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$SkillsTableOrderingComposer get skillId {
    final $$SkillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableOrderingComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillSessionsTable> {
  $$SkillSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SkillsTableAnnotationComposer get skillId {
    final $$SkillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableAnnotationComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillSessionsTable,
          SkillSession,
          $$SkillSessionsTableFilterComposer,
          $$SkillSessionsTableOrderingComposer,
          $$SkillSessionsTableAnnotationComposer,
          $$SkillSessionsTableCreateCompanionBuilder,
          $$SkillSessionsTableUpdateCompanionBuilder,
          (SkillSession, $$SkillSessionsTableReferences),
          SkillSession,
          PrefetchHooks Function({bool skillId})
        > {
  $$SkillSessionsTableTableManager(_$AppDatabase db, $SkillSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => SkillSessionsCompanion(
                id: id,
                skillId: skillId,
                date: date,
                minutes: minutes,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String skillId,
                required String date,
                required int minutes,
                Value<String?> note = const Value.absent(),
              }) => SkillSessionsCompanion.insert(
                id: id,
                skillId: skillId,
                date: date,
                minutes: minutes,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SkillSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({skillId = false}) {
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
                    if (skillId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.skillId,
                                referencedTable: $$SkillSessionsTableReferences
                                    ._skillIdTable(db),
                                referencedColumn: $$SkillSessionsTableReferences
                                    ._skillIdTable(db)
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

typedef $$SkillSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillSessionsTable,
      SkillSession,
      $$SkillSessionsTableFilterComposer,
      $$SkillSessionsTableOrderingComposer,
      $$SkillSessionsTableAnnotationComposer,
      $$SkillSessionsTableCreateCompanionBuilder,
      $$SkillSessionsTableUpdateCompanionBuilder,
      (SkillSession, $$SkillSessionsTableReferences),
      SkillSession,
      PrefetchHooks Function({bool skillId})
    >;
typedef $$ReflectionsTableCreateCompanionBuilder =
    ReflectionsCompanion Function({
      required String id,
      required String weekStart,
      Value<String?> grew,
      Value<String?> slipped,
      Value<String?> nextFocus,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$ReflectionsTableUpdateCompanionBuilder =
    ReflectionsCompanion Function({
      Value<String> id,
      Value<String> weekStart,
      Value<String?> grew,
      Value<String?> slipped,
      Value<String?> nextFocus,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$ReflectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableFilterComposer({
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

  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grew => $composableBuilder(
    column: $table.grew,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slipped => $composableBuilder(
    column: $table.slipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextFocus => $composableBuilder(
    column: $table.nextFocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReflectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableOrderingComposer({
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

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grew => $composableBuilder(
    column: $table.grew,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slipped => $composableBuilder(
    column: $table.slipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextFocus => $composableBuilder(
    column: $table.nextFocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReflectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get grew =>
      $composableBuilder(column: $table.grew, builder: (column) => column);

  GeneratedColumn<String> get slipped =>
      $composableBuilder(column: $table.slipped, builder: (column) => column);

  GeneratedColumn<String> get nextFocus =>
      $composableBuilder(column: $table.nextFocus, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReflectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReflectionsTable,
          Reflection,
          $$ReflectionsTableFilterComposer,
          $$ReflectionsTableOrderingComposer,
          $$ReflectionsTableAnnotationComposer,
          $$ReflectionsTableCreateCompanionBuilder,
          $$ReflectionsTableUpdateCompanionBuilder,
          (
            Reflection,
            BaseReferences<_$AppDatabase, $ReflectionsTable, Reflection>,
          ),
          Reflection,
          PrefetchHooks Function()
        > {
  $$ReflectionsTableTableManager(_$AppDatabase db, $ReflectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReflectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weekStart = const Value.absent(),
                Value<String?> grew = const Value.absent(),
                Value<String?> slipped = const Value.absent(),
                Value<String?> nextFocus = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReflectionsCompanion(
                id: id,
                weekStart: weekStart,
                grew: grew,
                slipped: slipped,
                nextFocus: nextFocus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weekStart,
                Value<String?> grew = const Value.absent(),
                Value<String?> slipped = const Value.absent(),
                Value<String?> nextFocus = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReflectionsCompanion.insert(
                id: id,
                weekStart: weekStart,
                grew: grew,
                slipped: slipped,
                nextFocus: nextFocus,
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

typedef $$ReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReflectionsTable,
      Reflection,
      $$ReflectionsTableFilterComposer,
      $$ReflectionsTableOrderingComposer,
      $$ReflectionsTableAnnotationComposer,
      $$ReflectionsTableCreateCompanionBuilder,
      $$ReflectionsTableUpdateCompanionBuilder,
      (
        Reflection,
        BaseReferences<_$AppDatabase, $ReflectionsTable, Reflection>,
      ),
      Reflection,
      PrefetchHooks Function()
    >;
typedef $$ChallengesTableCreateCompanionBuilder =
    ChallengesCompanion Function({
      required String id,
      required String title,
      required String description,
      required String type,
      required int durationDays,
      required String startDate,
      Value<String?> createdBy,
      Value<int> participants,
      Value<int> rowid,
    });
typedef $$ChallengesTableUpdateCompanionBuilder =
    ChallengesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<String> type,
      Value<int> durationDays,
      Value<String> startDate,
      Value<String?> createdBy,
      Value<int> participants,
      Value<int> rowid,
    });

final class $$ChallengesTableReferences
    extends BaseReferences<_$AppDatabase, $ChallengesTable, Challenge> {
  $$ChallengesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ChallengeParticipantsTable,
    List<ChallengeParticipant>
  >
  _challengeParticipantsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.challengeParticipants,
        aliasName: $_aliasNameGenerator(
          db.challenges.id,
          db.challengeParticipants.challengeId,
        ),
      );

  $$ChallengeParticipantsTableProcessedTableManager
  get challengeParticipantsRefs {
    final manager = $$ChallengeParticipantsTableTableManager(
      $_db,
      $_db.challengeParticipants,
    ).filter((f) => f.challengeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _challengeParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChallengesTableFilterComposer
    extends Composer<_$AppDatabase, $ChallengesTable> {
  $$ChallengesTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> challengeParticipantsRefs(
    Expression<bool> Function($$ChallengeParticipantsTableFilterComposer f) f,
  ) {
    final $$ChallengeParticipantsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.challengeParticipants,
          getReferencedColumn: (t) => t.challengeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChallengeParticipantsTableFilterComposer(
                $db: $db,
                $table: $db.challengeParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ChallengesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChallengesTable> {
  $$ChallengesTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChallengesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChallengesTable> {
  $$ChallengesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => column,
  );

  Expression<T> challengeParticipantsRefs<T extends Object>(
    Expression<T> Function($$ChallengeParticipantsTableAnnotationComposer a) f,
  ) {
    final $$ChallengeParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.challengeParticipants,
          getReferencedColumn: (t) => t.challengeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChallengeParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.challengeParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ChallengesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChallengesTable,
          Challenge,
          $$ChallengesTableFilterComposer,
          $$ChallengesTableOrderingComposer,
          $$ChallengesTableAnnotationComposer,
          $$ChallengesTableCreateCompanionBuilder,
          $$ChallengesTableUpdateCompanionBuilder,
          (Challenge, $$ChallengesTableReferences),
          Challenge,
          PrefetchHooks Function({bool challengeParticipantsRefs})
        > {
  $$ChallengesTableTableManager(_$AppDatabase db, $ChallengesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChallengesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChallengesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChallengesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> durationDays = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> participants = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChallengesCompanion(
                id: id,
                title: title,
                description: description,
                type: type,
                durationDays: durationDays,
                startDate: startDate,
                createdBy: createdBy,
                participants: participants,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String description,
                required String type,
                required int durationDays,
                required String startDate,
                Value<String?> createdBy = const Value.absent(),
                Value<int> participants = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChallengesCompanion.insert(
                id: id,
                title: title,
                description: description,
                type: type,
                durationDays: durationDays,
                startDate: startDate,
                createdBy: createdBy,
                participants: participants,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChallengesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({challengeParticipantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (challengeParticipantsRefs) db.challengeParticipants,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (challengeParticipantsRefs)
                    await $_getPrefetchedData<
                      Challenge,
                      $ChallengesTable,
                      ChallengeParticipant
                    >(
                      currentTable: table,
                      referencedTable: $$ChallengesTableReferences
                          ._challengeParticipantsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChallengesTableReferences(
                            db,
                            table,
                            p0,
                          ).challengeParticipantsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.challengeId == item.id,
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

typedef $$ChallengesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChallengesTable,
      Challenge,
      $$ChallengesTableFilterComposer,
      $$ChallengesTableOrderingComposer,
      $$ChallengesTableAnnotationComposer,
      $$ChallengesTableCreateCompanionBuilder,
      $$ChallengesTableUpdateCompanionBuilder,
      (Challenge, $$ChallengesTableReferences),
      Challenge,
      PrefetchHooks Function({bool challengeParticipantsRefs})
    >;
typedef $$ChallengeParticipantsTableCreateCompanionBuilder =
    ChallengeParticipantsCompanion Function({
      Value<int> id,
      required String challengeId,
      required String userName,
      required String joinedDate,
      Value<int> progress,
    });
typedef $$ChallengeParticipantsTableUpdateCompanionBuilder =
    ChallengeParticipantsCompanion Function({
      Value<int> id,
      Value<String> challengeId,
      Value<String> userName,
      Value<String> joinedDate,
      Value<int> progress,
    });

final class $$ChallengeParticipantsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ChallengeParticipantsTable,
          ChallengeParticipant
        > {
  $$ChallengeParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChallengesTable _challengeIdTable(_$AppDatabase db) =>
      db.challenges.createAlias(
        $_aliasNameGenerator(
          db.challengeParticipants.challengeId,
          db.challenges.id,
        ),
      );

  $$ChallengesTableProcessedTableManager get challengeId {
    final $_column = $_itemColumn<String>('challenge_id')!;

    final manager = $$ChallengesTableTableManager(
      $_db,
      $_db.challenges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_challengeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChallengeParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $ChallengeParticipantsTable> {
  $$ChallengeParticipantsTableFilterComposer({
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

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinedDate => $composableBuilder(
    column: $table.joinedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  $$ChallengesTableFilterComposer get challengeId {
    final $$ChallengesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.challengeId,
      referencedTable: $db.challenges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChallengesTableFilterComposer(
            $db: $db,
            $table: $db.challenges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChallengeParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChallengeParticipantsTable> {
  $$ChallengeParticipantsTableOrderingComposer({
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

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinedDate => $composableBuilder(
    column: $table.joinedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChallengesTableOrderingComposer get challengeId {
    final $$ChallengesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.challengeId,
      referencedTable: $db.challenges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChallengesTableOrderingComposer(
            $db: $db,
            $table: $db.challenges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChallengeParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChallengeParticipantsTable> {
  $$ChallengeParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get joinedDate => $composableBuilder(
    column: $table.joinedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  $$ChallengesTableAnnotationComposer get challengeId {
    final $$ChallengesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.challengeId,
      referencedTable: $db.challenges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChallengesTableAnnotationComposer(
            $db: $db,
            $table: $db.challenges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChallengeParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChallengeParticipantsTable,
          ChallengeParticipant,
          $$ChallengeParticipantsTableFilterComposer,
          $$ChallengeParticipantsTableOrderingComposer,
          $$ChallengeParticipantsTableAnnotationComposer,
          $$ChallengeParticipantsTableCreateCompanionBuilder,
          $$ChallengeParticipantsTableUpdateCompanionBuilder,
          (ChallengeParticipant, $$ChallengeParticipantsTableReferences),
          ChallengeParticipant,
          PrefetchHooks Function({bool challengeId})
        > {
  $$ChallengeParticipantsTableTableManager(
    _$AppDatabase db,
    $ChallengeParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChallengeParticipantsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ChallengeParticipantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ChallengeParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> challengeId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> joinedDate = const Value.absent(),
                Value<int> progress = const Value.absent(),
              }) => ChallengeParticipantsCompanion(
                id: id,
                challengeId: challengeId,
                userName: userName,
                joinedDate: joinedDate,
                progress: progress,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String challengeId,
                required String userName,
                required String joinedDate,
                Value<int> progress = const Value.absent(),
              }) => ChallengeParticipantsCompanion.insert(
                id: id,
                challengeId: challengeId,
                userName: userName,
                joinedDate: joinedDate,
                progress: progress,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChallengeParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({challengeId = false}) {
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
                    if (challengeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.challengeId,
                                referencedTable:
                                    $$ChallengeParticipantsTableReferences
                                        ._challengeIdTable(db),
                                referencedColumn:
                                    $$ChallengeParticipantsTableReferences
                                        ._challengeIdTable(db)
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

typedef $$ChallengeParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChallengeParticipantsTable,
      ChallengeParticipant,
      $$ChallengeParticipantsTableFilterComposer,
      $$ChallengeParticipantsTableOrderingComposer,
      $$ChallengeParticipantsTableAnnotationComposer,
      $$ChallengeParticipantsTableCreateCompanionBuilder,
      $$ChallengeParticipantsTableUpdateCompanionBuilder,
      (ChallengeParticipant, $$ChallengeParticipantsTableReferences),
      ChallengeParticipant,
      PrefetchHooks Function({bool challengeId})
    >;
typedef $$FellowshipLogsTableCreateCompanionBuilder =
    FellowshipLogsCompanion Function({
      required String id,
      required String date,
      Value<String?> contactName,
      Value<String?> note,
      required String createdAt,
      Value<int> promptType,
      Value<int> rowid,
    });
typedef $$FellowshipLogsTableUpdateCompanionBuilder =
    FellowshipLogsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String?> contactName,
      Value<String?> note,
      Value<String> createdAt,
      Value<int> promptType,
      Value<int> rowid,
    });

class $$FellowshipLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FellowshipLogsTable> {
  $$FellowshipLogsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactName => $composableBuilder(
    column: $table.contactName,
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

  ColumnFilters<int> get promptType => $composableBuilder(
    column: $table.promptType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FellowshipLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FellowshipLogsTable> {
  $$FellowshipLogsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactName => $composableBuilder(
    column: $table.contactName,
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

  ColumnOrderings<int> get promptType => $composableBuilder(
    column: $table.promptType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FellowshipLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FellowshipLogsTable> {
  $$FellowshipLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get contactName => $composableBuilder(
    column: $table.contactName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get promptType => $composableBuilder(
    column: $table.promptType,
    builder: (column) => column,
  );
}

class $$FellowshipLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FellowshipLogsTable,
          FellowshipLog,
          $$FellowshipLogsTableFilterComposer,
          $$FellowshipLogsTableOrderingComposer,
          $$FellowshipLogsTableAnnotationComposer,
          $$FellowshipLogsTableCreateCompanionBuilder,
          $$FellowshipLogsTableUpdateCompanionBuilder,
          (
            FellowshipLog,
            BaseReferences<_$AppDatabase, $FellowshipLogsTable, FellowshipLog>,
          ),
          FellowshipLog,
          PrefetchHooks Function()
        > {
  $$FellowshipLogsTableTableManager(
    _$AppDatabase db,
    $FellowshipLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FellowshipLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FellowshipLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FellowshipLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> contactName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> promptType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FellowshipLogsCompanion(
                id: id,
                date: date,
                contactName: contactName,
                note: note,
                createdAt: createdAt,
                promptType: promptType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                Value<String?> contactName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String createdAt,
                Value<int> promptType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FellowshipLogsCompanion.insert(
                id: id,
                date: date,
                contactName: contactName,
                note: note,
                createdAt: createdAt,
                promptType: promptType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FellowshipLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FellowshipLogsTable,
      FellowshipLog,
      $$FellowshipLogsTableFilterComposer,
      $$FellowshipLogsTableOrderingComposer,
      $$FellowshipLogsTableAnnotationComposer,
      $$FellowshipLogsTableCreateCompanionBuilder,
      $$FellowshipLogsTableUpdateCompanionBuilder,
      (
        FellowshipLog,
        BaseReferences<_$AppDatabase, $FellowshipLogsTable, FellowshipLog>,
      ),
      FellowshipLog,
      PrefetchHooks Function()
    >;
typedef $$FamilyTimeLogsTableCreateCompanionBuilder =
    FamilyTimeLogsCompanion Function({
      required String id,
      required String date,
      required double hours,
      Value<String?> note,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$FamilyTimeLogsTableUpdateCompanionBuilder =
    FamilyTimeLogsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<double> hours,
      Value<String?> note,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$FamilyTimeLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyTimeLogsTable> {
  $$FamilyTimeLogsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
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

class $$FamilyTimeLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyTimeLogsTable> {
  $$FamilyTimeLogsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
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

class $$FamilyTimeLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyTimeLogsTable> {
  $$FamilyTimeLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FamilyTimeLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyTimeLogsTable,
          FamilyTimeLog,
          $$FamilyTimeLogsTableFilterComposer,
          $$FamilyTimeLogsTableOrderingComposer,
          $$FamilyTimeLogsTableAnnotationComposer,
          $$FamilyTimeLogsTableCreateCompanionBuilder,
          $$FamilyTimeLogsTableUpdateCompanionBuilder,
          (
            FamilyTimeLog,
            BaseReferences<_$AppDatabase, $FamilyTimeLogsTable, FamilyTimeLog>,
          ),
          FamilyTimeLog,
          PrefetchHooks Function()
        > {
  $$FamilyTimeLogsTableTableManager(
    _$AppDatabase db,
    $FamilyTimeLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyTimeLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyTimeLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyTimeLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyTimeLogsCompanion(
                id: id,
                date: date,
                hours: hours,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required double hours,
                Value<String?> note = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FamilyTimeLogsCompanion.insert(
                id: id,
                date: date,
                hours: hours,
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

typedef $$FamilyTimeLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyTimeLogsTable,
      FamilyTimeLog,
      $$FamilyTimeLogsTableFilterComposer,
      $$FamilyTimeLogsTableOrderingComposer,
      $$FamilyTimeLogsTableAnnotationComposer,
      $$FamilyTimeLogsTableCreateCompanionBuilder,
      $$FamilyTimeLogsTableUpdateCompanionBuilder,
      (
        FamilyTimeLog,
        BaseReferences<_$AppDatabase, $FamilyTimeLogsTable, FamilyTimeLog>,
      ),
      FamilyTimeLog,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String title,
      required String type,
      required String periodStart,
      Value<bool> isAchieved,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> type,
      Value<String> periodStart,
      Value<bool> isAchieved,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAchieved => $composableBuilder(
    column: $table.isAchieved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAchieved => $composableBuilder(
    column: $table.isAchieved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAchieved => $composableBuilder(
    column: $table.isAchieved,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> periodStart = const Value.absent(),
                Value<bool> isAchieved = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                title: title,
                type: type,
                periodStart: periodStart,
                isAchieved: isAchieved,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String type,
                required String periodStart,
                Value<bool> isAchieved = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                title: title,
                type: type,
                periodStart: periodStart,
                isAchieved: isAchieved,
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

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$TodoItemsTableCreateCompanionBuilder =
    TodoItemsCompanion Function({
      required String id,
      required String title,
      required String date,
      Value<bool> isCompleted,
      Value<String?> completedAt,
      Value<bool> isSkipped,
      Value<int> sortOrder,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$TodoItemsTableUpdateCompanionBuilder =
    TodoItemsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> date,
      Value<bool> isCompleted,
      Value<String?> completedAt,
      Value<bool> isSkipped,
      Value<int> sortOrder,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$TodoItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodoItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodoItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSkipped =>
      $composableBuilder(column: $table.isSkipped, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TodoItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodoItemsTable,
          TodoItem,
          $$TodoItemsTableFilterComposer,
          $$TodoItemsTableOrderingComposer,
          $$TodoItemsTableAnnotationComposer,
          $$TodoItemsTableCreateCompanionBuilder,
          $$TodoItemsTableUpdateCompanionBuilder,
          (TodoItem, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItem>),
          TodoItem,
          PrefetchHooks Function()
        > {
  $$TodoItemsTableTableManager(_$AppDatabase db, $TodoItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoItemsCompanion(
                id: id,
                title: title,
                date: date,
                isCompleted: isCompleted,
                completedAt: completedAt,
                isSkipped: isSkipped,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String date,
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TodoItemsCompanion.insert(
                id: id,
                title: title,
                date: date,
                isCompleted: isCompleted,
                completedAt: completedAt,
                isSkipped: isSkipped,
                sortOrder: sortOrder,
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

typedef $$TodoItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodoItemsTable,
      TodoItem,
      $$TodoItemsTableFilterComposer,
      $$TodoItemsTableOrderingComposer,
      $$TodoItemsTableAnnotationComposer,
      $$TodoItemsTableCreateCompanionBuilder,
      $$TodoItemsTableUpdateCompanionBuilder,
      (TodoItem, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItem>),
      TodoItem,
      PrefetchHooks Function()
    >;
typedef $$DailyReflectionsTableCreateCompanionBuilder =
    DailyReflectionsCompanion Function({
      required String id,
      required String date,
      required String content,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$DailyReflectionsTableUpdateCompanionBuilder =
    DailyReflectionsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> content,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$DailyReflectionsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyReflectionsTable> {
  $$DailyReflectionsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReflectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyReflectionsTable> {
  $$DailyReflectionsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReflectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyReflectionsTable> {
  $$DailyReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyReflectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyReflectionsTable,
          DailyReflection,
          $$DailyReflectionsTableFilterComposer,
          $$DailyReflectionsTableOrderingComposer,
          $$DailyReflectionsTableAnnotationComposer,
          $$DailyReflectionsTableCreateCompanionBuilder,
          $$DailyReflectionsTableUpdateCompanionBuilder,
          (
            DailyReflection,
            BaseReferences<
              _$AppDatabase,
              $DailyReflectionsTable,
              DailyReflection
            >,
          ),
          DailyReflection,
          PrefetchHooks Function()
        > {
  $$DailyReflectionsTableTableManager(
    _$AppDatabase db,
    $DailyReflectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyReflectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReflectionsCompanion(
                id: id,
                date: date,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String content,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyReflectionsCompanion.insert(
                id: id,
                date: date,
                content: content,
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

typedef $$DailyReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyReflectionsTable,
      DailyReflection,
      $$DailyReflectionsTableFilterComposer,
      $$DailyReflectionsTableOrderingComposer,
      $$DailyReflectionsTableAnnotationComposer,
      $$DailyReflectionsTableCreateCompanionBuilder,
      $$DailyReflectionsTableUpdateCompanionBuilder,
      (
        DailyReflection,
        BaseReferences<_$AppDatabase, $DailyReflectionsTable, DailyReflection>,
      ),
      DailyReflection,
      PrefetchHooks Function()
    >;
typedef $$StreakLogTableCreateCompanionBuilder =
    StreakLogCompanion Function({
      required String id,
      required String date,
      required bool counted,
      required bool freezeUsed,
      required String anchorType,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$StreakLogTableUpdateCompanionBuilder =
    StreakLogCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<bool> counted,
      Value<bool> freezeUsed,
      Value<String> anchorType,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$StreakLogTableFilterComposer
    extends Composer<_$AppDatabase, $StreakLogTable> {
  $$StreakLogTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get counted => $composableBuilder(
    column: $table.counted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get freezeUsed => $composableBuilder(
    column: $table.freezeUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreakLogTableOrderingComposer
    extends Composer<_$AppDatabase, $StreakLogTable> {
  $$StreakLogTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get counted => $composableBuilder(
    column: $table.counted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get freezeUsed => $composableBuilder(
    column: $table.freezeUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreakLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreakLogTable> {
  $$StreakLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get counted =>
      $composableBuilder(column: $table.counted, builder: (column) => column);

  GeneratedColumn<bool> get freezeUsed => $composableBuilder(
    column: $table.freezeUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StreakLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StreakLogTable,
          StreakLogData,
          $$StreakLogTableFilterComposer,
          $$StreakLogTableOrderingComposer,
          $$StreakLogTableAnnotationComposer,
          $$StreakLogTableCreateCompanionBuilder,
          $$StreakLogTableUpdateCompanionBuilder,
          (
            StreakLogData,
            BaseReferences<_$AppDatabase, $StreakLogTable, StreakLogData>,
          ),
          StreakLogData,
          PrefetchHooks Function()
        > {
  $$StreakLogTableTableManager(_$AppDatabase db, $StreakLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> counted = const Value.absent(),
                Value<bool> freezeUsed = const Value.absent(),
                Value<String> anchorType = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreakLogCompanion(
                id: id,
                date: date,
                counted: counted,
                freezeUsed: freezeUsed,
                anchorType: anchorType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required bool counted,
                required bool freezeUsed,
                required String anchorType,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StreakLogCompanion.insert(
                id: id,
                date: date,
                counted: counted,
                freezeUsed: freezeUsed,
                anchorType: anchorType,
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

typedef $$StreakLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StreakLogTable,
      StreakLogData,
      $$StreakLogTableFilterComposer,
      $$StreakLogTableOrderingComposer,
      $$StreakLogTableAnnotationComposer,
      $$StreakLogTableCreateCompanionBuilder,
      $$StreakLogTableUpdateCompanionBuilder,
      (
        StreakLogData,
        BaseReferences<_$AppDatabase, $StreakLogTable, StreakLogData>,
      ),
      StreakLogData,
      PrefetchHooks Function()
    >;
typedef $$StreakFrozenTableCreateCompanionBuilder =
    StreakFrozenCompanion Function({
      required String id,
      required int count,
      required int bestStreak,
      Value<String?> lastAnchorDate,
      Value<String?> brokenDate,
      required int freezesEarned,
      Value<int> rowid,
    });
typedef $$StreakFrozenTableUpdateCompanionBuilder =
    StreakFrozenCompanion Function({
      Value<String> id,
      Value<int> count,
      Value<int> bestStreak,
      Value<String?> lastAnchorDate,
      Value<String?> brokenDate,
      Value<int> freezesEarned,
      Value<int> rowid,
    });

class $$StreakFrozenTableFilterComposer
    extends Composer<_$AppDatabase, $StreakFrozenTable> {
  $$StreakFrozenTableFilterComposer({
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

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAnchorDate => $composableBuilder(
    column: $table.lastAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brokenDate => $composableBuilder(
    column: $table.brokenDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freezesEarned => $composableBuilder(
    column: $table.freezesEarned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreakFrozenTableOrderingComposer
    extends Composer<_$AppDatabase, $StreakFrozenTable> {
  $$StreakFrozenTableOrderingComposer({
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

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAnchorDate => $composableBuilder(
    column: $table.lastAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brokenDate => $composableBuilder(
    column: $table.brokenDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freezesEarned => $composableBuilder(
    column: $table.freezesEarned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreakFrozenTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreakFrozenTable> {
  $$StreakFrozenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastAnchorDate => $composableBuilder(
    column: $table.lastAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brokenDate => $composableBuilder(
    column: $table.brokenDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freezesEarned => $composableBuilder(
    column: $table.freezesEarned,
    builder: (column) => column,
  );
}

class $$StreakFrozenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StreakFrozenTable,
          StreakFrozenData,
          $$StreakFrozenTableFilterComposer,
          $$StreakFrozenTableOrderingComposer,
          $$StreakFrozenTableAnnotationComposer,
          $$StreakFrozenTableCreateCompanionBuilder,
          $$StreakFrozenTableUpdateCompanionBuilder,
          (
            StreakFrozenData,
            BaseReferences<_$AppDatabase, $StreakFrozenTable, StreakFrozenData>,
          ),
          StreakFrozenData,
          PrefetchHooks Function()
        > {
  $$StreakFrozenTableTableManager(_$AppDatabase db, $StreakFrozenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakFrozenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakFrozenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakFrozenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> bestStreak = const Value.absent(),
                Value<String?> lastAnchorDate = const Value.absent(),
                Value<String?> brokenDate = const Value.absent(),
                Value<int> freezesEarned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreakFrozenCompanion(
                id: id,
                count: count,
                bestStreak: bestStreak,
                lastAnchorDate: lastAnchorDate,
                brokenDate: brokenDate,
                freezesEarned: freezesEarned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int count,
                required int bestStreak,
                Value<String?> lastAnchorDate = const Value.absent(),
                Value<String?> brokenDate = const Value.absent(),
                required int freezesEarned,
                Value<int> rowid = const Value.absent(),
              }) => StreakFrozenCompanion.insert(
                id: id,
                count: count,
                bestStreak: bestStreak,
                lastAnchorDate: lastAnchorDate,
                brokenDate: brokenDate,
                freezesEarned: freezesEarned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreakFrozenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StreakFrozenTable,
      StreakFrozenData,
      $$StreakFrozenTableFilterComposer,
      $$StreakFrozenTableOrderingComposer,
      $$StreakFrozenTableAnnotationComposer,
      $$StreakFrozenTableCreateCompanionBuilder,
      $$StreakFrozenTableUpdateCompanionBuilder,
      (
        StreakFrozenData,
        BaseReferences<_$AppDatabase, $StreakFrozenTable, StreakFrozenData>,
      ),
      StreakFrozenData,
      PrefetchHooks Function()
    >;
typedef $$SoulLogTableCreateCompanionBuilder =
    SoulLogCompanion Function({
      required String id,
      required String date,
      required int mood,
      Value<String?> note,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$SoulLogTableUpdateCompanionBuilder =
    SoulLogCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<int> mood,
      Value<String?> note,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$SoulLogTableFilterComposer
    extends Composer<_$AppDatabase, $SoulLogTable> {
  $$SoulLogTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
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

class $$SoulLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SoulLogTable> {
  $$SoulLogTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
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

class $$SoulLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoulLogTable> {
  $$SoulLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SoulLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SoulLogTable,
          SoulLogData,
          $$SoulLogTableFilterComposer,
          $$SoulLogTableOrderingComposer,
          $$SoulLogTableAnnotationComposer,
          $$SoulLogTableCreateCompanionBuilder,
          $$SoulLogTableUpdateCompanionBuilder,
          (
            SoulLogData,
            BaseReferences<_$AppDatabase, $SoulLogTable, SoulLogData>,
          ),
          SoulLogData,
          PrefetchHooks Function()
        > {
  $$SoulLogTableTableManager(_$AppDatabase db, $SoulLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoulLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SoulLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoulLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> mood = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SoulLogCompanion(
                id: id,
                date: date,
                mood: mood,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required int mood,
                Value<String?> note = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SoulLogCompanion.insert(
                id: id,
                date: date,
                mood: mood,
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

typedef $$SoulLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SoulLogTable,
      SoulLogData,
      $$SoulLogTableFilterComposer,
      $$SoulLogTableOrderingComposer,
      $$SoulLogTableAnnotationComposer,
      $$SoulLogTableCreateCompanionBuilder,
      $$SoulLogTableUpdateCompanionBuilder,
      (SoulLogData, BaseReferences<_$AppDatabase, $SoulLogTable, SoulLogData>),
      SoulLogData,
      PrefetchHooks Function()
    >;
typedef $$BibleSessionsTableCreateCompanionBuilder =
    BibleSessionsCompanion Function({
      required String id,
      required String date,
      required String bookId,
      required int chapterStart,
      required int chapterEnd,
      Value<int> durationMinutes,
      Value<String?> reflection,
      Value<bool> isPlanReading,
      Value<String?> planDay,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$BibleSessionsTableUpdateCompanionBuilder =
    BibleSessionsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> bookId,
      Value<int> chapterStart,
      Value<int> chapterEnd,
      Value<int> durationMinutes,
      Value<String?> reflection,
      Value<bool> isPlanReading,
      Value<String?> planDay,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$BibleSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $BibleSessionsTable> {
  $$BibleSessionsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterStart => $composableBuilder(
    column: $table.chapterStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterEnd => $composableBuilder(
    column: $table.chapterEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reflection => $composableBuilder(
    column: $table.reflection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlanReading => $composableBuilder(
    column: $table.isPlanReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planDay => $composableBuilder(
    column: $table.planDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BibleSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $BibleSessionsTable> {
  $$BibleSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterStart => $composableBuilder(
    column: $table.chapterStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterEnd => $composableBuilder(
    column: $table.chapterEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflection => $composableBuilder(
    column: $table.reflection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlanReading => $composableBuilder(
    column: $table.isPlanReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planDay => $composableBuilder(
    column: $table.planDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BibleSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BibleSessionsTable> {
  $$BibleSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapterStart => $composableBuilder(
    column: $table.chapterStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapterEnd => $composableBuilder(
    column: $table.chapterEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reflection => $composableBuilder(
    column: $table.reflection,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPlanReading => $composableBuilder(
    column: $table.isPlanReading,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planDay =>
      $composableBuilder(column: $table.planDay, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BibleSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BibleSessionsTable,
          BibleSession,
          $$BibleSessionsTableFilterComposer,
          $$BibleSessionsTableOrderingComposer,
          $$BibleSessionsTableAnnotationComposer,
          $$BibleSessionsTableCreateCompanionBuilder,
          $$BibleSessionsTableUpdateCompanionBuilder,
          (
            BibleSession,
            BaseReferences<_$AppDatabase, $BibleSessionsTable, BibleSession>,
          ),
          BibleSession,
          PrefetchHooks Function()
        > {
  $$BibleSessionsTableTableManager(_$AppDatabase db, $BibleSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BibleSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BibleSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BibleSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<int> chapterStart = const Value.absent(),
                Value<int> chapterEnd = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String?> reflection = const Value.absent(),
                Value<bool> isPlanReading = const Value.absent(),
                Value<String?> planDay = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BibleSessionsCompanion(
                id: id,
                date: date,
                bookId: bookId,
                chapterStart: chapterStart,
                chapterEnd: chapterEnd,
                durationMinutes: durationMinutes,
                reflection: reflection,
                isPlanReading: isPlanReading,
                planDay: planDay,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String bookId,
                required int chapterStart,
                required int chapterEnd,
                Value<int> durationMinutes = const Value.absent(),
                Value<String?> reflection = const Value.absent(),
                Value<bool> isPlanReading = const Value.absent(),
                Value<String?> planDay = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BibleSessionsCompanion.insert(
                id: id,
                date: date,
                bookId: bookId,
                chapterStart: chapterStart,
                chapterEnd: chapterEnd,
                durationMinutes: durationMinutes,
                reflection: reflection,
                isPlanReading: isPlanReading,
                planDay: planDay,
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

typedef $$BibleSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BibleSessionsTable,
      BibleSession,
      $$BibleSessionsTableFilterComposer,
      $$BibleSessionsTableOrderingComposer,
      $$BibleSessionsTableAnnotationComposer,
      $$BibleSessionsTableCreateCompanionBuilder,
      $$BibleSessionsTableUpdateCompanionBuilder,
      (
        BibleSession,
        BaseReferences<_$AppDatabase, $BibleSessionsTable, BibleSession>,
      ),
      BibleSession,
      PrefetchHooks Function()
    >;
typedef $$ReadingLoopsTableCreateCompanionBuilder =
    ReadingLoopsCompanion Function({
      required String id,
      required String planId,
      required int duration,
      required int startChapter,
      required String startDate,
      required String status,
      required int loopNumber,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$ReadingLoopsTableUpdateCompanionBuilder =
    ReadingLoopsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<int> duration,
      Value<int> startChapter,
      Value<String> startDate,
      Value<String> status,
      Value<int> loopNumber,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$ReadingLoopsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingLoopsTable> {
  $$ReadingLoopsTableFilterComposer({
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

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loopNumber => $composableBuilder(
    column: $table.loopNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingLoopsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingLoopsTable> {
  $$ReadingLoopsTableOrderingComposer({
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

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loopNumber => $composableBuilder(
    column: $table.loopNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingLoopsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingLoopsTable> {
  $$ReadingLoopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get loopNumber => $composableBuilder(
    column: $table.loopNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingLoopsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingLoopsTable,
          ReadingLoop,
          $$ReadingLoopsTableFilterComposer,
          $$ReadingLoopsTableOrderingComposer,
          $$ReadingLoopsTableAnnotationComposer,
          $$ReadingLoopsTableCreateCompanionBuilder,
          $$ReadingLoopsTableUpdateCompanionBuilder,
          (
            ReadingLoop,
            BaseReferences<_$AppDatabase, $ReadingLoopsTable, ReadingLoop>,
          ),
          ReadingLoop,
          PrefetchHooks Function()
        > {
  $$ReadingLoopsTableTableManager(_$AppDatabase db, $ReadingLoopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingLoopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingLoopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingLoopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<int> startChapter = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> loopNumber = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingLoopsCompanion(
                id: id,
                planId: planId,
                duration: duration,
                startChapter: startChapter,
                startDate: startDate,
                status: status,
                loopNumber: loopNumber,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required int duration,
                required int startChapter,
                required String startDate,
                required String status,
                required int loopNumber,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingLoopsCompanion.insert(
                id: id,
                planId: planId,
                duration: duration,
                startChapter: startChapter,
                startDate: startDate,
                status: status,
                loopNumber: loopNumber,
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

typedef $$ReadingLoopsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingLoopsTable,
      ReadingLoop,
      $$ReadingLoopsTableFilterComposer,
      $$ReadingLoopsTableOrderingComposer,
      $$ReadingLoopsTableAnnotationComposer,
      $$ReadingLoopsTableCreateCompanionBuilder,
      $$ReadingLoopsTableUpdateCompanionBuilder,
      (
        ReadingLoop,
        BaseReferences<_$AppDatabase, $ReadingLoopsTable, ReadingLoop>,
      ),
      ReadingLoop,
      PrefetchHooks Function()
    >;
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$CompletionsTableTableManager get completions =>
      $$CompletionsTableTableManager(_db, _db.completions);
  $$PrayerLogsTableTableManager get prayerLogs =>
      $$PrayerLogsTableTableManager(_db, _db.prayerLogs);
  $$BibleReadsTableTableManager get bibleReads =>
      $$BibleReadsTableTableManager(_db, _db.bibleReads);
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db, _db.skills);
  $$SkillSessionsTableTableManager get skillSessions =>
      $$SkillSessionsTableTableManager(_db, _db.skillSessions);
  $$ReflectionsTableTableManager get reflections =>
      $$ReflectionsTableTableManager(_db, _db.reflections);
  $$ChallengesTableTableManager get challenges =>
      $$ChallengesTableTableManager(_db, _db.challenges);
  $$ChallengeParticipantsTableTableManager get challengeParticipants =>
      $$ChallengeParticipantsTableTableManager(_db, _db.challengeParticipants);
  $$FellowshipLogsTableTableManager get fellowshipLogs =>
      $$FellowshipLogsTableTableManager(_db, _db.fellowshipLogs);
  $$FamilyTimeLogsTableTableManager get familyTimeLogs =>
      $$FamilyTimeLogsTableTableManager(_db, _db.familyTimeLogs);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db, _db.todoItems);
  $$DailyReflectionsTableTableManager get dailyReflections =>
      $$DailyReflectionsTableTableManager(_db, _db.dailyReflections);
  $$StreakLogTableTableManager get streakLog =>
      $$StreakLogTableTableManager(_db, _db.streakLog);
  $$StreakFrozenTableTableManager get streakFrozen =>
      $$StreakFrozenTableTableManager(_db, _db.streakFrozen);
  $$SoulLogTableTableManager get soulLog =>
      $$SoulLogTableTableManager(_db, _db.soulLog);
  $$BibleSessionsTableTableManager get bibleSessions =>
      $$BibleSessionsTableTableManager(_db, _db.bibleSessions);
  $$ReadingLoopsTableTableManager get readingLoops =>
      $$ReadingLoopsTableTableManager(_db, _db.readingLoops);
  $$WisdomNotesTableTableManager get wisdomNotes =>
      $$WisdomNotesTableTableManager(_db, _db.wisdomNotes);
}
