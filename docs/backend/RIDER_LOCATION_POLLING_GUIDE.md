# Customer Map — Rider Location 10s Polling Integration Guide

Goal: the customer's tracking map updates the rider's marker every 10 seconds by
polling a REST endpoint, instead of (or as a fallback to) the map-provider SSE
stream.

---

## 1. Backend (be_rider_service) — NEW endpoint (already implemented)

### `GET /fare/orders/:orderId/rider-location`

Gateway path the app calls:

```
GET https://be.beapp.in/api/rider-service/fare/orders/{orderId}/rider-location
Authorization: Bearer <JWT>
```

- **Controller:** `src/controllers/fare.controller.js` → `getRiderLiveLocation`
- **Route:** `src/routes/fare.route.js` (next to the `/status` route)
- **Auth:** standard `protect` middleware (JWT / gRPC session). Only the order's
  `userId`, `receiverUserId`, or `assignedRider` may call it — anyone else gets 403.
- **Rider position source:** map-provider gRPC `GetUserLocation(riderUserId)` —
  the same source the SSE streams use. Served by **be_map_service**
  (`src/grpc/services/providerService.js`, `LiveLocation` service) from the
  `ProviderStatus` collection, which the rider app refreshes every ~30s.
  gRPC address comes from `GRPC_MAP_PROVIDER_SERVER_ADDRESS` in be_rider_service;
  be_map_service binds `GRPC_PORT` (defaults differ: client 50052 vs server
  50051 — set the env vars in local dev).
- **Distances:** straight-line haversine computed in-process (no Mappls/OSRM
  road-distance calls — too expensive at a 10s poll rate).

### Response shapes

Active ride (`payment-pending` / `confirmed` / `in-progress` / `picked-up`):

```json
{
  "orderId": "ORD-12345",
  "status": "in-progress",
  "rideActive": true,
  "rider": {
    "userId": "665f...",
    "latitude": 19.0761,
    "longitude": 72.8776,
    "lastSeen": "2026-07-14T10:32:01.000Z"
  },
  "distanceToPickupKm": 1.24,
  "distanceToDropKm": 5.87
}
```

Ride over / not trackable (`completed`, `cancelled`, `rejected`, `pending`) — the
client must **stop polling**:

```json
{ "orderId": "ORD-12345", "status": "completed", "rideActive": false, "rider": null }
```

No rider assigned yet:

```json
{ "orderId": "ORD-12345", "status": "pending", "rideActive": false, "rider": null, "message": "No rider assigned yet." }
```

Rider position momentarily unknown (gRPC hiccup / rider offline) — keep polling,
keep the old marker:

```json
{ "orderId": "ORD-12345", "status": "in-progress", "rideActive": true, "rider": null, "message": "Rider location temporarily unavailable." }
```

Errors: `403` not a party to the order, `404` order not found, `500` server error.

---

## 2. Flutter (BlueEra_flutter) — integration

Existing stack this plugs into:

| Piece | File |
|---|---|
| Endpoint mixin | `lib/core/api/apiService/rider_service_api.dart` |
| Dio helper (JWT header baked in) | `lib/core/api/apiService/api_base_helper.dart` |
| Current SSE-based controller | `lib/features/chat/auth/controller/live_trach_rider_controller.dart` |
| Customer tracking screens | `fare_call_queue_screen.dart`, `goods_multi_call_tracking_screen.dart`, `track_rider_live_location_page.dart` |
| Existing 30s polling idiom to copy | `lib/features/chat/auth/service/location_update_service.dart` |

### Step 1 — add the endpoint to the rider-service mixin

`lib/core/api/apiService/rider_service_api.dart`:

```dart
mixin RiderServiceApi {
  // ...existing endpoints...

  String riderLiveLocationForOrder(String orderId) =>
      'rider-service/fare/orders/$orderId/rider-location';
}
```

### Step 2 — repo method

In the repo that already wraps rider-service order calls (same place as
`checkTrackOrderStatus`), add:

```dart
Future<ResponseModel> getRiderLiveLocationRepo(String orderId) async {
  ResponseModel response = await ApiBaseHelper.getData(
    url: riderLiveLocationForOrder(orderId),
  );
  return response;
}
```

(Match the exact `getData` signature used by the neighboring repo methods —
some take `url:`, some take positional path.)

### Step 3 — polling controller (GetX)

New file `lib/features/common/Discover/controller/rider_location_poll_controller.dart`:

