package ai.bluecs.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Brings the rider's live-location service back after a device reboot.
 *
 * Without this, a rider who restarts their phone mid-shift stays "live" as far
 * as they know while publishing nothing — the map service closes them five
 * minutes later and the orders quietly stop.
 *
 * Only acts when the rider was actually live when the device went down: the
 * active flag is persisted by the service itself and cleared when they go
 * offline, so a rider who ended their shift is never resurrected by a reboot.
 *
 * Starting a location foreground service from the background is restricted on
 * Android 12+, but receiving BOOT_COMPLETED is one of the documented exemptions.
 */
class RiderLocationBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        val prefs = context.getSharedPreferences(
            RiderLocationForegroundService.PREFS, Context.MODE_PRIVATE
        )
        if (!prefs.getBoolean(RiderLocationForegroundService.KEY_ACTIVE, false)) return
        // No creds survived → nothing we can authenticate with; the rider's next
        // app open re-arms everything.
        if (prefs.getString(RiderLocationForegroundService.KEY_TOKEN, null).isNullOrEmpty()) {
            return
        }

        try {
            val service = Intent(context, RiderLocationForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(service)
            } else {
                context.startService(service)
            }
            // Re-arm the watchdog too — WorkManager schedules do survive reboot,
            // but re-enqueueing with KEEP is harmless and covers the case where
            // the schedule was lost with the app's data.
            RiderLocationWatchdogWorker.schedule(context)
        } catch (_: Exception) {
            // Best-effort. The rider opening the app restores everything.
        }
    }
}
