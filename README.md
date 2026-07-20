# Meridian

Obligation and deadline intelligence for people who carry more commitments
than they can hold in their head.

Most reminder apps track **when something ends**. Meridian tracks **when you
must act** — a contract expiring 1 March with a 90-day cancellation clause has
a real deadline of 1 December, and 1 December is what the product shows you.

---

## Status

Early scaffold. Domain logic, design system, and the on-device extraction
channel are implemented. Persistence, sync, auth, payments and most screens are
not. **This code has not been compiled** — it was authored without a Flutter
SDK available. Expect to fix package version drift on first `pub get`.

---

## Setup on Windows

```bash
flutter pub get
flutter gen-l10n
flutter test
flutter run          # Android emulator — validates ~90% of behaviour
```

You cannot build for iOS locally. Push to `main` and Codemagic produces a
TestFlight build you install on your iPhone over the air. See `codemagic.yaml`.

---

## Architecture

```
lib/
  core/theme/       design tokens, type scale, ThemeExtension
  core/l10n/        ARB translation files
  domain/           entities and pure services — no Flutter imports
  application/      Riverpod providers, use cases
  data/             channels, repositories, persistence
  presentation/     screens and widgets
```

Dependencies point inward. `domain/` must never import Flutter — that is what
keeps the date logic, which is the risky part of this product, unit-testable.

### Rules that are not negotiable

1. **Never call `DateTime.now()` outside `nowProvider`.** This app is almost
   entirely time-dependent behaviour; a direct clock call makes it untestable.
2. **Never advance a recurrence from the previous occurrence.** Always compute
   from the original seed. See `recurrence_engine.dart` — drift is cumulative
   and invisible until a user misses a deadline a year later.
3. **Money is `int` minor units.** Never `double`.
4. **Extraction always produces a draft.** A misread date that silently starts
   alerting is worse than no capture at all.
5. **Colour appears only in the pressure ramp.** If colour shows up anywhere
   else in the UI, that is a bug.

---

## Privacy architecture

The product's core promise is that contracts do not leave the device.

```
photo/PDF ──► Vision OCR (on-device)
                    │
                    ├─ iOS 26 + Apple Intelligence
                    │     └─► Foundation Models structured extraction (on-device)
                    │
                    └─ otherwise
                          └─► NSDataDetector + pattern heuristics (on-device)
                                        │
                                        ▼
                            metadata only ──► encrypted sync
                            document file ──► stays local
```

No network call exists on either side of the extraction channel. This is
verifiable by reading `ios/Runner/DocumentExtraction.swift`, and that
verifiability is the point — this audience will ask.

The capability tier is reported to the UI and shown to the user. Do not hide
it. Someone who believes they have AI extraction but silently gets regex will
blame the product for the miss.

---

## Global launch — compliance

Shipping worldwide from day one means the strictest rule applies everywhere.

| Area | Approach |
|---|---|
| Privacy law | Build to **GDPR**. It is the strictest of GDPR / KVKK / CCPA, and satisfying it substantially covers the others. Turkey's KVKK adds VERBIS registration once you cross its thresholds. |
| Data residency | EU users' data in an EU region. Supabase and most providers support region pinning at project creation — you cannot change it later, so decide before the first row is written. |
| Processors | A signed DPA with every subprocessor, and a public subprocessor list. On-device extraction removes the hardest one from that list entirely. |
| EU representative | Required under GDPR Art. 27 for a Turkey-based controller offering services into the EU. |
| Consent | Granular, no pre-ticked boxes, withdrawal as easy as granting. |
| DSR | Export and erasure available in-app, honoured within 30 days. |
| Pricing | App Store Connect handles per-storefront conversion, but review the auto-generated tiers — the algorithmic price for Turkey and India will be wrong for a premium product. Set those manually. |
| Payments | Region-aware paywall behind remote config. External checkout links are US-storefront only; showing them elsewhere is a guideline violation. |
| Locales | Ship EN + TR at v1. Availability is global; localisation does not have to be. |

---

## Roadmap

- [x] Design tokens and theme
- [x] Obligation model, notice-period derivation
- [x] Recurrence engine with month-end and leap-year handling
- [x] Alert scheduling
- [x] On-device extraction channel
- [x] Horizon screen
- [ ] Persistence (drift) and offline queue
- [ ] Auth — Sign in with Apple, in-app account deletion
- [ ] Capture flows: scan, share extension, CSV import, templates
- [ ] Draft review screen
- [ ] Timeline and Exposure views
- [ ] Notifications wiring, server-side scheduling
- [ ] Delegation
- [ ] Payments — RevenueCat, server entitlements, region-aware paywall
- [ ] Privacy manifest audit across all dependencies
- [ ] Accessibility pass
