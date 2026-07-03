# Home-Service Enquiry — Flutter Integration Guide

Enquiry flow for **home-service providers** (plumber, electrician, appliance repair, …) from the Discover → **Home Service details** screen's **Enquire** button (`home_service_discover_details_screen_v2.dart`).

**This is a delta guide.** It is the *same* pipeline as the self-profession and professional-consultant enquiries — **same endpoints, same `service_enquiry` chat card, same socket events**. Everything not called out here works exactly as in [`service-enquiry-flutter-integration.md`](./service-enquiry-flutter-integration.md) (§2–§7) and [`profession-consultant-enquiry-flutter-integration.md`](./profession-consultant-enquiry-flutter-integration.md).

> **Backend delta (the only change needed):** provider validation on `POST earn-service/service-enquiries` must accept a **live home-service provider** as a valid `provider_id` — the same way it was widened to accept professional consultants. The **chat service needs no changes**; if it already runs the service-enquiry build, home service only needs the earn-service provider-validation deploy.

---

## 1. The flow at a glance

```
Home-service detail screen loads
Customer taps "Enquire" (the pill that used to open chat directly)
  → ServiceEnquirySheet: tick option chips (+ optional note, ≤1 optional photo)
  → POST earn-service/service-enquiries                     (§3 — same endpoint)
  → on 2xx: open the provider's BUSINESS chat (route = discover)
  → "service_enquiry" card arrives via socket + history      (unchanged)
Provider taps Accept / Decline → PUT …/{enquiryId}/status    (unchanged)
  → both cards flip via "serviceEnquiryStatusUpdated"        (unchanged)
```

The Flutter side reuses the shared sheet via a generic entry point:

```dart
ServiceEnquirySheet.openForProvider(
  context,
  userId: providerUserId,          // home-service provider's userId
  providerName: storeOrProviderName,
  category: providerProfession,    // drives the option chips (§2)
  chatName: storeOrProviderName,   // seeds the business chat opened on success
  chatProfile: storeLogoOrAvatar,
);
```

No home-service-specific submit path exists — it calls the same `DiscoverController.submitServiceEnquiry(providerId, selections, note, photoPaths)` every other provider type uses.

---

## 2. Options source — populate the sheet's chips

Same as the other flows: fetch the provider's predefined catalog by **profession / service category** and render the returned groups as tick-able chips, then always append the generic **Request Type** group.

`GET earn-service/predefined/{category}` (via `DiscoverRepo.fetchPredefinedCategory`) — `category` = the home-service provider's profession/service category (e.g. `PLUMBER`). Cached per category (fetched at most once per session); an empty/unknown category yields no fetched groups and the sheet falls back to just the generic Request Type group.

The always-on generic **Request Type** options (well-suited to home service):

```
Installation · Repair · Maintenance · Visit & Quote · Urgent / Same-day
```

> **Adding more selection groups:** the sheet renders whatever `{apiKey, title, options}` groups the catalog returns, plus the standard Request Type group. If you want an extra home-service group (e.g. **Preferred Time**: Morning / Afternoon / Evening / Weekend), it can be added — **but the backend must persist and echo that `apiKey`** in `metadata.serviceEnquiry` for the card to render it. Until then, stick to the catalog groups + `requestType`, which the card already knows how to render (empty groups are skipped).

---

## 3. Create enquiry — same endpoint, home-service payload

### `POST earn-service/service-enquiries`

Selections are sent keyed by the enquiry group's api key (as returned by the catalog, e.g. `servicesOffered`, plus `requestType`). Absent groups are treated as empty — no need to send the self-work-only keys.

```json
{
  "provider_id": "6624a1f0c2b9e4f1a0d33b21",
  "servicesOffered": ["Pipe leakage repair", "Tap installation"],
  "requestType": ["Repair", "Urgent / Same-day"],
  "note": "Kitchen sink pipe leaking since morning."
}
```

**Note** and **photo** are **optional**:
- The submit is allowed when there is **at least one ticked option OR a non-empty note OR a photo** (same rule as self-work/consultant; otherwise `400`).
- With a photo: same multipart shape — a `payload` string part + a `photos` file part. The client sends **at most 1** photo for home service; the backend cap stays **5 files / 10 MB each**; the URL comes back in `metadata.serviceEnquiry.photos`.

Server-side rules (identical to the other flows):
- `provider_id` must be a valid ObjectId belonging to a **live** provider — now *also* a **home-service provider** (active, not deleted). Otherwise `404 { "message": "Provider not found" }` — **match on status code, not message text**.
- At least one non-empty selection array **or** a non-empty note, else `400`.
- Cannot enquire to yourself (`400`).

**Response — `201`** (check 2xx, not `== 200`; no `conversationId` in the body):

```json
{ "success": true, "message": "Enquiry sent", "data": { "enquiryId": "…", "status": "pending" } }
```

On success, open the provider's **business** chat by their userId with `route = discover`.

---

## 4. Card, sockets, accept / decline — zero home-service-specific work

All identical to `service-enquiry-flutter-integration.md` §4–§5 — the same parser, listeners, and `ServiceEnquiryMsgCard` handle every provider type:

- **Card:** `message_type: "service_enquiry"`; the self-work groups (`serviceType` / `typesOfWork` / `workCategories`) come back as `[]` for home service — the card skips empty groups, so nothing to branch on. There is **no field telling you the provider type**; infer it from the conversation peer if a card ever needs to render differently.
- **Sockets:** `newServiceEnquiryReceived` (dedupe by `_id` — sender gets an echo) and `serviceEnquiryStatusUpdated` (`{ messageId, enquiryId, status }`).
- **Decision:** `PUT earn-service/service-enquiries/{enquiryId}/status` with `{ "status": "accepted" | "declined" }`; `403/404/409` semantics and safe-retry (same status → `200` + socket re-emit) unchanged.
- **Lists:** the same `GET /me` (customer) and `GET /provider/me` (provider inbox) return home-service enquiries too — one enquiry collection for all flows.
- **Push:** same `service_enquiry` / `service_enquiry_status` operations, `conversation_type: "business"`.

---

## 5. Integration checklist (home-service deltas only)

1. ☑ **Flutter:** the Home-Service detail screen's **Enquire** pill now opens `ServiceEnquirySheet.openForProvider(...)` instead of opening chat directly. On submit → `submitServiceEnquiry` → business chat.
2. ☐ **Backend:** widen `POST earn-service/service-enquiries` provider validation to accept a live **home-service** provider (mirrors the consultant change). Status code stays `404` with `"Provider not found"` when invalid.
3. ☐ Verify the card renders with the self-work groups empty (they arrive as `[]`).
4. ☐ Note + photo remain **optional**; submit gate = ≥1 selection **or** note **or** photo.
5. ☐ Everything else (socket listeners, retry/409 handling, history cold-open) is already covered by the main guide — no new work.
