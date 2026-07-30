# Standalone Doctor — Flutter Integration Guide

> **Audience:** Flutter developers. This guide assumes you know **nothing** about the backend.
> Every endpoint, field, rule and failure case is spelled out.
>
> **This document contains no Dart code by design.** It tells you *what* to call, *when*,
> *in what order*, and *what to do with every response*. How you write the widgets is your call.
>
> **Where to put this file:** the Flutter repo already keeps guides like this in
> `BlueEra_flutter/lib/docs/` (e.g. `healthcare-enquiry-ui-integration.md`,
> `laboratory-booking-ui-integration.md`). Copy this file there to follow that convention.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Architecture](#2-overall-architecture)
3. [Complete User Journey](#3-complete-user-journey)
4. [Screen by Screen Guide](#4-screen-by-screen-guide)
5. [API Integration](#5-api-integration)
6. [Authentication Flow](#6-authentication-flow)
7. [Image Upload Flow](#7-image-upload-flow)
8. [Screen State Management](#8-screen-state-management)
9. [API Calling Order](#9-api-calling-order)
10. [Validation Rules](#10-validation-rules)
11. [Error Handling](#11-error-handling)
12. [Loading States](#12-loading-states)
13. [UI Behaviour](#13-ui-behaviour)
14. [Discover Integration](#14-discover-integration)
15. [Chat Integration](#15-chat-integration)
16. [Booking Flow](#16-booking-flow)
17. [Statistics Screen](#17-statistics-screen)
18. [File Upload Sequence](#18-file-upload-sequence)
19. [Folder Suggestions](#19-folder-suggestions)
20. [Integration Checklist](#20-integration-checklist)
21. [Testing Checklist](#21-testing-checklist)
22. [API Reference](#22-api-reference)
23. [**Notifications (complete guide)**](#23-notifications-complete-guide) ← read this with §15
24. [**Troubleshooting — real bugs seen in testing**](#24-troubleshooting--real-bugs-seen-in-testing) ← read before you start
25. [**CUSTOMER SIDE — complete book & enquiry flow**](#25-customer-side--complete-book--enquiry-flow) ← ⚠️ MISSING IN THE APP TODAY
26. [**CRITICAL — stop reusing the Hospital screens for Doctors**](#26-critical--stop-reusing-the-hospital-screens-for-doctors)

---

## 1. Introduction

### What is a Standalone Doctor?

A **Standalone Doctor** is an independent doctor who runs their own practice — like an
electrician or a plumber in the services verticals. They:

- register **their own account** in the app,
- own **their own business listing**,
- appear in **Discover** on their own,
- receive **their own enquiries and bookings**,
- do **not** belong to any hospital.

### How is this different from a Hospital OPD Doctor?

The app already has doctors — but those are completely different things. **Never mix them up.**

| | **Hospital OPD Doctor** (already exists) | **Standalone Doctor** (this guide) |
|---|---|---|
| What it is | A row in the hospital's doctor list | An independent business account |
| Who created it | The **hospital owner**, from the hospital dashboard | The **doctor themselves**, at signup |
| Has a login? | ❌ No — it is just data | ✅ Yes — a real account with OTP login |
| Belongs to a hospital? | ✅ Always. Requires hospital + department | ❌ Never. No hospital field exists |
| Appears in Discover? | ❌ Only inside the hospital's profile page | ✅ Yes, as its own card |
| API base | `hospital-service/opd` | `hospital-service/doctors` |
| Booking API | `hospital-service/hospital-appointments` (needs `opd_id`) | `hospital-service/doctor-appointments` (**no** `opd_id`) |
| Enquiry API | `hospital-service/hospital-enquiries` | `user-service/business-enquiries` |
| Who gets the booking | The **hospital owner** | The **doctor** |
| Availability | A plain text string like `"10AM-1PM"` | A real weekly calendar |

> ⚠️ **The existing OPD flow has not changed at all.** Every existing hospital screen,
> controller and repo in `lib/features/me/hospital/` keeps working exactly as before.
> This is a brand-new, parallel module. Do not modify hospital files to build it.

### The most important rule of this feature

> **There is NO approval step.**
>
> The moment a doctor registers and saves their profile, they are **live** — instantly
> visible in Discover and instantly bookable. There is no "pending verification" screen,
> no "waiting for admin approval" state, no `isApproved` flag anywhere. Do not build any
> such UI. Profile edits also go live immediately.

---

## 2. Overall Architecture

### The services involved

```
                        ┌────────────────────────┐
                        │      FLUTTER APP       │
                        └───────────┬────────────┘
                                    │  Dio (ApiBaseHelper)
                                    │  Authorization: Bearer <token>
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐        ┌────────────────────┐       ┌──────────────────┐
│ auth-service  │        │   user-service     │       │ hospital-service │
│               │        │                    │       │                  │
│ • send OTP    │        │ • create account   │       │ ★ DOCTOR MODULE  │
│ • verify OTP  │        │ • Business listing │       │                  │
│ • sessions    │        │ • Discover         │       │ • doctor profile │
└───────────────┘        │ • availability     │       │ • certificates   │
                         │ • gallery / photos │       │ • appointments   │
                         │ • testimonials     │       │ • doctor stats   │
                         │ • ratings          │       │                  │
                         │ • statistics       │       │ (hospital + OPD  │
                         │ • ENQUIRY          │       │  also live here, │
                         └─────────┬──────────┘       │  untouched)      │
                                   │                  └────────┬─────────┘
                                   │                           │
                                   │   both publish events     │
                                   └───────────┬───────────────┘
                                               ▼
                                    ┌────────────────────┐
                                    │    chat-service    │
                                    │ • in-chat cards    │
                                    │ • socket events    │
                                    │ • push notifications│
                                    └────────────────────┘
```

### What this means for you

You will call **three** services for one feature. That is normal here.

| You want to… | Call this service |
|---|---|
| Send/verify OTP, log in | `auth-service` |
| Create the account & business listing | `user-service` |
| Cover photo, profile photo, gallery | `user-service` |
| Availability (visiting days) | `user-service` |
| Testimonials, ratings, statistics | `user-service` |
| Discover list of doctors | `user-service` |
| Send an enquiry to a doctor | `user-service` |
| **Doctor's professional profile (About Me)** | **`hospital-service`** |
| **Certificates & Awards** | **`hospital-service`** |
| **Appointments / Booking tab** | **`hospital-service`** |
| Chat cards + realtime | `chat-service` (via socket — you do not POST to it) |

### How this maps to the existing Flutter architecture

The project already has everything you need:

| Layer | Where it lives | What to do |
|---|---|---|
| Base URL | `lib/environment_config.dart` → `baseUrl` | Nothing. Already set. |
| Endpoint constants | `lib/core/api/apiService/*_service_api.dart` mixins | Add doctor endpoint strings to `hospital_service_api.dart` |
| All mixins combined | `lib/core/api/apiService/base_service.dart` | Nothing. `HospitalServiceApi` is already mixed in. |
| HTTP client | `lib/core/api/apiService/api_base_helper.dart` | Use `getHTTP` / `postHTTP` / `putHTTP` / `deleteHTTP` / `postMultiImage` |
| Repositories | `feature/repo/` — a class `extends BaseService` | Create doctor repos following `hospital_opd_repo.dart` |
| State | GetX — `GetxController`, `.obs`, `Get.put()` | Create doctor controllers |
| Routes | `lib/core/routes/route_helper.dart` + `route_constant.dart` | Add doctor route names |

**Endpoint strings are relative.** `ApiBaseHelper` prepends `baseUrl` automatically.
So you write `'hospital-service/doctors'`, **not** the full URL.

---

## 3. Complete User Journey

There are **two different people** using this feature. Keep them separate in your head.

### Journey A — The Doctor (owner)

```
① Splash
     ↓
② Mobile Number screen        →  auth-service: send OTP
     ↓
③ OTP screen                  →  auth-service: verify OTP
     ↓
④ Account Type = BUSINESS
     ↓
⑤ Business Creation form      →  user-service: add-user
      (business_name = "Dr. Umesh Gupta",
       category = DOCTORS)        ⇒ creates User + Business + token
     ↓
⑥ Logged in — Doctor Dashboard (tabs: Booking | Overview | About Me | Posts | Statics)
     ↓
⑦ Check profile               →  hospital-service: GET /doctors/me
     │
     ├── hasProfile = false ──→ ⑧ Create Profile form
     │                             →  hospital-service: POST /doctors
     │                                ⇒ DOCTOR IS NOW LIVE
     │
     └── hasProfile = true  ──→ ⑨ Show dashboard
     ↓
⑩ About Me (edit)             →  hospital-service: PUT /doctors/me
⑪ Overview / Expertise        →  hospital-service: PUT /doctors/me
⑫ Cover + Profile photo       →  user-service: upload + update business
⑬ Gallery                     →  user-service: live-photos
⑭ Certificates & Awards       →  hospital-service: POST /doctor-certificates
⑮ Availability (visiting days)→  user-service: PUT /business/availability/hours
⑯ Posts                       →  existing posts flow
⑰ Statics                     →  hospital-service: GET /doctors/me/stats
                                 + user-service: views / visits / chat-clicks
     ↓
⑱ Booking tab                 →  hospital-service: GET /doctor-appointments/owner/me
      accept / decline           →  PUT /doctor-appointments/:id/status
```

### Journey B — The Customer (patient)

```
① Discover  →  Healthcare  →  "Clinic Doctors" tab
     ↓            user-service: GET /business/filter?category=DOCTORS
② Doctor list (cards show name, specialization, fee, experience)
     ↓
③ Tap a card → Public Doctor Profile
     ↓            user-service: GET /business/:id      (identity, photos, contact)
     ↓          hospital-service: GET /doctors/full/:userId  (degree, fee, certificates)
     ↓
④ Chat / Enquiry  →  user-service: POST /business-enquiries
     ↓                 ⇒ in-chat enquiry card appears
⑤ Doctor accepts the enquiry
     ↓
⑥ "Book Appointment" button appears
     ↓
⑦ Booking form  →  hospital-service: POST /doctor-appointments
     ↓                 ⇒ in-chat booking card appears
⑧ Doctor accepts / declines · Customer may cancel
     ↓
⑨ Done. No payment. The visit happens offline.
```

---

## 4. Screen by Screen Guide

### 4.1 Mobile Number Screen  *(already exists — reuse)*

| Aspect | Detail |
|---|---|
| **Purpose** | Collect phone number, trigger OTP |
| **Entry point** | Splash (not logged in), or logout |
| **Exit point** | OTP screen |
| **Navigation** | Push OTP screen with the phone number |
| **Validation** | 10-digit Indian mobile number |
| **Dependencies** | None |
| **Loading** | Blocking loader on the "Send OTP" button |
| **Error handling** | Show inline error under the field |
| **Success handling** | Navigate to OTP screen |
| **Empty state** | N/A |

> **Nothing to build.** This screen already exists and is shared by every account type.

---

### 4.2 OTP Screen  *(already exists — reuse)*

| Aspect | Detail |
|---|---|
| **Purpose** | Verify the phone number |
| **Entry point** | Mobile Number screen |
| **Exit point** | Account-type selection → Business Creation |
| **Navigation** | On success, continue the existing signup flow |
| **Validation** | OTP length as per existing implementation |
| **Dependencies** | Phone number from the previous screen |
| **Loading** | Blocking loader while verifying |
| **Error handling** | "Invalid OTP" inline; allow resend |
| **Success handling** | Proceed to account creation |
| **Empty state** | N/A |

> **Nothing to build.**

---

### 4.3 Business Creation (Doctor signup)  *(existing screen — one new option)*

| Aspect | Detail |
|---|---|
| **Purpose** | Create the doctor's `User` + `Business` in one call |
| **Entry point** | After OTP verification, account type = BUSINESS |
| **Exit point** | Doctor Dashboard |
| **Navigation** | On success, save the token and go to the dashboard |
| **Validation** | Business name required; category must be selected |
| **Dependencies** | Category list from `user-service/business/getAllcategories` |
| **Loading** | Blocking loader — this is a one-shot signup |
| **Error handling** | Show server message; keep the form filled |
| **Success handling** | Store token + userId + businessId, go to dashboard |
| **Empty state** | N/A |

**The only new thing here:** the doctor picks the healthcare category **`DOCTORS`**
(the UI label is "Clinic Doctors" / "Doctors"). `CLINICS` also works and behaves identically.

> **Important:** the doctor's **name is the business name**. Enter `"Dr. Umesh Gupta"` as
> `business_name`. The backend copies it onto the user record, which is why the name shows
> everywhere without a separate field.

---

### 4.4 Doctor Dashboard (tab host)  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | Host the 5 tabs: **Booking · Overview · About Me · Posts · Statics** |
| **Entry point** | After login, when `account_type = BUSINESS` and category is `DOCTORS`/`CLINICS` |
| **Exit point** | Any tab, or logout |
| **Navigation** | Tab bar; each tab keeps its own scroll position |
| **Validation** | None |
| **Dependencies** | `GET /doctors/me` **must** run before showing tabs |
| **Loading** | Full-screen skeleton on first load only |
| **Error handling** | If `/doctors/me` fails → full-screen error + Retry |
| **Success handling** | `hasProfile=false` → show "Complete your profile" CTA over the tabs. `hasProfile=true` → render tabs |
| **Empty state** | Profile missing → prominent "Create Profile" card |

**Header items (already exist):** hamburger, "Earn", notification bell, **"Go live" toggle**
(the Go-live toggle uses the existing `user-service/business/availability/go-live` /
`end-live` endpoints — nothing new).

---

### 4.5 Overview Tab  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | Public-facing summary: cover photo, expertise, certificates, gallery, testimonials, contact |
| **Entry point** | Dashboard tab |
| **Exit point** | Edit sheets, "View All" certificates, "Add Photo" |
| **Navigation** | Pencil icon on Expertise → edit sheet. "View All" → certificates list |
| **Validation** | Expertise entries: non-empty, max 30 |
| **Dependencies** | `GET /doctors/me` (expertise + certificates), `GET /business/:id` (photos, contact) |
| **Loading** | Section-level skeletons — do **not** block the whole tab |
| **Error handling** | Per-section: failed section shows a small retry row; other sections still render |
| **Success handling** | After an edit, update local state; no full reload needed |
| **Empty state** | Expertise empty → "Add your expertise". Certificates empty → "Add certificate". Gallery empty → "Add Photo" placeholder |

**Sections and where the data comes from:**

| Section | Source |
|---|---|
| Joined date | `Business.created_at` (user-service) |
| Name + verified tick + subtitle | `Business.business_name`; subtitle = `specialization[0]` |
| ★ 4.8 (48 reviews) | `Business.avg_rating` / `total_ratings` |
| Cover Photo (+ Edit) | `Business.coverPicture` |
| **Expertise** (bullets, ✏️) | **`DoctorProfile.expertise[]`** 🆕 |
| **Certificate & Awards** (View All) | **`GET /doctor-certificates/me`** 🆕 |
| Gallery (+ Add Photo) | `Business.live_photos[]` |
| Testimonials (+ Reply) | `user-service/testimonials/public/:userId` |
| Contact Us + map | `Business` fields: website, email, phone, address, `business_location` |

---

### 4.6 About Me Tab — VIEW mode  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | Read-only display of the doctor's professional details |
| **Entry point** | Dashboard tab |
| **Exit point** | "Edit" → About Me edit form |
| **Navigation** | Edit button top-right |
| **Validation** | None (read-only) |
| **Dependencies** | `GET /doctors/me` |
| **Loading** | Row skeletons |
| **Error handling** | Inline retry |
| **Success handling** | Render rows |
| **Empty state** | If `hasProfile=false` → "Complete your profile" CTA instead of empty rows |

**Rows, in UI order, and the exact field each maps to:**

| UI row | API field | Display note |
|---|---|---|
| Degree | `degree[]` | Join with `", "` |
| Specialization | `specialization[]` | Join with `", "` |
| Experience | `experienceYears` | Render as `"16 Years"` |
| Registration Number | `registrationNumber` | Plain text |
| Consultation Fee | `consultationFee` + `feeType` | Render as `"₹600/Visit"` |
| Languages Spoken | `languagesSpoken[]` | Join with `", "` |
| Address | `address` | Plain text |
| Description | `description` | Expandable (`readmore` package already in the project) |
| Consultation Availability | **user-service** `GET /business/availability/hours` | `"Monday: 9:00 AM – 6:00 PM"` + expandable day list |

> ⚠️ **Availability is NOT part of `GET /doctors/me`.** It is a separate call to
> user-service. The About Me tab therefore needs **two** API calls.

---

### 4.7 About Me Tab — EDIT form  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | Create or update the professional profile |
| **Entry point** | "Edit" on About Me, or "Create Profile" CTA |
| **Exit point** | "SaVe" → back to view mode |
| **Navigation** | Back arrow warns about unsaved changes |
| **Validation** | See [Section 10](#10-validation-rules) — validate **before** calling the API |
| **Dependencies** | `GET /doctors/me` to prefill (skip when creating) |
| **Loading** | Blocking loader on Save only |
| **Error handling** | Map the server `message` to the right field where possible |
| **Success handling** | Show success toast, refresh local profile, pop back |
| **Empty state** | N/A |

**Field types — this matters:**

- **Degree / Specialization / Language Spoken** are **chip inputs**: a text field plus an
  **"Add"** button. Each tap adds one entry to a list. Show added entries as removable chips.
  Send the whole list as a JSON array.
- **Experience / Registration Number / Consultation Fee / Address** are single text fields.
- **Description** is a textarea with a live counter — the UI shows `50/1000`.
- **Consultation Availability** is a button (`"Add Your Visiting Days"`) opening a calendar
  sheet. That sheet saves to **user-service**, not to `/doctors/me`.

**Which endpoint does Save call?**

- Profile does **not** exist yet (`hasProfile=false`) → `POST /doctors`
- Profile exists → `PUT /doctors/me`

Get this wrong and you will see `400 "User already has a doctor profile"`.

---

### 4.8 Certificates screen  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | List / add / edit / delete Certificate & Awards |
| **Entry point** | "View All" on Overview |
| **Exit point** | Back, or add/edit sheet |
| **Navigation** | FAB or "+" to add; tap a card to edit; swipe/long-press to delete |
| **Validation** | `title` required, ≤200 chars; description ≤1000; issuedBy ≤200 |
| **Dependencies** | Doctor profile **must exist first** |
| **Loading** | Grid skeleton; blocking loader while uploading an image |
| **Error handling** | `404 "Create your doctor profile before adding certificates"` → send the user to the profile form |
| **Success handling** | Prepend the new certificate to the local list (API returns newest-first) |
| **Empty state** | Illustration + "Add your first certificate" |

---

### 4.9 Availability screen  *(existing — reuse)*

| Aspect | Detail |
|---|---|
| **Purpose** | Set weekly visiting days and hours |
| **Entry point** | "Add Your Visiting Days" on the About Me form |
| **Exit point** | Save → back |
| **Navigation** | Modal sheet or full screen |
| **Validation** | End time after start time; at least one open day |
| **Dependencies** | Business must exist |
| **Loading** | Blocking on save |
| **Error handling** | Standard |
| **Success handling** | Refresh the availability line on About Me |
| **Empty state** | All days closed by default |

> **Nothing new to build** if the business availability screen already exists — point the
> doctor flow at the same screen. Endpoints: `PUT`/`GET /user-service/business/availability/hours`.

---

### 4.10 Statics (Statistics) Tab  🆕 partly

| Aspect | Detail |
|---|---|
| **Purpose** | Show the doctor how their practice is performing |
| **Entry point** | Dashboard tab |
| **Exit point** | Tap a tile → filtered Booking list |
| **Navigation** | Tapping "Pending" opens Booking tab filtered to `status=pending` |
| **Validation** | None |
| **Dependencies** | 2–4 calls (see [Section 17](#17-statistics-screen)) |
| **Loading** | Per-tile shimmer |
| **Error handling** | A failed source shows `--` in its tile; other tiles still render |
| **Success handling** | Render numbers |
| **Empty state** | All zeros is a valid state — show `0`, not an empty screen |

---

### 4.11 Booking Tab (doctor's inbox)  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | See and act on appointment requests |
| **Entry point** | Dashboard tab, notification tap, or Statics tile |
| **Exit point** | Appointment detail |
| **Navigation** | Status filter chips: All / Pending / Accepted / Declined / Cancelled |
| **Validation** | None |
| **Dependencies** | `GET /doctor-appointments/owner/me` |
| **Loading** | List skeleton; per-card button spinner on accept/decline |
| **Error handling** | `409` → the request was already resolved; refresh the list |
| **Success handling** | Update that card's status in place — do **not** reload the whole list |
| **Empty state** | "No appointment requests yet" |

**Pagination:** infinite scroll using `page` / `limit` (limit max 100, default 20).

---

### 4.12 Public Doctor Profile (customer view)  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | What a patient sees before enquiring/booking |
| **Entry point** | Discover doctor card, chat card header, deep link |
| **Exit point** | Chat, Enquiry sheet, Booking sheet |
| **Navigation** | "Chat" and "Book Appointment" CTAs |
| **Validation** | None |
| **Dependencies** | **Two** calls: `GET /business/:id` **and** `GET /doctors/full/:userId` |
| **Loading** | Full skeleton |
| **Error handling** | If `/doctors/full/:userId` 404s → **still render the page** using business data only |
| **Success handling** | Merge both responses into one view model |
| **Empty state** | Doctor has no professional details yet → hide those rows, keep the page usable |

> ⚠️ **Critical:** `GET /doctors/full/:userId` returning **404** is normal — it means the
> doctor registered but has not completed their profile. Never show a full-page error for it.

---

### 4.13 Booking form (customer)  🆕

| Aspect | Detail |
|---|---|
| **Purpose** | Request an appointment |
| **Entry point** | "Book Appointment" on the public profile, or after an accepted enquiry |
| **Exit point** | Success → chat conversation showing the new card |
| **Navigation** | Bottom sheet or full screen |
| **Validation** | Date required and not in the past |
| **Dependencies** | `business_id` (from Discover); optional `enquiry_id` |
| **Loading** | Blocking loader (uploads may take time) |
| **Error handling** | See the error table in [Section 5.13](#513-post-doctor-appointments) |
| **Success handling** | Close the sheet, open/refresh the chat, show a success toast |
| **Empty state** | N/A |

---

## 5. API Integration

### Common to every API below

| Item | Value |
|---|---|
| **Base URL** | `baseUrl` from `lib/environment_config.dart` (prod: `https://be.beapp.in/api/`) |
| **How to write endpoints** | Relative, e.g. `hospital-service/doctors`. `ApiBaseHelper` prepends the base URL. |
| **Auth header** | `Authorization: Bearer <token>` — added automatically by the Dio interceptor |
| **Content type** | `application/json` unless multipart is stated |
| **Success envelope** | `{ "success": true, ... }` |
| **Error envelope** | `{ "success": false, "message": "<human readable>" }` |
| **Pagination envelope** | `{ "pagination": { "totalCount", "page", "limit", "totalPages" } }` |

---

### 5.1 `POST /doctors` — Create doctor profile

| | |
|---|---|
| **Purpose** | Create the doctor's professional profile. **Makes the doctor live immediately.** |
| **Method** | POST |
| **Endpoint** | `hospital-service/doctors` |
| **Auth** | ✅ Required |
| **Multipart** | ❌ No — JSON only |
| **Query / Path params** | None |

**Request body** (every field optional; send what the form has):

```json
{
  "degree": ["MBBS", "MD (General Medicine)", "DM (Cardiology)"],
  "specialization": ["Cardiologist"],
  "languagesSpoken": ["English", "Hindi", "Bengali"],
  "expertise": ["Angioplasty", "Echocardiography"],
  "experienceYears": 16,
  "registrationNumber": "2345/MC/2015",
  "consultationFee": 600,
  "feeType": "Per Visit",
  "address": "123 Park Street, Near Metro Station, Kolkata - 700016",
  "description": "I am a Cardiologist with over 16 years of experience..."
}
```

**Success — `201`**

```json
{
  "success": true,
  "data": {
    "_id": "68f1...",
    "userId": "68a2...",
    "degree": ["MBBS", "MD (General Medicine)"],
    "specialization": ["Cardiologist"],
    "languagesSpoken": ["English", "Hindi"],
    "expertise": [],
    "experienceYears": 16,
    "registrationNumber": "2345/MC/2015",
    "consultationFee": 600,
    "feeType": "Per Visit",
    "address": "123 Park Street...",
    "description": "...",
    "createdAt": "2026-07-29T10:00:00.000Z",
    "updatedAt": "2026-07-29T10:00:00.000Z"
  }
}
```

**Errors**

| Code | When | Message |
|---|---|---|
| 400 | Already has a profile | `User already has a doctor profile` |
| 400 | Array field sent as string | `degree must be an array of strings` |
| 400 | >30 entries | `<field> cannot have more than 30 entries` |
| 400 | Bad experience | `experienceYears must be a number between 0 and 80` |
| 400 | Bad fee | `consultationFee must be a number >= 0` |
| 400 | Bad fee type | `feeType must be one of: Per Visit, Per Hour, Per Session` |
| 400 | Long description | `description cannot exceed 1000 characters` |
| 401 | No/expired token | `Not authorized` |

**Retry behaviour:** ❌ Never auto-retry. A silent retry after a timeout can produce
`400 "User already has a doctor profile"`. On timeout, call `GET /doctors/me` to find out
whether it actually succeeded, then decide.

**Call when:** the user taps Save and `hasProfile == false`.
**Do NOT call when:** a profile already exists — use `PUT /doctors/me`.

---

### 5.2 `GET /doctors/me` — My profile

| | |
|---|---|
| **Purpose** | Load the logged-in doctor's profile **plus certificates** |
| **Method** | GET · **Endpoint** `hospital-service/doctors/me` · **Auth** ✅ |

**Success — `200` (profile exists)**

```json
{
  "success": true,
  "hasProfile": true,
  "data": {
    "_id": "68f1...",
    "userId": "68a2...",
    "degree": ["MBBS"],
    "specialization": ["Cardiologist"],
    "languagesSpoken": ["English"],
    "expertise": ["Angioplasty"],
    "experienceYears": 16,
    "registrationNumber": "2345/MC/2015",
    "consultationFee": 600,
    "feeType": "Per Visit",
    "address": "...",
    "description": "...",
    "certificates": [
      {
        "_id": "68f2...",
        "doctorProfileId": "68f1...",
        "userId": "68a2...",
        "title": "Membership Certificate",
        "description": "Awarded for distinguished service.",
        "imageUrl": "https://....s3.ap-south-1.amazonaws.com/doctor-certificates/xxx.png",
        "issuedBy": "United Nation Inter-Governmental Organization",
        "issuedDate": "2020-06-01T00:00:00.000Z",
        "createdAt": "...",
        "updatedAt": "..."
      }
    ]
  }
}
```

**Success — `200` (no profile yet)**

```json
{
  "success": true,
  "data": null,
  "hasProfile": false,
  "message": "No doctor profile found for this user"
}
```

> ⚠️ **This is a `200`, not a `404`.** Always branch on `hasProfile`. Treating this as an
> error is the single most common integration mistake here.

**Retry:** ✅ Safe to auto-retry once on timeout.
**Call when:** dashboard opens; after create/update; on pull-to-refresh.
**Do NOT call when:** rendering another user's profile — use `GET /doctors/full/:userId`.

---

### 5.3 `PUT /doctors/me` — Update my profile

| | |
|---|---|
| **Purpose** | Partially update the profile |
| **Method** | PUT · **Endpoint** `hospital-service/doctors/me` · **Auth** ✅ · JSON only |

**Partial semantics — important:** only the keys you send are written. Send just the About
Me fields when saving About Me, and just `expertise` when saving Overview. Omitted keys keep
their current values.

```json
{ "expertise": ["Angioplasty", "Echocardiography", "Pacemaker Implantation"] }
```

**Success — `200`:** `{ "success": true, "data": { ...updated profile... } }`

**Errors:** same 400s as create · `404 "No doctor profile found for this user"` · `401`

> ⚠️ Sending `"degree": []` **clears** the list. To leave a field alone, omit the key entirely.

**Retry:** ✅ Safe — idempotent.

---

### 5.4 `DELETE /doctors/me` — Delete my profile

| | |
|---|---|
| **Method** | DELETE · **Endpoint** `hospital-service/doctors/me` · **Auth** ✅ |

Deletes the profile **and all certificates**. Appointments are kept so both sides retain
their history.

**Success — `200`:** `{ "success": true, "message": "Doctor profile and certificates deleted successfully" }`
**Errors:** `404` (no profile) · `401`

**Always show a confirmation dialog.** Retry: ❌ never automatically.

---

### 5.5 `GET /doctors/me/stats` — My booking analytics

| | |
|---|---|
| **Method** | GET · **Endpoint** `hospital-service/doctors/me/stats` · **Auth** ✅ |

**Success — `200`**

```json
{
  "success": true,
  "data": {
    "appointments": { "pending": 4, "accepted": 12, "declined": 1, "cancelled": 2, "total": 19 },
    "upcomingAccepted": 5,
    "certificateCount": 3
  }
}
```

`upcomingAccepted` = accepted appointments dated today or later.
All four statuses are always present, even when `0`.

**Call when:** Statics tab opens or is pulled to refresh. **Do NOT** call on every tab switch.

---

### 5.6 `GET /doctors/full/:userId` — Public full profile

| | |
|---|---|
| **Purpose** | A patient viewing a doctor's profile |
| **Method** | GET · **Endpoint** `hospital-service/doctors/full/{userId}` · **Auth** ❌ Public |
| **Path param** | `userId` = the **owner's** user id — i.e. `Business.user_id` from Discover |

**Success — `200`:** same shape as `GET /doctors/me` `data`, including `certificates[]`.
**Errors:** `404 "Doctor profile not found"` — **normal**, means the profile is incomplete.

> ⚠️ Pass **`Business.user_id`**, not `Business._id`, and not `DoctorProfile._id`.

---

### 5.7 `GET /doctors/:id` — Basic profile by profile id

| | |
|---|---|
| **Method** | GET · **Endpoint** `hospital-service/doctors/{id}` · **Auth** ❌ Public |
| **Path param** | `id` = `DoctorProfile._id` |

Returns the profile **without** certificates. Rarely needed — prefer 5.6.
**Errors:** `400` invalid id · `404` not found.

---

### 5.8 `GET /doctors` — Public list / search

| | |
|---|---|
| **Method** | GET · **Endpoint** `hospital-service/doctors` · **Auth** ❌ Public |

**Query params** (all optional): `specialization`, `degree`, `language` (exact,
case-insensitive), `search` (substring across specialization/degree/expertise),
`minExperience`, `maxFee`, `page` (default 1), `limit` (default 20, max 100).

**Success — `200`:** `{ "success": true, "data": [ ...profiles... ], "pagination": {...} }`
**Errors:** `400` on non-numeric `minExperience` / `maxFee`.

> ⚠️ **Do not use this for Discover.** It returns `DoctorProfile` documents whose `_id`
> **cannot** be used to book. Discover must use `user-service/business/filter` (see
> [Section 14](#14-discover-integration)). Use this endpoint only for a
> "search doctors by specialization" feature, and map results to listings via `userId`.

---

### 5.9 `POST /doctor-certificates` — Add certificate

| | |
|---|---|
| **Method** | POST · **Endpoint** `hospital-service/doctor-certificates` · **Auth** ✅ |
| **Multipart** | ✅ Optional — two ways to send the image |

**Option A — JSON** (image already uploaded via presign):

```json
{
  "title": "Membership Certificate",
  "description": "Awarded for distinguished service.",
  "imageUrl": "https://bucket.s3.ap-south-1.amazonaws.com/uploads/xxx.png",
  "issuedBy": "United Nation Inter-Governmental Organization",
  "issuedDate": "2020-06-01"
}
```

**Option B — multipart/form-data**: text fields as normal parts plus a single file part
named **`image`** (≤10 MB). The backend uploads it to S3 and stores the URL.

> **Recommendation:** use **Option B**. It is one request instead of three and the project
> already has `postMultiImage` in `ApiBaseHelper`.

**Success — `201`:** `{ "success": true, "data": { ...certificate... } }`

**Errors**

| Code | When | Message |
|---|---|---|
| 400 | Missing title | `title is required` |
| 400 | Title too long | `title cannot exceed 200 characters` |
| 400 | Description too long | `description cannot exceed 1000 characters` |
| 400 | Bad date | `issuedDate must be a valid ISO date` |
| 400 | File too large / >1 file | `Image upload error: <detail>` |
| 404 | No doctor profile yet | `Create your doctor profile before adding certificates` |

**Retry:** ❌ Never auto-retry — you will create duplicates.

---

### 5.10 `GET /doctor-certificates/me` — My certificates

`GET hospital-service/doctor-certificates/me` · Auth ✅ · Returns
`{ "success": true, "data": [ ... ] }`, newest first, **not paginated**.

> Already included in `GET /doctors/me`. Use this only when refreshing the certificates
> list on its own.

---

### 5.11 `GET /doctor-certificates/doctor/:doctorProfileId` — Public certificates

`GET hospital-service/doctor-certificates/doctor/{doctorProfileId}` · Auth ❌ Public.
Path param is `DoctorProfile._id`. Errors: `400` invalid id.

> Also already included in `GET /doctors/full/:userId`. Use only for a standalone
> "View All" screen opened directly.

---

### 5.12 `PUT` / `DELETE /doctor-certificates/:id`

| | |
|---|---|
| **PUT** | `hospital-service/doctor-certificates/{id}` · Auth ✅ · JSON or multipart (`image`) |
| **DELETE** | `hospital-service/doctor-certificates/{id}` · Auth ✅ |

PUT is partial — send only changed fields. Sending a new `image` replaces the URL.
**Errors:** `400` invalid id/validation · `404 "Certificate not found or unauthorized"`
(this single message covers both "does not exist" and "not yours" — do not leak the difference).

DELETE success: `{ "success": true, "message": "Certificate deleted" }`. Confirm first.

---

### 5.13 `POST /doctor-appointments`

| | |
|---|---|
| **Purpose** | Customer requests an appointment |
| **Method** | POST · **Endpoint** `hospital-service/doctor-appointments` · **Auth** ✅ |
| **Multipart** | ✅ Optional |

**Option A — JSON**

```json
{
  "business_id": "68b7...",
  "appointmentDate": "2026-08-05",
  "preferredTime": "10:00 – 11:00 AM",
  "patientName": "Ramesh Kumar",
  "enquiry_id": "68c9...",
  "note": "Diabetic patient, needs morning slot"
}
```

**Option B — multipart/form-data**: one part named **`payload`** containing the **JSON string
above**, plus up to **5** file parts named **`photos`** (≤10 MB each) for reports/prescriptions.

| Field | Type | Required | Notes |
|---|---|---|---|
| `business_id` (or `businessId`) | ObjectId string | ✅ | `Business._id` from Discover |
| `appointmentDate` (or `appointment_date`) | date string | ✅ | Today or later |
| `preferredTime` | string | ⬦ | Free text |
| `patientName` | string | ⬦ | Who the visit is for |
| `enquiry_id` (or `enquiryId`) | ObjectId string | ⬦ | The customer's `BusinessEnquiry._id` |
| `note` | string | ⬦ | Free text |
| `photos` | file[] | ⬦ | Multipart only, max 5 |

> ⚠️ **There is no `opd_id`.** That field belongs to the *hospital* booking API. The doctor's
> name, specialization and fee are snapshotted **server-side** — never send them.

**Success — `201`**

```json
{
  "success": true,
  "message": "Appointment request sent",
  "data": { "appointmentId": "68d1...", "status": "pending" }
}
```

**Errors**

| Code | When | Message |
|---|---|---|
| 400 | Bad/missing business id | `A valid business_id is required` |
| 400 | Bad/missing date | `A valid appointmentDate is required` |
| 400 | Past date | `appointmentDate cannot be in the past` |
| 400 | Bad enquiry id | `enquiry_id must be a valid id` |
| 400 | Booking your own listing | `You cannot book an appointment on your own listing` |
| 400 | >5 photos | `A maximum of 5 photos is allowed` |
| 400 | Bad multipart payload | `Invalid JSON in payload field` |
| 404 | Listing missing/inactive | `Doctor listing not found` |
| 500 | user-service unreachable | server message |

**Retry:** ❌ Never auto-retry — duplicate bookings. On timeout, refresh
`GET /doctor-appointments/me` and check before letting the user resubmit.

**Do NOT call when:** the customer is the doctor themselves; the date is in the past
(block client-side); or `business_id` is missing.

---

### 5.14 `PUT /doctor-appointments/:appointmentId/status`

`PUT hospital-service/doctor-appointments/{appointmentId}/status` · Auth ✅

```json
{ "status": "accepted" }
```

| status | Who may set it | Allowed from |
|---|---|---|
| `accepted` | **doctor only** | `pending` |
| `declined` | **doctor only** | `pending` |
| `cancelled` | **customer only** | `pending` or `accepted` |

**Success — `200`:** `{ "success": true, "message": "Appointment accepted", "data": { "appointmentId": "...", "status": "accepted" } }`

**Errors**

| Code | When | Message |
|---|---|---|
| 400 | Bad id / bad status | `status must be 'accepted', 'declined' or 'cancelled'` |
| 403 | Customer tried accept/decline | `Only the doctor can accept or decline this appointment` |
| 403 | Doctor tried cancel | `Only the customer who requested this appointment can cancel it` |
| 404 | Not found | `Appointment not found` |
| 409 | Already resolved | `Appointment has already been declined` |

**Retry:** ✅ Safe. Re-sending the **same** status returns `200` (idempotent). A **different**
status on a resolved appointment returns `409` — on `409`, refresh the list; the other party
already acted.

---

### 5.15 List & detail endpoints

| Endpoint | Auth | Returns |
|---|---|---|
| `GET hospital-service/doctor-appointments/me` | ✅ customer | Requests I sent |
| `GET hospital-service/doctor-appointments/owner/me` | ✅ doctor | **The Booking tab** |
| `GET hospital-service/doctor-appointments/{appointmentId}` | ✅ participant | One appointment |

Query params: `status`, `page`, `limit` (max 100). Standard pagination envelope.

**Appointment document shape**

```jsonc
{
  "_id": "68d1...",
  "customerId": "68a9...",
  "ownerId": "68a2...",           // the doctor
  "businessId": "68b7...",        // Business._id
  "doctorProfileId": "68f1...",   // may be null
  "category": "DOCTOR",
  "doctorName": "Dr. Umesh Gupta",
  "specialization": "Cardiologist",
  "fees": 600,                    // display only — nothing is charged
  "feeType": "Per Visit",
  "doctorImage": "https://...",
  "appointmentDate": "2026-08-05T00:00:00.000Z",
  "preferredTime": "10:00 – 11:00 AM",
  "patientName": "Ramesh Kumar",
  "enquiryId": "68c9...",         // or null
  "note": "Diabetic patient",
  "photos": ["https://...", "https://..."],
  "listingName": "Dr. Umesh Gupta",
  "listingImage": "https://...",
  "location": "123 Park Street, Kolkata",
  "status": "pending",
  "createdAt": "...",
  "updatedAt": "..."
}
```

**`GET /{appointmentId}`** errors: `400` invalid id · `403 "You are not a participant of this appointment"` · `404`.

---

### 5.16 Admin endpoints (read-only)

| Endpoint | Purpose |
|---|---|
| `GET hospital-service/doctors/admin` | List all doctor profiles |
| `GET hospital-service/doctors/admin/stats` | Vertical-wide analytics |
| `GET hospital-service/doctor-appointments/admin` | List all appointments |

Auth ✅ and the account must be Admin/SubAdmin, else `403`.

> ⚠️ **These are view-only.** There is no approve, reject, activate or deactivate endpoint.
> Do not build any approval UI. Only build these screens if you are building the internal
> admin app.

---

### 5.17 Reused endpoints (not new, but you must call them)

| Purpose | Method + Endpoint | Service |
|---|---|---|
| Send OTP | `POST auth-service/sent-otp` | auth |
| Verify OTP | `POST auth-service/verify-otp` | auth |
| Create account + business | `POST user-service/user/add-user` | user |
| Business profile by id | `GET user-service/business/{id}` | user |
| Business by user id | `GET user-service/business/user/{userId}` | user |
| Discover list | `GET user-service/business/filter` | user |
| Update business (cover/profile/desc) | `PUT user-service/business/updateBusinessProfile` | user |
| Add gallery photo | `POST user-service/business/live-photosOne` | user |
| Remove gallery photo | `DELETE user-service/business/remove-live-image` | user |
| Get/Set availability | `GET`/`PUT user-service/business/availability/hours` | user |
| Today override | `PUT`/`DELETE user-service/business/availability/today` | user |
| Go live / end live | `POST user-service/business/availability/go-live` / `end-live` | user |
| Testimonials | `POST user-service/testimonials/add-testimonial`, `GET user-service/testimonials/public/{userId}` | user |
| Ratings | `POST`/`GET user-service/business/{businessId}/ratings` | user |
| Record a view | `POST user-service/business/{businessId}/view` | user |
| Profile visits | `POST`/`GET user-service/profile-visit/{userId}/profile-visit(s)` | user |
| Chat clicks | `POST`/`GET user-service/business/{userId}/chat-click(s)` | user |
| Presigned upload | `GET user-service/upload/init` | user |
| **Send an enquiry** | `POST user-service/business-enquiries` | user |
| Enquiry status | `PUT user-service/business-enquiries/{enquiryId}/status` | user |
| Enquiry by id | `GET user-service/business-enquiries/{enquiryId}` | user |

**All of these already exist as constants in `lib/core/api/apiService/user_service_api.dart`
and `auth_service_api.dart`.** Do not redefine them.

---

## 6. Authentication Flow

### The full picture

```
Phone number
     ↓
POST auth-service/sent-otp          { contact_no }
     ↓
POST auth-service/verify-otp        { contact_no, otp }
     ↓
POST user-service/user/add-user     (multipart: logo_image + fields)
     account_type = "BUSINESS"
     category_Of_Business = "DOCTORS"
     ↓
Response contains: token, user, business
     ↓
Save token → authTokenGlobal + secure storage
     ↓
Every later request: Authorization: Bearer <token>
```

### Key facts

- **There is no doctor-specific login.** A doctor logs in exactly like any other business.
  Nothing new to build in the auth layer.
- **The token is a JWT containing a `sessionId`.** The backend validates the session with
  the auth service on every protected call. You do not manage sessions manually.
- **There is no refresh-token endpoint.** When the token expires the server returns `401`.
- **`401` handling is already built.** `AuthManager.handleLogout()` in `api_base_helper.dart`
  clears state and navigates to the login route. **Do not write your own 401 handling** in
  the doctor repos — you will double-fire the logout.
- **Logout** uses the existing flow. Clear any doctor controllers you registered with
  `Get.put()` so a second account does not see the first doctor's cached data.

### Which doctor APIs need a token?

| Needs token ✅ | Public ❌ |
|---|---|
| `POST /doctors` | `GET /doctors` |
| `GET /doctors/me` | `GET /doctors/full/:userId` |
| `PUT /doctors/me` | `GET /doctors/:id` |
| `DELETE /doctors/me` | `GET /doctor-certificates/doctor/:doctorProfileId` |
| `GET /doctors/me/stats` | |
| All `/doctor-certificates` writes + `/me` | |
| All `/doctor-appointments` | |
| All `/doctors/admin*` (+ admin role) | |

> Public endpoints still work with a token attached — harmless. But guest users must be able
> to browse a doctor's public profile, so never gate those screens behind login.

---

## 7. Image Upload Flow

There are **two upload mechanisms** in this feature. Use the right one.

### Mechanism 1 — Presigned URL (user-service)

Used for **cover photo, profile photo, gallery**.

```
① GET user-service/upload/init?fileName=x.jpg&fileType=image/jpeg
        ↓ returns { uploadUrl, publicUrl, fileKey }
② PUT the raw file bytes to `uploadUrl` (direct to S3, no auth header)
        ↓
③ Send `publicUrl` to the relevant user-service endpoint
```

### Mechanism 2 — Direct multipart (hospital-service)

Used for **certificate images** and **appointment photos**. One request; the server uploads
to S3 for you.

### Per-item rules

| Item | Mechanism | Endpoint | Max count | Max size | Field name |
|---|---|---|---|---|---|
| Profile photo | Presign → business update | `user-service/business/updateBusinessProfile` | 1 | per existing flow | `logo` |
| Cover photo | Presign → business update | `user-service/business/updateBusinessProfile` | 1 | per existing flow | `coverPicture` |
| Gallery | Presign → live-photos | `user-service/business/live-photosOne` | per existing flow | per existing flow | — |
| **Certificate image** | **Direct multipart** | `hospital-service/doctor-certificates` | **1** | **10 MB** | **`image`** |
| **Appointment photos** | **Direct multipart** | `hospital-service/doctor-appointments` | **5** | **10 MB each** | **`photos`** |

### Allowed formats

The backend does not restrict MIME type — it stores whatever you send and serves it back.
**Enforce this on the client:** allow `jpg`, `jpeg`, `png`, `webp` only. The project already
uses `image_picker` + `croppy`; reuse them so images are compressed before upload.

### Multipart specifics for appointments

The appointment endpoint is **not** a flat multipart form. It expects:

- one text part named **`payload`** whose value is the **JSON string** of all fields,
- plus up to five file parts all named **`photos`**.

Sending fields as individual form parts will **not** work.

### Failure behaviour

- Upload errors surface as `400` with `Photo upload error: <detail>` or
  `Image upload error: <detail>`.
- If a presigned upload fails at step ②, **do not** call step ③ — you would save a broken URL.
- Compress and validate size **before** uploading; a 10 MB rejection after a long upload on
  mobile data is a bad experience.

---

## 8. Screen State Management

Using GetX, as the rest of the project does.

| Screen | Controller should hold | Cache? | Refresh when |
|---|---|---|---|
| Doctor Dashboard | `profile`, `hasProfile`, `isLoading`, `error` | ✅ In memory for the session | Pull-to-refresh; after any profile write |
| Overview | `expertise`, `certificates`, business snapshot | ✅ Reuse the dashboard's profile | After edit; pull-to-refresh |
| About Me (view) | Profile + availability | ✅ | After edit |
| About Me (edit) | Local form state only | ❌ Never cache a half-filled form as truth | Prefill once on open |
| Certificates | `List<Certificate>`, `isLoading` | ✅ | After add/edit/delete (update in place) |
| Statics | Stats object | ⏱️ Short-lived — treat as stale after ~60s | Tab focus; pull-to-refresh |
| Booking tab | `List<Appointment>`, `page`, `hasMore`, `statusFilter` | ✅ Per filter | Pull-to-refresh; socket event; after status change |
| Public profile | Merged business + doctor view model | ✅ Per `businessId`, short-lived | On open |
| Discover list | Paged list | ✅ | Pull-to-refresh; category change; location change |

### Rules of thumb

- **One source of truth for the profile.** Load it once in the dashboard controller; every
  tab reads from there. Do not call `GET /doctors/me` in three tabs.
- **Update in place after writes.** `PUT /doctors/me` returns the updated document — write it
  into state rather than re-fetching.
- **Never cache across accounts.** On logout, dispose every doctor controller.
- **Do not persist doctor data to Hive.** It changes often and is cheap to refetch. Hive is
  used in this project for chat and heavier caches.

---

## 9. API Calling Order

### 9.1 Doctor first-time onboarding

```
POST auth-service/sent-otp
      ↓
POST auth-service/verify-otp
      ↓
POST user-service/user/add-user            (category_Of_Business = DOCTORS)
      ↓  save token, userId, businessId
GET  hospital-service/doctors/me
      ↓
hasProfile == false
      ↓
Open "Create Profile" form
      ↓
POST hospital-service/doctors
      ↓  ⇒ DOCTOR IS LIVE
GET  hospital-service/doctors/me           (reload with certificates)
      ↓
Dashboard
```

### 9.2 Doctor returning login

```
Login (existing flow)
      ↓
GET user-service/business/user/{userId}    (business identity, photos, contact)
GET hospital-service/doctors/me            (professional profile) — run in parallel
      ↓
hasProfile ? Dashboard : "Complete your profile" CTA
```

> Run these two **in parallel**. They are independent.

### 9.3 Saving About Me

```
Validate locally
      ↓
hasProfile ? PUT /doctors/me : POST /doctors
      ↓
Write response into state
      ↓
Pop back to view mode
```

**Do not** call `GET /doctors/me` again — the write response already contains the profile.

### 9.4 Adding a certificate

```
Pick image → crop → compress
      ↓
POST hospital-service/doctor-certificates   (multipart: fields + `image`)
      ↓
Prepend result to the local certificates list
```

### 9.5 Setting availability

```
GET  user-service/business/availability/hours     (prefill)
      ↓
User edits the weekly schedule
      ↓
PUT  user-service/business/availability/hours
      ↓
Update the availability line on About Me
```

### 9.6 Statics tab

```
Parallel:
  GET hospital-service/doctors/me/stats                       (bookings)
  GET user-service/profile-visit/{userId}/profile-visits      (visits)
  GET user-service/business/{userId}/chat-clicks              (chat clicks)
  GET user-service/business/{businessId}/ratings              (rating summary)
      ↓
Render each tile as its own source resolves
```

### 9.7 Customer: Discover → profile → enquiry → booking

```
GET user-service/business/filter?category=DOCTORS&page=1&limit=20
      ↓  keep BOTH `_id` (businessId) and `user_id` (ownerUserId) from each card
Tap a card
      ↓
Parallel:
  GET user-service/business/{businessId}
  GET hospital-service/doctors/full/{ownerUserId}     (404 is OK)
      ↓
Tap "Chat"
      ↓
POST user-service/business-enquiries    { business_id, selections, note, photos[] }
      ↓  ⇒ enquiry card appears in chat
Doctor accepts → socket `healthcareEnquiryStatusUpdated`
      ↓
"Book Appointment" button appears
      ↓
POST hospital-service/doctor-appointments  { business_id, appointmentDate, enquiry_id }
      ↓  ⇒ booking card appears in chat
Doctor accepts → socket `healthcareBookingStatusUpdated`
```

### 9.8 Doctor handling a booking

```
GET hospital-service/doctor-appointments/owner/me?status=pending&page=1&limit=20
      ↓
Tap Accept
      ↓
PUT hospital-service/doctor-appointments/{id}/status  { status: "accepted" }
      ↓
Update that card in place  (do NOT reload the list)
```

---

## 10. Validation Rules

Validate **on the client first**. Every rule below is also enforced by the server, so a
missed client check becomes a `400`.

### Doctor profile

| Field | Required | Type | Rules | Server error |
|---|---|---|---|---|
| `degree` | ⬦ | string[] | ≤30 entries; trimmed; empties dropped; case-insensitive de-dupe | `degree must be an array of strings` / `cannot have more than 30 entries` |
| `specialization` | ⬦ | string[] | same as above | same |
| `languagesSpoken` | ⬦ | string[] | same as above | same |
| `expertise` | ⬦ | string[] | same as above | same |
| `experienceYears` | ⬦ | number | integer 0–80 | `experienceYears must be a number between 0 and 80` |
| `registrationNumber` | ⬦ | string | Free text, trimmed. **No regex, not unique** | — |
| `consultationFee` | ⬦ | number | ≥ 0 | `consultationFee must be a number >= 0` |
| `feeType` | ⬦ | enum | `Per Visit` \| `Per Hour` \| `Per Session` | `feeType must be one of: ...` |
| `address` | ⬦ | string | Free text, trimmed | — |
| `description` | ⬦ | string | ≤1000 chars | `description cannot exceed 1000 characters` |

**Notes:**
- **Nothing is strictly required.** A doctor can create an empty profile and fill it later.
  Enforce your own "at least specialization + fee" rule in the UI if the product wants it.
- **De-duplication is server-side and case-insensitive.** "English" and "english" collapse to
  one entry. Mirror this in the chip UI so the list does not visibly change after save.
- `registrationNumber` has **no format validation** and is **not unique** — two doctors may
  hold the same string. Do not build a "already taken" check.
- **Never send** `registrationVerified`, `isApproved`, `approvalStatus` or `userId`. They do
  not exist / are ignored. Ownership always comes from the token.

### Certificate

| Field | Required | Rules | Server error |
|---|---|---|---|
| `title` | ✅ | 1–200 chars | `title is required` / `title cannot exceed 200 characters` |
| `description` | ⬦ | ≤1000 chars | `description cannot exceed 1000 characters` |
| `issuedBy` | ⬦ | ≤200 chars | `issuedBy cannot exceed 200 characters` |
| `issuedDate` | ⬦ | ISO date, or `null`/`""` to clear | `issuedDate must be a valid ISO date` |
| `imageUrl` | ⬦ | String URL | — |
| `image` (file) | ⬦ | 1 file, ≤10 MB | `Image upload error: ...` |

### Appointment

| Field | Required | Rules | Server error |
|---|---|---|---|
| `business_id` | ✅ | Valid ObjectId (24 hex chars) | `A valid business_id is required` |
| `appointmentDate` | ✅ | Parseable date, **today or later** | `A valid appointmentDate is required` / `appointmentDate cannot be in the past` |
| `preferredTime` | ⬦ | Free text | — |
| `patientName` | ⬦ | Free text | — |
| `enquiry_id` | ⬦ | Valid ObjectId | `enquiry_id must be a valid id` |
| `note` | ⬦ | Free text | — |
| `photos` | ⬦ | ≤5 files, ≤10 MB each | `A maximum of 5 photos is allowed` |

**Date comparison is by calendar day** — booking for *today* is allowed. Disable past dates
in the picker; do not rely on the server alone.

### Appointment status

| Field | Rules |
|---|---|
| `status` | Exactly one of `accepted`, `declined`, `cancelled` |

Show **Accept/Decline** only to the doctor and **Cancel** only to the customer. Compare the
logged-in user id against `ownerId` / `customerId` on the appointment.

---

## 11. Error Handling

### By status code

| Code | Meaning | What Flutter should do |
|---|---|---|
| **400** | Validation failed | Show the server `message`. Map it to the offending field where you can. **Keep the form filled.** Never log the user out. |
| **401** | Token missing/expired | **Do nothing custom.** `AuthManager.handleLogout()` already clears state and routes to login. Adding your own handler will double-fire. |
| **403** | Wrong role for the action | Show the server message as a snackbar and **refresh the item** — usually the UI showed a button it should not have. |
| **404** | Not found | Depends: `GET /doctors/full/:userId` 404 = *normal*, render the page anyway. `PUT/DELETE /doctors/me` 404 = profile gone, send to create. `POST /doctor-certificates` 404 = create profile first. |
| **409** | Conflict — already resolved | The other party acted first. Show "This request was already <status>" and **refresh the list**. Never retry. |
| **422** | Not used by this module | If seen, treat exactly like `400`. |
| **500** | Server / dependency failure | "Something went wrong. Please try again." + Retry button. Do not auto-retry writes. |

### Non-HTTP failures

| Situation | What to do |
|---|---|
| **Timeout** | **Reads:** auto-retry once, then show Retry. **Writes:** never auto-retry — verify with a GET first (see 5.1 / 5.13). |
| **No internet** | The project already has `internet_connection_checker_plus`. Show an offline banner. Disable submit buttons. Serve cached read data if available. |
| **Image upload failed** | Keep the form open and the picked file selected. Show "Image upload failed — tap to retry". Never submit the record with a broken URL. |
| **OTP failed** | Existing auth flow handles it. Show "Invalid OTP", allow resend with a cooldown. |
| **Enquiry/booking created but chat card never appears** | The record **was** saved; only the chat card publish failed. Do **not** resubmit. The Booking tab (`/doctor-appointments/owner/me`) and enquiry inbox are the source of truth. Show "Request sent — check your Bookings". |

> **Important:** every write here (`POST /doctors`, certificates, appointments) responds to
> the client **before** the chat card is created. A missing card never means a missing record.

---

## 12. Loading States

| API | Loader | Blocking? |
|---|---|---|
| `POST auth-service/sent-otp` | Button spinner | ✅ Blocking |
| `POST auth-service/verify-otp` | Button spinner | ✅ Blocking |
| `POST user-service/user/add-user` | Full-screen | ✅ Blocking |
| `GET /doctors/me` (first load) | Full-screen skeleton | ⬦ Non-blocking (skeleton) |
| `GET /doctors/me` (refresh) | Pull-to-refresh spinner | ❌ Non-blocking |
| `POST /doctors` | Overlay on the Save button | ✅ Blocking |
| `PUT /doctors/me` | Overlay on the Save button | ✅ Blocking |
| `DELETE /doctors/me` | Dialog spinner | ✅ Blocking |
| `GET /doctors/me/stats` | Per-tile shimmer | ❌ Non-blocking |
| `GET /doctors/full/:userId` | Page skeleton | ❌ Non-blocking |
| `GET /doctors` | List skeleton (first page) / footer spinner (next pages) | ❌ Non-blocking |
| `GET /doctor-certificates/*` | Grid skeleton | ❌ Non-blocking |
| `POST/PUT /doctor-certificates` | Overlay + upload progress | ✅ Blocking |
| `DELETE /doctor-certificates/:id` | Card-level spinner | ❌ Non-blocking |
| `POST /doctor-appointments` | Full-screen with upload progress | ✅ Blocking |
| `PUT /doctor-appointments/:id/status` | Spinner **inside that card's button** | ❌ Non-blocking |
| `GET /doctor-appointments/*` | List skeleton / footer spinner | ❌ Non-blocking |
| `GET user-service/business/filter` | Card skeleton | ❌ Non-blocking |
| Availability GET/PUT | Sheet skeleton / button spinner | PUT ✅ Blocking |

> `ApiBaseHelper` has a `showProgress` flag. Pass `showProgress: false` for every
> non-blocking read (the existing repos do this — see `discover_repo.dart`).

---

## 13. UI Behaviour

| Screen | Skeleton | Pull to Refresh | Pagination | Infinite Scroll | Empty State | Retry Button | Offline |
|---|---|---|---|---|---|---|---|
| Doctor Dashboard | ✅ Full | ✅ | ❌ | ❌ | "Create profile" CTA | ✅ Full-screen | Show cached; banner |
| Overview | ✅ Per section | ✅ | ❌ | ❌ | Per section CTA | ✅ Per section | Cached |
| About Me (view) | ✅ Rows | ✅ | ❌ | ❌ | "Complete profile" | ✅ Inline | Cached |
| About Me (edit) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Disable Save |
| Certificates | ✅ Grid | ✅ | ❌ (not paginated) | ❌ | "Add your first certificate" | ✅ | Cached, disable add |
| Statics | ✅ Per tile | ✅ | ❌ | ❌ | Show `0`s | ✅ Per tile | Cached |
| Booking tab | ✅ List | ✅ | ✅ `page`/`limit` | ✅ | "No appointment requests yet" | ✅ | Cached, disable actions |
| Public profile | ✅ Full | ✅ | ❌ | ❌ | Hide missing rows | ✅ | Cached |
| Discover doctors | ✅ Cards | ✅ | ✅ | ✅ | "No doctors found nearby" | ✅ | Cached |

### Specific notes

- **Certificates are NOT paginated.** `GET /doctor-certificates/me` returns everything.
  If a doctor has 50+, virtualise the list client-side.
- **Infinite scroll:** load the next page when ~80% scrolled. Stop when
  `page >= pagination.totalPages`. Guard against double-firing at the boundary.
- **`limit` is capped at 100** server-side. Requesting more silently clamps.
- **Empty vs zero:** an all-zero Statics screen is a *success*, not an empty state.
- **Offline writes:** never queue them. Disable the button and tell the user.

---

## 14. Discover Integration

### The screen already exists

`lib/features/common/Discover/view/healthcare/health_care_listing_screen.dart` already routes
the **"Clinic Doctors"** category to a listing with `serviceType: 'DOCTORS'`. The plumbing is
in place — what is new is the **doctor data now attached to each card**.

### How doctors appear

```
GET user-service/business/filter?category=DOCTORS&page=1&limit=20
```

The backend enriches **every** `DOCTORS` / `CLINICS` listing with a doctor summary:

```jsonc
{
  "_id": "68b7...",              // Business._id  → use for BOOKING + ENQUIRY
  "user_id": "68a2...",          // Business.user_id → use for /doctors/full/:userId
  "business_name": "Dr. Umesh Gupta",
  "logo": "https://...",
  "coverPicture": "https://...",
  "address": "123 Park Street, Kolkata",
  "avg_rating": 4.8,
  "total_ratings": 48,

  // ↓↓↓ the new doctor enrichment ↓↓↓
  "specialization": ["Cardiologist"],
  "headline": "Cardiologist",       // = specialization[0] — the card subtitle
  "degree": ["MBBS", "MD (General Medicine)"],
  "experienceYears": 16,
  "consultationFee": 600,           // null when unset
  "feeType": "Per Visit",
  "languagesSpoken": ["English", "Hindi", "Bengali"],
  "certificate_count": 3
}
```

### Rendering the card

| Card element | Field |
|---|---|
| Title | `business_name` |
| Subtitle | `headline` (falls back to blank) |
| Qualification line | `degree.join(", ")` |
| Experience | `experienceYears` → `"16 Years"` |
| Fee | `consultationFee` + `feeType` → `"₹600/Visit"` |
| Languages | `languagesSpoken.join(", ")` |
| Rating | `avg_rating` / `total_ratings` |
| Image | `logo` or `coverPicture` |

### Two rules you must not get wrong

1. **`consultationFee` can be `null`.** That means the doctor has not set a fee — **hide the
   fee line entirely**. Rendering `₹0` would advertise a free consultation.
2. **Keep both ids from every card.** You need `_id` (for booking/enquiry) **and** `user_id`
   (for the public profile). Losing `user_id` means an extra round-trip later.

### Degraded data is normal

If the doctor service is briefly unavailable, the listing still returns — with empty arrays,
`0` counts and `consultationFee: null`. Your card must render fine in that state. It will
**never** be an error response.

### Filtering and searching

| Need | Use |
|---|---|
| Category tab (Doctors) | `GET user-service/business/filter?category=DOCTORS` |
| Free-text / geo business search | `GET user-service/business/search` (existing) |
| Filter by specialization / fee / experience | `GET hospital-service/doctors` — **then map by `userId`** |

> For a "find a Cardiologist under ₹800" screen, call `hospital-service/doctors`, collect the
> `userId`s, and resolve them to listings. Do **not** try to book using the `_id` returned by
> that endpoint — it is a `DoctorProfile._id`, not a `Business._id`.

### Opening the profile

```
Tap card
   → pass businessId (_id) AND ownerUserId (user_id)
   → GET user-service/business/{businessId}          (identity, photos, contact, availability)
   → GET hospital-service/doctors/full/{ownerUserId} (degree, fee, certificates) — 404 tolerated
   → optionally POST user-service/business/{businessId}/view   (analytics)
```

---

## 15. Chat Integration

### You never POST to the chat service

Chat cards are created **automatically** by the backend when an enquiry or booking is created.
Flutter's job is: **create the record → listen on the socket → render the card**.

### Opening a chat with a doctor

Use the **existing business chat flow** — the same one used for every other business listing.
`ChatViewController` already supports `activeRoute = AppConstants.route_discover`, which
resolves (or creates) the customer↔owner **business** conversation. The doctor is just another
business owner. Nothing new here.

**Ids you need:** the customer's own user id and the doctor's `user_id` (from the Discover card).

### The two card types

| Card | `message_type` | Created by | Metadata key |
|---|---|---|---|
| Enquiry | `healthcare_enquiry` | `POST user-service/business-enquiries` | `metadata.healthcareEnquiryId`, `metadata.healthcareEnquiry` |
| Booking | `healthcare_booking` | `POST hospital-service/doctor-appointments` | `metadata.healthcareBookingId`, `metadata.healthcareBooking` |

> **Good news:** both card types already exist in the app for hospitals and labs. A standalone
> doctor reuses **the exact same cards**. The only difference is `category: "DOCTOR"`.

### Booking card metadata

```jsonc
"metadata": {
  "healthcareBookingId": "68d1...",
  "healthcareBooking": {
    "bookingId": "68d1...",
    "category": "DOCTOR",              // ← how you know it is a standalone doctor
    "listingId": "68b7...",            // Business._id
    "listingName": "Dr. Umesh Gupta",
    "listingImage": "https://...",
    "location": "123 Park Street, Kolkata",
    "doctor": {
      "doctorProfileId": "68f1...",    // may be null
      "name": "Dr. Umesh Gupta",
      "department": "Cardiologist",    // the specialization
      "fees": 600,
      "image": "https://..."
    },
    "appointmentDate": "2026-08-05T00:00:00.000Z",
    "preferredTime": "10:00 – 11:00 AM",
    "patientName": "Ramesh Kumar",
    "enquiryId": "68c9...",
    "note": "Diabetic patient",
    "photos": ["https://..."],
    "status": "pending"
  },
  "is_cancelled": false
}
```

> ⚠️ Note `doctor.department` carries the **specialization** for a standalone doctor. The key
> is named `department` because the same card serves hospital OPD bookings. Render the label
> as "Specialization" when `category == "DOCTOR"`.

### Socket events to listen for

| Event | Fires when | Who receives it |
|---|---|---|
| `newHealthcareEnquiryReceived` | Enquiry created | Doctor (+ customer echo) |
| `healthcareEnquiryStatusUpdated` | Doctor accepted/declined the enquiry | Both |
| `newHealthcareBookingReceived` | Appointment requested | Doctor |
| `healthcareBookingStatusUpdated` | Accepted / declined / cancelled | Both |

Status-update payload: `{ messageId, bookingId, status }` (enquiry: `{ messageId, enquiryId, status }`).
On receipt, patch that message's metadata status in place and re-render — do not refetch the
conversation.

### Card buttons — who sees what

| Viewer | `pending` | `accepted` | `declined` / `cancelled` |
|---|---|---|---|
| Doctor (owner) | **Accept · Decline** | — | — (terminal) |
| Customer | **Cancel** | **Cancel** | — (terminal) |

After an accepted **enquiry**, show a **"Book Appointment"** button on the customer's enquiry
card, carrying that enquiry's id into `POST /doctor-appointments` as `enquiry_id`.

### Push notifications

Handled by the backend → chat-service → notification-service.

> ⚠️ **There IS work to do here.** Flutter currently routes `healthcare_enquiry` but
> **does not route `healthcare_booking`** — so appointment pushes dead-end today.
> See **[§23 Notifications](#23-notifications-complete-guide)** for the full contract,
> the exact operation names, and the one-file fix required.

---

## 16. Booking Flow

### The complete flow

```
CUSTOMER                                             DOCTOR
────────                                             ──────
Discover → doctor card
     │
     ▼
Public profile
     │
     ├─── (optional) Enquiry first ────────────────────────┐
     │    POST user-service/business-enquiries              │
     │         ⇒ healthcare_enquiry card in chat  ──────────▶ sees enquiry
     │                                                      │ accepts
     │    ◀─── socket healthcareEnquiryStatusUpdated ───────┘
     │         "Book Appointment" button appears
     ▼
Booking form
  business_id, appointmentDate, preferredTime,
  patientName, note, photos[], enquiry_id?
     │
     ▼
POST hospital-service/doctor-appointments
     │  201 { appointmentId, status: "pending" }
     │  ⇒ healthcare_booking card in chat  ───────────────▶ socket newHealthcareBookingReceived
     │                                                      + push notification
     │                                                      │
     │                                                      ▼
     │                                            Booking tab → Accept / Decline
     │                                            PUT /doctor-appointments/{id}/status
     │                                                      │
     ◀──── socket healthcareBookingStatusUpdated ───────────┘
     │      card flips to accepted/declined + push
     ▼
Customer may Cancel while pending OR accepted
PUT /doctor-appointments/{id}/status { "cancelled" }
     │
     ▼
DONE — no payment, no slot lock. The visit happens offline.
```

### Status machine

```
                doctor: accepted
   pending ──────────────────────► accepted ──┐
      │                                       │ customer: cancelled
      │         doctor: declined              ▼
      ├──────────────────────────► declined   cancelled  (terminal)
      │                            (terminal)
      └───── customer: cancelled ─► cancelled (terminal)
```

### Things that surprise people

- **No payment.** `fees` is display-only. Do not wire Razorpay into this flow.
- **No slot inventory.** Two customers can request the same time and both be accepted.
  `preferredTime` is **free text**. Show the doctor's availability as *guidance*, then let the
  customer type or pick a string.
- **`enquiry_id` is optional and not strictly enforced.** Direct booking works.
- **A customer can cancel an already-accepted booking.** Keep the Cancel button visible in the
  `accepted` state.
- **`doctorProfileId` may be `null`** if the doctor has not completed their profile. Booking
  still succeeds; the card falls back to the business name with no fee. Handle `null`.

---

## 17. Statistics Screen

Every number on the "Statics" tab, and exactly where it comes from.

| Tile | Source | Field |
|---|---|---|
| Total appointment requests | `GET hospital-service/doctors/me/stats` | `appointments.total` |
| Pending | same | `appointments.pending` |
| Accepted | same | `appointments.accepted` |
| Declined | same | `appointments.declined` |
| Cancelled | same | `appointments.cancelled` |
| Upcoming visits | same | `upcomingAccepted` |
| Certificates | same | `certificateCount` |
| Profile visits | `GET user-service/profile-visit/{userId}/profile-visits` | per existing model |
| Chat clicks | `GET user-service/business/{userId}/chat-clicks` | per existing model |
| Rating + review count | `GET user-service/business/{businessId}/ratings`, or `Business.avg_rating` / `total_ratings` | — |
| Followers | existing followers API | — |

### Notes

- **Booking numbers come from hospital-service. Everything else comes from user-service.**
  There is no single "stats" endpoint — that is intentional, so each service owns its own data.
- Call all sources **in parallel** and render each tile as it resolves.
- If one source fails, show `--` in **that tile only**. Never fail the whole screen.
- `upcomingAccepted` counts accepted appointments dated **today or later**.
- All four status counts are always returned, even when `0` — render `0`, not an empty tile.
- Tapping a status tile should open the Booking tab pre-filtered with that `status`.

---

## 18. File Upload Sequence

### A. Certificate image (recommended — single request)

```
① User picks an image        (image_picker)
② Crop                        (croppy)
③ Compress + check ≤10 MB     (client-side)
④ Build multipart:
      title, description, issuedBy, issuedDate  → text parts
      image                                      → file part
⑤ POST hospital-service/doctor-certificates
⑥ 201 → response.data contains the final imageUrl
⑦ Prepend to the local list
```

### B. Certificate image (alternative — presign)

```
① Pick → crop → compress
② GET user-service/upload/init?fileName=cert.jpg&fileType=image/jpeg
      → { uploadUrl, publicUrl, fileKey }
③ PUT the raw bytes to `uploadUrl`   (direct to S3, NO auth header)
④ POST hospital-service/doctor-certificates  with { title, imageUrl: publicUrl }
```

Use A unless you need an upload-progress bar decoupled from the record creation.

### C. Appointment photos (multipart only)

```
① Pick up to 5 images/PDF reports
② Validate: count ≤5, each ≤10 MB
③ Build multipart:
      payload → ONE text part containing the JSON string of all fields
      photos  → up to 5 file parts, ALL named "photos"
④ POST hospital-service/doctor-appointments
⑤ 201 → { appointmentId, status }
```

> ⚠️ `payload` must be a **JSON string**, not individual form fields.

### D. Cover / Profile photo / Gallery (presign — user-service)

```
① Pick → crop → compress
② GET user-service/upload/init?fileName=...&fileType=...
③ PUT bytes to `uploadUrl`
④ Send `publicUrl` to:
      cover/profile → PUT user-service/business/updateBusinessProfile
      gallery       → POST user-service/business/live-photosOne
```

### Failure rules

- If step ③ (S3 PUT) fails → **stop**. Do not call step ④.
- Never store a local file path in a URL field.
- Show real upload progress for files over ~2 MB.
- On failure, keep the picked file in state so Retry does not force re-picking.

---

## 19. Folder Suggestions

Follow the existing feature-module convention exactly as `lib/features/me/hospital/` does.

```
lib/features/me/doctor/                         ← NEW module (do not touch me/hospital/)
│
├── controller/
│   ├── doctor_profile_controller.dart          — profile + hasProfile, dashboard source of truth
│   ├── doctor_certificate_controller.dart      — certificates list + add/edit/delete
│   ├── doctor_appointment_controller.dart      — Booking tab, filters, pagination
│   └── doctor_stats_controller.dart            — Statics tab
│
├── model/
│   ├── doctor_profile_model.dart               — DoctorProfile + certificates[]
│   ├── doctor_certificate_model.dart
│   ├── doctor_appointment_model.dart
│   ├── doctor_stats_model.dart
│   └── doctor_discover_summary_model.dart      — the enrichment on business/filter cards
│
├── repo/
│   ├── doctor_profile_repo.dart                — extends BaseService
│   ├── doctor_certificate_repo.dart
│   └── doctor_appointment_repo.dart
│
├── view/
│   ├── dashboard/doctor_dashboard_screen.dart  — 5-tab host
│   ├── overview/doctor_overview_tab.dart
│   ├── about/doctor_about_me_tab.dart
│   ├── about/doctor_about_me_edit_screen.dart
│   ├── certificate/doctor_certificates_screen.dart
│   ├── certificate/doctor_certificate_form_screen.dart
│   ├── booking/doctor_booking_tab.dart
│   ├── booking/doctor_appointment_detail_screen.dart
│   ├── stats/doctor_statics_tab.dart
│   └── public/doctor_public_profile_screen.dart
│
└── widget/
    ├── doctor_expertise_section.dart
    ├── doctor_certificate_card.dart
    ├── doctor_appointment_card.dart
    ├── doctor_stat_tile.dart
    ├── chip_input_field.dart                   — the "Add" chip input (Degree/Specialization/Language)
    └── doctor_discover_card.dart
```

### Files to ADD to shared locations

| File | What to add |
|---|---|
| `lib/core/api/apiService/hospital_service_api.dart` | Doctor endpoint constants — this mixin is already wired into `BaseService` |
| `lib/core/routes/route_constant.dart` | Doctor route name constants |
| `lib/core/routes/route_helper.dart` | Doctor route cases |
| `lib/features/common/Discover/model/business_filter_res_model.dart` | Parse the new doctor enrichment fields on listing cards |

### Files to NOT touch

- Anything in `lib/features/me/hospital/` — the OPD flow must stay as-is.
- `api_base_helper.dart` — the 401/logout handling is already correct.
- `user_service_api.dart` / `auth_service_api.dart` — every endpoint you need already exists.

---

## 20. Integration Checklist

### Authentication & account
- ☐ OTP send working
- ☐ OTP verify working
- ☐ Business account created with `category_Of_Business = DOCTORS`
- ☐ Token stored and attached to every request
- ☐ 401 logout verified (no custom handler added)

### Doctor profile
- ☐ `GET /doctors/me` integrated
- ☐ `hasProfile == false` shows the create-profile CTA (**not** an error)
- ☐ `POST /doctors` creates the profile
- ☐ Doctor is live immediately (no approval UI anywhere)
- ☐ `PUT /doctors/me` partial update working
- ☐ About Me tab renders all 9 rows
- ☐ Chip inputs (Degree / Specialization / Language) add + remove
- ☐ Description counter shows `n/1000`
- ☐ `DELETE /doctors/me` with confirmation dialog

### Overview
- ☐ Cover photo displays + edit
- ☐ Profile photo displays
- ☐ Expertise section + edit
- ☐ Certificates carousel + "View All"
- ☐ Gallery + Add Photo
- ☐ Testimonials + Reply
- ☐ Contact Us + map
- ☐ Rating + review count

### Certificates
- ☐ `POST /doctor-certificates` (multipart) working
- ☐ Image upload ≤10 MB enforced client-side
- ☐ Edit certificate
- ☐ Delete certificate with confirmation
- ☐ `404 "Create your doctor profile first"` routes to the profile form
- ☐ Empty state

### Availability
- ☐ `GET /business/availability/hours` prefills
- ☐ `PUT /business/availability/hours` saves
- ☐ About Me availability row shows the summary line
- ☐ Go-live toggle working

### Statistics
- ☐ `GET /doctors/me/stats` integrated
- ☐ Profile visits, chat clicks, ratings pulled from user-service
- ☐ Parallel loading, per-tile failure handling
- ☐ Tapping a status tile filters the Booking tab

### Discover & public profile
- ☐ `business/filter?category=DOCTORS` list renders
- ☐ Doctor enrichment fields render on the card
- ☐ `consultationFee: null` hides the fee line
- ☐ Both `_id` and `user_id` kept from each card
- ☐ Public profile merges business + doctor data
- ☐ `GET /doctors/full/:userId` 404 does **not** break the page
- ☐ Infinite scroll + pull to refresh

### Chat & enquiry
- ☐ Chat opens via the existing business chat flow
- ☐ Enquiry uses **`user-service/business-enquiries`** — **NOT** `hospital-service/hospital-enquiries` (see [§24.1](#241-doctor-enquiry-sent-to-the-hospital-endpoint-confirmed-bug))
- ☐ `POST /business-enquiries` sends an enquiry
- ☐ `healthcare_enquiry` card renders for `category: DOCTORS`
- ☐ Doctor can accept/decline the enquiry
- ☐ "Book Appointment" appears after acceptance

### Booking
- ☐ `POST /doctor-appointments` (JSON) working
- ☐ `POST /doctor-appointments` (multipart with `payload` + `photos`) working
- ☐ Past dates blocked in the picker
- ☐ `healthcare_booking` card renders with `category: DOCTOR`
- ☐ Booking tab lists received requests
- ☐ Accept / Decline (doctor only)
- ☐ Cancel (customer only, from `pending` **and** `accepted`)
- ☐ `409` refreshes the list
- ☐ Socket events flip cards live

### Notifications (see [§23](#23-notifications-complete-guide))
- ☐ FCM device token registered after login
- ☐ FCM device token cleared on logout
- ☐ `healthcare_enquiry` push received + taps through
- ☐ `healthcare_enquiry_status` push received + taps through
- ☐ **`healthcare_booking` added to the routing switch** (currently missing — required fix)
- ☐ **`healthcare_booking_update` added to the routing switch** (currently missing — required fix)
- ☐ Tap routing verified from foreground / background / **killed** state
- ☐ Unknown operation falls back to `NotificationScreen` (no dead-end)
- ☐ In-app notification list shows all four doctor operations
- ☐ Socket + push deduped (no double banner)
- ☐ Booking-tab badge sourced from `appointments.pending`
- ☐ Hospital + lab booking pushes still route correctly (shared operations)

---

## 21. Testing Checklist

### Happy path
- ☐ Register a brand-new doctor end to end and confirm they appear in Discover **immediately**
- ☐ Fill every About Me field, save, reopen — all values persist
- ☐ Add 3 certificates with images; confirm they appear on Overview and the public profile
- ☐ Set availability Mon–Fri 9–6; confirm the summary line on About Me
- ☐ As a customer: Discover → profile → enquiry → doctor accepts → book → doctor accepts
- ☐ Confirm both chat cards render and flip in realtime

### Edge cases
- ☐ Doctor with **no** profile — dashboard shows the CTA, not an error
- ☐ Public profile of a doctor with no profile — page still renders (404 tolerated)
- ☐ `consultationFee` unset — fee line hidden everywhere (not `₹0`)
- ☐ Add "English" then "english" — de-duped to one chip after save
- ☐ Exactly 30 array entries succeeds; 31 shows the server error
- ☐ Description of exactly 1000 chars saves; 1001 is blocked client-side
- ☐ `experienceYears` 0 and 80 succeed; 81 fails
- ☐ Book for **today** — allowed
- ☐ Book with exactly 5 photos — allowed; 6 blocked client-side
- ☐ Doctor with no certificates — empty state
- ☐ Very long doctor name / specialization — no layout overflow
- ☐ Appointment where `doctorProfileId` is `null` — card still renders

### Failure cases
- ☐ Create a profile twice → `400 "User already has a doctor profile"` handled gracefully
- ☐ Customer taps Accept on a booking → `403`, button should not have been shown
- ☐ Accept an already-declined booking → `409`, list refreshes
- ☐ Add a certificate before creating a profile → `404`, routed to the profile form
- ☐ Book your own listing → `400` handled
- ☐ Book a deactivated listing → `404 "Doctor listing not found"`
- ☐ Expired token → auto logout, no crash, no duplicate logout
- ☐ Upload a 15 MB image → blocked client-side with a clear message

### Offline / slow network
- ☐ Airplane mode on the dashboard → cached data + offline banner
- ☐ Airplane mode on the About Me form → Save disabled
- ☐ Throttle to 2G, save profile → blocking loader, no double-submit
- ☐ Kill the network mid-upload → form state preserved, Retry works
- ☐ Timeout on `POST /doctors` → **no** blind auto-retry; verify with `GET /doctors/me`
- ☐ Timeout on `POST /doctor-appointments` → no duplicate booking created
- ☐ Background the app during upload → returns to a sane state
- ☐ Socket reconnect after network loss → card statuses resync

### Notifications
Full notification test matrix is in **[§23.11](#2311-notification-testing-checklist)** —
delivery, tap routing from all three app states, cross-vertical regression, dedupe,
tokens/privacy and edge cases.

### Regression (must still pass)
- ☐ Hospital profile create/edit unchanged
- ☐ Hospital departments / OPD / IPD unchanged
- ☐ Hospital enquiry + hospital appointment unchanged
- ☐ Lab booking unchanged
- ☐ Existing Discover categories unchanged
- ☐ Hotel / vehicle / hospital / lab notification routing unchanged

---

## 22. API Reference

Base URL: `baseUrl` from `environment_config.dart` (prod `https://be.beapp.in/api/`).
Auth = `Authorization: Bearer <token>`.

### Standalone Doctor — NEW APIs (hospital-service)

| Method | Endpoint | Purpose | Auth | Request | Response |
|---|---|---|---|---|---|
| POST | `hospital-service/doctors` | Create profile (goes live instantly) | ✅ | JSON: degree[], specialization[], languagesSpoken[], expertise[], experienceYears, registrationNumber, consultationFee, feeType, address, description | `201 { success, data: profile }` |
| GET | `hospital-service/doctors` | Public list/search | ❌ | Query: specialization, degree, language, search, minExperience, maxFee, page, limit | `200 { success, data: [], pagination }` |
| GET | `hospital-service/doctors/me` | My profile + certificates | ✅ | — | `200 { success, data, hasProfile }` |
| PUT | `hospital-service/doctors/me` | Partial update | ✅ | JSON: any subset of the create fields | `200 { success, data: profile }` |
| DELETE | `hospital-service/doctors/me` | Delete profile + certificates | ✅ | — | `200 { success, message }` |
| GET | `hospital-service/doctors/me/stats` | Booking analytics | ✅ | — | `200 { success, data: { appointments, upcomingAccepted, certificateCount } }` |
| GET | `hospital-service/doctors/full/{userId}` | Public full profile | ❌ | Path: owner userId | `200 { success, data }` · `404` if incomplete |
| GET | `hospital-service/doctors/{id}` | Basic profile | ❌ | Path: DoctorProfile._id | `200 { success, data }` |
| GET | `hospital-service/doctors/admin` | Admin list (read-only) | ✅ admin | Query: + userId, registrationNumber | `200 { success, data: [], pagination }` |
| GET | `hospital-service/doctors/admin/stats` | Admin analytics (read-only) | ✅ admin | — | `200 { success, data }` |
| POST | `hospital-service/doctor-certificates` | Add certificate | ✅ | JSON `{title, description, imageUrl, issuedBy, issuedDate}` **or** multipart + `image` | `201 { success, data }` |
| GET | `hospital-service/doctor-certificates/me` | My certificates | ✅ | — | `200 { success, data: [] }` |
| GET | `hospital-service/doctor-certificates/doctor/{doctorProfileId}` | Public certificates | ❌ | Path: DoctorProfile._id | `200 { success, data: [] }` |
| PUT | `hospital-service/doctor-certificates/{id}` | Update certificate | ✅ | JSON or multipart `image` | `200 { success, data }` |
| DELETE | `hospital-service/doctor-certificates/{id}` | Delete certificate | ✅ | — | `200 { success, message }` |
| POST | `hospital-service/doctor-appointments` | Request appointment | ✅ | JSON `{business_id, appointmentDate, preferredTime, patientName, enquiry_id, note}` **or** multipart `payload` + `photos[≤5]` | `201 { success, message, data: { appointmentId, status } }` |
| PUT | `hospital-service/doctor-appointments/{appointmentId}/status` | Accept/Decline/Cancel | ✅ | `{ status: accepted\|declined\|cancelled }` | `200 { success, message, data }` |
| GET | `hospital-service/doctor-appointments/me` | My requests (customer) | ✅ | Query: status, page, limit | `200 { success, data: [], pagination }` |
| GET | `hospital-service/doctor-appointments/owner/me` | **Booking tab** (doctor) | ✅ | Query: status, page, limit | `200 { success, data: [], pagination }` |
| GET | `hospital-service/doctor-appointments/admin` | Admin list (read-only) | ✅ admin | Query: status, customerId, ownerId, businessId, doctorProfileId, from, to, search, location, page, limit | `200 { success, data: [], pagination }` |
| GET | `hospital-service/doctor-appointments/{appointmentId}` | One appointment | ✅ | Path: id | `200 { success, data }` |

### Reused APIs (already exist — do not rebuild)

| Method | Endpoint | Purpose | Auth |
|---|---|---|---|
| POST | `auth-service/sent-otp` | Send OTP | ❌ |
| POST | `auth-service/verify-otp` | Verify OTP | ❌ |
| POST | `user-service/user/add-user` | Create account + business | ❌ |
| GET | `user-service/business/filter` | **Discover doctors** | ❌ |
| GET | `user-service/business/{id}` | Business profile | ✅ |
| GET | `user-service/business/user/{userId}` | Business by owner | ✅ |
| PUT | `user-service/business/updateBusinessProfile` | Cover / profile photo / details | ✅ |
| POST | `user-service/business/live-photosOne` | Add gallery photo | ✅ |
| DELETE | `user-service/business/remove-live-image` | Remove gallery photo | ✅ |
| GET/PUT | `user-service/business/availability/hours` | Weekly availability | ✅ |
| PUT/DELETE | `user-service/business/availability/today` | Today override | ✅ |
| POST | `user-service/business/availability/go-live` · `end-live` | Go live toggle | ✅ |
| POST/GET | `user-service/business/{businessId}/ratings` | Ratings | ✅ / ❌ |
| POST | `user-service/testimonials/add-testimonial` | Add testimonial | ✅ |
| GET | `user-service/testimonials/public/{userId}` | Testimonials | ❌ |
| POST | `user-service/business/{businessId}/view` | Record a view | ✅ |
| POST/GET | `user-service/profile-visit/{userId}/profile-visit(s)` | Visits | ✅ |
| POST/GET | `user-service/business/{userId}/chat-click(s)` | Chat clicks | ✅ |
| GET | `user-service/upload/init` | Presigned S3 upload | ✅ |
| POST | `user-service/business-enquiries` | **Send enquiry to a doctor** | ✅ |
| PUT | `user-service/business-enquiries/{enquiryId}/status` | Accept/decline enquiry | ✅ |
| GET | `user-service/business-enquiries/{enquiryId}` | Enquiry by id | ✅ |

---

## 23. Notifications (complete guide)

> Read this together with [§15 Chat Integration](#15-chat-integration). Every doctor
> notification is produced as a side effect of a chat card, so the two are one system.

### 23.1 How notifications work in BlueEra (the model you must understand)

There are **three delivery channels** and they all fire from one backend call:

```
Customer creates an enquiry / booking
            │
            ▼
   hospital-service  or  user-service
            │  (Kafka: chat.service topic)
            ▼
      be_chat_service
            │  creates the in-chat card
            │  emits the socket event
            │  calls sendNotification(...)
            ▼
   be_notification_service
            │
    ┌───────┼──────────┬───────────────┐
    ▼       ▼          ▼               ▼
  PUSH   IN-APP    WHATSAPP        (SMS — not
  (FCM)  (list)    (new biz only)   used here)
```

| Channel | What it is | Where Flutter reads it |
|---|---|---|
| **Push (FCM)** | Phone notification tray | `lib/core/services/app_notification.dart` |
| **In-app** | The bell icon / Notification screen | `GET /notification-service/notifications` |
| **Socket** | Live UI update while the app is open | `chatSocketUrl` socket events (§15) |
| **WhatsApp** | Gallabox message to the doctor | Nothing to do — server side only |

> ⚠️ **Push and socket are different things.** If the doctor has the app **open on the
> chat screen**, they get the **socket** event (card appears instantly). If the app is
> **backgrounded or killed**, they get the **push**. Both may fire. Your UI must be
> idempotent — dedupe by `messageId` / `bookingId`.

### 23.2 CRITICAL: the FCM message is **data-only**

The backend deliberately sends **no `notification` block** — only a `data` payload.

> This means **Android and iOS will NOT display anything by themselves.**
> **Flutter builds the notification.** The backend supplies the title, body, image,
> channel, group key and action buttons inside `data`; Flutter renders exactly one
> notification from it and owns the tap routing.

This is already implemented in `app_notification.dart` for every other vertical — you are
not building it from scratch. But it explains why a missing `case` in the routing switch
means the notification appears and then **does nothing when tapped**.

### 23.3 All doctor notification types

These are the **only four** operations in the standalone doctor flow. `operation` is the
FCM `data.operation` value and also the `type` field on the in-app notification record.

| # | `operation` | Fired when | Sent TO | `senderId` is | WhatsApp? |
|---|---|---|---|---|---|
| 1 | `healthcare_enquiry` | Customer sends an enquiry to the doctor | **Doctor** | the customer | ✅ Yes |
| 2 | `healthcare_enquiry_status` | Doctor accepted / declined the enquiry | **Customer** | the doctor | ❌ No |
| 3 | `healthcare_booking` | Customer requests an appointment | **Doctor** | the customer | ✅ Yes |
| 4 | `healthcare_booking_update` | Accepted / declined → customer · Cancelled → doctor | **The other party** | whoever acted | ❌ No |

> ⚠️ **Naming trap.** Hotel uses `hotel_booking_status`. Healthcare uses
> **`healthcare_booking_update`** — `_update`, **not** `_status`. Getting this wrong is
> the single most likely bug in this section.

#### Backend status: ✅ VERIFIED COMPLETE — nothing to build server-side

All four notifications already fire. The doctor feature added **zero** notification code — it
publishes the *existing* Kafka events and the existing chat-service handlers do the rest.
Verified against the live source:

| Operation | Fired from | Kafka route |
|---|---|---|
| `healthcare_enquiry` | `be_chat_service/src/utils/healthcareEnquiryHandler.js:123` | `consumer.js:215` `CREATE_HEALTHCARE_ENQUIRY` |
| `healthcare_enquiry_status` | `healthcareEnquiryHandler.js:204` | `consumer.js:218` `HEALTHCARE_ENQUIRY_STATUS_UPDATED` |
| `healthcare_booking` | `healthcareBookingHandler.js:119` | `consumer.js:239` `CREATE_HEALTHCARE_BOOKING` |
| `healthcare_booking_update` | `healthcareBookingHandler.js:186` | `consumer.js:242` `HEALTHCARE_BOOKING_STATUS_UPDATED` |

Also verified:
- **No notification template is required.** `notification-templates.json` has 154 templates and
  none for healthcare — that is fine. `firebaseNotification.js:639-645` falls back:
  `title` → `data.title` → **sender's name**; `body` → **`data.message`** (the text the chat
  handler passed). This is the same path hotel/vehicle/business enquiries already use in production.
- **WhatsApp is enabled** for `healthcare_enquiry` and `healthcare_booking` via the
  `WHATSAPP_BUSINESS_OPERATIONS` allowlist in `sendMessage.controller.js`. Status events
  deliberately do not send WhatsApp.
- **Push + in-app are both enabled** (`type = ["push_notification", "notification"]`).

> **Conclusion: the only outstanding work is in Flutter** — the two missing `case` labels in
> §23.6. No backend change is needed or recommended.

> ⚠️ **These operations are shared across three verticals.** Hospital appointments,
> laboratory test bookings and standalone doctor appointments all use the *same four*
> operation names. To tell them apart you must read the **card's `category`** field
> (`"HOSPITAL"` / `"LABORATORY"` / `"DOCTOR"`) from the chat message metadata — the push
> payload itself does **not** carry the category. Route all three to the chat thread and
> let the card render itself; do not try to branch by vertical from the push alone.

### 23.4 Exact FCM `data` payload

Every push in the app — including these four — arrives with this data map:

```jsonc
{
  // ── What to display (backend-controlled; Flutter renders it) ──
  "title": "Dr. Umesh Gupta",
  "body": "New appointment request for Dr. Umesh Gupta",
  "imageUrl": "https://...",
  "style": "...",

  // ── Android channel (Flutter auto-creates it) ──
  "channelId": "default",
  "channelName": "Notifications",
  "channelImportance": "default",

  // ── Grouping / actions ──
  "groupKey": "healthcare_booking",      // == operation
  "actions": "[]",                        // JSON string of action buttons

  // ── Rich media (usually empty here) ──
  "mediaUrl": "", "mediaType": "", "mediaThumbnail": "",
  "mediaDuration": "", "mediaFileName": "",

  // ── Identity — THIS IS WHAT YOU ROUTE ON ──
  "operation": "healthcare_booking",
  "notificationId": "1774610672000",
  "timestamp": "2026-07-30T10:00:00.000Z",

  // ── Sender — THIS IS WHAT YOU OPEN THE CHAT WITH ──
  "senderId": "68a9...",
  "senderName": "Ramesh Kumar",
  "senderProfileImage": "https://..."
}
```

**The two keys that matter for routing:**

- **`operation`** → decides *where* to navigate. Flutter lowercases it before the switch.
- **`senderId`** → the other participant's user id. `_openChatWithUser(senderId)` opens the
  correct customer↔doctor conversation. **Do not** expect `conversation_id` in the push —
  it is not included for these operations.

### 23.5 Notification titles and bodies

> **There are no notification templates for these operations.** `notification-templates.json`
> in be_notification_service has 154 templates and **none** of them match healthcare,
> booking or enquiry. That is intentional and works — the resolver
> (`firebaseNotification.js:639-645`) falls back to:
>
> - **title** = `data.title` → else **the sender's name** (e.g. `"Ramesh Kumar"` on a new
>   booking to the doctor; `"friends clinic"` on a status update to the customer)
> - **body** = **`data.message`** — the exact text the chat handler passed

| Operation | Body text the user sees |
|---|---|
| `healthcare_enquiry` | `You have a new healthcare enquiry!` |
| `healthcare_enquiry_status` | `Your healthcare enquiry was accepted` (or `declined`) |
| `healthcare_booking` | `New appointment request for <doctorName> at <listingName>` |
| `healthcare_booking_update` | `Your booking request was accepted` (or `declined` / `cancelled`) |

> ⚠️ **Known cosmetic quirk.** For a standalone doctor, `doctorName` and `listingName` are
> the **same value** (the doctor's name *is* the business name). So the booking body reads:
> *"New appointment request for Dr. Umesh Gupta at Dr. Umesh Gupta"*.
> This is harmless but looks odd. Fixing it requires a backend change in
> `be_chat_service/src/utils/healthcareBookingHandler.js`. **Do not try to patch the text
> in Flutter** — the `body` is rendered as-is by design. Raise it as a backend ticket if the
> product team cares.

### 23.6 Tap routing — ⚠️ ONE REQUIRED FLUTTER FIX

**File:** `lib/core/services/app_notification.dart`
**Function:** `_onTapNotificationFromStatusBar(...)` → the `switch (operation)`

**Current state (verified):**

| Operation | Handled today? | Result |
|---|---|---|
| `healthcare_enquiry` | ✅ Yes | Opens the chat |
| `healthcare_enquiry_status` | ✅ Yes | Opens the chat |
| `hotel_booking` / `hotel_booking_status` | ✅ Yes | Opens the chat |
| `vehicle_booking` / `vehicle_booking_status` | ✅ Yes | Opens the chat |
| **`healthcare_booking`** | ❌ **MISSING** | Falls to `default:` — **dead-ends** |
| **`healthcare_booking_update`** | ❌ **MISSING** | Falls to `default:` — **dead-ends** |

**What to do:** add both operations to the **existing** enquiry/booking case group
(the one that already contains `healthcare_enquiry`, `hotel_booking`, `vehicle_booking`)
so they run the same `_openChatWithUser(data['senderId'])` behaviour.

> This is a **pre-existing gap that already affects hospital appointments and lab test
> bookings**, not something the doctor feature introduced. Fixing it repairs all three
> verticals at once. It is a one-place, additive change — no other operation is affected.

**Where should each notification land?**

| Operation | Recommended destination | Why |
|---|---|---|
| `healthcare_enquiry` | Chat thread with `senderId` | The enquiry card is there |
| `healthcare_enquiry_status` | Chat thread with `senderId` | The card flipped |
| `healthcare_booking` | Chat thread with `senderId` (consistent), **or** the doctor's Booking tab | The card is in chat; the Booking tab is the doctor's work queue |
| `healthcare_booking_update` | Chat thread with `senderId` | The card flipped |

> **Recommendation:** send all four to the **chat thread**, matching every other vertical.
> That is one line of change and behaviourally consistent. If the product team specifically
> wants the doctor taken to the **Booking tab** for `healthcare_booking`, branch on whether
> the logged-in user is the doctor (compare against `ownerId`) — but be aware you cannot
> know that from the push payload alone, so you would have to check the local account type.

> ⚠️ **Never leave a `default:` that does nothing.** The project's own
> `NOTIFICATION_REDIRECT_FIX.md` sets the rule: unmatched operations must fall back to
> `NotificationScreen` (`RouteHelper.getNotificationScreenRoute()`), which needs no route
> arguments and cannot crash.

### 23.7 In-app notification list (the bell icon)

Push is not the only surface. The same events are stored and readable.

| Purpose | Method + Endpoint | Auth |
|---|---|---|
| List notifications | `GET /notification-service/notifications` | ✅ |
| Mark one read | `notification-service/notifications/` + id | ✅ |
| Delete one | `DELETE /notification-service/notifications/{notifyId}` | ✅ |
| Clear all | `DELETE /notification-service/notifications/all` | ✅ |
| Settings | `notification-service/notifications/settings` | ✅ |

**All five already exist** in `lib/core/api/apiService/notification_service_api.dart`.
Nothing new to add.

**Record shape** (the `type` field is the operation):

```jsonc
{
  "_id": "6a38f926...",
  "type": "healthcare_booking",        // == operation
  "status": "UNREAD",                  // UNREAD | READ
  "sentBy": "68a9...",                 // customer (or doctor for status events)
  "sentTo": "68a2...",                 // the recipient
  "message": "New appointment request for Dr. Umesh Gupta",
  "metadata": {
    "title": "...",
    "message": "...",
    "senderName": "Ramesh Kumar",
    "originalOperation": "healthcare_booking"
  },
  "sender_profile": {                  // enriched — use for the avatar + name row
    "id": "68a9...",
    "name": "Ramesh Kumar",
    "profile_image": "https://...",
    "account_type": "INDIVIDUAL"
  },
  "created_at": "2026-07-30T08:58:14.565Z"
}
```

**What Flutter should do:** the Notification screen already renders this list generically.
Confirm the four doctor operations show a sensible icon and title, and that tapping a row
uses the **same routing switch** as the push tap (so behaviour is identical from both
surfaces). Do not build a doctor-specific notification screen.

### 23.8 Device token registration (must work or nothing arrives)

Pushes are delivered to the tokens stored on the user record. Endpoints already exist:

| Purpose | Endpoint |
|---|---|
| Save/refresh FCM token | `PATCH user-service/user/me/device-token` |
| Clear token on logout | `DELETE user-service/user/me/device-token` |
| iOS VoIP token (calls only) | `PATCH user-service/user/me/voip-token` |

**Rules:**
- Register the token **after login**, and again on every FCM token refresh.
- **Clear the token on logout** — otherwise the next user on that device receives the
  previous doctor's appointment notifications. This is a privacy issue, not just a bug.
- A doctor logged in on two devices gets the push on **both**. That is intended.

### 23.9 App state behaviour

| App state | What happens | Flutter responsibility |
|---|---|---|
| **Foreground, on the chat screen** | Socket event fires; card appears live | Render the card. Suppress a duplicate banner for the conversation already on screen |
| **Foreground, elsewhere** | Data push arrives | Build and show the notification; also refresh the Booking-tab badge |
| **Background** | Data push arrives via the background handler | Build the notification; on tap route via the switch |
| **Killed / cold start** | Push wakes the app | The existing cold-start tap handler runs the same switch. Verify routing works from a fully killed state — this is the case most often broken |

Because the FCM message is **data-only**, the background isolate handler in
`app_notification.dart` must be alive for the notification to appear at all. It already is —
do not disable it.

### 23.10 Badges and unread counts

- The **Booking tab** should show an unread/pending badge. Source it from
  `GET /doctors/me/stats` → `appointments.pending`, **not** from a notification count.
  Notifications can be cleared; pending requests cannot.
- The **bell icon** count comes from the notification list (`status: "UNREAD"`).
- Refresh the pending badge when a `healthcare_booking` push or socket event arrives.

### 23.11 Notification testing checklist

**Delivery**
- ☐ Doctor receives a push when a customer sends an **enquiry** (`healthcare_enquiry`)
- ☐ Customer receives a push when the doctor **accepts** the enquiry (`healthcare_enquiry_status`)
- ☐ Doctor receives a push when a customer **requests an appointment** (`healthcare_booking`)
- ☐ Customer receives a push when the doctor **accepts/declines** (`healthcare_booking_update`)
- ☐ Doctor receives a push when the customer **cancels** (`healthcare_booking_update`)
- ☐ The doctor does **not** get notified of their own action, and vice versa

**Tap routing (test each from all three app states)**
- ☐ Foreground tap → correct screen
- ☐ Background tap → correct screen
- ☐ **Killed / cold start tap → correct screen** (most commonly broken)
- ☐ `healthcare_booking` tap **no longer dead-ends** (the §23.6 fix)
- ☐ `healthcare_booking_update` tap no longer dead-ends
- ☐ An unknown operation falls back to `NotificationScreen`, never a blank screen or crash

**Cross-vertical regression (same four operations!)**
- ☐ Hospital appointment push still routes correctly
- ☐ Lab test booking push still routes correctly
- ☐ Hotel and vehicle booking pushes unchanged

**Dedupe & state**
- ☐ App open on the chat screen → card appears once, not twice (socket + push)
- ☐ Two devices logged in as the doctor → both receive it; acting on one updates the other via socket
- ☐ Booking-tab badge updates when a push arrives
- ☐ Bell icon unread count increments, and clears on read

**Tokens & privacy**
- ☐ Token registered after login
- ☐ Token cleared on logout
- ☐ Log out, log in as a **different** user → the new user does **not** receive the old doctor's notifications

**Edge cases**
- ☐ Notification arrives while the doctor has **no profile** yet → does not crash
- ☐ Notification for a booking whose `doctorProfileId` is `null` → card still renders
- ☐ Airplane mode during the event → push arrives on reconnect (within FCM TTL); in-app list still shows it
- ☐ Notification permission denied → in-app list still works; app does not crash
- ☐ Very long doctor name in the body → no layout overflow in the tray

### 23.12 Notification do's and don'ts

| ✅ Do | ❌ Don't |
|---|---|
| Route on `data.operation` (lowercased) | Don't parse the `body` text to decide routing |
| Open chat with `data.senderId` | Don't expect `conversation_id` in the push |
| Read `category` from the **card metadata** to tell doctor/hospital/lab apart | Don't try to infer the vertical from the push payload |
| Dedupe socket + push by `messageId` / `bookingId` | Don't show two banners for one event |
| Clear the device token on logout | Don't leave it — the next user gets these pushes |
| Use `appointments.pending` for the Booking badge | Don't use the notification unread count for it |
| Fall back to `NotificationScreen` for unknown ops | Don't leave an empty `default:` |
| Add the two missing cases to the existing group | Don't create a new switch or a doctor-only handler |

---

## 24. Troubleshooting — real bugs seen in testing

### 24.1 Doctor enquiry sent to the HOSPITAL endpoint (CONFIRMED BUG)

**Symptom reported:** *"The doctor account has one enquiry. It shows in the chat, but
`GET /doctor-appointments/owner/me` returns nothing."*

**This is two separate problems mixed together. The backend is behaving correctly in both.**

#### Problem A — an enquiry is NOT an appointment

They are two different objects, in two different collections, with two different endpoints:

| | **Enquiry** | **Appointment (Booking)** |
|---|---|---|
| What it is | "I have a question / I need treatment" | "Book me on this date" |
| Created by | `POST user-service/business-enquiries` | `POST hospital-service/doctor-appointments` |
| Stored in | `businessenquiries` (user-service DB) | `doctorappointments` (hospital-service DB) |
| Doctor's inbox | `GET user-service/business-enquiries/owner/me` | `GET hospital-service/doctor-appointments/owner/me` |
| Chat card | `healthcare_enquiry` | `healthcare_booking` |

> **An enquiry will NEVER appear in `/doctor-appointments/owner/me`.** That endpoint lists
> appointments only. This is by design, not a bug. If the Booking tab should also show
> enquiries, the app must call **both** endpoints and merge the two lists — that is a product
> decision, not a backend gap.

#### Problem B — the enquiry went to the wrong service (the actual bug)

A read-only database check on the reported account
(`ownerId 6a6ad637f26863992efa04fd`, business `6a6ad683f26863992efa0696`, "friends clinic",
`category_Of_Business: "DOCTORS"`) found:

| Collection | Expected | Actually found |
|---|---|---|
| `doctorappointments` (whole DB) | — | **0 rows** → Booking tab is correctly empty |
| `businessenquiries` (correct doctor enquiry inbox) | 2 | **0 rows** |
| `hospitalenquiries` (hospital-only) | 0 | **2 rows** ← the enquiries landed here |

The two stray records look like this:

```jsonc
{
  "category": "HOSPITAL",                 // ← wrong: this business is DOCTORS
  "hospitalId": "6a6ad683f26863992efa0696",
  "departments": ["Cardiology"],          // ← hospital-shaped payload
  "purpose": ["Consultation"],
  "hospitalName": "friends clinic",
  "status": "pending"
}
```

**Root cause:** the app called

```
❌ POST hospital-service/hospital-enquiries    { hospital_id, departments[], purpose[], timeline[] }
```

when for a `DOCTORS` / `CLINICS` business it must call

```
✅ POST user-service/business-enquiries        { business_id, selections{}, note, photos[] }
```

**Why it looked like it "worked":** `hospital-service/hospital-enquiries` does not check the
business category. It resolved the listing over gRPC, saved the row with a hardcoded
`category: "HOSPITAL"`, and published the same `CREATE_HEALTHCARE_ENQUIRY` Kafka event — so a
chat card **did** appear. The record is simply in the wrong place and labelled as a hospital
enquiry, so it will never show in the doctor's enquiry inbox.

#### The fix (client side)

Choose the enquiry endpoint by the listing's `category_Of_Business`:

| `category_Of_Business` | Enquiry endpoint | Payload shape |
|---|---|---|
| `HOSPITALS` | `POST hospital-service/hospital-enquiries` | `hospital_id` + `departments[]` / `purpose[]` / `timeline[]` |
| **`DOCTORS`, `CLINICS`** | **`POST user-service/business-enquiries`** | **`business_id` + generic `selections{}` map** |
| `DIAGNOSTIC` and all other healthcare | `POST user-service/business-enquiries` | `business_id` + `selections{}` |

For a doctor, send the groups inside `selections`:

```json
{
  "business_id": "6a6ad683f26863992efa0696",
  "selections": {
    "Specialization": ["Cardiology"],
    "Purpose": ["Consultation"],
    "Timeline": ["This week"]
  },
  "note": "",
  "photos": []
}
```

#### How to verify the fix

1. Send a new enquiry from a customer to this doctor.
2. `GET user-service/business-enquiries/owner/me` → the new enquiry **must** appear.
3. `GET hospital-service/hospital-enquiries/owner/me` → must **not** grow.

#### What to do about the 2 existing stray records

They are still visible at `GET hospital-service/hospital-enquiries/owner/me`, so nothing is
lost. Options: leave them (harmless test data), or have someone delete them directly in the DB.
**Do not** build a migration for two test rows.

#### Two other findings on this same account

- **The doctor's profile is empty:** `specialization: []`, `consultationFee: 0`. So the
  Discover card will show a blank subtitle and (correctly) **hide** the fee line. Fill the
  profile via `PUT /doctors/me` before judging how the card looks.
- **No appointment has ever been created anywhere** — `doctorappointments` has 0 rows in the
  entire database. To test the Booking tab you must first call
  `POST hospital-service/doctor-appointments`.

#### Optional backend hardening (not done — your call)

`POST /hospital-enquiries` could reject a listing whose `category_Of_Business` is not a
hospital category, turning this silent mis-route into a clear `400`. I have **not** made that
change, because it touches the live hospital enquiry path and some production hospital
businesses may carry non-canonical category values. Say the word if you want it.

### 24.2 Booking tab is empty but the customer says they booked

Check in this order:

1. Did they create an **appointment** or only an **enquiry**? (see §24.1 Problem A)
2. Did the app POST to `doctor-appointments` or `hospital-appointments`? A doctor booking sent
   to `hospital-appointments` will fail with `404 "Doctor not found for this hospital"` because
   there is no OPD record — but check the client logs.
3. Was `business_id` the `Business._id` from Discover, or accidentally a `DoctorProfile._id`?
   The latter returns `404 "Doctor listing not found"`.
4. Is the logged-in account really the listing owner? The inbox filters on
   `ownerId == Business.user_id`.

### 24.3 Chat card appeared but the REST list is empty (or vice versa)

- **Card but no list row** → almost always the wrong endpoint / wrong collection (§24.1).
- **List row but no card** → the record saved but the Kafka publish to chat failed. The
  record is real; do not resubmit. This is the known gap documented in §11.

---

## 25. CUSTOMER SIDE — complete book & enquiry flow

> ### ⚠️ THIS IS THE MISSING HALF
>
> A live audit of the app found the **doctor panel** (owner side) integrated, but the
> **customer side** is not. Customers currently reach a doctor through the *hospital* screens,
> which post to the *hospital* endpoints — that is the confirmed bug in [§24.1](#241-doctor-enquiry-sent-to-the-hospital-endpoint-confirmed-bug).
>
> **Backend status for the customer side: ✅ COMPLETE AND VERIFIED. Nothing to build server-side.**
> Every endpoint below already exists and was tested against live data. See §25.7 for the proof.

### 25.1 The 6 screens a customer needs

```
① Discover → Healthcare → "Clinic Doctors"     (list of standalone doctors)
        ↓  tap a card
② Doctor Public Profile                         (NEW screen — not the hospital one)
        ↓
   ┌────┴─────────────────────────────┐
   ▼                                  ▼
③ Enquiry sheet                    ⑤ Booking sheet
   "I have a question"                "Book me on this date"
        ↓                                  ↓
④ Chat — enquiry card              ⑥ Chat — booking card
   doctor accepts/declines            doctor accepts/declines
                                      customer can cancel
```

Plus two list screens the customer needs to see their own history:

```
⑦ My Enquiries      → GET user-service/business-enquiries/me
⑧ My Appointments   → GET hospital-service/doctor-appointments/me
```

### 25.2 Step ① — Doctor list (Discover)

```
GET user-service/business/filter?category=DOCTORS&page=1&limit=20
```

| Item | Value |
|---|---|
| Auth | ❌ Not required (send it anyway if logged in) |
| Also valid | `category=CLINICS` |
| Pagination | `page` / `limit`, response has `pagination.totalPages` |

**From each card you MUST keep two ids:**

| Keep | Field | Used for |
|---|---|---|
| `businessId` | `_id` | enquiry + booking + ratings + view tracking |
| `ownerUserId` | `user_id` | the doctor's professional profile + chat |

**Card fields** (the doctor enrichment — see §14 for the full list): `business_name`,
`headline`, `degree[]`, `experienceYears`, `consultationFee`, `feeType`, `languagesSpoken[]`,
`certificate_count`, `avg_rating`, `total_ratings`, `logo`, `coverPicture`, `address`.

> ⚠️ `consultationFee` may be **`null`** → hide the fee row. Never render `₹0`.

### 25.3 Step ② — Doctor Public Profile

**Two calls, in parallel:**

```
GET user-service/business/{businessId}          ← identity, photos, gallery, contact, availability, ratings
GET hospital-service/doctors/full/{ownerUserId} ← degree, specialization, fee, expertise, certificates
```

| Call | Auth | 404 handling |
|---|---|---|
| `business/{businessId}` | ✅ | Real error — show retry |
| `doctors/full/{ownerUserId}` | ❌ Public | **NORMAL** — doctor hasn't filled their profile. Render the page from business data only, hide the professional rows. **Never show a full-page error.** |

Optional analytics (fire-and-forget, ignore failures):

```
POST user-service/business/{businessId}/view
POST user-service/profile-visit/{ownerUserId}/profile-visit
```

**What to render:** name, photo, cover, `headline`, degree line, experience, fee, languages,
address + map, expertise bullets, certificates carousel, gallery, testimonials, rating.
**Two CTAs at the bottom: `Chat / Enquiry` and `Book Appointment`.**

### 25.4 Step ③④ — Send an enquiry

```
POST user-service/business-enquiries
```

> ⚠️ **NOT** `hospital-service/hospital-enquiries`. That endpoint is for hospitals only and
> will silently store the record as `category: "HOSPITAL"` in the wrong collection — the exact
> bug in §24.1.

| Item | Value |
|---|---|
| Auth | ✅ Required |
| Content type | **`application/json` only** — no multipart |
| Photos | Already-uploaded **public URLs** (use `GET user-service/upload/init` first) |

**Body:**

```json
{
  "business_id": "6a6ad683f26863992efa0696",
  "selections": {
    "Specialization": ["Cardiology"],
    "Purpose": ["Consultation"],
    "Timeline": ["This week"]
  },
  "note": "Chest pain since 2 days",
  "photos": ["https://bucket.s3.ap-south-1.amazonaws.com/uploads/a.jpg"]
}
```

**`selections` is an open group→values map.** The group labels are **decided by the app**, not
the backend — it stores whatever you send. Recommended groups for a doctor:
`Specialization`, `Purpose`, `Timeline`.

> ⚠️ Do **not** send `departments` / `purpose` / `timeline` as top-level arrays. That is the
> *hospital* payload shape. This endpoint only reads `selections`.

**Rules**
- At least **one selection or a note** — else `400 "At least one selection or a note is required"`
- Max **5** photos — else `400`
- Cannot enquire on your own listing — `400`
- Business not found — `404`

**Success — `201`:** `{ "success": true, "message": "Enquiry sent", "data": { "enquiryId", "status": "pending" } }`

**What happens next (automatic):** a `healthcare_enquiry` card appears in the customer↔doctor
business conversation, the doctor gets `newHealthcareEnquiryReceived` + push + WhatsApp.

**Then:** open the chat thread so the customer sees their card.

**Doctor's reply** flips it via `PUT user-service/business-enquiries/{enquiryId}/status`
`{ "status": "accepted" | "declined" }` → socket `healthcareEnquiryStatusUpdated`.

### 25.5 Step ⑤⑥ — Book an appointment

```
POST hospital-service/doctor-appointments
```

> ⚠️ **NOT** `hospital-service/hospital-appointments`. That one requires an `opd_id` (a doctor
> inside a hospital) and will fail for a standalone doctor.

| Item | Value |
|---|---|
| Auth | ✅ Required |
| Content type | JSON, **or** multipart (`payload` JSON-string + up to 5 `photos` files) |

**Body:**

```json
{
  "business_id": "6a6ad683f26863992efa0696",
  "appointmentDate": "2026-08-05",
  "preferredTime": "10:00 – 11:00 AM",
  "patientName": "Ramesh Kumar",
  "enquiry_id": "6a6ad9f4d4f8f91f09984007",
  "note": "Diabetic patient"
}
```

Only `business_id` and `appointmentDate` are required. **There is no `opd_id`** — the doctor's
name / specialization / fee are snapshotted server-side.

`enquiry_id` is the **`BusinessEnquiry._id`** returned in step ③. Optional — direct booking
without an enquiry works fine.

**Success — `201`:** `{ "success": true, "message": "Appointment request sent", "data": { "appointmentId", "status": "pending" } }`

**Errors:** see the full table in [§5.13](#513-post-doctor-appointments).

**Enquiry-first pattern:** after `healthcareEnquiryStatusUpdated` flips the enquiry card to
`accepted`, show a **"Book Appointment"** button on that card and pass its enquiry id through.

### 25.6 Steps ⑦⑧ — Customer's own history, and cancelling

| Screen | Endpoint | Auth |
|---|---|---|
| My Enquiries | `GET user-service/business-enquiries/me?status=&page=&limit=` | ✅ |
| One enquiry | `GET user-service/business-enquiries/{enquiryId}` | ✅ participant |
| My Appointments | `GET hospital-service/doctor-appointments/me?status=&page=&limit=` | ✅ |
| One appointment | `GET hospital-service/doctor-appointments/{appointmentId}` | ✅ participant |
| **Cancel an appointment** | `PUT hospital-service/doctor-appointments/{id}/status` `{ "status": "cancelled" }` | ✅ customer only |

**Cancel rules:** the customer may cancel while `pending` **or** `accepted`. `declined` and
`cancelled` are terminal → `409`. The customer can **never** send `accepted`/`declined` → `403`.

> There is **no** "cancel enquiry" endpoint. An enquiry only has `pending` → `accepted` /
> `declined`, all set by the doctor. Don't render a cancel button on an enquiry card.

### 25.7 Customer-side API summary + backend verification

| # | Purpose | Method + Endpoint | Service | Exists? |
|---|---|---|---|---|
| 1 | Doctor list | `GET business/filter?category=DOCTORS` | user | ✅ |
| 2 | Business detail | `GET business/{businessId}` | user | ✅ |
| 3 | Doctor professional profile | `GET doctors/full/{ownerUserId}` | hospital | ✅ |
| 4 | Certificates (standalone) | `GET doctor-certificates/doctor/{doctorProfileId}` | hospital | ✅ |
| 5 | Availability | `GET business/availability/hours` | user | ✅ |
| 6 | Testimonials | `GET testimonials/public/{ownerUserId}` | user | ✅ |
| 7 | Ratings read / write | `GET`/`POST business/{businessId}/ratings` | user | ✅ |
| 8 | Track view | `POST business/{businessId}/view` | user | ✅ |
| 9 | Presign upload | `GET upload/init` | user | ✅ |
| 10 | **Send enquiry** | `POST business-enquiries` | user | ✅ |
| 11 | My enquiries | `GET business-enquiries/me` | user | ✅ |
| 12 | **Book appointment** | `POST doctor-appointments` | hospital | ✅ |
| 13 | My appointments | `GET doctor-appointments/me` | hospital | ✅ |
| 14 | Cancel appointment | `PUT doctor-appointments/{id}/status` | hospital | ✅ |
| 15 | Open chat | existing business chat flow | chat | ✅ |

**Backend verification performed on live data** (account `friends clinic`,
business `6a6ad683f26863992efa0696`, `category_Of_Business: "DOCTORS"`):

- `GetDoctorProfileByUserId` gRPC returns the real profile, including
  `expertise: ["angioplasty"]` and **1 certificate with a working S3 image URL** — so the
  doctor-panel write path and the customer-facing read path both work.
- The Discover enrichment builds correctly from that profile.
- `Business` is `isActive: true` with the right category, so it is discoverable.

> **Conclusion: zero backend work required for the customer side.** Every one of the 15 calls
> above is live. The work is 100% Flutter.

### 25.8 Customer-side integration checklist

- ☐ "Clinic Doctors" list calls `business/filter?category=DOCTORS`
- ☐ Card keeps **both** `_id` and `user_id`
- ☐ Card renders `headline`, degree, experience, languages, rating
- ☐ `consultationFee: null` hides the fee row
- ☐ Tapping a card opens the **Doctor** profile, not the hospital screen (§26)
- ☐ Profile makes both calls in parallel
- ☐ `doctors/full/:userId` 404 does not break the page
- ☐ Certificates carousel renders
- ☐ Availability shown from user-service
- ☐ **Enquiry posts to `user-service/business-enquiries`** with `selections{}`
- ☐ Enquiry photos uploaded via presign first, sent as URLs
- ☐ Enquiry card appears in chat
- ☐ "Book Appointment" appears after the doctor accepts
- ☐ **Booking posts to `hospital-service/doctor-appointments`** with `business_id`
- ☐ No `opd_id` sent anywhere
- ☐ Past dates blocked in the picker
- ☐ Booking card appears in chat
- ☐ Customer can cancel while `pending` and while `accepted`
- ☐ My Enquiries + My Appointments screens work
- ☐ No cancel button on enquiry cards

---

## 26. CRITICAL — stop reusing the Hospital screens for Doctors

### 26.1 What the app does today (audited)

`lib/features/common/Discover/view/healthcare/health_care_listing_screen.dart` routes the
**Clinic Doctors** category like this:

```
slug == CLINIC_DOCTORS
   → HospitalListScreen(serviceType: 'DOCTORS')
        → HospitalServiceAiController._fetch()
             → GET user-service/business/filter?category=DOCTORS      ✅ CORRECT API
             → record.toHospitalFullData()                            ❌ hospital adapter
        → on tap: Get.to(() => DiscoverHospitalHomeScreen())          ❌ HOSPITAL screen
```

### 26.2 Why this is wrong — three concrete failures

**Failure 1 — every doctor field is thrown away.**
`business_filter_to_hospital_adapter.dart` maps a listing into `HospitalFullData`. By its own
docstring it maps only "logo, cover/gallery, name, description, address + coordinates,
primary phone, department names/count + facility names/count". It has **no fields** for
`headline`, `specialization`, `degree`, `experienceYears`, `consultationFee`, `feeType`,
`languagesSpoken` or `certificate_count`. The backend sends all of them; the adapter
**silently discards** them. That is why doctor cards look empty.

**Failure 2 — the detail screen is a hospital.**
`DiscoverHospitalHomeScreen` loads the full **hospital** profile and renders
`OPD / IPD Departments`, `Emergency & Critical Care`, `Other Facilities`, `Vision & Mission`,
`Emergency Contact`, and caches "OPD doctors". A standalone doctor has **none** of these — no
hospital record, no departments, no OPD rows. The user sees a broken, mostly-empty hospital page.

**Failure 3 — this is what caused the §24.1 bug.**
Because the customer lands on the hospital detail screen, its enquiry button posts to
`hospital-service/hospital-enquiries` with the hospital payload
(`departments[]` / `purpose[]`). That is exactly why the two live enquiries for "friends clinic"
were stored in `hospitalenquiries` with `category: "HOSPITAL"` and never appeared in the
doctor's proper inbox. **Fixing the screens fixes the data bug.**

### 26.3 What to change

| Step | Action |
|---|---|
| 1 | **Stop** routing `CLINIC_DOCTORS` to `HospitalListScreen`. Point it at a new `DoctorDiscoverListScreen`. |
| 2 | **Do not** use `toHospitalFullData()` for doctors. Parse the listing into a new `DoctorDiscoverSummary` model that keeps the doctor enrichment fields. |
| 3 | **Do not** open `DiscoverHospitalHomeScreen`. Open a new `DoctorPublicProfileScreen` (§25.3). |
| 4 | Enquiry → `user-service/business-enquiries` with `selections{}` (§25.4). |
| 5 | Booking → `hospital-service/doctor-appointments` with `business_id`, no `opd_id` (§25.5). |

**Precedent to copy:** the Diagnostic/Lab category already does this correctly —
`slug == LABTEST` opens **`LabDiscoverListScreen`**, its own screen, not `HospitalListScreen`.
Follow that exact pattern for doctors.

```
// today                                    // target
slug == LABTEST  → LabDiscoverListScreen    slug == LABTEST        → LabDiscoverListScreen
slug == HOSPITAL → HospitalListScreen       slug == HOSPITAL       → HospitalListScreen
slug == CLINIC_DOCTORS → HospitalListScreen slug == CLINIC_DOCTORS → DoctorDiscoverListScreen  ★NEW
```

### 26.4 What must NOT change

- `HospitalListScreen` with `serviceType: 'HOSPITALS'` — leave exactly as is.
- `DiscoverHospitalHomeScreen` — leave exactly as is. It is correct **for hospitals**.
- `business_filter_to_hospital_adapter.dart` — leave it; hospitals still need it.
- `slug == ALTERNATIVE_WELLNESS → HospitalListScreen(serviceType: 'wellness')` — out of scope
  here, but note it has the same "wellness rendered as a hospital" smell. Raise separately.

> **Do not "fix" this by adding doctor fields to `HospitalFullData`.** That would couple the
> two verticals in the model layer — the same mistake the backend deliberately avoided by
> keeping `DoctorProfile` and `OPD` completely separate. Build the parallel doctor path.

### 26.5 Acceptance test for this change

- ☐ Clinic Doctors tab lists doctors with specialization, degree, experience, fee, languages
- ☐ Tapping a doctor opens a **doctor** page — no Departments, no Emergency Care, no OPD list
- ☐ Enquiry from that page lands in `businessenquiries` (user-service), **not** `hospitalenquiries`
- ☐ Booking from that page lands in `doctorappointments`, **not** `hospitalappointments`
- ☐ The doctor sees the enquiry at `GET user-service/business-enquiries/owner/me`
- ☐ The doctor sees the booking at `GET hospital-service/doctor-appointments/owner/me`
- ☐ **Regression:** the Hospitals tab and hospital detail page are byte-for-byte unchanged
- ☐ **Regression:** hospital enquiry + hospital OPD appointment still work

---

## Quick reference — the 14 mistakes to avoid

1. **`GET /doctors/me` returning `hasProfile: false` is a `200`, not an error.**
2. **`business_id` ≠ `DoctorProfile._id`.** Booking and enquiry use `Business._id` from Discover.
3. **`GET /doctors/full/:userId` takes `Business.user_id`,** not `Business._id`.
4. **There is no `opd_id`** in the standalone doctor booking API.
5. **`consultationFee: null` means "not set"** — hide the line; never render `₹0`.
6. **No approval workflow exists.** Do not build a pending/verification screen.
7. **Never auto-retry POSTs** — duplicate profiles, certificates and bookings.
8. **Multipart appointments need a `payload` JSON-string part**, not flat form fields.
9. **It is `healthcare_booking_update`, not `healthcare_booking_status`.** Hotel uses
   `_status`; healthcare uses `_update`.
10. **`healthcare_booking` is not in Flutter's notification routing switch yet** — add it,
    or every appointment push dead-ends (§23.6).
11. **The push payload has no `category`.** To tell doctor / hospital / lab apart, read
    `category` from the chat card metadata, not from the notification.
12. **Doctor enquiry goes to `user-service/business-enquiries`** with a `selections{}` map —
    **not** `hospital-service/hospital-enquiries` with `departments[]` (§24.1, §25.4).
13. **Never open `DiscoverHospitalHomeScreen` for a doctor.** Build a doctor profile screen.
    Reusing the hospital screen is what caused the wrong-endpoint bug (§26).
14. **Never map a doctor listing through `toHospitalFullData()`** — it silently discards every
    doctor field the backend sends (§26.2).
