package com.amu.beslet_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)        // Sound operations
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beslet_app/sounds")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDefaultAlarmUri" -> {
                        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        result.success(uri?.toString())
                    }
                    "deleteNotificationChannel" -> {
                        val id = call.argument<String>("id")
                        if (id != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                            nm.deleteNotificationChannel(id)
                        }
                        result.success(true)
                    }
                    "saveAlarmSound" -> {
                        val src = call.argument<String>("src") ?: ""
                        val ext = call.argument<String>("ext") ?: "mp3"
                        val soundsDir = File(filesDir, "sounds")
                        soundsDir.mkdirs()
                        val dest = File(soundsDir, "prayer_alarm_custom.$ext")
                        try {
                            val srcUri = Uri.parse(src)
                            contentResolver.openInputStream(srcUri)?.use { input ->
                                dest.outputStream().use { output -> input.copyTo(output) }
                            }
                        } catch (_: Exception) {
                            try {
                                File(src).inputStream().use { it.copyTo(dest.outputStream()) }
                            } catch (e2: Exception) {
                                result.error("COPY_FAILED", "Could not copy sound file", null)
                                return@setMethodCallHandler
                            }
                        }
                        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", dest)
                        result.success(uri.toString())
                    }
                    "schedulePlaybackAlarm" -> {
                        val timestamp = call.argument<Long>("timestamp") ?: 0L
                        val soundUri = call.argument<String>("soundUri")
                        val title = call.argument<String>("title") ?: "Time to pray! \uD83D\uDE4F"
                        val body = call.argument<String>("body") ?: "Your prayer reminder"
                        val requestCode = call.argument<Int>("requestCode") ?: 1000
                        val hour = call.argument<Int>("hour") ?: -1
                        val minute = call.argument<Int>("minute") ?: -1
                        val verseText = call.argument<String>("verseText")
                        val verseRef = call.argument<String>("verseRef")
                        val dayIndex = call.argument<Int>("dayIndex") ?: 0
                        val lang = call.argument<String>("lang") ?: "en"

                        val playableUri = if (soundUri == "resource://prayer_alarm") {
                            "android.resource://$packageName/${R.raw.prayer_alarm}"
                        } else {
                            soundUri
                        }

                        val intent = Intent(this, AlarmReceiver::class.java).apply {
                            putExtra(AlarmService.EXTRA_SOUND_URI, playableUri)
                            putExtra(AlarmService.EXTRA_TITLE, title)
                            putExtra(AlarmService.EXTRA_BODY, body)
                            putExtra("requestCode", requestCode)
                            putExtra("timestamp", timestamp)
                            putExtra("hour", hour)
                            putExtra("minute", minute)
                            putExtra("verseText", verseText)
                            putExtra("verseRef", verseRef)
                            putExtra("dayIndex", dayIndex)
                            putExtra("lang", lang)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this, requestCode, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        var exact = false
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                exact = alarmManager.canScheduleExactAlarms()
                                if (exact) {
                                    alarmManager.setExactAndAllowWhileIdle(
                                        AlarmManager.RTC_WAKEUP, timestamp, pendingIntent
                                    )
                                } else {
                                    alarmManager.setAndAllowWhileIdle(
                                        AlarmManager.RTC_WAKEUP, timestamp, pendingIntent
                                    )
                                }
                            } else {
                                exact = true
                                alarmManager.setExactAndAllowWhileIdle(
                                    AlarmManager.RTC_WAKEUP, timestamp, pendingIntent
                                )
                            }
                        } catch (e: SecurityException) {
                            // Some OEMs (ColorOS etc.) claim exact-alarm support
                            // and then refuse at set-time; degrade to inexact
                            // instead of silently dropping the alarm.
                            Log.e(TAG, "Exact alarm blocked for TC=$requestCode; falling back", e)
                            try {
                                alarmManager.setAndAllowWhileIdle(
                                    AlarmManager.RTC_WAKEUP, timestamp, pendingIntent
                                )
                            } catch (e2: Exception) {
                                Log.e(TAG, "Alarm scheduling failed for TC=$requestCode", e2)
                                result.error("ALARM_SCHEDULE_FAILED", e2.message, null)
                                return@setMethodCallHandler
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Alarm scheduling failed for TC=$requestCode", e)
                            result.error("ALARM_SCHEDULE_FAILED", e.message, null)
                            return@setMethodCallHandler
                        }
                        Log.i(TAG, "Armed prayer alarm TC=$requestCode at $timestamp (exact=$exact)")

                        PrayerAlarmMirror.upsert(
                            this,
                            PrayerAlarmMirror.Entry(
                                requestCode = requestCode,
                                hour = hour,
                                minute = minute,
                                soundUri = playableUri,
                                title = title,
                                body = body,
                                verseText = verseText,
                                verseRef = verseRef,
                                dayIndex = dayIndex,
                                lang = lang,
                            )
                        )
                        result.success(mapOf("scheduled" to true, "exact" to exact))
                    }
                    "getExactAlarmStatus" -> {
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
                        result.success(canExact)
                    }
                    "cancelPlaybackAlarm" -> {
                        val requestCode = call.argument<Int>("requestCode") ?: 1000
                        val intent = Intent(this, AlarmReceiver::class.java)
                        val pendingIntent = PendingIntent.getBroadcast(
                            this, requestCode, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        alarmManager.cancel(pendingIntent)
                        pendingIntent.cancel()
                        PrayerAlarmMirror.remove(this, requestCode)
                        result.success(true)
                    }
                    "scheduleOnceReminder" -> {
                        val requestCode = call.argument<Int>("requestCode") ?: 4000
                        val timestamp = call.argument<Long>("timestamp") ?: 0L
                        val note = call.argument<String>("note") ?: "Reminder"
                        ReminderAlarmMirror.upsert(
                            this,
                            ReminderAlarmMirror.Entry(
                                requestCode = requestCode,
                                fireAt = timestamp,
                                note = note,
                            )
                        )
                        val exact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            am.canScheduleExactAlarms()
                        } else {
                            true
                        }
                        try {
                            ReminderAlarmReceiver.scheduleOnce(this, requestCode, timestamp, note)
                            result.success(mapOf("scheduled" to true, "exact" to exact))
                        } catch (e: Exception) {
                            Log.e(TAG, "Reminder schedule failed for TC=$requestCode", e)
                            result.error("REMINDER_SCHEDULE_FAILED", e.message, null)
                        }
                    }
                    "cancelOnceReminder" -> {
                        val requestCode = call.argument<Int>("requestCode") ?: 4000
                        ReminderAlarmReceiver.cancelOnce(this, requestCode)
                        result.success(true)
                    }
                    "snoozeReminder" -> {
                        val requestCode = call.argument<Int>("requestCode") ?: 4000
                        val entry = ReminderAlarmMirror.entry(this, requestCode)
                        if (entry != null) {
                            val fireAt = System.currentTimeMillis() + 9L * 60 * 1000
                            ReminderAlarmMirror.upsert(
                                this,
                                ReminderAlarmMirror.Entry(entry.requestCode, fireAt, entry.note)
                            )
                            ReminderAlarmReceiver.scheduleOnce(this, entry.requestCode, fireAt, entry.note)
                        }
                        result.success(true)
                    }
                    "stopAlarmNow" -> {
                        val stopIntent = Intent(this, AlarmService::class.java).apply {
                            action = AlarmService.ACTION_DISMISS
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(stopIntent)
                        } else {
                            startService(stopIntent)
                        }
                        result.success(true)
                    }
                    "isAlarmPlaying" -> {
                        // Simple check: service might be running
                        result.success(false)
                    }
                    else -> result.notImplemented()
                }
            }

        // Launch route: set by PrayerAlarmActivity ("Pray Now") so the warm
        // start can open straight into the prayer screen.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beslet_app/launch")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchRoute" -> {
                        result.success(pendingLaunchRoute)
                        pendingLaunchRoute = null
                    }
                    else -> result.notImplemented()
                }
            }

        // Notification settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beslet_app/notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            })
                        } else {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            })
                        }
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        @Volatile
        var pendingLaunchRoute: String? = null
        private const val TAG = "BesletAlarm"
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Warm-start launch from the full-screen alarm: the Dart side only
        // polls getLaunchRoute during _warmStart, so push it when the app is
        // already running.
        val route = pendingLaunchRoute
        if (route != null) {
            pendingLaunchRoute = null
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                try {
                    MethodChannel(messenger, "beslet_app/launch").invokeMethod("onLaunchRoute", route, null)
                } catch (_: Exception) {}
            }
        }
    }
}
