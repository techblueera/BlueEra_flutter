# `call:ringing` — Flutter Integration Guide

Server-pushed event that reports the **callee's** state back to the **caller** during call setup, so the outgoing-call screen can show context-aware labels ("Dialing…", "Ringing…", "Connecting…", "Connected", …) instead of a generic "Calling…".

> **Additive only.** Every existing event (`call:incoming`, `call:accepted`, `call:declined`, `call:cancelled`, `call:ended`, `call:answered-elsewhere`, `call:offer`, `call:answer`, `call:ice-candidate`) continues to behave exactly as before. `call:ringing` is an extra stream the caller listens to.

---

## 1. Who listens

| Role | Listens to `call:ringing`? |
|---|---|
| Caller (initiator) | **Yes** — drives the outgoing-call screen label. |
| Callee (receiver) | No — keeps using `call:incoming` to show the incoming-call modal. |

The server only emits the event to `call.initiated_by`. Receivers will never see it.

---

## 2. State enum

| `state` value | UI label (suggestion) | Meaning | Terminal? |
|---|---|---|---|
| `dialing` | "Dialing…" | Callee has no active socket at initiate time — push notification sent. | No |
| `ringing` | "Ringing…" | Callee's device got `call:incoming` and is showing the incoming-call modal. | No |
| `connecting` | "Connecting…" | Callee tapped accept; WebRTC handshake is in progress. | No |
| `connected` | "Connected" | Callee's SDP answer reached the caller — media is flowing. | No (until `call:ended`) |
| `no_answer` | "No answer" | 20 s ringing timeout fired; call auto-missed. | **Yes** |
| `declined` | "Call declined" | Callee tapped decline. | **Yes** |
| `busy` | "User is busy" | Callee was already in another call at initiate time. | **Yes** |
| `cancelled` | "Cancelled" | Caller hung up before the callee accepted — server echoes this back. | **Yes** |
| `failed` | "Call failed" | Technical failure. Not emitted by the server — derived client-side from a 5xx on `/initiateCall`. | **Yes** |

### State transitions

```
           ┌─── dialing ────┐
           │                ▼
 initiate ─┤              ringing ──► connecting ──► connected ──► call:ended
           │                │
           └─── ringing ────┘
                            │
            terminals: no_answer | declined | busy | cancelled | failed
```

- `dialing → ringing` happens when the callee's socket comes back online within the 20 s window (server reconciles and upgrades automatically).
- `connected` is emitted by `be_chat_service` when it relays the callee's `call:answer` SDP — it's the closest proxy the server has for "media flowing".
- After any terminal state, show the label for ~2 s then close the outgoing-call screen.

---

## 3. Payload contract

**Event:** `call:ringing` (server → caller)

### 1-to-1 call

```json
{
  "call_id": "64f9d1e2b8c3a1f9e3a4b5c6",
  "room_id": "6a3b2c1d-0e4f-5a6b-7c8d-9e0f1a2b3c4d",
  "conversation_id": "64fa0011aabbccdd00112233",
  "target_user_id": "65a1c7f0b2d3e4f501020304",
  "state": "ringing",
  "reason": null,
  "is_group_call": false,
  "participants": null,
  "timestamp": "2026-04-22T12:04:33.812Z"
}
```

### Group call

For group calls `target_user_id` is `null` and the full snapshot is sent each time any single participant transitions — idempotent, so you can replace your local map wholesale.

```json
{
  "call_id": "64f9d1e2b8c3a1f9e3a4b5c6",
  "room_id": "6a3b2c1d-0e4f-5a6b-7c8d-9e0f1a2b3c4d",
  "conversation_id": "64fa0011aabbccdd00112233",
  "target_user_id": null,
  "state": "ringing",
  "reason": null,
  "is_group_call": true,
  "participants": [
    { "user_id": "u1", "state": "connected" },
    { "user_id": "u2", "state": "ringing" },
    { "user_id": "u3", "state": "declined", "reason": "user_declined" },
    { "user_id": "u4", "state": "dialing" }
  ],
  "timestamp": "2026-04-22T12:04:38.004Z"
}
```

