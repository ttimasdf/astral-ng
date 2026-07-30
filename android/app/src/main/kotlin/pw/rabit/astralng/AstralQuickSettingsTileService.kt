package pw.rabit.astralng

import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

@TargetApi(Build.VERSION_CODES.N)
class AstralQuickSettingsTileService : TileService() {
    private val widgetData: SharedPreferences by lazy {
        HomeWidgetPlugin.getData(this)
    }

    private val preferenceListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == CONNECTION_STATE_KEY || key == REQUIRES_VPN_KEY) {
                updateTile()
            }
        }

    override fun onCreate() {
        super.onCreate()
        widgetData.registerOnSharedPreferenceChangeListener(preferenceListener)
    }

    override fun onDestroy() {
        widgetData.unregisterOnSharedPreferenceChangeListener(preferenceListener)
        super.onDestroy()
    }

    override fun onTileAdded() {
        super.onTileAdded()
        updateTile()
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()

        when (widgetData.getString(CONNECTION_STATE_KEY, STATE_IDLE)) {
            STATE_CONNECTING -> return
            STATE_IDLE -> {
                val requiresVpn = widgetData.getBoolean(REQUIRES_VPN_KEY, true)
                if (requiresVpn && VpnService.prepare(this) != null) {
                    openAppForVpnPermission()
                    return
                }
            }
        }

        qsTile?.let { tile ->
            tile.state = Tile.STATE_UNAVAILABLE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = getString(R.string.quick_settings_tile_status_updating)
            }
            tile.updateTile()
        }

        try {
            HomeWidgetBackgroundIntent.getBroadcast(this, TOGGLE_URI).send()
        } catch (_: PendingIntent.CanceledException) {
            updateTile()
        }
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        val state = widgetData.getString(CONNECTION_STATE_KEY, STATE_IDLE)
        val statusRes = when (state) {
            STATE_CONNECTED -> {
                tile.state = Tile.STATE_ACTIVE
                R.string.quick_settings_tile_status_connected
            }
            STATE_CONNECTING -> {
                tile.state = Tile.STATE_UNAVAILABLE
                R.string.quick_settings_tile_status_connecting
            }
            else -> {
                tile.state = Tile.STATE_INACTIVE
                R.string.quick_settings_tile_status_disconnected
            }
        }

        val status = getString(statusRes)
        tile.label = getString(R.string.quick_settings_tile_label)
        tile.contentDescription = getString(
            R.string.quick_settings_tile_content_description,
            status,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = status
        }
        tile.updateTile()
    }

    private fun openAppForVpnPermission() {
        Toast.makeText(
            this,
            R.string.quick_settings_tile_vpn_permission_required,
            Toast.LENGTH_LONG,
        ).show()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        } ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                OPEN_APP_REQUEST_CODE,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(launchIntent)
        }
    }

    companion object {
        private const val CONNECTION_STATE_KEY = "connection_state"
        private const val REQUIRES_VPN_KEY = "requires_vpn"
        private const val STATE_IDLE = "idle"
        private const val STATE_CONNECTING = "connecting"
        private const val STATE_CONNECTED = "connected"
        private const val OPEN_APP_REQUEST_CODE = 4102
        private val TOGGLE_URI: Uri = Uri.parse("astral://toggle_connection")
    }
}
