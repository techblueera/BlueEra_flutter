# Tiffin Order — Flutter Integration Guide

End-to-end guide for integrating the **tiffin order flow** into the Flutter app.
The flow mirrors the home-made-food order flow.

- **Order lifecycle** → REST (this service, `be_earn_with_blueera_service`)
- **Real-time order card + "ready" updates** → Socket.IO (`be_chat_service`)
- **Push notifications** → via the notification service (existing app handling)

---

## 1. Architecture at a glance

```
 Customer app                 Earn service (REST)              Chat service (Kafka consumer + Socket.IO)
 ────────────                 ───────────────────              ─────────────────────────────────────────
 Browse tiffins  ──GET /tiffins──►
 Build cart (client-side)
 Place order     ──POST /tiffinOrders──► creates TiffinOrder
                                         └─(self-pickup)─ Kafka: CREATE_TIFFIN_PICKUP_ORDER ─►
                                                                          creates chat "order card"
                                                                          socket → seller: newTiffinPickupOrderReceived
                                                                          push  → seller
 Cook marks ready ──PUT /tiffinOrders/:id/ready──►
                                         └─ Kafka: TIFFIN_ORDER_READY ─►  updates card (isReady=true)
                                                                          socket → both: tiffinPickupOrderReady
                                                                          push  → customer
```

Two delivery types:
- `self-pickup` — fully wired today (chat card + notifications). **Use this.**
- `rider` — order is created, but rider assignment/tracking is **not live yet** (rider-service gRPC client pending). Hide or disable in UI until then.

---

## 2. Config & packages

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0
  socket_io_client: ^2.0.3+1
```

```dart
// lib/config/api_config.dart
class ApiConfig {
  // Earn service (REST). Trailing slash matters for the gateway base.
  static const String earnBaseUrl =
      'https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/earn-service';
  // Local dev: 'http://localhost:3000'

