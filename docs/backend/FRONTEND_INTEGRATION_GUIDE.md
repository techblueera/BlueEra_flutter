# Frontend Integration Guide — Vehicle Service (v2)

**Service:** `be_vehicle_service` · **Gateway base:** `https://be.beapp.in/api/vehicle-service`

The vehicle service has been rebuilt around the same four-tier catalog shape as
`be_grocery_service`. The old flat `Brand → Model → Variant` API is **gone** and will
not return — this guide is the replacement contract.

Read §1 first if you are migrating an existing screen; it maps every removed endpoint
to its replacement.

---

## 1. Migration map — what was removed and what replaces it

Every path below now returns **404 with a JSON body** (`{ "status": false, "message": "Cannot GET ..." }`).
Note the JSON — previously these returned an HTML error page, which crashed clients
that parse every response as JSON.

| Removed | Replacement |
|---|---|
| `GET /vehicles/catalog/brands` | `GET /categories?level=1` |
| `GET /vehicles/catalog/models?brand_id=` | `GET /categories?level=2&parentId=<brandId>` |
| `GET /vehicles/catalog/models/:id/variants` | `GET /products?categoryId=<modelCategoryId>` (via `/products/search`) |
| `GET /vehicles/catalog/variants/:id` (prefill) | `GET /products/:productId` — returns the trim **and its colours** |
| `GET /vehicles/catalog/categories` | `GET /categories/nested` |
| `GET /upload/init`, `/upload/init-v2` | **No presigned upload.** Post files directly as `multipart/form-data` to `POST /inventory` — see §5 |
| `POST /vehicles/create` and the `/vehicles/*` CRUD | `POST /inventory` (§4) |
| `GET /vehicles/me/list` | `GET /inventory/my` |
| `POST /vehicles/:id/images` | Included in `POST`/`PUT /inventory` (§5) |
| `/vehicles/bookings/*` | `/bookings/*` (§6) — the `/vehicles` prefix is dropped |
| `/facilities/*`, `/gallery/*`, `/testimonials/*`, `/live-photos/*`, `/contact-us/*` | Removed from this service. Do not call them here. |

> **The `/vehicles` prefix is gone.** Everything is mounted at the root:
> `/categories`, `/products`, `/inventory`, `/bookings`.

---

## 2. The mental model

```
Category  level 0   "4 Wheeler"                 key 4W
   └─ Category  level 1   "Maruti Suzuki"       key BRAND_MARUTI_SUZUKI     ← BRAND
        └─ Category  level 2  "Swift"           key MODEL_MARUTI_..._SWIFT  ← MODEL (leaf)
             └─ Product   "Maruti Swift VXi"                                ← TRIM
                  └─ ProductVariant  "Pearl Arctic White"                   ← COLOUR
                       └─ Inventory  (seller A, USED, 42k km, ₹5.2L)        ← LISTING
```

Two rules that drive every screen:

1. **The catalog is read-only master data.** Sellers never create a Category, Product or
   ProductVariant. They only create an **Inventory** row that references an existing
   `ProductVariant`.
2. **`Inventory.productVariant` is required.** The add-vehicle flow must walk the seller
   all the way down to a **colour** before it can submit. A trim id is not enough.

### NEW vs USED

Both are Inventory rows; `condition` decides where display data comes from.

| | NEW | USED |
|---|---|---|
| Identity & specs | from catalog | from catalog |
| Photos | from catalog | **seller uploads their own** |
| Seller supplies | `on_road_price`, `availability`, `delivery_time`, `emi_available`, `special_offers` | `km_driven`, `ownership`, `registration_year`, `condition_grade`, `expected_price`, `is_negotiable`, `insurance_valid_till`, `rc_available`, `service_history`, `description` |

---

## 3. Auth

Send `Authorization: Bearer <jwt>` exactly as today.

| Guard | Meaning |
|---|---|
| **public** | no header needed |
| **protect** | any authenticated user |
| **admin** | Admin / SubAdmin only |

A missing token returns **400** `{"message":"No token provided"}`; an invalid one returns
**401**.

---

## 4. Seller journey — listing a vehicle

### Step 1 — pick the type (level 0)

```http
GET /categories?level=0
```
Returns a flat array of root categories (`4 Wheeler`, `2 Wheeler`, …). Each has
`_id`, `name`, `key`, `image`.

### Step 2 — pick the brand (level 1)

```http
GET /categories?level=1&parentId=<rootCategoryId>
```

### Step 3 — pick the model (level 2, the leaf)

```http
GET /categories?level=2&parentId=<brandCategoryId>
```

