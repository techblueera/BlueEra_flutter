# Professional-Consultant Enquiry — Backend Contract

Customer "Enquiry" flow for **professional consultants** (advocate, tax consultant, CA, etc.), reached from the Discover → Professional Consultant screen's **Enquire** button.

It **reuses the existing service-enquiry infrastructure** — the same create endpoint, the same `service_enquiry` chat card, the same socket events, and the same accept/decline flow as the self‑profession enquiry (see `service-enquiry-flutter-integration.md`). This doc only describes what is **different / required** for consultants. The client widget is separate (`ProfessionEnquirySheet`) but it calls the same API.

Base path: `earn-service/*`, `Authorization: Bearer <token>`.

---

## 1. The one required backend change

The create endpoint today rejects a provider who isn't a **live self‑profession provider** with `404 Self-profession provider not found`. For consultants that check fails.

**Required:** accept a **professional‑consultant** as a valid `provider_id` too. i.e. relax the provider validation to:

> `provider_id` must be a live **self‑profession provider OR professional‑consultant** (active, not deleted) — otherwise `404`.

Everything else (enquiry persistence, chat‑card creation, socket emit, status PUT) is **identical** to the self‑profession flow and needs no change.

---

## 2. API — Create enquiry (same endpoint)

### `POST earn-service/service-enquiries`

Consultants only send the `servicesOffered` and `requestType` groups (the other self‑work segments — `serviceType` / `typesOfWork` / `workCategories` — are not used for consultants). All keys already exist on the enquiry schema, so no schema change.

**JSON variant** (no photos):

```json
{
  "provider_id": "6624a1f0c2b9e4f1a0d33b21",
  "servicesOffered": ["Contract drafting", "Legal consultation"],
  "requestType": ["Consultation", "Urgent"],
  "note": "Need help reviewing a vendor agreement this week."
}
```

**Multipart variant** (with 1 photo/document): `multipart/form-data` with exactly:

| Part      | Type        | Notes                                          |
|-----------|-------------|------------------------------------------------|
| `payload` | string part | The JSON object above, encoded as a string.    |
| `photos`  | file part   | The image (client sends at most 1; backend cap stays 5 / 10 MB each). |

Rules (same as self‑work):
- `provider_id` required, valid ObjectId, live **self‑profession or consultant** provider (else `404`).
- At least one non‑empty array **or** a non‑empty `note`, else `400`.
- Cannot enquire to yourself (`400`).

**Response — `201`** (same shape):

```json
{ "success": true, "message": "Enquiry sent", "data": { "enquiryId": "…", "status": "pending" } }
```

Client checks 2xx only and opens the consultant's **business** chat (`route = discover`) by `provider_id` — it does **not** read a `conversationId` from the response.

---

## 3. Chat card, socket, accept/decline — all unchanged

These are **identical** to the self‑profession enquiry (same code path, same `service_enquiry` message type). No consultant‑specific work:

- **Card message:** `message_type: "service_enquiry"`, `metadata.serviceEnquiry` carrying the selected arrays (`servicesOffered`, `requestType`), `photos`, `note`, `status`. For consultants the other arrays come back empty `[]` — the card already skips empty groups.
- **Socket:** `newServiceEnquiryReceived` (server → provider, echoed to customer) on create; `serviceEnquiryStatusUpdated` (`{ messageId, enquiryId, status }`) on the provider's decision.
- **Status:** `PUT earn-service/service-enquiries/{enquiryId}/status` with `{ "status": "accepted" | "declined" }` — idempotent, re‑emits the socket event.
- **Conversation lane:** `business` (lands in the Inquiry tab, like self‑work).
- **Push:** same `service_enquiry` / `service_enquiry_status` operations, `conversation_type: "business"`.

See `service-enquiry-flutter-integration.md` §3–§5 for the exact payloads — they apply verbatim.

---

## 4. Options source (client‑side; informational)

The consultant enquiry sheet populates its **Services Offered** chips from the predefined‑professional catalog (not part of the chat flow, but listed so the team has the full picture):

### `GET earn-service/predefined-professional/<professionSlug>`

`<professionSlug>` is the consultant's profession (e.g. `ADVOCATE`), read client‑side from the provider record (`userDetails.profession`).

**Current response** (one segment):

```json
{
  "success": true,
  "data": {
    "category": "ADVOCATE",
    "servicesOffered": ["Legal consultation", "Contract drafting", "Court representation", "Document review"]
  }
}
```

The client maps `data.servicesOffered` → the **Services Offered** group, and always appends a fixed generic **Request Type** group (`Consultation / Document review / Quote / Estimate / Follow-up / Urgent`). Results are **cached per profession** and **prefetched** when the consultant tab loads, so the sheet opens instantly and a profession is fetched at most once.

> **Optional enhancement:** if you want consultants to offer more selectable groups (e.g. `practiceAreas`, `expertise`, `consultationModes`), add those arrays to this same response object. The client can then surface them as additional enquiry groups — tell the app team which keys and they'll map them like `servicesOffered`.

---

## 5. Backend checklist

1. ☐ Allow `provider_id` to be a **professional‑consultant** (not only self‑profession) on `POST /service-enquiries` and `PUT /service-enquiries/{id}/status` — the only required change.
2. ☐ No schema change: `servicesOffered`, `requestType`, `note`, `photos` already exist on the enquiry.
3. ☐ Card creation + `newServiceEnquiryReceived` / `serviceEnquiryStatusUpdated` + `business` conversation: reuse the existing self‑profession path as‑is.
4. ☐ (Optional) Expand `predefined-professional/<slug>` to return more segment arrays if you want richer consultant enquiry options.
