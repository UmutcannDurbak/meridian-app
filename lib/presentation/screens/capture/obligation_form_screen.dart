import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/locale/currency_defaults.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/obligation.dart';
import '../../../domain/services/recurrence_engine.dart';
import '../../widgets/pressable.dart';

/// Manual entry, draft review, and editing an existing obligation (e.g. from
/// search) share this screen — the only difference is what pre-fills the
/// fields, what the primary action does, and what happens to status on save.
///
/// FR-103: title and date are the only required fields, and the form must be
/// completable in under 10 seconds, so everything else starts collapsed
/// behind "More details" for a fresh manual entry. Review and edit both
/// start expanded — there's already real data worth looking at.
class ObligationFormScreen extends ConsumerStatefulWidget {
  const ObligationFormScreen({
    super.key,
    this.draft,
    this.existing,
    this.extractionDisclosure,
  }) : assert(
          draft == null || existing == null,
          'pass draft or existing, not both',
        );

  /// When set, the screen opens in draft-review mode: fields pre-filled from
  /// extraction, the row already persisted as [ObligationStatus.draft], and
  /// the primary action confirms it into a live obligation — always
  /// [ObligationStatus.dormant] — rather than creating a new one.
  final Obligation? draft;

  /// When set, the screen opens in edit mode for an already-live obligation
  /// (e.g. tapped from search): fields pre-filled, and saving preserves its
  /// existing status rather than forcing one.
  final Obligation? existing;

  /// Shown as a banner in review mode. See ExtractionCapabilities.disclosure.
  final String? extractionDisclosure;

  @override
  ConsumerState<ObligationFormScreen> createState() =>
      _ObligationFormScreenState();
}

