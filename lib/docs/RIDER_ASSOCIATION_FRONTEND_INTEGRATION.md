# Rider-Business Association — Frontend Integration Guide

This document provides complete step-by-step details for integrating the rider-business association feature into the Flutter mobile app. The feature allows riders and businesses (shops) to form delivery partnerships. Either party can initiate a request, which appears as a special chat message. The recipient accepts or rejects. Notifications and socket events fire at every step.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Models](#2-data-models)
3. [REST API Endpoints](#3-rest-api-endpoints)
4. [Socket.IO Events Reference](#4-socketio-events-reference)
5. [Push Notification Events](#5-push-notification-events)
6. [Complete Flow: Rider Sends Request to Business](#6-complete-flow-rider-sends-request-to-business)
7. [Complete Flow: Business Sends Request to Rider](#7-complete-flow-business-sends-request-to-rider)
8. [Chat Message Structure](#8-chat-message-structure)
9. [UI Screens Required](#9-ui-screens-required)
10. [Edge Cases & Error Handling](#10-edge-cases--error-handling)
11. [Testing Checklist](#11-testing-checklist)

---

## 1. Architecture Overview

The association system spans three backend services. The **rider service** is the source of truth for association state. The **chat service** handles messages, socket events, and in-app notifications. The **notification service** handles push notifications.

```
Flutter App (Rider)           Rider Service (REST)            Chat Service (Kafka)           Flutter App (Business)
     |                              |                              |                              |
     |-- POST /request ----------->|                              |                              |
     |<-- 201 { association }      |                              |                              |
     |                              |-- Kafka: CREATE_RIDER_ ---->|                              |
     |                              |   ASSOCIATION_REQUEST        |-- socket: newRiderAssociation|
     |                              |                              |   Request ------------------>|
     |                              |-- Kafka: notification ------>| (push notification)          |
     |                              |   .service                   |                              |
     |                              |                              |                              |
     |                              |<-- PATCH /:id/respond -------|                              |
     |                              |    { action: "accept" }      |<----------------------------|
     |                              |                              |                              |
     |                              |-- Kafka: RIDER_ASSOCIATION ->|                              |
     |                              |   _ACCEPTED                  |-- socket: riderAssociation  |
     |<-- socket: riderAssociation |                              |   Accepted ----------------->|
     |   Accepted                   |                              |                              |
     |                              |                              |                              |
     |========== ASSOCIATION ACTIVE — BOTH PARTIES CAN NOW SEE EACH OTHER IN THEIR LIST =========|
```

**Key points:**
- Rider service stores the association document (source of truth)
- Chat service creates/updates messages in a `"business"` type conversation
- All API calls go to the rider service; chat service only receives Kafka events
- Socket events update the UI in real-time without polling
- Push notifications are the fallback when the user is offline
- Association requests auto-expire after 7 days (configurable via `ASSOCIATION_REQUEST_TTL_DAYS` env var)
- A cron job runs every 15 minutes to expire stale pending requests

---

## 2. Data Models

### 2.1 RiderAssociation Model

This is the document stored in MongoDB by the rider service.

```dart
class RiderAssociation {
  final String id;               // MongoDB _id
  final String riderUserId;      // The rider's user ID
  final String businessUserId;   // The business owner's user ID
  final String requestedBy;      // "rider" or "business" — who initiated
  final String status;           // "pending", "accepted", "rejected", "expired", "dissociated"
  final String statusReason;     // Optional reason (for reject/dissociate)
  final DateTime? expiresAt;     // When this pending request will auto-expire
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RiderAssociation.fromJson(Map<String, dynamic> json) {
    return RiderAssociation(
      id: json['_id'] ?? '',
      riderUserId: json['riderUserId'] ?? '',
      businessUserId: json['businessUserId'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      status: json['status'] ?? '',
      statusReason: json['statusReason'] ?? '',
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
```

### 2.2 Association Status Flow

```
                    ┌──────────┐
           ┌───────│  pending  │───────┐
           │       └──────────┘       │
           │            │              │
      (recipient    (recipient     (7-day TTL
       accepts)      rejects)      exceeded)
           │            │              │
           v            v              v
     ┌──────────┐ ┌──────────┐  ┌──────────┐
     │ accepted │ │ rejected │  │ expired  │
     └──────────┘ └──────────┘  └──────────┘
           │            │              │
      (either       (either        (either
       party         party          party
       ends it)     re-requests)   re-requests)
           │            │              │
           v            └──────┬───────┘
     ┌──────────┐              │
     │dissociated│             v
     └──────────┘        ┌──────────┐
           │             │  pending  │  (re-request reuses same document)
           │             └──────────┘
      (either party
       re-requests)
           │
           v
     ┌──────────┐
     │  pending  │
     └──────────┘
```

**Important:** Re-requests after rejection, dissociation, or expiry do NOT create a new document. The existing record is updated back to `pending`. The compound unique index `{ riderUserId, businessUserId }` ensures only one record per pair.

### 2.3 Chat Message Metadata — RiderAssociation Info

This is the metadata attached to `rider_association` type chat messages. Used for rendering the card UI.

```dart
class RiderAssociationMessageMetadata {
  final String riderAssociationId;  // Same as association _id
  final String associationId;
  final String riderUserId;
  final String businessUserId;
  final String requestedBy;         // "rider" or "business"
  final String status;              // Updates in real-time via socket events
  final RiderInfo riderInfo;
  final BusinessInfo businessInfo;
}

class RiderInfo {
  final String name;
  final String profileImage;       // URL or empty string
  final String vehicleType;        // e.g. "twoWheelerRider", "fourWheeler"
  final String contactNo;
  final double ratingsAverage;
  final int ratingsCount;
}

class BusinessInfo {
  final String businessName;
  final String logo;               // URL or empty string
  final String category;           // e.g. "grocery", "restaurant"
  final String contactNo;
}
```

### 2.4 Rider Extra Data (New)

The `metadata.riderExtra` object is included in rider_association messages. It contains additional rider details fetched via gRPC from the rider service at message creation time.

```dart
class RiderExtra {
  final int associationCount;       // Total number of associations for this rider (all statuses)
  final RiderAddress? address;      // Rider's registered home address
  final RiderLocation? currentLocation; // Rider's last known GPS location
}

class RiderAddress {
  final String streetAddress;       // e.g. "Tharamangalam, Tamil Nadu, India"
  final String houseNo;
  final String landmark;
  final String pincode;
  final String city;
  final String state;
  final bool locationPermission;
  final GeoPoint? homeLocation;     // { type: "Point", coordinates: [lng, lat] }
}

class RiderLocation {
  final String type;                // "Point"
  final List<double>? coordinates;  // [longitude, latitude] — may be absent if location not shared
}
```

**Usage notes:**
- `associationCount` tells the business how many total associations the rider has (across all businesses and statuses). Useful for showing rider experience/activity.
- `address` is the rider's registered home address from onboarding. May have `[0, 0]` coordinates if location permission was not granted.
- `currentLocation.coordinates` may be missing or `[0, 0]` if the rider hasn't shared live location.

---

## 3. REST API Endpoints

**Base URL:** Rider Service — e.g. `https://be.blueera.ai/api/rider-service/api`

**Auth:** All endpoints require `Authorization: Bearer <token>` header.

---

### 3.1 Send Association Request

Creates a new association request. Either a rider or a business user can call this.

- **Endpoint:** `POST /riders/associations/request`
- **Auth:** Required (Bearer token)

#### How Role Resolution Works

The frontend does NOT need to specify who is the rider and who is the business. The backend figures it out automatically:

1. Checks if the requester (logged-in user) has a Rider record in the database
2. Fetches the target user's `account_type` via gRPC from the User Service
3. If requester is a rider AND target is `BUSINESS` → `requestedBy: "rider"`
4. If requester is `BUSINESS` AND target has a Rider record → `requestedBy: "business"`
5. Any other combination → 400 error

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `targetUserId` | String | Yes | The user ID of the other party (rider or business) |

#### Example Request — Rider requesting a business

```json
{
  "targetUserId": "60d5ec49f1b2c8b1a4e4b123"
}
```

#### Example Request — Business requesting a rider

```json
{
  "targetUserId": "60d5ec49f1b2c8b1a4e4b789"
}
```

#### Success Response (201 Created)

```json
{
  "_id": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
  "requestedBy": "rider",
  "status": "pending",
  "statusReason": "",
  "expiresAt": "2026-03-28T10:30:00.000Z",
  "createdAt": "2026-03-21T10:30:00.000Z",
  "updatedAt": "2026-03-21T10:30:00.000Z",
  "__v": 0
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 400 | `"Cannot send association request to yourself."` | `targetUserId` equals the logged-in user's ID |
| 400 | `"One party must be a rider and the other a business user."` | Neither party is a rider, or both are riders, or neither is a business |
| 400 | `"Rider onboarding is not complete."` | The rider party has `isOnboardingComplete: false` |
| 400 | `"Association request is already pending."` | A `pending` association already exists between these two users |
| 400 | `"Already associated with this business/rider."` | An `accepted` association already exists between these two users |
| 404 | `"User not found."` | The `targetUserId` does not exist in the User Service |
| 404 | `"Rider profile not found."` | The rider party has no Rider document in the rider service |
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Error creating association request"` | Unexpected server error |

#### What Happens After Success

1. A `RiderAssociation` document is created (or an existing rejected/dissociated/expired one is updated back to `pending`)
2. A Kafka event `CREATE_RIDER_ASSOCIATION_REQUEST` is sent to the chat service
3. The chat service creates a `rider_association` type message in a `"business"` conversation between the two users
4. The chat service emits a `newRiderAssociationRequest` socket event to the target user
5. A push notification with operation `rider_association_request` is sent to the target user

---

### 3.2 Respond to Association Request

Accept or reject a pending association request. **Only the recipient can respond** — not the person who sent the request.

- **Endpoint:** `PATCH /riders/associations/:id/respond`
- **Auth:** Required (Bearer token)

#### Who Is the Recipient?

| `requestedBy` value | Recipient (who can respond) |
|---------------------|-----------------------------|
| `"rider"` | The business user (`businessUserId`) |
| `"business"` | The rider (`riderUserId`) |

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `action` | String | Yes | `"accept"` or `"reject"` |
| `reason` | String | No | Optional reason, stored in `statusReason`. Useful when rejecting. |

#### Example Request — Accept

```json
{
  "action": "accept",
  "reason": "Happy to partner with you"
}
```

#### Example Request — Reject

```json
{
  "action": "reject",
  "reason": "Not looking for riders at this time"
}
```

#### Success Response — Accepted (200 OK)

```json
{
  "_id": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
  "requestedBy": "rider",
  "status": "accepted",
  "statusReason": "Happy to partner with you",
  "expiresAt": "2026-03-28T10:30:00.000Z",
  "createdAt": "2026-03-21T10:30:00.000Z",
  "updatedAt": "2026-03-22T08:00:00.000Z",
  "__v": 0
}
```

#### Success Response — Rejected (200 OK)

```json
{
  "_id": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
  "requestedBy": "rider",
  "status": "rejected",
  "statusReason": "Not looking for riders at this time",
  "expiresAt": "2026-03-28T10:30:00.000Z",
  "createdAt": "2026-03-21T10:30:00.000Z",
  "updatedAt": "2026-03-22T08:00:00.000Z",
  "__v": 0
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 400 | `"Invalid action. Must be 'accept' or 'reject'."` | `action` is not `"accept"` or `"reject"` |
| 400 | `"This association request has expired."` | The association status is `expired` (past 7-day TTL) |
| 400 | `"This request has already been responded to."` | The association status is not `pending` (already accepted/rejected/dissociated) |
| 403 | `"You are not authorized to respond to this request."` | The logged-in user is not the intended recipient |
| 404 | `"Association not found."` | No association exists with the given ID |
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Internal server error"` | Unexpected server error |

#### What Happens After Success

1. The association status updates to `accepted` or `rejected`
2. Kafka event `RIDER_ASSOCIATION_ACCEPTED` or `RIDER_ASSOCIATION_REJECTED` is sent to chat service
3. The chat service updates the original `rider_association` message's `metadata.riderAssociation.status`
4. The chat service creates a new text message in the same conversation:
   - If accepted: `"[Rider Name] is now associated with [Business Name]"`
   - If rejected: `"Association request was declined"`
5. Socket event `riderAssociationAccepted` or `riderAssociationRejected` is emitted to BOTH parties
6. Push notification sent to the requester (the person who originally sent the request)

---

### 3.3 List My Associations

Returns a paginated list of all associations where the logged-in user is either the rider or the business.

- **Endpoint:** `GET /riders/associations`
- **Auth:** Required (Bearer token)

#### Query Parameters

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `status` | String | No | (all) | Filter by status: `pending`, `accepted`, `rejected`, `expired`, `dissociated` |
| `page` | Integer | No | `1` | Page number (1-indexed) |
| `limit` | Integer | No | `10` | Results per page (max 100) |

#### Example Requests

```
GET /riders/associations                              → All associations, page 1
GET /riders/associations?status=accepted              → Only active partnerships
GET /riders/associations?status=pending               → Only pending requests
GET /riders/associations?status=accepted&page=2&limit=5  → Paginated active partnerships
```

#### Success Response (200 OK)

```json
{
  "associations": [
    {
      "_id": "683d1a2b4f5e6d7c8a9b0c1d",
      "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
      "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
      "requestedBy": "rider",
      "status": "accepted",
      "statusReason": "",
      "expiresAt": "2026-03-28T10:30:00.000Z",
      "createdAt": "2026-03-21T10:30:00.000Z",
      "updatedAt": "2026-03-22T08:00:00.000Z"
    },
    {
      "_id": "683d1a2b4f5e6d7c8a9b0c2e",
      "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
      "businessUserId": "60d5ec49f1b2c8b1a4e4b456",
      "requestedBy": "business",
      "status": "pending",
      "statusReason": "",
      "expiresAt": "2026-03-28T14:00:00.000Z",
      "createdAt": "2026-03-21T14:00:00.000Z",
      "updatedAt": "2026-03-21T14:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 2,
    "totalPages": 1
  }
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Internal server error"` | Unexpected server error |

---

### 3.4 Get Single Association

Returns a single association by its ID. The logged-in user must be one of the two parties.

- **Endpoint:** `GET /riders/associations/:id`
- **Auth:** Required (Bearer token)

#### Success Response (200 OK)

```json
{
  "_id": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
  "requestedBy": "rider",
  "status": "accepted",
  "statusReason": "",
  "expiresAt": "2026-03-28T10:30:00.000Z",
  "createdAt": "2026-03-21T10:30:00.000Z",
  "updatedAt": "2026-03-22T08:00:00.000Z"
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 403 | `"You are not part of this association."` | Logged-in user is neither `riderUserId` nor `businessUserId` |
| 404 | `"Association not found."` | No association with this ID exists |
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Internal server error"` | Unexpected server error |

---

### 3.5 Dissociate (End Association)

Ends an active (`accepted`) association. Either the rider or the business can do this.

- **Endpoint:** `PATCH /riders/associations/:id/dissociate`
- **Auth:** Required (Bearer token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reason` | String | No | Optional reason for ending the association |

#### Example Request

```json
{
  "reason": "No longer delivering in this area"
}
```

#### Success Response (200 OK)

```json
{
  "_id": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
  "requestedBy": "rider",
  "status": "dissociated",
  "statusReason": "No longer delivering in this area",
  "expiresAt": "2026-03-28T10:30:00.000Z",
  "createdAt": "2026-03-21T10:30:00.000Z",
  "updatedAt": "2026-03-23T14:00:00.000Z"
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 400 | `"Cannot dissociate. Association is not active."` | Association status is not `accepted` (e.g. still pending, already dissociated, etc.) |
| 403 | `"You are not part of this association."` | Logged-in user is neither `riderUserId` nor `businessUserId` |
| 404 | `"Association not found."` | No association with this ID exists |
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Internal server error"` | Unexpected server error |

#### What Happens After Success

1. Association status changes to `dissociated`
2. Kafka event `RIDER_ASSOCIATION_DISSOCIATED` sent to chat service
3. Chat service updates the original message's `metadata.riderAssociation.status` to `dissociated`
4. Chat service creates a new text message: `"Rider association has been ended"`
5. Socket event `riderAssociationDissociated` emitted to both parties
6. Push notification sent to the OTHER party (the one who didn't initiate the dissociation)

---

### 3.6 Check Association Between Two Users

Checks if an association exists between any two users. The order of IDs does not matter. Useful for determining the "Associate" button state on a profile screen.

- **Endpoint:** `GET /riders/associations/check`
- **Auth:** Required (Bearer token)

#### Query Parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `userId1` | String | Yes | User ID of the first party |
| `userId2` | String | Yes | User ID of the second party |

#### Example Request

```
GET /riders/associations/check?userId1=69bd0ef28c0f463d91134206&userId2=69b79df28c0f463d91112cd4
```

#### Success Response — Association Found (200 OK)

```json
{
  "exists": true,
  "association": {
    "_id": "69be3aae2ff4da987316809f",
    "riderUserId": "69bd0ef28c0f463d91134206",
    "businessUserId": "69b79df28c0f463d91112cd4",
    "requestedBy": "rider",
    "status": "accepted",
    "statusReason": "",
    "expiresAt": null,
    "createdAt": "2026-03-21T06:29:02.963Z",
    "updatedAt": "2026-03-21T06:29:02.963Z"
  }
}
```

#### Success Response — No Association Found (200 OK)

```json
{
  "exists": false,
  "association": null
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 400 | `"Both userId1 and userId2 are required."` | One or both query params missing |
| 400 | `"userId1 and userId2 must be different."` | Both IDs are the same |
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Internal server error"` | Unexpected server error |

#### Frontend Usage — Profile Screen Button State

Call this endpoint when opening another user's profile to determine the "Associate" button state:

```dart
final res = await dio.get('/riders/associations/check', queryParameters: {
  'userId1': currentUserId,
  'userId2': profileUserId,
});

if (!res.data['exists']) {
  // Show "Send Association Request" button (enabled)
} else {
  final status = res.data['association']['status'];
  final requestedBy = res.data['association']['requestedBy'];
  final isRequester = (requestedBy == 'rider' && currentUserId == res.data['association']['riderUserId'])
      || (requestedBy == 'business' && currentUserId == res.data['association']['businessUserId']);

  switch (status) {
    case 'pending':
      if (isRequester) {
        // Show "Request Pending" (disabled)
      } else {
        // Show "View Request" → opens chat conversation
      }
      break;
    case 'accepted':
      // Show "Associated ✅" or "View Association"
      break;
    case 'rejected':
    case 'expired':
    case 'dissociated':
      // Show "Send Association Request" (enabled — will re-request)
      break;
  }
}
```

### 3.7 Get Associated Shops (Enriched)

Returns enriched data about all businesses (shops) associated with the requesting rider. Includes business details, distance from rider, and grocery data (inventory count + category breakdown).

- **Endpoint:** `GET /riders/associations/shops`
- **Auth:** Required (Bearer token — rider must be authenticated)

#### Query Parameters

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `filter` | String | No | `all` | Service type filter: `grocery` (only shops with grocery inventory + enriched data), `food` (food-type shops), `healthcare` (healthcare-type shops), `all` (all shops, no enrichment data). |
| `page` | Integer | No | `1` | Pagination page (1-indexed) |
| `limit` | Integer | No | `10` | Results per page |
| `latitude` | Number | No | — | Rider's current latitude. If omitted, fetched from Map Provider Service. |
| `longitude` | Number | No | — | Rider's current longitude. If omitted, fetched from Map Provider Service. |

#### Example Request

```
GET /riders/associations/shops?filter=grocery&page=1&limit=10&latitude=21.2514&longitude=81.6296
```

#### Success Response (200 OK)

```json
{
  "shops": [
    {
      "associationId": "69be3aae2ff4da987316809f",
      "businessUserId": "69b79df28c0f463d91112cd4",
      "business": {
        "id": "69b79df28c0f463d91112cd5",
        "business_name": "Fresh Mart Grocery",
        "type_of_business": "Grocery",
        "logo": "https://example.com/logo.png",
        "category_of_business": { "name": "Grocery" },
        "address": "123 MG Road, Raipur",
        "city_state_pincode": "Raipur, CG, 492001",
        "business_location": { "lat": 21.2514, "lon": 81.6296 },
        "business_number": { "office_mob_no": { "number": "9876543210" } },
        "avg_rating": 4.2,
        "total_ratings": 85,
        "isActive": true,
        "business_isVerified": true
      },
      "distance": "3.45 km",
      "grocery": {
        "totalProducts": 142,
        "parentCategories": [
          {
            "category": { "id": "...", "name": "Fruits & Vegetables", "image": "https://..." },
            "count": 45
          },
          {
            "category": { "id": "...", "name": "Dairy & Bakery", "image": "https://..." },
            "count": 32
          }
        ]
      }
    }
  ],
  "pagination": { "page": 1, "limit": 10, "total": 3, "totalPages": 1 }
}
```

#### Empty Response — No Associations (200 OK)

```json
{
  "shops": [],
  "pagination": { "page": 1, "limit": 10, "total": 0, "totalPages": 0 }
}
```

#### Error Responses

| Status | Message | When It Happens |
|--------|---------|-----------------|
| 400 | `"Invalid filter. Must be one of: grocery, food, healthcare, all"` | Invalid filter query param |
| 401 | `"Not authorized, no token"` | Missing or invalid Bearer token |
| 500 | `"Internal server error"` | Unexpected server error |

#### Field Notes

| Field | Notes |
|-------|-------|
| `distance` | `null` if rider location is unavailable (no coords provided + Map Provider failure) |
| `grocery` | Only present when `filter=grocery`. `null` if Grocery Service gRPC call fails. Not included for `filter=all`, `food`, or `healthcare`. |
| `grocery.totalProducts` | Count of unique `productVariant` IDs in the shop's inventory |
| `grocery.parentCategories` | Top-level category breakdown with product counts per category |
| `business` | Skipped entirely if Business Service gRPC call fails for that shop |

#### Frontend Usage — Shops List Screen

```dart
final res = await dio.get('/riders/associations/shops', queryParameters: {
  'filter': 'grocery',
  'page': 1,
  'limit': 10,
  'latitude': currentPosition.latitude,
  'longitude': currentPosition.longitude,
});

final shops = res.data['shops'] as List;
final pagination = res.data['pagination'];

for (final shop in shops) {
  final businessName = shop['business']['business_name'];
  final distance = shop['distance']; // e.g. "3.45 km" or null
  final totalProducts = shop['grocery']?['totalProducts'] ?? 0;
  final categories = shop['grocery']?['parentCategories'] ?? [];

  // Render shop card with name, distance, product count, category chips
}

// Handle pagination
if (pagination['page'] < pagination['totalPages']) {
  // Load next page
}
```

---

## 4. Socket.IO Events Reference

Listen for these events on the existing socket connection. These are emitted by the **chat service** after it processes Kafka events from the rider service.

### 4.1 `newRiderAssociationRequest`

- **When:** A new association request is created (or re-requested after rejection/dissociation/expiry)
- **Emitted To:** The recipient only (NOT the requester)
- **Payload:**

```json
{
  "message": {
    "_id": "683d2b3c4d5e6f7a8b9c0d1e",
    "conversation_id": "682a1b2c3d4e5f6a7b8c9d0e",
    "senderId": "60d5ec49f1b2c8b1a4e4b789",
    "message_type": "rider_association",
    "sub_type": "rider_association",
    "message": "New rider association request",
    "status": "sent",
    "metadata": {
      "riderAssociationId": "683d1a2b4f5e6d7c8a9b0c1d",
      "riderAssociation": {
        "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
        "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
        "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
        "requestedBy": "rider",
        "status": "pending",
        "riderInfo": {
          "name": "Ravi Kumar",
          "profileImage": "https://s3.amazonaws.com/bucket/rider-photo.jpg",
          "vehicleType": "twoWheelerRider",
          "contactNo": "9876543210",
          "ratings": { "average": 4.5, "count": 120 }
        },
        "businessInfo": {
          "businessName": "Fresh Mart Grocery",
          "logo": "https://s3.amazonaws.com/bucket/business-logo.jpg",
          "category": "grocery",
          "contactNo": "9876543211"
        }
      },
      "riderExtra": {
        "associationCount": 4,
        "address": {
          "streetAddress": "Tharamangalam, Tamil Nadu, India",
          "houseNo": "",
          "landmark": "Near bus stand",
          "pincode": "636502",
          "city": "Tharamangalam",
          "state": "Tamil Nadu",
          "locationPermission": false,
          "homeLocation": { "type": "Point", "coordinates": [0, 0] }
        },
        "currentLocation": {
          "type": "Point",
          "coordinates": [78.0123, 11.5432]
        }
      }
    },
    "created_at": "2026-03-21T10:30:00.000Z",
    "conversation": {
      "_id": "682a1b2c3d4e5f6a7b8c9d0e",
      "type": "business",
      "last_message": "New rider association request",
      "last_message_type": "rider_association"
    }
  }
}
```

**Frontend action:**
- If this conversation is currently open → render the new message in the chat
- Update the chat list to show the new last message
- Display rider's association count, address, and location from `metadata.riderExtra`
- Optionally show an in-app toast/banner

### 4.2 `riderAssociationAccepted`

- **When:** A pending request is accepted
- **Emitted To:** Both rider and business
- **Payload:**

```json
{
  "messageId": "683d2b3c4d5e6f7a8b9c0d1e",
  "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123"
}
```

**Frontend action:**
- Find the `rider_association` message card with this `associationId`
- Update the status badge from "Pending" (orange) → "Accepted" (green)
- Remove the Accept/Reject buttons
- Optionally show a "End Association" button

### 4.3 `riderAssociationRejected`

- **When:** A pending request is rejected
- **Emitted To:** Both rider and business
- **Payload:**

```json
{
  "messageId": "683d2b3c4d5e6f7a8b9c0d1e",
  "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
  "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
  "businessUserId": "60d5ec49f1b2c8b1a4e4b123"
}
```

**Frontend action:**
- Find the `rider_association` message card with this `associationId`
- Update the status badge from "Pending" (orange) → "Rejected" (red)
- Remove the Accept/Reject buttons

### 4.4 `riderAssociationDissociated`

- **When:** An active association is ended by either party
- **Emitted To:** Both rider and business
- **Payload:**

```json
{
  "messageId": "683d2b3c4d5e6f7a8b9c0d1e",
  "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
  "dissociatedBy": "60d5ec49f1b2c8b1a4e4b789"
}
```

**Frontend action:**
- Find the `rider_association` message card with this `associationId`
- Update the status badge from "Accepted" (green) → "Dissociated" (grey)
- Remove the "End Association" button
- `dissociatedBy` tells you which party ended it (useful for UI messaging)

### 4.5 `riderAssociationExpired`

- **When:** A pending request passes its 7-day TTL without a response (triggered by cron job every 15 minutes)
- **Emitted To:** Both rider and business
- **Payload:**

```json
{
  "messageId": "683d2b3c4d5e6f7a8b9c0d1e",
  "associationId": "683d1a2b4f5e6d7c8a9b0c1d"
}
```

**Frontend action:**
- Find the `rider_association` message card with this `associationId`
- Update the status badge from "Pending" (orange) → "Expired" (grey)
- Remove Accept/Reject buttons
- Optionally show a "Re-request" button

---

## 5. Push Notification Events

These are the notification operations published to the `notification.service` Kafka topic. **Share this section with the notification service owner.**

### 5.1 `rider_association_request`

- **Description:** A new rider-business association request has been created.
- **Trigger:** `riderAssociation.controller.js` → `createAssociationRequest()`
- **Sender:** The user who initiated the request (rider or business).
- **Receivers:** The target user (the other party).
- **Data Payload:**
  ```json
  {
    "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "title": "New Association Request",
    "message": "New rider association request from Ravi Kumar"
  }
  ```

### 5.2 `rider_association_accepted`

- **Description:** A pending association request has been accepted by the recipient.
- **Trigger:** `riderAssociation.controller.js` → `respondToAssociation()`
- **Sender:** The user who accepted (the recipient of the original request).
- **Receivers:** The user who originally sent the request (the requester).
- **Data Payload:**
  ```json
  {
    "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "title": "Association Accepted",
    "message": "Fresh Mart Grocery accepted your association request"
  }
  ```

### 5.3 `rider_association_rejected`

- **Description:** A pending association request has been rejected by the recipient.
- **Trigger:** `riderAssociation.controller.js` → `respondToAssociation()`
- **Sender:** The user who rejected (the recipient of the original request).
- **Receivers:** The user who originally sent the request (the requester).
- **Data Payload:**
  ```json
  {
    "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "title": "Association Declined",
    "message": "Fresh Mart Grocery declined your association request"
  }
  ```

### 5.4 `rider_association_dissociated`

- **Description:** An active association has been ended by one of the two parties.
- **Trigger:** `riderAssociation.controller.js` → `dissociateAssociation()`
- **Sender:** The user who ended the association.
- **Receivers:** The other party (the one who did NOT end it).
- **Data Payload:**
  ```json
  {
    "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "title": "Association Ended",
    "message": "Ravi Kumar has ended the rider association"
  }
  ```

### 5.5 `rider_association_expired`

- **Description:** A pending association request has expired because the recipient did not respond within the TTL (default 7 days).
- **Trigger:** `expireAssociations.cron.js` (cron job runs every 15 minutes)
- **Sender:** The rider's user ID (system-triggered but attributed to the rider).
- **Receivers:** Both parties (rider and business).
- **Data Payload:**
  ```json
  {
    "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "title": "Association Request Expired",
    "message": "Your association request has expired."
  }
  ```

### Kafka Payload Structure (for notification service owner)

All of the above are published to the `notification.service` Kafka topic with this structure:

```json
{
  "type": ["push_notification", "notification"],
  "operation": "rider_association_request",
  "sender_user": "60d5ec49f1b2c8b1a4e4b789",
  "receiver_users": ["60d5ec49f1b2c8b1a4e4b123"],
  "data": {
    "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "title": "New Association Request",
    "message": "New rider association request from Ravi Kumar"
  }
}
```

The notification service should handle these 5 new operations: `rider_association_request`, `rider_association_accepted`, `rider_association_rejected`, `rider_association_dissociated`, `rider_association_expired`.

---

## 6. Complete Flow: Rider Sends Request to Business

This is a step-by-step walkthrough of the most common flow.

### Step 1: Rider opens the business's profile and taps "Associate"

The app calls:

```
POST /riders/associations/request
Authorization: Bearer <rider_token>

{ "targetUserId": "BUSINESS_USER_ID" }
```

### Step 2: Backend processes the request

1. Finds the rider's `Rider` document → confirms `isOnboardingComplete: true`
2. Fetches the target user via gRPC → confirms `account_type: "BUSINESS"`
3. Checks for an existing association between this pair
4. Creates (or updates) the `RiderAssociation` document with `status: "pending"`
5. Fetches rider info (name, photo, vehicle, ratings) and business info (name, logo, category) for the chat message metadata
6. Emits Kafka event to chat service and notification service
7. Returns 201 with the association object

### Step 3: Chat service creates the message

1. Finds or creates a `"business"` type conversation between the rider and business user
2. Creates a message with `message_type: "rider_association"` and full metadata
3. Updates the conversation's `last_message` to "New rider association request"
4. Emits `newRiderAssociationRequest` socket event to the business user
5. Sends push notification with operation `rider_association_request` to the business user

### Step 4: Business user sees the request

**If online (socket connected):**
- The `newRiderAssociationRequest` event fires
- Chat list updates with the new message
- If the conversation is open, the association card renders with rider info and Accept/Reject buttons

**If offline:**
- Push notification arrives: "New rider association request from Ravi Kumar"
- Tapping the notification opens the chat conversation
- The association card is visible in the message history

### Step 5: Business user accepts

```
PATCH /riders/associations/683d1a2b4f5e6d7c8a9b0c1d/respond
Authorization: Bearer <business_token>

{ "action": "accept" }
```

### Step 6: Both parties see the update

1. Association card's badge changes from "Pending" → "Accepted"
2. A new text message appears: "Ravi Kumar is now associated with Fresh Mart Grocery"
3. The rider gets a push notification: "Fresh Mart Grocery accepted your association request"

---

## 7. Complete Flow: Business Sends Request to Rider

The flow is identical to Section 6, except the roles are reversed:

1. **Business** calls `POST /riders/associations/request` with `{ "targetUserId": "RIDER_USER_ID" }`
2. Backend sets `requestedBy: "business"`, `riderUserId: RIDER_USER_ID`, `businessUserId: BUSINESS_USER_ID`
3. The **rider** receives the socket event and push notification
4. The **rider** is the one who can accept or reject
5. The **business** gets the acceptance/rejection notification

Everything else (Kafka events, chat messages, socket events) works the same way.

---

## 8. Chat Message Structure

### 8.1 The Association Request Message

This is the message created when a new association request is sent. It lives in a conversation of type `"business"`.

```json
{
  "_id": "683d2b3c4d5e6f7a8b9c0d1e",
  "conversation_id": "682a1b2c3d4e5f6a7b8c9d0e",
  "senderId": "60d5ec49f1b2c8b1a4e4b789",
  "message_type": "rider_association",
  "sub_type": "rider_association",
  "message": "New rider association request",
  "status": "sent",
  "metadata": {
    "riderAssociationId": "683d1a2b4f5e6d7c8a9b0c1d",
    "riderAssociation": {
      "associationId": "683d1a2b4f5e6d7c8a9b0c1d",
      "riderUserId": "60d5ec49f1b2c8b1a4e4b789",
      "businessUserId": "60d5ec49f1b2c8b1a4e4b123",
      "requestedBy": "rider",
      "status": "pending",
      "riderInfo": {
        "name": "Ravi Kumar",
        "profileImage": "https://s3.amazonaws.com/bucket/rider-photo.jpg",
        "vehicleType": "twoWheelerRider",
        "contactNo": "9876543210",
        "ratings": { "average": 4.5, "count": 120 }
      },
      "businessInfo": {
        "businessName": "Fresh Mart Grocery",
        "logo": "https://s3.amazonaws.com/bucket/business-logo.jpg",
        "category": "grocery",
        "contactNo": "9876543211"
      }
    },
    "riderExtra": {
      "associationCount": 4,
      "address": {
        "streetAddress": "Tharamangalam, Tamil Nadu, India",
        "houseNo": "",
        "landmark": "Near bus stand",
        "pincode": "636502",
        "city": "Tharamangalam",
        "state": "Tamil Nadu",
        "locationPermission": false,
        "homeLocation": { "type": "Point", "coordinates": [0, 0] }
      },
      "currentLocation": {
        "type": "Point",
        "coordinates": [78.0123, 11.5432]
      }
    }
  },
  "created_at": "2026-03-21T10:30:00.000Z"
}
```

### 8.2 How `metadata.riderAssociation.status` Updates

The `status` field inside `metadata.riderAssociation` is updated in-place by the chat service when it processes Kafka events. The message `_id` stays the same — only the metadata changes.

| Kafka Event | New Status Value |
|-------------|-----------------|
| `CREATE_RIDER_ASSOCIATION_REQUEST` | `"pending"` (initial) |
| `RIDER_ASSOCIATION_ACCEPTED` | `"accepted"` |
| `RIDER_ASSOCIATION_REJECTED` | `"rejected"` |
| `RIDER_ASSOCIATION_DISSOCIATED` | `"dissociated"` |
| `RIDER_ASSOCIATION_EXPIRED` | `"expired"` |

### 8.3 Confirmation Text Messages

After acceptance, rejection, or dissociation, the chat service also creates a **new text message** in the same conversation:

| Event | Message Text | `message_type` |
|-------|-------------|-----------------|
| Accepted | `"Ravi Kumar is now associated with Fresh Mart Grocery"` | `"text"` |
| Rejected | `"Association request was declined"` | `"text"` |
| Dissociated | `"Rider association has been ended"` | `"text"` |

These are separate messages from the original `rider_association` card. The conversation's `last_message` is updated to this confirmation text.

### 8.4 Conversation Type

Association messages live in conversations of type `"business"`. This is NOT the same as `"order"` (used for selfpickup and grocery orders). When fetching the chat list, filter by conversation type `"business"` to see these conversations.

### 8.5 Chat List Preview

In the chat list, the `last_message_type` will be `"rider_association"` when the latest message is an association request. Display `"[ Rider Association ]"` as the preview text (similar to how `"[ Self-Pickup Order ]"` is shown for selfpickup messages).

After acceptance/rejection/dissociation, `last_message_type` changes to `"text"` and `last_message` contains the confirmation text.

---

## 9. UI Screens Required

### 9.1 Association Card (Chat Bubble)

When rendering messages in chat, check for `message_type === "rider_association"`. Render a card with:

**Header:**
- Handshake icon + "Rider Association" title
- "Requested by rider/business" subtitle
- Status badge (Pending/Accepted/Rejected/Expired/Dissociated)

**Body — Rider Section:**
- Profile image (or fallback avatar)
- Name
- Vehicle type (e.g. "Two Wheeler")
- Contact number
- Ratings (e.g. "4.5 ★ (120)")
- Association count from `metadata.riderExtra.associationCount` (e.g. "4 associations")
- Address from `metadata.riderExtra.address` (city, state, pincode)
- Location from `metadata.riderExtra.currentLocation.coordinates` (if available)

**Body — Business Section:**
- Logo (or fallback avatar)
- Business name
- Category
- Contact number

**Footer — Action Buttons (conditional):**

| Association Status | Show to Recipient | Show to Requester | Show to Either Party |
|--------------------|--------------------|--------------------|-----------------------|
| `pending` | Accept + Reject buttons | Nothing (just "Pending" badge) | — |
| `accepted` | — | — | "End Association" button |
| `rejected` | — | — | Nothing (just "Rejected" badge) |
| `expired` | — | — | Nothing (just "Expired" badge) |
| `dissociated` | — | — | Nothing (just "Dissociated" badge) |

**How to determine if the logged-in user is the recipient:**
```dart
final isRecipient = (association.requestedBy == 'rider' && currentUserId == association.businessUserId)
    || (association.requestedBy == 'business' && currentUserId == association.riderUserId);
```

**Status badge colors:**

| Status | Color | Icon |
|--------|-------|------|
| `pending` | Orange/Yellow | Hourglass ⏳ |
| `accepted` | Green | Check ✅ |
| `rejected` | Red/Pink | Cross ❌ |
| `expired` | Grey | Hourglass ⌛ |
| `dissociated` | Grey | No-entry 🚫 |

### 9.2 Association List Screen

A new screen (accessible from profile or settings) showing all associations with filter tabs:

- **Active** — `status=accepted`
- **Pending** — `status=pending`
- **Past** — `status=rejected,expired,dissociated` (fetch separately or fetch all and filter client-side)

Each list item shows:
- The other party's name and profile image
- Status badge
- "Requested by you" / "Requested by them" label
- Tap to open the business conversation in chat

### 9.3 Profile Screen — "Associate" Button

On a rider's profile (if viewed by a business) or a business's profile (if viewed by a rider), show an "Associate" button. Before showing, you may call `GET /riders/associations?status=pending` or `GET /riders/associations?status=accepted` and check if an association already exists with this user. Adjust the button accordingly:

| Existing Status | Button State |
|-----------------|-------------|
| None | "Send Association Request" (enabled) |
| `pending` + you are requester | "Request Pending" (disabled) |
| `pending` + you are recipient | "View Request" (opens chat) |
| `accepted` | "Associated ✅" (or "View Association") |
| `rejected` / `expired` / `dissociated` | "Send Association Request" (enabled — will re-request) |

---

## 10. Edge Cases & Error Handling

### 10.1 Duplicate Request

**Scenario:** Rider taps "Associate" twice quickly, or network retries send the request twice.

**What happens:** The first request creates the document. The second request hits the compound unique index `{ riderUserId, businessUserId }` and gets caught — returns `400 "Association request is already pending."`.

**Frontend handling:** Show the error message. The first request succeeded, so the UI should already reflect the pending state.

### 10.2 Re-Request After Rejection

**Scenario:** A business rejected a rider's request. The rider wants to try again later.

**What happens:** The rider calls `POST /riders/associations/request` again with the same `targetUserId`. The backend finds the existing document with `status: "rejected"`, updates it back to `"pending"`, sets a new `expiresAt`, and emits all Kafka events again. A new chat message is created.

**Frontend handling:** The profile screen should show "Send Association Request" (enabled) when the existing status is `rejected`, `expired`, or `dissociated`.

### 10.3 Re-Request After Expiry

**Scenario:** A request was pending for 7 days. The cron job marked it as `expired`. The requester wants to try again.

**What happens:** Identical to 10.2 — the existing document is updated back to `"pending"`.

### 10.4 Re-Request After Dissociation

**Scenario:** An active partnership was ended. Either party wants to re-associate.

**What happens:** Identical to 10.2 — the existing document is updated back to `"pending"`.

### 10.5 Rider Onboarding Incomplete

**Scenario:** A user has a Rider record but hasn't finished all 7 onboarding steps.

**What happens:** Returns `400 "Rider onboarding is not complete."` This applies whether the rider is the requester OR the target. Both sides must have a complete rider profile.

**Frontend handling:** Show a message prompting the rider to complete onboarding first. Optionally navigate to the onboarding screen.

### 10.6 Wrong Role Combination

**Scenario:** Two riders try to associate, or two businesses try to associate, or a regular user (neither rider nor business) tries.

**What happens:** Returns `400 "One party must be a rider and the other a business user."`

**Frontend handling:** This should ideally never happen if the "Associate" button is only shown on the correct profile types. Show the error as a toast if it does.

### 10.7 Request to Self

**Scenario:** A user somehow sends a request where `targetUserId` equals their own user ID.

**What happens:** Returns `400 "Cannot send association request to yourself."`

**Frontend handling:** Don't show the "Associate" button on the user's own profile.

### 10.8 Unauthorized Response Attempt

**Scenario:** The requester (not the recipient) tries to accept/reject their own request. Or a third party tries.

**What happens:** Returns `403 "You are not authorized to respond to this request."`

**Frontend handling:** Only show Accept/Reject buttons to the recipient. If somehow triggered, show the error.

### 10.9 Responding to an Expired Request

**Scenario:** A business opens an old chat, sees a pending request, and taps Accept. But the request expired between when they opened the chat and when they tapped.

**What happens:** Returns `400 "This association request has expired."` The socket event `riderAssociationExpired` may or may not have been received yet.

**Frontend handling:** Show a toast "This request has expired". Update the card badge to "Expired". The user can ask the other party to re-request.

### 10.10 User Offline When Request Arrives

**Scenario:** The target user is not connected via socket when the request is sent.

**What happens:** The socket event `newRiderAssociationRequest` has no connected sockets to emit to — it's silently skipped. The push notification (`rider_association_request`) is sent as a fallback. When the user opens the app and loads their chat list, the message will appear in their `"business"` conversation from the normal message fetch.

**Frontend handling:** No special handling needed. Push notification handles the offline case. Messages are always available via the GET messages API.

### 10.11 Kafka Failure After Association Created

**Scenario:** The rider service creates/updates the `RiderAssociation` document, but the Kafka event to the chat service fails.

**What happens:** The association is created (source of truth in rider service is fine), but no chat message appears. The rider gets a 201 response. This is a fire-and-forget pattern — the Kafka emit is wrapped in try-catch.

**Frontend handling:** The rider sees the success response. If the chat message doesn't appear, the association list (`GET /riders/associations`) still shows it. The chat message is a nice-to-have, not the source of truth.

### 10.12 Multiple Associations

**Scenario:** A rider associates with 3 different businesses, or a business associates with 5 different riders.

**What happens:** Each pair gets its own `RiderAssociation` document and its own `"business"` conversation. They are completely independent.

**Frontend handling:** The association list screen shows all of them. Each conversation in the chat list is separate.

### 10.13 Conversation Already Exists

**Scenario:** The rider and business already have a `"business"` type conversation from a previous interaction (e.g. a prior association that was dissociated and re-requested).

**What happens:** The chat service reuses the existing conversation. The new association message appears in the same conversation alongside the old messages.

---

## 11. Testing Checklist

### API Tests

- [ ] **Rider → Business request:** POST request returns 201, `requestedBy: "rider"`, `status: "pending"`
- [ ] **Business → Rider request:** POST request returns 201, `requestedBy: "business"`, `status: "pending"`
- [ ] **Self-request blocked:** POST with own user ID returns 400
- [ ] **Duplicate request blocked:** Second POST for same pair returns 400 "already pending"
- [ ] **Already associated blocked:** POST when status is `accepted` returns 400
- [ ] **Wrong roles blocked:** Two riders or two businesses returns 400
- [ ] **Incomplete onboarding blocked:** Rider without complete onboarding returns 400
- [ ] **Accept request:** PATCH respond with `accept` returns 200, `status: "accepted"`
- [ ] **Reject request:** PATCH respond with `reject` returns 200, `status: "rejected"`
- [ ] **Invalid action blocked:** PATCH respond with `"maybe"` returns 400
- [ ] **Non-recipient blocked:** Requester trying to respond returns 403
- [ ] **Expired request blocked:** Responding to expired request returns 400
- [ ] **Re-request after rejection:** POST again returns 201, same `_id`, `status: "pending"`
- [ ] **Re-request after dissociation:** POST again returns 201, same `_id`, `status: "pending"`
- [ ] **Re-request after expiry:** POST again returns 201, same `_id`, `status: "pending"`
- [ ] **Dissociate:** PATCH dissociate returns 200, `status: "dissociated"`
- [ ] **Dissociate non-active blocked:** PATCH dissociate on pending/rejected returns 400
- [ ] **List associations:** GET returns paginated results, filter by status works
- [ ] **Get single association:** GET /:id returns the correct document
- [ ] **Unauthorized access blocked:** GET /:id for a non-party user returns 403

### Socket Event Tests

- [ ] **Request → `newRiderAssociationRequest`** fires on recipient's socket
- [ ] **Accept → `riderAssociationAccepted`** fires on both sockets
- [ ] **Reject → `riderAssociationRejected`** fires on both sockets
- [ ] **Dissociate → `riderAssociationDissociated`** fires on both sockets
- [ ] **Expire (cron) → `riderAssociationExpired`** fires on both sockets

### Push Notification Tests

- [ ] **Request → `rider_association_request`** notification received by target
- [ ] **Accept → `rider_association_accepted`** notification received by requester
- [ ] **Reject → `rider_association_rejected`** notification received by requester
- [ ] **Dissociate → `rider_association_dissociated`** notification received by other party
- [ ] **Expire → `rider_association_expired`** notification received by both parties

### Chat Message Tests

- [ ] **Request creates** `rider_association` message with correct metadata
- [ ] **Accept updates** message metadata status to `accepted` and creates confirmation text message
- [ ] **Reject updates** message metadata status to `rejected` and creates confirmation text message
- [ ] **Dissociate updates** message metadata status to `dissociated` and creates text message
- [ ] **Expire updates** message metadata status to `expired`
- [ ] **Conversation type** is `"business"` (not `"order"`)
- [ ] **Re-request** creates a new message (old message keeps its old status)

### UI Tests

- [ ] **Association card renders** correctly with rider info, business info, and status badge
- [ ] **Accept/Reject buttons** only show to the recipient when status is `pending`
- [ ] **End Association button** only shows when status is `accepted`
- [ ] **Socket events update** the card badge and buttons in real-time
- [ ] **Chat list preview** shows `"[ Rider Association ]"` for association messages
- [ ] **Offline user** receives push notification and sees message on next app open
- [ ] **Association list screen** shows all associations with correct filters
- [ ] **Profile "Associate" button** reflects the current association state
