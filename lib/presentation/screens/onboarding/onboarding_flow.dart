import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/onboarding_providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../widgets/pressable.dart';

/// Wraps [child] behind a one-time first-run walkthrough. Sits inside
/// [AppLockGate] in main.dart — a brand new install still authenticates
/// first if the lock is on, then sees this exactly once.
class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool? _seen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen =
        await ref.read(onboardingPreferenceProvider).hasSeenOnboarding();
    if (mounted) setState(() => _seen = seen);
  }

  Future<void> _complete() async {
    await ref.read(onboardingPreferenceProvider).setSeen(true);
    if (mounted) setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) {
    // Same principle as AppLockGate's checking splash: a blank paper-coloured
    // frame for the one frame this takes to load, never a spinner.
    if (_seen == null) return Container(color: context.tone.paper);
    if (!_seen!) return OnboardingWalkthrough(onDone: _complete);
    return widget.child;
  }
}

class _Step {
  const _Step(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _stepIcons = [
  CupertinoIcons.checkmark_seal,
  CupertinoIcons.list_bullet,
  CupertinoIcons.add_circled,
  CupertinoIcons.hand_draw,
  CupertinoIcons.calendar,
];

List<_Step> _stepsFor(AppStrings s) => [
      for (var i = 0; i < _stepIcons.length; i++)
        _Step(_stepIcons[i], s.onboardTitle(i + 1), s.onboardBody(i + 1)),
    ];

class OnboardingWalkthrough extends StatefulWidget {
  const OnboardingWalkthrough({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingWalkthrough> createState() => _OnboardingWalkthroughState();
}

class _OnboardingWalkthroughState extends State<OnboardingWalkthrough> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _stepIcons.length - 1;

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _controller.nextPage(duration: Motion.base, curve: Motion.easing);
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    final steps = _stepsFor(s);
    return Scaffold(
      backgroundColor: tone.paper,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: TextButton(
                  onPressed: _isLast ? null : widget.onDone,
                  child: Text(_isLast ? '' : s.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _StepView(step: steps[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.md,
                Space.xl,
                Space.xl,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        AnimatedContainer(
                          duration: Motion.base,
                          curve: Motion.easing,
                          margin: const EdgeInsets.symmetric(
                            horizontal: Space.xxs,
                          ),
                          width: i == _page ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page ? tone.ink : tone.hairline,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(
                        _isLast ? s.onboardingGetStarted : s.onboardingNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.surface,
              shape: BoxShape.circle,
              border: Border.all(color: tone.hairline),
            ),
            child: Icon(step.icon, size: 36, color: tone.ink),
          ),
          const SizedBox(height: Space.xl),
          Text(
            step.title,
            style: Type.title(tone.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          Text(
            step.body,
            style: Type.body(tone.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Small "Replay walkthrough" entry point for Settings — the first-run gate
/// only fires once, but a user who skipped it or just wants a refresher
/// should still be able to reach it deliberately.
class OnboardingReplayTile extends ConsumerWidget {
  const OnboardingReplayTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    return Pressable(
      onTap: () async {
        await ref.read(onboardingPreferenceProvider).setSeen(false);
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => OnboardingWalkthrough(
              onDone: () async {
                await ref.read(onboardingPreferenceProvider).setSeen(true);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: tone.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.paper,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(
                CupertinoIcons.hand_draw,
                size: 18,
                color: tone.inkMuted,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(s.replayWalkthrough, style: Type.heading(tone.ink)),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16, color: tone.inkFaint),
          ],
        ),
      ),
    );
  }
}
