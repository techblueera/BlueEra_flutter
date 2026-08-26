# Calls — what the app still needs from the backend

**Reply to:** `CALL_BACKEND_STATUS_FOR_FRONTEND.md` (rev 2)
**Scope:** only the items that block or worsen the four live bugs below. Everything
else in rev 2 is accepted as-is.

Four bugs were reported from the field. Three are ours and are fixed client-side;
the fourth needs one new push. This document is the whole backend ask — there is
nothing else outstanding from this round.

| # | Bug | Owner | Needs backend? |
|---|---|---|---|
| 1 | Decline button dead + subsequent calls auto-rejected | app | **No** — fixed |
| 2 | Black screen after tapping a notification for an ended call | app | **Partly — §2** |
| 3 | Ringing notification can be swiped away | app | **No** — fixed |
| 4 | "Call Ended" notification should open Call History | app | **Yes — §1** |

---

## §1 — Please add a `call_ended` push (blocks bug 4)

**What we need:** a terminal push when a call the user was *on* finishes, so tapping
it can open Call History.

Today the only terminal operations are `missed_call` and (per rev 2 §4.1)
`broadcast_ride_request` / `fare_ride_incoming_call`. There is **no** notification
for a call that was answered and then ended, so "tap the Call Ended notification"
has nothing to tap. We have wired the client for `call_ended` already — it is inert
until you send it.

```jsonc
{
  "operation": "call_ended",
  "call_id": "…",
  "conversation_id": "…",
  "call_type": "audio_call" | "video_call",
  "end_reason": "completed" | "network_error" | "declined" | "busy",
  "duration_seconds": 143,
  "callerData": { /* the §7 shape, unchanged */ }
}
```

- Same `data.payload = JSON.stringify(data)` envelope as the rest — our handler
  already reads `payload.call_id` (rev 2 §4).
- Low importance. This is a receipt, not an alert: **no** sound, **no**
  `fullScreenIntent`, **no** `category: call`.
- Send it to **both** participants.
- `ttl_seconds`: short (30 is fine). A call-ended receipt arriving ten minutes late
  is noise.

**Also confirms rev 2 §6.3, which you asked us to decide:** use
`call_status: "network_error"` on the chat bubble for a dropped call, with the copy
**"Call disconnected"**. `"completed"` for everything else, as today. That unblocks
the one-line enum change in `message.schema.js:213-225`.

---

## §2 — `POST call/accept` on a dead call: please keep 404 and 400 distinguishable

**Related to bug 2 (black screen).**

Rev 2 §4.3 told us an *ended* call returns `400 "Call is no longer active"` while a
*missing* one returns `404`. We now treat both as "call is gone" — that part is
handled.

The remaining ask is only that these stay **distinguishable and stable**, because
the black screen happens when the app launches a call UI for a call that is already
over. Our recovery path is: launch → `GET call/active` → nothing → close. That is
only reliable while a dead call gives a *fast, unambiguous* answer.

Concretely:

- Do **not** collapse 400 and 404 into one code — we log them differently.
- Please make sure the ended-call response carries `call_id`, so we can match it to
  the notification that launched us rather than guessing.

No new endpoint needed.

---

## §3 — Decisions you asked for in rev 2

Answering all four so nothing is left open on your side:

| rev 2 item | Our decision |
|---|---|
| §4.2 — cancel-race suppression vs guaranteed terminal push | **Guarantee the push.** Drop the 2000ms suppression. A cold-booting device silently missing the cancel is worse than a brief banner flicker on a warm one; we de-duplicate on `call_id` client-side. |
| §6.3 — dropped-call `call_status` + copy | `"network_error"` / **"Call disconnected"** (see §1). |
| §3 — `connected_at` on `call:answer`? | **Not needed.** Places 1, 2 and 4 are enough — do not wire a call-record lookup into the chat service's signalling path. |
| §11 — ring window 20s or 30s | **Align on 30s.** Our UI, our copy and the push TTL all assume 30; 20s reads as "they hung up on me". One-line change on your side per your note. |
| open #4 — device-aware `call/active` | **Yes, when §1 is reshaped** — not before. `call:answered-elsewhere` covers us in the meantime. |

---

## §4 — Already actioned on our side, listed so you can close them out

- **`fare_ride_incoming_call`** is now accepted alongside `incoming_call` in the push
  handler (rev 2 §7). It was being dropped on terminated devices; it is not any more.
- **`400 "Call is no longer active"`** is treated identically to `404`.
- **`call_cancelled` is not relied on.** We treat `missed_call` as the cancel signal,
  per rev 2 §4.1. No need to add the second operation.
- **`response.call.started_at`** from `POST call/accept` is our clock anchor (rev 2 §3).
- **Fallback chain trimmed** to `caller_info.name` / `callerData.name` only, with one
  guard for a missing `caller_info` (rev 2 §7).

---

## Not a backend issue — recorded so it is not re-filed

**Bug 3, the swipe-away ringing notification — fixed on our side.** Android 14 made
ongoing notifications user-dismissible, and `targetSdkVersion` here is 36, so
`ongoing: true` was no longer enough. We now post the ring as a `CallStyle`
notification from a `phoneCall` foreground service, which is the one combination
the platform still refuses to let a user swipe away. The heads-up banner can
still be pushed aside — that is the platform behaviour and matches the expected
behaviour as reported — while the status-bar entry survives until the call stops
ringing. Nothing for you.

**Bug 1, the decline loop.** Root-caused to two client defects: the notification's
Decline action called into the controller without the call ids, so a backgrounded
app declined nothing; and a failed decline request skipped the state reset, leaving
the client permanently "busy" and auto-rejecting every later call with `reason:
"busy"`. If you saw a spike of instant busy-declines, that was us. Both fixed.
