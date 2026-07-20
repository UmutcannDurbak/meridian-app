# Software Requirements Specification
## Working title: **Meridian** — Obligation & Deadline Intelligence

**Version:** 1.0 DRAFT
**Date:** July 2026
**Platform:** iOS 16+ (Flutter), Android to follow
**Companion document:** iOS_Flutter_Roadmap_and_SRS.md (toolchain, CI, App Store process)

---

## 1. PRODUCT DEFINITION

### 1.1 Purpose
Meridian is a private obligation register for people who carry a large number of dated commitments with financial or legal consequences. It captures obligations with minimal effort, warns early enough to act, and makes the cost of forgetting visible.

### 1.2 The core insight
Most reminder apps track **when something ends**. Meridian tracks **when you must act**.

A supplier contract expiring 1 March with a 90-day cancellation clause has a true deadline of 1 December. An executive who learns about it on 15 February has already lost the decision. Meridian derives and surfaces the *action deadline*, not the expiry date.

This is the product's defensible differentiator and should drive the primary UI hierarchy.

### 1.3 Positioning
Not a to-do app. Not a calendar. A **register of consequences**.

The value proposition is not organization — it is avoided loss. A single missed auto-renewal or lapsed compliance certificate typically exceeds the annual subscription cost by an order of magnitude. Marketing and in-app framing should be economic, not productivity-flavored.

### 1.4 Target users
| Persona | Context | Primary need |
|---|---|---|
| **Elif — CFO, mid-size firm** | 150+ vendor contracts, insurance, tax filings, audit dates | Notice-period tracking, financial exposure forecast, delegation to finance team |
| **Murat — owner, 3 restaurants** | Licenses, equipment service, lease renewals, staff certifications, tax | One place for business + personal, photo capture, no learning curve |
| **Dr. Aylin — surgeon** | Medical licensure, board certification, malpractice insurance, CME credits, personal obligations | Absolute reliability, privacy, minimal setup |
| **Kerem — CTO** | SaaS renewals, domain/SSL expiry, vendor SLAs, compliance audits | Bulk import, integrations, team visibility |

**Common trait — the design constraint:** high income, severe time scarcity, low tolerance for setup friction, high sensitivity about data confidentiality. They will abandon the product during onboarding if it feels like work.

### 1.5 What this is not (v1 non-goals)
- Not a task manager, project tool, or note app
- Not a calendar replacement — it *complements* the calendar
- No team collaboration beyond simple delegation
- No accounting or invoicing
- No Android in v1

---

## 2. THE CENTRAL PRODUCT RISK

**Your users will not perform data entry.**

This is the single failure mode most likely to kill the product. An executive with 200 obligations will never manually type them. If first-run experience requires it, they churn in the first session and the premium price becomes indefensible.

Therefore: **capture friction is the primary engineering priority, ranked above every other feature.** Every requirement below is subordinate to it. If a tradeoff arises between capture ease and any other capability, capture wins.

Secondary risk: **App Review Guideline 4.2 (minimum functionality).** A reminder app with elegant styling may be judged too thin. The AI extraction and notice-period engine are what establish substantive functionality — they are also compliance insurance.

---

## 3. FUNCTIONAL REQUIREMENTS

Priority: **P0** = required for launch · **P1** = launch if possible · **P2** = post-launch

### 3.1 Capture (highest priority)

| ID | Requirement | Pri |
|---|---|---|
| FR-101 | **Email forwarding.** Each account receives a unique private address (`u-a7f3@in.meridian.app`). Forwarded mail is parsed into a draft obligation with proposed title, date, counterparty, amount, and category. User confirms with one tap. | P0 |
| FR-102 | **Document scan.** Photograph or import a PDF/image. OCR + LLM extraction proposes obligation fields, with the source region highlighted for verification. | P0 |
| FR-103 | **Manual entry.** Single-screen form: title and date required, everything else optional and progressively disclosed. Must be completable in under 10 seconds. | P0 |
| FR-104 | **Natural language entry.** "Insurance renews 12 March, 30 day notice" parses into a structured obligation. | P1 |
| FR-105 | **Bulk import.** CSV/Excel with guided column mapping. Critical for onboarding users who already keep a spreadsheet — most of them do. | P0 |
| FR-106 | **Calendar import.** Read-only scan of the user's calendar; suggest dated items that look like obligations. User selects which to adopt. | P1 |
| FR-107 | **Templates.** Prebuilt obligation sets by profession and business type (restaurant, clinic, agency, logistics), each with typical notice periods pre-filled. | P1 |
| FR-108 | **Share extension.** Accept content shared from Mail, Files, Safari, Photos directly into capture. | P1 |

