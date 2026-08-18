package com.amu.beslet_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * A tiny JSON mirror of the one-off reminders that were armed by Flutter so the
 * native side can re-arm them after a reboot (AlarmManager alarms do not survive
 * a reboot). Written by MainActivity on every schedule/cancel and read by
 * ReminderAlarmReceiver on BOOT_COMPLETED / MY_PACKAGE_REPLACED. Firing is
 * one-shot: the receiver deletes the entry the moment the alarm goes off.
 */
object ReminderAlarmMirror {

    data class Entry(
        val requestCode: Int,
        val fireAt: Long,
        val note: String,
    )

    private fun file(context: Context) = java.io.File(context.filesDir, "reminder_alarms.json")

    private fun toJson(e: Entry) = JSONObject().apply {
        put("requestCode", e.requestCode)
        put("fireAt", e.fireAt)
        put("note", e.note)
    }

    private fun fromJson(o: JSONObject) = Entry(
        requestCode = o.optInt("requestCode"),
        fireAt = o.optLong("fireAt"),
        note = o.optString("note"),
    )

    @Synchronized
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

    @Synchronized
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
    fun entry(context: Context, requestCode: Int): Entry? =
        readAll(context).firstOrNull { it.requestCode == requestCode }

    @Synchronized
    fun entries(context: Context): List<Entry> = readAll(context)
}