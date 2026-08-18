package com.amu.beslet_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class ReminderAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED -> {
                reArmFromMirror(context)
                return
            }
            ACTION_SNOOZE -> {
                val requestCode = intent.getIntExtra("requestCode", -1)
                val entry = if (requestCode >= 0) {
                    ReminderAlarmMirror.entry(context, requestCode)
                } else {
                    null
                }
                if (entry != null) {
                    // Snooze (+9 min) keeps the note and stays one-shot.
                    val fireAt = System.currentTimeMillis() + 9L * 60 * 1000
                    ReminderAlarmMirror.upsert(
                        context,
                        ReminderAlarmMirror.Entry(
                            requestCode = entry.requestCode,
                            fireAt = fireAt,
                            note = entry.note,
                        )
                    )
                    scheduleOnce(context, entry.requestCode, fireAt, entry.note)
                }
                stopReminderSurface(context)
                return
            }
            ACTION_DISMISS -> {
                val requestCode = intent.getIntExtra("requestCode", -1)
                if (requestCode >= 0) ReminderAlarmMirror.remove(context, requestCode)
                stopReminderSurface(context)
                return
            }
        }

        // A reminder fired: it is one-shot, so purge it before ringing.
        val requestCode = intent.getIntExtra("requestCode", -1)
        val note = intent.getStringExtra("note") ?: "Reminder"
        if (requestCode >= 0) ReminderAlarmMirror.remove(context, requestCode)

        val serviceIntent = Intent(context, ReminderAlarmService::class.java).apply {
            action = ReminderAlarmService.ACTION_PLAY
            putExtra("requestCode", requestCode)
            putExtra("note", note)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                context.startForegroundService(serviceIntent)
            } catch (e: Exception) {
                // Inexact (fallback) alarms fire this receiver in the
                // background, where Android 12+ forbids foreground services.
                // The plugin notification leg still rings.
                Log.w(TAG, "Reminder FGS start blocked for TC=$requestCode; plugin leg covers", e)
            }
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun stopReminderSurface(context: Context) {
        val stopIntent = Intent(context, ReminderAlarmService::class.java).apply {
            action = ReminderAlarmService.ACTION_DISMISS
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                context.startForegroundService(stopIntent)
            } catch (e: Exception) {
                // Same background constraint as above; nothing is left ringing.
                Log.w(TAG, "Reminder stop FGS blocked; already cleared", e)
            }
        } else {
            context.startService(stopIntent)
        }
    }

    companion object {
        const val ACTION_FIRE = "com.amu.beslet_app.REMINDER_FIRE"
        const val ACTION_SNOOZE = "com.amu.beslet_app.REMINDER_SNOOZE"
        const val ACTION_DISMISS = "com.amu.beslet_app.REMINDER_DISMISS"
        private const val TAG = "BesletReminder"

        fun scheduleOnce(context: Context, requestCode: Int, fireAt: Long, note: String) {
            val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
                action = ACTION_FIRE
                putExtra("requestCode", requestCode)
                putExtra("note", note)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pendingIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pendingIntent)
            }
        }

        fun cancelOnce(context: Context, requestCode: Int) {
            val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
                action = ACTION_FIRE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            ReminderAlarmMirror.remove(context, requestCode)
        }

        /** After a reboot, re-arm any reminder that has not fired yet. Entries in
         *  the past are purged — they already rang (or were snoozed past). */
        private fun reArmFromMirror(context: Context) {
            val now = System.currentTimeMillis()
            for (e in ReminderAlarmMirror.entries(context)) {
                if (e.fireAt <= now) {
                    ReminderAlarmMirror.remove(context, e.requestCode)
                    continue
                }
                ReminderAlarmMirror.upsert(context, e)
                scheduleOnce(context, e.requestCode, e.fireAt, e.note)
            }
        }
    }
}