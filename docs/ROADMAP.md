# iOS Application — Roadmap & Software Requirements Specification

**Build path:** Flutter (Windows-based development)
**Scope:** v1 with full backend + payments
**Document status:** DRAFT v0.1 — app-specific sections pending product definition
**Date:** July 2026

---

## PART 0 — THE WINDOWS CONSTRAINT (read first)

### What you can do on Windows
- 100% of Dart/Flutter code authoring
- Android emulator testing (validates ~90% of your logic and UI)
- Backend development, API work, database, admin tooling
- Unit, widget, and integration tests
- Git, CI configuration, design work, asset production

### What you cannot do on Windows
- Run the iOS Simulator
- Compile, sign, archive, or notarize an iOS build
- Upload to App Store Connect
- Debug iOS-only rendering or platform-channel issues locally

### The bridge: cloud macOS
You never need to own a Mac, but you need to rent CPU time on one.

| Option | Cost | Best for |
|---|---|---|
| **Codemagic** | Free tier (500 min/mo), then ~$0.095/min | Recommended. Flutter-native, YAML config, direct TestFlight upload |
| **GitHub Actions** (macos runners) | Free for public repos; paid minutes private | Teams already on GitHub, more setup work |
| **Bitrise** | Free tier, paid from ~$40/mo | Larger teams, more integrations |
| **MacinCloud / MacStadium** | ~$25–70/mo | When you need interactive Xcode/Simulator debugging |

**Recommended combination:** Codemagic for all routine builds and TestFlight delivery, plus a short-term MacinCloud rental during the two weeks before launch for interactive debugging of iOS-only issues.

### Physical device testing
You have an iPhone — that is enough. Install builds via **TestFlight**, which is delivered over the air from App Store Connect. No cable, no Mac, no Xcode required on your end. This is your primary iOS testing loop.

### Critical practice
Test on a real iOS device **early and continuously**, not at the end. Flutter is highly consistent across platforms but not perfectly so. Recurring divergences: safe-area and notch/Dynamic Island handling, keyboard inset behavior, scroll physics, font rendering and baseline metrics, back-gesture behavior, date/time and locale formatting, permission dialog timing, and haptics.

---

## PART 1 — TOOLING & TECHNOLOGY STACK

### Development environment (Windows)
| Layer | Tool | Notes |
|---|---|---|
| SDK | Flutter (stable channel) | Includes Dart |
| IDE | VS Code + Flutter/Dart extensions | Lighter than Android Studio; Android Studio if you prefer full tooling |
| Emulator | Android Studio AVD | Enable hardware acceleration (WHPX/HAXM) |
| Version control | Git + GitHub/GitLab | Required for CI |
| API testing | Postman or Insomnia | |
| Design | Figma | Free tier is sufficient |

### Application architecture
| Concern | Recommendation | Rationale |
|---|---|---|
| State management | **Riverpod** | Compile-safe, testable, no BuildContext coupling. (Bloc is the alternative if your team prefers explicit event/state modeling.) |
| Navigation | **go_router** | Declarative, deep-link and universal-link ready — required for payment return flows |
| Networking | **dio** | Interceptors for auth refresh, retry, logging |
| Serialization | **freezed** + **json_serializable** | Immutable models, generated boilerplate |
| Local storage | **drift** (SQL) or **Isar** | For offline cache |
| Secure storage | **flutter_secure_storage** | Tokens go in Keychain, never SharedPreferences |
| DI | Riverpod providers | Avoid a second DI framework |

**Layering:** `presentation → application (use cases) → domain (entities) → data (repositories, DTOs)`. Dependencies point inward only. Domain layer has zero Flutter imports.

### Backend options
| Option | When to choose |
|---|---|
| **Supabase** | Recommended for v1. Postgres, auth, storage, realtime, edge functions. Open-source, no vendor lock-in, excellent Flutter SDK. |
| **Firebase** | If you want the most mature Flutter ecosystem and don't mind NoSQL + Google lock-in |
| **Custom (FastAPI / NestJS + Postgres)** | If you have unusual business logic or compliance needs. Highest control, highest cost. |

Supporting services: **Sentry** (crash reporting), **PostHog** or **Firebase Analytics** (product analytics), **Cloudflare R2 / Supabase Storage** (media), **Resend/SendGrid** (transactional email).

### Payments stack
- **in_app_purchase** or **RevenueCat** — RevenueCat is strongly recommended. It abstracts StoreKit, handles receipt validation server-side, manages entitlements, and gives you subscription analytics. Free below $2.5k/mo revenue.
- **Stripe** — only for physical goods/services, or for the external US web checkout described below.

---

## PART 2 — PAYMENTS: RULES AND ARCHITECTURE

This is the highest-risk area of your v1. Get it wrong and you get rejected or, worse, removed after approval.

