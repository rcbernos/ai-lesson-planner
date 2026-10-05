// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LessonPlansTable extends LessonPlans
    with TableInfo<$LessonPlansTable, LessonPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gradeLevelMeta =
      const VerificationMeta('gradeLevel');
  @override
  late final GeneratedColumn<int> gradeLevel = GeneratedColumn<int>(
      'grade_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ilawContentMeta =
      const VerificationMeta('ilawContent');
  @override
  late final GeneratedColumn<String> ilawContent = GeneratedColumn<String>(
      'ilaw_content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        gradeLevel,
        subject,
        ilawContent,
        status,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_plans';
  @override
  VerificationContext validateIntegrity(Insertable<LessonPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
          _gradeLevelMeta,
          gradeLevel.isAcceptableOrUnknown(
              data['grade_level']!, _gradeLevelMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('ilaw_content')) {
      context.handle(
          _ilawContentMeta,
          ilawContent.isAcceptableOrUnknown(
              data['ilaw_content']!, _ilawContentMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      gradeLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grade_level']),
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      ilawContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ilaw_content']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $LessonPlansTable createAlias(String alias) {
    return $LessonPlansTable(attachedDatabase, alias);
  }
}

class LessonPlan extends DataClass implements Insertable<LessonPlan> {
  final int id;
  final String title;
  final int? gradeLevel;
  final String? subject;
  final String? ilawContent;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const LessonPlan(
      {required this.id,
      required this.title,
      this.gradeLevel,
      this.subject,
      this.ilawContent,
      required this.status,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || gradeLevel != null) {
      map['grade_level'] = Variable<int>(gradeLevel);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || ilawContent != null) {
      map['ilaw_content'] = Variable<String>(ilawContent);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LessonPlansCompanion toCompanion(bool nullToAbsent) {
    return LessonPlansCompanion(
      id: Value(id),
      title: Value(title),
      gradeLevel: gradeLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(gradeLevel),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      ilawContent: ilawContent == null && nullToAbsent
          ? const Value.absent()
          : Value(ilawContent),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LessonPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonPlan(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      gradeLevel: serializer.fromJson<int?>(json['gradeLevel']),
      subject: serializer.fromJson<String?>(json['subject']),
      ilawContent: serializer.fromJson<String?>(json['ilawContent']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'gradeLevel': serializer.toJson<int?>(gradeLevel),
      'subject': serializer.toJson<String?>(subject),
      'ilawContent': serializer.toJson<String?>(ilawContent),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LessonPlan copyWith(
          {int? id,
          String? title,
          Value<int?> gradeLevel = const Value.absent(),
          Value<String?> subject = const Value.absent(),
          Value<String?> ilawContent = const Value.absent(),
          String? status,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      LessonPlan(
        id: id ?? this.id,
        title: title ?? this.title,
        gradeLevel: gradeLevel.present ? gradeLevel.value : this.gradeLevel,
        subject: subject.present ? subject.value : this.subject,
        ilawContent: ilawContent.present ? ilawContent.value : this.ilawContent,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  LessonPlan copyWithCompanion(LessonPlansCompanion data) {
    return LessonPlan(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      gradeLevel:
          data.gradeLevel.present ? data.gradeLevel.value : this.gradeLevel,
      subject: data.subject.present ? data.subject.value : this.subject,
      ilawContent:
          data.ilawContent.present ? data.ilawContent.value : this.ilawContent,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonPlan(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subject: $subject, ')
          ..write('ilawContent: $ilawContent, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, gradeLevel, subject, ilawContent,
      status, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonPlan &&
          other.id == this.id &&
          other.title == this.title &&
          other.gradeLevel == this.gradeLevel &&
          other.subject == this.subject &&
          other.ilawContent == this.ilawContent &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LessonPlansCompanion extends UpdateCompanion<LessonPlan> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> gradeLevel;
  final Value<String?> subject;
  final Value<String?> ilawContent;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const LessonPlansCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.subject = const Value.absent(),
    this.ilawContent = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LessonPlansCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.gradeLevel = const Value.absent(),
    this.subject = const Value.absent(),
    this.ilawContent = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<LessonPlan> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? gradeLevel,
    Expression<String>? subject,
    Expression<String>? ilawContent,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (subject != null) 'subject': subject,
      if (ilawContent != null) 'ilaw_content': ilawContent,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LessonPlansCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<int?>? gradeLevel,
      Value<String?>? subject,
      Value<String?>? ilawContent,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return LessonPlansCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subject: subject ?? this.subject,
      ilawContent: ilawContent ?? this.ilawContent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<int>(gradeLevel.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (ilawContent.present) {
      map['ilaw_content'] = Variable<String>(ilawContent.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonPlansCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subject: $subject, ')
          ..write('ilawContent: $ilawContent, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReferenceNotesTable extends ReferenceNotes
    with TableInfo<$ReferenceNotesTable, ReferenceNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lessonPlanIdMeta =
      const VerificationMeta('lessonPlanId');
  @override
  late final GeneratedColumn<int> lessonPlanId = GeneratedColumn<int>(
      'lesson_plan_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES lesson_plans (id) ON DELETE SET NULL'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, lessonPlanId, title, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_notes';
  @override
  VerificationContext validateIntegrity(Insertable<ReferenceNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_plan_id')) {
      context.handle(
          _lessonPlanIdMeta,
          lessonPlanId.isAcceptableOrUnknown(
              data['lesson_plan_id']!, _lessonPlanIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferenceNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lessonPlanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lesson_plan_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReferenceNotesTable createAlias(String alias) {
    return $ReferenceNotesTable(attachedDatabase, alias);
  }
}

class ReferenceNote extends DataClass implements Insertable<ReferenceNote> {
  final int id;
  final int? lessonPlanId;
  final String title;
  final String? content;
  final DateTime createdAt;
  const ReferenceNote(
      {required this.id,
      this.lessonPlanId,
      required this.title,
      this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lessonPlanId != null) {
      map['lesson_plan_id'] = Variable<int>(lessonPlanId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReferenceNotesCompanion toCompanion(bool nullToAbsent) {
    return ReferenceNotesCompanion(
      id: Value(id),
      lessonPlanId: lessonPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonPlanId),
      title: Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ReferenceNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceNote(
      id: serializer.fromJson<int>(json['id']),
      lessonPlanId: serializer.fromJson<int?>(json['lessonPlanId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonPlanId': serializer.toJson<int?>(lessonPlanId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String?>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReferenceNote copyWith(
          {int? id,
          Value<int?> lessonPlanId = const Value.absent(),
          String? title,
          Value<String?> content = const Value.absent(),
          DateTime? createdAt}) =>
      ReferenceNote(
        id: id ?? this.id,
        lessonPlanId:
            lessonPlanId.present ? lessonPlanId.value : this.lessonPlanId,
        title: title ?? this.title,
        content: content.present ? content.value : this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  ReferenceNote copyWithCompanion(ReferenceNotesCompanion data) {
    return ReferenceNote(
      id: data.id.present ? data.id.value : this.id,
      lessonPlanId: data.lessonPlanId.present
          ? data.lessonPlanId.value
          : this.lessonPlanId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceNote(')
          ..write('id: $id, ')
          ..write('lessonPlanId: $lessonPlanId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lessonPlanId, title, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceNote &&
          other.id == this.id &&
          other.lessonPlanId == this.lessonPlanId &&
          other.title == this.title &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ReferenceNotesCompanion extends UpdateCompanion<ReferenceNote> {
  final Value<int> id;
  final Value<int?> lessonPlanId;
  final Value<String> title;
  final Value<String?> content;
  final Value<DateTime> createdAt;
  const ReferenceNotesCompanion({
    this.id = const Value.absent(),
    this.lessonPlanId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReferenceNotesCompanion.insert({
    this.id = const Value.absent(),
    this.lessonPlanId = const Value.absent(),
    required String title,
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<ReferenceNote> custom({
    Expression<int>? id,
    Expression<int>? lessonPlanId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonPlanId != null) 'lesson_plan_id': lessonPlanId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReferenceNotesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? lessonPlanId,
      Value<String>? title,
      Value<String?>? content,
      Value<DateTime>? createdAt}) {
    return ReferenceNotesCompanion(
      id: id ?? this.id,
      lessonPlanId: lessonPlanId ?? this.lessonPlanId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonPlanId.present) {
      map['lesson_plan_id'] = Variable<int>(lessonPlanId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceNotesCompanion(')
          ..write('id: $id, ')
          ..write('lessonPlanId: $lessonPlanId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BibliographyTable extends Bibliography
    with TableInfo<$BibliographyTable, BibliographyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BibliographyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lessonPlanIdMeta =
      const VerificationMeta('lessonPlanId');
  @override
  late final GeneratedColumn<int> lessonPlanId = GeneratedColumn<int>(
      'lesson_plan_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES lesson_plans (id) ON DELETE SET NULL'));
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, lessonPlanId, author, title, year, url, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bibliography';
  @override
  VerificationContext validateIntegrity(Insertable<BibliographyData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_plan_id')) {
      context.handle(
          _lessonPlanIdMeta,
          lessonPlanId.isAcceptableOrUnknown(
              data['lesson_plan_id']!, _lessonPlanIdMeta));
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BibliographyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BibliographyData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lessonPlanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lesson_plan_id']),
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BibliographyTable createAlias(String alias) {
    return $BibliographyTable(attachedDatabase, alias);
  }
}

class BibliographyData extends DataClass
    implements Insertable<BibliographyData> {
  final int id;
  final int? lessonPlanId;
  final String author;
  final String title;
  final int year;
  final String? url;
  final DateTime createdAt;
  const BibliographyData(
      {required this.id,
      this.lessonPlanId,
      required this.author,
      required this.title,
      required this.year,
      this.url,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lessonPlanId != null) {
      map['lesson_plan_id'] = Variable<int>(lessonPlanId);
    }
    map['author'] = Variable<String>(author);
    map['title'] = Variable<String>(title);
    map['year'] = Variable<int>(year);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BibliographyCompanion toCompanion(bool nullToAbsent) {
    return BibliographyCompanion(
      id: Value(id),
      lessonPlanId: lessonPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonPlanId),
      author: Value(author),
      title: Value(title),
      year: Value(year),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      createdAt: Value(createdAt),
    );
  }

  factory BibliographyData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BibliographyData(
      id: serializer.fromJson<int>(json['id']),
      lessonPlanId: serializer.fromJson<int?>(json['lessonPlanId']),
      author: serializer.fromJson<String>(json['author']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int>(json['year']),
      url: serializer.fromJson<String?>(json['url']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonPlanId': serializer.toJson<int?>(lessonPlanId),
      'author': serializer.toJson<String>(author),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int>(year),
      'url': serializer.toJson<String?>(url),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BibliographyData copyWith(
          {int? id,
          Value<int?> lessonPlanId = const Value.absent(),
          String? author,
          String? title,
          int? year,
          Value<String?> url = const Value.absent(),
          DateTime? createdAt}) =>
      BibliographyData(
        id: id ?? this.id,
        lessonPlanId:
            lessonPlanId.present ? lessonPlanId.value : this.lessonPlanId,
        author: author ?? this.author,
        title: title ?? this.title,
        year: year ?? this.year,
        url: url.present ? url.value : this.url,
        createdAt: createdAt ?? this.createdAt,
      );
  BibliographyData copyWithCompanion(BibliographyCompanion data) {
    return BibliographyData(
      id: data.id.present ? data.id.value : this.id,
      lessonPlanId: data.lessonPlanId.present
          ? data.lessonPlanId.value
          : this.lessonPlanId,
      author: data.author.present ? data.author.value : this.author,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      url: data.url.present ? data.url.value : this.url,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BibliographyData(')
          ..write('id: $id, ')
          ..write('lessonPlanId: $lessonPlanId, ')
          ..write('author: $author, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('url: $url, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lessonPlanId, author, title, year, url, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BibliographyData &&
          other.id == this.id &&
          other.lessonPlanId == this.lessonPlanId &&
          other.author == this.author &&
          other.title == this.title &&
          other.year == this.year &&
          other.url == this.url &&
          other.createdAt == this.createdAt);
}

class BibliographyCompanion extends UpdateCompanion<BibliographyData> {
  final Value<int> id;
  final Value<int?> lessonPlanId;
  final Value<String> author;
  final Value<String> title;
  final Value<int> year;
  final Value<String?> url;
  final Value<DateTime> createdAt;
  const BibliographyCompanion({
    this.id = const Value.absent(),
    this.lessonPlanId = const Value.absent(),
    this.author = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.url = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BibliographyCompanion.insert({
    this.id = const Value.absent(),
    this.lessonPlanId = const Value.absent(),
    required String author,
    required String title,
    required int year,
    this.url = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : author = Value(author),
        title = Value(title),
        year = Value(year);
  static Insertable<BibliographyData> custom({
    Expression<int>? id,
    Expression<int>? lessonPlanId,
    Expression<String>? author,
    Expression<String>? title,
    Expression<int>? year,
    Expression<String>? url,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonPlanId != null) 'lesson_plan_id': lessonPlanId,
      if (author != null) 'author': author,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (url != null) 'url': url,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BibliographyCompanion copyWith(
      {Value<int>? id,
      Value<int?>? lessonPlanId,
      Value<String>? author,
      Value<String>? title,
      Value<int>? year,
      Value<String?>? url,
      Value<DateTime>? createdAt}) {
    return BibliographyCompanion(
      id: id ?? this.id,
      lessonPlanId: lessonPlanId ?? this.lessonPlanId,
      author: author ?? this.author,
      title: title ?? this.title,
      year: year ?? this.year,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonPlanId.present) {
      map['lesson_plan_id'] = Variable<int>(lessonPlanId.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BibliographyCompanion(')
          ..write('id: $id, ')
          ..write('lessonPlanId: $lessonPlanId, ')
          ..write('author: $author, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('url: $url, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LessonPlansTable lessonPlans = $LessonPlansTable(this);
  late final $ReferenceNotesTable referenceNotes = $ReferenceNotesTable(this);
  late final $BibliographyTable bibliography = $BibliographyTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [lessonPlans, referenceNotes, bibliography];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('lesson_plans',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reference_notes', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('lesson_plans',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bibliography', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

typedef $$LessonPlansTableCreateCompanionBuilder = LessonPlansCompanion
    Function({
  Value<int> id,
  required String title,
  Value<int?> gradeLevel,
  Value<String?> subject,
  Value<String?> ilawContent,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$LessonPlansTableUpdateCompanionBuilder = LessonPlansCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<int?> gradeLevel,
  Value<String?> subject,
  Value<String?> ilawContent,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

final class $$LessonPlansTableReferences
    extends BaseReferences<_$AppDatabase, $LessonPlansTable, LessonPlan> {
  $$LessonPlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReferenceNotesTable, List<ReferenceNote>>
      _referenceNotesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.referenceNotes,
              aliasName: 'lesson_plans__id__reference_notes__lesson_plan_id');

  $$ReferenceNotesTableProcessedTableManager get referenceNotesRefs {
    final manager = $$ReferenceNotesTableTableManager($_db, $_db.referenceNotes)
        .filter((f) => f.lessonPlanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_referenceNotesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BibliographyTable, List<BibliographyData>>
      _bibliographyRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.bibliography,
              aliasName: 'lesson_plans__id__bibliography__lesson_plan_id');

  $$BibliographyTableProcessedTableManager get bibliographyRefs {
    final manager = $$BibliographyTableTableManager($_db, $_db.bibliography)
        .filter((f) => f.lessonPlanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bibliographyRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LessonPlansTableFilterComposer
    extends Composer<_$AppDatabase, $LessonPlansTable> {
  $$LessonPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gradeLevel => $composableBuilder(
      column: $table.gradeLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ilawContent => $composableBuilder(
      column: $table.ilawContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> referenceNotesRefs(
      Expression<bool> Function($$ReferenceNotesTableFilterComposer f) f) {
    final $$ReferenceNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.referenceNotes,
        getReferencedColumn: (t) => t.lessonPlanId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReferenceNotesTableFilterComposer(
              $db: $db,
              $table: $db.referenceNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bibliographyRefs(
      Expression<bool> Function($$BibliographyTableFilterComposer f) f) {
    final $$BibliographyTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bibliography,
        getReferencedColumn: (t) => t.lessonPlanId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BibliographyTableFilterComposer(
              $db: $db,
              $table: $db.bibliography,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LessonPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonPlansTable> {
  $$LessonPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gradeLevel => $composableBuilder(
      column: $table.gradeLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ilawContent => $composableBuilder(
      column: $table.ilawContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LessonPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonPlansTable> {
  $$LessonPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get gradeLevel => $composableBuilder(
      column: $table.gradeLevel, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get ilawContent => $composableBuilder(
      column: $table.ilawContent, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> referenceNotesRefs<T extends Object>(
      Expression<T> Function($$ReferenceNotesTableAnnotationComposer a) f) {
    final $$ReferenceNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.referenceNotes,
        getReferencedColumn: (t) => t.lessonPlanId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReferenceNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.referenceNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bibliographyRefs<T extends Object>(
      Expression<T> Function($$BibliographyTableAnnotationComposer a) f) {
    final $$BibliographyTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bibliography,
        getReferencedColumn: (t) => t.lessonPlanId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BibliographyTableAnnotationComposer(
              $db: $db,
              $table: $db.bibliography,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LessonPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonPlansTable,
    LessonPlan,
    $$LessonPlansTableFilterComposer,
    $$LessonPlansTableOrderingComposer,
    $$LessonPlansTableAnnotationComposer,
    $$LessonPlansTableCreateCompanionBuilder,
    $$LessonPlansTableUpdateCompanionBuilder,
    (LessonPlan, $$LessonPlansTableReferences),
    LessonPlan,
    PrefetchHooks Function({bool referenceNotesRefs, bool bibliographyRefs})> {
  $$LessonPlansTableTableManager(_$AppDatabase db, $LessonPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int?> gradeLevel = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String?> ilawContent = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              LessonPlansCompanion(
            id: id,
            title: title,
            gradeLevel: gradeLevel,
            subject: subject,
            ilawContent: ilawContent,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<int?> gradeLevel = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String?> ilawContent = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              LessonPlansCompanion.insert(
            id: id,
            title: title,
            gradeLevel: gradeLevel,
            subject: subject,
            ilawContent: ilawContent,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LessonPlansTable, LessonPlan>(table),
                    $$LessonPlansTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {referenceNotesRefs = false, bibliographyRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (referenceNotesRefs) db.referenceNotes,
                if (bibliographyRefs) db.bibliography
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (referenceNotesRefs)
                    await $_getPrefetchedData<LessonPlan, $LessonPlansTable,
                            ReferenceNote>(
                        currentTable: table,
                        referencedTable: $$LessonPlansTableReferences
                            ._referenceNotesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonPlansTableReferences(db, table, p0)
                                .referenceNotesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.lessonPlanId == item.id),
                        typedResults: items),
                  if (bibliographyRefs)
                    await $_getPrefetchedData<LessonPlan, $LessonPlansTable,
                            BibliographyData>(
                        currentTable: table,
                        referencedTable: $$LessonPlansTableReferences
                            ._bibliographyRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonPlansTableReferences(db, table, p0)
                                .bibliographyRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.lessonPlanId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LessonPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonPlansTable,
    LessonPlan,
    $$LessonPlansTableFilterComposer,
    $$LessonPlansTableOrderingComposer,
    $$LessonPlansTableAnnotationComposer,
    $$LessonPlansTableCreateCompanionBuilder,
    $$LessonPlansTableUpdateCompanionBuilder,
    (LessonPlan, $$LessonPlansTableReferences),
    LessonPlan,
    PrefetchHooks Function({bool referenceNotesRefs, bool bibliographyRefs})>;
typedef $$ReferenceNotesTableCreateCompanionBuilder = ReferenceNotesCompanion
    Function({
  Value<int> id,
  Value<int?> lessonPlanId,
  required String title,
  Value<String?> content,
  Value<DateTime> createdAt,
});
typedef $$ReferenceNotesTableUpdateCompanionBuilder = ReferenceNotesCompanion
    Function({
  Value<int> id,
  Value<int?> lessonPlanId,
  Value<String> title,
  Value<String?> content,
  Value<DateTime> createdAt,
});

final class $$ReferenceNotesTableReferences
    extends BaseReferences<_$AppDatabase, $ReferenceNotesTable, ReferenceNote> {
  $$ReferenceNotesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LessonPlansTable _lessonPlanIdTable(_$AppDatabase db) =>
      db.lessonPlans
          .createAlias('reference_notes__lesson_plan_id__lesson_plans__id');

  $$LessonPlansTableProcessedTableManager? get lessonPlanId {
    final $_column = $_itemColumn<int>('lesson_plan_id');
    if ($_column == null) return null;
    final manager = $$LessonPlansTableTableManager($_db, $_db.lessonPlans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonPlanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReferenceNotesTableFilterComposer
    extends Composer<_$AppDatabase, $ReferenceNotesTable> {
  $$ReferenceNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LessonPlansTableFilterComposer get lessonPlanId {
    final $$LessonPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonPlanId,
        referencedTable: $db.lessonPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonPlansTableFilterComposer(
              $db: $db,
              $table: $db.lessonPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReferenceNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReferenceNotesTable> {
  $$ReferenceNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LessonPlansTableOrderingComposer get lessonPlanId {
    final $$LessonPlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonPlanId,
        referencedTable: $db.lessonPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonPlansTableOrderingComposer(
              $db: $db,
              $table: $db.lessonPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReferenceNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReferenceNotesTable> {
  $$ReferenceNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LessonPlansTableAnnotationComposer get lessonPlanId {
    final $$LessonPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonPlanId,
        referencedTable: $db.lessonPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.lessonPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReferenceNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReferenceNotesTable,
    ReferenceNote,
    $$ReferenceNotesTableFilterComposer,
    $$ReferenceNotesTableOrderingComposer,
    $$ReferenceNotesTableAnnotationComposer,
    $$ReferenceNotesTableCreateCompanionBuilder,
    $$ReferenceNotesTableUpdateCompanionBuilder,
    (ReferenceNote, $$ReferenceNotesTableReferences),
    ReferenceNote,
    PrefetchHooks Function({bool lessonPlanId})> {
  $$ReferenceNotesTableTableManager(
      _$AppDatabase db, $ReferenceNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferenceNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferenceNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferenceNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> lessonPlanId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ReferenceNotesCompanion(
            id: id,
            lessonPlanId: lessonPlanId,
            title: title,
            content: content,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> lessonPlanId = const Value.absent(),
            required String title,
            Value<String?> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ReferenceNotesCompanion.insert(
            id: id,
            lessonPlanId: lessonPlanId,
            title: title,
            content: content,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ReferenceNotesTable, ReferenceNote>(table),
                    $$ReferenceNotesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonPlanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lessonPlanId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonPlanId,
                    referencedTable:
                        $$ReferenceNotesTableReferences._lessonPlanIdTable(db),
                    referencedColumn: $$ReferenceNotesTableReferences
                        ._lessonPlanIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReferenceNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReferenceNotesTable,
    ReferenceNote,
    $$ReferenceNotesTableFilterComposer,
    $$ReferenceNotesTableOrderingComposer,
    $$ReferenceNotesTableAnnotationComposer,
    $$ReferenceNotesTableCreateCompanionBuilder,
    $$ReferenceNotesTableUpdateCompanionBuilder,
    (ReferenceNote, $$ReferenceNotesTableReferences),
    ReferenceNote,
    PrefetchHooks Function({bool lessonPlanId})>;
typedef $$BibliographyTableCreateCompanionBuilder = BibliographyCompanion
    Function({
  Value<int> id,
  Value<int?> lessonPlanId,
  required String author,
  required String title,
  required int year,
  Value<String?> url,
  Value<DateTime> createdAt,
});
typedef $$BibliographyTableUpdateCompanionBuilder = BibliographyCompanion
    Function({
  Value<int> id,
  Value<int?> lessonPlanId,
  Value<String> author,
  Value<String> title,
  Value<int> year,
  Value<String?> url,
  Value<DateTime> createdAt,
});

final class $$BibliographyTableReferences extends BaseReferences<_$AppDatabase,
    $BibliographyTable, BibliographyData> {
  $$BibliographyTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonPlansTable _lessonPlanIdTable(_$AppDatabase db) =>
      db.lessonPlans
          .createAlias('bibliography__lesson_plan_id__lesson_plans__id');

  $$LessonPlansTableProcessedTableManager? get lessonPlanId {
    final $_column = $_itemColumn<int>('lesson_plan_id');
    if ($_column == null) return null;
    final manager = $$LessonPlansTableTableManager($_db, $_db.lessonPlans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonPlanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BibliographyTableFilterComposer
    extends Composer<_$AppDatabase, $BibliographyTable> {
  $$BibliographyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LessonPlansTableFilterComposer get lessonPlanId {
    final $$LessonPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonPlanId,
        referencedTable: $db.lessonPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonPlansTableFilterComposer(
              $db: $db,
              $table: $db.lessonPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BibliographyTableOrderingComposer
    extends Composer<_$AppDatabase, $BibliographyTable> {
  $$BibliographyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LessonPlansTableOrderingComposer get lessonPlanId {
    final $$LessonPlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonPlanId,
        referencedTable: $db.lessonPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonPlansTableOrderingComposer(
              $db: $db,
              $table: $db.lessonPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BibliographyTableAnnotationComposer
    extends Composer<_$AppDatabase, $BibliographyTable> {
  $$BibliographyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LessonPlansTableAnnotationComposer get lessonPlanId {
    final $$LessonPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonPlanId,
        referencedTable: $db.lessonPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.lessonPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BibliographyTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BibliographyTable,
    BibliographyData,
    $$BibliographyTableFilterComposer,
    $$BibliographyTableOrderingComposer,
    $$BibliographyTableAnnotationComposer,
    $$BibliographyTableCreateCompanionBuilder,
    $$BibliographyTableUpdateCompanionBuilder,
    (BibliographyData, $$BibliographyTableReferences),
    BibliographyData,
    PrefetchHooks Function({bool lessonPlanId})> {
  $$BibliographyTableTableManager(_$AppDatabase db, $BibliographyTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BibliographyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BibliographyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BibliographyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> lessonPlanId = const Value.absent(),
            Value<String> author = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BibliographyCompanion(
            id: id,
            lessonPlanId: lessonPlanId,
            author: author,
            title: title,
            year: year,
            url: url,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> lessonPlanId = const Value.absent(),
            required String author,
            required String title,
            required int year,
            Value<String?> url = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BibliographyCompanion.insert(
            id: id,
            lessonPlanId: lessonPlanId,
            author: author,
            title: title,
            year: year,
            url: url,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BibliographyTable, BibliographyData>(table),
                    $$BibliographyTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonPlanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lessonPlanId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonPlanId,
                    referencedTable:
                        $$BibliographyTableReferences._lessonPlanIdTable(db),
                    referencedColumn:
                        $$BibliographyTableReferences._lessonPlanIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BibliographyTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BibliographyTable,
    BibliographyData,
    $$BibliographyTableFilterComposer,
    $$BibliographyTableOrderingComposer,
    $$BibliographyTableAnnotationComposer,
    $$BibliographyTableCreateCompanionBuilder,
    $$BibliographyTableUpdateCompanionBuilder,
    (BibliographyData, $$BibliographyTableReferences),
    BibliographyData,
    PrefetchHooks Function({bool lessonPlanId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LessonPlansTableTableManager get lessonPlans =>
      $$LessonPlansTableTableManager(_db, _db.lessonPlans);
  $$ReferenceNotesTableTableManager get referenceNotes =>
      $$ReferenceNotesTableTableManager(_db, _db.referenceNotes);
  $$BibliographyTableTableManager get bibliography =>
      $$BibliographyTableTableManager(_db, _db.bibliography);
}
