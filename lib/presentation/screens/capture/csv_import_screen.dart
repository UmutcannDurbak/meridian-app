import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/services/csv_import.dart';

enum _Step { pickFile, mapping, preview }

/// FR-105 — bulk import from a spreadsheet. The onboarding strategy this
/// product actually depends on: a CFO with 200 obligations will populate
/// this from a file they already keep, not by typing 200 rows by hand.
///
/// Three steps: pick a .csv, map its columns to obligation fields, review
/// what will actually be created before committing. The mapping step exists
/// because guessing wrong on 200 rows silently is worse than asking once.
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  _Step _step = _Step.pickFile;
  String? _pickError;
  bool _picking = false;
  bool _saving = false;

  String _fileName = '';
  List<String> _headers = const [];
  List<List<Object?>> _dataRows = const [];

  String? _titleHeader;
  String? _dateHeader;
  String? _categoryHeader;
  String? _counterpartyHeader;
  String? _noticeDaysHeader;
  String? _valueHeader;
  String? _currencyHeader;
  String? _autoRenewsHeader;

  List<CsvImportRow> _rows = const [];

  bool get _mappingComplete => _titleHeader != null && _dateHeader != null;

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _pickError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _picking = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _picking = false;
          _pickError = 'Could not read that file.';
        });
        return;
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final table = const CsvToListConverter(shouldParseNumbers: false)
          .convert(text, eol: '\n');
      if (table.length < 2) {
        setState(() {
          _picking = false;
          _pickError = 'That file needs a header row and at least one row '
              'of data.';
        });
        return;
      }

      final headers = table.first.map((h) => '$h'.trim()).toList();
      setState(() {
        _picking = false;
        _fileName = file.name;
        _headers = headers;
        _dataRows = table.skip(1).toList();
        _titleHeader = _guess(headers, ['title', 'name', 'obligation']);
        _dateHeader = _guess(headers, [
          'expirydate',
          'expiry',
          'date',
          'duedate',
          'renewaldate',
        ]);
        _categoryHeader = _guess(headers, ['category', 'type']);
        _counterpartyHeader =
            _guess(headers, ['counterparty', 'vendor', 'provider', 'party']);
        _noticeDaysHeader = _guess(headers, ['noticedays', 'notice']);
        _valueHeader = _guess(headers, ['value', 'amount', 'price', 'cost']);
        _currencyHeader = _guess(headers, ['currency']);
        _autoRenewsHeader =
            _guess(headers, ['autorenew', 'autorenews', 'renews']);
        _step = _Step.mapping;
      });
    } catch (_) {
      setState(() {
        _picking = false;
        _pickError = 'Something went wrong reading that file.';
      });
    }
  }

  static String? _guess(List<String> headers, List<String> candidates) {
    for (final h in headers) {
      final normalized = h.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
      if (candidates.contains(normalized)) return h;
    }
    return null;
  }

  void _buildPreview() {
    final rows = CsvImportService.buildRows(
      headers: _headers,
      dataRows: _dataRows,
      mapping: CsvColumnMapping(
        title: _titleHeader!,
        expiryDate: _dateHeader!,
        category: _categoryHeader,
        counterparty: _counterpartyHeader,
        noticeDays: _noticeDaysHeader,
        value: _valueHeader,
        currency: _currencyHeader,
        autoRenews: _autoRenewsHeader,
      ),
      nextId: () => const Uuid().v4(),
    );
    setState(() {
      _rows = rows;
      _step = _Step.preview;
    });
  }

  Future<void> _confirmImport() async {
    final valid = _rows.where((r) => r.isValid).map((r) => r.obligation!);
    if (valid.isEmpty) return;

    setState(() => _saving = true);
    await ref.read(obligationRepositoryProvider).upsertAll(valid.toList());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import spreadsheet')),
      body: SafeArea(
        child: switch (_step) {
          _Step.pickFile => _PickFileStep(
              picking: _picking,
              error: _pickError,
              onPick: _pickFile,
            ),
          _Step.mapping => _MappingStep(
              fileName: _fileName,
              rowCount: _dataRows.length,
              headers: _headers,
              titleHeader: _titleHeader,
              dateHeader: _dateHeader,
              categoryHeader: _categoryHeader,
              counterpartyHeader: _counterpartyHeader,
              noticeDaysHeader: _noticeDaysHeader,
              valueHeader: _valueHeader,
              currencyHeader: _currencyHeader,
              autoRenewsHeader: _autoRenewsHeader,
              onChanged: (field, value) => setState(() {
                switch (field) {
                  case _Field.title:
                    _titleHeader = value;
                  case _Field.date:
                    _dateHeader = value;
                  case _Field.category:
                    _categoryHeader = value;
                  case _Field.counterparty:
                    _counterpartyHeader = value;
                  case _Field.noticeDays:
                    _noticeDaysHeader = value;
                  case _Field.value:
                    _valueHeader = value;
                  case _Field.currency:
                    _currencyHeader = value;
                  case _Field.autoRenews:
                    _autoRenewsHeader = value;
                }
              }),
              canContinue: _mappingComplete,
              onContinue: _buildPreview,
            ),
          _Step.preview => _PreviewStep(
              rows: _rows,
              saving: _saving,
              onConfirm: _confirmImport,
              onBack: () => setState(() => _step = _Step.mapping),
            ),
        },
      ),
    );
  }
}