  // Chat service (Socket.IO) — same host the app already uses for messaging.
  static const String chatSocketUrl = 'https://<chat-service-host>';
}
```

**Auth:** every `/tiffinOrders/*` endpoint is protected. Send the same JWT the app
already holds from login:

```
Authorization: Bearer <jwt>
```

---

## 3. Endpoint reference

Base = `earnBaseUrl`. All require `Authorization: Bearer <jwt>` unless noted.

| Method | Path | Role | Purpose |
|---|---|---|---|
| `GET`  | `/tiffins?lat=&long=&tiffinName=` | public | Browse / search tiffins |
| `GET`  | `/tiffins/:id` | public | Tiffin detail |
| `GET`  | `/tiffins/user/:userId` | public | A cook's tiffins |
| `POST` | `/tiffinOrders` | customer | Place an order |
| `GET`  | `/tiffinOrders/me` | customer | Order history (paginated) |
| `GET`  | `/tiffinOrders/status/me` | customer | Has an ongoing order? |
| `PUT`  | `/tiffinOrders/:id` | customer/seller | Update status / cancel / assign rider |
| `GET`  | `/tiffinOrders/:orderId/alternatives` | customer | Alternative cooks for an order |
| `GET`  | `/tiffinOrders/seller/me` | seller (cook) | Cook's incoming orders (paginated) |
| `PUT`  | `/tiffinOrders/:orderId/ready` | seller (cook) | Mark order ready for pickup |

### Order status values
`placed → in-progress → completed` (happy path), plus `cancelled` and `expired`.
- Customer may **cancel** only while `placed`.
- Self-pickup orders left untouched auto-**expire** after 1h.
- `in-progress` is set automatically once **every** cook on the order marks ready.

---

## 4. Request / response shapes

### POST `/tiffinOrders` — request
Only `tiffin` id + `quantity` per item. Prices and the seller are resolved on the
backend from the Tiffin document (never trusted from the client).

```json
{
  "items": [
    { "tiffin": "665f1a2b3c4d5e6f7a8b9c0d", "quantity": 2 }
  ],
  "deliveryType": "self-pickup",
  "discount": 0
}
```

### POST `/tiffinOrders` — response `201` (self-pickup)
```json
{
  "_id": "66a0c9...",
  "userId": "customer123",
  "items": [
    {
      "tiffin": "665f1a2b3c4d5e6f7a8b9c0d",
      "quantity": 2,
      "mrp": 80,
      "sellingPrice": 70,
      "centerName": "Anna's Kitchen",
      "sellerLocation": { "type": "Point", "coordinates": [75.857, 22.719] }
    }
  ],
  "totalItems": 2,
  "totalMRP": 160,
  "discount": 0,
  "grandTotal": 140,
  "deliveryType": "self-pickup",
  "sellerId": "cook456",
  "sellerIds": ["cook456"],
  "pickupStatus": { "cook456": "pending" },
  "orderStatus": "placed",
  "createdAt": "2026-06-23T10:00:00.000Z",
  "updatedAt": "2026-06-23T10:00:00.000Z",
  "contact_no": "9876500000"
}
```

Notes:
- `coordinates` are **`[longitude, latitude]`** (GeoJSON order) — flip for most map SDKs.
- `centerName` + `sellerLocation` are attached **per item, only for self-pickup**.
- `contact_no` is the customer's own number (best-effort; may be absent).
- `mrp`/`sellingPrice` come back as **numbers** here (they are strings on the Tiffin doc).
- In the **create** response `items[].tiffin` is the **id string**. In the **list**
  response (`/me`, `/seller/me`) it is the **populated tiffin object**. Parse both (see model).

### GET `/tiffinOrders/me` — response `200`
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "_id": "66a0c9...",
        "items": [
          {
            "tiffin": {
              "_id": "665f...",
              "tiffinName": "Veg Deluxe Lunch",
              "tiffinKey": "morningTiffin",
              "tiffinTiming": { "start": "12:00 PM", "end": "2:00 PM" },
              "images": ["https://..."],
              "sellingPrice": "70",
              "mrp": "80",
              "centerName": "Anna's Kitchen",
              "foodType": "Veg",
              "location": { "type": "Point", "coordinates": [75.857, 22.719] }
            },
            "quantity": 2,
            "mrp": 80,
            "sellingPrice": 70
          }
        ],
        "totalItems": 2,
        "grandTotal": 140,
        "deliveryType": "self-pickup",
        "orderStatus": "placed",
        "createdAt": "2026-06-23T10:00:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1, "totalPages": 1, "totalOrders": 1,
      "hasNextPage": false, "hasPrevPage": false, "nextPage": null, "prevPage": null
    }
  }
}
```
Query params: `page`, `limit`, `orderStatus` (comma-separated, e.g. `placed,in-progress`),
`startDate`, `endDate`, `sortBy` (`createdAt|updatedAt|grandTotal|orderStatus`), `sortOrder` (`asc|desc`).

### GET `/tiffinOrders/status/me` — response `200`
```json
{ "hasOngoingOrder": true, "order": { /* order, statuses placed|in-progress */ } }
// or
{ "hasOngoingOrder": false, "message": "No ongoing orders found." }
```

### PUT `/tiffinOrders/:id` — cancel / update
```json
{ "orderStatus": "cancelled" }   // customer: only while 'placed'
{ "rider": "<riderUserId>" }     // assign a rider (rider flow pending)
```
Returns the updated order. `403` if you're neither owner nor a seller; `400` if cancelling a non-`placed` order.

### GET `/tiffinOrders/:orderId/alternatives?filter=suggested|cheapest|nearest&latitude=&longitude=`
`latitude`/`longitude` required only for `nearest`. Response:
```json
[
  {
    "sellerId": "cook789",
    "name": "Ravi's Tiffins",
    "profilePicture": "https://...",
    "centerName": "Ravi's Kitchen",
    "noOfItemsAvailable": 1,
    "totalPriceForAvailableItems": 65,
    "distance": 1234.5,
    "availableProducts": [ { /* full tiffin doc */ } ]
  }
]
```
Alternatives are other active cooks offering tiffins in the **same meal slot(s)**
(`tiffinKey`) as the order. `distance` is in metres (or `null` if no location given).

### PUT `/tiffinOrders/:orderId/ready` (cook) → returns updated order with `pickupStatus[me]='ready'`.

---

## 5. Dart models

```dart
// lib/features/tiffin_order/models/tiffin_models.dart

/// Tiffin meal slots (the listing's `tiffinKey`).
enum TiffinKey { morningTiffin, breakfast, eveningDinner, unknown }

