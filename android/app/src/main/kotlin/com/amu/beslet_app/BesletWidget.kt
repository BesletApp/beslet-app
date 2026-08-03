package com.amu.beslet_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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
    val lightState = widgetData.getString("lightState", "dawn") ?: "dawn"
    val lightLabel = widgetData.getString("lightLabel", "Dawn") ?: "Dawn"

    val palette = when (lightState) {
      "noon" -> LampPalette("☀️", "#20263A", "#A8C6E8", "#8FA3BD")
      "dusk" -> LampPalette("🌇", "#3A2418", "#E8965C", "#C09A7E")
      "night" -> LampPalette("🌙", "#171822", "#8F8FD0", "#6E6E8F")
      else -> LampPalette("🌅", "#2A2518", "#E6C877", "#B7A87E")
    }
    val glyph = palette.glyph
    val bg = palette.background
    val fg = palette.primary
    val dim = palette.secondary

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
            setTextViewText(R.id.widget_light, "$glyph  $lightLabel")
            setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor(bg))
            setTextColor(R.id.widget_verse_am, Color.parseColor(fg))
            setTextColor(R.id.widget_verse_en, Color.parseColor(dim))
            setTextColor(R.id.widget_light, Color.parseColor(dim))
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}

data class LampPalette(
    val glyph: String,
    val background: String,
    val primary: String,
    val secondary: String,
)
