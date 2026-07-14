package ai.bluecs.app

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Rational
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CallActivity : FlutterActivity() {

    companion object {
        const val CALL_BRIDGE_CHANNEL = "com.bluehr.call/bridge"
        const val CALL_PIP_CHANNEL = "com.bluehr.call/pip"
        const val CALL_VOLUME_CHANNEL = "com.bluehr.call/volume"
        const val RINGTONE_CHANNEL = "com.bluehr.ringtone/default"
        private const val ACTION_MUTE_TOGGLE = "ai.bluecs.app.calling.MUTE_TOGGLE"
        private const val ACTION_HANGUP = "ai.bluecs.app.calling.HANGUP"
    }

    private var pipChannel: MethodChannel? = null
    private var volumeChannel: MethodChannel? = null
    // While true, the hardware volume rocker is forwarded to Flutter (to drive
    // the WebRTC call gain) instead of adjusting the OS stream volume.
    private var callVolumeActive = false
    private var isInPip = false
    private var ringtone: Ringtone? = null

    private val pipActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_MUTE_TOGGLE -> {
                    pipChannel?.invokeMethod("onPipAction", "mute_toggle")
                }
                ACTION_HANGUP -> {
                    pipChannel?.invokeMethod("onPipAction", "hangup")
                }
            }
        }
    }

    /// IMPORTANT: Tell Flutter to start `callMain()` instead of `main()`
    override fun getDartEntrypointFunctionName(): String {
        return "callMain"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Show on lock screen and turn screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // Keep screen on during call
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Register PiP action receiver
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val filter = IntentFilter().apply {
                addAction(ACTION_MUTE_TOGGLE)
                addAction(ACTION_HANGUP)
            }
            registerReceiver(pipActionReceiver, filter, Context.RECEIVER_EXPORTED)
        }

        /// Bridge channel (Flutter ↔ Android)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_BRIDGE_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getCallParams" -> {

                    val params = HashMap<String, Any?>()

                    intent.extras?.let { extras ->

                        params["callId"] = extras.getString("callId", "")
                        params["roomId"] = extras.getString("roomId", "")
                        params["conversationId"] = extras.getString("conversationId", "")
                        params["callType"] = extras.getString("callType", "audio")
                        params["callerName"] = extras.getString("callerName", "")
                        params["callerImage"] = extras.getString("callerImage", "")
                        params["remoteUserId"] = extras.getString("remoteUserId", "")
                        params["remoteUserName"] = extras.getString("remoteUserName", "")
                        params["remoteUserImage"] = extras.getString("remoteUserImage", "")
                        params["isCaller"] = extras.getBoolean("isCaller", true)
                        params["isGroupCall"] = extras.getBoolean("isGroupCall", false)
                        params["iceServers"] = extras.getString("iceServers", "{}")

                    }

                    result.success(params)
                }

                "finishCallActivity" -> {
                    closeCallScreen()
                    result.success(null)
                }

                "closeCallActivity" -> {
                    closeCallScreen()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        /// PiP channel
        pipChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_PIP_CHANNEL
        )

        pipChannel?.setMethodCallHandler { call, result ->

            when (call.method) {

                "enterPip" -> {
                    val success = enterCallPipMode()
                    result.success(success)
                }

                "isInPipMode" -> {

                    val inPip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                        isInPictureInPictureMode
                    else
                        false

                    result.success(inPip)
                }

                else -> result.notImplemented()
            }
        }

        // Ringtone channel — registered here too because CallActivity runs its
        // own FlutterEngine (dart entrypoint `callMain`), so the channel
        // registered in MainActivity isn't reachable from this engine. Without
        // this, DefaultRingtone.stop() throws MissingPluginException when a
        // call is accepted via CallActivity.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RINGTONE_CHANNEL
        ).setMethodCallHandler { call, result ->
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

        // Volume channel — Flutter toggles interception on/off for the duration
        // of a call. While active, dispatchKeyEvent() forwards the hardware
        // volume rocker to Flutter as `onVolumeKey` instead of letting the OS
        // change the (Bluetooth-locked) call-stream volume.
        volumeChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_VOLUME_CHANNEL
        )
        volumeChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setCallVolumeActive" -> {
                    callVolumeActive = call.argument<Boolean>("active") ?: false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (callVolumeActive && !isInPip) {
            val keyCode = event.keyCode
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
            ) {
                if (event.action == KeyEvent.ACTION_DOWN) {
                    volumeChannel?.invokeMethod(
                        "onVolumeKey",
                        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
                    )
                }
                // Consume so the OS doesn't also adjust the call stream (which a
                // Bluetooth/CarPlay device can lock) — gain is handled in Dart.
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    // Delegates to the process-wide CallRinger singleton — a ring started in
    // the MainActivity engine must be stoppable from this engine and vice
    // versa (the old per-activity Ringtone field kept ringing after accept).
    private fun playDefaultRingtone() = CallRinger.play(applicationContext)

    private fun stopDefaultRingtone() = CallRinger.stop(applicationContext)

    /// Auto enter PiP when user presses Home
    override fun onUserLeaveHint() {
        enterCallPipMode()
    }

    private fun enterCallPipMode(): Boolean {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false

        val actions = ArrayList<RemoteAction>()

        // Mute action
        val muteIntent = Intent(ACTION_MUTE_TOGGLE)

        val mutePendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            muteIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val muteAction = RemoteAction(
            Icon.createWithResource(this, android.R.drawable.ic_btn_speak_now),
            "Mute",
            "Toggle mute",
            mutePendingIntent
        )

        actions.add(muteAction)

        // Hangup action
        val hangupIntent = Intent(ACTION_HANGUP)

        val hangupPendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            hangupIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val hangupAction = RemoteAction(
            Icon.createWithResource(this, android.R.drawable.ic_menu_call),
            "Hang Up",
            "End call",
            hangupPendingIntent
        )

        actions.add(hangupAction)

        val params = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(9, 16))
            .setActions(actions)
            .build()

        return enterPictureInPictureMode(params)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {

        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)

        isInPip = isInPictureInPictureMode

        pipChannel?.invokeMethod(
            "onPipModeChanged",
            isInPictureInPictureMode
        )
    }

    private fun closeCallScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }
    }

    override fun onDestroy() {

        try {
            unregisterReceiver(pipActionReceiver)
        } catch (_: Exception) {}

        try {
            ringtone?.stop()
        } catch (_: Exception) {}
        ringtone = null

        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        super.onDestroy()
    }
}