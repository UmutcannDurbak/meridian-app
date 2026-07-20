import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../application/obligation_providers.dart';
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
      );
      if (file == null) {
        if (mounted) setState(() => _working = false);
        return;
      }

      final capabilities = await _extraction.capabilities();
      final result = await _extraction.extract(file.path);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _working = false;
          _error = capabilities.ocr
              ? 'Could not read that document. Try a clearer photo, or add '
                  'it manually.'
              : 'On-device extraction is not available on this device. You '
                  'can still add it manually.';
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
        _error = 'Something went wrong reading that document.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a document')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 48,
                color: tone.inkFaint,
              ),
              const SizedBox(height: Space.lg),
              Text(
                'Photograph a contract, invoice, or renewal notice.',
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
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_working ? 'Reading…' : 'Take photo'),
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton.icon(
                onPressed: _working
                    ? null
                    : () => _pickAndExtract(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from library'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
