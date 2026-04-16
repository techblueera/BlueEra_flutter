package ai.bluecs.app

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Rational
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.view.WindowManager
import java.net.URL
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: FlutterActivity() {
    private val SCREEN_CHANNEL = "com.bluehr.screenshot/channel"
    private val VIDEO_CHANNEL = "com.bluehr.video/keep_screen_on"
    private val RINGTONE_CHANNEL = "com.bluehr.ringtone/default"
    private val SHORTCUT_CHANNEL = "com.bluehr.shortcut/channel"
    private val CALL_LAUNCHER_CHANNEL = "com.bluehr.call/launcher"
    private val INCOMING_CALL_NOTIF_CHANNEL = "com.bluehr.incoming_call_notification"
    private val MEDIA_SCANNER_CHANNEL = "ai.bluecs.app/media_scanner"

    private var ringtone: Ringtone? = null

    private val CHANNEL = "com.vahcare.lab/pip"
    private val ACTION_COMPLETE_RIDE = "ACTION_COMPLETE_RIDE"
    private var isPipEnabled = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ------------------------------
        // MEDIA SCANNER CHANNEL — makes files show in Gallery
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanFile" -> {
                        val path = call.argument<String>("path") ?: ""
                        if (path.isNotEmpty()) {
                            android.media.MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(path),
                                null
                            ) { _, uri ->
                                // Scan complete — file now visible in Gallery
                            }
                            result.success(true)
                        } else {
                            result.error("INVALID", "Path is empty", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ------------------------------
        // SCREENSHOT CHANNEL
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
        // VIDEO KEEP SCREEN ON CHANNEL
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
        // RINGTONE CHANNEL
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

        // ------------------------------
        // SHORTCUT CHANNEL
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createShortcut" -> {
                        val conversationId = call.argument<String>("conversationId") ?: ""
                        val name = call.argument<String>("name") ?: "Chat"
                        val profileImageUrl = call.argument<String>("profileImage") ?: ""
                        val userId = call.argument<String>("userId") ?: ""
                        val chatType = call.argument<String>("chatType") ?: "personal"

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            createChatShortcut(conversationId, name, profileImageUrl, userId, chatType, result)
                        } else {
                            result.error("UNSUPPORTED", "Shortcuts require Android 8.0+", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ------------------------------
        // CALL LAUNCHER CHANNEL — launches CallActivity in a separate task
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_LAUNCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchCallActivity" -> {
                        val intent = Intent(this@MainActivity, CallActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_MULTIPLE_TASK
                            )
                            putExtra("callId", call.argument<String>("callId") ?: "")
                            putExtra("roomId", call.argument<String>("roomId") ?: "")
                            putExtra("conversationId", call.argument<String>("conversationId") ?: "")
                            putExtra("callType", call.argument<String>("callType") ?: "audio")
                            putExtra("callerName", call.argument<String>("callerName") ?: "")
                            putExtra("callerImage", call.argument<String>("callerImage") ?: "")
                            putExtra("remoteUserId", call.argument<String>("remoteUserId") ?: "")
                            putExtra("remoteUserName", call.argument<String>("remoteUserName") ?: "")
                            putExtra("remoteUserImage", call.argument<String>("remoteUserImage") ?: "")
                            putExtra("isCaller", call.argument<Boolean>("isCaller") ?: true)
                            putExtra("isGroupCall", call.argument<Boolean>("isGroupCall") ?: false)
                            putExtra("iceServers", call.argument<String>("iceServers") ?: "{}")
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "bringCallActivityToFront" -> {
                        val intent = Intent(this@MainActivity, CallActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP
                            )
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ------------------------------
        // INCOMING CALL NOTIFICATION CHANNEL — shows custom notification with filled buttons
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INCOMING_CALL_NOTIF_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as Map<String, Any?>
                        IncomingCallNotificationHelper.show(applicationContext, args)
                        result.success(null)
                    }
                    "cancel" -> {
                        val notifId = call.argument<Int>("notifId") ?: 0
                        IncomingCallNotificationHelper.cancel(applicationContext, notifId)
                        result.success(null)
                    }
                    "readPendingAction" -> {
                        val prefs = applicationContext.getSharedPreferences("call_action_prefs", Context.MODE_PRIVATE)
                        val action = prefs.getString("pending_call_action", null)
                        if (action != null) {
                            val data = mapOf(
                                "action" to action,
                                "callId" to (prefs.getString("pending_call_id", "") ?: ""),
                                "roomId" to (prefs.getString("pending_room_id", "") ?: ""),
                                "callType" to (prefs.getString("pending_call_type", "") ?: "")
                            )
                            prefs.edit().clear().apply()
                            result.success(data)
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

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

    // ------------------------------
    // CREATE CHAT SHORTCUT
    // ------------------------------
    private fun createChatShortcut(
        conversationId: String,
        name: String,
        profileImageUrl: String,
        userId: String,
        chatType: String,
        result: MethodChannel.Result
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("UNSUPPORTED", "Shortcuts require Android 8.0+", null)
            return
        }

        CoroutineScope(Dispatchers.Main).launch {
            try {
                val shortcutManager = getSystemService(ShortcutManager::class.java)

                val icon = if (profileImageUrl.isNotEmpty()) {
                    try {
                        val bitmap = withContext(Dispatchers.IO) {
                            val url = URL(profileImageUrl)
                            val connection = url.openConnection()
                            connection.connectTimeout = 5000
                            connection.readTimeout = 5000
                            BitmapFactory.decodeStream(connection.getInputStream())
                        }
                        if (bitmap != null) {
                            val circularBitmap = getCircularBitmap(bitmap)
                            Icon.createWithBitmap(circularBitmap)
                        } else {
                            Icon.createWithResource(this@MainActivity, android.R.drawable.ic_dialog_info)
                        }
                    } catch (e: Exception) {
                        Icon.createWithResource(this@MainActivity, android.R.drawable.ic_dialog_info)
                    }
                } else {
                    Icon.createWithResource(this@MainActivity, android.R.drawable.ic_dialog_info)
                }

                val intent = Intent(this@MainActivity, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("https://blueera.ai/app/chat/$conversationId?userId=$userId&chatType=$chatType&name=${Uri.encode(name)}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }

                val shortcutId = "chat_$conversationId"
                val shortcut = ShortcutInfo.Builder(this@MainActivity, shortcutId)
                    .setShortLabel(name)
                    .setLongLabel(name)
                    .setIcon(icon)
                    .setIntent(intent)
                    .build()

                if (shortcutManager.isRequestPinShortcutSupported) {
                    shortcutManager.requestPinShortcut(shortcut, null)
                    result.success(true)
                } else {
                    result.error("NOT_SUPPORTED", "Pin shortcut not supported on this device", null)
                }
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        }
    }

    private fun getCircularBitmap(bitmap: Bitmap): Bitmap {
        val size = minOf(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint().apply {
            isAntiAlias = true
        }
        val path = Path().apply {
            addCircle(size / 2f, size / 2f, size / 2f, Path.Direction.CCW)
        }
        canvas.clipPath(path)
        val left = (size - bitmap.width) / 2f
        val top = (size - bitmap.height) / 2f
        canvas.drawBitmap(bitmap, left, top, paint)
        return output
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