TiffinKey tiffinKeyFromString(String? s) => switch (s) {
      'morningTiffin' => TiffinKey.morningTiffin,
      'breakfast' => TiffinKey.breakfast,
      'eveningDinner' => TiffinKey.eveningDinner,
      _ => TiffinKey.unknown,
    };

enum OrderStatus { placed, inProgress, completed, cancelled, expired, unknown }

OrderStatus orderStatusFromString(String? s) => switch (s) {
      'placed' => OrderStatus.placed,
      'in-progress' => OrderStatus.inProgress,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      'expired' => OrderStatus.expired,
      _ => OrderStatus.unknown,
    };

enum DeliveryType { selfPickup, rider }

String deliveryTypeToApi(DeliveryType t) =>
    t == DeliveryType.selfPickup ? 'self-pickup' : 'rider';

class TiffinTiming {
  final String? start; // "12:00 PM"
  final String? end;   // "2:00 PM"
  const TiffinTiming({this.start, this.end});
  factory TiffinTiming.fromJson(Map<String, dynamic> j) =>
      TiffinTiming(start: j['start'], end: j['end']);
}

class GeoPoint {
  final double longitude; // coordinates[0]
  final double latitude;  // coordinates[1]
  const GeoPoint(this.longitude, this.latitude);
  static GeoPoint? fromJson(Map<String, dynamic>? j) {
    final c = j?['coordinates'];
    if (c is List && c.length == 2) {
      return GeoPoint((c[0] as num).toDouble(), (c[1] as num).toDouble());
    }
    return null;
  }
}

/// A tiffin listing (full when populated, partial in alternatives/cards).
class Tiffin {
  final String id;
  final String tiffinName;
  final TiffinKey tiffinKey;
  final String? description;
  final List<String> images;
  final double sellingPrice; // stored as String on backend → parsed here
  final double mrp;
  final String? centerName;
  final String? foodType;
  final TiffinTiming? tiffinTiming;
  final GeoPoint? location;
  final String? userId; // the cook

