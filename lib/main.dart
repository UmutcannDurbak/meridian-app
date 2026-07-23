import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/theme/theme.dart';
import 'presentation/screens/app_lock_gate.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/notification_scheduler.dart';
import 'presentation/screens/onboarding/onboarding_flow.dart';

void main() {
  // obligationRepositoryProvider self-constructs its backing store on first
  // read (the real database on io platforms, an in-memory one on web) — see
  // data/repositories/repository_provider.dart. No override needed here;
  // only tests override it, with an in-memory test database.
  runApp(const ProviderScope(child: MeridianApp()));
}

class MeridianApp extends StatelessWidget {
  const MeridianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meridian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // No explicit `locale:` — leaving it unset means Flutter resolves the
      // active locale from the device's own language settings against
      // supportedLocales below, which is exactly "app language follows
      // device language" with no extra plumbing needed.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
      ],
      // Date and currency formatting flow from this via intl — but only if
      // something actually sets Intl.defaultLocale, which nothing did
      // before _LocaleSync. Without it every DateFormat/NumberFormat call
      // in the app quietly formats as en_US no matter the device's real
      // locale, regardless of what supportedLocales declares.
      builder: (context, child) => _LocaleSync(child: child!),
      home: const AppLockGate(
        child: NotificationScheduler(
          child: OnboardingGate(child: AppShell()),
        ),
      ),
    );
  }
}

/// Keeps `package:intl`'s ambient default locale in sync with the device's
/// real locale (region included, e.g. `en_GB` vs `en_US`) — not the
/// resolved UI [Locale], which only carries a language code since
/// [MeridianApp.supportedLocales] has no region variants. Money and dates
/// should follow the device's actual regional settings even when the UI
/// text itself falls back to English.
class _LocaleSync extends StatefulWidget {
  const _LocaleSync({required this.child});
  final Widget child;

  @override
  State<_LocaleSync> createState() => _LocaleSyncState();
}

class _LocaleSyncState extends State<_LocaleSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) => _sync();

  void _sync() {
    final tag = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    if (Intl.defaultLocale != tag) {
      setState(() => Intl.defaultLocale = tag);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
