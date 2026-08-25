# Calls — backend requirements, and where each one stands

**Service:** call service (`call.beapp.in`) + the notification service that builds the FCM message
**Thread:** frontend asks → backend reply (`CALL_BACKEND_STATUS_FOR_FRONTEND.md`, verified
line by line against `be_call_service` on `prod-staging`) → this document.

This is the single source of truth. It absorbed the old
`CALL_SIGNALLING_BACKEND_UPDATES.md`, whose asks are items 2, 5 and 6 — all now
built.

## Status

| # | Item | Status |
|---|---|---|
| 2 | Participant-drop timeout (10s) | ✅ **Done** — live on `prod-staging` |
| 5 | `reason: "busy"` on decline | ✅ **Done** |
| 6 | `end_reason` + idempotent `call/end` | ✅ **Done** (one gap: the chat bubble — §6) |
| 7 | One shape for caller name / image | ✅ **Done** — both channels already send it (§7) |
| 8 | TTL on the `incoming_call` push | ➖ Closed — handled client-side, other service anyway |
| 1 | `GET call/active` restorable | ⬜ **Open** — endpoint exists, response too thin (§1) |
| 3 | `connected_at` | ⬜ **Open** — small; the value already exists as `started_at` (§3) |
| 4 | Terminal push to terminated devices | ⬜ **Open** — needs the decision in §4 |

**Nothing is blocked on us.** Everything the client can do without the server is
shipped (§9), including the two workarounds that make §4 safe to change.

---

## ⬜ 1. `GET call/active` — widen the response

Confirmed as a delta, not a new endpoint. Today it returns the Redis
active-call hash plus room and participants; `{ "active_call": null }` with `200`
when nothing is live is already the shape we wanted.

**Still missing from the §1 contract:** `i_am_caller`, `peer.name`,
`peer.profile_image`, `connected_at`, `ice_servers`, `metadata`.

Without `ice_servers` in particular the response cannot rebuild a call, which is
why the client still does not consume this endpoint.

```json
{
  "active_call": {
    "call_id": "…", "room_id": "…", "conversation_id": "…",
    "call_type": "audio_call", "is_group_call": false,
    "status": "connected", "initiated_by": "user_123", "i_am_caller": false,
    "peer": { "user_id": "…", "name": "…", "profile_image": "…" },
    "connected_at": 1756118220000,
    "ice_servers": { "iceServers": [ { "urls": "…" } ] },
    "metadata": null
  }
}
```

Two things to fix along with the shape:

1. **A ringing receiver currently gets `null`.** `user_active_call:{userId}` is
   written on initiate / accept / join, never while merely being rung — so a
   receiver killed while the phone was ringing cannot recover the incoming call.
   That is the case this endpoint matters most for.
2. **Send real JSON types.** The Redis hash stringifies everything, so
   `is_group_call` comes back as `"false"`. Please cast on the way out rather
   than making every client parse defensively.

---

## ⬜ 3. `connected_at` — expose the value that already exists

Confirmed: `call/accept` already stamps `started_at` on the call record at the
moment the accept succeeds — exactly the definition we proposed. So this is
exposing an existing value, not computing a new one.

Return it as **epoch milliseconds** in four places:

1. `POST call/accept` response — currently `{ success, ice_servers, call }`
2. socket `call:accepted` — currently `{ call_id, room_id, accepted_by, metadata }`
3. socket `call:answer`
4. `GET call/active` (§1)

The client keeps its local wall-clock anchor until this lands, so the timer is
already accurate on each device — what is missing is the two ends *agreeing*,
and having something to restore a timer from after a process kill.

---

## ⬜ 4. Terminal push — one decision needed

**What works:** `missed_call` is published on both caller-cancel and ring
timeout. `POST call/accept` returns `404` for a call that no longer exists.

### 4.1 `call_cancelled` is never sent — no change needed on your side

Our handler already keys on `missed_call` **or** `call_cancelled`, and both
cancel the ringing notification by `call_id`. `missed_call` alone works today.
Add the second operation only if it is useful to you; we do not need it.

### 4.2 The 2-second cancel suppression — **please remove it**

This is the decision you asked us for.

> *"Suppress the flicker, or guarantee the cancel reaches a cold-booting
> device."*

**Guarantee the cancel.** Send it always, including inside the first 2 seconds.

The flicker was a real symptom of a real problem — the cancel overtaking the
incoming banner — but suppressing the *cancel* fixes the flicker by
guaranteeing the worse outcome: a phone that rings, full screen, for a call
nobody is on, on exactly the cold-boot path that is hardest for a user to
escape.

