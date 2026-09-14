# Rider live-location foreground service — crash, fix, and permission strategy

Covers the `java.lang.SecurityException: Starting FGS with type location ...`
crash in `RiderLocationForegroundService.onStartCommand` on Android 14+
(`targetSdkVersion 36`).

---

## 1. What actually happened

```
java.lang.SecurityException: Starting FGS with type location ... targetSDK=36
  requires permissions:
    all of the permissions allOf=true [android.permission.FOREGROUND_SERVICE_LOCATION]
    any of the permissions allOf=false [ACCESS_COARSE_LOCATION, ACCESS_FINE_LOCATION]
    and the app must be in the eligible state/exemptions to access the foreground only permission
```

The message lists three requirements. **The first two were already satisfied** —
`AndroidManifest.xml` declares `FOREGROUND_SERVICE_LOCATION` (line 56) and both
location permissions (lines 11–12). The failure is the third clause.

Location is a **while-in-use** permission. Per
[the FGS type docs](https://developer.android.com/develop/background-work/services/fgs/service-types):

> The location runtime permissions are subject to while-in-use restrictions. For
> this reason, you cannot create a `location` foreground service while your app
> is in the background, **unless you've been granted the
> `ACCESS_BACKGROUND_LOCATION` runtime permission**.

The crash report says *Device State at Crash: 100% background*. So: a rider who
granted **"While using the app"** but not **"Allow all the time"**, with the
service started from a background context.

Declaring `ACCESS_BACKGROUND_LOCATION` in the manifest is **not** holding it. It
is a runtime permission, and on Android 11+ the user cannot grant it from a
dialog at all — only from the system Settings page.

### The four background start paths

| Caller | Context | Was it a crash source? |
|---|---|---|
| `MainActivity` method channel `"start"` | Activity on screen | No — foreground start is legal on while-in-use alone |
| `RiderLocationBootReceiver` | BOOT_COMPLETED — never visible | **Yes** |
| `RiderLocationWatchdogWorker` | WorkManager — background | **Yes** |
| `scheduleRestart()` AlarmManager → `PendingIntent.getService` | fires after task removal | **Yes** |

### Why the existing `try/catch` never fired

`RiderLocationWatchdogWorker` wrapped its start like this:

```kotlin
return try {
    applicationContext.startForegroundService(intent)   // returns fine
    Result.success()
} catch (_: Exception) {
    Result.retry()                                      // never reached
}
```

`startForegroundService()` **succeeds**. The system then delivers
`onStartCommand` to the service, and the `SecurityException` is thrown *there* —
a different stack, in a different component, after the caller's `try` block has
already returned. No caller-side `catch` can ever intercept it.

That is why the fix has to exist in two places: a pre-check in each caller, and
a `try/catch` inside the service.

### A related misconception in the code

`RiderLocationBootReceiver` carried this comment:

> Starting a location foreground service from the background is restricted on
> Android 12+, but receiving BOOT_COMPLETED is one of the documented exemptions.

Half right, and the half that is wrong is the half that crashed. There are **two
separate restrictions** with **two separate exemption lists**:

1. **Background-start restriction** (Android 12+) → throws
   `ForegroundServiceStartNotAllowedException`. BOOT_COMPLETED *is* an exemption.
2. **While-in-use permission restriction** (Android 14+) → throws
   `SecurityException`. BOOT_COMPLETED is **not** an exemption; only
   `ACCESS_BACKGROUND_LOCATION` is.

For the record, `location` is *not* on
[Android 15's list of types banned from BOOT_COMPLETED](https://developer.android.com/about/versions/15/behavior-changes-15)
(that list is `camera`, `dataSync`, `mediaPlayback`, `mediaProjection`,
`microphone`). Restoring the service after a reboot is legitimate — but only
with the background grant held.

---

## 2. Defensive fix in the service

`RiderLocationForegroundService.onStartCommand` — the promotion is now the first
thing that can fail, and it cannot throw.

```kotlin
if (!promoteToForeground()) {
    stopSelf(startId)
    return START_NOT_STICKY
}
```

Two details matter as much as the `try/catch`:

- **`stopSelf()` is mandatory.** A service started via
  `startForegroundService()` that never reaches `startForeground()` is killed
  with `ForegroundServiceDidNotStartInTimeException` after ~5 seconds. Catching
  the first crash and then sitting there just trades it for a second one.
- **`START_NOT_STICKY`, not `START_STICKY`.** A sticky restart of a service that
  *cannot* go foreground is an infinite crash-restart loop. The rider is
  recovered by the next app open, not by a retry that cannot succeed.

```kotlin
private fun promoteToForeground(): Boolean {
    val reason = LocationFgsGuard.ineligibilityReason(
        this,
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
        recordBlocked("SecurityException: ${e.message?.take(180)}")
        false
    } catch (e: Exception) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            e is ForegroundServiceStartNotAllowedException
        ) {
            recordBlocked("background start not allowed")
        } else {
            recordBlocked("startForeground failed: ${e.javaClass.simpleName}")
        }
        false
    }
}
```

Three layers, deliberately:

1. **Ask first** — the ordinary "rider revoked Allow all the time" case becomes
   a logged no-op instead of a caught throwable.
2. **`ServiceCompat.startForeground`** — passes the type on API 29+, omits it
   below, so one call site covers `minSdk 26` through `targetSdk 36`. The
   original called the 2-arg `startForeground()` and relied entirely on the
   manifest's `foregroundServiceType`.
3. **Catch anyway** — the eligibility rule includes exemptions no app can
   introspect (bound foreground service, active `mediaProjection`, OEM
   allowlists), so step 1 can be wrong in both directions. This layer is the
   only one guaranteed to hold.

### Making silent failure visible

`recordBlocked()` writes the reason to SharedPreferences. Without it, refusal is
invisible in the worst possible way: the rider believes they are live, the
service is gone, and the map service closes them after five minutes of silence.
Dart reads it back through the `eligibility` channel method and can re-prompt.

---

## 3. Caller pre-checks

### Kotlin — `LocationFgsGuard.kt`

The composite check, used by every caller:

```kotlin
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
```

It returns the *reason*, not a bare boolean, because on a rider's device in the
field the difference between "the manifest entry was dropped by a merge" and
"the rider downgraded to While using the app" decides whether it's a build
problem or a re-prompt.

### Foreground detection — why not `ProcessLifecycleOwner`

The primary check uses process importance:

```kotlin
fun isAppVisible(context: Context): Boolean {
    return try {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        val mine = android.os.Process.myPid()
        val info = am.runningAppProcesses?.firstOrNull { it.pid == mine } ?: return false
        info.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE
    } catch (e: Exception) {
        false   // unknown state → take the strict path
    }
}
```

`IMPORTANCE_FOREGROUND_SERVICE` is included on purpose: a process already
running another foreground service is eligible to start one more, which is how
this service legitimately restarts itself while the app is closed.

`ProcessLifecycleOwner` is also provided (`isAppInForegroundByLifecycle()`) since
it was asked for, but it is **not** the right primary check here:

- it reports **Activity** lifecycle, and the crashing paths run in processes
  with no Activity at all (BOOT_COMPLETED, WorkManager);
- process importance is what the platform itself gates on;
- it must be called on the main thread;
- it needs `androidx.lifecycle:lifecycle-process`, which this project gets only
  **transitively** (WorkManager 2.9.1 → lifecycle-process 2.7.0, resolved to
  2.10.0 — verified with `./gradlew :app:dependencies`). If it becomes a
  crash-prevention dependency, declare it explicitly, or a future WorkManager
  bump silently removes it:

  ```gradle
  implementation 'androidx.lifecycle:lifecycle-process:2.10.0'
  ```

### Applied at each call site

```kotlin
// RiderLocationBootReceiver — at boot the app is never visible
val blocked = LocationFgsGuard.ineligibilityReason(context, requireBackgroundGrant = true)
if (blocked != null) {
    Log.w(TAG, "not restoring rider location service after boot: $blocked")
    return
}
```

```kotlin
// RiderLocationWatchdogWorker
val blocked = LocationFgsGuard.ineligibilityReason(
    applicationContext,
    requireBackgroundGrant = !LocationFgsGuard.isAppVisible(applicationContext)
)
if (blocked != null) {
    Log.w(TAG, "not restarting rider location service: $blocked")
    return Result.success()   // NOT retry() — see below
}
```

`Result.success()` rather than `Result.retry()`: a missing permission does not
resolve by trying again in ten minutes, and retrying burns the worker's backoff
budget. The periodic schedule stays in place, so the moment the rider grants the
permission the next window picks it up.

```kotlin
// onTaskRemoved — don't arm a restart alarm that can only fail
if (prefs.getBoolean(KEY_ACTIVE, false) &&
    LocationFgsGuard.hasBackgroundLocationPermission(this) &&
    LocationFgsGuard.hasForegroundLocationPermission(this)
) {
    scheduleRestart()
}
```

```kotlin
// MainActivity channel — an Activity is attached, so while-in-use is enough
val blocked = LocationFgsGuard.ineligibilityReason(this, requireBackgroundGrant = false)
...
} else if (blocked != null) {
    result.error("FGS_NOT_ELIGIBLE", blocked, null)   // structured error, not a crash
}
```

### Dart — `LiveLocationService`

`_startNativeKillModePinger()` previously invoked the channel with **no
permission check at all**, and `_ensureLocationUsable()` ran *after* it. Now:

```dart
if (!await GoLivePermissionService.isBackgroundLocationGranted()) {
  _nativeKillModeUnavailableReason =
      'Background location ("Allow all the time") is not granted';
  return;
}

try {
  await _nativeLocationChannel.invokeMethod('start', {...});
  _nativeKillModeUnavailableReason = null;
} on PlatformException catch (e) {
  _nativeKillModeUnavailableReason = e.message ?? e.code;
}
```

And to detect a refusal that happened while the app was away:

```dart
final state = await LiveLocationService().nativeLocationEligibility();
if (state?['lastBlockedReason'] != null) {
  // The rider has been invisible to customers since lastBlockedAt.
  await GoLivePermissionService.requestBackgroundLocation();
}
```

`GoLivePermissionService.isBackgroundLocationGranted()` already checks
foreground first then `Permission.locationAlways` — reuse it rather than adding
a second source of truth.

---

## 4. Manifest & permission strategy

### The manifest was already correct

No changes were needed. For reference, the required set:

```xml
<!-- While-in-use location. At least one is required for a `location` FGS. -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- "Allow all the time". REQUIRED to start/keep a location FGS from the
     background. Declared here, but granted only at runtime via Settings. -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Any foreground service. -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Android 14+ typed FGS permission, matching foregroundServiceType below. -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!-- Restoring the service after reboot. -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<service
    android:name=".RiderLocationForegroundService"
    android:exported="false"
    android:foregroundServiceType="location" />
```

Two things to keep an eye on:

- **Never put `android:maxSdkVersion` on the location or FGS permissions.** The
  manifest correctly caps `READ_EXTERNAL_STORAGE` (32), `BLUETOOTH` (30) and
  `WRITE_EXTERNAL_STORAGE` (28); a cap on any of the five above would reproduce
  this crash on exactly the devices that enforce it.
- **`foregroundServiceType` must match the permission and the
  `ServiceCompat.startForeground` type argument.** All three now say `location`.

### Requesting `ACCESS_BACKGROUND_LOCATION` correctly

The platform enforces a strict sequence, and getting it wrong produces a silent
permanent denial:

1. **Foreground first.** Request `ACCESS_FINE_LOCATION` and have it granted.
   Requesting background before foreground is auto-denied.
2. **Never request both in one call.** On Android 11+ a combined request is
   rejected outright.
3. **Explain before asking.** Play policy requires a prominent in-app disclosure
   for background location, and it must appear *before* the system UI. The
   existing `go_live_permission_screen.dart` is that disclosure — keep the ask
   behind it.
4. **On Android 11+ there is no dialog.** `Permission.locationAlways.request()`
   returns `permanentlyDenied`; the user must pick "Allow all the time" on the
   app's Settings page. The existing code handles this:

   ```dart
   var always = await Permission.locationAlways.status;
   if (!always.isGranted) {
     always = await Permission.locationAlways.request();
   }
   if (!always.isGranted && always.isPermanentlyDenied) {
     await openAppSettings();
   }
   return always.isGranted;
   ```

5. **Re-check on every resume.** The grant can be revoked in Settings at any
   time, and Android auto-revokes permissions for unused apps. A rider who was
   live yesterday is not necessarily eligible today — which is exactly the
   scenario that produced this crash.

### Play Store note

`ACCESS_BACKGROUND_LOCATION` requires a declaration form and a video
demonstration of the in-app disclosure. Rider live-tracking is a sanctioned use
case, but the listing must show the disclosure screen and the feature it gates.

---

## 5. Behaviour after the fix

| Situation | Before | After |
|---|---|---|
| Background start, no "Allow all the time" | `SecurityException`, process crash | Logged, service stops cleanly, reason persisted |
| Boot with background grant | Worked | Works (unchanged) |
| Boot without background grant | Crash | Skipped, logged |
| Watchdog restart while backgrounded, grant revoked | Crash every 15 min | Skipped; resumes automatically when re-granted |
| Task swiped, grant revoked | Alarm → crash | No alarm armed |
| Foreground start from Dart | Worked | Works; refusal returns `FGS_NOT_ELIGIBLE` instead of crashing |
| Rider silently not publishing | No signal anywhere | `lastBlockedReason` readable from Dart on resume |

---

## 6. Verification

- `./gradlew :app:compileDebugKotlin` — **BUILD SUCCESSFUL**, no new warnings.
- `flutter analyze lib/` — zero errors; the changed Dart file reports no issues.
- `flutter test` — the 8 pre-existing widget-rendering failures are unchanged;
  no new failures.

There is no Android unit-test source set in this project (`app/src/test` and
`app/src/androidTest` do not exist), so the Kotlin paths are not covered by
automated tests. Manual reproduction:

1. Go live, grant **While using the app** only.
2. Force-stop, then trigger the watchdog:
   `adb shell cmd jobscheduler run -f ai.bluecs.app <jobId>`, or reboot to
   exercise the boot receiver.
3. Before: `SecurityException` in logcat plus a process death. After:
   `W/RiderLocationWatchdog: not restarting rider location service: background
   start without ACCESS_BACKGROUND_LOCATION`.
4. Grant **Allow all the time**, repeat — the service starts and publishes.

---

## Sources

- [Foreground service types — `location`](https://developer.android.com/develop/background-work/services/fgs/service-types)
- [Restrictions on starting a foreground service from the background](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)
- [Behavior changes: apps targeting Android 15+](https://developer.android.com/about/versions/15/behavior-changes-15)
- [Changes to foreground service types for Android 15](https://developer.android.com/about/versions/15/changes/foreground-service-types)
