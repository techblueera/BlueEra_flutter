package ai.bluecs.new_order_call_notification

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person

/**
 * Builds the new-order alert as a **CallStyle** notification.
 *
 * Why CallStyle, when this is an order and not a call: from Android 14 the
 * user can dismiss any ongoing notification, and `setOngoing(true)` /
 * `FLAG_NO_CLEAR` became advisory. Google's behaviour-changes page lists the
 * only surviving exemptions — CallStyle, media, device-policy-controller and
 * search-selector notifications. A foreground service is NOT one of them. So
 * CallStyle is the single supported way to post an alert the seller cannot
 * flick away, and `flutter_local_notifications` cannot build one.
 *
 * The cost is the template's fixed button labels: the system renders
 * "Decline" / "Answer" and does not allow custom text on a CallStyle action.
 *
 * `setOngoing(true)` is REQUIRED — the exemption applies to CallStyle
 * notifications that are ongoing, not to CallStyle alone.
 */
internal object NewOrderCallStyleNotification {

    private const val TAG = "NewOrderCallNotif"

    /**
     * Versioned: Android freezes a channel's sound and importance when it is
     * first created and resurrects them if the same id is recreated, so
     * changing either REQUIRES a new id. Bump to `_v2` if you change the tone.
     */
    private const val CHANNEL_ID = "new_order_call_v1"
    private const val CHANNEL_NAME = "New Orders"
    private const val CHANNEL_DESCRIPTION =
        "New order alerts that stay until you respond"

    /** Extras the host activity is launched with, read back by the plugin. */
    const val EXTRA_PAYLOAD = "new_order_payload"
    const val EXTRA_NOTIFICATION_ID = "new_order_notification_id"

    fun show(context: Context, args: Map<String, Any?>): Boolean {
        val notificationId = (args["id"] as? Number)?.toInt() ?: return false
        val title = args["title"]?.toString().orEmpty().ifEmpty { "New order received" }
        val body = args["body"]?.toString().orEmpty()
        val caller = args["caller"]?.toString().orEmpty().ifEmpty { title }
        val payload = args["payload"]?.toString().orEmpty()
        val deadlineMillis = (args["deadlineMillis"] as? Number)?.toLong() ?: 0L
        val soundName = args["sound"]?.toString().orEmpty()
        val iconName = args["icon"]?.toString().orEmpty()
        val accentColor = (args["accentColor"] as? Number)?.toInt() ?: 0

        return try {
            ensureChannel(context, soundName)

            // Opening the order must NOT go through a BroadcastReceiver:
            // Android 12 banned notification trampolines (a receiver started
            // from a notification may not launch an activity). So Answer, the
            // body tap and the full-screen intent all target the launcher
            // activity directly, carrying the payload as extras. The
            // notification is then cancelled from Dart once it has drained the
            // pending action — which is also what keeps "opened" and
            // "dismissed" a single code path.
            val openIntent = openAppPendingIntent(context, notificationId, payload)

            // Dismiss has no UI, so a receiver is fine (and correct — it must
            // not bring the app to the front).
            val dismissIntent = PendingIntent.getBroadcast(
                context,
                notificationId * 2 + 1,
                Intent(context, NewOrderActionReceiver::class.java).apply {
                    action = NewOrderActionReceiver.ACTION_DISMISS
                    putExtra(EXTRA_NOTIFICATION_ID, notificationId)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val person = Person.Builder()
                .setName(caller)
                .setImportant(true)
                .build()

            // forIncomingCall(caller, decline, answer):
            //   decline → our Dismiss, answer → open the order.
            //
            // The colour hints are the ONLY part of this template the app
            // controls. Setting both to the same brand blue is what takes the
            // stock red/green call colouring off the buttons — their labels
            // and phone icons belong to the system template and cannot be
            // changed (see the class doc).
            val callStyle = NotificationCompat.CallStyle
                .forIncomingCall(person, dismissIntent, openIntent)
            if (accentColor != 0) {
                callStyle.setAnswerButtonColorHint(accentColor)
                callStyle.setDeclineButtonColorHint(accentColor)
            }

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(resolveIcon(context, iconName))
                .setStyle(callStyle)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                // The two flags that make it unswipeable, given CallStyle.
                .setOngoing(true)
                .setAutoCancel(false)
                // Takes over the screen instead of waiting in the shade. Also
                // what keeps a CallStyle notification ranked as high priority
                // when the app has no foreground service backing it.
                .setFullScreenIntent(openIntent, true)
                .setContentIntent(openIntent)
                // A re-delivered push for the same order refreshes it silently.
                .setOnlyAlertOnce(true)

            // Brand accent for the small icon / header line.
            if (accentColor != 0) builder.setColor(accentColor)

            // Response countdown. The CallStyle template owns its layout, so
            // depending on OEM/version this may not be rendered — the deadline
            // is therefore also written into `body` by the Dart caller, which
            // always shows.
            if (deadlineMillis > 0L) {
                builder.setWhen(deadlineMillis)
                    .setShowWhen(true)
                    .setUsesChronometer(true)
                    .setChronometerCountDown(true)
            }

            val notification = builder.build()
            // Belt and braces for Android ≤ 13 and the lock screen, where this
            // still means something on its own.
            notification.flags = notification.flags or Notification.FLAG_NO_CLEAR

            NotificationManagerCompat.from(context).notify(notificationId, notification)
            true
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted (API 33+).
            Log.w(TAG, "notify denied: ${e.message}")
            false
        } catch (e: Exception) {
            Log.w(TAG, "show failed: ${e.message}", e)
            false
        }
    }

    fun cancel(context: Context, notificationId: Int) {
        try {
            NotificationManagerCompat.from(context).cancel(notificationId)
        } catch (e: Exception) {
            Log.w(TAG, "cancel failed: ${e.message}")
        }
    }

    /** Answer / body tap / full-screen: straight to the launcher activity. */
    private fun openAppPendingIntent(
        context: Context,
        notificationId: Int,
        payload: String
    ): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN)
        launch.apply {
            // SINGLE_TOP so a warm app gets onNewIntent() instead of a second
            // activity instance; the host declares android:launchMode="singleTop".
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_PAYLOAD, payload)
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        return PendingIntent.getActivity(
            context,
            notificationId * 2,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun ensureChannel(context: Context, soundName: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = CHANNEL_DESCRIPTION
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setShowBadge(true)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 600, 300, 600)

            val soundId = resolveRaw(context, soundName)
            if (soundId != 0) {
                val uri = Uri.parse("android.resource://${context.packageName}/$soundId")
                val attributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    // Ringtone usage: a call-category alert should play at ring
                    // volume, not notification volume.
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .build()
                setSound(uri, attributes)
            }
        }
        manager.createNotificationChannel(channel)
    }

    /** Host-app resources, resolved by name — they don't live in this module. */
    private fun resolveRaw(context: Context, name: String): Int =
        if (name.isEmpty()) 0
        else context.resources.getIdentifier(name, "raw", context.packageName)

    private fun resolveIcon(context: Context, name: String): Int {
        if (name.isNotEmpty()) {
            val id = context.resources.getIdentifier(name, "drawable", context.packageName)
            if (id != 0) return id
        }
        return context.applicationInfo.icon
    }
}
