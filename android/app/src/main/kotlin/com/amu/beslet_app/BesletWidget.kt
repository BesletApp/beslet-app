package com.amu.beslet_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BesletWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.beslet_widget_layout).apply {
            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            setTextViewText(
                R.id.widget_verse_am, widgetData.getString("verseAm", null) ?: "ጸሎት እና ቃል")
            setTextViewText(
                R.id.widget_verse_en, widgetData.getString("verseEn", null) ?: "Prayer & Word")
            setTextViewText(
                R.id.widget_day, widgetData.getString("dayLabel", null) ?: "Day 1 of 90")
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
