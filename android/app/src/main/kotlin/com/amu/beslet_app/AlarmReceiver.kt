package com.amu.beslet_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                reArmFromMirror(context)
                return
            }
        }

        val requestCode = intent.getIntExtra("requestCode", 1000)

        // Start the foreground service that plays the sound.
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            action = AlarmService.ACTION_PLAY
            putExtra(AlarmService.EXTRA_SOUND_URI, intent.getStringExtra(AlarmService.EXTRA_SOUND_URI))
            putExtra(AlarmService.EXTRA_TITLE, intent.getStringExtra(AlarmService.EXTRA_TITLE))
            putExtra(AlarmService.EXTRA_BODY, intent.getStringExtra(AlarmService.EXTRA_BODY))
            putExtra("verseText", intent.getStringExtra("verseText"))
            putExtra("verseRef", intent.getStringExtra("verseRef"))
            putExtra("hour", intent.getIntExtra("hour", -1))
            putExtra("minute", intent.getIntExtra("minute", -1))
            putExtra("dayIndex", intent.getIntExtra("dayIndex", 0))
            putExtra("lang", intent.getStringExtra("lang"))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Re-arm this appointment for the next day. The next fire is derived
        // from the wall-clock hour/minute (not an absolute +24h shift) so a
        // timezone or DST change while the app is closed cannot drift the
        // follow-up alarm, and it stays exact whenever exact alarms are allowed.
        val hour = intent.getIntExtra("hour", -1)
        val minute = intent.getIntExtra("minute", -1)
        if (hour >= 0 && minute >= 0) {
            val nextFire = nextOccurrence(context, hour, minute)

            val rearmIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(AlarmService.EXTRA_SOUND_URI, intent.getStringExtra(AlarmService.EXTRA_SOUND_URI))
                putExtra(AlarmService.EXTRA_TITLE, intent.getStringExtra(AlarmService.EXTRA_TITLE))
                putExtra(AlarmService.EXTRA_BODY, intent.getStringExtra(AlarmService.EXTRA_BODY))
                putExtra("requestCode", requestCode)
                putExtra("timestamp", nextFire)
                putExtra("hour", hour)
                putExtra("minute", minute)
                putExtra("verseText", intent.getStringExtra("verseText"))
                putExtra("verseRef", intent.getStringExtra("verseRef"))
                putExtra("dayIndex", intent.getIntExtra("dayIndex", 0))
                putExtra("lang", intent.getStringExtra("lang"))
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, requestCode, rearmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            scheduleExact(context, alarmManager, nextFire, pendingIntent)
        }
    }

    /** The next moment at [hour]:[minute] in the device's local zone (today if
     *  still upcoming, otherwise tomorrow). */
    private fun nextOccurrence(context: Context, hour: Int, minute: Int): Long {
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        var fireAt = cal.timeInMillis
        if (fireAt <= now) fireAt += 24L * 60 * 60 * 1000
        return fireAt
    }

    /** Exact when the system allows it, exact-quality fallback otherwise. */
    private fun scheduleExact(context: Context, alarmManager: AlarmManager, fireAt: Long, pendingIntent: PendingIntent) {
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

    /** Re-arms every prayer stored in the mirror after a reboot. */
    private fun reArmFromMirror(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (e in PrayerAlarmMirror.entries(context)) {
            val fireAt = nextOccurrence(context, e.hour, e.minute)

            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(AlarmService.EXTRA_SOUND_URI, e.soundUri)
                putExtra(AlarmService.EXTRA_TITLE, e.title)
                putExtra(AlarmService.EXTRA_BODY, e.body)
                putExtra("requestCode", e.requestCode)
                putExtra("timestamp", fireAt)
                putExtra("hour", e.hour)
                putExtra("minute", e.minute)
                putExtra("verseText", e.verseText)
                putExtra("verseRef", e.verseRef)
                putExtra("dayIndex", e.dayIndex)
                putExtra("lang", e.lang)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, e.requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            scheduleExact(context, alarmManager, fireAt, pendingIntent)
        }
    }
}
