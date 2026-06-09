package com.amu.beslet_app

import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val CHANNEL_ID = "prayer_alarm_playing"
        const val NOTIFICATION_ID = 200
        const val ALARM_DURATION_MINUTES = 5L
        const val ACTION_PLAY = "com.amu.beslet_app.ALARM_PLAY"
        const val ACTION_DISMISS = "com.amu.beslet_app.ALARM_DISMISS"
        const val EXTRA_SOUND_URI = "sound_uri"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
    }

    override fun onCreate() {
        super.onCreate()
        acquireWakeLock()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                val soundUri = intent.getStringExtra(EXTRA_SOUND_URI)
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Time to pray! \uD83D\uDE4F"
                val body = intent.getStringExtra(EXTRA_BODY) ?: "Your prayer reminder"
                startForegroundWithNotification(title, body, soundUri)
                startPlaying(soundUri)
                scheduleAutoStop()
            }
            ACTION_DISMISS -> stopAlarm()
        }
        return START_STICKY
    }

    private fun startForegroundWithNotification(title: String, body: String, soundUri: String?) {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(this, 0, openIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val dismissIntent = Intent(this, AlarmService::class.java).apply { action = ACTION_DISMISS }
        val dismissPendingIntent = PendingIntent.getService(this, 1, dismissIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(openPendingIntent)
            .addAction(android.R.drawable.ic_lock_idle_alarm, "Dismiss", dismissPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setFullScreenIntent(openPendingIntent, true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun startPlaying(soundUri: String?) {
        mediaPlayer?.release()
        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build())
            setLooping(true)
            setVolume(1.0f, 1.0f)
            try {
                if (soundUri != null && soundUri.isNotEmpty()) {
                    setDataSource(applicationContext, Uri.parse(soundUri))
                } else {
                    val defaultUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    setDataSource(applicationContext, defaultUri)
                }
            } catch (e: Exception) {
                try {
                    val defaultUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    setDataSource(applicationContext, defaultUri)
                } catch (e2: Exception) {
                    stopAlarm()
                    return
                }
            }
            prepare()
            start()
        }
    }

    private fun scheduleAutoStop() {
        Executors.newSingleThreadScheduledExecutor().schedule({
            stopAlarm()
        }, ALARM_DURATION_MINUTES, TimeUnit.MINUTES)
    }

    private fun stopAlarm() {
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
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP, "Beslet:AlarmWakeLock")
        wakeLock?.acquire(TimeUnit.MINUTES.toMillis(ALARM_DURATION_MINUTES + 1))
    }

    private fun releaseWakeLock() {
        wakeLock?.apply { if (isHeld) release() }
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = android.app.NotificationChannel(CHANNEL_ID, "Prayer Alarm Playing",
                NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null)
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }
}
