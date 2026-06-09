package com.amu.beslet_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
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
    }
}
