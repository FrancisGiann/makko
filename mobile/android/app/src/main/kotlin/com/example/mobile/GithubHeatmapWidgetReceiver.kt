package com.example.mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class GithubHeatmapWidgetReceiver : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_github_heatmap).apply {
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_heatmap_root, pendingIntent)

                val imagePath = widgetData.getString("github_heatmap_image", null)
                if (!imagePath.isNullOrEmpty()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_heatmap_image, bitmap)
                        setViewVisibility(R.id.widget_heatmap_image, View.VISIBLE)
                        setViewVisibility(R.id.widget_heatmap_empty, View.GONE)
                    } else {
                        setViewVisibility(R.id.widget_heatmap_image, View.GONE)
                        setViewVisibility(R.id.widget_heatmap_empty, View.VISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.widget_heatmap_image, View.GONE)
                    setViewVisibility(R.id.widget_heatmap_empty, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
