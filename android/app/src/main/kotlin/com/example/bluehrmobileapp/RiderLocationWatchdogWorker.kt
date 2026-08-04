package ai.bluecs.app

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Restarts [RiderLocationForegroundService] when it has stopped while the rider
 * is still live.
 *
 * THIS IS NOT THE HEARTBEAT. WorkManager's minimum periodic interval is 15
 * minutes and Doze defers even that, while the map service closes a provider
 * after 5 minutes of silence — a WorkManager-driven ping would drop riders
 * offline constantly. The heartbeat is the foreground service; this is the
 * watchdog that notices when that service is gone.
 *
 * It covers the case nothing else can: an OEM battery manager (Xiaomi, Oppo,
 * Vivo, Realme, aggressive Samsung profiles) killing the service outright, where
 * both START_STICKY and the task-removal alarm are ignored. Worst case the rider
 * is offline for one watchdog interval instead of the rest of their shift.
 *
 * Two failure shapes are checked, because "running" is not the same as
 * "working":
 *   1. the service object is gone (process killed → [RiderLocationForegroundService.isRunning] is false);
 *   2. the service is alive but hasn't published in a while (wedged network /
 *      location stack), detected via the last-ping stamp.
 */
class RiderLocationWatchdogWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        const val WORK_NAME = "rider_live_location_watchdog"

        /// WorkManager's floor. Asking for less is silently raised to this.
        const val INTERVAL_MINUTES = 15L

        /// A service that hasn't published in this long is treated as wedged and
        /// restarted. Generous relative to the 30s heartbeat so a patch of bad
        /// network doesn't cause a pointless restart.
        const val STALE_PING_MS = 5 * 60 * 1000L

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<RiderLocationWatchdogWorker>(
                INTERVAL_MINUTES, TimeUnit.MINUTES
            ).build()
            // KEEP: going live repeatedly must not reset the schedule, or the
            // watchdog would never actually get to run on a rider who toggles.
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }

    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences(
            RiderLocationForegroundService.PREFS, Context.MODE_PRIVATE
        )

        // Rider went offline — stop checking and let the schedule die.
        if (!prefs.getBoolean(RiderLocationForegroundService.KEY_ACTIVE, false)) {
            cancel(applicationContext)
            return Result.success()
        }

        val lastPing = prefs.getLong(RiderLocationForegroundService.KEY_LAST_PING, 0L)
        val stale = lastPing > 0L &&
            System.currentTimeMillis() - lastPing > STALE_PING_MS

        if (RiderLocationForegroundService.isRunning && !stale) {
            return Result.success()
        }

        return try {
            val intent = Intent(applicationContext, RiderLocationForegroundService::class.java)
            // Creds are already in SharedPreferences, so a bare start is enough;
            // the service re-reads them exactly as it does on a sticky restart.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent)
            } else {
                applicationContext.startService(intent)
            }
            Result.success()
        } catch (_: Exception) {
            // Android 12+ blocks some background foreground-service starts. Retry
            // on the next window rather than dropping the watchdog.
            Result.retry()
        }
    }
}
