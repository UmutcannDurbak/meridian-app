import 'package:drift/drift.dart';

/// Column-level mirror of [Obligation][1]. Enums are stored as their `name`
/// string rather than an index — index storage silently corrupts existing
/// rows the day someone reorders an enum, and this table holds the one thing
/// in the app users cannot afford to lose.
///
/// [1]: ../../domain/entities/obligation.dart
class ObligationRows extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get expiryDate => dateTime()();
  IntColumn get noticeDays => integer().withDefault(const Constant(0))();
  BoolColumn get noticeDaysAssumed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get counterparty => text().nullable()();

  // Money as integer minor units — never a float. See Obligation.value.
  IntColumn get valueMinorUnits => integer().nullable()();
  TextColumn get valueCurrency => text().nullable()();
  TextColumn get direction => text().withDefault(const Constant('expense'))();

  BoolColumn get autoRenews => boolean().withDefault(const Constant(false))();
  TextColumn get criticality =>
      text().withDefault(const Constant('important'))();
  TextColumn get status => text().withDefault(const Constant('dormant'))();

  TextColumn get recurrenceFrequency => text().nullable()();
  IntColumn get recurrenceInterval => integer().nullable()();
  DateTimeColumn get recurrenceUntil => dateTime().nullable()();
  IntColumn get recurrenceCount => integer().nullable()();

  TextColumn get assigneeId => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Set by a "Snooze" action; null means not currently snoozed. Deliberately
  /// its own column rather than a shift of [expiryDate] — see
  /// Obligation.snoozedUntil for why the two must never be conflated.
  DateTimeColumn get snoozedUntil => dateTime().nullable()();

  /// Comma-joined attachment ids. A join table is unwarranted while every
  /// attachment belongs to exactly one obligation and there is no attachment
  /// entity of its own yet.
  TextColumn get attachmentIds => text().withDefault(const Constant(''))();

  TextColumn get createdVia => text().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
