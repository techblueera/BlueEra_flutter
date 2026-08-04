package ai.bluecs.new_order_call_notification

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Method channel for the new-order CallStyle notification.
 *
 * Being a real Flutter plugin (rather than a channel wired up in
 * MainActivity) is the whole point: `GeneratedPluginRegistrant` registers it
 * on EVERY engine, including the one `firebase_messaging` spins up for
 * background / terminated pushes — which is precisely when a new order needs
 * to be posted. A channel registered in `MainActivity.configureFlutterEngine`
 * does not exist in that isolate.
 *
 * Methods:
 *  - `show`              → post the alert; returns true when it was posted
 *  - `cancel`            → take it down (the order was opened or dismissed)
 *  - `readPendingAction` → the payload the app was launched with, or null
 *
 * Callback to Dart:
 *  - `onOrderOpened`     → fired when a live app is re-entered via the alert
 */
class NewOrderCallNotificationPlugin :
    FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener {

    private companion object {
        const val CHANNEL = "ai.bluecs/new_order_call_notification"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null

    /**
     * Payload from a launch intent this plugin has seen but Dart hasn't
     * collected yet. On a cold start the engine is still booting when the
     * activity's intent arrives, so the value waits here until
     * `readPendingAction` asks for it.
     */
    private var pendingPayload: String? = null
    private var pendingNotificationId: Int = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "show" -> {
                @Suppress("UNCHECKED_CAST")
                val args = (call.arguments as? Map<String, Any?>).orEmpty()
                result.success(NewOrderCallStyleNotification.show(context, args))
            }

            "cancel" -> {
                val id = (call.argument<Number>("id"))?.toInt() ?: 0
                if (id != 0) NewOrderCallStyleNotification.cancel(context, id)
                result.success(null)
            }

            "readPendingAction" -> {
                // Cold start: the launch intent is still on the activity, so
                // check it too — the plugin may have attached after it arrived.
                captureIntent(activityBinding?.activity?.intent)
                val payload = pendingPayload
                val id = pendingNotificationId
                pendingPayload = null
                pendingNotificationId = 0
                result.success(
                    if (payload == null) null
                    else mapOf("payload" to payload, "notificationId" to id)
                )
            }

            else -> result.notImplemented()
        }
    }

    // ── Activity lifecycle: catching the "order opened" intent ─────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        captureIntent(binding.activity.intent)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    /** Warm launch: the app was already running when the alert was tapped. */
    override fun onNewIntent(intent: Intent): Boolean {
        if (!captureIntent(intent)) return false
        // Dart is definitely alive here, so hand it over immediately rather
        // than waiting for someone to poll `readPendingAction`.
        val payload = pendingPayload ?: return false
        val id = pendingNotificationId
        pendingPayload = null
        pendingNotificationId = 0
        channel.invokeMethod(
            "onOrderOpened",
            mapOf("payload" to payload, "notificationId" to id)
        )
        return false // never consume it — other plugins read this intent too
    }

    /**
     * Pull our extras off [intent] and clear them, so the same launch intent
     * can't be replayed on every configuration change or resume.
     */
    private fun captureIntent(intent: Intent?): Boolean {
        val payload = intent
            ?.getStringExtra(NewOrderCallStyleNotification.EXTRA_PAYLOAD)
            ?.takeIf { it.isNotEmpty() }
            ?: return false

        pendingPayload = payload
        pendingNotificationId =
            intent.getIntExtra(NewOrderCallStyleNotification.EXTRA_NOTIFICATION_ID, 0)
        intent.removeExtra(NewOrderCallStyleNotification.EXTRA_PAYLOAD)
        intent.removeExtra(NewOrderCallStyleNotification.EXTRA_NOTIFICATION_ID)
        return true
    }
}
