package ai.bluecs.new_order_call_notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Handles the Dismiss button, and nothing else.
 *
 * Opening the order deliberately does NOT come through here: since Android 12
 * a BroadcastReceiver started by a notification may not launch an activity
 * (the "notification trampoline" ban), so Answer / body tap / full-screen
 * intent all target the launcher activity directly.
 *
 * Cancelling here is the only place the alert is taken down without the app
 * being involved — which is exactly the one exit the product asked for
 * besides tapping it.
 */
class NewOrderActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_DISMISS = "ai.bluecs.new_order_call_notification.DISMISS"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_DISMISS) return
        val notificationId =
            intent.getIntExtra(NewOrderCallStyleNotification.EXTRA_NOTIFICATION_ID, 0)
        if (notificationId == 0) return
        NewOrderCallStyleNotification.cancel(context, notificationId)
    }
}
