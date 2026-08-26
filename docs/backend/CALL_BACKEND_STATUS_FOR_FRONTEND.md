# Calls — backend status (rev 3): everything you asked for is built

**Reply to:** `CALL_NOTIFICATION_REQUIREMENTS.md`
**Supersedes:** rev 2
**Status:** implemented on `prod-staging` working trees, **not yet committed or
deployed** — review the diff before it ships.

Your §1 and §2 asks are done, and all four decisions in your §3 are implemented.
One extra section at the end, §7, is the UI spec for the busy-call flow.

| Your item | Status |
|---|---|
| §1 `call_ended` push | ✅ **Built** — all four `end_reason` values, silent, own channel |
| §1 `call_status: "network_error"` + "Call disconnected" | ✅ **Built** — enum widened, both teardown paths |
| §2 400 vs 404 stay distinguishable, ended-call carries `call_id` | ✅ **Built** — plus typed `code` on both |
| §3 drop the 2000 ms cancel suppression | ✅ **Removed** |
| §3 ring window → 30 s | ✅ **Changed** (was 20 s) |
| §3 `connected_at` on accept + `call:accepted` | ✅ **Built** — not on `call:answer`, per your decision |
| §3 device-aware `call/active` | ⏸ deferred with §1's reshape, as you asked |

**One bug found while doing this — see §6.** `call_status: "busy"` was already
being written by `call/decline` but was **not in the chat schema's enum**. It
survived only because the gRPC bridge updates without validators; any later
`.save()` on that message would have thrown. Fixed in the same change.

---

## 1. `call_ended` — the new push

Fires when a call that was **answered** ends, on both teardown paths:
a normal hang-up (`POST call/end`) and the 10 s network-drop timeout.

```jsonc
{
  "operation": "call_ended",
  "data": {
    "call_id": "…", "room_id": "…", "conversation_id": "…", "message_id": "…",
    "call_type": "audio_call" | "video_call",
    "is_group": false,
    "end_reason": "completed" | "network_error",
    "duration_seconds": 143,
    "title": "Call ended",
    "message": "Voice call ended · 2:23",     // or "Voice call disconnected"
    "ttl_seconds": 30
  },
  "callerData": { /* the §7 shape, unchanged */ }
}
```

Same envelope as everything else: `data.payload = JSON.stringify(data)`, so your
existing `payload.call_id` read works untouched.

**Sent to both participants, and each receipt names the other person.** For a
1-to-1 call it is published twice with the sender swapped, so A's notification
reads *"Call with Bhupinder"* and B's reads *"Call with Anjali"*. Group calls name
the initiator. `callerData` is therefore the **other party**, not always the caller.

**It is deliberately the quietest notification in the system:**

| | |
|---|---|
| Android channel | `call_updates` — **new**, importance `low` |
| Sound | none (no `sound` key at all) |
| Priority | `normal` (Android) / `apns-priority: 5` (iOS) |
| `fullScreenIntent` | no |
| APNs `category` | **none** — a call category would put CallKit affordances on a dead call |
| VoIP / PushKit | **never** — see the note below |
| Mutable | **yes**, under the `chat` preference category |

> **Why it is not in `CALL_OPERATIONS`.** That set also switches on the iOS
> VoIP/PushKit path, gated on `isCallOp && hasRealCall`. `call_ended` carries a
> real `call_id`, so adding it there would have rung a CallKit incoming-call UI
> for a call that had just finished. It is in a new `DEDUPED_OPERATIONS` set
> instead, which gives it Kafka retry-dedupe without the ring.

**All four `end_reason` values are emitted**, and the audience differs by design:

| `end_reason` | Fires on | Sent to | `duration_seconds` |
|---|---|---|---|
| `completed` | `POST call/end` | both participants | real duration |
| `network_error` | the 10 s disconnect teardown | both participants | duration up to the drop |
| `declined` | `POST call/decline` | **the caller only** | `0` |
| `busy` | `POST call/decline` with `reason: "busy"` | **the caller only** | `0` |

**Why decline notifies only one side.** The person who pressed Decline performed
the action deliberately — a "call ended" banner for something you just did reads
as a bug. The caller is the one who needs telling, and until now got nothing at
all: **no push of any kind was published on the decline path**, so a caller whose
app had been killed simply watched the call go silent with nothing to tap. That
was a real hole and your enum closed it.

Titles differ so the notification is readable without opening it: *"Call
declined"*, *"User was busy"*, *"Call ended"*.

**Dedupe fix that came with it.** The producer's `dedupe_key` was
`${call_id}:${operation}` — with two `call_ended` publishes per call, the
notification service's 60 s window swallowed the second one and only one of the
two people got a receipt. The key now includes the sorted receiver set, so
retry-dedupe still works and legitimate second publishes get through.

---

