package ai.bluecs.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

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
 * BOOT_COMPLETED exempts this receiver from the Android 12 *background-start*
 * restriction (`ForegroundServiceStartNotAllowedException`). It does NOT exempt
 * it from the Android 14+ *while-in-use permission* rule that a `location` FGS
 * is additionally subject to: at boot the app is by definition not visible, so
 * without `ACCESS_BACKGROUND_LOCATION` the service's `startForeground()` throws
 * `SecurityException` and takes the process with it. Two different restrictions
 * with two different exemption lists; the old comment conflated them, and this
 * receiver was one of the three background paths producing the crash.
 */
class RiderLocationBootReceiver : BroadcastReceiver() {

    private companion object {
        const val TAG = "RiderLocationBoot"
    }

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

        // Pre-flight. The service defends itself too, but starting a service we
        // know cannot go foreground costs a process wake, a notification
        // channel, and a 5-second window in which the platform is waiting for a
        // startForeground() that will never come.
        val blocked = LocationFgsGuard.ineligibilityReason(
            context,
            requireBackgroundGrant = true // at boot the app is never visible
        )
        if (blocked != null) {
            Log.w(TAG, "not restoring rider location service after boot: $blocked")
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
