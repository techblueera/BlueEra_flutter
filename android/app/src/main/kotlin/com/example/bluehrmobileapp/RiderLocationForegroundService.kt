package ai.bluecs.app

import android.app.AlarmManager
import android.app.ForegroundServiceStartNotAllowedException
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Foreground service that keeps a LIVE rider discoverable by POSTing their
 * location to the map service every 30s — in foreground, background AND after
 * the app is swipe/OS-killed.
 *
 * WHY A FOREGROUND SERVICE AND NOT WORKMANAGER: WorkManager's minimum periodic
 * interval is 15 minutes, and Doze defers even that to a maintenance window.
 * The map service closes a provider after 5 minutes of silence, so a
 * WorkManager heartbeat would drop riders offline continuously. A
 * `foregroundServiceType="location"` service is the platform's sanctioned way
 * to track someone who is on duty, and it is exempt from those limits while it
 * runs. WorkManager is only useful here as a slow watchdog that restarts THIS
 * service — see onTaskRemoved, which covers the same gap without the extra
 * dependency.
 *
 * Why native (not the Dart timer): a Dart Timer dies the moment the Flutter
 * engine is torn down (background freeze / kill). This service does the GPS
 * read + HTTP POST itself, entirely independent of the Flutter engine, and is
 * START_STICKY so Android restarts it after a kill. On restart the intent is
 * null, so the token/userId/baseUrl are persisted to SharedPreferences and
 * re-read here.
 *
 * Stopped by the Dart side (LiveLocationService.stop → channel "stop") which
 * clears the active flag; the next tick then stops the service.
 */
class RiderLocationForegroundService : Service() {

