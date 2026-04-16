package ai.bluecs.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

/**
 * Builds and shows an incoming-call notification with a custom layout
 * featuring filled green (Accept) and red (Decline) buttons.
 */
object IncomingCallNotificationHelper {

    private const val CHANNEL_ID = "incoming_calls_custom"
    private const val CHANNEL_NAME = "Incoming Calls"

    fun show(context: Context, args: Map<String, Any?>) {
        val callId = args["callId"]?.toString() ?: ""
        val roomId = args["roomId"]?.toString() ?: ""
        val callerName = args["callerName"]?.toString() ?: "Incoming Call"
        val callType = args["callType"]?.toString() ?: "audio_call"
        val notifId = args["notifId"] as? Int ?: generateNotifId(callId)

        ensureChannel(context)

        val isVideo = callType == "video_call"

        // --- Build RemoteViews with custom layout ---
        val remoteViews = RemoteViews(context.packageName, R.layout.notification_incoming_call)
        remoteViews.setTextViewText(R.id.tv_caller_name, callerName)
        remoteViews.setTextViewText(
            R.id.tv_call_type,
            if (isVideo) "Incoming video call" else "Incoming voice call"
        )

        // --- Decline PendingIntent ---
        val declineIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = CallActionReceiver.ACTION_DECLINE
            putExtra(CallActionReceiver.EXTRA_CALL_ID, callId)
            putExtra(CallActionReceiver.EXTRA_ROOM_ID, roomId)
            putExtra(CallActionReceiver.EXTRA_CALL_TYPE, callType)
            putExtra(CallActionReceiver.EXTRA_NOTIF_ID, notifId)
        }
        val declinePending = PendingIntent.getBroadcast(
            context,
            notifId * 2,
            declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        remoteViews.setOnClickPendingIntent(R.id.btn_decline, declinePending)

        // --- Accept PendingIntent ---
        val acceptIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = CallActionReceiver.ACTION_ACCEPT
            putExtra(CallActionReceiver.EXTRA_CALL_ID, callId)
            putExtra(CallActionReceiver.EXTRA_ROOM_ID, roomId)
            putExtra(CallActionReceiver.EXTRA_CALL_TYPE, callType)
            putExtra(CallActionReceiver.EXTRA_NOTIF_ID, notifId)
        }
        val acceptPending = PendingIntent.getBroadcast(
            context,
            notifId * 2 + 1,
            acceptIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        remoteViews.setOnClickPendingIntent(R.id.btn_accept, acceptPending)

        // --- Full-screen intent (opens app on locked screen) ---
        val fullScreenIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val fullScreenPending = PendingIntent.getActivity(
            context,
            notifId,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // --- Custom ringtone URI from res/raw ---
        val soundUri = Uri.parse("android.resource://${context.packageName}/${R.raw.hangouts_call}")

        // --- Build notification ---
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(fullScreenPending, true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSound(soundUri)
            .setVibrate(longArrayOf(0, 1000, 500, 1000))
            .build()

        // FLAG_INSISTENT makes the sound repeat until the user acts on the notification
        notification.flags = notification.flags or Notification.FLAG_INSISTENT

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notifId, notification)
    }

    fun cancel(context: Context, notifId: Int) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notifId)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Delete old channel so the updated sound takes effect.
            // Android caches channel settings after creation — the only way
            // to change the sound is to delete and recreate.
            manager.deleteNotificationChannel(CHANNEL_ID)

            val soundUri = Uri.parse("android.resource://${context.packageName}/${R.raw.hangouts_call}")
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
                setShowBadge(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
                setSound(soundUri, audioAttr)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun generateNotifId(callId: String): Int {
        return if (callId.isEmpty()) 99001 else (callId.hashCode() and 0x7FFFFFFF)
    }
}
