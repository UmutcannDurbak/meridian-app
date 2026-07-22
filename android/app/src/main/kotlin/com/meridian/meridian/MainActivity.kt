package com.meridian.meridian

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity, not FlutterActivity — local_auth's BiometricPrompt
// integration on Android requires a FragmentActivity to attach to.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DocumentExtraction.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