## 2. Dead-call responses — now typed, and they carry `call_id`

`POST call/accept`, unchanged status codes, richer bodies:

```jsonc
// 404 — no such call
{ "success": false, "code": "CALL_NOT_FOUND", "message": "Call not found",
  "call_id": "<the id you sent>" }

// 400 — the call existed and is over
{ "success": false, "code": "CALL_NO_LONGER_ACTIVE",
  "message": "Call is no longer active",
  "call_id": "…", "status": "ended", "end_reason": "completed" }
```

The two stay distinct, as you asked. `call_id` is echoed on both so a
cold-booted process can match the refusal to the notification that launched it
rather than guessing. `end_reason` is a bonus — it tells you *why* the call is
gone, which is the difference between "they hung up" and "you were too slow".

---

## 3. `connected_at`

Places 1 and 2 only, per your decision. Nothing was wired into `call:answer`.

```jsonc
// POST call/accept — response
{ "success": true, "ice_servers": { … }, "connected_at": 1756118220000, "call": { … } }

// socket call:accepted
{ "call_id": "…", "room_id": "…", "accepted_by": "…",
  "connected_at": 1756118220000, "metadata": null }
```

Epoch **milliseconds**, server clock, taken from the same `started_at` the
call-log duration is computed from — so both ends now agree. `null` for a call
that somehow has no `started_at`; keep your local anchor as the fallback.

Place 4 (`GET call/active`) still waits for that endpoint's reshape.

---

## 4. Ring window is now 30 seconds

`RINGING_TIMEOUT_MS` 20 s → **30 s**, and the Redis `RINGING_TTL` 20 s → 30 s to
match (an expired ringing key meant a receiver coming back online mid-ring had
nothing to recover from). The sweeper polls every 5 s, so a call is actually
missed at **30–35 s**. Your UI, your copy and the push TTL now agree with the
server.

---

## 5. The cancel-race suppression is gone

The 2000 ms skip in `call/cancel` is deleted. A `missed_call` push now goes out
**every** time the caller cancels, including inside the accept → app-launch
window. Your `call_id` de-duplication is what absorbs the flicker on a warm
device, exactly as you proposed.

---

## 6. Dropped calls in the chat bubble — and a latent bug

**Your decision implemented:** a call torn down by the network-drop path now
writes `call_status: "network_error"` with the text **"Call disconnected"**, on
both the message and the conversation preview. A normal hang-up is unchanged —
`"completed"` / `"Call ended - 2:23"`.

Both paths were fixed: `POST call/end` with `end_reason: "network_error"`, and
the server-side 10 s disconnect teardown, which previously wrote
`"completed"` / *"Call ended - 0:00"* for every dropped call.

**The bug.** Widening the enum in `message.schema.js` exposed that
`call_status: "busy"` — written by `call/decline` since the busy-signal work —
was **never in the enum**. It only ever persisted because the gRPC bridge uses
`findByIdAndUpdate` without validators; any code path that later loaded that
message and called `.save()` would have thrown a ValidationError on it. Both
`"network_error"` and `"busy"` are now declared.

So the enum your bubble can receive is:

```
ringing · connecting · completed · missed · declined · network_error · busy · failed · null
```

---

## 7. Busy calls — do not show an error, show the call UI

This is the UI spec for the flow you raised. **A busy callee is a call outcome,
not a request failure**, and it must never surface as a toast, snackbar or
dialog. The caller taps Call, gets a call screen, and the call screen tells them
what happened — the same way a phone does.

### 7.1 Two paths that must look identical

| Path | When | What arrives |
|---|---|---|
| **A — pre-flight** | the server already knows the callee is on a call | `POST call/initiate` → **409** `code: "RECEIVER_BUSY"` |
| **B — race** | both calls start at once; the callee's app auto-declines the second | call goes out, then `call:ringing` → `{ state: "busy", reason: "receiver_busy" }` |

The caller cannot tell these apart and should not be able to. **Both render the
same screen.** Path B already lands in the call UI; path A is the one that
currently shows an error, and that is the change.

The 409 now carries everything path B does:

```jsonc
{ "success": false, "code": "RECEIVER_BUSY", "message": "User is on another call",
  "busy": true, "reason": "receiver_busy",
  "busy_users": ["user_123"], "target_user_id": "user_123" }
```

### 7.2 The sequence

```
t = 0        user taps Call
             → push OutgoingCallScreen IMMEDIATELY (name, avatar, "Calling…")
             → start the ring-back tone
             → the network request has not returned yet, and that is fine

t ≈ 0.3 s    409 RECEIVER_BUSY arrives
             → DO NOT pop the screen
             → hold "Calling…" until a minimum dwell of 700 ms has passed

t = 0.7 s    → cross-fade the status line to "Anjali is on another call"
             → stop ring-back, start the busy tone
             → surface [ Call again ] and [ Message ]

t = 2.7 s    → busy tone ends → auto-dismiss back to the chat
             (unless the user has touched the screen — then it stays)
```

