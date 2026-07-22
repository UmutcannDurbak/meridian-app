import 'package:flutter/services.dart';

import '../../domain/entities/obligation.dart';

enum ExtractionTier { onDeviceModel, heuristic, unavailable }

class ExtractionCapabilities {
  const ExtractionCapabilities({
    required this.ocr,
    required this.onDeviceModel,
  });
  final bool ocr;
  final bool onDeviceModel;

  /// Shown verbatim in the capture UI. Users on this price tier will ask, and
  /// a vague answer costs more trust than an honest limitation.
  String get disclosure => onDeviceModel
      ? 'Read on this device. The document is not uploaded.'
      : 'Text read on this device. This device does not support on-device '
          'AI extraction, so some fields may need completing by hand. The '
          'document is still not uploaded.';
}

class ExtractionResult {
  const ExtractionResult({
    required this.title,
    required this.counterparty,
    required this.expiryDate,
    required this.noticeDays,
    required this.autoRenews,
    required this.amount,
    required this.currency,
    required this.tier,
    required this.confidence,
  });

  final String title;
  final String counterparty;
  final DateTime? expiryDate;
  final int noticeDays;
  final bool autoRenews;
  final double amount;
  final String currency;
  final ExtractionTier tier;
  final String confidence;

  /// Always produces a DRAFT. Extraction never creates a live obligation:
  /// a hallucinated or misread date that silently starts alerting is worse
  /// than no capture at all.
  Obligation toDraft(String id) => Obligation(
        id: id,
        title: title.isEmpty ? 'Untitled document' : title,
        category: ObligationCategory.contract,
        expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
        noticeDays: noticeDays,
        noticeDaysAssumed: noticeDays == 0,
        counterparty: counterparty.isEmpty ? null : counterparty,
        autoRenews: autoRenews,
        value: amount > 0 && currency.isNotEmpty
            ? Money((amount * 100).round(), currency)
            : null,
        status: ObligationStatus.draft,
        createdVia: CaptureSource.scan,
      );
}

/// Bridge to the native on-device pipeline. No network calls exist on either
/// side of this channel.
class ExtractionChannel {
  static const _c = MethodChannel('app.meridian/extraction');

  Future<ExtractionCapabilities> capabilities() async {
    try {
      final r = await _c.invokeMapMethod<String, dynamic>('capabilities');
      return ExtractionCapabilities(
        ocr: r?['ocr'] as bool? ?? false,
        onDeviceModel: r?['onDeviceModel'] as bool? ?? false,
      );
    } on MissingPluginException {
      // No iOS host implementation on this platform (e.g. the Android
      // emulator used for the Windows dev loop). Not an error — capture
      // just degrades to manual entry.
      return const ExtractionCapabilities(ocr: false, onDeviceModel: false);
    } on PlatformException {
      return const ExtractionCapabilities(ocr: false, onDeviceModel: false);
    }
  }

  Future<ExtractionResult?> extract(String path) async {
    try {
      final r = await _c.invokeMapMethod<String, dynamic>(
        'extract',
        {'path': path},
      );
      if (r == null) return null;

      final raw = r['expiryDate'] as String? ?? '';
      return ExtractionResult(
        title: r['title'] as String? ?? '',
        counterparty: r['counterparty'] as String? ?? '',
        expiryDate: raw.isEmpty ? null : DateTime.tryParse(raw),
        noticeDays: r['noticeDays'] as int? ?? 0,
        autoRenews: r['autoRenews'] as bool? ?? false,
        amount: (r['amount'] as num?)?.toDouble() ?? 0,
        currency: r['currency'] as String? ?? '',
        tier: switch (r['tier'] as String?) {
          'on_device_model' => ExtractionTier.onDeviceModel,
          'heuristic' => ExtractionTier.heuristic,
          _ => ExtractionTier.unavailable,
        },
        confidence: r['confidence'] as String? ?? 'none',
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
