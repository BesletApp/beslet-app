package com.amu.beslet_app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The full-screen prayer alarm: shows the prayer time, date and today's verse
 * above the lock screen. "Pray Now" dismisses and opens the prayer screen;
 * "Dismiss" only stops the alarm. Also finishes itself when AlarmService
 * auto-stops after five minutes.
 */
class PrayerAlarmActivity : Activity() {

    private val finishReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == AlarmService.ACTION_ALARM_FINISHED) finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Pre-27 the theme attributes don't exist; apply flags manually. The
        // theme already sets windowShowWhenLocked / windowTurnScreenOn on 27+.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_prayer_alarm)

        configureUi(intent)

        ContextCompat.registerReceiver(
            this,
            finishReceiver,
            IntentFilter(AlarmService.ACTION_ALARM_FINISHED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        configureUi(intent)
    }

    private fun configureUi(intent: Intent?) {
        val hour = intent?.getIntExtra("hour", -1) ?: -1
        val minute = intent?.getIntExtra("minute", -1) ?: -1
        val verseText = intent?.getStringExtra("verseText").orEmpty()
        val verseRef = intent?.getStringExtra("verseRef").orEmpty()

        val timeText = findViewById<TextView>(R.id.timeText)
        val label = findViewById<TextView>(R.id.alarmLabel)
        val lang = intent?.getStringExtra("lang") ?: "en"
        val isAm = lang == "am"

        if (hour >= 0 && minute >= 0) {
            timeText.text = String.format(Locale.getDefault(), "%d:%02d", hour, minute)
        } else {
            timeText.text = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date())
        }

        val title = if (isAm) "የጸሎት ጊዜ" else "Time to pray"
        label.text = title

        findViewById<TextView>(R.id.dateText).text =
            SimpleDateFormat("EEEE, MMMM d", Locale.getDefault()).format(Date())

        val verse = findViewById<TextView>(R.id.verseText)
        verse.text = verseText.ifEmpty { "" }
        findViewById<TextView>(R.id.verseRef).text = verseRef

        applyFonts(verse, isAm)

        findViewById<View>(R.id.btnPrayNow).setOnClickListener {
            dismiss(openPrayer = true)
        }
        findViewById<View>(R.id.btnDismiss).setOnClickListener {
            dismiss(openPrayer = false)
        }
    }

    private fun applyFonts(verse: TextView, isAm: Boolean) {
        // The verse is Amharic scripture; prefer the bundled Ethiopic font.
        val paths = listOf(
            "flutter_assets/assets/fonts/NotoSansEthiopic.ttf",
            "assets/fonts/NotoSansEthiopic.ttf",
        )
        for (p in paths) {
            try {
                val t = Typeface.createFromAsset(assets, p)
                verse.typeface = t
                return
            } catch (_: Exception) {}
        }
        if (isAm) {
            verse.typeface = Typeface.create("notoserif", Typeface.NORMAL)
        }
    }

    private fun dismiss(openPrayer: Boolean) {
        stopPlayback()
        finish()
        if (openPrayer) {
            MainActivity.pendingLaunchRoute = "/prayer"
            val launch = packageManager.getLaunchIntentForPackage(packageName)
            launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try { startActivity(launch) } catch (_: Exception) {}
        }
    }

    private fun stopPlayback() {
        val dismissIntent = Intent(this, AlarmService::class.java).apply {
            action = AlarmService.ACTION_DISMISS
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(dismissIntent)
            } else {
                startService(dismissIntent)
            }
        } catch (e: Exception) {
            // The activity is foreground, so this is only defensive; nothing
            // left ringing either way.
            android.util.Log.w(TAG, "stopPlayback FGS start blocked", e)
        }
    }

    override fun onBackPressed() {
        // Backing out should not leave the alarm ringing silently forever —
        // treat it like Dismiss so the user is not trapped.
        dismiss(openPrayer = false)
    }

    companion object {
        private const val TAG = "BesletAlarm"
    }

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(finishReceiver) } catch (_: Exception) {}
    }
}