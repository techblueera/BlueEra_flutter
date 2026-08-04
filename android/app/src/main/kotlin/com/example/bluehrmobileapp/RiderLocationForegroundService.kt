package ai.bluecs.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat
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
        const val CHANNEL_ID = "rider_live_location"
        const val NOTIFICATION_ID = 99003
        const val PREFS = "rider_live_location_prefs"
        const val KEY_TOKEN = "token"
        const val KEY_USER = "userId"
        const val KEY_BASE = "baseUrl"
        const val KEY_ACTIVE = "active"

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

        startForeground(NOTIFICATION_ID, buildNotification())
        isRunning = true

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
        if (prefs.getBoolean(KEY_ACTIVE, false)) {
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
