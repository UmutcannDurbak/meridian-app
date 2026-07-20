package com.meridian.meridian

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity — local_auth's BiometricPrompt
// integration on Android requires a FragmentActivity to attach to.
class MainActivity : FlutterFragmentActivity()
