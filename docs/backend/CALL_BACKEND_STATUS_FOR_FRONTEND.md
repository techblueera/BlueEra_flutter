# Calls — backend status, item by item

**Reply to:** `CALL_BACKEND_REQUIREMENTS.md`
**Verified against:** `be_call_service` on `prod-staging`, read line by line — not from memory.

**Headline: §2, §5 and §6 are already built and merged.** They were the whole of
the old `CALL_SIGNALLING_BACKEND_UPDATES.md`. If they look absent in testing,
check the deploy on `call.beapp.in` before filing anything — the code is on
`prod-staging`.

## Checklist status

| # | Item | Status |
|---|---|---|
| 1 | `GET call/active` restorable | ⚠️ **Endpoint exists, response is thin** |
| 2 | Participant-drop timeout (10s) | ✅ **Done** |
| 3 | `connected_at` | ❌ Not exposed — but the value exists |
| 4 | Terminal push to terminated devices | ⚠️ **Partly** — see below, one part works against you |
| 5 | `reason: "busy"` on decline | ✅ **Done** |
| 6 | `end_reason` + idempotent `call/end` | ✅ **Done** |
| 7 | One shape for caller name / image | ✅ **Both channels already send it** |
| 8 | TTL on `incoming_call` push | ❌ Not in this service |

---

## ✅ §2 — Participant-drop timeout: done

All three requirements are live:

- **10 seconds**, matching your client exactly (`index.js`, `DISCONNECT_GRACE_MS = 10000`).
- Marked `end_reason: "network_error"` on the call record.
- `call:ended` emitted to everyone remaining with `reason: "network_error"` and the real `duration_seconds`.

**Your open question #3 — yes, there is a presence signal, and it already drives this.**
The chat service publishes `call:user:disconnected` / `call:user:connected` over
Redis pub/sub. The timer starts on disconnect and is **cancelled the moment the
user reconnects**. A transport upgrade or cell handover will not end a healthy
call — the exact case you were worried about.

## ✅ §5 — Busy signal: done

`POST call/decline` reads your optional `reason`. When it is `"busy"`:

- the caller receives `call:ringing` with `state: "busy"`, `reason: "receiver_busy"`
- the call is recorded with `end_reason: "busy"`, not missed
- the chat entry reads **"User is busy"**

Nothing further needed from you — `CallRingingState.busy` will fire.

## ✅ §6 — `end_reason` + idempotency: done

- `POST call/end` accepts and persists your `end_reason`.
- A late or duplicate `call/end` for an already-ended call short-circuits: it
  returns success, writes no second entry, and **will not overwrite** a real
  `end_reason` such as `network_error` with `completed`.
- The call record distinguishes dropped from completed.

⚠️ One known gap on §6.3: the **chat bubble** for a dropped call still says
`call_status: "completed"` and *"Call ended - 0:00"*. The call record is correct;
the message text is not. Fixing it needs a new value in the chat service's
`call_status` enum, which changes what your bubble renders — tell us which you
want and we will do it together rather than guess.

---

## ⚠️ §1 — `GET call/active` exists, but returns too little

**Answer to your open question #1: yes it exists, and this is a delta, not a new endpoint.**

Today it returns the Redis active-call hash plus the room and participant list:

```json
{
  "success": true,
  "active_call": {
    "call_id": "…", "conversation_id": "…", "initiated_by": "…",
    "call_type": "audio_call", "status": "ringing", "is_group_call": "false",
    "room_id": "…", "participants": ["user_1", "user_2"]
  }
}
```

`{ "active_call": null }` with `200` when nothing is live — already the shape you asked for.

**Missing against your §1 contract:** `i_am_caller`, `peer.name`,
`peer.profile_image`, `connected_at`, `ice_servers`, `metadata`.

**One behavioural gap worth knowing:** a **ringing receiver gets `null`**. The
`user_active_call` key is written when a user *initiates*, *accepts* or *joins* —
never while merely being rung. So your §1 rule *"ringing counts as active"* is not
satisfied today: a receiver killed while the phone was ringing cannot recover the
incoming call. That is a separate fix from widening the response.

