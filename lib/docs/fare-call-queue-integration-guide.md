# Fare Call Queue - Frontend Integration Guide

## Overview

The Fare Call Queue feature introduces a **call-based ride acceptance flow**. Instead of riders receiving push notifications and accepting rides from a list, riders now receive an **audio call** from the customer. After accepting the call, the rider's screen transforms to show ride details with Accept/Reject buttons. If a rider rejects (or doesn't answer), the system automatically calls the next rider in the queue.

---

## Quick Reference Checklist

### Customer App
- [ ] Add `orderType: "fare-call"` to `POST /fare/orders` request body
- [ ] Listen for socket event `ride:queue:calling` — show "Calling rider X of Y..."
- [ ] Listen for socket event `ride:queue:accepted` — show rider info, call is active
- [ ] Listen for socket event `ride:queue:exhausted` — show "No riders available"
- [ ] Add cancel button that calls `POST /fare/orders/{orderId}/cancel-queue`

### Rider App
- [ ] On `call:incoming` / FCM push: check `metadata?.orderType === "fare-call"` to detect ride calls
- [ ] After accepting call: if fare-call, transform call screen to show ride details + Accept/Reject buttons
- [ ] "Accept Ride" button -> `POST /fare/orders/{orderId}/ride-action` with `{ "action": "accept" }`
- [ ] "Reject Ride" button -> `POST /fare/orders/{orderId}/ride-action` with `{ "action": "reject" }`
- [ ] `orderId` comes from `metadata.orderId` in the call event/push payload

---

## Flow Summary

```
Customer places order (orderType: 'fare-call')
        |
        v
System calls Rider #1
        |
        v
Rider #1 sees incoming call --> Accepts call --> Call screen transforms (ride details + buttons)
        |                                                |
   [Decline / No answer]                        [Accept Ride]  or  [Reject Ride]
        |                                           |                    |
        v                                     Order assigned         Call ends
  System calls Rider #2                      Call stays active    System calls Rider #3
        |                                                              ...
       ...
        |
  All riders exhausted --> Customer notified "No riders available"
```

---

## Customer (User) Side

### 1. Place a Fare-Call Order

**Endpoint:** `POST /fare/orders`

Add `orderType: "fare-call"` to the existing request body. Everything else stays the same.

```json
{
  "selectedRiders": ["rider_user_id_1", "rider_user_id_2", "rider_user_id_3"],
  "pickupLocation": {
    "address": "123 Main St",
    "latitude": 12.9716,
    "longitude": 77.5946
  },
  "dropLocation": {
    "address": "456 Oak Ave",
    "latitude": 12.9352,
    "longitude": 77.6245
  },
  "fare": 250,
  "orderFor": "InCity",
  "modeOfPayment": "postpaid",
  "orderForWhom": "myself",
  "orderType": "fare-call"
}
```

**Response:** Same as existing `201` response with the RideOrder object. The call queue starts automatically after the response.

> **Note:** If `orderType` is omitted or set to `"standard"`, the existing notification-based flow is used. No breaking changes.

### 2. Listen for Queue Progress (Socket Events)

After placing a fare-call order, the customer's frontend should listen for these socket events:

#### `ride:queue:calling`

Emitted each time the system starts calling a new rider. Includes WebRTC connection details so the customer app can auto-join the call room.

```json
{
  "orderId": "ORD-1711900000000",
  "riderIndex": 0,
  "totalRiders": 3,
  "riderId": "rider_user_id_1",
  "call_id": "665a1b2c3d4e5f6789012345",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "conversation_id": "665a1b2c3d4e5f6789abcdef",
  "ice_servers": [ ... ]
}
```

**IMPORTANT — Customer must auto-join the call:**
1. On receiving this event, the customer app must join the WebRTC room using `room_id` and `call_id`
2. Create a WebRTC peer connection using the provided `ice_servers`
3. Send a `call:offer` via socket and exchange ICE candidates
4. This is required because the call is initiated server-side, not by the customer tapping a button

**UI suggestion:** Show a progress indicator like "Calling rider 1 of 3..." with the call connecting in the background.

#### `ride:queue:accepted`

Emitted when a rider accepts the ride.

