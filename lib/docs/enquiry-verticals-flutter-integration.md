# Enquiry / Booking Cards — Flutter Integration Guide (business / healthcare / hotel / education / vehicle)

Backend status: **all four enquiry verticals are code-complete on `prod-staging`** (chat-side card fix merged in be_chat_service PR #39, other-service id fix merged in PR #8). Vehicle (`vehicles/bookings`) is a **booking**, not an enquiry — same overall pipeline, one extra buyer-side action (Cancel) — and shares the same be_chat_service deploy. All REST bases below are **confirmed live at the gateway** (`https://be.beapp.in/api/...` answers 401/400-auth, not 404). Card creation/flip additionally needs the **be_chat_service deploy** that includes PR #39. Enquiries / bookings sent before that deploy will NOT appear as cards — always test with fresh ones.

The overall flow is identical to the service-enquiry guide you already have
(`service-enquiry-flutter-integration.md`): `POST` create → open the business
chat (`route = discover`) → card arrives via socket + history → owner
accepts/declines via `PUT .../status` → both cards flip via socket. **Vehicle
additionally lets the buyer cancel via `PUT .../cancel`** while the booking
is still `pending` — a fifth possible transition that also lands on the
same `vehicleBookingStatusUpdated` socket event.

**What differs per vertical is only:** base path, the listing id field name,
photo transport, the selection fields, and the card/socket/push names.
Everything in §"Common behavior" below is byte-identical across all five
verticals (including earn).

---

## 1. Per-vertical cheat sheet

| | **Other business** | **Healthcare** | **Hotel** | **Education** | **Vehicle** |
|---|---|---|---|---|---|
| Owning service | be_other_service | be_user_service | be_hotel_service | be_education_service | be_vehicle_service |
| REST base | `other-service/other-enquiries` | `user-service/business-enquiries` | `hotel-service/api/hotel-enquiries` (note the extra `/api` — same as all hotel-service calls) | `education-service/education-enquiries` | `vehicle-service/vehicles/bookings` |
| Listing id field | `business_id` | `business_id` | `hotel_id` | `listing_id` | `inventoryId` |
| …which id is it | other-service BusinessProfile `_id` (backend now also accepts owner userId or user-service Business `_id`) | user-service Business `_id` | HotelProfile `_id` | School/listing `_id` | Vehicle inventory listing `_id` (from vehicle detail screen — **not** the catalog variant id) |
| Content type | **JSON only** | **JSON only** | JSON **or** multipart | JSON **or** multipart | **JSON only** |
| Photos | pre-uploaded **URLs** in `photos[]` (presign via `GET other-service/upload/init`) | pre-uploaded **URLs** in `photos[]` (presign via `/upload/init`) | multipart `payload` + `photos` file parts (≤5, ≤10 MB each) | multipart `payload` + `photos` file parts (≤5, ≤10 MB each) | pre-uploaded **URLs** in `photos[]` |
| Selections | open map `selections: { "Group": ["value"] }` | open map `selections: { "Group": ["value"] }` | fixed arrays: `roomType`, `purpose`, `amenities`, `timeline` | fixed arrays: `courses`, `admissionFor`, `requirements`, `timeline` | fixed field `intent` (`BUY` \| `TEST_DRIVE` \| `EXCHANGE` \| `INFO`) + optional `offerPrice` (number) |
| Not-found message | `Business not found` | `Business not found` | `Hotel not found` | `Listing not found` | `Vehicle not found` |
| Card `message_type` / `sub_type` | `business_enquiry` | `healthcare_enquiry` | `hotel_enquiry` | `education_enquiry` | `vehicle_booking` |
| Metadata keys | `metadata.businessEnquiryId` / `metadata.businessEnquiry` | `metadata.healthcareEnquiryId` / `metadata.healthcareEnquiry` | `metadata.hotelEnquiryId` / `metadata.hotelEnquiry` | `metadata.educationEnquiryId` / `metadata.educationEnquiry` | `metadata.vehicleBookingId` / `metadata.booking` |
| Socket: new card | `newBusinessEnquiryReceived` | `newHealthcareEnquiryReceived` | `newHotelEnquiryReceived` | `newEducationEnquiryReceived` | `newVehicleBookingReceived` |
| Socket: status flip | `businessEnquiryStatusUpdated` | `healthcareEnquiryStatusUpdated` | `hotelEnquiryStatusUpdated` | `educationEnquiryStatusUpdated` | `vehicleBookingStatusUpdated` |
| Push operations | `business_enquiry` / `business_enquiry_status` | `healthcare_enquiry` / `healthcare_enquiry_status` | `hotel_enquiry` / `hotel_enquiry_status` | `education_enquiry` / `education_enquiry_status` | `vehicle_booking` / `vehicle_booking_status` |
| Status values | `pending → accepted \| declined` | `pending → accepted \| declined` | `pending → accepted \| declined` | `pending → accepted \| declined` | `pending → accepted \| declined \| cancelled` (buyer-cancel only) |
| Owner / seller inbox | `GET .../owner/me` | `GET .../owner/me` | `GET .../owner/me` | `GET .../owner/me` | `GET .../seller/me` |
| Buyer inbox | `GET .../me` | `GET .../me` | `GET .../me` | `GET .../me` | `GET .../me` |
| Buyer cancel | ❌ | ❌ | ❌ | ❌ | ✅ `PUT .../:id/cancel` (pending only) |

> ⚠️ Vehicle uses `seller/me` (not `owner/me`) and the listing field is
> `inventoryId` (not `business_id` / `hotel_id` / `listing_id`). Earn is the
> other outlier (`/provider/me`, `provider_id`). The four enquiry verticals
> all use `/owner/me`.

---

## 2. Create requests — one example per shape

**JSON-only verticals with a `selections` map (other business, healthcare)**
— photos are URLs you already uploaded via the presign flow
(`GET .../upload/init` → PUT bytes → keep `publicUrl`), max 5:

```json
POST other-service/other-enquiries          // or user-service/business-enquiries
{
  "business_id": "<listing id>",
  "selections": { "Services": ["Home Loan"], "Purpose": ["Compare rates"] },
  "note": "optional free text",
  "photos": ["https://<bucket>.s3....jpg"]
}
```

**Multipart verticals (hotel, education)** — same convention as the earn-service
doc: string part `payload` + repeated file part `photos` (server uploads to S3):

```json
// payload part for hotel:
{ "hotel_id": "<HotelProfile id>", "roomType": ["Deluxe"], "purpose": ["Family trip"],
  "amenities": ["Pool"], "timeline": ["This weekend"], "note": "..." }

// payload part for education:
{ "listing_id": "<School id>", "courses": ["B.Tech CSE"], "admissionFor": ["2026-27"],
  "requirements": ["Hostel"], "timeline": ["Immediate"], "note": "..." }
```

**Vehicle booking (JSON only)** — `intent` is the only required field
besides the listing id; `offerPrice` is optional and only meaningful for
`BUY` / `EXCHANGE`:

```json
POST vehicle-service/vehicles/bookings
{
  "inventoryId": "<Vehicle listing id>",
  "intent": "BUY",              // BUY | TEST_DRIVE | EXCHANGE | INFO
  "offerPrice": 750000,           // optional
  "note": "optional free text",
  "photos": ["https://.../trade-in.jpg"]
}
```

Validation is uniform: listing id required + valid ObjectId (400), at least one
selection **or** a note (400 — for the 4 enquiry verticals; vehicle requires a
valid `intent` instead), max 5 photos (400), cannot enquire on your own
listing (400), listing missing (404 — show "no longer available" and refresh).

---

## 3. Common behavior (identical to the service-enquiry guide)

- **Create success = 201** `{ success, message: "Enquiry sent" | "Booking placed", data: { enquiryId | bookingId, status: "pending" } }`. Check the 2xx range/`success`, never `== 200`. No `conversationId` in the response — open the owner's business chat via `route = discover` as usual.
- **Status:** `PUT {base}/{enquiryId}/status` body `{ "status": "accepted" | "declined" }` → 200. `403` not the owner, `404` unknown id, `409` the opposite decision already made (refresh card). **Retrying the same decision is safe**: 200 + the socket event is re-emitted. **Vehicle** additionally allows `PUT {base}/{bookingId}/cancel` from the buyer (no body needed) → sends `status: "cancelled"` on the same socket event, `409` if already settled.
- **Card envelope:** standard message shape (`conversation_id`, `senderId` = customer/buyer, `created_at`, snake_case) with `metadata.<x>EnquiryId` / `metadata.vehicleBookingId`, `metadata.<x>Enquiry` / `metadata.booking` (payload incl. `status`), `order_status` (true once accepted), `is_cancelled` (true once the buyer cancels — vehicle only). Switch your parser on `message_type`.
- **Card payload fields** mirror the create request per vertical plus the listing snapshot: business/healthcare → `listingId, listingName, listingImage, location, category, selections`; hotel → `hotelId, hotelName, hotelImage, priceText, location` + the four arrays; education → `listingId, listingName, listingImage, location, category` + the four arrays; vehicle → `inventoryId, snapshot: { title, image, priceText, condition, location }, intent, offerPrice`. All + `photos`, `note`, `status`, `customerId` / `buyerId`, `ownerId` / `sellerId`.
- **Sockets:** new-card event payload `{ message }` — **dedupe by `message._id`** (the sender gets an echo). Status event payload `{ messageId, enquiryId | bookingId, status }` — find by `messageId`, set `metadata.<x>Enquiry.status` (or `metadata.booking.status`), rebuild the card. Dropping an unmatched status event is fine (history carries the final status).
- **Cold open:** all five card types are now returned by the normal message-history endpoint — the card must render from history, test it.
- **Lists (optional inbox screens):** `GET .../me` (sent), `GET .../owner/me` (received — vehicle uses `/seller/me`), `GET .../{enquiryId}` (participant only). `{ success, data: [...], pagination: { totalCount, page, limit, totalPages } }`, `?status=` filter, `limit` ≤ 100, newest first.

---

## 4. Integration checklist

1. ☐ Per vertical, use the correct **listing id field name and id space** (see table — this caused the other-service 404).
2. ☐ Photos: URLs-in-JSON for other/healthcare/vehicle, multipart for hotel/education. Never mix.
3. ☐ Parser: five `message_type` cases, each reading its own `metadata.<x>Enquiry` / `metadata.booking` key.
4. ☐ Register all 10 socket listeners (5 × new-card + 5 × status). Dedupe new-card by `message._id`.
5. ☐ Push routing: 10 operations (table row "Push operations") → route to the business conversation like pickup-order pushes.
6. ☐ Owner / seller inbox path — `/owner/me` for the four enquiry verticals, `/seller/me` for vehicle. Only earn uses `/provider/me`.
7. ☐ **Vehicle only**: render the buyer-side **Cancel** button on the card while `pending`; wire it to `PUT {base}/{bookingId}/cancel`.
8. ☐ Test cold open per vertical (card renders from history after app restart).
9. ☐ Test only with enquiries / bookings created **after** the backend deploy.