**FR-101 and FR-105 together constitute the onboarding strategy.** A new user should reach a populated register within five minutes without typing.

### 3.2 The obligation model

| ID | Requirement | Pri |
|---|---|---|
| FR-201 | Obligation fields: title, category, counterparty, expiry date, **notice-period days**, **derived action deadline**, recurrence rule, monetary value + currency, status, attachments, notes, owner/assignee, criticality. | P0 |
| FR-202 | **Notice-period engine.** Action deadline = expiry − notice days. Where both exist, the action deadline is the primary date shown everywhere in the UI; expiry is secondary. | P0 |
| FR-203 | Categories: Contract, Subscription, Payment, Insurance, License/Permit, Certification, Maintenance, Tax/Filing, Warranty, Document (passport/ID), Meeting/Commitment, Other. User-definable additions. | P0 |
| FR-204 | Recurrence: none, daily, weekly, monthly, quarterly, annual, custom interval, nth-weekday-of-month. Completing one instance generates the next. | P0 |
| FR-205 | Auto-renewal flag. When set, the obligation renews automatically unless the user acts before the action deadline — the alert copy changes to reflect that inaction has a cost. | P0 |
| FR-206 | Attachments: PDF and images, encrypted at rest, viewable in-app. | P0 |
| FR-207 | Status lifecycle: Upcoming → Action Window Open → Overdue → Resolved / Dismissed / Renewed. | P0 |
| FR-208 | Criticality: Critical / Important / Routine. Drives alert aggressiveness and visual weight. | P0 |

### 3.3 Alerting

| ID | Requirement | Pri |
|---|---|---|
| FR-301 | **Escalating alert schedules**, not single reminders. Default for Critical: 90/60/30/14/7/3/1 days before action deadline, then daily until resolved. Fully configurable per obligation and per category. | P0 |
| FR-302 | Per-category default schedules, editable once and inherited by all new obligations in that category. | P0 |
| FR-303 | Channels: push, email, and optionally SMS (P2). Critical obligations may use time-sensitive notifications that pierce Focus modes. | P0 |
| FR-304 | Quiet hours and a daily digest option — a single morning summary instead of scattered pings. Expect most users to prefer this. | P0 |
| FR-305 | **Snooze with mandatory re-date.** Dismissing an alert requires choosing when to be reminded again; silent dismissal is not permitted for Critical items. | P0 |
| FR-306 | Escalation to a second person (assistant, partner) if a Critical obligation goes unacknowledged past a threshold. | P1 |
| FR-307 | Home Screen and Lock Screen widgets: next action deadline, count of open action windows. | P1 |

### 3.4 Views & intelligence

| ID | Requirement | Pri |
|---|---|---|
| FR-401 | **Horizon** (home): a single prioritized list answering "what needs me now?" Not a calendar grid. Grouped as Overdue / This Week / This Month / Later. | P0 |
| FR-402 | **Timeline**: 12-month forward scroll of obligations, visually weighted by monetary value and criticality. | P1 |
| FR-403 | **Exposure**: forecast of committed spend by month, and total value of obligations entering their action window. Converts the product from reminders into a financial instrument. | P1 |
| FR-404 | Search and filter across every field, including attachment text. | P0 |
| FR-405 | Grouping by counterparty — see every obligation tied to one vendor at once. | P1 |
| FR-406 | **Value saved** counter: cumulative monetary value of obligations resolved within their action window. Directly justifies renewal at subscription time. | P1 |
| FR-407 | Export to PDF/CSV. | P1 |

### 3.5 Delegation