### The rules as of mid-2026
1. **Digital goods and subscriptions consumed inside the app must offer Apple IAP.** Commission is 30%, dropping to 15% for developers under $1M annual revenue (applied automatically per account) and 15% for auto-renewing subscriptions after year one.
2. **Physical goods and real-world services must NOT use IAP.** Use Stripe. Using IAP here is itself a rejection reason.
3. **US storefront only:** since May 2025 you may include buttons, links, and calls-to-action directing users to external web checkout. Apple is currently barred from charging commission on those purchases and cannot dictate the link's placement, wording, or formatting.
4. **Outside the US, the same UI is a violation.** The EU has separate alternative-terms programs with their own fee structures. Japan opened alternative payments via iOS 26.2.
5. **This will change.** The Ninth Circuit upheld the contempt finding but permitted Apple to charge a "reasonable commission" tied to demonstrable costs; the rate has not been set. Litigation is ongoing.

### Architectural implications
- Build a **server-side entitlement system** as the single source of truth. The app asks your backend "what does this user have access to?" — never the client deciding based on a local receipt.
- Make payment routing **region-aware and server-driven**. Ship a feature flag / remote config that decides per-storefront whether to show the external link. Never hardcode. You will change this.
- Validate receipts **server-side**. Client-side validation is trivially bypassed.
- Handle: restore purchases, subscription upgrade/downgrade/crossgrade, grace periods, billing retry, refunds, and family sharing. Apple tests several of these during review.
- Implement **App Store Server Notifications V2** webhook for renewal and cancellation events.

---

## PART 3 — APP STORE PUBLISHING REQUIREMENTS

### Account
- **Apple Developer Program: $99/year.** No submission is possible without it.
- **Individual** account: registered under your personal legal name, which is displayed publicly.
- **Organization** account: requires a D-U-N-S number from Dun & Bradstreet; displays company legal name. Obtaining a D-U-N-S can take 1–2 weeks — start this early if you want a business name.
- Choosing the wrong type is a common early mistake and is painful to change later.

### Technical requirements
- **Since April 28, 2026: builds must be compiled with Xcode 26 or later using the iOS 26 SDK.** Codemagic lets you pin the Xcode version — set it explicitly, don't rely on the default.
- Deployment target: iOS 16 is the practical minimum for new submissions given active device distribution.
- **Privacy manifest (`PrivacyInfo.xcprivacy`)** declaring required-reason API usage (file timestamps, disk space, keyboard state, user defaults, etc.). Missing or incomplete manifests are among the most common rejection causes in 2025–2026. Note that your *third-party Flutter packages* also need manifests — audit your dependency tree.
- Valid distribution certificate and provisioning profile (Codemagic can manage these automatically).
- App icon, launch screen, and all required screenshot sizes.

### Metadata & compliance
- **Live privacy policy URL** (must be reachable at review time)
- App Privacy "nutrition label" — data collection disclosures, must match actual behavior
- Age rating questionnaire
- Export compliance declaration (encryption usage)
- Support URL
- **If your app generates or displays AI content, a clear user-facing disclosure is mandatory** — formalized in the 2025 guidelines, actively checked, and apps found non-compliant after approval can be removed.
- Account deletion must be available **in-app** if you offer account creation. Non-negotiable.
- Sign in with Apple must be offered if you offer any third-party social login.

### Review process
- Roughly 90% of submissions are reviewed within 24 hours; typical turnaround is 24–48 hours.
- Apps involving payments, AI, health, or finance take longer.
- Expedited review can be requested for urgent fixes — use sparingly.
- Statuses: In Review → Ready for Sale / Pending Developer Release / Rejected.
- Release options: immediate, manual, or phased (7-day staged rollout — recommended for v1).

### Common rejection causes to design against
| Guideline | Cause |
|---|---|
| 2.1 | Crashes, broken links, placeholder content, reviewer can't access features |
| 2.3.x | Screenshots or description don't match actual functionality |
| 3.1.1 | Payment rules violations (see Part 2) |
| 4.2 | "Minimum functionality" — a thin wrapper around a website |
| 5.1.1 | Requesting data or permissions not needed for core function; forcing registration for features that don't require it |
| 5.1.1(v) | No in-app account deletion |

**Always provide a working demo account** in App Review notes if any content sits behind login. This is the single cheapest way to avoid a rejection round.

---

## PART 4 — DESIGN PRINCIPLES

### Platform fidelity
Flutter defaults to Material Design, which looks *wrong* on iOS. Decide deliberately:
- **Adaptive** — Cupertino widgets on iOS, Material on Android. Most native-feeling, most work.
- **Custom design system** — your own visual language applied consistently across platforms. This is what premium apps (Airbnb, Spotify, Duolingo) do, and it's the recommended path for a distinctive product.

