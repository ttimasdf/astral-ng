package pw.rabit.astralng

import android.content.Intent
import android.content.pm.ApplicationInfo
import com.plugin.vpn_service_plugin.TauriVpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun getDartEntrypointArgs(): List<String>? {
        val inherited = super.getDartEntrypointArgs()?.toMutableList() ?: mutableListOf()
        val debuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!debuggable) return inherited.ifEmpty { null }

        intent.getStringExtra(LOG_PRESET_EXTRA)
            ?.takeIf { it.length <= MAX_OPTION_LENGTH }
            ?.let { inherited.add("--log-preset=$it") }

        val modules = intent.getStringArrayExtra(LOG_MODULES_EXTRA)?.asList()
            ?: intent.getStringExtra(LOG_MODULES_EXTRA)?.split(',')
            ?: emptyList()
        modules
            .asSequence()
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .filter { it.length <= MAX_OPTION_LENGTH }
            .take(MAX_MODULE_OVERRIDES)
            .forEach { inherited.add("--log-module=$it") }

        val duration = intent.extras?.get(LOG_DURATION_EXTRA)?.toString()
        duration
            ?.takeIf { it.length <= MAX_OPTION_LENGTH }
            ?.let { inherited.add("--log-duration=$it") }

        return inherited.ifEmpty { null }
    }

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

    override fun onDestroy() {
        if (isFinishing && !isChangingConfigurations) {
            stopService(Intent(this, TauriVpnService::class.java))
        }
        super.onDestroy()
    }

    companion object {
        const val QUICK_SETTINGS_CHANNEL = "pw.rabit.astralng/quick_settings"
        const val LOG_PRESET_EXTRA = "astral.log-preset"
        const val LOG_MODULES_EXTRA = "astral.log-modules"
        const val LOG_DURATION_EXTRA = "astral.log-duration"
        const val MAX_MODULE_OVERRIDES = 32
        const val MAX_OPTION_LENGTH = 256

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