| ID | Requirement | Pri |
|---|---|---|
| FR-501 | Invite an assistant or colleague with scoped access to specific obligations or categories. | P1 |
| FR-502 | Assign an obligation to another user; both parties receive alerts; owner sees acknowledgement state. | P1 |
| FR-503 | Roles: Owner (full), Delegate (edit assigned), Viewer (read-only). | P1 |
| FR-504 | Audit log of who changed or resolved what, and when. | P2 |

### 3.6 Account, privacy, platform

| ID | Requirement | Pri |
|---|---|---|
| FR-601 | Sign in with Apple, email magic link. Sign in with Apple mandatory if any third-party login is offered. | P0 |
| FR-602 | **In-app account deletion** with full data purge. App Store requirement — omission causes rejection. | P0 |
| FR-603 | Biometric app lock (Face ID), required by default given the sensitivity of contract data. | P0 |
| FR-604 | Full offline read; writes queue and sync on reconnect. | P0 |
| FR-605 | Data export in machine-readable format on request (GDPR/KVKK). | P0 |
| FR-606 | **AI disclosure**: clear user-facing notice wherever extraction occurs. Mandatory under Apple's 2025 guidelines; non-compliance can cause removal after approval. | P0 |
| FR-607 | Siri Shortcuts / App Intents for voice capture. | P2 |

---

## 4. USE CASES

### UC-01 — Capture a contract by email forward
**Actor:** Elif (CFO) · **Precondition:** Authenticated, forwarding address known

1. Elif receives a supplier agreement PDF by email.
2. She forwards it to her private Meridian address. *(Interaction ends here — total effort ~4 seconds.)*
3. System extracts text from body and attachment.
4. Extraction model proposes: title, counterparty, expiry date, notice period, value, category.
5. System computes action deadline = expiry − notice period.
6. System creates a **draft** obligation and sends one push: "Draft ready — Acme Logistics, act by 3 Dec."
7. Elif opens it; fields are shown alongside the highlighted source text.
8. She taps **Confirm**.

**Postcondition:** Obligation active, alert schedule generated from category defaults.

**Alternates:**
- *4a. Confidence below threshold* — fields flagged for review; system never silently guesses a date.
- *4b. No date found* — draft created with date empty and a single prompt; never discarded.
- *5a. No notice period stated* — category default applied and labelled "assumed," editable.
- *8a. Not confirmed within 7 days* — reminder; drafts never expire or auto-delete.

**Rule:** an unconfirmed draft must never be treated as an active obligation, and must never be deleted.

---

### UC-02 — Prevent an unwanted auto-renewal
**Actor:** Kerem (CTO) · **Trigger:** Action deadline in 30 days

1. System sends: "Datadog renews 14 Feb at $48,000. Cancel or renegotiate by **15 Jan** — 30 days left."
2. Kerem opens the obligation, reviews attached contract and prior-year value.
3. He selects **Delegate → Ops lead**, adding a note.
4. Ops lead is alerted and inherits the escalating schedule.
5. Ops lead marks **Renegotiated**, entering the new value.
6. System resolves the obligation, generates next year's instance from the new terms, and credits the delta to the Value Saved counter.

**Alternate — 4a. No acknowledgement within 7 days:** escalation returns to Kerem and criticality is auto-raised.

---

### UC-03 — First-run population
**Actor:** Murat (business owner) · **Precondition:** Just installed

1. Onboarding asks two questions only: business type, and role.
2. System offers a **template pack** (Restaurant: food licence, fire inspection, lease, equipment service, POS subscription, insurance, tax dates) with typical notice periods pre-filled.
3. Murat selects the relevant items and supplies only the dates he knows.
4. System offers three further routes: import a spreadsheet, forward emails, or scan documents.
5. Murat photographs his lease; system extracts and drafts.
6. Home screen now shows a populated Horizon.

**Success criterion:** ≥8 obligations registered within 5 minutes, with fewer than 20 taps.

---

### UC-04 — Daily check
**Actor:** Any · **Frequency:** Highest-volume interaction in the product

1. User opens app (Face ID).
2. **Horizon** loads in under 400ms showing what requires action.
3. User swipes to resolve, snooze, or delegate directly from the list.