Either way, respect iOS **behavioral** conventions even under a custom skin: edge-swipe back, bottom-anchored primary actions within thumb reach, native-feeling scroll physics and rubber-band overscroll, iOS-standard share sheet, and haptic feedback on meaningful state changes.

### iOS 26 "Liquid Glass"
iOS 26 shipped Apple's broadest visual update ever. Your app will look dated if it ignores it entirely and broken if it imitates it badly. Choose one coherent direction rather than half-adopting.

### A premium feel comes from
1. **Restraint** — one accent color, two typefaces maximum, generous whitespace
2. **A real type scale** — define 6–8 named text styles and never deviate
3. **An 8pt spacing grid** — no arbitrary padding values anywhere
4. **Motion with intent** — 200–300ms, eased, purposeful. Shared-element transitions between list and detail. Never animate for decoration.
5. **Every state designed** — loading (skeletons, not spinners), empty (illustrated, with a clear next action), error (recoverable, human language), success
6. **Optimistic UI** — reflect user actions immediately, reconcile with the server after
7. **Accessibility** — Dynamic Type support, 4.5:1 contrast minimum, 44×44pt touch targets, VoiceOver labels, reduced-motion respect. Apple checks some of this.

### Deliverables
Design tokens (color, type, spacing, radius, elevation) → Figma component library → screen designs → prototype → implementation as a Flutter theme extension. Never hardcode a color or size in a widget.

---

## PART 5 — DELIVERY ROADMAP

### Phase 0 — Foundation (Week 1–2)
- Define the product (see gaps below), write user stories, success metrics
- Competitive analysis
- Apple Developer Program enrollment — **start now**, D-U-N-S can take weeks
- Install Flutter SDK, Android Studio, VS Code on Windows; verify `flutter doctor`
- Create repo, branch strategy, commit conventions

### Phase 1 — Design (Week 2–4)
- Information architecture and user flows
- Design tokens and component library in Figma
- All primary screens plus every loading/empty/error state
- Clickable prototype, validated with 5 target users

### Phase 2 — Scaffold & CI (Week 4–5)
- Flutter project, folder structure, layer boundaries
- Theme system from design tokens
- Routing skeleton with go_router
- Backend project, schema, auth
- **Codemagic pipeline → TestFlight, running end to end before any real feature exists.** Do this early; discovering signing problems at launch is the classic failure mode.

### Phase 3 — Core build (Week 5–12)
- Auth (including Sign in with Apple and in-app account deletion)
- Core feature vertical slices, one at a time, each shipped to TestFlight
- Offline cache and sync
- Continuous testing on your physical iPhone

### Phase 4 — Payments (Week 12–15)
Deliberately separate and late, because it's the most complex and most rejection-prone area.
- App Store Connect product configuration
- RevenueCat integration, server entitlements, receipt validation
- Region-aware payment routing behind remote config
- Sandbox testing: purchase, restore, upgrade, downgrade, cancel, refund, expiry

### Phase 5 — Hardening (Week 15–18)
- Sentry, analytics, performance profiling
- Accessibility audit
- Privacy manifest audit across all dependencies
- Beta with 20–50 external TestFlight testers
- Fix, iterate

### Phase 6 — Submission (Week 18–20)
- Screenshots for all required sizes, app preview video
- Store listing copy, keywords, privacy labels, age rating
- Privacy policy and terms published live
- Demo account prepared for reviewers
- Submit → expect one rejection round → resubmit
- Phased release

### Phase 7 — Post-launch
- Monitor crash-free rate (target >99.5%), funnel drop-off, subscription conversion
- Respond to reviews
- Ship a small update within 2–3 weeks to signal active maintenance

---

## PART 6 — SRS SECTIONS PENDING PRODUCT DEFINITION

The following cannot be written until the app concept is defined:

- [ ] Product purpose, scope, and target users
- [ ] Functional requirements (FR-001…) with priority and acceptance criteria
- [ ] Use cases with actors, preconditions, main flow, alternate flows, postconditions
- [ ] Domain model and entity-relationship diagram
- [ ] API contract
- [ ] Screen inventory and navigation map
- [ ] Monetization model — what exactly is being sold, and is it digital or physical? (This determines the entire payment architecture in Part 2.)
- [ ] Non-functional requirements: performance budgets, offline behavior, security, compliance (GDPR/KVKK/CCPA as applicable)
- [ ] Test plan and traceability matrix

---

## KEY RISKS

| Risk | Mitigation |
|---|---|
| Payment rules change mid-build | Server-driven, region-aware routing behind remote config |
| iOS-only bug found late | TestFlight from week 5, test on device continuously |
| Rejection delays launch | Budget 2 review rounds; demo account; pre-submission guideline self-audit |
| Privacy manifest gaps in dependencies | Audit third-party packages before submission, not during |
| Cloud build minutes cost creep | Batch builds; don't build every commit, build every merge to main |
