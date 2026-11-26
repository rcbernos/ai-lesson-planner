import 'package:drift/drift.dart';

/// Table: lesson_plans
/// Stores generated and manually-created lesson plans following the ILAW format.
class LessonPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get gradeLevel => integer().nullable()();
  TextColumn get subject => text().nullable()();
  TextColumn get ilawContent => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// Table: reference_notes
/// Custom teacher reference notes attached to a lesson plan.
class ReferenceNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonPlanId => integer().nullable().references(
    LessonPlans,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get title => text()();
  TextColumn get content => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table: bibliography
/// Structured bibliography metadata (Author, Title, Year) per ILAW spec.
class Bibliography extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonPlanId => integer().nullable().references(
    LessonPlans,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get author => text()();
  TextColumn get title => text()();
  IntColumn get year => integer()();
  TextColumn get url => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table: chat_sessions
/// Stores chat conversations for guided slot-filling assistant.
class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get created => dateTime().withDefault(currentDateAndTime)();
  TextColumn get messages => text()(); // JSON array of ChatMessage
  TextColumn get header => text()(); // JSON PlanHeader
  TextColumn get grades => text()(); // JSON array of GradeInput
  TextColumn get sharedSubTheme => text()();
  TextColumn get multigradeModel => text()();
  TextColumn get outputLanguage => text()(); // 'filipino' or 'english'
}
