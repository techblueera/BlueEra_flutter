package ai.bluecs.app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Direct bridge to flutter_webrtc's process-wide AudioSwitchManager singleton.
 *
 * Why this exists: FlutterWebRTCPlugin.startListening() runs
 * `AudioSwitchManager.instance = new AudioSwitchManager(context)` on EVERY
 * engine attach. This app still runs more than one (MainActivity, the FCM
 * background isolate, the overlay window), so any engine attaching mid-call
 * swaps the singleton for a fresh instance that was never activate()d.
 * From then on `Helper.selectAudioOutput(...)` records a selection that is
 * never applied — the speaker button lights up in the UI while the audio stays
 * on the earpiece, and the failure is invisible because nothing throws.
 *
 * This bridge re-activates whichever instance is current *before* selecting,
 * and reads the selection back afterwards so Dart can render the route that is
 * genuinely live instead of the one it asked for.
 *
 * Everything goes through reflection deliberately: com.twilio.audioswitch is a
 * transitive `implementation` dependency of the plugin and is not on this
 * module's compile classpath, so `selectedAudioDevice()` cannot be named
 * directly. Reflection also means a plugin upgrade degrades to "no read-back"
 * instead of a build failure.
 */
object CallAudioBridge {

    const val CHANNEL = "com.bluehr.call/audio_route"

    private const val MANAGER_CLASS = "com.cloudwebrtc.webrtc.audio.AudioSwitchManager"
    private const val KIND_CLASS = "com.cloudwebrtc.webrtc.audio.AudioDeviceKind"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "selectOutput" -> {
                    applySelection(call.argument<String>("name") ?: "")
                    // start() and selectAudioOutput() both hop through the
                    // manager's own main-looper handler; posting here puts the
                    // read-back behind them on the same queue.
                    Handler(Looper.getMainLooper()).post {
                        result.success(currentOutputName())
                    }
                }
                "currentOutput" -> result.success(currentOutputName())
                else -> result.notImplemented()
            }
        }
    }

    private fun manager(): Any? = try {
        Class.forName(MANAGER_CLASS).getField("instance").get(null)
    } catch (t: Throwable) {
        null
    }

    private fun applySelection(typeName: String) {
        val mgr = manager() ?: return
        try {
            // Idempotent — the manager guards on its own isActive flag. Must run
            // BEFORE the select: start() calls removeCallbacksAndMessages(null)
            // on the shared handler, which would drop a pending selection.
            mgr.javaClass.getMethod("start").invoke(mgr)
        } catch (_: Throwable) {
        }
        if (typeName.isEmpty()) return
        try {
            val kindCls = Class.forName(KIND_CLASS)
            val kind = kindCls
                .getMethod("fromTypeName", String::class.java)
                .invoke(null, typeName) ?: return
            mgr.javaClass.getMethod("selectAudioOutput", kindCls).invoke(mgr, kind)
        } catch (_: Throwable) {
        }
    }

    /** The route the plugin currently has selected, or null if unreadable. */
    private fun currentOutputName(): String? {
        val mgr = manager() ?: return null
        val device = try {
            mgr.javaClass.getMethod("selectedAudioDevice").invoke(mgr)
        } catch (_: Throwable) {
            null
        } ?: return null
        // Names match AudioDeviceKind.typeName on the plugin side.
        return when (device.javaClass.simpleName) {
            "Speakerphone" -> "speaker"
            "Earpiece" -> "earpiece"
            "BluetoothHeadset" -> "bluetooth"
            "WiredHeadset" -> "wired-headset"
            else -> null
        }
    }
}
