# Building and publishing Meridian (Android)

This is the Android half of the release story — no cloud Mac needed, no
Codemagic, just your own machine and the Play Console. (iOS release process
lives in `docs/ROADMAP.md`, Part 1/3 — that one genuinely does need the
TestFlight/cloud-Mac path once you have an Apple developer account.)

## 1. One-time setup: a real signing key

Every release build must be signed. Play Store outright rejects a
debug-signed upload, and the debug key isn't a secret — it's the same on
every machine with the Android SDK installed. You need your own.

### Generate the keystore

Run this once, on your own machine (not in a shared/cloud shell — this file
is a permanent secret):

```bash
keytool -genkey -v -keystore meridian-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

`keytool` ships with any JDK (Android Studio bundles one). It'll prompt for
a store password, a key password, and your name/org details for the
certificate — the certificate details don't matter for functionality, only
the passwords and the file itself do.

**Put the resulting `.jks` file somewhere durable and back it up** — a
password manager's file storage, an encrypted drive, wherever you keep
things you cannot afford to lose. Once Play Store has accepted a build
signed with this key, every future update must be signed with the *same*
key (see the Play App Signing note below — it gives you a recovery path if
you enroll before you need it).

### Point the build at it

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` and fill in the real store password, key
password, and the **absolute path** to the `.jks` file you just generated.
This file is gitignored — it will never be committed, by design.

That's it. `android/app/build.gradle.kts` already reads this file and signs
release builds with it automatically. Nothing else to configure.

## 2. Build it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
```

**For Play Store — an App Bundle, not an APK.** Play Console has required
AAB for new apps since 2021; it lets Play Store generate optimized APKs per
device instead of shipping one bundle with every architecture/density baked
in.

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

**For sideloading / sending to a tester directly over USB or a link** — an
APK:

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Both commands fail loudly if `android/key.properties` is missing required
fields — that's intentional; a silently-debug-signed release build is a
worse failure mode than a build that refuses to run.

### Bumping the version

`pubspec.yaml`'s `version: 0.1.0+1` is `versionName+versionCode` — Gradle
reads both straight from it (see `flutter.versionCode`/`flutter.versionName`
in `build.gradle.kts`), so there's exactly one place to edit. **Play Console
requires `versionCode` to strictly increase on every upload** — `0.1.0+1` →
`0.1.0+2` for a same-version rebuild, `0.1.1+3` for the next release, etc.
It rejects an upload with a versionCode it's already seen.

## 3. Play Console — the publication path

1. **Account** — [play.google.com/console](https://play.google.com/console),
   $25 one-time fee (unlike Apple's $99/*year*). A day or so of identity
   verification before you can publish.
2. **Create the app**, set its default language and app/game category.
3. **Play App Signing** — accept this when prompted (it's the default now).
   You upload builds signed with your *upload* key (the one from step 1);
   Google re-signs with an *app signing* key it holds for you. If you ever
   lose the upload keystore, Google can help you rotate to a new one — you
   are not permanently locked out the way you would be without this.
4. **Internal testing track first.** Upload the AAB there before anything
   else — instant availability to testers you add by email, no review wait.
   This is your real-device distribution loop before Play Store review ever
   enters the picture.
5. **Store listing** — title, short/full description, icon, feature
   graphic, phone screenshots (minimum counts and sizes are enforced by the
   console UI as you fill it in).
6. **Required before *any* production submission**, all under
   Policy/App content in the console:
   - **Privacy policy URL** — must be live and reachable at review time.
     Meridian holds financial/contract data; this is not optional.
   - **Data safety form** — what data the app collects and why. Answer this
     honestly against what the app actually does — mismatches are a
     rejection and, worse, a later takedown reason.
   - **Content rating questionnaire** (IARC).
   - **Target API level** — Play Store enforces a recent `targetSdkVersion`
     floor that moves forward roughly yearly; `flutter.targetSdkVersion`
     (set by your Flutter SDK version) needs to clear whatever the current
     floor is at submission time.
   - **App access** — if any part of the app is gated behind login, provide
     reviewer credentials here. There's no login in Meridian today, so this
     is a non-issue for now.
7. **Closed → open testing** (optional but recommended) before production —
   wider test rings, still no public store listing yet.
8. **Production release**, staged rollout recommended (e.g. 20% → 50% →
   100% over a few days) so a bad build reaches a fraction of users, not
   everyone, before you can halt it.
9. **Review time** is typically hours to a couple of days for a first
   submission, often faster for updates — much faster than Apple's process,
   and there's no equivalent of App Review's payment-rules scrutiny unless
   you add in-app purchases.

## 4. What's still open before a real submission

- **R8/ProGuard shrinking is off** (see the comment in `build.gradle.kts`).
  Not Play-mandatory, but worth it for download size — needs tested
  keep-rules for drift/sqlite3, ML Kit, local_auth, flutter_local_notifications,
  and purchases_flutter first, since several use reflection R8 can strip by
  default.
- **App icon** — confirm `android/app/src/main/res/mipmap-*/ic_launcher.png`
  is your real icon, not the Flutter default, and add an adaptive icon
  (`mipmap-anydpi-v26/ic_launcher.xml` + foreground/background layers) if
  it isn't there yet — Play Console will flag a missing adaptive icon.
  `flutter_launcher_icons` (a dev dependency you'd add) generates all the
  densities from one source image if you don't want to do it by hand.
  Same for `ios/Runner/Assets.xcassets` when the iOS side gets picked up.
  Note the app currently has RevenueCat's `purchases_flutter` in
  `pubspec.yaml` but no products/entitlements wired up — that's a
  Phase-4-later concern per `docs/ROADMAP.md`, not a blocker for an Android
  testing-track release.
- **Privacy policy** — needs to exist and be hosted somewhere before step 6
  above; nothing in this repo generates one.