class _ObligationFormScreenState extends ConsumerState<ObligationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _counterparty;
  late final TextEditingController _noticeDays;
  late final TextEditingController _amount;
  DateTime? _expiryDate;
  late ObligationCategory _category;
  late Criticality _criticality;
  late MoneyDirection _direction;
  late bool _autoRenews;
  late bool _detailsExpanded;
  /// Currency for a value entered on this obligation. Whatever it already
  /// has wins; a brand new obligation defaults to the device's own currency
  /// rather than always assuming USD.
  late String _currency;

  /// Only meaningful, and only shown, while [_autoRenews] is on — how often
  /// the term renews. Defaults to monthly, the most common case, but the
  /// user picks it explicitly rather than the app leaving it undefined.
  late Frequency _recurrenceFrequency;
  late int _recurrenceInterval;
  bool _saving = false;
  String? _dateError;

  Obligation? get _source => widget.draft ?? widget.existing;
  bool get _isReview => widget.draft != null;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = _source;
    _title = TextEditingController(text: d?.title ?? '');
    _counterparty = TextEditingController(text: d?.counterparty ?? '');
    _noticeDays = TextEditingController(
      text: d != null && d.noticeDays > 0 ? '${d.noticeDays}' : '',
    );
    _amount = TextEditingController(
      text: d?.value != null ? d!.value!.major.toStringAsFixed(2) : '',
    );
    _expiryDate = d?.expiryDate;
    _category = d?.category ?? ObligationCategory.contract;
    _criticality = d?.criticality ?? Criticality.important;
    _direction = d?.direction ?? MoneyDirection.expense;
    _autoRenews = d?.autoRenews ?? false;
    _currency = d?.value?.currency ?? CurrencyDefaults.forDevice();
    _recurrenceFrequency = d?.recurrence?.frequency ?? Frequency.monthly;
    _recurrenceInterval = d?.recurrence?.interval ?? 1;
    // Review and edit: show everything up front, there's real data worth
    // seeing. Fresh manual entry stays collapsed — title + date and nothing
    // else is the common case.
    _detailsExpanded = _isReview || _isEdit;
  }

  @override
  void dispose() {
    _title.dispose();
    _counterparty.dispose();
    _noticeDays.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(nowProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (_expiryDate == null) {
      setState(() => _dateError = 'Required');
    }
    if (!formOk || _expiryDate == null) return;

    setState(() => _saving = true);

    final source = _source;
    final amount = double.tryParse(_amount.text.trim());
    final notice = int.tryParse(_noticeDays.text.trim()) ?? 0;

    final obligation = Obligation(
      id: source?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      category: _category,
      expiryDate: _expiryDate!,
      noticeDays: notice,
      // Carried forward rather than reset: if extraction assumed a category
      // default and the user hasn't corrected it, the tag stays honest.
      noticeDaysAssumed: source?.noticeDaysAssumed ?? false,
      counterparty:
          _counterparty.text.trim().isEmpty ? null : _counterparty.text.trim(),
      value: amount != null && amount > 0
          ? Money((amount * 100).round(), _currency)
          : null,
      direction: _direction,
      autoRenews: _autoRenews,
      criticality: _criticality,
      // A confirmed draft is always dormant (newly live). An edit preserves
      // whatever status the obligation already had — this form has no
      // status field of its own to change it deliberately. A fresh manual
      // entry has no source, so it defaults to dormant too.
      status: _isReview
          ? ObligationStatus.dormant
          : (source?.status ?? ObligationStatus.dormant),
      // Only meaningful for an auto-renewing obligation — turning the
      // switch off drops whatever period was picked rather than leaving a
      // stale rule attached to something that no longer renews.
      recurrence: _autoRenews
          ? RecurrenceRule(
              frequency: _recurrenceFrequency,
              interval: _recurrenceInterval,
            )
          : null,
      assigneeId: source?.assigneeId,
      notes: source?.notes,
      attachmentIds: source?.attachmentIds ?? const [],
      createdVia: source?.createdVia ?? CaptureSource.manual,
      snoozedUntil: source?.snoozedUntil,
    );

    await ref.read(obligationRepositoryProvider).upsert(obligation);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReview
              ? 'Review draft'
              : (_isEdit ? 'Edit obligation' : 'New obligation'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              if (widget.extractionDisclosure != null) ...[
                _DisclosureBanner(text: widget.extractionDisclosure!),
                const SizedBox(height: Space.md),
              ],
              TextFormField(
                controller: _title,
                autofocus: !_isReview && !_isEdit,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Space.md),
              Pressable(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry date',
                    errorText: _dateError,
                    suffixIcon: Icon(
                      CupertinoIcons.calendar,
                      size: 18,
                      color: tone.inkMuted,
                    ),
                  ),
                  child: Text(
                    _expiryDate == null
                        ? 'Select a date'
                        : DateFormat.yMMMd().format(_expiryDate!),
                    style: Type.body(
                      _expiryDate == null ? tone.inkFaint : tone.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              _MoreDetails(
                expanded: _detailsExpanded,
                onToggle: () =>
                    setState(() => _detailsExpanded = !_detailsExpanded),
                children: [
                  DropdownButtonFormField<ObligationCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c in ObligationCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                  const SizedBox(height: Space.md),
                  TextFormField(
                    controller: _counterparty,
                    decoration:
                        const InputDecoration(labelText: 'Counterparty'),
                  ),
                  const SizedBox(height: Space.md),
                  TextFormField(
                    controller: _noticeDays,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Notice period (days)',
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Value ($_currency)'),
                  ),
                  const SizedBox(height: Space.md),
                  SegmentedButton<MoneyDirection>(
                    segments: const [
                      ButtonSegment(
                        value: MoneyDirection.expense,
                        label: Text('You pay'),
                      ),
                      ButtonSegment(
                        value: MoneyDirection.income,
                        label: Text('You receive'),
                      ),
                    ],
                    selected: {_direction},
                    onSelectionChanged: (s) =>
                        setState(() => _direction = s.first),
                  ),
                  const SizedBox(height: Space.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Renews automatically'),
                    value: _autoRenews,
                    onChanged: (v) => setState(() => _autoRenews = v),
                  ),
                  if (_autoRenews) ...[
                    const SizedBox(height: Space.sm),
                    _RecurrencePicker(
                      frequency: _recurrenceFrequency,
                      interval: _recurrenceInterval,
                      onFrequencyChanged: (f) =>
                          setState(() => _recurrenceFrequency = f),
                      onIntervalChanged: (i) =>
                          setState(() => _recurrenceInterval = i),
                      previewAnchor: _expiryDate,
                    ),
                  ],
                  const SizedBox(height: Space.md),
                  SegmentedButton<Criticality>(
                    segments: const [
                      ButtonSegment(
                        value: Criticality.routine,
                        label: Text('Routine'),
                      ),
                      ButtonSegment(
                        value: Criticality.important,
                        label: Text('Important'),
                      ),
                      ButtonSegment(
                        value: Criticality.critical,
                        label: Text('Critical'),
                      ),
                    ],
                    selected: {_criticality},
                    onSelectionChanged: (s) =>
                        setState(() => _criticality = s.first),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(
                  _saving ? 'Saving…' : (_isReview ? 'Confirm' : 'Save'),
                ),
              ),
              const SizedBox(height: Space.xxl),
            ],
          ),
        ),
      ),
    );
  }

}