  const Tiffin({
    required this.id,
    required this.tiffinName,
    required this.tiffinKey,
    this.description,
    this.images = const [],
    this.sellingPrice = 0,
    this.mrp = 0,
    this.centerName,
    this.foodType,
    this.tiffinTiming,
    this.location,
    this.userId,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  factory Tiffin.fromJson(Map<String, dynamic> j) => Tiffin(
        id: (j['_id'] ?? j['id']).toString(),
        tiffinName: j['tiffinName'] ?? '',
        tiffinKey: tiffinKeyFromString(j['tiffinKey']),
        description: j['description'],
        images: (j['images'] as List?)?.map((e) => '$e').toList() ?? const [],
        sellingPrice: _num(j['sellingPrice']),
        mrp: _num(j['mrp']),
        centerName: j['centerName'],
        foodType: j['foodType'],
        tiffinTiming: j['tiffinTiming'] is Map
            ? TiffinTiming.fromJson(Map<String, dynamic>.from(j['tiffinTiming']))
            : null,
        location: GeoPoint.fromJson(
            (j['location'] as Map?)?.cast<String, dynamic>()),
        userId: j['userId']?.toString(),
      );
}

/// One line item. `tiffin` may be an id string (create response) or a
/// populated object (list responses). We keep both.
class OrderItem {
  final String tiffinId;
  final Tiffin? tiffin; // null when not populated
  final int quantity;
  final double mrp;
  final double sellingPrice;
  final String? centerName;          // self-pickup create response
  final GeoPoint? sellerLocation;    // self-pickup create response

  const OrderItem({
    required this.tiffinId,
    this.tiffin,
    required this.quantity,
    required this.mrp,
    required this.sellingPrice,
    this.centerName,
    this.sellerLocation,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) {
    final raw = j['tiffin'];
    final populated = raw is Map ? Tiffin.fromJson(raw.cast<String, dynamic>()) : null;
    return OrderItem(
      tiffinId: populated?.id ?? raw.toString(),
      tiffin: populated,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      mrp: (j['mrp'] as num?)?.toDouble() ?? 0,
      sellingPrice: (j['sellingPrice'] as num?)?.toDouble() ?? 0,
      centerName: j['centerName'],
      sellerLocation: GeoPoint.fromJson(
          (j['sellerLocation'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

class TiffinOrder {
  final String id;
  final String userId;
  final String? sellerId;
  final List<String> sellerIds;
  final List<OrderItem> items;
  final int totalItems;
  final double totalMRP;
  final double discount;
  final double grandTotal;
  final DeliveryType deliveryType;
  final OrderStatus orderStatus;
  final Map<String, String> pickupStatus; // sellerId -> 'pending'|'ready'
  final String? riderId;
  final String? contactNo; // present on create response
  final DateTime? createdAt;

  const TiffinOrder({
    required this.id,
    required this.userId,
    this.sellerId,
    this.sellerIds = const [],
    this.items = const [],
    this.totalItems = 0,
    this.totalMRP = 0,
    this.discount = 0,
    this.grandTotal = 0,
    this.deliveryType = DeliveryType.selfPickup,
    this.orderStatus = OrderStatus.placed,
    this.pickupStatus = const {},
    this.riderId,
    this.contactNo,
    this.createdAt,
  });

  factory TiffinOrder.fromJson(Map<String, dynamic> j) => TiffinOrder(
        id: (j['_id'] ?? j['id']).toString(),
        userId: j['userId']?.toString() ?? '',
        sellerId: j['sellerId']?.toString(),
        sellerIds:
            (j['sellerIds'] as List?)?.map((e) => '$e').toList() ?? const [],
        items: (j['items'] as List?)
                ?.map((e) => OrderItem.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        totalItems: (j['totalItems'] as num?)?.toInt() ?? 0,
        totalMRP: (j['totalMRP'] as num?)?.toDouble() ?? 0,
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        grandTotal: (j['grandTotal'] as num?)?.toDouble() ?? 0,
        deliveryType: j['deliveryType'] == 'rider'
            ? DeliveryType.rider
            : DeliveryType.selfPickup,
        orderStatus: orderStatusFromString(j['orderStatus']),
        pickupStatus: (j['pickupStatus'] as Map?)
                ?.map((k, v) => MapEntry('$k', '$v')) ??
            const {},
        riderId: j['rider']?.toString(),
        contactNo: j['contact_no']?.toString(),
        createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
      );
}

class OrderAlternative {
  final String sellerId;
  final String? name;
  final String? profilePicture;
  final String? centerName;
  final int noOfItemsAvailable;
  final double totalPriceForAvailableItems;
  final double? distanceMeters;
  final List<Tiffin> availableProducts;

  const OrderAlternative({
    required this.sellerId,
    this.name,
    this.profilePicture,
    this.centerName,
    this.noOfItemsAvailable = 0,
    this.totalPriceForAvailableItems = 0,
    this.distanceMeters,
    this.availableProducts = const [],
  });

  factory OrderAlternative.fromJson(Map<String, dynamic> j) => OrderAlternative(
        sellerId: j['sellerId'].toString(),
        name: j['name'],
        profilePicture: j['profilePicture'],
        centerName: j['centerName'],
        noOfItemsAvailable: (j['noOfItemsAvailable'] as num?)?.toInt() ?? 0,
        totalPriceForAvailableItems:
            (j['totalPriceForAvailableItems'] as num?)?.toDouble() ?? 0,
        distanceMeters: (j['distance'] as num?)?.toDouble(),
        availableProducts: (j['availableProducts'] as List?)
                ?.map((e) => Tiffin.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}
```

---

## 6. REST client (Dio)

```dart
// lib/features/tiffin_order/data/tiffin_order_api.dart
import 'package:dio/dio.dart';
import '../models/tiffin_models.dart';
import '../../../config/api_config.dart';

class TiffinOrderApi {
  final Dio _dio;

  TiffinOrderApi(String Function() getToken)
      : _dio = Dio(BaseOptions(baseUrl: ApiConfig.earnBaseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = getToken();
        if (t.isNotEmpty) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
    ));
  }

  // ---- Browse ----
  Future<List<Tiffin>> browseTiffins(
      {double? lat, double? long, String? search}) async {
    final res = await _dio.get('/tiffins', queryParameters: {
      if (lat != null) 'lat': lat,
      if (long != null) 'long': long,
      if (search != null && search.isNotEmpty) 'tiffinName': search,
    });
    final list = (res.data is List) ? res.data : (res.data['data'] ?? []);
    return (list as List)
        .map((e) => Tiffin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Customer ----
  Future<TiffinOrder> createOrder({
    required List<({String tiffinId, int quantity})> items,
    DeliveryType deliveryType = DeliveryType.selfPickup,
    double discount = 0,
  }) async {
    final res = await _dio.post('/tiffinOrders', data: {
      'items': items
          .map((e) => {'tiffin': e.tiffinId, 'quantity': e.quantity})
          .toList(),
      'deliveryType': deliveryTypeToApi(deliveryType),
      'discount': discount,
    });
    return TiffinOrder.fromJson(res.data as Map<String, dynamic>);
  }

  Future<({List<TiffinOrder> orders, bool hasNextPage, int currentPage})>
      myOrders({int page = 1, int limit = 10, List<String>? statuses}) async {
    final res = await _dio.get('/tiffinOrders/me', queryParameters: {
      'page': page,
      'limit': limit,
      if (statuses != null && statuses.isNotEmpty)
        'orderStatus': statuses.join(','),
    });
    final data = res.data['data'];
    return (
      orders: (data['orders'] as List)
          .map((e) => TiffinOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNextPage: data['pagination']?['hasNextPage'] == true,
      currentPage: (data['pagination']?['currentPage'] as num?)?.toInt() ?? page,
    );
  }

  Future<TiffinOrder?> ongoingOrder() async {
    final res = await _dio.get('/tiffinOrders/status/me');
    if (res.data['hasOngoingOrder'] == true) {
      return TiffinOrder.fromJson(res.data['order'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<TiffinOrder> cancelOrder(String orderId) async {
    final res = await _dio
        .put('/tiffinOrders/$orderId', data: {'orderStatus': 'cancelled'});
    return TiffinOrder.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OrderAlternative>> alternatives(
    String orderId, {
    String filter = 'suggested', // suggested | cheapest | nearest
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.get('/tiffinOrders/$orderId/alternatives',
        queryParameters: {
          'filter': filter,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        });
    return (res.data as List)
        .map((e) => OrderAlternative.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Seller (cook) ----
  Future<List<TiffinOrder>> sellerOrders(
      {int page = 1, int limit = 10, List<String>? statuses}) async {
    final res = await _dio.get('/tiffinOrders/seller/me', queryParameters: {
      'page': page,
      'limit': limit,
      if (statuses != null && statuses.isNotEmpty)
        'orderStatus': statuses.join(','),
    });
    return (res.data['data']['orders'] as List)
        .map((e) => TiffinOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TiffinOrder> markReady(String orderId) async {
    final res = await _dio.put('/tiffinOrders/$orderId/ready');
    return TiffinOrder.fromJson(res.data as Map<String, dynamic>);
  }
}
```

---

## 7. Real-time (Socket.IO, chat service)

The app already connects to the chat service for messaging. Reuse that connection —
just add two listeners. Connection auth is via the handshake `auth.token`:

```dart
// lib/features/tiffin_order/data/tiffin_socket.dart
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/tiffin_models.dart';
import '../../../config/api_config.dart';

class TiffinOrderSocket {
  io.Socket? _socket;

  void connect(String jwt) {
    _socket = io.io(
      ApiConfig.chatSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': jwt}) // → socket.user_id on the server
          .enableReconnection()
          .build(),
    );
    _socket!.connect();
  }

  /// COOK side — a new tiffin order arrived. Payload: { message: <chatMessage> }.
  void onNewOrder(void Function(Map<String, dynamic> message) cb) {
    _socket?.on('newTiffinPickupOrderReceived', (data) {
      final msg = (data?['message'] as Map?)?.cast<String, dynamic>();
      if (msg != null) cb(msg);
    });
  }

  /// CUSTOMER side — your order was marked ready.
  /// Payload: { messageId, orderId, sellerId }.
  void onOrderReady(void Function(String orderId, String sellerId) cb) {
    _socket?.on('tiffinPickupOrderReady', (data) {
      cb('${data?['orderId']}', '${data?['sellerId']}');
    });
  }

  /// CUSTOMER/COOK side — the order card was cancelled by the customer.
  /// Payload: { messageId, orderId, sellerId }. On reload the card shows
  /// cancelled regardless (metadata.is_cancelled = true).
  void onOrderCancelled(void Function(String orderId, String sellerId) cb) {
    _socket?.on('tiffinPickupOrderCancelled', (data) {
      cb('${data?['orderId']}', '${data?['sellerId']}');
    });
  }

  void dispose() {
    _socket?.off('newTiffinPickupOrderReceived');
    _socket?.off('tiffinPickupOrderReady');
    _socket?.off('tiffinPickupOrderCancelled');
  }
}
```

Usage:
```dart
final socket = TiffinOrderSocket()..connect(jwt);

// Customer: refresh the order when the cook marks it ready
socket.onOrderReady((orderId, sellerId) {
  if (orderId == currentOrder.id) {
    // update UI → "Ready for pickup", refetch the order, show pickup CTA
  }
});

// Cook: a new order landed
socket.onNewOrder((message) {
  final order = message['metadata']?['order'];
  // show toast + refresh sellerOrders()
});
```

> The card is also persisted as a chat message, so it appears in the conversation
> between the customer and the cook (see §8). Real-time events are for live UI;
> the chat thread + `/tiffinOrders/me` are the source of truth on reload.

---

## 8. The chat "order card" message

When a self-pickup order is placed, the chat service writes a message into the
customer↔cook **business** conversation. Render it specially when
`message_type == 'tiffin_selfpickup'`.

Shape (as returned by the chat history `getMessages` / socket payload):
```json
{
  "_id": "<messageId>",
  "conversation_id": "<id>",
  "senderId": "<customerId>",
  "message_type": "tiffin_selfpickup",
  "sub_type": "tiffin_selfpickup",
  "message": "New self-pickup tiffin order",
  "metadata": {
    "order": {
      "orderId": "<tiffinOrderId>",
      "sellerId": "<cookId>",
      "businessId": "<cookId>",
      "items": [
        {
          "tiffinId": "665f...",
          "tiffinName": "Veg Deluxe Lunch",
          "tiffinKey": "morningTiffin",
          "tiffinTiming": { "start": "12:00 PM", "end": "2:00 PM" },
          "images": ["https://..."],
          "quantity": 2,
          "mrp": 80,
          "sellingPrice": 70
        }
      ],
      "totalItems": 2,
      "grandTotal": 140,
      "deliveryType": "self-pickup",
      "sellerLocation": { "type": "Point", "coordinates": [75.857, 22.719] },
      "isReady": false
    },
    "tiffinPickupOrderId": "<tiffinOrderId>",
    "order_status": false,
    "is_cancelled": false
  }
}
```

`order_status` / `order.isReady` flip to `true` after the cook marks it ready.

> ### ⚠️ Item enrichment — backend MUST populate this (common bug)
> The stored TiffinOrder item only holds `{ tiffin, quantity, mrp, sellingPrice,
> sellerLocation }` — it has **no name and no images** (see the `POST
> /tiffinOrders` 201 response). When the chat service builds this card message it
> **must join the Tiffin document** and write the display fields into each
> `metadata.order.items[]`. Without this the card renders **blank name + no
> image**.
>
> Required per item in the card (joined from the Tiffin doc):
> - **`images`** — array of image URL strings `["https://…"]` (or `[{ "url": "…" }]`).
>   The app shows `items[i].images[0].url`. **Missing this ⇒ no tiffin image.**
> - **`tiffinName`** — item title. (App also accepts `foodName` / `productName`.)
> - `tiffinId`, and optionally `tiffinKey` + `tiffinTiming` for timing.
>
> Also required at the metadata level:
> - **`metadata.tiffinPickupOrderId`** — the app parses `metadata.order` **only
>   when this key is present**. Missing it ⇒ the whole card is empty.
>
> So the chat-card item is the *enriched* shape shown above, NOT the raw order
> item from the REST create response. Same enrichment the home-made-food card
> already does (`foodName` + `images`).
>
> **Backend status — RESOLVED:** the earn service now joins the Tiffin doc
> (`tiffinName` + `images`) **and signs each S3 image key into a presigned
> download URL** before publishing, so `metadata.order.items[].images` are
> renderable `https://…` strings. (Tiffin images are stored as S3 keys; the
> raw keys were being sent before, which is why no image showed.)

```dart
// Minimal card renderer
Widget buildTiffinOrderCard(Map<String, dynamic> message) {
  final order = (message['metadata']?['order'] as Map?)?.cast<String, dynamic>() ?? {};
  final items = (order['items'] as List?) ?? [];
  final isReady = message['metadata']?['order_status'] == true ||
      order['isReady'] == true;
  final isCancelled = message['metadata']?['is_cancelled'] == true;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lunch_dining),
            const SizedBox(width: 8),
            const Text('Tiffin order', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(label: Text(isCancelled ? 'Cancelled' : (isReady ? 'Ready' : 'Placed'))),
          ]),
          const SizedBox(height: 8),
          ...items.map((it) => Text(
              '${it['quantity']} × ${it['tiffinName']}  '
              '(${it['tiffinTiming']?['start'] ?? ''}–${it['tiffinTiming']?['end'] ?? ''})')),
          const Divider(),
          Text('Total: ₹${order['grandTotal']}'),
        ],
      ),
    ),
  );
}
```

---

## 9. Push notifications

Notifications are emitted via the notification service (existing app handling). Two operations:
- `tiffin_pickup_order` → to the **cook** when an order is placed.
- `tiffin_pickup_order_ready` → to the **customer** when it's ready.

The notification `data` carries `message_type: "tiffin_selfpickup"`, `conversation_id`,
`message_id`, `conversation_type: "business"`. On tap, deep-link to the conversation
(or the order detail) using those ids. No SMS is sent for this type (push + in-app only).

---

## 10. Suggested customer flow (wiring it together)

```
1. Browse:        api.browseTiffins(lat, long, search)
2. Cart:          collect [(tiffinId, quantity)] client-side (group by cook if you allow multi-cook)
3. Pre-check:     api.ongoingOrder()  → warn if one is already active (optional UX)
4. Place:         final order = await api.createOrder(items: cart, deliveryType: selfPickup)
5. Confirmation:  show grandTotal, per-item sellerLocation on a map (flip coords!),
                  customer contactNo, and a "Chat with cook" CTA (open conversation with sellerId)
6. Live:          socket.onOrderReady(...) → flip UI to "Ready for pickup"
7. History:       api.myOrders(statuses: ['placed','in-progress','completed'])
8. Cancel:        api.cancelOrder(id)   // only while 'placed'
9. Alternatives:  api.alternatives(order.id, filter: 'nearest', latitude, longitude)
```

### Cook flow
```
1. List:    api.sellerOrders(statuses: ['placed','in-progress'])
2. Live:    socket.onNewOrder(...) → toast + refresh list
3. Ready:   api.markReady(orderId)  → triggers customer notification + card update
```

---

## 11. Error handling

All errors return `{ "message": "..." }` (orders) or `{ "success": false, "message": "..." }` (lists).

| Code | When | UI |
|---|---|---|
| `400` | empty items, invalid id, inactive tiffin, illegal cancel | show `message` |
| `401` | missing/expired token | refresh token / re-login |
| `403` | updating an order you don't own / aren't a seller on | hide action |
| `404` | tiffin or order not found | refresh list |
| `500` | server error | generic retry |

```dart
try {
  await api.createOrder(...);
} on DioException catch (e) {
  final msg = e.response?.data?['message'] ?? 'Something went wrong';
  showError(msg);
}
```

---

## 12. Gotchas checklist

- [ ] Coordinates are **`[long, lat]`** — flip before passing to map widgets.
- [ ] `items[].tiffin` is an **id string on create**, a **populated object on list** — the model handles both.
- [ ] Prices on the **Tiffin doc** are strings; on the **order** they're numbers.
- [ ] Customer can **cancel only while `placed`**.
- [ ] On cancel, the card's `metadata.is_cancelled` flips to `true` and a **`tiffinPickupOrderCancelled`** socket event fires `{ messageId, orderId, sellerId }` — add the listener for live UI; on reload the card shows cancelled regardless.
- [ ] Multi-cook cart → `sellerIds` has >1 entry; order goes `in-progress` only when **all** cooks mark ready; render `pickupStatus` per cook.
- [ ] `rider` delivery: order is created but rider assignment/tracking is **not live yet** — prefer `self-pickup` in UI.
- [ ] Real-time is best-effort; on app resume, refetch `/tiffinOrders/me` and the chat thread.
- [ ] Self-pickup orders **auto-expire after 1h** if untouched — reflect `expired` in history.
```
