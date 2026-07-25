import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/local/extraction_channel.dart';
import 'obligation_form_screen.dart';

/// Photograph a document, extract it on-device, hand off to review.
///
/// Nothing here calls the network — see ios/Runner/DocumentExtraction.swift.
/// The photo is read locally by Vision/Foundation Models; only the resulting
/// draft obligation (title, dates, amount) is ever persisted, and even that
/// stays local until the user confirms it on the review screen.
class ScanCaptureScreen extends ConsumerStatefulWidget {
  const ScanCaptureScreen({super.key});

  @override
  ConsumerState<ScanCaptureScreen> createState() => _ScanCaptureScreenState();
}

class _ScanCaptureScreenState extends ConsumerState<ScanCaptureScreen> {
  final _extraction = ExtractionChannel();
  bool _working = false;
  String? _error;

  Future<void> _pickAndExtract(ImageSource source) async {
    setState(() {
      _working = true;
      _error = null;
    });

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        // A modern phone camera photo is easily 4000x3000+ pixels.
        // Decoding that at full resolution on the native side (see
        // DocumentExtraction.kt) risks an OutOfMemoryError on real hardware
        // — an emulator or a downsized gallery test image won't reproduce
        // it, which is exactly the kind of gap between "works on my dev
        // loop" and "fails on device". Capping here means the file written
        // to disk is already a size OCR doesn't need more than anyway.
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (file == null) {
        if (mounted) setState(() => _working = false);
        return;
      }

      final capabilities = await _extraction.capabilities();
      final result = await _extraction.extract(file.path);

      if (!mounted) return;

      if (result == null) {
        final s = AppStrings.of(context);
        setState(() {
          _working = false;
          _error = capabilities.ocr
              ? s.scanErrorUnreadable
              : s.scanErrorUnavailable;
        });
        return;
      }

      // Persisted immediately as a draft: an unconfirmed capture must never
      // be lost, even if the user backs out of the review screen. See
      // ObligationStatus.draft and UC-01.
      final draft = result.toDraft(const Uuid().v4());
      await ref.read(obligationRepositoryProvider).upsert(draft);

      if (!mounted) return;
      setState(() => _working = false);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ObligationFormScreen(
            draft: draft,
            extractionDisclosure: capabilities.disclosure,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = AppStrings.of(context).scanErrorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.captureScanTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.doc_text_viewfinder,
                size: 48,
                color: tone.inkFaint,
              ),
              const SizedBox(height: Space.lg),
              Text(
                s.scanPrompt,
                style: Type.body(tone.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xl),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: Type.label(Pressure.closing),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.md),
              ],
              FilledButton.icon(
                onPressed:
                    _working ? null : () => _pickAndExtract(ImageSource.camera),
                icon: const Icon(CupertinoIcons.camera),
                label: Text(_working ? s.scanReading : s.scanTakePhoto),
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton.icon(
                onPressed: _working
                    ? null
                    : () => _pickAndExtract(ImageSource.gallery),
                icon: const Icon(CupertinoIcons.photo_on_rectangle),
                label: Text(s.scanChooseLibrary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
