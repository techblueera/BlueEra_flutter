# Call signalling — required backend support

**Service:** call service (`call.beapp.in`)
**Status:** NOT IMPLEMENTED server-side. The app changes are done and shipped
behind additive fields, so nothing here breaks if you deploy later.

Two independent changes, both driven by app-side fixes:

| § | Change | App side | Backend needed? |
|---|---|---|---|
| 1–4 | **Network-drop timeout** (10s) | `CallController._onTransportLost` / `_abandonCallForNetwork` | **Yes** — participant-drop timeout, else call logs stay open |
| 5 | **Busy signal** | `CallController._rejectAsBusy` | **Yes** — honour `reason: "busy"` on decline |

---

## 0. Why the client alone is not enough

The app now tears a call down after **10 seconds** without a working transport,
on whichever side notices. That fixes the common case, but it cannot fix all of
them, because **a device with no internet cannot tell the server anything.**

Concretely, the app's teardown POST to `call/end` is issued while the device is
still offline. It will usually fail. So:

| scenario | who notices | covered by the app? |
|---|---|---|
| A loses Wi-Fi, app alive | A (connectivity), B (ICE disconnect) | ✅ both sides |
| A's app is force-killed | B (ICE disconnect) | ✅ B tears down |
| A loses network AND stays offline | A locally only | ⚠️ **B relies on ICE alone** |
| A's device dies / airplane mode mid-call | B (ICE disconnect) | ✅ B tears down |
| Either — **server-side call log** | nobody reaches the server | ❌ **needs server** |

The last row is the one that needs you: when both participants drop off without
a successful `call/end`, the call record stays open forever and the call log is
wrong for both users.

---

## 1. What the app now sends

### `POST call/end` — new optional field

```json
{
  "call_id":    "...",
  "room_id":    "...",
  "end_reason": "network_error"
}
```

`end_reason` is **new and optional**. It is sent only when the call was
terminated by the connectivity grace period, never on a normal hang-up.
Existing behaviour is unchanged when it is absent.

Please persist it on the call record so the log can distinguish "ended" from
"dropped". Unknown-field tolerance means the app can ship this before you do.

### `call:leave-room` — new optional field

```json
{ "room_id": "...", "call_id": "...", "reason": "network_error" }
```

Same story: additive, best-effort, and it will frequently NOT arrive because the
sender is offline. **Do not rely on it.**

---

## 2. What the server needs to do

### 2.1 Participant-drop timeout (the important one)

When a participant's socket disconnects from an active call room and does **not**
rejoin within **10 seconds**:

1. mark the call ended, `end_reason: "network_error"`
2. emit `call:ended` to every remaining participant, with the same reason
3. write the call log entry with the real duration up to the drop

This is what stops the other party being stranded, and it is the only mechanism
that works when the dropped device never comes back. Keep the window at 10s so
the server and the app agree — a shorter server window kills recoverable calls,
a longer one leaves the app's own timeout to fire first and the two logs disagree.

### 2.2 Tolerate a late / duplicate `call/end`

A recovering client may send `call/end` for a call the server already closed on
timeout. That must be idempotent — return success, do not create a second log
entry, do not error.

### 2.3 Do not bill / count a dropped call as answered

If `end_reason == "network_error"` and the connected duration is ~0, the call
should log as dropped, not as a completed call.

---

## 3. What the app does today (for reference)

- Connectivity is watched for the whole life of a call, from the first ring —
  driven off `callStatus`, so it covers ringing, outgoing, connecting and
  connected.
- **Ringing / outgoing + transport lost** → abandoned immediately. There is no
  media path to resume and no way to reach the server to accept, so the incoming
  UI is dismissed with "Call ended — no internet connection" instead of being
  left on screen over a dead connection.
- **Connected + transport lost** → 10s grace. The screen shows "Reconnecting…".
  If it comes back, the call continues and the socket is reconnected. If it does
  not, the call is torn down with "Call ended — connection lost".
- **Peer ICE `disconnected`** → same 10s grace, then teardown. Previously this
  did nothing at all, which is how the far end was left in a ghost call with a
  running timer and no audio.

---

## 5. Busy signal — callee is already on a call

### The problem

When B is already on a call and A rings them, B's app used to drop the incoming
`call:incoming` on the floor:

```dart
if (callStatus.value != CallStatus.idle) return;   // silent
```

The server therefore never learned B was busy. A rang for the **full 30-second**
timeout and was then told **"No answer"** — when the truthful answer, *"user is
busy"*, was available the instant the second call arrived.

### What the app now sends

B's app immediately declines the SECOND call with a reason:

```
POST call/decline
{
  "call_id": "<the NEW call>",
  "room_id": "<the NEW call>",
  "reason":  "busy"
}
```

`reason` is **new and optional**. It is sent only for this auto-reject, never
for a user-initiated decline.

### What the server needs to do

Relay it to the caller as the **`busy`** ringing state, not `declined`:

```
call:ringing → { "state": "busy", ... }
```

The app already models this end-to-end and needs no further change:
`CallRingingState.fromServer("busy")` → `CallRingingState.busy` → label
**"User is busy"** → `isTerminal == true`, so the caller's outgoing screen shows
the reason and auto-dismisses after 2s instead of ringing out.

Please also log the call as **busy/rejected**, not as a missed call — B never
had the chance to answer it.

### Degradation if you do nothing

The decline itself still works, so A stops ringing immediately and sees
**"Call declined"** instead of **"User is busy"**. Wrong word, right timing —
still far better than the 30-second wait. So this is a correctness improvement,
not a blocker.

### Already working: the 409 path

`POST call/initiate` returning **409** is already handled — the caller shows
"User is busy on another call" and marks the ringing state busy locally. That
covers the case where the server *already knows* B is engaged. §5 covers the
case where it does not: a race between two calls, or B being on a call the
server has not marked busy.

---

## 6. Open question for the backend team

Is there an existing heartbeat / presence signal on the call room we should use
instead of raw socket disconnect? A socket can drop and reconnect on a healthy
network (transport upgrade, brief cell handover), and treating every drop as a
participant loss would end calls that were fine. If presence already exists,
the 10s timer should hang off that rather than off `disconnect`.