**The 700 ms minimum dwell is the whole trick.** A 409 can return in 200 ms; if
you switch the moment it lands, the screen flashes and reads as a crash. Holding
"Calling…" briefly makes it read as a call that was placed and answered by a busy
line — which is exactly what happened.

### 7.3 The screen

```
┌──────────────────────────────────────┐
│                                      │
│              ( avatar )              │
│                                      │
│           Anjali Thakur              │
│                                      │
│      ● Anjali is on another call     │   ← was "Calling…" 700 ms ago
│                                      │
│         ♪ busy tone (2 s)            │
│                                      │
│   [ Call again ]      [ Message ]    │
│                                      │
│                 ✕                    │
└──────────────────────────────────────┘
```

- Status line uses the **name** when you have it (`caller_info.name` from the
  conversation), falling back to *"User is busy"* — the existing
  `CallRingingState.busy` label.
- **Do not turn the screen red or show a warning icon.** Busy is a normal
  outcome. Neutral surface, muted status colour.
- **Do not vibrate.** The user is holding the phone and looking at it.
- `Call again` re-fires `initiate`; a second busy just replays this screen.
- `Message` drops straight into the conversation — usually what the caller
  actually wants.

### 7.4 `CALLER_ALREADY_IN_CALL` is a different screen

`POST call/initiate` also returns 409 when **you** are the one already on a call.
That is not a busy callee and must not look like one:

```jsonc
{ "success": false, "code": "CALLER_ALREADY_IN_CALL",
  "message": "You are already in a call", "room_id": "room_51a…" }
```

**Never open an outgoing-call screen for this.** Show an inline prompt —
*"You're already on a call"* with **[ Return to call ]** — and use the returned
`room_id` to restore the live call. Rendering "User is busy" here blames the
wrong person, which is why these two 409s now carry different codes instead of
different message strings.

### 7.5 Group calls

`initiate` does **not** fail when some invitees are busy — it filters them out
and rings the rest, returning `busy_users` in the 200 response. The
caller-facing `call:ringing` then carries a per-participant list with
`state: "busy"`. Render those as a muted **"busy"** chip next to the person in
the participant list; do not treat the call as failed.

### 7.6 One thing to know

A **path A** busy produces **no call record and no chat bubble** — the call was
refused before anything was created, so nothing appears in call history. A
**path B** busy does create one, logged as `end_reason: "busy"` with the bubble
*"User is busy"*. If you want path A to leave a history entry too, that is a
backend change and we should discuss whether an un-placed call belongs in
history at all.

---

## 8. Files changed

**be_call_service**

| File | Change |
|---|---|
| `src/controllers/call.controller.js` | `sendCallEndedNotification()` helper; wired into `endCall`, `handleCallDisconnect` and `declineCall` (caller-only); `connected_at` on accept + `call:accepted`; typed codes on the two 409s and the accept 400/404; `network_error` bubble copy; cancel-race suppression removed |
| `src/utils/notificationHelper.js` | `dedupe_key` now includes the receiver set |
| `src/utils/ringingTimeout.js` | ring window 20 s → 30 s |
| `src/utils/callStateManager.js` | `RINGING_TTL` 20 s → 30 s |

**be_notification_service**

| File | Change |
|---|---|
| `src/utils/firebaseNotification.js` | `call_ended` FCM config (silent, low priority); `call_updates` channel; APNs alert copy; `callerData` for `call_ended` |
| `src/utils/consumer.js` | `DEDUPED_OPERATIONS` so `call_ended` dedupes **without** entering the VoIP path |
| `src/utils/notificationCategories.js` | `call_ended` under `chat`, deliberately **not** a bypass operation |
| `public/notification-templates.json` | `call_ended` template |
| `public/in-app-notifications.json` | `call_ended` in-app entry |

**be_chat_service**

| File | Change |
|---|---|
| `src/models/schema/message.schema.js` | `call_status` enum + `network_error`, + `busy` |

All files parse clean. The notification service's jest suite could not be run
here — `jest` is not installed in that repo — so these changes are **unverified
by tests**; the `call_ended` path wants one manual round-trip on staging before
it ships.

---

## 9. Still open

| Item | Status |
|---|---|
| `GET call/active` rich response (rev 2 §1) | not started — `i_am_caller`, `peer.*`, `ice_servers`, `metadata`, `connected_at`, and "ringing counts as active" |
| Device-aware `call/active` | deferred with the above, per your decision |
| `call_cancelled` operation | not adding it — you confirmed `missed_call` is enough |
| `connected_at` on `call:answer` | not adding it — you confirmed places 1, 2, 4 are enough |