```json
{
  "orderId": "ORD-1711900000000",
  "riderId": "rider_user_id_2",
  "riderInfo": {
    "id": "rider_user_id_2",
    "name": "Rahul Kumar",
    "contact": "9876543210",
    "profileImage": "https://..."
  }
}
```

**UI suggestion:** Show success screen with rider details. The audio call between customer and rider is already active at this point.

#### `ride:queue:exhausted`

Emitted when all riders have rejected or timed out.

```json
{
  "orderId": "ORD-1711900000000"
}
```

**UI suggestion:** Show "No riders available. Please try again."

### 3. Cancel Queue (Optional)

If the customer wants to cancel while riders are being called:

**Endpoint:** `POST /fare/orders/{orderId}/cancel-queue`

No request body needed. Auth token required.

```json
// Response 200
{
  "success": true,
  "message": "Fare-call order cancelled.",
  "data": {
    "orderId": "ORD-1711900000000",
    "status": "cancelled"
  }
}
```

---

## Rider Side

### 1. Receive Incoming Call

The rider receives the standard `call:incoming` socket event and push notification.

#### How to Differentiate: Fare-Call vs Regular Call

The `metadata` field is available in **3 places** so the frontend can detect a fare-call regardless of app state:

| Source | Where to Check | When Available |
|---|---|---|
| **FCM Push Notification** | `JSON.parse(data.payload).metadata.orderType === "fare-call"` | App killed/backgrounded |
| **Socket `call:incoming`** | `event.metadata.orderType === "fare-call"` | App in foreground |
| **Socket `call:accepted`** | `event.metadata.orderType === "fare-call"` | After accepting call |

For regular calls, `metadata` will be `null` in all three places.

#### Socket `call:incoming` Event

The event now includes a `metadata` field:

```json
{
  "call_id": "665a1b2c3d4e5f6789012345",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "conversation_id": "665a1b2c3d4e5f6789abcdef",
  "call_type": "audio_call",
  "initiated_by": "customer_user_id",
  "is_group_call": false,
  "message": { ... },
  "metadata": {
    "orderType": "fare-call",
    "orderId": "ORD-1711900000000",
    "orderMongoId": "665a1b2c3d4e5f6789000001",
    "rideDetails": {
      "pickup": {
        "address": "123 Main St",
        "lat": 12.9716,
        "lng": 77.5946
      },
      "drop": {
        "address": "456 Oak Ave",
        "lat": 12.9352,
        "lng": 77.6245
      },
      "fare": 250,
      "distance": 8.5,
      "orderFor": "InCity",
      "modeOfPayment": "postpaid"
    }
  }
}
```

#### FCM Push Notification Payload

When the app is backgrounded/killed, the push notification contains the metadata inside the `payload` data field:

```
FCM data fields:
  operation: "incoming_call"
  callerData: "{ \"id\": \"...\", \"name\": \"...\", ... }"   // caller info
  payload: "{ \"call_id\": \"...\", \"room_id\": \"...\", \"metadata\": { \"orderType\": \"fare-call\", \"orderId\": \"...\", \"rideDetails\": { ... } } }"
```

**Detection:** `JSON.parse(fcmData.payload).metadata?.orderType === "fare-call"`

If it's a fare-call, the Flutter call screen should show ride details immediately (from `rideDetails` inside metadata) along with the standard incoming call UI.

### 2. Accept the Call (Standard Flow)

The rider accepts the call normally using the existing `POST /call/accept` endpoint. No changes here.

### 3. Transform the Call Screen

After the call is accepted, the `call:accepted` socket event also includes `metadata`:

```json
{
  "call_id": "665a1b2c3d4e5f6789012345",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "accepted_by": "rider_user_id",
  "metadata": {
    "orderType": "fare-call",
    "orderId": "ORD-1711900000000",
    "rideDetails": { ... }
  }
}
```

**When `metadata.orderType === "fare-call"`**, transform the active call screen to show:

- **Ride details overlay** on the call screen:
  - Pickup address
  - Drop address
  - Fare amount
  - Distance
  - Ride type (InCity, OutStation, etc.)
  - Payment mode (prepaid/postpaid)
- **"Accept Ride" button** (green)
- **"Reject Ride" button** (red)
- Audio call continues in the background - rider and customer can talk

### 4. Accept or Reject the Ride

