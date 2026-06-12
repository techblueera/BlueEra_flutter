# Professional-Consultant Enquiry — Flutter Integration Guide

Enquiry flow for **professional consultants** (advocate, CA, tax consultant, …) from the Discover → Professional Consultant screen's **Enquire** button.

**Backend status: complete.** It is the same pipeline as the self-profession enquiry — same endpoints, same `service_enquiry` chat card, same socket events. The backend change for consultants is confined to the earn service (provider validation now accepts a live consultant profile); **the chat service needed no changes**. If the chat service already runs the service-enquiry build, consultants only require the earn-service deploy.

This is a **delta guide** — everything not mentioned here works exactly as in `service-enquiry-flutter-integration.md` (§2–§7 apply verbatim).

---

## 1. The flow at a glance

```
Consultant tab loads → prefetch option chips per profession        (§2)
Customer taps "Enquire" on a consultant card
  → ProfessionEnquirySheet: tick Services Offered / Request Type (+ note, ≤1 photo)
  → POST earn-service/service-enquiries                            (§3 — same endpoint)
  → on 2xx: open the consultant's BUSINESS chat (route = discover)
  → "service_enquiry" card arrives via socket + history            (unchanged)
Consultant taps Accept / Decline → PUT …/{enquiryId}/status        (unchanged)
  → both cards flip via "serviceEnquiryStatusUpdated"              (unchanged)
```

---

## 2. Options source — populate the sheet's chips

### `GET earn-service/predefined-professional/{professionSlug}`

`professionSlug` = the consultant's profession read from the provider record (`userDetails.profession`), e.g. `ADVOCATE`. The backend uppercases it before lookup, so `advocate` works too.

**Response:**

```json
{
  "success": true,
  "data": {
    "category": "ADVOCATE",
    "servicesOffered": ["Legal consultation", "Contract drafting", "Court representation", "Document review"]
  }
}
```

(`data` also carries `_id`, `isActive`, timestamps — ignore them.)

Client behavior (as designed):
- Map `data.servicesOffered` → the **Services Offered** chip group.
- Always append the fixed generic **Request Type** group: `Consultation / Document review / Quote / Estimate / Follow-up / Urgent`.
- **Cache per profession + prefetch** when the consultant tab loads (one fetch per profession, sheet opens instantly).
- `404` (unknown profession) → show only the generic Request Type group + note; the submit rule (§3) still holds.

```dart
final cache = <String, List<String>>{};

Future<List<String>> servicesFor(String profession) async {
  final slug = profession.toUpperCase();
  if (cache.containsKey(slug)) return cache[slug]!;
  try {
    final res = await dio.get('$earnBase/predefined-professional/$slug');
    return cache[slug] = List<String>.from(res.data['data']['servicesOffered'] ?? []);
  } on DioException {
    return cache[slug] = const []; // sheet falls back to Request Type + note
  }
}
```

---

## 3. Create enquiry — same endpoint, consultant payload

### `POST earn-service/service-enquiries`

Consultants send **only** `servicesOffered` and `requestType` (plus `note` / photos). Do not send the self-work groups (`serviceType`, `typesOfWork`, `workCategories`) — absent arrays are treated as empty.

```json
{
  "provider_id": "6624a1f0c2b9e4f1a0d33b21",
  "servicesOffered": ["Contract drafting", "Legal consultation"],
  "requestType": ["Consultation", "Urgent"],
  "note": "Need help reviewing a vendor agreement this week."
}
```

With an attachment: same multipart shape as self-work — `payload` string part + `photos` file part. The client sends at most 1 file for consultants; the backend cap stays 5 files / 10 MB each, and the URL comes back in `metadata.serviceEnquiry.photos`.

Reuse the same `createEnquiry()` Dio helper from the main guide — just pass only the consultant fields:

```dart
final enquiryId = await createEnquiry(
  providerId: consultant.userId,
  servicesOffered: selectedServices,
  requestType: selectedRequestTypes,
  note: noteController.text.trim(),
  photos: attachment != null ? [attachment] : const [],
);
```

Server-side rules (identical to self-work, one message changed):
- `provider_id` must be a valid ObjectId belonging to a **live** provider — now *either* a self-profession provider *or* a professional consultant (active, not deleted). Otherwise **`404 { "message": "Provider not found" }`** ← note: the message changed from the old `"Self-profession provider not found"`; match on status code, not message text.
- At least one non-empty array **or** a non-empty note, else `400`.
- Cannot enquire to yourself (`400`).

**Response — `201`** (same shape, same caveats as the main guide: check 2xx not `== 200`, no `conversationId` in the body):

```json
{ "success": true, "message": "Enquiry sent", "data": { "enquiryId": "…", "status": "pending" } }
```

On success, open the consultant's **business** chat by their userId with `route = discover` — exactly like self-work.

---

## 4. Card, sockets, accept/decline — zero consultant-specific work

All identical to `service-enquiry-flutter-integration.md` §4–§5; the same parser, listeners, and card widget handle both provider types:

- **Card:** `message_type: "service_enquiry"`; for consultants `metadata.serviceEnquiry.serviceType / typesOfWork / workCategories` come back as `[]` — the card already skips empty groups, so nothing to branch on. There is **no field telling you the provider type**; if `ServiceEnquiryMsgCard` ever needs to render differently for consultants, infer it from the conversation peer, not the card.
- **Sockets:** `newServiceEnquiryReceived` (dedupe by `_id` — sender gets an echo) and `serviceEnquiryStatusUpdated` (`{ messageId, enquiryId, status }`).
- **Decision:** `PUT earn-service/service-enquiries/{enquiryId}/status` with `{ "status": "accepted" | "declined" }` — consultant must be the authenticated caller; `403/404/409` semantics and the safe-retry behavior (same status → 200 + socket re-emit) are unchanged.
- **Lists:** the same `GET /me` (customer) and `GET /provider/me` (consultant inbox) endpoints return consultant enquiries too — there is one enquiry collection for both flows.
- **Push:** same `service_enquiry` / `service_enquiry_status` operations, `conversation_type: "business"`.

---

## 5. Integration checklist (consultant deltas only)

1. ☐ Prefetch + cache `predefined-professional/{slug}` per profession when the consultant tab loads; fall back to the generic Request Type group on 404/error.
2. ☐ `ProfessionEnquirySheet` submits only `servicesOffered` + `requestType` (+ `note`, ≤1 photo) through the existing create call.
3. ☐ Update any 404 handling that matched on the message string: it is now `"Provider not found"` (status code is still 404).
4. ☐ Verify the card renders with the self-work groups empty (they arrive as `[]`).
5. ☐ Everything else (stub flag, socket listeners, retry/409 handling, history cold-open) is already covered by the main guide's checklist — no new work.
