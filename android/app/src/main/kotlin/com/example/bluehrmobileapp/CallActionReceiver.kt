package ai.bluecs.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

/**
 * Answer / Decline from the [IncomingCallService] CallStyle notification.
 *
 * ## Decline posts to the server here, natively
 *
 * It used to only stash a SharedPreferences flag and wait for the app to be
 * opened, so a decline from a backgrounded or killed app never reached the
 * server: the caller went on ringing for the full window and was then told "no
 * answer". The comment claimed a Dart background handler would cover it — that
 * handler belongs to `flutter_local_notifications` and is never invoked for a
 * notification the platform posted on our behalf from a service.
 *
 * So the decline goes out from here, on a worker thread inside [goAsync], using
 * credentials Dart mirrors into plain prefs ([PREFS_NAME]). The pending flag is
 * still written: it is what lets the app reconcile its own state next time it
 * opens, and it is the fallback if the request fails.
 *
 * ## Accept still launches the app
 *
 * Answering needs the UI, the WebRTC stack and the audio session — none of which
 * exist here. The flag plus a launch is the whole of it; `main.dart` reads the
 * flag on start and accepts.
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

        /** Plain prefs, deliberately: a BroadcastReceiver cannot read Dart's
         *  secure storage, and this holds only what a decline needs. */
        const val PREFS_NAME = "call_action_prefs"
        const val KEY_AUTH_TOKEN = "call_auth_token"
        const val KEY_CALL_BASE_URL = "call_base_url"

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

        // Take the ring down IMMEDIATELY — before any network or Dart work. The
        // ring may have been started by either Flutter engine or by the
        // foreground service; all three are stopped here so none can outlive
        // the tap.
        NotificationManagerCompat.from(context).cancel(notifId)
        CallRinger.stop(context)
        IncomingCallService.stop(context)

        when (intent.action) {
            ACTION_ACCEPT -> {
                Log.d(TAG, "Accept tapped for call $callId")
                savePendingAction(context, "accept", callId, roomId, callType)
                launchApp(context)
            }
            ACTION_DECLINE -> {
                Log.d(TAG, "Decline tapped for call $callId")
                // Written FIRST: if the POST below fails, the next app open
                // still knows a decline was intended and can reconcile.
                savePendingAction(context, "decline", callId, roomId, callType)
                postDecline(context, callId, roomId)
                // Deliberately NOT launching the app — declining from the lock
                // screen should not drag the whole app to the foreground.
            }
        }
    }

    /**
     * `POST call/decline`, off the main thread, holding the broadcast open.
     *
     * [goAsync] is what buys the time: without it the receiver returns and the
     * process can be killed mid-request. The timeouts are short because the
     * window is short — a decline that has not left in 8 seconds is not going
     * to, and the server's own ring timeout is the backstop.
     */
    private fun postDecline(context: Context, callId: String, roomId: String) {
        if (callId.isEmpty() || roomId.isEmpty()) {
            Log.w(TAG, "decline skipped — missing ids (call=$callId room=$roomId)")
            return
        }
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val token = prefs.getString(KEY_AUTH_TOKEN, "") ?: ""
        val base = (prefs.getString(KEY_CALL_BASE_URL, "") ?: "").trim()
        if (token.isEmpty() || base.isEmpty()) {
            Log.w(TAG, "decline skipped — no mirrored credentials")
            return
        }

        val pending = goAsync()
        thread(start = true) {
            try {
                val url = URL(base.trimEnd('/') + "/call/decline")
                (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 8000
                    readTimeout = 8000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $token")
                    val body = JSONObject()
                        .put("call_id", callId)
                        .put("room_id", roomId)
                        .toString()
                    outputStream.use { it.write(body.toByteArray()) }
                    Log.d(TAG, "decline POST → $responseCode")
                    disconnect()
                }
            } catch (e: Exception) {
                Log.w(TAG, "decline POST failed: $e")
            } finally {
                pending.finish()
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
