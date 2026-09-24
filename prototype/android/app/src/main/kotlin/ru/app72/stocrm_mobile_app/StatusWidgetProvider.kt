package ru.app72.stocrm_mobile_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class StatusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val title = prefs.getString("title", "Всё в порядке") ?: "Всё в порядке"
        val subtitle = prefs.getString("subtitle", "VAG Market") ?: "VAG Market"
        val screen = prefs.getString("screen", "book") ?: "book"
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.status_widget)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_sub, subtitle)
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_screen", screen)
                data = Uri.parse("vagmarket://open?screen=$screen")
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(context, id, intent, flags),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        const val PREFS = "vagmarket_widget"
    }
}