**Rule:** the most common actions must be reachable without opening a detail screen. This interaction defines the product's perceived quality more than any other.

---

### UC-05 — Subscription purchase
**Actor:** Trial user, day 12 of 14

1. Paywall presents the Value Saved figure accumulated during trial.
2. User selects Annual.
3. **US storefront:** both Apple IAP and an external web checkout link are shown.
   **All other storefronts:** IAP only. *(Showing the external link outside the US is a guideline violation.)*
4. Purchase completes; receipt validated **server-side**.
5. Server grants entitlement; client re-queries entitlement state.

**Alternates:** 4a. Validation fails → access preserved for 24h grace, flagged for support. 4b. Network lost → purchase reconciled on next launch via restore.

---

## 5. DOMAIN MODEL

```
User ──< Obligation >── Counterparty
 │           │
 │           ├──< Attachment
 │           ├──< AlertRule ──< AlertInstance
 │           ├──< Occurrence      (recurrence instances)
 │           └──< ActivityEntry   (audit)
 │
 ├──< Delegation >── User
 ├──< Category (system + custom)
 └──── Subscription (entitlement, server-authoritative)

CaptureJob ── source(email|scan|import|manual) ── ExtractionResult ── Obligation(draft)
```

**Obligation** — id, user_id, title, category_id, counterparty_id, expiry_date, notice_days, **action_deadline (derived, indexed)**, recurrence_rule, auto_renews, value_amount, currency, criticality, status, assignee_id, notes, created_via, created_at, updated_at

`action_deadline` is the primary sort and query key across the application and must be indexed accordingly.

---

## 6. SCREEN INVENTORY

| Screen | Purpose |
|---|---|
| Onboarding (3 steps max) | Role → template pack → capture route |
| **Horizon** (home) | Prioritized action list. Default tab. |
| Timeline | 12-month forward view |
| Exposure | Financial forecast |
| Obligation detail | Full record, attachments, history, actions |
| Capture sheet | Manual / scan / natural language |
| Draft review | Extracted fields beside source document |
| Counterparty detail | All obligations for one vendor |
| Search | Global, including attachment text |
| Settings | Alerts, quiet hours, security, delegation, subscription, export, delete account |
| Paywall | Region-aware |

Navigation: bottom bar — **Horizon · Timeline · Capture (center) · Exposure · Settings**. Capture is centered and prominent; it is the highest-value action.

---

## 7. UI & UX DESIGN DIRECTION

### 7.1 Principle
Elegance here means **calm under load**. A user with 200 obligations must feel in control, not besieged. Restraint is the aesthetic. Anything decorative that does not aid comprehension is removed.

Avoid the two obvious traps: gold-on-black "luxury" styling, which reads as cheap to actual executives, and dense enterprise-dashboard density, which reads as work.

### 7.2 Visual system
- **Palette:** near-black `#0A0B0D` and warm off-white `#FAFAF8` as base. One restrained accent — deep amber or slate blue. Semantic colors reserved *exclusively* for urgency states, never decoration.
- **Urgency encoding:** critical items earn weight through typographic scale and whitespace, not red. Red appears only for genuinely overdue items, so it retains meaning.
- **Typography:** one high-quality sans (SF Pro or Inter). 7-step scale. Numerals tabular throughout — dates and money must align in columns.
- **Space:** 8pt grid, generous. Whitespace is the primary signal of premium quality.
- **Depth:** subtle, single-layer. No heavy shadows.
- **Dark mode:** first-class, not an afterthought.
- **iOS 26 Liquid Glass:** adopt deliberately and coherently, or abstain entirely. Partial adoption looks broken.

### 7.3 Interaction
- Every list row supports swipe-to-resolve and swipe-to-snooze
- Long-press previews the full record without navigation
- Haptics on resolve — a small, satisfying confirmation
- Shared-element transition from row to detail
- Optimistic updates: actions register instantly, sync afterwards
- 200–300ms eased motion; nothing animates without purpose

### 7.4 Required states
Every screen specifies loading (skeleton, never spinner), empty (illustrated, one clear action), error (human language, recoverable), and success.

