# UI Integration Guide — Packages & Testimonials

Service: **`be_laboratory_service`**
Screens: **Create Your Own Packages**, **Testimonials** (profile section)
Base URL: same as the rest of the lab service API. All routes below are relative to it.

Auth: send the bearer token on **writes** (`POST`/`PUT`/`DELETE`). Reads are public.
The lab is resolved server-side from the token → the caller's `LaboratoryProfile`, so
the client never sends `userId`/`laboratoryId` on create.

Standard response envelope:
```json
{ "success": true, "data": { /* ... */ }, "message": "..." }
```

---

## 1. Packages — "Create Your Own Packages"

A package is a **named bundle of existing tests** with its own MRP + customer price.
Tests must already exist as `PathologyTest`s (created via the Add Test screen); the
package references their ids.

### Endpoints
| Method | Path                        | Auth | Use in UI |
|--------|-----------------------------|------|-----------|
| POST   | `/packages`                 | ✅   | Submit the "Create Your Own Packages" form |
| GET    | `/packages/laboratory/:labId` | ❌ | Render the packages list on a lab's public profile |
| GET    | `/packages`                 | ✅   | Owner dashboard — my packages (token-scoped) |
| GET    | `/packages/:id`             | ❌   | Package detail — returns `tests` **populated** |
| PUT    | `/packages/:id`             | ✅   | Edit package |
| DELETE | `/packages/:id`             | ✅   | Remove package |

### Create — request body
```json
{
  "name": "Full Body Checkup",
  "description": "Comprehensive annual health screening.",
  "imageUrl": "https://cdn.../full-body.png",
  "tests": ["665f0a...b1", "665f0a...c2"],   // PathologyTest _id array, min 1
  "packageMrp": 2500,
  "customerPrice": 1499,
  "gender": "All"                             // "Male" | "Female" | "All" (default All)
}
```
- `name` is **free text** — bind it to the preset chips (Basic Health Checkup, Full Body
  Checkup, Executive, Diabetes, Thyroid, Heart Check-up, Senior Citizen, Men Health …)
  **and** allow the "Add Manually" custom entry. No enum restriction server-side.
- `tests`: collect the ids the user ticked in the test picker. Server rejects an empty
  array with `400 "A package must include at least 1 test."`
- `gender`: use for the gender-targeted packages (e.g. Men Health → `"Male"`).

### Create — success `201`
```json
{ "success": true, "data": { "_id": "...", "name": "Full Body Checkup", "tests": ["665f0a...b1"], ... }, "message": "Created successfully." }
```

### Package list card (`GET /packages/laboratory/:labId`)
Returns raw packages (tests **not** populated — only ids). Show `name`, `imageUrl`,
`customerPrice` with `packageMrp` struck through, and `tests.length` as "N tests".

### Package detail (`GET /packages/:id`)
`tests` is **populated** with display fields — render each row directly:
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "name": "Full Body Checkup",
    "packageMrp": 2500,
    "customerPrice": 1499,
    "tests": [
      { "_id": "665f0a...b1", "testName": "Complete Blood Count (CBC)",
        "groupCategory": "Blood & Routine Tests", "estimatedReportHours": 24,
        "customerPrice": 1200, "testFees": 1500,
        "specimenCollectionMethod": "Home" }
    ]
  }
}
```

### Edit / Delete
`PUT /packages/:id` accepts any subset of the create fields (send the full `tests` array
to replace membership). `DELETE /packages/:id`. Both are ownership-scoped — a `404
"Not found or unauthorized."` means the package isn't owned by the token's lab.

---

## 2. Testimonials — profile section

### Endpoints
| Method | Path                            | Auth | Use in UI |
|--------|---------------------------------|------|-----------|
| POST   | `/testimonials`                 | ✅   | Add testimonial |
| GET    | `/testimonials/laboratory/:labId` | ❌ | Testimonials carousel on public profile |
| GET    | `/testimonials`                 | ✅   | Owner dashboard — my testimonials |
| GET    | `/testimonials/:id`             | ❌   | Single testimonial |
| PUT    | `/testimonials/:id`             | ✅   | Edit |
| DELETE | `/testimonials/:id`             | ✅   | Remove |

### Create — request body
```json
{
  "authorName": "Dr. Ramesh Gupta",
  "designation": "Managing Director",
  "message": "Qorem ipsum dolor sit amet, consectetur adipiscing elit...",
  "photoUrl": "https://cdn.../ramesh.png"    // optional
}
```
`authorName` and `message` are required. Render the card as quote → author name →
designation, with `photoUrl` as the avatar (fall back to initials when absent).

---

## Where these sit on the profile screen

The lab profile screen already aggregates the other sections by `labId`
(`/gallery/laboratory/:labId`, `/facilities/...`, `/health-camps/...`,
`/contact-us/...`). Add two more parallel fetches keyed on the same `labId`:

- **Packages** block → `GET /packages/laboratory/:labId`
- **Testimonials** block → `GET /testimonials/laboratory/:labId`

Both return `[]` (not an error) when the lab has none — render the existing
"You Have Not Post Any …" empty state.

## Notes for the frontend team
- No changes to any existing endpoint or the Add Test form. The per-test `packageType`
  field on `PathologyTest` is unrelated to these new Package bundles — keep sending it as
  before; it is just a catalog label.
- `userId`/`laboratoryId` are never sent by the client — they are derived from the token.
- Money fields are plain numbers (INR). Format on the client (e.g. `INR-1,499`).
