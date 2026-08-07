package com.amu.beslet_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val requestCode = intent.getIntExtra("requestCode", 1000)
        val timestamp = intent.getLongExtra("timestamp", 0L)

        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            action = AlarmService.ACTION_PLAY
            putExtra(AlarmService.EXTRA_SOUND_URI, intent.getStringExtra(AlarmService.EXTRA_SOUND_URI))
            putExtra(AlarmService.EXTRA_TITLE, intent.getStringExtra(AlarmService.EXTRA_TITLE))
            putExtra(AlarmService.EXTRA_BODY, intent.getStringExtra(AlarmService.EXTRA_BODY))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Re-arm this appointment for the next day.
        if (timestamp > 0L) {
            val rearmIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(AlarmService.EXTRA_SOUND_URI, intent.getStringExtra(AlarmService.EXTRA_SOUND_URI))
                putExtra(AlarmService.EXTRA_TITLE, intent.getStringExtra(AlarmService.EXTRA_TITLE))
                putExtra(AlarmService.EXTRA_BODY, intent.getStringExtra(AlarmService.EXTRA_BODY))
                putExtra("requestCode", requestCode)
                putExtra("timestamp", timestamp)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, requestCode, rearmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp + 24L * 60 * 60 * 1000, pendingIntent)
        }
    }
}