**Empty states matter disproportionately here** — a new user's first screen is empty and must feel like an invitation, not a failure.

### 7.5 Accessibility
Dynamic Type to XXL without layout breakage, 4.5:1 minimum contrast, 44×44pt targets, full VoiceOver labelling, reduced-motion respected. Note that this user base skews 40–60 — larger type support is a real usage requirement, not just compliance.

---

## 8. MONETIZATION

**Model:** auto-renewing subscription, digital service → **Apple IAP is mandatory.**

| Tier | Price | Contents |
|---|---|---|
| Trial | Free, 14 days | Full features, no card required |
| Personal | ~$14.99/mo or $119/yr | Unlimited obligations, all capture methods, 1 delegate |
| Business | ~$29.99/mo or $249/yr | 5 delegates, exposure forecasting, priority extraction, export |

Rationale for high pricing: a single prevented auto-renewal typically exceeds annual cost many times over. Price low and the product reads as a toy to this audience. Annual billing is strongly preferred — it matches the annual rhythm of the obligations themselves.

**Implementation:** RevenueCat, server-side receipt validation, server-authoritative entitlements, App Store Server Notifications V2 webhook, region-aware paywall behind remote config. Full detail in Part 2 of the companion roadmap.

---

## 9. NON-FUNCTIONAL REQUIREMENTS

| ID | Requirement |
|---|---|
| NFR-01 | Cold start to interactive Horizon < 1.2s; warm < 400ms |
| NFR-02 | List scrolling at 60fps with 1,000+ obligations |
| NFR-03 | Full offline read; writes queue and reconcile |
| NFR-04 | **Alert delivery reliability > 99.9%** — the product's entire promise. Server-side scheduling, never client-only timers. Independent monitoring with alerting on delivery failure. |
| NFR-05 | Attachments and sensitive fields encrypted at rest; TLS 1.3 in transit |
| NFR-06 | Tokens in Keychain via flutter_secure_storage; never SharedPreferences |
| NFR-07 | Document extraction completes < 30s p95 |
| NFR-08 | Crash-free sessions > 99.5% |
| NFR-09 | GDPR + KVKK compliant; export and erasure honored within 30 days |
| NFR-10 | Documents used for extraction are not retained by the model provider and not used for training. **State this explicitly in-app** — this audience will ask. |
| NFR-11 | Privacy manifest complete, including all third-party Flutter packages |

**NFR-04 and NFR-10 are the two that determine whether this audience trusts the product.** A single missed alert or one ambiguous data-handling answer loses the user permanently.

---

## 10. TEST PLAN

| Area | Approach |
|---|---|
| Notice-period derivation | Unit tests: leap years, month-end rollovers, DST boundaries, timezone travel |
| Recurrence | Unit tests across all rule types; verify no drift over 24 generated instances |
| Alert scheduling | Integration tests with simulated clock advancement |
| Extraction accuracy | Fixture corpus of 100+ real-world contracts; track precision/recall per field; regression-gate on release |
| Payments | Sandbox: purchase, restore, upgrade, downgrade, cancel, refund, expiry, grace period, family sharing |
| Offline | Airplane-mode create/edit/resolve, then reconcile; conflict resolution |
| Accessibility | VoiceOver walkthrough of every flow; Dynamic Type at XXL |
| Device | TestFlight from week 5; minimum iPhone SE, standard, and Pro Max form factors |

---

## 11. OPEN DECISIONS

1. **Extraction provider** — third-party LLM API versus self-hosted. Materially affects NFR-10 and the confidentiality story. Recommend a provider with contractual no-training and no-retention terms, stated verbatim in the privacy policy.
2. **Email ingestion infrastructure** — inbound parsing service selection and abuse/spam handling on user-specific addresses.
3. **Multi-currency** — is value tracking single-currency in v1? Affects the Exposure view.
4. **Launch market** — Turkey/EU/US determines KVKK vs GDPR emphasis and payment routing on day one.
5. **Name and brand** — "Meridian" is a placeholder. Verify trademark and App Store name availability early; name disputes surface late and hurt.
