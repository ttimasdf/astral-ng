package pw.rabit.astralng

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QUICK_SETTINGS_CHANNEL,
        )
        channel.setMethodCallHandler { call, result ->
            if (call.method == "ready") {
                quickSettingsChannel = channel
                isQuickSettingsReady = true
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        quickSettingsChannel = null
        isQuickSettingsReady = false
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        const val QUICK_SETTINGS_CHANNEL = "pw.rabit.astralng/quick_settings"

        private var quickSettingsChannel: MethodChannel? = null
        private var isQuickSettingsReady = false

        /**
         * Delivers a user tile tap to the primary Flutter engine without starting an Activity.
         * Returns false when the app is not running and the caller must use an Activity fallback.
         */
        fun dispatchQuickSettingsToggle(action: String): Boolean {
            val channel = quickSettingsChannel
            if (!isQuickSettingsReady || channel == null) return false

            channel.invokeMethod("toggleConnection", mapOf("action" to action))
            return true
        }
    }
}