> Shortcut: `GET /categories/nested` returns the whole tree in one call if you'd rather
> cache it and drive all three pickers client-side.

#### All category reads (all public)

| Endpoint | Use |
|---|---|
| `GET /categories?level=&parentId=` | flat list, the three pickers above |
| `GET /categories/nested?categoryId=&categoryKey=` | whole tree, or one subtree |
| `GET /categories/nested/with-inventory?userId=&businessId=` | tree pruned to branches with ≥1 live listing; pass `userId`/`businessId` to scope it to one seller's storefront |
| `GET /categories/search?key=&name=&level=` | type-ahead over the tree |
| `GET /categories/:id` | one node |
| `GET /categories/:id/children` | its direct children |
| `GET /categories/key/:key/children` | direct children by parent **key** (e.g. `4W`) — handy when you hardcode roots instead of caching ids |
| `GET /categories/key/:key/children/with-inventory` | same, kept only where the subtree has live stock |

`key` is globally unique and uppercase (`4W`, `BRAND_MARUTI_SUZUKI`), so it's a stable
handle to hardcode against — safer than an `_id`. `level` is derived server-side; never
send it on a write.

### Step 4 — pick the trim

```http
GET /products/search?categoryId=<modelCategoryId>&page=1&limit=20
Authorization: Bearer <jwt>
```

`categoryId` resolves to the **whole subtree**, so passing a brand or even `?key=4W`
also works and returns everything beneath. `?searchTerm=` runs a text search.

```jsonc
{
  "data": [ { "_id": "...", "name": "Maruti Swift VXi", "brand": "...", "model": "...",
              "ex_showroom_price": 799000, "fuel_type": "PETROL", "transmission": "MANUAL",
              "images": [{ "url": "https://..." }], "variants": [ /* colours */ ] } ],
  "pagination": { "total": 42, "page": 1, "limit": 20, "totalPages": 3 }
}
```

### Step 5 — pick the colour  ← **this is the id you submit**

```http
GET /products/:productId
```

```jsonc
{ "data": { "_id": "<productId>", "name": "Maruti Swift VXi", "ex_showroom_price": 799000,
            "variants": [ { "_id": "<productVariantId>",   // ← submit THIS
                            "colorName": "Pearl Arctic White", "colorHex": "F7F7F7",
                            "images": [{ "url": "https://..." }] } ] } }
```

Use the trim's fields to pre-fill the form (specs, ex-showroom price) — there is no
separate prefill endpoint any more.

### Step 6 — create the listing

See §5 for the exact request. Minimum body:

```jsonc
{ "productVariant": "<productVariantId>", "condition": "USED" }
```

---

## 5. Creating and updating a listing (incl. photos)

`POST /inventory` · `PUT /inventory/:id` — both accept **either** `application/json`
**or** `multipart/form-data`. There is no separate upload step.

### Required on create

| Field | Notes |
|---|---|
| `productVariant` | ObjectId of the **colour** (step 5) |
| `condition` | `"NEW"` or `"USED"` |

### Location

Send **`lat` + `lng`** as plain fields. The server builds the GeoJSON point.
Never send `location` yourself. Also send `address`, `city`, `state`, `pincode`
for display and pincode filtering.

### Photos — multipart

| Part | Cardinality | Notes |
|---|---|---|
| `images` | repeatable, **max 12** | the seller's photos |
| `cover_image` | single | optional; if omitted the **first `images` entry becomes the cover** |

```
POST /inventory
Authorization: Bearer <jwt>
Content-Type: multipart/form-data

productVariant = 665f...c21
condition      = USED
km_driven      = 42000
expected_price = 520000
city           = Bhopal
lat            = 23.2148
lng            = 77.4601
specification  = {"permit":"valid"}      // JSON-encoded string is parsed server-side
images         = <file p1.jpg>
images         = <file p2.jpg>
cover_image    = <file cover.jpg>
```

Exceeding 12 files, or sending a file under any other field name, returns **400**:

```json
{ "status": false, "message": "Unexpected file field \"images\", or too many files for that field.",
  "code": "LIMIT_UNEXPECTED_FILE", "field": "images" }
```

> If any part of the write fails, uploaded S3 objects are rolled back — you will not be
> left with orphaned files.

### Editing photos — `PUT /inventory/:id`

- New `images` / `cover_image` files **append** to what's already there.
- `imagesToRemove` deletes photos, from the row **and** from S3. Accepts any of:
  a single URL string, a repeated form field, or a JSON array string
  (`["https://…/a.jpg","https://…/b.jpg"]`).
- If the removed set contained the cover, the cover automatically re-points at a
  surviving photo.

### JSON clients