    companion object {
        const val TAG = "RiderLocationFgs"
        const val CHANNEL_ID = "rider_live_location"
        const val NOTIFICATION_ID = 99003
        const val PREFS = "rider_live_location_prefs"
        const val KEY_TOKEN = "token"
        const val KEY_USER = "userId"
        const val KEY_BASE = "baseUrl"
        const val KEY_ACTIVE = "active"

        /// Why the last foreground promotion was refused, or absent when the
        /// service last started cleanly. Read by Dart on resume so a rider who
        /// silently stopped publishing is re-prompted for "Allow all the time"
        /// instead of believing they are live while the map service has already
        /// closed them.
        const val KEY_BLOCKED_REASON = "fgsBlockedReason"
        const val KEY_BLOCKED_AT = "fgsBlockedAt"

        /// Wall-clock of the last accepted publish. The watchdog reads it to
        /// tell "running" apart from "actually working".
        const val KEY_LAST_PING = "lastPingAt"

        /// True while the service object is alive in THIS process. A process
        /// kill resets it to false on reload, which is exactly the signal the
        /// watchdog needs.
        @Volatile
        @JvmStatic
        var isRunning: Boolean = false
            private set

        /// Matches the Dart heartbeat. The map-service closes a provider after
        /// 5 minutes of silence, so 30s survives several consecutive failures.
        const val INTERVAL_MS = 30_000L

        /// Delay before re-arming after the task is swiped away. Short, but not
        /// instant — the OS is tearing the task down and an immediate restart
        /// races that.
        const val RESTART_DELAY_MS = 2_000L

        const val LOCATION_PATH = "/map-service/api/provider/location"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var ticking = false

    private val tick = object : Runnable {
        override fun run() {
            pingLocation()
            handler.postDelayed(this, INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // NOTHING above this line. The clock on
        // ForegroundServiceDidNotStartInTimeException starts at the caller's
        // startForegroundService() and runs for ~5s; everything between that
        // call and startForeground() spends it, and all of this runs on the
        // main thread. Reading SharedPreferences used to happen up here, which
        // is a synchronous disk read — cheap when the page cache is warm, less
        // so on a device under I/O load. Persisting the creds first bought
        // nothing: the promotion does not consult them.
        //
        // The worst caller for that deadline, a BOOT_COMPLETED receiver, has
        // since been removed outright — see the note in AndroidManifest.xml.
        // What remains are MainActivity (app visible) and the WorkManager
        // watchdog (process already warm).
        //
        // MUST be the first thing that can fail, and it MUST NOT throw.
        //
        // Android 14+ (this app targets 36) rejects `startForeground()` for a
        // `location` service unless the app holds FOREGROUND_SERVICE_LOCATION,
        // holds fine/coarse location, AND is in an eligible state to use a
        // while-in-use permission. The last clause is the one that fired in
        // production: the rider had granted "While using the app" only, and
        // the watchdog/boot receiver/restart alarm started this service with
        // the app 100% in the background. The throw landed here, in
        // onStartCommand, NOT in the caller's try/catch — which is why the
        // watchdog's `catch` around startForegroundService never saw it.
        if (!promoteToForeground()) {
            // Give up cleanly. Two things matter here:
            //
            //  * stopSelf() must happen — a service started with
            //    startForegroundService() that never reaches startForeground()
            //    is killed with ForegroundServiceDidNotStartInTimeException
            //    after ~5s, which is a second crash on top of the first.
            //  * START_NOT_STICKY, not START_STICKY — a sticky restart of a
            //    service that cannot go foreground is an infinite crash loop.
            //    The rider is brought back by the next app open (see
            //    KEY_BLOCKED_REASON), not by a retry that cannot succeed.
            stopSelf(startId)
            return START_NOT_STICKY
        }

        isRunning = true

        // Past the deadline — disk work is safe from here on.
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // Persist creds when started with them (foreground start from Dart). On
        // a START_STICKY restart the intent is null → we keep the last values.
        val token = intent?.getStringExtra("token")
        val userId = intent?.getStringExtra("userId")
        val baseUrl = intent?.getStringExtra("baseUrl")
        if (!token.isNullOrEmpty() && !userId.isNullOrEmpty() && !baseUrl.isNullOrEmpty()) {
            prefs.edit()
                .putString(KEY_TOKEN, token)
                .putString(KEY_USER, userId)
                .putString(KEY_BASE, baseUrl)
                .putBoolean(KEY_ACTIVE, true)
                .apply()
        }

        // Only ever runs while the rider is live — the flag is cleared the
        // moment they go offline, and the watchdog cancels itself on seeing
        // that. Nothing here publishes a location for an offline user.
        if (prefs.getBoolean(KEY_ACTIVE, false)) {
            RiderLocationWatchdogWorker.schedule(applicationContext)
        }

        if (!ticking) {
            ticking = true
            handler.post(tick) // first ping immediately, then every INTERVAL_MS
        }
        return START_STICKY
    }

    /**
     * Promotes this service to the foreground, returning false instead of
     * throwing when the platform refuses.
     *
     * Defence in depth, in this order:
     *
     *  1. Ask [LocationFgsGuard] first, so the ordinary "rider revoked Allow
     *     all the time" case is a logged no-op rather than a caught throwable.
     *  2. Call through `ServiceCompat`, which passes the type on API 29+ and
     *     omits it below, so one call site covers every supported API level.
     *  3. Catch anyway. The eligibility rule includes exemptions no app can
     *     introspect, so step 1 can be wrong in both directions; this is the
     *     only layer that is guaranteed to hold.
     */
    private fun promoteToForeground(): Boolean {
        val reason = LocationFgsGuard.ineligibilityReason(
            this,
            // A visible process may use a while-in-use permission without the
            // background grant; an invisible one may not.
            requireBackgroundGrant = !LocationFgsGuard.isAppVisible(this)
        )
        if (reason != null) {
            recordBlocked(reason)
            Log.w(TAG, "not promoting to foreground: $reason")
            return false
        }

        return try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                } else {
                    0
                }
            )
            clearBlocked()
            true
        } catch (e: SecurityException) {
            // Missing permission, or ineligible app state, on API 34+.
            recordBlocked("SecurityException: ${e.message?.take(180)}")
            Log.w(TAG, "startForeground denied: $e")
            false
        } catch (e: Exception) {
            // API 31+ ForegroundServiceStartNotAllowedException is the common
            // one; it is referenced by name only where it exists so this file
            // still compiles against older platforms.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                e is ForegroundServiceStartNotAllowedException
            ) {
                recordBlocked("background start not allowed")
                Log.w(TAG, "foreground start not allowed: $e")
            } else {
                recordBlocked("startForeground failed: ${e.javaClass.simpleName}")
                Log.w(TAG, "startForeground failed: $e")
            }
            false
        }
    }

    /**
     * Leaves a breadcrumb the app can read on next launch.
     *
     * Without this the failure is invisible: the rider believes they are live,
     * the service is gone, and the map service closes them five minutes later.
     * The Dart side reads this on resume and can re-prompt for "Allow all the
     * time" instead of silently never publishing again.
     */
    private fun recordBlocked(reason: String) {
        try {
            getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(KEY_BLOCKED_REASON, reason)
                .putLong(KEY_BLOCKED_AT, System.currentTimeMillis())
                .apply()
        } catch (_: Exception) {
        }
    }

    private fun clearBlocked() {
        try {
            val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (prefs.contains(KEY_BLOCKED_REASON)) {
                prefs.edit()
                    .remove(KEY_BLOCKED_REASON)
                    .remove(KEY_BLOCKED_AT)
                    .apply()
            }
        } catch (_: Exception) {
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * The app was swiped out of recents.
     *
     * START_STICKY alone is NOT enough here: on task removal many OEM builds
     * (Xiaomi, Oppo, Vivo, Realme, and Samsung's aggressive profile) destroy the
     * service without honouring the sticky restart, which is exactly the case
     * this service exists for — a live rider whose app is gone. Schedule a
     * one-shot alarm to bring it back, but only while the rider is still live;
     * a rider who went offline must not be resurrected.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // The alarm fires with the task gone, so the restarted service will be
        // promoting itself from a fully background state. Without the "Allow
        // all the time" grant that restart is guaranteed to be refused — and
        // before the guard existed, guaranteed to crash. Don't arm an alarm
        // whose only possible outcome is a failed start.
        if (prefs.getBoolean(KEY_ACTIVE, false) &&
            LocationFgsGuard.hasBackgroundLocationPermission(this) &&
            LocationFgsGuard.hasForegroundLocationPermission(this)
        ) {
            scheduleRestart()
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun scheduleRestart() {
        try {
            val restart = PendingIntent.getService(
                this,
                NOTIFICATION_ID,
                Intent(this, RiderLocationForegroundService::class.java),
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarms = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarms.set(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + RESTART_DELAY_MS,
                restart
            )
        } catch (_: Exception) {
            // Nothing more we can do from a dying process; the rider's next app
            // open re-arms the service.
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        ticking = false
        isRunning = false
        super.onDestroy()
    }

    private fun pingLocation() {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ACTIVE, false)) {
            // Rider went offline — tear the service AND the watchdog down, so
            // nothing keeps publishing (or keeps trying to restart something
            // that publishes) for someone who is no longer live.
            RiderLocationWatchdogWorker.cancel(applicationContext)
            stopSelf()
            return
        }
        val token = prefs.getString(KEY_TOKEN, null) ?: return
        // Still required as a signed-in guard, but deliberately NOT sent in the
        // body — the provider is resolved from the bearer token (see below).
        prefs.getString(KEY_USER, null) ?: return
        val baseUrl = prefs.getString(KEY_BASE, null) ?: return
        val loc = lastKnownLocation() ?: return

        // Network on a worker thread — never block the main looper.
        Thread {
            try {
                val endpoint = baseUrl.trimEnd('/') + LOCATION_PATH
                val conn = URL(endpoint).openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.setRequestProperty("Authorization", "Bearer $token")
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                conn.doOutput = true
                // Body is exactly { lat, lng }. The provider comes from the
                // bearer token — a client-supplied userId is either ignored or,
                // if the server trusted it, would let one rider publish another
                // rider's position.
                val body = JSONObject()
                    .put("lat", loc.latitude)
                    .put("lng", loc.longitude)
                    .toString()
                conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                val code = conn.responseCode // triggers the request
                if (code in 200..299) {
                    prefs.edit()
                        .putLong(KEY_LAST_PING, System.currentTimeMillis())
                        .apply()
                }
                conn.disconnect()
            } catch (_: Exception) {
                // Best-effort — the next tick retries.
            }
        }.start()
    }

    // Last known fix from GPS or network — whichever is newer. The rider is
    // typically stationary once the app is killed, so a last-known fix is an
    // acceptable heartbeat; the app's own 60s ping sends a fresh fix whenever
    // the Flutter engine is alive.
    private fun lastKnownLocation(): Location? {
        return try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val gps = try {
                lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            } catch (_: SecurityException) {
                null
            }
            val net = try {
                lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            } catch (_: SecurityException) {
                null
            }
            when {
                gps != null && net != null -> if (gps.time >= net.time) gps else net
                else -> gps ?: net
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Live Location",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps you discoverable to customers while you're live"
                setShowBadge(false)
                setSound(null, null)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("You're live")
            .setContentText("Sharing your location so customers can find you")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
