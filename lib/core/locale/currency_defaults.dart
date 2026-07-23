import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Guesses an ISO 4217 currency code from a device locale — used to default
/// a new obligation's currency to whatever the user's region actually uses
/// instead of hardcoding USD.
///
/// This is a default, not a commitment: nothing stops a user from entering
/// a value in a different currency, and an obligation that already has a
/// value keeps its own currency regardless of what this returns.
abstract final class CurrencyDefaults {
  static String forDevice() {
    final tag = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    return forLocaleTag(tag);
  }

  static String forLocaleTag(String tag) {
    // NumberFormat.simpleCurrency resolves a currency from locale the same
    // way it decides symbol/placement for `simpleCurrency(name: ...)`
    // elsewhere in the app — reusing it here keeps the guess consistent
    // with how that money later gets displayed.
    final name = NumberFormat.simpleCurrency(locale: tag).currencyName;
    return name ?? 'USD';
  }
}
