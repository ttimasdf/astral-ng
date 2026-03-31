package pw.rabit.astralng

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AstralWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout_small).apply {
                val isConnected = widgetData.getBoolean("is_connected", false)
                val statusText = if (isConnected) "Connected" else "Disconnected"
                setTextViewText(R.id.widget_status, statusText)

                val ipText = widgetData.getString("ip_address", "No IP")
                setTextViewText(R.id.widget_ip, ipText)

                // Set click listener to toggle connection
                val pendingIntent = getLaunchIntent(context)
                if (pendingIntent != null) {
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getLaunchIntent(context: Context): android.app.PendingIntent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        return android.app.PendingIntent.getActivity(
            context,
            0,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
    }
}
