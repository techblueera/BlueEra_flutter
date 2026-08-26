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
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.VibrationEffect
import android.os.Vibrator
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
    private val CALL_PIP_CHANNEL = "com.bluehr.call/pip"
    private val INCOMING_CALL_NOTIF_CHANNEL = "com.bluehr.incoming_call_notification"
    private val MEDIA_SCANNER_CHANNEL = "ai.bluecs.app/media_scanner"
    private val APP_SHARE_CHANNEL = "ai.bluecs.app/app_share"
    private val CALL_VOLUME_CHANNEL = "com.bluehr.call/volume"
    private val RIDER_LOCATION_CHANNEL = "ai.bluecs.app/rider_location"

    // Target size for the downsampled chat-shortcut launcher icon (px). Adaptive
    // launcher icons top out around 108dp; 256px covers xxxhdpi with headroom.
    private val SHORTCUT_ICON_SIZE_PX = 256

    private var ringtone: Ringtone? = null

    private val CHANNEL = "com.vahcare.lab/pip"
    private val ACTION_COMPLETE_RIDE = "ACTION_COMPLETE_RIDE"
    private var isPipEnabled = false

    private var volumeChannel: MethodChannel? = null
    // While true (set by Flutter for the duration of an in-app call), the
    // hardware volume rocker is forwarded to Flutter to drive the WebRTC call
    // gain instead of changing the OS stream volume.
    private var callVolumeActive = false

    // ── Call window / PiP ───────────────────────────────────────────────────
    // Behaviour inherited from the old CallActivity, which had show-on-lock,
    // turn-screen-on and keep-screen-on baked into its manifest entry. Those
    // must not apply to the whole app all the time, so Flutter switches them on
    // for the duration of a call and off when it ends.
    private var callPipChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Audio-route bridge. Registered on every engine that can own a call so
        // Dart can re-activate + read back flutter_webrtc's shared
        // AudioSwitchManager. See CallAudioBridge for why that is necessary.
        CallAudioBridge.register(flutterEngine.dartExecutor.binaryMessenger)

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
        // RIDER LIVE-LOCATION CHANNEL — starts/stops the native foreground
        // service that pings the rider's location every 60s in
        // foreground/background/killed state (a Dart timer dies on kill).
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RIDER_LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val token = call.argument<String>("token")
                        val userId = call.argument<String>("userId")
                        val baseUrl = call.argument<String>("baseUrl")
                        if (token.isNullOrEmpty() || userId.isNullOrEmpty() || baseUrl.isNullOrEmpty()) {
                            result.error("INVALID", "token, userId and baseUrl are required", null)
                        } else {
                            val intent = Intent(this, RiderLocationForegroundService::class.java)
                                .putExtra("token", token)
                                .putExtra("userId", userId)
                                .putExtra("baseUrl", baseUrl)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        }
                    }
                    "stop" -> {
                        // Clear the active flag so neither a START_STICKY
                        // restart, the task-removal alarm, the boot receiver nor
                        // the watchdog can resurrect pinging: location is only
                        // ever published while the rider is LIVE.
                        getSharedPreferences(
                            RiderLocationForegroundService.PREFS,
                            Context.MODE_PRIVATE
                        ).edit()
                            .putBoolean(RiderLocationForegroundService.KEY_ACTIVE, false)
                            .apply()
                        RiderLocationWatchdogWorker.cancel(applicationContext)
                        stopService(Intent(this, RiderLocationForegroundService::class.java))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ------------------------------
        // APP-TARGETED SHARE CHANNEL — send a file straight to a named app
        // (e.g. WhatsApp) instead of opening the system chooser.
        //
        // share_plus cannot do this: ShareParams has no package field, and the
        // `whatsapp://send?text=` URL scheme carries text only — it has no way
        // to attach a file. Sending an image directly therefore needs a native
        // ACTION_SEND with setPackage().
        // ------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFileToApp" -> {
                        val path = call.argument<String>("path")
                        val mimeType = call.argument<String>("mimeType") ?: "image/*"
                        val text = call.argument<String>("text")
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        result.success(shareFileToApp(path, mimeType, text, packages))
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
        // CALL WINDOW CHANNEL — show-over-lock-screen / turn-screen-on /
        // keep-screen-on for the duration of a call. Inherited from the retired
        // CallActivity, which had these in its manifest entry.
        //
        // Call Picture-in-Picture used to live here too and is deliberately
        // gone: the call screen entered PiP on Back, and leaving PiP exited the
        // app. Back now minimises to the in-app top call strip.
        // ------------------------------
        callPipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_PIP_CHANNEL)
        callPipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setCallWindowActive" -> {
                    setCallWindowActive(call.argument<Boolean>("active") ?: false)
                    result.success(null)
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
                    "startRingService" -> {
                        // The non-dismissible CallStyle ring (Android 12+).
                        // Dart still posts its own notification either way —
                        // this one supersedes it where the platform allows.
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                        IncomingCallService.start(applicationContext, args)
                        result.success(IncomingCallService.isSupported())
                    }
                    "stopRingService" -> {
                        IncomingCallService.stop(applicationContext)
                        result.success(null)
                    }
                    "syncCallAuth" -> {
                        // Mirror the token + call base URL into PLAIN prefs so
                        // CallActionReceiver can POST a decline without the app
                        // running. A BroadcastReceiver cannot read Dart's
                        // secure storage, and waiting for the app to open is
                        // what made Decline a no-op in the first place.
                        val prefs = applicationContext.getSharedPreferences(
                            CallActionReceiver.PREFS_NAME, Context.MODE_PRIVATE
                        )
                        prefs.edit()
                            .putString(
                                CallActionReceiver.KEY_AUTH_TOKEN,
                                call.argument<String>("authToken") ?: ""
                            )
                            .putString(
                                CallActionReceiver.KEY_CALL_BASE_URL,
                                call.argument<String>("callBaseUrl") ?: ""
                            )
                            .apply()
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

        // ------------------------------
        // CALL VOLUME CHANNEL — intercept the hardware volume rocker during an
        // in-app call so it drives the WebRTC software gain (works on Bluetooth/
        // CarPlay where the OS call-stream volume is locked by the accessory).
        // ------------------------------
        volumeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_VOLUME_CHANNEL)
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
        if (callVolumeActive) {
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
                // Consume so the OS doesn't also adjust the call stream — the
                // gain change is applied in Dart and covers every audio route.
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    // ------------------------------
    // PLAY / STOP INCOMING-CALL RINGTONE — delegates to the process-wide
    // CallRinger singleton so a ring started here can be stopped from the
    // CallActivity engine or CallActionReceiver (and vice versa).
    // ------------------------------
    /**
     * Send [path] straight to the first app in [packages] that can receive it,
     * skipping the system chooser.
     *
     * Returns false when nothing could be launched — no file, no FileProvider
     * URI, or none of the target apps are installed/visible. The Dart caller
     * treats false as "fall back to the normal share sheet", so a missing
     * WhatsApp degrades instead of failing.
     *
     * Package visibility matters here: on API 30+ `resolveActivity` returns
     * null for any package not declared in the manifest's <queries>, so the
     * targets must be listed there or this always returns false.
     */
    private fun shareFileToApp(
        path: String?,
        mimeType: String,
        text: String?,
        packages: List<String>
    ): Boolean {
        if (path.isNullOrEmpty() || packages.isEmpty()) return false
        val file = java.io.File(path)
        if (!file.exists()) return false

        // file:// URIs throw FileUriExposedException on API 24+, so the image
        // has to be handed over through the FileProvider declared in the
        // manifest (authority ${applicationId}.beshare).
        val uri = try {
            androidx.core.content.FileProvider.getUriForFile(
                this,
                "$packageName.beshare",
                file
            )
        } catch (e: Exception) {
            return false
        }

        for (pkg in packages) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
                setPackage(pkg)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) == null) continue
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // Installed but refused the intent — try the next candidate.
            }
        }
        return false
    }

    private fun playDefaultRingtone() = CallRinger.play(applicationContext)

    private fun stopDefaultRingtone() = CallRinger.stop(applicationContext)

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
                            // Read the bytes once, then downsample to the small
                            // launcher-shortcut icon size instead of decoding the
                            // full-resolution image into memory.
                            val bytes = connection.getInputStream().use { it.readBytes() }
                            decodeSampledBitmap(bytes, SHORTCUT_ICON_SIZE_PX, SHORTCUT_ICON_SIZE_PX)
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
                    data = Uri.parse("https://beapp.in/app/chat/$conversationId?userId=$userId&chatType=$chatType&name=${Uri.encode(name)}")
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

    // Decode an image from bytes downsampled to roughly reqWidth x reqHeight,
    // using inSampleSize so BitmapFactory never allocates the full-resolution
    // bitmap. Bounds are read first with inJustDecodeBounds, so the byte array
    // is decoded twice (cheap bounds pass, then the sampled pass).
    private fun decodeSampledBitmap(data: ByteArray, reqWidth: Int, reqHeight: Int): Bitmap? {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(data, 0, data.size, options)
        options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)
        options.inJustDecodeBounds = false
        return BitmapFactory.decodeByteArray(data, 0, data.size, options)
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
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

    /**
     * Apply (or drop) the window behaviour a call needs: visible over the lock
     * screen, screen turned on for an incoming ring, and no screen timeout for
     * its duration. The old CallActivity declared these in the manifest; doing
     * that on MainActivity would apply them to the entire app, so they are
     * scoped to the call here.
     */
    private fun setCallWindowActive(active: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(active)
            setTurnScreenOn(active)
        } else {
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            @Suppress("DEPRECATION")
            if (active) window.addFlags(flags) else window.clearFlags(flags)
        }
        if (active) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onUserLeaveHint() {
        // No call branch here any more. Leaving the app mid-call used to shrink
        // the call into Picture-in-Picture; PiP is gone because dismissing it
        // closed the app. The call keeps running in the background (foreground
        // service + the floating overlay), and the in-app top strip is the way
        // back to it.
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