```dart
import 'dart:async';
import 'package:get/get.dart';

class RiderLocationPollController extends GetxController {
  // Same reactive fields the SSE controller exposes, so map widgets
  // (Obx on liveLat/liveLng) work unchanged.
  var liveLat = 0.0.obs;
  var liveLng = 0.0.obs;
  var rideCompleted = false.obs;
  var distanceToPickupKm = RxnDouble();
  var distanceToDropKm = RxnDouble();
  var orderStatus = ''.obs;
  var lastSeen = RxnString();

  Timer? _timer;
  String? _orderId;
  bool _requestInFlight = false;

  /// Start polling every [interval] (default 10s). Fires once immediately.
  void startPolling(String orderId,
      {Duration interval = const Duration(seconds: 10)}) {
    stopPolling();
    _orderId = orderId;
    rideCompleted.value = false;
    _tick(); // immediate first fetch — don't wait 10s for first marker
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_requestInFlight || _orderId == null) return; // no overlapping calls
    _requestInFlight = true;
    try {
      final response =
          await MakeOrderRepo().getRiderLiveLocationRepo(_orderId!);
      final data = response.response?.data;
      if (data == null) return;

      orderStatus.value = data['status'] ?? '';

      if (data['rideActive'] == false) {
        // completed / cancelled / rejected — stop the timer for good.
        rideCompleted.value = true;
        stopPolling();
        return;
      }

      final rider = data['rider'];
      if (rider != null) {
        liveLat.value = (rider['latitude'] as num).toDouble();
        liveLng.value = (rider['longitude'] as num).toDouble();
        lastSeen.value = rider['lastSeen'];
      }
      // rider == null with rideActive true → transient gap; keep old
      // marker position and keep polling.

      distanceToPickupKm.value =
          (data['distanceToPickupKm'] as num?)?.toDouble();
      distanceToDropKm.value = (data['distanceToDropKm'] as num?)?.toDouble();
    } catch (_) {
      // Network blip — swallow, next tick retries. Timer stays alive.
    } finally {
      _requestInFlight = false;
    }
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}
```

### Step 4 — wire into the tracking screen

In `fare_call_queue_screen.dart` (and `goods_multi_call_tracking_screen.dart`),
where the SSE controller is currently started:

```dart
final pollController = Get.put(RiderLocationPollController());

@override
void initState() {
  super.initState();
  pollController.startPolling(widget.orderId); // 10s default
  // Marker update: same `ever` worker pattern already used for the SSE lat:
  _riderLatWorker = ever(pollController.liveLat, (lat) {
    final pos = LatLng(lat, pollController.liveLng.value);
    _updateRiderMarker(pos);
    _drawRoute(pos); // existing polyline redraw
  });
}

void _updateRiderMarker(LatLng pos) {
  setState(() {
    _markers.removeWhere((m) => m.markerId.value == 'rider');
    _markers.add(Marker(
      markerId: const MarkerId('rider'),
      position: pos,
      icon: _riderIcon, // existing bike/rider bitmap
      anchor: const Offset(0.5, 0.5),
      rotation: _bearingFrom(_lastRiderPos, pos), // optional heading
    ));
    _lastRiderPos = pos;
  });
  _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
}
```

Ride-completed handling (same as the SSE flow today):

```dart
_completedWorker = ever(pollController.rideCompleted, (done) {
  if (done == true) {
    // show "ride completed" UI / pop tracking screen
  }
});
```

### Step 5 — lifecycle

```dart
@override
void dispose() {
  _riderLatWorker?.dispose();
  _completedWorker?.dispose();
  pollController.stopPolling();
  Get.delete<RiderLocationPollController>();
  super.dispose();
}
```

Optionally pause when backgrounded (saves battery + server load):

```dart
class _TrackingScreenState extends State<...> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pollController.stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      pollController.startPolling(widget.orderId);
    }
  }
}
```

---

## 3. Coexistence with the existing SSE stream

Today the customer screens use `riderLiveLocationOrderStream` (SSE from
`https://map.beapp.in/api/provider/live-stream/{riderId}`). Two options:

1. **Replace** — swap `LiveTrachRiderController.fetchStream(riderId)` for
   `RiderLocationPollController.startPolling(orderId)`. Simpler, one code path,
   10s freshness.
2. **Fallback (recommended)** — keep SSE as primary (sub-second updates), start
   the 10s poll only when the SSE connection errors/drops, stop it when SSE
   reconnects. The poll endpoint also returns order `status`, which SSE does
   not, so the poll doubles as a status watchdog.

Note the identifier difference: **SSE keys on `riderId`, the poll endpoint keys
on `orderId`** (it resolves `assignedRider` server-side — safer if the rider is
reassigned).

---

## 4. Smoke test

```bash
# 1. Grab a live order id with an assigned rider (any trackable status).
# 2. As the CUSTOMER of that order:
curl -s "https://be.beapp.in/api/rider-service/fare/orders/<ORDER_ID>/rider-location" \
  -H "Authorization: Bearer <CUSTOMER_JWT>" | jq

# Expect: rideActive true + rider.latitude/longitude.
# 3. Repeat with another user's JWT → expect 403.
# 4. Complete/cancel the order, call again → rideActive false.
```

Server-side cost at 10s: one Mongo `findOne` + one gRPC `GetUserLocation` per
poll. No external road-distance API calls.