**Endpoint:** `POST /fare/orders/{orderId}/ride-action`

The `orderId` comes from `metadata.orderId` in the call events.

#### Accept Ride

```json
// Request
{
  "action": "accept"
}

// Response 200
{
  "success": true,
  "message": "Ride accepted successfully. Call will remain active.",
  "data": {
    "orderId": "ORD-1711900000000",
    "status": "payment-pending",
    "assignedRider": "rider_user_id"
  }
}
```

**After acceptance:**
- The call stays active (rider and customer can keep talking)
- Transform the call screen back to normal call UI or show ride-in-progress UI
- The order status moves to `payment-pending` -> normal ride flow continues from here

#### Reject Ride

```json
// Request
{
  "action": "reject"
}

// Response 200
{
  "success": true,
  "message": "Ride rejected. Next rider will be called.",
  "data": {
    "orderId": "ORD-1711900000000",
    "riderIndex": 1,
    "totalRiders": 3
  }
}
```

**After rejection:**
- The call will be ended automatically by the backend
- The rider returns to normal state
- The system automatically calls the next rider in the queue

### 5. Decline the Call (Without Answering)

If the rider declines the incoming call using the existing `POST /call/decline` endpoint, the system automatically moves to the next rider. No new code needed on the rider side for this case.

### 6. No Answer (Timeout)

If the rider doesn't answer within 45 seconds, the call times out automatically and the system calls the next rider. No frontend action needed.

---

## Error Responses

All new endpoints return consistent error formats:

```json
// 400 - Bad Request
{
  "success": false,
  "message": "Invalid action. Must be \"accept\" or \"reject\"."
}

// 403 - Forbidden (wrong rider)
{
  "success": false,
  "message": "You are not the rider currently being called for this order."
}

// 404 - Not Found
{
  "success": false,
  "message": "Order not found."
}

// 409 - Conflict (already accepted)
{
  "success": false,
  "message": "Order has already been accepted or is no longer available."
}
```

---

## New Endpoints Summary

| Endpoint | Method | Who Calls | Purpose |
|---|---|---|---|
| `/fare/orders` | POST | Customer | Existing - now accepts `orderType: "fare-call"` |
| `/fare/orders/{orderId}/ride-action` | POST | Rider | Accept or reject ride from call screen |
| `/fare/orders/{orderId}/cancel-queue` | POST | Customer | Cancel while queue is in progress |

## New/Modified Socket Events Summary

| Event | Direction | Recipient | When |
|---|---|---|---|
| `call:incoming` | Server -> Client | Rider | Existing - now includes `metadata` for fare-calls |
| `call:accepted` | Server -> Client | Both | Existing - now includes `metadata` for fare-calls |
| `ride:queue:calling` | Server -> Client | Customer | Each time a new rider is being called |
| `ride:queue:accepted` | Server -> Client | Customer | A rider accepted the ride |
| `ride:queue:exhausted` | Server -> Client | Customer | All riders rejected/timed out |

---

## Ride Details Object Reference

The `metadata.rideDetails` object available in `call:incoming` and `call:accepted`:

| Field | Type | Description |
|---|---|---|
| `pickup.address` | string | Pickup address text |
| `pickup.lat` | number | Pickup latitude |
| `pickup.lng` | number | Pickup longitude |
| `drop.address` | string | Drop-off address text |
| `drop.lat` | number | Drop-off latitude |
| `drop.lng` | number | Drop-off longitude |
| `fare` | number | Calculated fare amount (INR) |
| `distance` | number | Trip distance in km |
| `orderFor` | string | Ride type: `InCity`, `OutStation`, `HourlyRental`, `Parcel` |
| `modeOfPayment` | string | `prepaid` or `postpaid` |
| `eta` | object/null | ETA from rider's current location to pickup |
| `eta.distanceKm` | number | Road distance from rider to pickup in km (e.g., `4.2`) |
| `eta.durationMin` | number | Estimated travel time in minutes (e.g., `8`) |

---

## Backwards Compatibility

- All existing flows remain unchanged
- `orderType` defaults to `"standard"` if not provided
- `metadata` is `null` for regular (non-fare) calls
- No changes to existing call accept/decline/end flows
- The `/fare/orders/{orderId}/status` PATCH endpoint still works for standard orders
