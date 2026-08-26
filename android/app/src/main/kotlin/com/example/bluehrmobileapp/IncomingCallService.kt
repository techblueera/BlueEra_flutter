package ai.bluecs.app

import android.app.ForegroundServiceStartNotAllowedException
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Person
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * The ringing incoming call, as a `phoneCall` foreground service carrying a
 * `CallStyle` notification.
 *
 * ## Why a service, when a plain notification already rings
 *
 * The notification was already `ongoing` + `autoCancel(false)`, which used to be
 * enough. **Android 14 (API 34) made ongoing notifications user-dismissible**, so
 * on a modern device the ring could be swiped away while the phone was still
 * ringing — the call went on, the caller went on waiting, and the receiver had
 * nothing left on screen to answer with. `targetSdkVersion` here is 36.
 *
 * The platform leaves exactly one combination non-dismissible for this case: a
 * **`CallStyle`** notification posted by a **foreground service whose type is
 * `phoneCall`**. Both halves are required — `CallStyle` alone is still swipeable,
 * and a `phoneCall` service with an ordinary notification is too. That is what
 * this class is.
 *
 * A heads-up banner can still be pushed away by the user (that is the platform's
 * behaviour and the reported expectation); the entry in the status bar survives
 * until the call actually stops ringing.
 *
 * ## Lifetime
 *
 * Started when the ring begins, stopped by [ACTION_STOP] from every path that
 * ends it — accept, decline, caller cancel, ring timeout, the in-app screen
 * taking over. It is a RING service, not a call service: it does not outlive the
 * ringing state, so an answered call is not holding a foreground service for its
 * whole duration.
 *
 * ## Below API 31
 *
 * `CallStyle` is API 31+. On older devices [start] is a no-op and Dart keeps
 * using its `flutter_local_notifications` path, which was never affected by the
 * Android 14 change those devices do not have.
 */
class IncomingCallService : Service() {

    companion object {
        const val ACTION_START = "ai.bluecs.app.RING_START"
        const val ACTION_STOP = "ai.bluecs.app.RING_STOP"

        const val EXTRA_CALL_ID = "callId"
        const val EXTRA_ROOM_ID = "roomId"
        const val EXTRA_CALL_TYPE = "callType"
        const val EXTRA_CALLER_NAME = "callerName"

        private const val TAG = "IncomingCallService"

        /** Its own channel — the ring is a different thing from a chat ping. */
        private const val CHANNEL_ID = "incoming_calls_ringing_v1"
        private const val CHANNEL_NAME = "Incoming Calls"

        /** One ring at a time, so one fixed id. */
        private const val NOTIF_ID = 99010

        /** Whether this device can do the CallStyle + phoneCall-FGS combination. */
        fun isSupported(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

        fun start(context: Context, args: Map<String, Any?>) {
            if (!isSupported()) return
            val intent = Intent(context, IncomingCallService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_CALL_ID, args["callId"]?.toString() ?: "")
                putExtra(EXTRA_ROOM_ID, args["roomId"]?.toString() ?: "")
                putExtra(EXTRA_CALL_TYPE, args["callType"]?.toString() ?: "audio_call")
                putExtra(EXTRA_CALLER_NAME, args["callerName"]?.toString() ?: "")
            }
            try {
                context.startForegroundService(intent)
            } catch (e: Exception) {
                // A background start can be refused (Android 12+ restrictions).
                // Never crash the ring path for it — Dart's notification is
                // still up, so the user can still answer.
                Log.w(TAG, "startForegroundService refused: $e")
            }
        }

        fun stop(context: Context) {
            if (!isSupported()) return
            try {
                context.startService(
                    Intent(context, IncomingCallService::class.java)
                        .apply { action = ACTION_STOP }
                )
            } catch (e: Exception) {
                Log.w(TAG, "stop failed: $e")
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP || intent == null) {
            stopRing()
            return START_NOT_STICKY
        }

        val callId = intent.getStringExtra(EXTRA_CALL_ID) ?: ""
        val roomId = intent.getStringExtra(EXTRA_ROOM_ID) ?: ""
        val callType = intent.getStringExtra(EXTRA_CALL_TYPE) ?: "audio_call"
        val rawName = intent.getStringExtra(EXTRA_CALLER_NAME)?.trim() ?: ""
        val callerName =
            if (rawName.isEmpty() || rawName == "Unknown") "Incoming Call" else rawName

        ensureChannel()

        try {
            val notification = buildNotification(callId, roomId, callType, callerName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIF_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                startForeground(NOTIF_ID, notification)
            }
        } catch (e: Exception) {
            // Android 12+ throws when a foreground start is not permitted from
            // the current app state. Give up quietly rather than crashing the
            // process while a call is coming in.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                e is ForegroundServiceStartNotAllowedException
            ) {
                Log.w(TAG, "foreground start not allowed: $e")
            } else {
                Log.w(TAG, "startForeground failed: $e")
            }
            stopRing()
        }
        return START_NOT_STICKY
    }

    private fun stopRing() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {
        }
        try {
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .cancel(NOTIF_ID)
        } catch (_: Exception) {
        }
        stopSelf()
    }

    private fun buildNotification(
        callId: String,
        roomId: String,
        callType: String,
        callerName: String
    ): Notification {
        val isVideo = callType == "video_call"

        val decline = actionIntent(CallActionReceiver.ACTION_DECLINE, callId, roomId, callType, 0)
        val answer = actionIntent(CallActionReceiver.ACTION_ACCEPT, callId, roomId, callType, 1)

        // Opens the app over the lock screen. The same launch intent the rest of
        // the call paths use, so answering from here lands where answering from
        // anywhere else does.
        val fullScreen = PendingIntent.getActivity(
            this,
            2,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle(callerName)
            .setContentText(if (isVideo) "Incoming video call" else "Incoming voice call")
            .setCategory(Notification.CATEGORY_CALL)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreen, true)
            .setContentIntent(fullScreen)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // The whole point of this class. `forIncomingCall` is what makes the
            // system render Answer/Decline itself and — with the phoneCall
            // service type — refuse to let the entry be swiped away.
            val caller = Person.Builder().setName(callerName).setImportant(true).build()
            builder.setStyle(
                Notification.CallStyle.forIncomingCall(caller, decline, answer)
            )
        }

        return builder.build()
    }

    private fun actionIntent(
        action: String,
        callId: String,
        roomId: String,
        callType: String,
        requestOffset: Int
    ): PendingIntent {
        val intent = Intent(this, CallActionReceiver::class.java).apply {
            this.action = action
            putExtra(CallActionReceiver.EXTRA_CALL_ID, callId)
            putExtra(CallActionReceiver.EXTRA_ROOM_ID, roomId)
            putExtra(CallActionReceiver.EXTRA_CALL_TYPE, callType)
            putExtra(CallActionReceiver.EXTRA_NOTIF_ID, NOTIF_ID)
        }
        return PendingIntent.getBroadcast(
            this,
            NOTIF_ID + requestOffset,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun ensureChannel() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val soundUri =
            Uri.parse("android.resource://$packageName/${R.raw.hangouts_call}")
        val audioAttr = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .build()

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Incoming voice and video call alerts"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setShowBadge(false)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 1000, 500, 1000)
            setSound(soundUri, audioAttr)
        }
        manager.createNotificationChannel(channel)
    }
}
