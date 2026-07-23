import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/onboarding_preference.dart';

final onboardingPreferenceProvider = Provider<OnboardingPreference>((ref) {
  return OnboardingPreference();
});
