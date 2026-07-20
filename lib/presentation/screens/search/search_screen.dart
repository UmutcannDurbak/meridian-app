import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/services/search_service.dart';
import '../../widgets/obligation_row.dart';
import '../capture/obligation_form_screen.dart';

/// FR-404. Searches every obligation's title, counterparty, notes, and
/// category — see SearchService for what counts as a match. Tapping a
/// result opens it for editing.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final all = ref.watch(obligationListProvider).valueOrNull ?? const [];
    final now = ref.watch(nowProvider);
    final repo = ref.watch(obligationRepositoryProvider);
    final results = SearchService.search(all, _query);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search obligations',
            border: InputBorder.none,
          ),
          style: Type.body(tone.ink),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.clear),
              onPressed: () => setState(() {
                _controller.clear();
                _query = '';
              }),
            ),
        ],
      ),
      body: SafeArea(
        child: _query.isEmpty
            ? _Prompt(tone: tone)
            : results.isEmpty
                ? _NoResults(tone: tone, query: _query)
                : ListView.separated(
                    padding: const EdgeInsets.all(Space.md),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                    itemBuilder: (context, i) {
                      final o = results[i];
                      return ObligationRow(
                        obligation: o,
                        now: now,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ObligationFormScreen(existing: o),
                          ),
                        ),
                        onResolve: () => repo.resolve(o.id),
                        onSnooze: () =>
                            repo.snooze(o.id, const Duration(days: 7)),
                      );
                    },
                  ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.tone});
  final ToneScheme tone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, size: 32, color: tone.inkFaint),
            const SizedBox(height: Space.md),
            Text(
              'Search by title, counterparty, notes, or category.',
              style: Type.body(tone.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.tone, required this.query});
  final ToneScheme tone;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 32,
              color: tone.inkFaint,
            ),
            const SizedBox(height: Space.md),
            Text(
              'Nothing matches "$query".',
              style: Type.body(tone.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
