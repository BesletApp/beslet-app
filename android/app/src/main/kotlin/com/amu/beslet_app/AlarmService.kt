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
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var stopFuture: ScheduledFuture<*>? = null
    private val autoStopExecutor = Executors.newSingleThreadScheduledExecutor()

    companion object {
        const val CHANNEL_ID = "prayer_alarm_playing"
        const val NOTIFICATION_ID = 200
        const val ALARM_DURATION_MINUTES = 5L
        const val ACTION_PLAY = "com.amu.beslet_app.ALARM_PLAY"
        const val ACTION_DISMISS = "com.amu.beslet_app.ALARM_DISMISS"
        const val ACTION_ALARM_FINISHED = "com.amu.beslet_app.ALARM_FINISHED"
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
                startForegroundWithNotification(title, body, soundUri, intent)
                startPlaying(soundUri)
                // A neighbouring slot firing while one is still ringing fully
                // supersedes it: reset the auto-stop and wake period so the
                // earlier run can never end the newer alarm early.
                renewWakeLock()
                scheduleAutoStop(ALARM_DURATION_MINUTES * 60_000L)
                launchFullScreen(intent)
            }
            ACTION_DISMISS -> stopAlarm()
        }
        return START_STICKY
    }

    /** Puts the full-screen prayer screen above the lock screen via the
     *  notification's full-screen intent (the documented, background-activity
     *  exempt way to surface an Activity when the process may be dead). */
    private fun launchFullScreen(intent: Intent) {
        try {
            startActivity(buildActivityIntent(intent))
        } catch (_: Exception) {
            // Background start blocked (unlikely for an alarm) — the
            // full-screen intent on the notification still surfaces it.
        }
    }

    private fun buildActivityIntent(intent: Intent): Intent =
        Intent(this, PrayerAlarmActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_TITLE, intent.getStringExtra(EXTRA_TITLE))
            putExtra(EXTRA_BODY, intent.getStringExtra(EXTRA_BODY))
            putExtra("verseText", intent.getStringExtra("verseText"))
            putExtra("verseRef", intent.getStringExtra("verseRef"))
            putExtra("hour", intent.getIntExtra("hour", -1))
            putExtra("minute", intent.getIntExtra("minute", -1))
            putExtra("dayIndex", intent.getIntExtra("dayIndex", 0))
            putExtra("lang", intent.getStringExtra("lang"))
        }

    private fun startForegroundWithNotification(title: String, body: String, soundUri: String?, sourceIntent: Intent) {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = openIntent?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        val dismissIntent = Intent(this, AlarmService::class.java).apply { action = ACTION_DISMISS }
        val dismissPendingIntent = PendingIntent.getService(this, 1, dismissIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        // Same intent that launchFullScreen() uses, so the full-screen surface
        // shows the correct time and verse even when the process was dead.
        val fullScreenIntent = buildActivityIntent(sourceIntent)
        val fullScreenPendingIntent = PendingIntent.getActivity(this, 2, fullScreenIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(openPendingIntent)
            .addAction(android.R.drawable.ic_lock_idle_alarm, getString(R.string.alarm_dismiss), dismissPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setFullScreenIntent(fullScreenPendingIntent, true)
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

    private fun scheduleAutoStop(delayMs: Long = ALARM_DURATION_MINUTES * 60_000L) {
        stopFuture?.cancel(false)
        stopFuture = autoStopExecutor.schedule({ stopAlarm() }, delayMs, TimeUnit.MILLISECONDS)
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
        sendBroadcast(Intent(ACTION_ALARM_FINISHED))
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP, "Beslet:AlarmWakeLock")
        wakeLock?.acquire(TimeUnit.MINUTES.toMillis(ALARM_DURATION_MINUTES + 1))
    }

    private fun renewWakeLock() {
        releaseWakeLock()
        acquireWakeLock()
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
        stopFuture?.cancel(false)
        stopFuture = null
        autoStopExecutor.shutdownNow()
        stopAlarm()
        super.onDestroy()
    }
}
