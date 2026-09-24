package ru.app72.stocrm_mobile_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "vagmarket/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    getSharedPreferences(StatusWidgetProvider.PREFS, MODE_PRIVATE).edit()
                        .putString("title", args["title"]?.toString() ?: "Всё в порядке")
                        .putString("subtitle", args["subtitle"]?.toString() ?: "VAG Market")
                        .putString("screen", args["screen"]?.toString() ?: "book")
                        .putString("state", args["state"]?.toString() ?: "ok")
                        .apply()
                    val mgr = AppWidgetManager.getInstance(this)
                    val ids = mgr.getAppWidgetIds(ComponentName(this, StatusWidgetProvider::class.java))
                    if (ids.isNotEmpty()) {
                        sendBroadcast(
                            Intent(this, StatusWidgetProvider::class.java)
                                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
                        )
                    }
                    result.success(true)
                }
                "launchScreen" -> {
                    val fromExtra = intent?.getStringExtra("widget_screen")
                    val fromUri = intent?.data?.getQueryParameter("screen")
                    result.success(fromExtra ?: fromUri)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