Unchanged and fully supported — you may pass `images` as an array of already-hosted URLs.
Multer only parses multipart bodies, so a JSON request passes straight through.

### Fields you cannot set

`owner` is always derived from your token. `is_verified` and `deleted_at` are
server-owned. `productVariant` is **create-only** — re-listing a different colour is a
new listing, not an edit. These are silently dropped, not rejected, so extra keys from
older clients keep working.

### Managing listings

| Endpoint | Purpose |
|---|---|
| `GET /inventory/my?page&limit&condition` | your listings, **including inactive** |
| `GET /inventory/summary` | `{ total, active, inactive, verified, newCount, usedCount }` |
| `PATCH /inventory/:id/toggle` | body `{ "is_active": bool }`, or omit the body to flip |
| `DELETE /inventory/:id` | soft delete |

---

## 6. Buyer journey

### Discovery

| Endpoint | Use |
|---|---|
| `GET /products/user/search?pincode=` **or** `?lat=&lng=&range=` | main buyer search. Starts from **live listings** and rolls up to trim cards carrying `listingCount` + `priceFrom`. One of pincode / lat+lng+range is **required** |
| `GET /products/popular` | trims ranked by live-listing count |
| `GET /products/by-root-category?limit=` | home rails: newest trims bucketed per root category |
| `POST /products/similar` | body `{ productIds[], pincode \| lat/lng/range, limit }`; each row carries `matchRank` (0 same-model, 1 same-brand, 2 other) |
| `GET /categories/nested/with-inventory` | category tree **pruned to branches that actually have stock** |

### Listings

```http
GET /inventory/browse?productId=&productVariant=&condition=&pincode=&lat=&lng=&range=&page=&limit=
GET /inventory/:id
GET /inventory/seller/:userId          # a seller's storefront (live listings only)
```

Every listing read is enriched with:

- `variant`, `product`, `modelCategory` — the joined catalog
- `seller`, `sellerBusiness` — from the user service (**best-effort**; may be `null` if
  that service is briefly unavailable — render a fallback, don't treat it as an error)
- **`display_price`** — the single resolved "price to show"
  (NEW on-road → USED asking → generic `price`). **Prefer this over computing the price
  client-side**, so every surface shows the same number.

`page`/`limit` are clamped server-side (limit max 100).

---

## 7. Enquiries (`/bookings`)

`booking` is the contract name; conceptually it is an **enquiry**. No payment, no stock
decrement, one request per listing.

```http
POST /bookings
{ "inventoryId": "...", "intent": "BUY", "offerPrice": 500000, "note": "...", "photos": ["https://..."] }
```

`intent` ∈ `BUY | TEST_DRIVE | EXCHANGE | INFO`.
Bounds: `note` ≤ 2000 chars · `photos` ≤ 10, each an `http(s)` URL · `offerPrice` ≥ 0.

| Endpoint | Who |
|---|---|
| `GET /bookings/me` | buyer's sent requests |
| `GET /bookings/seller/me` | requests received |
| `GET /bookings/:id` | buyer or seller only, else 403 |
| `PUT /bookings/:id/status` | **seller** — `{ "status": "accepted" \| "declined" }` |
| `PUT /bookings/:id/cancel` | **buyer** — only while pending |

Status flow: `pending → accepted | declined | cancelled`.

**Errors worth handling explicitly on create:**

| Code | Meaning |
|---|---|
| 404 | listing inactive or deleted |
| 400 | you cannot enquire on your **own** listing |
| 409 | you already have an open request on this listing |

Creating a booking also opens a chat card in `be_chat_service` automatically — no
separate call needed.

---

## 8. Response envelopes

Not yet uniform across the service. Code defensively:

| Shape | Where |
|---|---|
| `{ data, pagination: { total, page, limit, totalPages } }` | product search, all listing lists |
| `{ data }` | single product, single listing |
| bare array / bare object | most `/categories` reads |
| `{ status, booking }` / `{ status, bookings, pagination }` | `/bookings` |
| `{ message, data }` | writes |

Errors are **always JSON**: `{ "message": "..." }` or `{ "status": false, "message": "..." }`.

> Please add a content-type check in the response decoder anyway. A gateway 502/504 can
> still return an HTML body from outside this service, and today that crashes the parser
> (`type 'String' is not a subtype of type 'int'`).

---

## 9. Not available

- No seller-facing catalog writes, and no "request a missing model" flow — if a model is
  absent from the catalog, the seller currently cannot list it. Tell the backend team.
- No admin listing moderation endpoint yet (`is_verified` is read-only for now).
- No batch/expiry/low-stock endpoints — a vehicle is a unique unit, so the grocery
  analogues don't apply.
