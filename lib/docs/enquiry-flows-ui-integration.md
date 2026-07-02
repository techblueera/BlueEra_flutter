# Enquiry / Booking Cards — UI Integration Note

Covers **Vehicle, Hotel, Education, Hospital**. All of these are **enquiry-only chat-card flows**.
They are NOT orders.

> ⚠️ **IMPORTANT:** Do **not** wire any of these "Book / Enquire" buttons into the order /
> self-pickup / book-a-rider / delivery / cart / payment flow. There is **no payment, no
> delivery, no rider, no pickup, no availability/inventory check** anywhere in these flows.
> The button only creates an enquiry; the rest happens as a chat card the owner accepts/declines.

---

## The one common flow (same for all 4 services)

1. Buyer taps **Enquire / Book** on a listing → app calls `POST <create endpoint>` (Bearer token).
2. Backend creates the enquiry (`status: "pending"`) and a **chat card** appears in the
   buyer↔owner **business** conversation.
3. Owner gets the card + push, and taps **Accept** or **Decline** → `PUT .../status`.
4. Card flips live for both sides via a socket event.

All endpoints require the `Authorization: Bearer <token>` header. `customerId` (buyer) and
`ownerId`/`sellerId`/`businessId` (owner) are derived from the token + listing — the client
does **not** send them.

---

## Per-service contract

### 1. Vehicle  — base `/vehicles/bookings`
| | |
|---|---|
| Create | `POST /vehicles/bookings` |
| Body | `{ inventoryId, intent, offerPrice?, note?, photos?[] }` — `intent` ∈ `BUY \| TEST_DRIVE \| EXCHANGE \| INFO` |
| My (buyer) list | `GET /vehicles/bookings/me?status=&page=&limit=` |
| Received (owner) list | `GET /vehicles/bookings/seller/me` |
| Get one | `GET /vehicles/bookings/:id` |
| Accept/Decline (owner) | `PUT /vehicles/bookings/:id/status` body `{ status: "accepted" \| "declined" }` |
| Cancel (buyer) | `PUT /vehicles/bookings/:id/cancel` |
| Status values | `pending → accepted \| declined \| cancelled` |
| Chat card `message_type` | `vehicle_booking` |
| Card data path | `metadata.booking` (id at `metadata.vehicleBookingId`) |
| Sockets | new: `newVehicleBookingReceived` `{message}` · flip: `vehicleBookingStatusUpdated` `{messageId,bookingId,status}` |

### 2. Hotel — has **two** flows

**2a. Hotel Enquiry — base `/hotel-enquiries`**
| | |
|---|---|
| Create | `POST /hotel-enquiries` body `{ hotel_id, roomType?[], purpose?[], amenities?[], timeline?[], note?, photos?[] }` (≥1 selection or a note required) |
| Lists | `GET /hotel-enquiries/me` · `GET /hotel-enquiries/owner/me` · `GET /hotel-enquiries/:id` |
| Accept/Decline (owner) | `PUT /hotel-enquiries/:id/status` body `{ status: "accepted" \| "declined" }` |
| Status values | `pending → accepted \| declined` (no cancel) |
| Chat card `message_type` | `hotel_enquiry` |
| Card data path | `metadata.hotelEnquiry` (id at `metadata.hotelEnquiryId`) |
| Sockets | `newHotelEnquiryReceived` · `hotelEnquiryStatusUpdated` |

**2b. Hotel Booking — base `/hotel-bookings`** (carries dates/guests, still no payment/availability)
| | |
|---|---|
| Create | `POST /hotel-bookings` body `{ hotel_id, roomType?, checkIn?, checkOut?, guests?, note?, photos?[] }` (`checkOut` must be after `checkIn`) |
| Lists | `GET /hotel-bookings/me` · `GET /hotel-bookings/owner/me` · `GET /hotel-bookings/:id` |
| Status update | `PUT /hotel-bookings/:id/status` — owner sends `accepted`/`declined`; **customer** sends `cancelled` |
| Status values | `pending → accepted \| declined \| cancelled` |
| Chat card `message_type` | `hotel_booking` |
| Card data path | `metadata.booking` (id at `metadata.hotelBookingId`) |
| Sockets | `newHotelBookingReceived` · `hotelBookingStatusUpdated` |

### 3. Education — base `/education-enquiries`
| | |
|---|---|
| Create | `POST /education-enquiries` body `{ listing_id, courses?[], admissionFor?[], requirements?[], timeline?[], note?, photos?[] }` (≥1 selection or a note required) |
| Lists | `GET /education-enquiries/me` · `GET /education-enquiries/owner/me` · `GET /education-enquiries/:id` |
| Accept/Decline (owner) | `PUT /education-enquiries/:id/status` body `{ status: "accepted" \| "declined" }` |
| Status values | `pending → accepted \| declined` (no cancel) |
| Chat card `message_type` | `education_enquiry` |
| Card data path | `metadata.educationEnquiry` (id at `metadata.educationEnquiryId`) |
| Sockets | `newEducationEnquiryReceived` · `educationEnquiryStatusUpdated` |

### 4. Hospital — base `/hospital-enquiries`
| | |
|---|---|
| Create | `POST /hospital-enquiries` body `{ hospital_id, departments?[], purpose?[], timeline?[], note?, photos?[] }` (≥1 selection or a note required) |
| Lists | `GET /hospital-enquiries/me` · `GET /hospital-enquiries/owner/me` · `GET /hospital-enquiries/:id` |
| Accept/Decline (owner) | `PUT /hospital-enquiries/:id/status` body `{ status: "accepted" \| "declined" }` |
| Status values | `pending → accepted \| declined` (no cancel) |
| Chat card `message_type` | `healthcare_enquiry` |
| Card data path | `metadata.healthcareEnquiry` (id at `metadata.healthcareEnquiryId`); selections under `metadata.healthcareEnquiry.selections` |
| Sockets | `newHealthcareEnquiryReceived` · `healthcareEnquiryStatusUpdated` |

---

## Notes for the chat card widget

- Photos may be sent as **multipart** instead of JSON: send the JSON fields as a string
  `payload` part plus up to **5** `photos` files. JSON body works too.
- The card object (`metadata.<x>Enquiry` or `metadata.booking`) includes a denormalized
  **snapshot** (name / image / priceText / location) so the card renders without re-fetching.
  `priceText` is **display only** — nothing is charged.
- Render only **Accept / Decline** for the owner (and **Cancel** for the buyer where the flow
  supports it — vehicle and hotel-booking only).
- On the `...StatusUpdated` socket event, find the message by `messageId` (or the `*EnquiryId`/
  `bookingId`) and update its status in place; both parties receive it.
- All four cards are structurally identical — one reusable "enquiry card" widget parameterized
  by `message_type` and the metadata key is enough; no per-service screens needed.
</content>
</invoke>



