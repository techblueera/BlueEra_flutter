# Earn Artist — Flutter Integration Guide (Expertise → Profile → Enquiry)

End-to-end guide for the Artist / Content-Creator vertical in `be_earn_with_blueera_service` (+ `be_chat_service` for the enquiry chat card). Covers the full journey:

1. **Expertise catalog** — pick a `type` (parent group) → `category` → suggested `expertise`.
2. **Artist profile** — create/read/update the profile, including S3 media uploads (logo, gallery, certificates).
3. **Enquiry** — a customer enquires to an artist; an in-chat card is created and its status flips live.

Base path: same `earn-service/*` base URL and `Authorization: Bearer <token>` header used by every other earn-service call. All money/ids are strings; all list responses are JSON.

> **Ownership rule:** an artist profile is **always owned by a User** (the caller's token). There is no channel/provider-type concept. A user may own **exactly one** artist profile.

---

## 0. The journey at a glance

```
STEP 1  Expertise catalog (read-only, public reference data)
  GET earn-service/predefined-artist-expertise/types          → [ARTIST, CONTENT_CREATOR]
  GET earn-service/predefined-artist-expertise/type/ARTIST     → categories under a type
  GET earn-service/predefined-artist-expertise/PAINTER?type=ARTIST → suggested expertise

STEP 2  Create / manage the artist profile
  GET  earn-service/earn-artists/any/check                    → gate the "Create" button
  POST earn-service/earn-artists                              → create + get S3 upload URLs
  (PUT the file bytes to each presigned URL)
  GET  earn-service/earn-artists?all=true&...                 → discover / search
  GET  earn-service/earn-artists/{id}                         → profile detail (user populated)
  PUT  earn-service/earn-artists/{id}                         → edit

STEP 3  Enquiry (customer → artist) + chat card
  POST earn-service/artist-enquiries                          → JSON or multipart
  → open the artist's BUSINESS chat (route = discover)
  → backend (async, Kafka): creates "artist_enquiry" card + socket "newArtistEnquiryReceived"
  PUT  earn-service/artist-enquiries/{enquiryId}/status       → accept/decline
  → socket "artistEnquiryStatusUpdated" to BOTH parties → both cards flip
```

---

## STEP 1 — Expertise catalog

Read-only reference data used to drive the profile-creation pickers. Two parent **types** ship seeded: `ARTIST` (36 categories) and `CONTENT_CREATOR` (17 categories). Each category carries a suggested `expertise[]` list.

Response envelope for all list calls: `{ success: true, count: <n>, data: [...] }`.

### 1a. List the types (top-level picker)

`GET earn-service/predefined-artist-expertise/types`

```json
{
  "success": true,
  "count": 2,
  "data": [
    { "type": "ARTIST", "typeName": "Artist", "categoryCount": 36 },
    { "type": "CONTENT_CREATOR", "typeName": "Content Creator", "categoryCount": 17 }
  ]
}
```

### 1b. Categories under a type (second picker)

`GET earn-service/predefined-artist-expertise/type/ARTIST`

```json
{
  "success": true,
  "count": 36,
  "data": [
    {
      "_id": "…",
      "type": "ARTIST",
      "typeName": "Artist",
      "category": "PAINTER",
      "categoryName": "Painter",
      "field": "",
      "expertise": ["Oil painting", "Acrylic painting", "Watercolor painting", "…"],
      "isActive": true
    }
  ]
}
```

> `CONTENT_CREATOR` categories additionally carry a `field` grouping (e.g. `"Media Creators"`, `"Writing Creators"`) — use it to render section headers in the category picker. `ARTIST` categories have `field: ""`.

### 1c. Suggested expertise for one category (third picker)

`GET earn-service/predefined-artist-expertise/{category}?type={type}`

Always pass `?type=` — `PHOTOGRAPHER` exists under **both** types, so without it you get an array of both matches. With `?type=` you get a single object:

```json
{
  "success": true,
  "data": {
    "type": "ARTIST", "typeName": "Artist",
    "category": "PHOTOGRAPHER", "categoryName": "Photographer",
    "expertise": ["Portrait photography", "Wedding photography", "…"]
  }
}
```

### Dart — catalog service

```dart
class ArtistCatalogApi {
  final Dio dio; // baseUrl = ".../earn-service", auth interceptor attached
  ArtistCatalogApi(this.dio);

  Future<List<ArtistType>> getTypes() async {
    final r = await dio.get('/predefined-artist-expertise/types');
    return (r.data['data'] as List).map((e) => ArtistType.fromJson(e)).toList();
  }

  Future<List<ArtistCategory>> getCategories(String type) async {
    final r = await dio.get('/predefined-artist-expertise/type/$type');
    return (r.data['data'] as List).map((e) => ArtistCategory.fromJson(e)).toList();
  }

  Future<ArtistCategory> getCategory(String category, String type) async {
    final r = await dio.get('/predefined-artist-expertise/$category',
        queryParameters: {'type': type});
    return ArtistCategory.fromJson(r.data['data']);
  }
}
```

The values you carry forward into STEP 2:
- `type`  → `EarnArtist.type`  (e.g. `"ARTIST"`)
- `category` (or `categoryName`) → `EarnArtist.category` (e.g. `"Painter"`)
- the ticked `expertise` strings → `EarnArtist.expertise[]`

> **⚠️ Field-mapping (client naming ↔ backend fields).** The picker the user sees is a *category → subcategory* chooser, but the backend field names are shifted one level up. Map them like this:
> - the user's **category** (the parent group they pick first — `ARTIST` / `CONTENT_CREATOR`) → **`EarnArtist.type`**
> - the user's **subcategory** (the child they pick second — `Painter`, `Singer`, `Video Creator`) → **`EarnArtist.category`**
>
> So "category" in the UI is `type` in the payload, and "subcategory" in the UI is `category` in the payload. Send them accordingly on `POST`/`PUT` and read them back the same way. (This is why the catalog endpoints call the parent `type` and the child `category`.)

---

## STEP 2 — The artist profile

### 2a. Gate the create button

`GET earn-service/earn-artists/any/check`  → `{ "exists": true, "artistId": "…" }`

If `exists`, route the user to **edit** their existing `artistId` instead of create (the create endpoint returns `409` with `existingArtistId` otherwise).

### 2b. Create the profile — `POST earn-service/earn-artists`

The owner is taken from your token — **do not** send any user/provider id. Only `category` is required; `title` is auto-generated as `"<Your Name> <Category>"` when omitted.

Media is uploaded via **S3 presigned URLs**: you send the *content types* you want to upload, the server stores placeholder keys and returns short-lived `PUT` URLs, and you upload the bytes directly to S3.

**Full create body:**

```json
{
  "type": "ARTIST",
  "category": "Painter",
  "description": "Contemporary oil & acrylic artist based in Pune.",
  "expertise": ["Oil painting", "Portrait painting", "Abstract art"],

  "brandCollaborations": ["665f0a…businessId1", "665f0b…businessId2"],

  "channels": [
    { "name": "Instagram", "url": "https://instagram.com/artist" },
    { "name": "YouTube", "channelId": "665f0c…internalChannelId" }
  ],

  "contactUs": {
    "description": "Available for commissions & live events",
    "website": "https://artist.example",
    "email": "artist@example.com",
    "number": "+91 90000 00000"
  },

  "booking": {
    "minimumPrice": 2000,
    "price": 500,
    "bookingType": "Commission",
    "priceType": "perHour"
  },

  "gallery": [
    { "name": "Portraits", "images": [] },
    { "name": "Murals", "images": [] }
  ],

  "certificatesAndAwards": [
    { "name": "State Art Award 2024", "description": "Best emerging artist", "media": [] }
  ],

  "logoContentType": "image/png",

  "galleryUploads": [
    { "galleryIndex": 0, "contentTypes": ["image/jpeg", "image/jpeg"] },
    { "galleryIndex": 1, "contentTypes": ["image/png"] }
  ],

  "certificateUploads": [
    { "certificateIndex": 0, "media": [{ "type": "image", "contentType": "image/jpeg" }] }
  ]
}
```

> **Critical ordering:** `galleryUploads[i].galleryIndex` and `certificateUploads[i].certificateIndex` are **indices into the `gallery` / `certificatesAndAwards` arrays you send in the same request**. So you must include the gallery group (with an empty `images: []`) and the certificate (with empty `media: []`) in the body, then reference their position by index. `priceType` is one of `perHour` | `perVisit`.

**Response** — the created profile plus the presigned upload URLs:

```json
{
  "artist": {
    "_id": "66aa…",
    "userId": "6624…",
    "user": { "id": "6624…", "name": "Asha Verma", "profile_image": "…" },
    "title": "Asha Verma Painter",
    "type": "ARTIST",
    "category": "Painter",
    "serviceLogo": "https://…s3…/logo (presigned GET)",
    "gallery": [ { "name": "Portraits", "images": [] }, … ],
    "…": "…"
  },
  "uploadUrls": {
    "logo": "https://s3…PUT-url",
    "gallery": [
      { "galleryIndex": 0, "images": ["https://s3…PUT", "https://s3…PUT"] },
      { "galleryIndex": 1, "images": ["https://s3…PUT"] }
    ],
    "certificates": [
      { "certificateIndex": 0, "media": [{ "type": "image", "url": "https://s3…PUT" }] }
    ]
  }
}
```

### 2c. Upload the bytes to each presigned URL

For **every** URL in `uploadUrls`, do an HTTP `PUT` of the raw file bytes with the **same `Content-Type`** you declared. Use a bare Dio (no auth header — the signature is in the URL).

```dart
final _plain = Dio(); // no interceptors

Future<void> putToS3(String url, File file, String contentType) async {
  await _plain.put(
    url,
    data: file.openRead(),
    options: Options(
      headers: {
        Headers.contentTypeHeader: contentType,
        Headers.contentLengthHeader: await file.length(),
      },
    ),
  );
}
```

Order of upload doesn't matter; do them in parallel. Map each returned URL back to the file the user picked, matching by index:

```dart
Future<void> uploadArtistMedia(UploadUrls u, ArtistDraft d) async {
  final jobs = <Future>[];
  if (u.logo != null && d.logoFile != null) {
    jobs.add(putToS3(u.logo!, d.logoFile!, d.logoContentType!));
  }
  for (final g in u.gallery) {
    final files = d.gallery[g.galleryIndex].files; // your picked files for that group
    for (var i = 0; i < g.images.length; i++) {
      jobs.add(putToS3(g.images[i], files[i], lookupMime(files[i])));
    }
  }
  for (final c in u.certificates) {
    final media = d.certificates[c.certificateIndex].files;
    for (var i = 0; i < c.media.length; i++) {
      jobs.add(putToS3(c.media[i].url, media[i], lookupMime(media[i])));
    }
  }
  await Future.wait(jobs);
}
```

After the PUTs succeed the media is live; the next `GET` returns presigned **download** URLs in the same fields (`serviceLogo`, `gallery[].images`, `certificatesAndAwards[].media[].key`).

> **Certificate media download field.** On GET, each `certificatesAndAwards[].media[]` item is `{ type, key }` where **`key`** carries the presigned **download URL** (the stored S3 key is swapped for the URL in place — the field name stays `key`, it is *not* renamed to `url` on read). `type` is `"image"` | `"video"`. Read the image/video from `media[].key`.

### 2d. Discover / search — `GET earn-service/earn-artists`

Returns a **plain array** when `all=true` (list/search), or a **single object** (your own newest profile) when `all=false`/omitted.

> **Own-profile envelope (no-profile case).** When `all` is omitted/`false`, the response is the **bare profile object** (not wrapped in `{ data }` / `{ artist }`), or **`200` with a JSON `null` body** when you have no profile yet — it is **not** a `404`. Gate the create-CTA on `GET .../any/check` (`exists`), not on a 404. Note the own-profile GET also drops a profile whose owner can't be resolved via the user service, so it can return `null` even if a row exists — treat `/any/check` as the source of truth for "do I have a profile".

| Query param   | Effect                                                        |
|---------------|--------------------------------------------------------------|
| `all=true`    | Public list/search mode (otherwise scoped to your own profile) |
| `name` / `q`  | Case-insensitive partial match on the title                  |
| `category`    | Exact category                                               |
| `type`        | Parent group (`ARTIST` / `CONTENT_CREATOR`)                  |
| `expertise`   | Comma-separated; matches **any** listed skill                |
| `bookingType` | Exact `booking.bookingType`                                  |
| `priceType`   | `perHour` / `perVisit`                                        |
| `minPrice` / `maxPrice` | Range on `booking.price`                           |
| `isActive`    | `true` / `false`                                             |
| `page` / `limit` | Pagination (list mode)                                    |

Example: `GET earn-service/earn-artists?all=true&type=ARTIST&category=Painter&priceType=perHour&minPrice=200&maxPrice=1000&expertise=Oil painting,Portrait painting`

Every returned profile has its owner populated under **`user`**, and all media fields are presigned download URLs. (Profiles whose owner can't be fetched are omitted from the list.)

> **`brandCollaborations` holds Business ids and is NOT populated on the artist GET.** Each entry is a **Business id** (a `Business` entity id) — the artist GET returns them as a **plain array of id strings**, it does *not* expand them into `{ name, logo, location }`. To render the "Associate Brands" strip (logo + name + sublabel) you must **populate each business from its id** against the Business service. The sublabel/logo/name come from the resolved Business record, not from the artist document.

### 2e. Other profile endpoints

| Method & path | Purpose |
|---|---|
| `GET earn-service/earn-artists/{id}` | Public profile detail (`user` populated) |
| `GET earn-service/earn-artists/user/{userId}?page&limit` | A user's profiles, paginated |
| `PUT earn-service/earn-artists/{id}` | Edit (owner only). Arrays like `expertise`/`gallery`/`channels` **replace**; `contactUs`/`booking` **merge**. Send `logoContentType` to swap the logo (returns a new `uploadUrls.logo`), or `deleteLogo: true` to remove it. `serviceLogo`/`userId` in the body are ignored. |
| `DELETE earn-service/earn-artists/{id}` | Soft-delete + S3 cleanup (owner only) |
| `POST earn-service/earn-artists/{id}/gallery/{galleryIndex}/images` | Add images to an existing gallery group → `{ uploadUrls: [PUT urls] }` |
| `DELETE earn-service/earn-artists/{id}/gallery/{galleryIndex}/images` | Remove images (`{ image_urls: [...] }` or `{ image_url: "…" }`) |

---

## STEP 3 — The enquiry flow

A customer viewing an artist taps **Enquire**. This creates an `ArtistEnquiry`, and — asynchronously via Kafka — an in-chat **`artist_enquiry`** card in the customer↔artist **business** conversation (handled by `be_chat_service`).

```
Customer taps "Enquire" on an artist profile
  → POST earn-service/artist-enquiries                (JSON or multipart)
  → on HTTP 2xx: open the artist's BUSINESS chat (route = discover)
  → backend emits socket "newArtistEnquiryReceived" + creates the card
Artist taps Accept / Decline on the card
  → PUT earn-service/artist-enquiries/{enquiryId}/status
  → backend emits socket "artistEnquiryStatusUpdated" to BOTH → cards flip
```

### 3a. Create the enquiry — `POST earn-service/artist-enquiries`

Target the artist by **`artist_id`** (the profile `_id`) **or** **`provider_id`** (the artist's `userId`). Selection arrays mirror the profile: `expertise` + the generic `requestType`.

**JSON variant** (no photos):

```json
{
  "artist_id": "66aa…",
  "expertise": ["Oil painting", "Portrait painting"],
  "requestType": ["Commission", "Live event"],
  "note": "Want a 2x3 ft portrait, oil on canvas, delivered in 3 weeks."
}
```

Server-side rules (mirror your submit gating):
- A valid `artist_id` **or** `provider_id` is required, and must resolve to a **live** artist profile (active, not deleted) → else `404 Artist profile not found`.
- At least one non-empty array (`expertise` / `requestType`) **or** a non-empty `note`, else `400`.
- You cannot enquire to yourself → `400`.

**Multipart variant** (1–5 photos): `multipart/form-data` with exactly:

| Part      | Type         | Notes                                              |
|-----------|--------------|----------------------------------------------------|
| `payload` | string part  | The JSON object above, encoded as a string.        |
| `photos`  | file part(s) | Repeated, one per file. **Max 5, max 10 MB each.** |

Limit violations return `400 { success:false, message:"Photo upload error: …" }`. Photos are uploaded to S3 server-side; their URLs appear inside the chat card's `metadata.artistEnquiry.photos`.

**Response:**

```json
{ "success": true, "message": "Enquiry sent", "data": { "enquiryId": "66bb…", "status": "pending" } }
```

```dart
Future<String> createArtistEnquiry({
  String? artistId,
  String? providerId,
  List<String> expertise = const [],
  List<String> requestType = const [],
  String note = '',
  List<File> photos = const [],
}) async {
  final payload = {
    if (artistId != null) 'artist_id': artistId,
    if (providerId != null) 'provider_id': providerId,
    if (expertise.isNotEmpty) 'expertise': expertise,
    if (requestType.isNotEmpty) 'requestType': requestType,
    if (note.isNotEmpty) 'note': note,
  };

  Response r;
  if (photos.isEmpty) {
    r = await dio.post('/artist-enquiries', data: payload);
  } else {
    final form = FormData.fromMap({
      'payload': jsonEncode(payload),
      'photos': [
        for (final f in photos)
          await MultipartFile.fromFile(f.path, filename: f.path.split('/').last),
      ],
    });
    r = await dio.post('/artist-enquiries', data: form);
  }
  return r.data['data']['enquiryId'] as String;
}
```

On HTTP 2xx, open the artist's **business** conversation with `route = discover` (same lane the chat card lands in) so the customer sees their card appear.

### 3b. Artist accepts / declines — `PUT earn-service/artist-enquiries/{enquiryId}/status`

Body: `{ "status": "accepted" }` or `{ "status": "declined" }`. Only the artist on the enquiry may call it, and only while `pending`.

- `200` → `{ success:true, message:"Enquiry accepted", data:{ enquiryId, status } }`
- `403` → caller is not the artist
- `409` → already accepted/declined (re-sending the *same* status is idempotent and returns `200`)

Both parties then receive the `artistEnquiryStatusUpdated` socket event and the card flips.

### 3c. Lists & detail

| Method & path | Who | Returns |
|---|---|---|
| `GET earn-service/artist-enquiries/me?status&page&limit` | Customer | Enquiries I sent |
| `GET earn-service/artist-enquiries/provider/me?status&page&limit` | Artist | Enquiries sent to me |
| `GET earn-service/artist-enquiries/{enquiryId}` | Either participant | One enquiry |
| `GET earn-service/artist-enquiries/admin/all?…` | Admin | All, with filters (date/customer/provider/artist/category/status) |

Paginated responses: `{ success, data:[…], pagination:{ totalCount, page, limit, totalPages } }`. Valid `status` values: `pending` \| `accepted` \| `declined`.

---

## 4. Chat card (be_chat_service)

The card is created and updated by `be_chat_service` off Kafka; the Flutter chat client only needs to **render** and **listen**.

- **Card message:** `message_type = "artist_enquiry"`, `sub_type = "artist_enquiry"`, in the `business` conversation between customer and artist. Render from `metadata.artistEnquiry`:

  ```json
  "metadata": {
    "artistEnquiryId": "66bb…",
    "artistEnquiry": {
      "enquiryId": "66bb…",
      "customerId": "6624…",
      "providerId": "6624…",
      "artistId": "66aa…",
      "expertise": ["Oil painting", "Portrait painting"],
      "requestType": ["Commission"],
      "photos": ["https://…s3…/artist-enquiries/…"],
      "note": "…",
      "status": "pending"
    }
  }
  ```

- **Socket events** (join your user room as usual):
  - `newArtistEnquiryReceived` → `{ message: <card message> }` — append/refresh the card (dedupe by `_id`).
  - `artistEnquiryStatusUpdated` → `{ messageId, enquiryId, status }` — patch that card's `metadata.artistEnquiry.status` to flip Accept/Decline UI.

- **Cold open:** the card is included in chat history (`sub_type "artist_enquiry"` is whitelisted), so no special fetch is needed — the normal `getMessages` pagination returns it.

```dart
socket.on('newArtistEnquiryReceived', (data) {
  final msg = data['message'];
  chat.upsertMessageById(msg); // dedupe by _id
});

socket.on('artistEnquiryStatusUpdated', (data) {
  chat.patchArtistEnquiryStatus(
    messageId: data['messageId'],
    status: data['status'], // "accepted" | "declined"
  );
});
```

---

## 5. Overview tab — field contract (design ↔ API)

Answers to the fields the content-creator **Overview** design needs. Use this to replace the client-side fallbacks/placeholders with real bindings (or to lock the fallback where the backend intentionally doesn't provide the field).

| # | Overview element | Backend status | What to bind / do |
|---|---|---|---|
| 1 | **"Joined – <date>" pill** | ✅ **Available.** The schema is `timestamps: true`, so every profile GET (`/{id}`, own-profile, list) returns **`createdAt`** and `updatedAt` as **ISO-8601** strings. | Read `createdAt`; format to the pill. No fallback/hide needed. |
| 2 | **Cover Photo carousel + Edit** | ❌ **No dedicated field.** `EarnArtist` has only `serviceLogo` (single logo) and `gallery[]` (named image groups). There is no `coverPhotos[]`/`coverImages[]` and no cover upload path. | Keep the fallback: source the carousel from `gallery[].images` (flattened), falling back to `serviceLogo`. "Edit cover" should edit the gallery/logo. Lock this behavior. |
| 3 | **★ rating + review count** | ❌ **Not implemented.** No `avgRating`/`totalReviews` (or equivalent) on the model, and no ratings endpoint for artists. | Hide the rating row, or keep it clearly static, until a ratings feature ships. Do not expect it on the profile GET. |
| 4 | **Testimonials carousel + Reply** | ❌ **Not implemented in this service.** No testimonial source scoped to an artist/creator, and no reply endpoint. | Keep the empty-state; leave **Reply** stubbed. Revisit if/when a testimonial source is exposed. |
| 5 | **Certificate media image** | ✅ **Available as `key`.** On GET each `certificatesAndAwards[].media[]` is `{ type, key }`, where **`key`** is the presigned **download URL** (`type` = `image`\|`video`). | Render from `media[].key` (it holds the URL on read — the field is not renamed to `url`). |
| 6 | **Associate Brands (logo+name+sublabel)** | ⚠️ **Business ids only.** `brandCollaborations[]` is returned as **bare Business id strings** — never populated into `{ name, logo, location }` on the artist GET. | Each id is a **Business id**; populate it from the Business service/record to get logo/name/sublabel. Don't expect populated objects on the artist GET. |
| 7 | **Own-profile fetch / create-CTA gate** | ✅ **Clarified.** Own-profile GET (`all` omitted/`false`) returns the **bare profile object**, or **`200` with `null`** when none exists — **not a 404**. It also returns `null` if the owner can't be resolved via the user service. | Treat `GET .../any/check` (`{ exists, artistId }`) as the source of truth for the create-vs-edit gate; treat `200 null` (not 404) as "no profile yet". |

> **Net:** items 1, 5, 7 are ready to wire against real data; items 2, 3, 4 are **not backed by this service** (keep fallbacks/empty states); item 6 needs a **client-side brand-id → brand lookup**.

---

## 6. Error contract cheat-sheet

| Code | When | Client action |
|---|---|---|
| `400` | Missing `category` / bad body / self-enquiry / photo-limit | Show field validation; block submit |
| `401` | Missing/invalid token | Re-auth |
| `403` | Not the owner (profile edit) / not the artist (status) | Hide the action |
| `404` | Profile / enquiry / artist not found | Toast + back |
| `409` | Second profile create (`existingArtistId`) / already-decided enquiry | Route to edit / refresh card |
| `500` | Unexpected | Generic retry toast |

---

## 7. Build order for the client

1. **Catalog pickers** (STEP 1) — cache `types` + per-type categories; drive the expertise chips from the selected category.
2. **Profile create/edit** (STEP 2) — the two-phase media flow: `POST` to get `uploadUrls`, then `PUT` bytes to S3. Gate with `/any/check`.
3. **Discover + detail** (STEP 2d/2e) — search list → profile detail (owner in `user`).
4. **Enquiry** (STEP 3) — submit → open business chat; wire the two sockets for the card + status flip.
```
