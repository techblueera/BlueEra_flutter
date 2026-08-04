# Rider live location — how it works

**Audience:** product, ops and engineering leads.
**Scope:** how a live rider's position reaches the server, what keeps it running
when the app isn't in front of the rider, and where it can still fail.

---

## 1. Why this exists

A rider who is **live** must be findable. Customer discovery ranks riders by
their last reported position, and the map service **drops a rider off the map
after 5 minutes of silence**. If the app stops reporting — because the phone
locked, the rider swiped the app away, or the battery manager killed it — the
rider believes they are online and takes no orders, with nothing on screen to
tell them why.

So the goal is simple to state and hard to guarantee: **while a rider is live,
their position reaches the server every 30 seconds, in every app state.**

---

## 2. The one rule

> **Location is sent only while the rider is LIVE.**

Going offline clears a single stored flag, and every mechanism below checks it:
the heartbeat stops, the background service tears itself down, the watchdog
cancels itself, and the restart-after-reboot does nothing. There is no path that
publishes a location for a rider who is not live.

The same applies to logout, which stops everything explicitly.

This is true for **riders and self-employed providers alike** — both use the same
go-live switch and the same reporting.

---

## 3. What sends the location, and when

| App state | What runs | How often | Position used |
|---|---|---|---|
| Open, on screen | App timer | 30s | Fresh GPS |
| Open, in background / screen off | App timer, kept awake by a foreground service | 30s | Fresh GPS |
| Swiped away / killed | Android background service (independent of the app) | 30s | Last known |
| Killed by the phone's battery manager | Watchdog restarts the service | checked every 15 min | — |
| After a reboot | Boot listener restarts the service | at boot | — |
| App reopened | State is re-asserted and reporting restarts | immediately | Fresh GPS |

There is also a **faster channel during an active ride** (roughly every 3–5
seconds) so the customer's tracking map moves smoothly. That is separate from
the 30-second "I am available" heartbeat described here.

**Server side:** each report is a small `POST` carrying only latitude and
longitude. The rider is identified from their login token, never from anything
the app puts in the message — so one rider can never report a position on behalf
of another.

---

## 4. What happens when something fails

| Problem | What the app does | What the rider sees |
|---|---|---|
| Network drops a report | Retries twice, 5 seconds apart, then waits for the next cycle | Nothing |
| GPS can't get a fix | Waits up to 20s, then sends the last known position | Nothing |
| A cycle runs long | Skips the overlapping cycle so positions can't arrive out of order | Nothing |
| Location switched off | Tells them, and opens the phone's location settings | A message, once per shift |
| Location permission missing | Asks for it | The standard permission prompt |
| Permission permanently blocked | Tells them, and opens app settings | A message, once per shift |
| App swiped away | Background service keeps reporting; re-armed within 2s if the phone stops it | Nothing |
| Battery manager kills the service | Watchdog restarts it at the next 15-minute check | Offline for at most one check |
| Phone reboots mid-shift | Reporting restarts at boot | Nothing |

Failures are deliberately **silent** unless the rider is the only one who can fix
them. An earlier version raised an error message on every failed report, so a
rider on a weak connection was interrupted every minute about something that
corrected itself.

---

## 5. Why a background service and not a scheduled job

We were asked whether Android's WorkManager could do the reporting. It cannot,
for one hard reason:

> **WorkManager's minimum repeat interval is 15 minutes**, and the phone's power
> saving can delay even that. The server drops a rider after 5 minutes.

A WorkManager-driven heartbeat would put riders offline more or less
continuously. The mechanism Android provides for exactly this case — a person
who is on duty and being tracked — is a **foreground service with a location
type**, which is what we use, and which is exempt from those delays while it
runs. It is the same approach the large delivery and ride-hailing apps take, and
it is why a persistent notification is shown while a rider is live.

WorkManager still earns a place, just not that one: it runs a **15-minute
watchdog** that asks "the rider is live — is the reporting service actually
alive and reporting?" and restarts it if not. Slow, but it is the only thing
that recovers from an aggressive battery manager killing the service outright.
It checks two different things, because *running* is not the same as *working*:

1. the service is gone (the app's process was killed), or
2. the service is alive but hasn't successfully reported in 5 minutes.

---

## 6. Layers, and what each one is for

| Layer | Covers | Why the layer below isn't enough |
|---|---|---|
| App timer | App open (foreground and background) | — |
| Foreground-service hold | Screen off, other apps in use | Android freezes a background app's timers |
| Background location service | App swiped away or killed | The app's timer dies with the app |
| Restart on task removal | Phones that ignore Android's own restart | Several popular brands do ignore it |
| 15-minute watchdog | Battery managers that kill the service anyway | Nothing else notices a kill |
| Boot listener | Reboot mid-shift | Every other layer died with the phone |

---

## 7. What the rider must allow

Reporting is only as good as the permissions granted. The go-live flow asks for
these; if any is later revoked, the app asks again the next time it needs it.

| Permission | Why | If refused |
|---|---|---|
| Location, "while using the app" | To get a position at all | Cannot go live |
| Location, "allow all the time" | To keep reporting with the app in the background | Reporting stops when the app isn't on screen |
| Notifications | The persistent "you are live" notice | Android may not let the service run |
| Battery optimisation off *(recommended)* | Stops the phone killing the service | Reporting is interrupted; the watchdog recovers it slowly |
| Autostart *(some brands)* | Lets the service be restarted after a kill | Reporting may not recover until the app is opened |

**Ops note:** on Xiaomi, Oppo, Vivo and Realme phones, "autostart" and "no
battery restrictions" must be enabled manually per app. This is the single
biggest cause of riders silently dropping offline, and no amount of app code can
work around it — it is worth putting in rider onboarding material.

---

## 8. Known limits

| Limit | Status |
|---|---|
| Rider force-stops the app from Settings | **Cannot be recovered.** Android blocks all restarts by design until the app is opened. |
| iPhone, app killed | **Not supported.** iOS has no equivalent background mechanism. Reporting covers foreground and background only. |
| Brand-specific battery managers | Mitigated by the watchdog; fully solved only by the rider allowing autostart. |
| Aeroplane mode / no data | Positions are not queued while offline; reporting resumes on reconnect. |

---

## 9. Summary for a status update

> While a rider is live, their location is sent to the server every 30 seconds —
> whether the app is open, in the background, or closed. Five layers keep that
> running: an in-app timer, a foreground service, an Android background service,
> a 15-minute watchdog that restarts it after a phone kills it, and a boot
> listener for restarts. Nothing is ever sent when a rider is offline. The two
> cases we cannot cover are a rider force-stopping the app, and iPhones with the
> app fully closed — both are platform restrictions rather than gaps in the
> implementation.