Note the Redis hash stringifies everything — `is_group_call` comes back as
`"false"`, not `false`. If you consume the endpoint before it is reshaped, parse
defensively.

## ❌ §3 — `connected_at` not exposed, but the value exists

**Answer to your open question #2: yes.** `call/accept` already stamps
`started_at` on the call record at the moment the accept succeeds — which is
exactly the definition you proposed. So §3 is *exposing an existing value*, not
computing a new one.

Not currently returned in any of the four places you listed: the `call/accept`
response returns `{ success, ice_servers, call }`, and `call:accepted` carries
`{ call_id, room_id, accepted_by, metadata }`.

Keep your local anchor until this ships.

## ⚠️ §4 — Terminal push: partly there, and one part works against you

**What works:** `missed_call` is published to the notification service on both
caller-cancel and ring-timeout. `POST call/accept` returns **404** for a call
that no longer exists, which is the behaviour you asked to keep.

**Three gaps:**

1. **`call_cancelled` is never sent.** Only `missed_call` exists. If your handler
   keys on `operation == "call_cancelled"`, it will never fire — treat
   `missed_call` as the cancel signal for now, or ask us to add the second
   operation.

2. **The cancel race is deliberately suppressed.** If the caller cancels within
   **2 seconds** of initiating, the push is skipped on purpose — the reasoning
   was that the incoming banner had not landed yet and replacing it caused a
   pop-and-replace flicker. That is precisely the accept → launch window in your
   §4, so for a very fast cancel a terminated device gets **no** terminal push.
   These two intentions are in direct conflict and it needs a joint decision:
   suppress the flicker, or guarantee the cancel reaches a cold-booting device.
   We would rather you pick.

3. **A call that has *ended* returns `400`, not `404`.** 404 is only for
   "call not found". If your "Call is no longer available" path keys on 404 alone,
   handle **400 with `message: "Call is no longer active"`** the same way.

## ✅ §7 — Both channels already send the shape you want

`call:incoming` carries `caller_info.name` and `caller_info.profile_image`,
resolved over gRPC, with the business name and logo preferred for business
accounts. That is the shape you asked for.

The **FCM** side already sends the shape you asked for too. The notification
service builds `data.callerData` for every call operation:

```json
{
  "id": "…", "name": "…", "profile_image": "…",
  "contact_no": "…", "account_type": "…", "username": "…",
  "businessData": { "business_name": "…", "logo": "…" }
}
```

So `callerData.name` and `callerData.profile_image` are both there. **You can drop
`data.senderName` and `callerData.username` from your fallback chain**, and all
six socket-side aliases.

Two caveats:

- On the socket side `caller_info` is **omitted entirely** when the gRPC lookup
  fails, rather than sent empty. Keep one fallback for a missing `caller_info`.
- For a **business caller**, `callerData.name` is the sender's own name while the
  business name sits separately under `callerData.businessData.business_name`.
  The notification service re-fetches the sender for call operations, so which of
  the two lands in `name` is worth one spot-check with a business account before
  you rely on it. `caller_info.name` on the socket already prefers the business
  name.

## ❌ §8 — TTL: not this service

`android.ttl` / `apns-expiration` are set where the FCM message is built, in the
notification service. Not something we can change here. You have already noted it
is belt-and-braces since the client drops pushes older than 45s.

---

## Your open question #4 — multi-device

**Today `call/active` would return the call on *both* devices.** The lookup key is
`user_active_call:{userId}` — per user, not per device — so the service cannot
tell the device that answered from the one that did not. `call:answered-elsewhere`
*is* emitted, so the socket path is correct; the REST endpoint simply has no
device identity to work with.

Making it per-device means threading a device id through the call session. Worth
deciding when §1 is reshaped, not after.

---

## Summary — what to build against

**Use now:** the §2 drop timeout, §5 busy state, §6 `end_reason` and idempotent
`call/end`. All live on `prod-staging`.

**Do not build against yet:** §1's rich response, §3's `connected_at`, §4's
`call_cancelled` operation.

**Needs a decision from you before we code it:**
- §4.2 — cancel-race suppression vs guaranteed terminal push
- §6.3 — what a dropped call should read as in the chat bubble
- open #4 — whether `call/active` should become device-aware
