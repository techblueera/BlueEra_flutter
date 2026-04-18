package ai.bluecs.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.core.app.NotificationManagerCompat

/**
 * Handles Accept / Decline button taps from the custom incoming-call notification.
 * Mirrors the logic in app_notification.dart's background notification handlers.
 *
 * Accept: marks a flag in SharedPreferences + launches the app so main.dart's
 * cold-start check auto-accepts the call.
 *
 * Decline: marks a decline flag + launches the app so the foreground handler
 * can invoke CallController.declineCall() with full context. The native-side
 * REST call is left to flutter_local_notifications' existing bg handler as
 * fallback.
 */
class CallActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_ACCEPT = "ai.bluecs.app.CALL_ACCEPT"
        const val ACTION_DECLINE = "ai.bluecs.app.CALL_DECLINE"
        const val EXTRA_CALL_ID = "callId"
        const val EXTRA_ROOM_ID = "roomId"
        const val EXTRA_CALL_TYPE = "callType"
        const val EXTRA_NOTIF_ID = "notifId"
        private const val TAG = "CallActionReceiver"
        private const val PREFS_NAME = "call_action_prefs"
        private const val KEY_PENDING_ACTION = "pending_call_action"
        private const val KEY_PENDING_CALL_ID = "pending_call_id"
        private const val KEY_PENDING_ROOM_ID = "pending_room_id"
        private const val KEY_PENDING_CALL_TYPE = "pending_call_type"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val callId = intent.getStringExtra(EXTRA_CALL_ID) ?: ""
        val roomId = intent.getStringExtra(EXTRA_ROOM_ID) ?: ""
        val callType = intent.getStringExtra(EXTRA_CALL_TYPE) ?: ""
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 0)

        // Dismiss the notification
        NotificationManagerCompat.from(context).cancel(notifId)

        when (intent.action) {
            ACTION_ACCEPT -> {
                Log.d(TAG, "Accept tapped for call $callId")
                savePendingAction(context, "accept", callId, roomId, callType)
                launchApp(context)
            }
            ACTION_DECLINE -> {
                Log.d(TAG, "Decline tapped for call $callId")
                // Stash a pending-decline flag so the next organic app open
                // can reconcile server state. Intentionally NOT calling
                // launchApp(): decline from terminate/background should not
                // bring the app to the foreground.
                savePendingAction(context, "decline", callId, roomId, callType)
            }
        }
    }

    private fun savePendingAction(
        context: Context,
        action: String,
        callId: String,
        roomId: String,
        callType: String
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_PENDING_ACTION, action)
            .putString(KEY_PENDING_CALL_ID, callId)
            .putString(KEY_PENDING_ROOM_ID, roomId)
            .putString(KEY_PENDING_CALL_TYPE, callType)
            .apply()
    }

    private fun launchApp(context: Context) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (launchIntent != null) {
            context.startActivity(launchIntent)
        }
    }
}
