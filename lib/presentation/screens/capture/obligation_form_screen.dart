import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/obligation.dart';

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
  late bool _autoRenews;
  late bool _detailsExpanded;
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
    _autoRenews = d?.autoRenews ?? false;
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
          ? Money((amount * 100).round(), source?.value?.currency ?? 'USD')
          : null,
      autoRenews: _autoRenews,
      criticality: _criticality,
      // A confirmed draft is always dormant (newly live). An edit preserves
      // whatever status the obligation already had — this form has no
      // status field of its own to change it deliberately. A fresh manual
      // entry has no source, so it defaults to dormant too.
      status: _isReview
          ? ObligationStatus.dormant
          : (source?.status ?? ObligationStatus.dormant),
      recurrence: source?.recurrence,
      assigneeId: source?.assigneeId,
      notes: source?.notes,
      attachmentIds: source?.attachmentIds ?? const [],
      createdVia: source?.createdVia ?? CaptureSource.manual,
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
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(Radii.sm),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry date',
                    errorText: _dateError,
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
                    decoration: const InputDecoration(labelText: 'Value (USD)'),
                  ),
                  const SizedBox(height: Space.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Renews automatically'),
                    value: _autoRenews,
                    onChanged: (v) => setState(() => _autoRenews = v),
                  ),
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
          Icon(Icons.lock_outline, size: 16, color: tone.inkMuted),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: Type.label(tone.inkMuted))),
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
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              children: [
                Text('More details', style: Type.label(tone.inkMuted)),
                const SizedBox(width: Space.xxs),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
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
