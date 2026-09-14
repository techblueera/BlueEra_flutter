package ai.bluecs.app

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner

/**
 * Decides whether this app may legally start / promote a
 * `foregroundServiceType="location"` service right now.
 *
 * ## Why this exists
 *
 * On Android 14+ (targetSdk 34+) `Service.startForeground()` for a `location`
 * service throws `SecurityException` unless ALL of the following hold:
 *
 *  1. `FOREGROUND_SERVICE` is declared,
 *  2. `FOREGROUND_SERVICE_LOCATION` is declared,
 *  3. `ACCESS_FINE_LOCATION` **or** `ACCESS_COARSE_LOCATION` is *granted at
 *     runtime*, and
 *  4. the app is "in an eligible state to access the foreground only
 *     permission" — location is a **while-in-use** permission, so a process
 *     that is not visible may only use it when `ACCESS_BACKGROUND_LOCATION`
 *     is granted, or when a narrow platform exemption applies.
 *
 * Points 1–2 are manifest entries and are already correct in this app. The
 * production crash is point 4: the rider granted "While using the app" but not
 * "Allow all the time", and the service was started from the background.
 *
 * ## Why the caller's try/catch did not help
 *
 * `context.startForegroundService(...)` and the `SecurityException` happen on
 * **different stacks**. The start call returns successfully; the system then
 * delivers `onStartCommand` to the service, and the throw happens there. So
 * `RiderLocationWatchdogWorker`'s `try { startForegroundService() } catch` could
 * never have caught it — the crash was already in a different frame by then.
 * The guard therefore has to run in two places: here, *before* asking, and
 * again as a try/catch *inside* the service.
 *
 * ## Why this is advisory, not authoritative
 *
 * The full eligibility rule includes exemptions this app cannot introspect
 * (a bound foreground service, a running `mediaProjection`, an active
 * `ACTION_VIEW_LOCUS` session, OEM allowlists...). [canStartFromBackground]
 * is therefore deliberately conservative: it answers "is a start obviously
 * safe?", not "is a start definitely illegal?". A false negative costs one
 * skipped restart; a false positive used to cost a process crash — and the
 * service's own try/catch is what makes a false positive survivable.
 */
object LocationFgsGuard {

    private const val TAG = "LocationFgsGuard"