**We have taken the ordering problem onto the client.** Every path that retires
an incoming call now writes a tombstone (`markCallRetired`, in shared storage so
the FCM background isolate and the app isolate see the same record, pruned after
5 minutes). Both ring paths — the Android full-screen notification and iOS
CallKit — refuse to show a call whose id is tombstoned. So a cancel that arrives
*before* the incoming push no longer causes a pop-and-replace flicker: the
incoming push is simply never shown.

That guard is shipped. Removing the suppression is safe as soon as you deploy.

### 4.3 A call that ended returns `400`, not `404` — fixed on our side

Thanks for flagging this; it was a live bug. The accept path keyed on 404 alone,
so an ended call surfaced as a raw error toast instead of "Call is no longer
available". It now treats **400 with a "no longer active" message** the same as
404. No change needed from you.

---

## ⬜ 6. The dropped-call chat bubble — our answer

> *"Fixing it needs a new value in the chat service's `call_status` enum, which
> changes what your bubble renders — tell us which you want."*

**Add `call_status: "dropped"`**, and keep `call_time` populated with the real
connected duration.

The bubble will read **"Call dropped • 02:14"**, with the normal connected-call
icon rather than the red missed-call arrow — the call happened, the line died.
"Call ended - 0:00" is the misleading part, not the wording.

**Ship it whenever you like — the client is already safe either way.** The
renderer handles `"dropped"` today, and any `call_status` it does not recognise
falls through to the server's own message text rather than breaking. Use
`network_error` on the call record as the trigger.

---

## ✅ 7. Caller name / image — resolved, with two fallbacks kept

Both channels already send the shape we asked for. Two changes on our side:

- **Business callers now ring with the business name and logo on the push too.**
  `caller_info.name` already prefers the business name on the socket, so the same
  call used to ring as "David Retail Mart" over the socket and as the staff
  member's own name over FCM. The push path now prefers
  `callerData.businessData.business_name` / `.logo` for `account_type: BUSINESS`,
  which makes the two agree. This is the spot-check you flagged — worth one test
  with a business account on your side too.
- **We are keeping the fallback chains** rather than trimming them, for the two
  reasons you gave: `caller_info` is omitted entirely when the gRPC lookup fails,
  and which name lands in `callerData.name` for a business caller is not yet
  confirmed by a live test. They cost nothing and they are the difference
  between a name and "Incoming Call". We will trim them once a business call has
  been observed end to end on both channels.

---

## Open question 4 — device-aware `call/active`

**Yes, make it device-aware, and do it while §1 is being reshaped** — threading a
device id through the call session afterwards is the more expensive order.

Semantics we would build against: `call/active` returns the call **only to the
device that is a participant in the media session** (the one that initiated,
accepted or joined). Every other signed-in device gets `null`, matching what
`call:answered-elsewhere` already tells them over the socket.

We do not send a device identifier to the call service today — only
`X-Device-Type` and `X-Device-OS`. Name the header you want (`X-Device-Id`, a
stable per-install id) and have `initiate` / `accept` / `join` record it on the
session; attaching it to every call-service request is a one-line change on our
side.

---

## 9. What is already handled client-side

So nobody builds these twice:

| Fix | Detail |
|---|---|
| Call timer no longer loses seconds | Duration derived from a wall-clock anchor instead of counted ticks — Android throttles timers for a backgrounded process, so every skipped tick was a lost second. |
| Late pushes dropped | An `incoming_call` push whose server-stamped `sentTime` is older than 45s is ignored, in both the foreground and background handlers. This is why §8 is closed. |
| Retired calls cannot ring | Tombstone written by every path that takes a call down; both ring paths check it. This is what makes §4.2 safe. |
| 400 handled as "call is gone" | §4.3. |
| Business caller name / logo on the push | §7. |
| `dropped` bubble | §6 — renders as soon as you send it. |
| Stale ongoing-call record | Cleared on every cold start, so a force-kill mid-call cannot leave a phantom "Live call ongoing" banner. |
| Killed-state accept lands in the app | Splash boots normally for a call launch and re-opens the call room on top of the home shell, instead of leaving the call as the only page. |

---

## 10. What we are waiting on, in priority order

1. **§1** — widen `GET call/active` (+ ringing receivers, + real JSON types).
   This is the only item no client work can substitute for: a killed process has
   no socket, no WebRTC session and no memory of the call.
2. **§4.2** — remove the 2s cancel suppression. Our guard is already deployed.
3. **§3** — expose `started_at` as `connected_at` in the four places above.
4. **§6** — add `call_status: "dropped"`.
5. **Open 4** — name the device-id header when §1 is reshaped.