class _DisclosureBanner extends StatelessWidget {
  const _DisclosureBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tone.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.lock, size: 16, color: tone.inkMuted),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: Type.label(tone.inkMuted))),
        ],
      ),
    );
  }
}

/// Frequency + interval for an auto-renewing obligation, plus a live preview
/// of when the next renewal actually lands — e.g. "monthly" against an
/// expiry of 4 Aug reads as "next renewal: 4 Sep" here, not left implicit.
class _RecurrencePicker extends StatelessWidget {
  const _RecurrencePicker({
    required this.frequency,
    required this.interval,
    required this.onFrequencyChanged,
    required this.onIntervalChanged,
    required this.previewAnchor,
  });

  final Frequency frequency;
  final int interval;
  final ValueChanged<Frequency> onFrequencyChanged;
  final ValueChanged<int> onIntervalChanged;

  /// The obligation's expiry date, if picked yet — the preview has nothing
  /// to anchor to until it is.
  final DateTime? previewAnchor;

  static const _options = [
    Frequency.weekly,
    Frequency.monthly,
    Frequency.quarterly,
    Frequency.annual,
    Frequency.custom,
  ];

  static String _label(Frequency f) => switch (f) {
        Frequency.weekly => 'Weekly',
        Frequency.monthly => 'Monthly',
        Frequency.quarterly => 'Quarterly',
        Frequency.annual => 'Annually',
        Frequency.custom => 'Custom (days)',
        Frequency.daily => 'Daily',
        Frequency.none => 'None',
      };

  /// What the interval stepper counts in, e.g. "Every 2 [weeks]".
  static String _unit(Frequency f, int interval) {
    final plural = interval != 1;
    return switch (f) {
      Frequency.weekly => plural ? 'weeks' : 'week',
      Frequency.monthly => plural ? 'months' : 'month',
      Frequency.quarterly => plural ? 'quarters' : 'quarter',
      Frequency.annual => plural ? 'years' : 'year',
      Frequency.custom => plural ? 'days' : 'day',
      Frequency.daily => plural ? 'days' : 'day',
      Frequency.none => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final anchor = previewAnchor;
    final next = anchor == null
        ? null
        : RecurrenceEngine.next(
            anchor,
            RecurrenceRule(frequency: frequency, interval: interval),
            anchor,
          );

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: tone.paper,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tone.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Renewal period', style: Type.label(tone.inkMuted)),
          const SizedBox(height: Space.sm),
          DropdownButtonFormField<Frequency>(
            initialValue: frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: [
              for (final f in _options)
                DropdownMenuItem(value: f, child: Text(_label(f))),
            ],
            onChanged: (v) {
              if (v != null) onFrequencyChanged(v);
            },
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Text('Every', style: Type.body(tone.ink)),
              const SizedBox(width: Space.sm),
              _Stepper(
                value: interval,
                onChanged: onIntervalChanged,
              ),
              const SizedBox(width: Space.sm),
              Text(_unit(frequency, interval), style: Type.body(tone.ink)),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Next renewal: ${DateFormat.yMMMd().format(next)}',
              style: Type.label(tone.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const _min = 1;
  static const _max = 30;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tone.hairline),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.minus, size: 16),
            onPressed: value > _min ? () => onChanged(value - 1) : null,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Type.body(tone.ink),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.plus, size: 16),
            onPressed: value < _max ? () => onChanged(value + 1) : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MoreDetails extends StatelessWidget {
  const _MoreDetails({
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              children: [
                Text('More details', style: Type.label(tone.inkMuted)),
                const SizedBox(width: Space.xxs),
                Icon(
                  expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  size: 14,
                  color: tone.inkMuted,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: Motion.base,
          sizeCurve: Motion.easing,
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
