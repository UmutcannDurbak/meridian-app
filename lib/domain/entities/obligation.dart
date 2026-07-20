import 'package:meta/meta.dart';

enum ObligationCategory {
  contract,
  subscription,
  payment,
  insurance,
  licence,
  certification,
  maintenance,
  tax,
  warranty,
  document,
  commitment,
  other,
}

enum Criticality { routine, important, critical }

enum ObligationStatus {
  /// Window has not opened. Nothing to do yet.
  dormant,

  /// Inside the action window. This is where the product earns its money.
  actionable,

  /// Action deadline passed. If [Obligation.autoRenews], the user has now
  /// been committed to another term.
  lapsed,

  /// User acted in time.
  resolved,

  /// User explicitly decided this needs no action.
  dismissed,

  /// Extracted but not yet confirmed by a human. Never alerts, never counted
  /// as a real obligation, and never auto-deleted.
  draft,
}

@immutable
class Money {
  const Money(this.minorUnits, this.currency);
  final int minorUnits; // store money as integers, never doubles
  final String currency; // ISO 4217

  double get major => minorUnits / 100;
}

/// A dated commitment with a consequence.
///
/// The field that matters most here is [actionDeadline], which is derived,
/// not entered. A contract expiring 1 March with a 90-day cancellation clause
/// has a real deadline of 1 December — and 1 December is what the user must
/// see, everywhere, as the primary date. [expiryDate] is secondary information.
@immutable
class Obligation {
  const Obligation({
    required this.id,
    required this.title,
    required this.category,
    required this.expiryDate,
    this.noticeDays = 0,
    this.noticeDaysAssumed = false,
    this.counterparty,
    this.value,
    this.autoRenews = false,
    this.criticality = Criticality.important,
    this.status = ObligationStatus.dormant,
    this.recurrence,
    this.assigneeId,
    this.notes,
    this.attachmentIds = const [],
    this.createdVia = CaptureSource.manual,
  });

  final String id;
  final String title;
  final ObligationCategory category;

  /// When the thing itself ends.
  final DateTime expiryDate;

  /// Days of notice required before [expiryDate] to act.
  final int noticeDays;

  /// True when [noticeDays] came from a category default rather than from the
  /// document or the user. Must be surfaced in the UI — an assumed notice
  /// period that is wrong is the one way this product can actively harm a user.
  final bool noticeDaysAssumed;

  final String? counterparty;
  final Money? value;

  /// When true, inaction has a cost: the term renews by itself.
  final bool autoRenews;

  final Criticality criticality;
  final ObligationStatus status;
  final RecurrenceRule? recurrence;
  final String? assigneeId;
  final String? notes;
  final List<String> attachmentIds;
  final CaptureSource createdVia;

  /// The date the user must act by. Derived, indexed, and the primary sort
  /// key across the entire application.
  DateTime get actionDeadline =>
      expiryDate.subtract(Duration(days: noticeDays));

  /// The window opens when alerting begins and closes at [actionDeadline].
  ///
  /// Where a notice period exists the window is the notice period itself.
  /// Where none exists there is still a window — we open it a criticality-
  /// dependent lead time before expiry, because "no notice period" does not
  /// mean "no warning needed".
  DateTime get windowOpens {
    if (noticeDays > 0) return expiryDate.subtract(Duration(days: noticeDays));
    return expiryDate.subtract(Duration(days: _defaultLead));
  }

  int get _defaultLead => switch (criticality) {
        Criticality.critical => 90,
        Criticality.important => 30,
        Criticality.routine => 7,
      };

  /// For a notice-period obligation the window opens early and closes at the
  /// action deadline; the span between them is the decision period.
  DateTime get windowCloses => actionDeadline;

  /// How much of the decision window has been consumed, 0..1.
  /// Drives the single chromatic element in the UI.
  double pressureAt(DateTime now) {
    final open = noticeDays > 0
        ? expiryDate.subtract(Duration(days: noticeDays + _defaultLead))
        : windowOpens;
    final close = windowCloses;
    if (!now.isAfter(open)) return 0;
    if (!now.isBefore(close)) return 1;
    final total = close.difference(open).inSeconds;
    if (total <= 0) return 1;
    return now.difference(open).inSeconds / total;
  }

  int daysUntilAction(DateTime now) =>
      _dateOnly(actionDeadline).difference(_dateOnly(now)).inDays;

  bool isActionable(DateTime now) =>
      !now.isBefore(windowOpens) && now.isBefore(windowCloses);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Obligation copyWith({
    String? title,
    ObligationCategory? category,
    DateTime? expiryDate,
    int? noticeDays,
    bool? noticeDaysAssumed,
    String? counterparty,
    Money? value,
    bool? autoRenews,
    Criticality? criticality,
    ObligationStatus? status,
    RecurrenceRule? recurrence,
    String? assigneeId,
    String? notes,
    List<String>? attachmentIds,
  }) =>
      Obligation(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        expiryDate: expiryDate ?? this.expiryDate,
        noticeDays: noticeDays ?? this.noticeDays,
        noticeDaysAssumed: noticeDaysAssumed ?? this.noticeDaysAssumed,
        counterparty: counterparty ?? this.counterparty,
        value: value ?? this.value,
        autoRenews: autoRenews ?? this.autoRenews,
        criticality: criticality ?? this.criticality,
        status: status ?? this.status,
        recurrence: recurrence ?? this.recurrence,
        assigneeId: assigneeId ?? this.assigneeId,
        notes: notes ?? this.notes,
        attachmentIds: attachmentIds ?? this.attachmentIds,
        createdVia: createdVia,
      );
}

enum CaptureSource { manual, scan, share, import, calendar, template, natural }

enum Frequency { none, daily, weekly, monthly, quarterly, annual, custom }

@immutable
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
  });

  final Frequency frequency;
  final int interval;
  final DateTime? until;
  final int? count;
}
