package com.amu.beslet_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Sound operations
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

                        val intent = Intent(this, AlarmReceiver::class.java).apply {
                            putExtra(AlarmService.EXTRA_SOUND_URI, soundUri)
                            putExtra(AlarmService.EXTRA_TITLE, title)
                            putExtra(AlarmService.EXTRA_BODY, body)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this, requestCode, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (alarmManager.canScheduleExactAlarms()) {
                                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
                            } else {
                                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
                            }
                        } else {
                            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
                        }
                        result.success(true)
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
}
