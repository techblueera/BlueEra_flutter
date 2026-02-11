package ai.bluecs.app

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Rational
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vahcare.lab/pip"
    private val ACTION_COMPLETE_RIDE = "ACTION_COMPLETE_RIDE"
    private var isPipEnabled = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val filter = IntentFilter(ACTION_COMPLETE_RIDE)
            // Note: Use Context.RECEIVER_EXPORTED if targeting Android 14+
            registerReceiver(pipReceiver, filter, Context.RECEIVER_EXPORTED)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePipStatus" -> {
                    isPipEnabled = call.argument<Boolean>("isEnabled") ?: false
                    result.success(null)
                }
                "enterPip" -> {
                    enterPipMode()
                    result.success(true)
                }
                "isInPipMode" -> {
                    val inPip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) isInPictureInPictureMode else false
                    result.success(inPip)
                }
                else -> result.notImplemented()
            }
        }
    }

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_COMPLETE_RIDE) {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("completeRide", null)
                }
            }
        }
    }

    override fun onUserLeaveHint() {
        if (isPipEnabled) {
            enterPipMode()
        } else {
            super.onUserLeaveHint()
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(1, 1))
                .build()

            enterPictureInPictureMode(params)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(pipReceiver)
        } catch (e: Exception) {}
        super.onDestroy()
    }
}


/*class MainActivity : FlutterActivity() {
//    override fun onUserLeaveHint() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            // Set the aspect ratio (e.g., 16:9 for video or 1:1 for a lab report)
//            val aspectRatio = Rational(16, 9)
//            val params = PictureInPictureParams.Builder()
//                .setAspectRatio(aspectRatio)
//                .build()
//            enterPictureInPictureMode(params)
//        }
//    }


    private val CHANNEL = "com.vahcare.lab/pip"


    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val aspectRatio = Rational(16, 9)
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio) // Square ratio for lab stats
                .build()
            enterPictureInPictureMode(params)
        }
    }

    private val SCREEN_CHANNEL = "com.bluehr.screenshot/channel"
    private val VIDEO_CHANNEL = "com.bluehr.video/keep_screen_on"

    // 👉 Added new channel for ringtone
    private val RINGTONE_CHANNEL = "com.bluehr.ringtone/default"

    // 👉 Ringtone instance
    private var ringtone: Ringtone? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "enterPip") {
                enterPipMode()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

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
}*/

//Dont Delete below code -by Boopathi
//class MainActivity: FlutterActivity() {
//    private val CHANNEL = "com.vahcare.lab/pip"
//    private val ACTION_COMPLETE_RIDE = "ACTION_COMPLETE_RIDE"
//    private var isPipEnabled = false
//
//    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            val filter = IntentFilter(ACTION_COMPLETE_RIDE)
//            // Note: Use Context.RECEIVER_EXPORTED if targeting Android 14+
//            registerReceiver(pipReceiver, filter, Context.RECEIVER_EXPORTED)
//        }
//
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//            when (call.method) {
//                "updatePipStatus" -> {
//                    isPipEnabled = call.argument<Boolean>("isEnabled") ?: false
//                    result.success(null)
//                }
//                "enterPip" -> {
//                    enterPipMode()
//                    result.success(true)
//                }
//                "isInPipMode" -> {
//                    val inPip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) isInPictureInPictureMode else false
//                    result.success(inPip)
//                }
//                else -> result.notImplemented()
//            }
//        }
//    }
//
//    private val pipReceiver = object : BroadcastReceiver() {
//        override fun onReceive(context: Context, intent: Intent) {
//            if (intent.action == ACTION_COMPLETE_RIDE) {
//                flutterEngine?.dartExecutor?.binaryMessenger?.let {
//                    MethodChannel(it, CHANNEL).invokeMethod("completeRide", null)
//                }
//            }
//        }
//    }
//
//    override fun onUserLeaveHint() {
//        if (isPipEnabled) {
//            enterPipMode()
//        } else {
//            super.onUserLeaveHint()
//        }
//    }
//
//    private fun enterPipMode() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            val actions = ArrayList<RemoteAction>()
//
//            // Intent for the button
//            val intent = Intent(ACTION_COMPLETE_RIDE)
//            val pendingIntent = PendingIntent.getBroadcast(
//                this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
//            )
//
//
//            val icon = Icon.createWithResource(this, android.R.drawable.ic_menu_save)
//
//            val remoteAction = RemoteAction(
//                icon,
//                "Cancel Ride",  // Text Label
//                "Cancel",       // Content Description
//                pendingIntent
//            )
//
//
//            remoteAction.isEnabled = true
//
//            actions.add(remoteAction)
//
//            val params = PictureInPictureParams.Builder()
//                .setAspectRatio(Rational(1, 1))
//                .setActions(actions)
//                .build()
//            enterPictureInPictureMode(params)
//        }
//    }
//
//    override fun onDestroy() {
//        try {
//            unregisterReceiver(pipReceiver)
//        } catch (e: Exception) {}
//        super.onDestroy()
//    }
//}