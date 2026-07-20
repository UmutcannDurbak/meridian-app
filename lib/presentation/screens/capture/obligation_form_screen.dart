import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/obligation.dart';

/// Manual entry and draft review share this screen — the only difference is
/// what pre-fills the fields and what the primary action does.
///
/// FR-103: title and date are the only required fields, and the form must be
/// completable in under 10 seconds, so everything else starts collapsed
/// behind "More details". In review mode there is already a draft on record
/// (see UC-01), so the details start expanded for verification instead.
class ObligationFormScreen extends ConsumerStatefulWidget {
  const ObligationFormScreen({
    super.key,
    this.draft,
    this.extractionDisclosure,
  });

  /// When set, the screen opens in draft-review mode: fields pre-filled from
  /// extraction, the row already persisted as [ObligationStatus.draft], and
  /// the primary action confirms it into a live obligation rather than
  /// creating a new one.
  final Obligation? draft;

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

  bool get _isReview => widget.draft != null;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
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
    // Review mode: show everything up front for verification. Manual entry:
    // stay collapsed so the common case is title + date and nothing else.
    _detailsExpanded = _isReview;
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

    final draft = widget.draft;
    final amount = double.tryParse(_amount.text.trim());
    final notice = int.tryParse(_noticeDays.text.trim()) ?? 0;

    final obligation = Obligation(
      id: draft?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      category: _category,
      expiryDate: _expiryDate!,
      noticeDays: notice,
      // Carried forward rather than reset: if extraction assumed a category
      // default and the user hasn't corrected it, the tag stays honest.
      noticeDaysAssumed: draft?.noticeDaysAssumed ?? false,
      counterparty:
          _counterparty.text.trim().isEmpty ? null : _counterparty.text.trim(),
      value: amount != null && amount > 0
          ? Money((amount * 100).round(), draft?.value?.currency ?? 'USD')
          : null,
      autoRenews: _autoRenews,
      criticality: _criticality,
      status: ObligationStatus.dormant,
      recurrence: draft?.recurrence,
      assigneeId: draft?.assigneeId,
      notes: draft?.notes,
      attachmentIds: draft?.attachmentIds ?? const [],
      createdVia: draft?.createdVia ?? CaptureSource.manual,
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
        title: Text(_isReview ? 'Review draft' : 'New obligation'),
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
                autofocus: !_isReview,
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
                        DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
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

  static String _categoryLabel(ObligationCategory c) => switch (c) {
        ObligationCategory.contract => 'Contract',
        ObligationCategory.subscription => 'Subscription',
        ObligationCategory.payment => 'Payment',
        ObligationCategory.insurance => 'Insurance',
        ObligationCategory.licence => 'Licence / permit',
        ObligationCategory.certification => 'Certification',
        ObligationCategory.maintenance => 'Maintenance',
        ObligationCategory.tax => 'Tax / filing',
        ObligationCategory.warranty => 'Warranty',
        ObligationCategory.document => 'Document',
        ObligationCategory.commitment => 'Meeting / commitment',
        ObligationCategory.other => 'Other',
      };
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
