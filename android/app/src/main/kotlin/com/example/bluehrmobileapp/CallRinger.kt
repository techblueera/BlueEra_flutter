package ai.bluecs.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator

/**
 * Process-wide incoming-call ringer (sound + vibration).
 *
 * A singleton on purpose: a ring can be started from the UI engine or from the
 * FCM background isolate, and a per-activity `ringtone` field meant a ring
 * started in one could never be stopped from the other. CallActionReceiver
 * also stops this directly so the ring dies the instant Accept/Decline is
 * tapped on the notification, before any Dart runs.
 *
 * Sound rides the RINGTONE stream (follows the phone's ringer volume) and
 * honors the ringer mode: normal → sound + vibration, vibrate → vibration
 * only, silent → nothing.
 *
 * ## Stopping is guaranteed, not assumed
 *
 * A ring that outlives its stop is the worst failure this class has: the phone
 * rings on with nothing on screen to explain it, and `isLooping` means it never
 * ends on its own. Two mechanisms make sure that cannot happen, both needed for
 * different reasons:
 *
 *  - **Retried stops.** On several OEM ROMs a `Ringtone.stop()` issued while
 *    the tone is still preparing is a no-op, and the sound starts *after* the
 *    stop that was supposed to prevent it. So [stop] re-issues itself on the
 *    same object shortly after.
 *  - **A watchdog.** If Dart never calls [stop] at all — screen destroyed,
 *    timer starved in the background, dismiss push never delivered — the ring
 *    ends by itself after [MAX_RING_MS].
 *
 * Both are keyed on [generation] so a *new* ring started in the meantime is
 * never silenced by the previous one's leftovers.
 */
object CallRinger {

    /** Longer than any offer window (ride requests expire in ~45s), so this
     *  only ever fires when something failed to stop the ring. */
    private const val MAX_RING_MS = 75_000L

    /** Re-stop delays, covering a `stop()` that raced the tone's preparation. */
    private val RETRY_STOP_MS = longArrayOf(250L, 1_200L)

    private val handler = Handler(Looper.getMainLooper())

    private var ringtone: Ringtone? = null

    /** Bumped by every [play] and [stop]; pending work from an older
     *  generation is stale and must not touch the current ring. */
    private var generation = 0

    @Synchronized
    fun play(context: Context) {
        val appContext = context.applicationContext
        // Supersede anything pending from a previous ring.
        generation++
        val thisGeneration = generation
        handler.removeCallbacksAndMessages(null)

        val audioManager =
            appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val ringerMode = audioManager.ringerMode

        // Armed before the tone starts: if anything below throws, the ring
        // (or the vibration, which repeats indefinitely) still has an end.
        handler.postDelayed({ stopIfCurrent(appContext, thisGeneration) }, MAX_RING_MS)

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
        stopTone(ringtone)
        ringtone = RingtoneManager.getRingtone(appContext, uri)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
            }
        }
        try {
            ringtone?.play()
        } catch (_: Exception) {
            // Nothing to ring with — make sure we don't leave the watchdog
            // holding a ring that never started.
            stopIfCurrent(appContext, thisGeneration)
        }
    }

    @Synchronized
    fun stop(context: Context) {
        val appContext = context.applicationContext
        generation++
        val thisGeneration = generation
        handler.removeCallbacksAndMessages(null)

        // Held onto for the retries: the field is cleared now so a fresh
        // `play()` can take over, but this instance is the one that may still
        // be coming up on a slow ROM and needs stopping again.
        val target = ringtone
        ringtone = null
        stopTone(target)
        cancelVibration(appContext)

        for (delay in RETRY_STOP_MS) {
            handler.postDelayed({
                synchronized(this) {
                    if (thisGeneration != generation) return@synchronized
                    stopTone(target)
                    cancelVibration(appContext)
                }
            }, delay)
        }
    }

    /** True while a tone is held — lets callers assert the ring really ended. */
    @Synchronized
    fun isPlaying(): Boolean = ringtone != null

    @Synchronized
    private fun stopIfCurrent(context: Context, expectedGeneration: Int) {
        if (expectedGeneration != generation) return
        stop(context)
    }

    private fun stopTone(tone: Ringtone?) {
        try {
            tone?.stop()
        } catch (_: Exception) {
            // Already released / never started — nothing left to silence.
        }
    }

    private fun cancelVibration(context: Context) {
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