enum _Field {
  title,
  date,
  category,
  counterparty,
  noticeDays,
  value,
  currency,
  autoRenews,
}

class _PickFileStep extends StatelessWidget {
  const _PickFileStep({
    required this.picking,
    required this.error,
    required this.onPick,
  });

  final bool picking;
  final String? error;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 48, color: tone.inkFaint),
            const SizedBox(height: Space.lg),
            Text(
              'Already keep a spreadsheet of contracts, renewals, or '
              'deadlines? Import it instead of typing everything by hand.',
              style: Type.body(tone.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              'CSV only for now — export from Excel or Sheets as CSV first.',
              style: Type.label(tone.inkFaint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xl),
            if (error != null) ...[
              Text(
                error!,
                style: Type.label(Pressure.closing),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.md),
            ],
            FilledButton.icon(
              onPressed: picking ? null : onPick,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(picking ? 'Reading…' : 'Choose a CSV file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MappingStep extends StatelessWidget {
  const _MappingStep({
    required this.fileName,
    required this.rowCount,
    required this.headers,
    required this.titleHeader,
    required this.dateHeader,
    required this.categoryHeader,
    required this.counterpartyHeader,
    required this.noticeDaysHeader,
    required this.valueHeader,
    required this.currencyHeader,
    required this.autoRenewsHeader,
    required this.onChanged,
    required this.canContinue,
    required this.onContinue,
  });

  final String fileName;
  final int rowCount;
  final List<String> headers;
  final String? titleHeader;
  final String? dateHeader;
  final String? categoryHeader;
  final String? counterpartyHeader;
  final String? noticeDaysHeader;
  final String? valueHeader;
  final String? currencyHeader;
  final String? autoRenewsHeader;
  final void Function(_Field field, String? value) onChanged;
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Text(
                '$fileName — $rowCount row${rowCount == 1 ? '' : 's'}',
                style: Type.label(tone.inkMuted),
              ),
              const SizedBox(height: Space.md),
              Text(
                'Match each column to a field. Title and date are required '
                '— everything else is optional.',
                style: Type.body(tone.inkMuted),
              ),
              const SizedBox(height: Space.lg),
              _headerDropdown(
                context,
                label: 'Title *',
                value: titleHeader,
                required: true,
                onChanged: (v) => onChanged(_Field.title, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Expiry date *',
                value: dateHeader,
                required: true,
                onChanged: (v) => onChanged(_Field.date, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Category',
                value: categoryHeader,
                onChanged: (v) => onChanged(_Field.category, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Counterparty',
                value: counterpartyHeader,
                onChanged: (v) => onChanged(_Field.counterparty, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Notice period (days)',
                value: noticeDaysHeader,
                onChanged: (v) => onChanged(_Field.noticeDays, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Value',
                value: valueHeader,
                onChanged: (v) => onChanged(_Field.value, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Currency',
                value: currencyHeader,
                onChanged: (v) => onChanged(_Field.currency, v),
              ),
              const SizedBox(height: Space.md),
              _headerDropdown(
                context,
                label: 'Renews automatically',
                value: autoRenewsHeader,
                onChanged: (v) => onChanged(_Field.autoRenews, v),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: FilledButton(
              onPressed: canContinue ? onContinue : null,
              child: const Text('Preview'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        if (!required) const DropdownMenuItem(child: Text('— None —')),
        for (final h in headers) DropdownMenuItem(value: h, child: Text(h)),
      ],
      onChanged: onChanged,
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.rows,
    required this.saving,
    required this.onConfirm,
    required this.onBack,
  });

  final List<CsvImportRow> rows;
  final bool saving;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final validCount = rows.where((r) => r.isValid).length;
    final invalidCount = rows.length - validCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  invalidCount == 0
                      ? '$validCount ready to import'
                      : '$validCount ready · $invalidCount need attention',
                  style: Type.heading(tone.ink),
                ),
              ),
              TextButton(onPressed: onBack, child: const Text('Edit mapping')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            itemCount: rows.length,
            separatorBuilder: (_, __) => Divider(color: tone.hairline, height: 1),
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  r.isValid ? Icons.check_circle_outline : Icons.error_outline,
                  color: r.isValid ? tone.inkMuted : Pressure.closing,
                  size: 20,
                ),
                title: Text(
                  r.isValid ? r.obligation!.title : 'Row ${r.rowNumber}',
                  style: Type.body(tone.ink),
                ),
                subtitle: Text(
                  r.isValid
                      ? 'Expires '
                          '${r.obligation!.expiryDate.toIso8601String().split('T').first}'
                      : r.error!,
                  style: Type.label(
                    r.isValid ? tone.inkMuted : Pressure.closing,
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: FilledButton(
              onPressed: (validCount == 0 || saving) ? null : onConfirm,
              child: Text(
                saving ? 'Importing…' : 'Import $validCount obligation${validCount == 1 ? '' : 's'}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
