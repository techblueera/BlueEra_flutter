package ai.bluecs.app

import android.app.ForegroundServiceStartNotAllowedException
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Keeps the app's process — and with it the Flutter engine and the chat
 * WebSocket — alive while a call is in progress and the app is backgrounded.
 *
 * ## What this replaces
 *
 * `SocketKeepAliveService` (Dart) called `startService` on a
 * `com.bluehr.socket/service` channel that no native handler was ever
 * registered for, so on Android the call keep-alive did nothing for the life of
 * the feature: backgrounding an active call let Android freeze the process and
 * drop the socket. This is the service that was always supposed to be behind
 * that channel.
 *
 * ## Why `phoneCall` and not `microphone` or `dataSync`
 *
 * `phoneCall` requires `FOREGROUND_SERVICE_PHONE_CALL` plus one of "declares
 * `MANAGE_OWN_CALLS`" or "is the default dialer". Both of those are *declared*
 * manifest permissions — they cannot be revoked at runtime, so this service
 * cannot be put into the ineligible state that crashed
 * [RiderLocationForegroundService]. `MANAGE_OWN_CALLS` reaches the merged
 * manifest from the vendored `flutter_callkit_incoming` plugin, and is now also
 * declared explicitly by the app so a plugin change cannot silently remove it.
 *
 * The alternatives are worse:
 *
 *  * `microphone` needs the `RECORD_AUDIO` **runtime** grant, which is
 *    while-in-use restricted — revocable by the user and illegal to start from
 *    the background. That is exactly the failure mode that produced the
 *    `SecurityException` in the rider location service.
 *  * `dataSync` carries no prerequisite but is semantically wrong for a call,
 *    which matters for Play policy review, and Android 15 tightened it further.
 *  * `connectedDevice` is for external-device links, not calls.
 *
 * ## Lifecycle
 *
 * Started from Dart when a call becomes active (app in the foreground, so no
 * background-start restriction applies) and stopped when it ends.
 */
class CallKeepAliveService : Service() {

    companion object {
        private const val TAG = "CallKeepAliveService"
        private const val CHANNEL_ID = "call_keep_alive_v1"
        private const val CHANNEL_NAME = "Ongoing Calls"

        /// Distinct from IncomingCallService's 99010 (the ringing notification)
        /// and RiderLocationForegroundService's 99003. Reuses the id the
        /// deleted SocketKeepAliveService had, which nothing else claims.
        private const val NOTIFICATION_ID = 99002

        const val ACTION_START = "ai.bluecs.app.CALL_KEEPALIVE_START"
        const val ACTION_STOP = "ai.bluecs.app.CALL_KEEPALIVE_STOP"

        /// Hard cap on how long the service may hold itself up.
        ///
        /// `call_controller.dart` calls `start()` from four places and `stop()`
        /// from one. That asymmetry is a leak waiting to happen, and a leaked
        /// `phoneCall` foreground service is a particularly bad one: the
        /// notification is ongoing and — because Android 14 exempts call-type
        /// services from swipe-to-dismiss — the user cannot clear it. Four
        /// hours is far beyond any real call and well short of "until reboot".
        private const val MAX_DURATION_MS = 4 * 60 * 60 * 1000L

        /// True while the service is holding the process up, in THIS process.
        @Volatile
        @JvmStatic
        var isRunning: Boolean = false
            private set

        /**
         * Starts the keep-alive. Safe to call when already running — the
         * service simply re-arms its timeout.
         *
         * Returns false when the platform refused the start. The caller is a
         * method channel, so the refusal is reported to Dart rather than
         * thrown: a call that cannot be protected must still connect.
         */
        fun start(context: Context): Boolean {
            return try {
                val intent = Intent(context, CallKeepAliveService::class.java)
                    .apply { action = ACTION_START }
                context.startForegroundService(intent)
                true
            } catch (e: Exception) {
                // Android 12+ can refuse a background start. Never let the call
                // path die for a keep-alive that is only an optimisation.
                Log.w(TAG, "startForegroundService refused: $e")
                false
            }
        }

        fun stop(context: Context) {
            try {
                // startService, not startForegroundService: this is a plain
                // delivery of ACTION_STOP to an already-running service, and
                // startForegroundService on a stopped service would create one
                // just to tear it down — and oblige it to call startForeground
                // within 5s first.
                context.startService(
                    Intent(context, CallKeepAliveService::class.java)
                        .apply { action = ACTION_STOP }
                )
            } catch (e: Exception) {
                Log.w(TAG, "stop failed: $e")
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable {
        Log.w(TAG, "keep-alive exceeded ${MAX_DURATION_MS}ms — stopping (leaked stop()?)")
        shutdown()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A null intent means a system-initiated restart. There is no call to
        // protect at that point, so decline rather than posting "Call in
        // progress" over nothing.
        if (intent == null || intent.action == ACTION_STOP) {
            shutdown()
            return START_NOT_STICKY
        }

        if (!promoteToForeground()) {
            // Must stop: a service started via startForegroundService() that
            // never reaches startForeground() is killed with
            // ForegroundServiceDidNotStartInTimeException after ~5s.
            stopSelf(startId)
            return START_NOT_STICKY
        }

        isRunning = true
        handler.removeCallbacks(timeout)
        handler.postDelayed(timeout, MAX_DURATION_MS)

        // START_NOT_STICKY, deliberately — the opposite of the rider location
        // service. A live rider is still live after a process kill, so that one
        // is worth restarting. A call is not resumable: the engine, the WebRTC
        // peer connection and the socket all died with the process, so a sticky
        // restart would only post a "Call in progress" notification for a call
        // that no longer exists.
        return START_NOT_STICKY
    }

    /**
     * The app was swiped out of recents. The Flutter engine goes with it, so
     * the call is over regardless of what this service does — take the
     * notification down rather than leaving a ghost call on screen.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        shutdown()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeout)
        isRunning = false
        super.onDestroy()
    }

    /**
     * Promotes to the foreground without ever throwing.
     *
     * The prerequisites here are declared permissions rather than runtime
     * grants, so a refusal should be impossible — but "should be impossible"
     * is precisely what the location service's bare `startForeground()` call
     * assumed. The catch costs nothing and removes a whole crash class.
     */
    private fun promoteToForeground(): Boolean {
        return try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                } else {
                    0
                }
            )
            true
        } catch (e: SecurityException) {
            // MANAGE_OWN_CALLS missing from the merged manifest, or the typed
            // FGS permission dropped.
            Log.w(TAG, "startForeground denied — check MANAGE_OWN_CALLS: $e")
            false
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                e is ForegroundServiceStartNotAllowedException
            ) {
                Log.w(TAG, "foreground start not allowed: $e")
            } else {
                Log.w(TAG, "startForeground failed: $e")
            }
            false
        }
    }

    /** Takes the notification down and stops. Idempotent. */
    private fun shutdown() {
        handler.removeCallbacks(timeout)
        isRunning = false
        try {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        } catch (_: Exception) {
        }
        try {
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps your call connected while the app is in the background"
                setShowBadge(false)
                setSound(null, null)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call in progress")
            .setContentText("Tap to return to your call")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .build()
    }
}
