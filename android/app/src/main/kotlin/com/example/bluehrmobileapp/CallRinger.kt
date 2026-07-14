package ai.bluecs.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

/**
 * Process-wide incoming-call ringer (sound + vibration).
 *
 * A singleton on purpose: the app runs TWO Flutter engines (MainActivity and
 * CallActivity), and the old per-activity `ringtone` field meant a ring
 * started in one activity could never be stopped from the other — accept a
 * call in the CallActivity engine and MainActivity's ringtone kept ringing.
 * CallActionReceiver also stops this directly so the ring dies the instant
 * Accept/Decline is tapped on the notification, before any Dart runs.
 *
 * Sound rides the RINGTONE stream (follows the phone's ringer volume) and
 * honors the ringer mode: normal → sound + vibration, vibrate → vibration
 * only, silent → nothing.
 */
object CallRinger {

    private var ringtone: Ringtone? = null

    @Synchronized
    fun play(context: Context) {
        val appContext = context.applicationContext
        val audioManager =
            appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val ringerMode = audioManager.ringerMode

        if (ringerMode != AudioManager.RINGER_MODE_SILENT) {
            startVibration(appContext)
        }
        if (ringerMode != AudioManager.RINGER_MODE_NORMAL) {
            return // silent or vibrate-only — no sound
        }

        // App ringtone from res/raw; fall back to the system default.
        val uri: Uri = try {
            Uri.parse("android.resource://${appContext.packageName}/${R.raw.hangouts_call}")
        } catch (_: Exception) {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        }
        ringtone?.stop()
        ringtone = RingtoneManager.getRingtone(appContext, uri)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
            }
        }
        ringtone?.play()
    }

    @Synchronized
    fun stop(context: Context) {
        ringtone?.stop()
        ringtone = null
        try {
            val vibrator = context.applicationContext
                .getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator.cancel()
        } catch (_: Exception) {}
    }

    private fun startVibration(appContext: Context) {
        try {
            val vibrator =
                appContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (!vibrator.hasVibrator()) return
            val pattern = longArrayOf(0, 1000, 500, 1000, 500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, 1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, 1)
            }
        } catch (_: Exception) {
            // Vibration is best-effort; never break the ring for it.
        }
    }
}
