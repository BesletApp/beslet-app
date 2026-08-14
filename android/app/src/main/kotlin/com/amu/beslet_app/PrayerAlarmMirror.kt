package com.amu.beslet_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * A tiny JSON mirror of the prayer alarms that were armed by Flutter so the
 * native side can re-arm them after a reboot (AlarmManager alarms do not
 * survive a reboot). Written by MainActivity on every schedule/cancel and
 * read by AlarmReceiver on BOOT_COMPLETED / MY_PACKAGE_REPLACED.
 */
object PrayerAlarmMirror {

    data class Entry(
        val requestCode: Int,
        val hour: Int,
        val minute: Int,
        val soundUri: String?,
        val title: String,
        val body: String,
        val verseText: String?,
        val verseRef: String?,
        val dayIndex: Int,
        val lang: String?,
    )

    private fun file(context: Context) = java.io.File(context.filesDir, "prayer_alarms.json")

    private fun toJson(e: Entry) = JSONObject().apply {
        put("requestCode", e.requestCode)
        put("hour", e.hour)
        put("minute", e.minute)
        put("soundUri", e.soundUri)
        put("title", e.title)
        put("body", e.body)
        put("verseText", e.verseText)
        put("verseRef", e.verseRef)
        put("dayIndex", e.dayIndex)
        put("lang", e.lang)
    }

    private fun fromJson(o: JSONObject) = Entry(
        requestCode = o.optInt("requestCode"),
        hour = o.optInt("hour"),
        minute = o.optInt("minute"),
        soundUri = o.optString("soundUri").takeIf { it.isNotEmpty() },
        title = o.optString("title"),
        body = o.optString("body"),
        verseText = o.optString("verseText").takeIf { it.isNotEmpty() },
        verseRef = o.optString("verseRef").takeIf { it.isNotEmpty() },
        dayIndex = o.optInt("dayIndex"),
        lang = o.optString("lang").takeIf { it.isNotEmpty() },
    )

    private fun readAll(context: Context): List<Entry> {
        val f = file(context)
        if (!f.exists()) return emptyList()
        return try {
            val arr = JSONArray(f.readText())
            (0 until arr.length()).mapNotNull { idx ->
                try { fromJson(arr.getJSONObject(idx)) } catch (_: Exception) { null }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun writeAll(context: Context, entries: List<Entry>) {
        val arr = JSONArray()
        entries.forEach { arr.put(toJson(it)) }
        file(context).writeText(arr.toString())
    }

    @Synchronized
    fun upsert(context: Context, e: Entry) {
        val all = readAll(context).filterNot { it.requestCode == e.requestCode }
        writeAll(context, all + e)
    }

    @Synchronized
    fun remove(context: Context, requestCode: Int) {
        writeAll(context, readAll(context).filterNot { it.requestCode == requestCode })
    }

    @Synchronized
    fun entries(context: Context): List<Entry> = readAll(context)
}
