package ai.bluecs.app

import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val SCREEN_CHANNEL = "com.bluehr.screenshot/channel"
    private val VIDEO_CHANNEL = "com.bluehr.video/keep_screen_on"

    // 👉 Added new channel for ringtone
    private val RINGTONE_CHANNEL = "com.bluehr.ringtone/default"

    // 👉 Ringtone instance
    private var ringtone: Ringtone? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ------------------------------
        // EXISTING SCREENSHOT CHANNEL
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureScreen" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }
                    "disableSecureScreen" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ------------------------------
        // EXISTING VIDEO KEEP SCREEN ON CHANNEL
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepOn" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "keepOff" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ------------------------------
        // NEW RINGTONE CHANNEL
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playRingtone" -> {
                        playDefaultRingtone()
                        result.success(null)
                    }
                    "stopRingtone" -> {
                        stopDefaultRingtone()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ------------------------------
    // PLAY DEFAULT SYSTEM RINGTONE
    // ------------------------------
    private fun playDefaultRingtone() {
        val uri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        ringtone = RingtoneManager.getRingtone(applicationContext, uri)
        ringtone?.play()
    }

    // ------------------------------
    // STOP RINGTONE
    // ------------------------------
    private fun stopDefaultRingtone() {
        ringtone?.stop()
    }
}