### Field reference

| Field | Type | Description |
|---|---|---|
| `call_id` | string (ObjectId) | Call document ID. Same as returned by `POST /call/initiate`. |
| `room_id` | string (uuid) | WebRTC room ID. |
| `conversation_id` | string (ObjectId) | Chat conversation this call belongs to. |
| `target_user_id` | string \| null | For 1-to-1: the callee's ID. For group: `null` — see `participants`. |
| `state` | enum | See state table above. For group calls, this is the **aggregate** state (see §5). |
| `reason` | string \| null | Optional machine-readable code for terminal states (`user_declined`, `user_cancelled`, `ringing_timeout`). |
| `is_group_call` | boolean | Toggles which payload variant is in use. |
| `participants` | array \| null | Present only for group calls. Each entry has `user_id`, `state`, optional `reason`. |
| `timestamp` | ISO string | Server emit time. Useful for debouncing out-of-order messages. |

---

## 4. Required client change — include `call_id` in `call:answer`

To emit the `connected` state, the chat service needs `call_id` on the `call:answer` payload it relays. Today the Flutter client sends only `{ room_id, target_user_id, sdp }` — **add `call_id`**:

```dart
socket.emit('call:answer', {
  'room_id': roomId,
  'target_user_id': callerId,
  'sdp': answer.toMap(),
  'call_id': callId, //  ← new, required for `connected` to fire
});
```

If `call_id` is missing, everything else still works but the caller will never see `connected` — the UI will stay on `connecting` until the first real media event.

---

## 5. Dart reference implementation

### Enum + label map

```dart
enum CallRingingState {
  dialing,
  ringing,
  connecting,
  connected,
  noAnswer,
  declined,
  busy,
  failed,
  cancelled;

  static CallRingingState fromServer(String raw) {
    switch (raw) {
      case 'dialing':    return CallRingingState.dialing;
      case 'ringing':    return CallRingingState.ringing;
      case 'connecting': return CallRingingState.connecting;
      case 'connected':  return CallRingingState.connected;
      case 'no_answer':  return CallRingingState.noAnswer;
      case 'declined':   return CallRingingState.declined;
      case 'busy':       return CallRingingState.busy;
      case 'cancelled':  return CallRingingState.cancelled;
      default:           return CallRingingState.failed;
    }
  }

  bool get isTerminal => switch (this) {
    CallRingingState.noAnswer ||
    CallRingingState.declined ||
    CallRingingState.busy     ||
    CallRingingState.failed   ||
    CallRingingState.cancelled => true,
    _ => false,
  };

  String get label => switch (this) {
    CallRingingState.dialing    => 'Dialing…',
    CallRingingState.ringing    => 'Ringing…',
    CallRingingState.connecting => 'Connecting…',
    CallRingingState.connected  => 'Connected',
    CallRingingState.noAnswer   => 'No answer',
    CallRingingState.declined   => 'Call declined',
    CallRingingState.busy       => 'User is busy',
    CallRingingState.failed     => 'Call failed',
    CallRingingState.cancelled  => 'Cancelled',
  };
}
```

### `CallStateManager` (listener + group aggregation)