    /** Foreground (while-in-use) location — fine or coarse. Requirement 3. */
    fun hasForegroundLocationPermission(context: Context): Boolean {
        return granted(context, Manifest.permission.ACCESS_FINE_LOCATION) ||
            granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)
    }

    /**
     * "Allow all the time". Requirement 4 for any background start.
     *
     * Below Android 10 there is no separate background-location grant — holding
     * foreground location is sufficient — so this reports the foreground grant
     * there rather than a permission the platform will never report as granted.
     */
    fun hasBackgroundLocationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return hasForegroundLocationPermission(context)
        }
        return granted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
    }

    /**
     * The typed FGS permission. Normal (install-time) permission, so this is
     * really a check that the manifest entry survived a merge — but a missing
     * entry fails at `startForeground()` with the same fatal `SecurityException`
     * as a missing runtime grant, so it is worth answering before we ask.
     */
    fun hasForegroundServiceLocationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        return granted(context, Manifest.permission.FOREGROUND_SERVICE_LOCATION)
    }

    /**
     * Whether this process currently counts as visible to the user.
     *
     * `ActivityManager.RunningAppProcessInfo.importance` is used rather than
     * `ProcessLifecycleOwner` because it models what the platform actually
     * gates on — process importance — and because it needs no extra dependency
     * and works in a process with no Activity at all, which is exactly the
     * BOOT_COMPLETED and WorkManager case. `ProcessLifecycleOwner` reports
     * *Activity* lifecycle; in a boot-started process it has no activities to
     * report on. See the class docs for the `lifecycle-process` variant.
     *
     * `IMPORTANCE_FOREGROUND_SERVICE` is included: a process already running
     * some other foreground service is eligible to start another one, which is
     * how this service legitimately restarts itself while the app is closed.
     */
    fun isAppVisible(context: Context): Boolean {
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                ?: return false
            val mine = android.os.Process.myPid()
            val info = am.runningAppProcesses?.firstOrNull { it.pid == mine } ?: return false
            info.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE
        } catch (e: Exception) {
            // Some OEM builds restrict runningAppProcesses. Unknown state is
            // treated as "not visible" so we fall back to the strict path.
            Log.w(TAG, "importance check failed: $e")
            false
        }
    }

    /**
     * The check to run immediately before `startForegroundService()` from a
     * **background** context — boot receiver, WorkManager, AlarmManager.
     *
     * Requires the full set including "Allow all the time", unless the process
     * happens to be visible right now (in which case the while-in-use grant is
     * enough and the start is a normal foreground start).
     */
    fun canStartFromBackground(context: Context): Boolean =
        ineligibilityReason(context, requireBackgroundGrant = !isAppVisible(context)) == null

    /**
     * The check to run before a **foreground** start — the method channel from
     * Dart, where an Activity is on screen.
     *
     * Background location is not required to *start* here, but it is required
     * for the service to survive the app going to background, which is the
     * whole point of this service. Callers should still gate the feature on
     * "Allow all the time" in the UI; this only decides whether starting now
     * would crash.
     */
    fun canStartFromForeground(context: Context): Boolean =
        ineligibilityReason(context, requireBackgroundGrant = false) == null

    /**
     * Null when a start is safe, otherwise a short reason for the log.
     *
     * Returning the reason rather than a bare boolean is deliberate: this fires
     * on a rider's device in the field, where the difference between "the
     * manifest entry is missing" and "the rider downgraded to While using the
     * app" decides whether it is a build problem or a re-prompt.
     */
    fun ineligibilityReason(context: Context, requireBackgroundGrant: Boolean): String? {
        if (!hasForegroundServiceLocationPermission(context)) {
            return "FOREGROUND_SERVICE_LOCATION not held"
        }
        if (!hasForegroundLocationPermission(context)) {
            return "no ACCESS_FINE/COARSE_LOCATION grant"
        }
        if (requireBackgroundGrant && !hasBackgroundLocationPermission(context)) {
            return "background start without ACCESS_BACKGROUND_LOCATION"
        }
        return null
    }

    /**
     * The `ProcessLifecycleOwner` reading of "is the app foregrounded".
     *
     * `androidx.lifecycle:lifecycle-process` is already on the runtime
     * classpath (WorkManager 2.9.1 pulls it in, resolved to 2.10.0). If this
     * becomes the primary check, add it explicitly to `app/build.gradle` —
     * relying on a transitive dependency for a crash-prevention path is how it
     * silently disappears during a WorkManager upgrade:
     *
     * ```gradle
     * implementation 'androidx.lifecycle:lifecycle-process:2.10.0'
     * ```
     *
     * [isAppVisible] is preferred for the FGS decision because it reads process
     * importance — what the platform itself gates on — and is meaningful in a
     * process with no Activity, which is exactly the BOOT_COMPLETED and
     * WorkManager case this crash came from. This variant answers a different
     * and narrower question: "is one of our Activities started?" It is the
     * better signal for UI decisions (should we show a permission dialog now?)
     * and it must be called on the main thread.
     */
    fun isAppInForegroundByLifecycle(): Boolean {
        return try {
            ProcessLifecycleOwner.get().lifecycle.currentState
                .isAtLeast(Lifecycle.State.STARTED)
        } catch (e: Exception) {
            // Not initialised in this process (a content-provider-less boot
            // process, or a non-default process). Unknown means not visible.
            Log.w(TAG, "ProcessLifecycleOwner unavailable: $e")
            false
        }
    }

    private fun granted(context: Context, permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED
}
