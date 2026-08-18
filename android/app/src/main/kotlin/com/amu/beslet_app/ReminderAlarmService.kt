package com.amu.beslet_app

import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Rings a gentle one-off reminder: a short soft chime plus a heads-up
 * notification showing the note, with Snooze / Dismiss actions. Stays
 * foreground only for the duration of the chime so OEMs cannot kill it late.
 */
class ReminderAlarmService : Service() {

    companion object {
        const val CHANNEL_ID = "reminder_alarm_playing"
        const val NOTIFICATION_ID = 300
        const val CHIME_DURATION_MS = 7000L
        const val ACTION_PLAY = "com.amu.beslet_app.REMINDER_PLAY"
        const val ACTION_DISMISS = "com.amu.beslet_app.REMINDER_DISMISS"
        const val EXTRA_REQUEST_CODE = "requestCode"
        const val EXTRA_NOTE = "note"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var stopFuture: ScheduledFuture<*>? = null
    private val autoStopExecutor = Executors.newSingleThreadScheduledExecutor()

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                val requestCode = intent.getIntExtra(EXTRA_REQUEST_CODE, -1)
                val note = intent.getStringExtra(EXTRA_NOTE) ?: getString(R.string.reminder_notification_title)
                startForegroundWithNotification(requestCode, note)
                acquireWakeLock()
                playChime()
                vibrate()
                stopFuture?.cancel(false)
                stopFuture = autoStopExecutor.schedule({ stopAlarm() }, CHIME_DURATION_MS, TimeUnit.MILLISECONDS)
            }
            ACTION_DISMISS -> stopAlarm()
            else -> stopAlarm()
        }
        return START_NOT_STICKY
    }

    private fun startForegroundWithNotification(requestCode: Int, note: String) {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = openIntent?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        val snoozeAction = PendingIntent.getBroadcast(
            this, requestCode,
            Intent(this, ReminderAlarmReceiver::class.java).apply {
                action = ReminderAlarmReceiver.ACTION_SNOOZE
                putExtra(EXTRA_REQUEST_CODE, requestCode)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val dismissAction = PendingIntent.getBroadcast(
            this, requestCode + 1,
            Intent(this, ReminderAlarmReceiver::class.java).apply {
                action = ReminderAlarmReceiver.ACTION_DISMISS
                putExtra(EXTRA_REQUEST_CODE, requestCode)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.reminder_notification_title))
            .setContentText(note)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(openPendingIntent)
            .addAction(android.R.drawable.ic_lock_idle_alarm, getString(R.string.reminder_snooze), snoozeAction)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, getString(R.string.reminder_dismiss), dismissAction)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun playChime() {
        mediaPlayer?.release()
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build())
                setLooping(false)
                setVolume(0.4f, 0.4f)
                setDataSource(this@ReminderAlarmService, android.net.Uri.parse(
                    "android.resource://$packageName/${R.raw.prayer_alarm}"
                ))
                prepare()
                start()
            }
        } catch (_: Exception) {
            mediaPlayer = null
        }
    }

    private fun vibrate() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(300, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(300)
            }
        } catch (_: Exception) {
        }
    }

    private fun stopAlarm() {
        stopFuture?.cancel(false)
        stopFuture = null
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Beslet:ReminderWakeLock")
        wakeLock?.acquire(CHIME_DURATION_MS + 2000)
    }

    private fun releaseWakeLock() {
        wakeLock?.apply { if (isHeld) release() }
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = android.app.NotificationChannel(CHANNEL_ID,
                getString(R.string.reminder_notification_title),
                NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null)
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopFuture?.cancel(false)
        stopFuture = null
        autoStopExecutor.shutdownNow()
        stopAlarm()
        super.onDestroy()
    }
}