```dart
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CallStateManager extends ChangeNotifier {
  CallStateManager(this._socket) {
    _socket.on('call:ringing', _onRinging);
    _socket.on('call:ended',   (_) => _reset());
  }

  final IO.Socket _socket;

  String? currentCallId;
  CallRingingState state = CallRingingState.dialing;
  final Map<String, CallRingingState> participantStates = {};

  /// Call when you've just POSTed /call/initiate and got the call_id back.
  void attach(String callId) {
    currentCallId = callId;
    state = CallRingingState.dialing;
    participantStates.clear();
    notifyListeners();
  }

  /// Call on REST failure from /call/initiate.
  void markFailedLocally() {
    state = CallRingingState.failed;
    notifyListeners();
  }

  void _onRinging(dynamic raw) {
    final data = (raw as Map).cast<String, dynamic>();
    if (data['call_id'] != currentCallId) return; // stale / other call

    if (data['is_group_call'] == true && data['participants'] is List) {
      for (final p in (data['participants'] as List).cast<Map>()) {
        participantStates[p['user_id'] as String] =
            CallRingingState.fromServer(p['state'] as String);
      }
      state = _aggregateGroup();
    } else {
      state = CallRingingState.fromServer(data['state'] as String);
    }
    notifyListeners();
  }

  CallRingingState _aggregateGroup() {
    final values = participantStates.values;
    if (values.any((s) => s == CallRingingState.connected))  return CallRingingState.connected;
    if (values.any((s) => s == CallRingingState.connecting)) return CallRingingState.connecting;
    if (values.any((s) => s == CallRingingState.ringing))    return CallRingingState.ringing;
    if (values.every((s) => s == CallRingingState.dialing))  return CallRingingState.dialing;
    // all remaining participants are in terminal states → call effectively over
    return CallRingingState.noAnswer;
  }

  void _reset() {
    currentCallId = null;
    participantStates.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socket.off('call:ringing', _onRinging);
    super.dispose();
  }
}
```

### Wiring the outgoing-call screen

```dart
final manager = context.watch<CallStateManager>();
final label = manager.state.label;

// show `label` under the callee's name
// on manager.state.isTerminal: wait ~2s, then Navigator.pop()
```

---

## 6. Expected sequences

| # | Scenario | Events seen on caller (A) |
|---|---|---|
| 1 | B online, accepts | `ringing` → `connecting` → `connected` → (later) `call:ended` |
| 2 | B offline the whole time | `dialing` → `no_answer` (at t ≈ 20 s) |
| 3 | B offline, reconnects at t=8s and accepts | `dialing` → `ringing` → `connecting` → `connected` |
| 4 | B declines | `ringing` → `declined` |
| 5 | A cancels | `ringing` → `cancelled` (echo from server) |
| 6 | B is already on another call | `POST /call/initiate` returns `409 { busy: true }` — Flutter calls `markFailedLocally()` or a dedicated `busy` helper |
| 7 | 4-way group, mixed online/offline | each transition → full `participants[]` snapshot |
| 8 | Bad `conversation_id` | `POST /call/initiate` returns `500` — Flutter calls `markFailedLocally()` |

Scenarios 6 and 8 are the only cases the server does **not** emit `call:ringing`; Flutter sets the state from the REST response.

---

## 7. Debug hooks

- Server logs: `grep RINGING_STATE_EMIT` in `be_call_service` + `be_chat_service` logs to see every emit with `call_id`, `target`, `state`.
- Redis: `redis-cli psubscribe "call:socket:emit"` then trigger a call — every `call:ringing` payload shows up live.
- Ringing TTL key: `redis-cli get user_ringing:<userId>` returns the `room_id` while the user is ringing (clears on accept/decline/timeout).

---

## 8. Quick checklist for the Flutter team

- [ ] Attach `CallStateManager.attach(callId)` right after `POST /call/initiate` succeeds.
- [ ] Subscribe to `call:ringing` on the same socket you already use for `call:incoming`.
- [ ] Add `call_id` to every `call:answer` emit payload.
- [ ] Map `state` → label as per §2 (or ship your own copy).
- [ ] On `isTerminal`, delay 2 s then dismiss the outgoing-call screen.
- [ ] On `POST /call/initiate` 409/5xx, bypass the server event and surface `busy`/`failed` locally.
- [ ] Backwards-compat sanity check: all existing call events (`call:incoming`, `call:accepted`, `call:declined`, `call:cancelled`, `call:ended`, `call:answered-elsewhere`, `call:offer`, `call:ice-candidate`) still wired the same way.
