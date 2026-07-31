# Standalone Doctor — Flutter Frontend Audit & Fix Guide

> **What this document is:** a code-level audit of `C:\BlueEra\BlueEra_flutter` for the
> Standalone Doctor feature. It lists **exactly what is wrong, why it is wrong, where it is
> wrong (file + line), and what to build instead.**
>
> **Backend is confirmed working.** 31/31 live API tests passed against production
> (see `STANDALONE_DOCTOR_FLUTTER_GUIDE.md` §27). Every bug below is client-side.
>
> **No code in this document — instructions only.**

---

## Table of Contents

1. [Verdict in one page](#1-verdict-in-one-page)
2. [What the frontend already got RIGHT](#2-what-the-frontend-already-got-right)
3. [🔴 BUG #1 — A doctor booking can never be created](#3--bug-1--a-doctor-booking-can-never-be-created)
4. [🟠 BUG #2 — Booking push notifications dead-end](#4--bug-2--booking-push-notifications-dead-end)
5. [🟡 BUG #3 — "Alternative Wellness" still routed as a hospital](#5--bug-3--alternative-wellness-still-routed-as-a-hospital)
6. [The fix plan — what to build and what to reuse](#6-the-fix-plan--what-to-build-and-what-to-reuse)
7. [How to verify each fix](#7-how-to-verify-each-fix)
8. [Final checklist](#8-final-checklist)

---

## 1. Verdict in one page

### The complaint

> *"Order received in chat, all working — but `GET /doctor-appointments/owner/me` shows nothing."*

### The cause, in one sentence

**The app has no way to create a doctor booking.** The customer can only send an *enquiry*.
The booking API is wired in the repository layer but **no screen ever calls it**.

### The proof

| Check | Result |
|---|---|
| `doctorappointments` rows in the production DB | **0** (before my test) |
| Callers of `DoctorAppointmentRepo.createAppointment()` | **0** |
| Callers of `DoctorAppointmentRepo.getMyAppointments()` | **0** |
| Callers of `DoctorAppointmentRepo.getAppointmentById()` | **0** |
| "Book Appointment" CTA on the doctor's public profile | **does not exist** |
| "Book Appointment" CTA on a DOCTOR enquiry chat card | **blocked by a category check** |
| A doctor appointment sheet (like the hospital one) | **does not exist** |
| Backend `POST /doctor-appointments` | ✅ works — returns `201`, appears in both inboxes |

So the Booking tab is empty **because nothing has ever been booked**, not because the
endpoint is broken. The chat card the doctor sees is an **enquiry**, which is a different
object stored in a different collection and will never appear in the booking list.

### Scoreboard

| Area | Status |
|---|---|
| Doctor panel (owner side) | ✅ **Complete** |
| Discover list + card | ✅ **Complete** |
| Public doctor profile | ⚠️ **Enquiry only — no booking** |
| Customer booking flow | 🔴 **Missing entirely** |
| Customer "My Appointments" | 🔴 **Missing entirely** |
| Booking push notifications | 🟠 **Dead-end on tap** |

---

## 2. What the frontend already got RIGHT

Credit where it is due — most of the work is done and correct. **Do not touch these.**

| Area | File | Status |
|---|---|---|
| Doctor endpoints | `core/api/apiService/hospital_service_api.dart:134-168` | ✅ All 17 defined correctly |
| Doctor module | `features/me/doctor/**` | ✅ Controllers, models, repos, views |
| Doctor dashboard | `features/me/doctor/view/v2/doctor_home_screen_v2.dart` | ✅ 5-tab host |
| About Me + edit form | `view/v2/tabs/doctor_about_me_tab.dart`, `view/about/*` | ✅ Built |
| Chip inputs | `widget/doctor_chip_input_field.dart` | ✅ Correct pattern |
| Certificates | `view/certificate/doctor_certificates_screen.dart` | ✅ Built |
| Overview / Statics | `view/v2/tabs/doctor_overview_tab.dart`, `doctor_statics_tab.dart` | ✅ Built |
| **Booking tab (doctor inbox)** | `view/v2/tabs/doctor_booking_tab.dart` | ✅ Built, accept/decline wired |
| **Discover routing fixed** | `Discover/view/healthcare/health_care_listing_screen.dart` | ✅ `CLINIC_DOCTORS` → `DoctorDiscoverListView` |
| Discover model | `Discover/model/doctor_discover_summary.dart` | ✅ Parses all doctor fields |
| **Null-fee handled** | `doctor_discover_summary.dart:136` `hasFee` getter | ✅ Correct |
| Doctor card | `Discover/widget/doctor_discover_card.dart` | ✅ Built |
| Public profile | `Discover/view/healthcare/doctor_public_profile_screen.dart` | ✅ Built (except booking) |
| **Enquiry uses the right endpoint** | profile screen → `HealthcareEnquirySheet` under DOCTOR category | ✅ Correct |
| Booking repo (multipart shape) | `repo/doctor_appointment_repo.dart` | ✅ Correct — `payload` + `photos` |

> The §26 problem from the previous guide (doctors routed through the hospital screens)
> **has been fixed.** `CLINIC_DOCTORS` now opens `DoctorDiscoverListView`, and the enquiry
> correctly posts to `user-service/business-enquiries` with a `selections{}` map.

---

## 3. 🔴 BUG #1 — A doctor booking can never be created

**Severity: CRITICAL.** This is the reported problem. Three separate pieces are missing.

### 3.1 Missing piece A — no "Book Appointment" button on the doctor profile

**File:** `features/common/Discover/view/healthcare/doctor_public_profile_screen.dart`
**Line ~140:** the bottom bar renders only `_enquiryBottomBar(...)`.
**Line 631-648:** `_enquiryBottomBar` builds exactly **one** button, titled `AppStrings.inquiry.tr`.

**What is wrong:** a customer viewing a doctor can only send an enquiry. There is no path to
a booking from the profile at all.

**Compare with hospitals:** `discover_hospital_home_screen.dart` opens
`HospitalAppointmentSheet` for direct booking. Doctors have no equivalent.

**What to do:** add a **second** CTA next to Inquiry — e.g. a two-button row
`[ Inquiry ] [ Book Appointment ]`. Hide both on your own listing (that check already exists
and is correct — keep it).

---

### 3.2 Missing piece B — the enquiry chat card blocks the CTA for doctors

**File:** `features/chat/view/business_chat/widgets/healthcare_enquiry_msg_card.dart`

```
line 414   if (_isMyMessage && _canOpenAppointmentSheet) _bookAppointmentRow();
line 415   if (_isMyMessage && _canOpenLabBookingSheet)  _bookTestRow();

line 605   bool get _canOpenAppointmentSheet {
line 608     if ((e.category ?? '').toUpperCase() != 'HOSPITAL') return false;   ← BLOCKS DOCTORS
line 616   HospitalAppointmentSheet.open(...)                                    ← hospital sheet

line  48     if ((e.category ?? '').toUpperCase() != 'LABORATORY') return false; ← lab branch
```

**What is wrong:** the card supports exactly two verticals — `HOSPITAL` and `LABORATORY`.
A **`DOCTORS`**-category enquiry matches neither, so after the doctor accepts the enquiry the
"Book Appointment" button **never renders**. The enquiry-first flow is dead for doctors.

> This is why the flow "feels" complete: the enquiry is sent, the card appears, the doctor
> accepts — and then it silently stops. There is no next step in the UI.

**What to do:** add a **third** branch for `DOCTOR` / `DOCTORS` that opens a new doctor
appointment sheet. Follow the exact shape of the two existing branches — same guard style
(hide the button when any required id is missing), same row widget pattern.

> ⚠️ **Category string check.** The enquiry card receives `category` from the enquiry
> record, which for a doctor is **`"DOCTORS"`** (plural — copied from
> `Business.category_Of_Business`). The **booking** card uses **`"DOCTOR"`** (singular).
> Accept **both**, case-insensitively, or the button will silently stay hidden. This
> mismatch is real and is the easiest thing to get wrong in this whole fix.

---

### 3.3 Missing piece C — there is no doctor appointment sheet

**Exists:** `features/me/medical/widget/hospital_appointment_sheet.dart` (hospital) and a lab
booking sheet.
**Missing:** any doctor equivalent.

**Why the hospital sheet cannot be reused:** it is built around picking an **OPD doctor**
(`opd_id`) from a hospital's department list. A standalone doctor has **no OPD record and no
departments** — `opd_id` does not exist and the backend does not accept it.

**What the doctor sheet must collect:**

| Field | Required | Notes |
|---|---|---|
| `business_id` | ✅ | The `Business._id` the profile was opened with. **Not** `DoctorProfile._id`. |
| `appointmentDate` | ✅ | Date picker, **today or later** — disable past dates |
| `preferredTime` | ⬦ | Free text or chips. Show the doctor's availability as guidance only |
| `patientName` | ⬦ | Who the visit is for |
| `note` | ⬦ | Free text |
| `enquiry_id` | ⬦ | Only when opened from an accepted enquiry card |
| `photos` | ⬦ | Max 5, ≤10 MB each — reports/prescriptions |

**Do NOT send:** `opd_id`, `doctorName`, `specialization`, `fees`, `doctorProfileId`.
The backend snapshots all of those server-side. Verified live:

```
category: "DOCTOR", doctorName: "Dr Kevin Cancer Specialist",
specialization: "dentist", fees: 200, feeType: "Per Visit"
```

**What to call:** `DoctorAppointmentRepo.createAppointment()` — **already written and correct**,
including the unusual multipart shape (one `payload` JSON-string part + up to five `photos`
file parts). It just has no caller today.

---

### 3.4 Missing piece D — the customer has no "My Appointments" screen

`getMyAppointments()` and `getAppointmentById()` have **zero callers**. A customer who books
has no way to see or **cancel** the request.

**What to build:** a "My Appointments" list for the customer, with a **Cancel** action.

> Cancel rules (server-enforced, verified): the customer may cancel while `pending`
> **and** while `accepted`. The customer may **never** send `accepted`/`declined` → `403`.
> `declined`/`cancelled` are terminal → `409`.

---

## 4. 🟠 BUG #2 — Booking push notifications dead-end

**File:** `core/services/app_notification.dart`
**Line 3234-3235:** the enquiry/booking case group contains only:

```
case 'healthcare_enquiry':
case 'healthcare_enquiry_status':
```

**Missing:** `healthcare_booking` and `healthcare_booking_update`.

**Effect:** the notification is delivered and displayed, but tapping it falls through to
`default:` and goes nowhere. The doctor gets a push about a new appointment and tapping it
does nothing.

> ⚠️ **Naming trap:** hotel uses `hotel_booking_status`; healthcare uses
> **`healthcare_booking_update`** — `_update`, not `_status`.

**Note:** this is a **pre-existing gap that already affects hospital appointments and lab test
bookings**, not something the doctor feature introduced. Adding the two cases to the existing
group repairs all three verticals at once.

**Where they should go:** the same case group that already handles `healthcare_enquiry`,
`hotel_booking` and `vehicle_booking` — they all call `_openChatWithUser(data['senderId'])`.

---

## 5. 🟡 BUG #3 — "Alternative Wellness" still routed as a hospital

**File:** `features/common/Discover/view/healthcare/health_care_listing_screen.dart`

```
slug == ALTERNATIVE_WELLNESS  →  HospitalListScreen(serviceType: 'wellness')
```

**Two problems:**

1. **Same mixing bug that was just fixed for doctors** — wellness listings get force-fitted
   through the hospital adapter and land on the hospital detail screen.
2. **`'wellness'` is almost certainly not a real category tag_id.** The backend resolves
   `category` against `Category.tag_id`, which are UPPER_SNAKE values like `HOSPITALS`,
   `DOCTORS`, `DIAGNOSTIC`. A lowercase `'wellness'` will very likely match nothing and
   return an empty list.

**Severity:** low for the doctor feature, but it is the same class of defect and worth a
separate ticket. **Out of scope for this fix — do not bundle it in.**

---

## 6. The fix plan — what to build and what to reuse

### 6.1 Order of work

| # | Task | Why first |
|---|---|---|
| 1 | Doctor appointment sheet | Everything else depends on it |
| 2 | "Book Appointment" CTA on the public profile | Direct booking path |
| 3 | `DOCTOR` branch in the enquiry chat card | Enquiry-first path |
| 4 | Notification cases | Makes the push actionable |
| 5 | Customer "My Appointments" + cancel | Completes the loop |

### 6.2 What to reuse — do not rebuild

| Need | Reuse this | Location |
|---|---|---|
| Call the booking API | `DoctorAppointmentRepo.createAppointment()` | `features/me/doctor/repo/doctor_appointment_repo.dart` |
| Endpoint constants | `doctorAppointments`, `doctorAppointmentsMe`, `doctorAppointmentStatus(id)` | `core/api/apiService/hospital_service_api.dart:158-168` |
| Appointment model | `DoctorAppointmentModel` | `features/me/doctor/model/doctor_appointment_model.dart` |
| Appointment card widget | `DoctorAppointmentCard` | `features/me/doctor/widget/doctor_appointment_card.dart` |
| State pattern | `DoctorAppointmentController` | `features/me/doctor/controller/` |
| Sheet structure / layout | `HospitalAppointmentSheet` — **copy the shape, not the `opd_id` logic** | `features/me/medical/widget/hospital_appointment_sheet.dart` |
| Enquiry sheet | `HealthcareEnquirySheet` — already used correctly | `features/me/medical/widget/healthcare_enquiry_sheet.dart` |
| Image picking / crop | `image_picker` + `croppy` | already in `pubspec.yaml` |
| Chat card rendering | `healthcare_booking_msg_card.dart` — already exists | `features/chat/view/business_chat/widgets/` |

### 6.3 What NOT to do

| ❌ Don't | Why |
|---|---|
| Send `opd_id` in a doctor booking | Only hospitals have OPD records; the field does not exist here |
| Send `doctorName` / `fees` / `specialization` | The server snapshots them — client values are ignored |
| Use `DoctorProfile._id` as `business_id` | Different id space → `404 "Doctor listing not found"` |
| Reuse `HospitalAppointmentSheet` as-is | It is built around picking an OPD doctor |
| Auto-retry `createAppointment` on timeout | Creates duplicate bookings. Verify with `GET /doctor-appointments/me` first |
| Add doctor fields to `HospitalFullData` | Couples the two verticals — the exact mistake the backend avoided |
| Build any approval/verification UI | There is no approval step. A doctor is live on registration |
| Write your own `401` handling | `AuthManager.handleLogout()` already does it |

### 6.4 Data the sheet needs at open time

| From | Value | Used as |
|---|---|---|
| Discover card / profile screen | `Business._id` | `business_id` |
| Discover card / profile screen | `Business.user_id` | chat + profile fetch |
| Enquiry chat card (enquiry-first only) | `enquiryId` | `enquiry_id` |
| Doctor profile (display only) | `consultationFee` + `feeType` | show "You will be charged ₹600/Visit at the clinic" |

> The fee is **display only**. There is no payment in this flow — do not wire Razorpay.

---

## 7. How to verify each fix

### 7.1 Booking creation (BUG #1)

1. Log in as a customer, open a doctor from Discover.
2. Tap **Book Appointment**, pick a future date, submit.
3. Expect `201` with `{ appointmentId, status: "pending" }`.
4. Log in as the doctor → **Booking tab** must show it immediately.
5. Confirm in the DB: the row is in **`doctorappointments`**, `category: "DOCTOR"` —
   **not** in `hospitalappointments`.

### 7.2 Enquiry-first path

1. Customer sends an enquiry → doctor accepts.
2. The customer's enquiry card must now show **Book Appointment**.
3. Tapping it opens the doctor sheet with `enquiry_id` prefilled.
4. After submit, the created appointment must have `enquiryId` populated (not `null`).

### 7.3 Permissions

| Action | Expected |
|---|---|
| Customer taps Accept | Button should not be visible; API returns `403` |
| Doctor taps Cancel | Button should not be visible; API returns `403` |
| Accept an already-declined booking | `409` → refresh the list |
| Book a past date | Blocked in the picker; API returns `400` |
| Book your own listing | CTA hidden; API returns `400` |

### 7.4 Notifications (BUG #2)

1. Customer books → doctor receives a push.
2. **Tap it from foreground, background, and killed state** — all three must navigate.
3. Regression: hospital appointment and lab booking pushes must also now route.

### 7.5 Regression — must still pass

- Hospitals tab and hospital detail page unchanged
- Hospital enquiry + hospital OPD appointment unchanged
- Lab booking unchanged
- Doctor panel (Overview / About Me / Certificates / Statics) unchanged

---

## 8. Final checklist

### 🔴 Critical — booking

- ☐ Doctor appointment sheet created (no `opd_id`)
- ☐ Sheet collects `business_id`, `appointmentDate`, `preferredTime`, `patientName`, `note`, `photos`
- ☐ Past dates disabled in the picker
- ☐ Max 5 photos, ≤10 MB each, enforced client-side
- ☐ Sheet calls `DoctorAppointmentRepo.createAppointment()`
- ☐ **Book Appointment** CTA added to the doctor public profile
- ☐ Both CTAs hidden on your own listing
- ☐ `DOCTOR` branch added to `healthcare_enquiry_msg_card.dart`
- ☐ Category check accepts **both** `"DOCTOR"` and `"DOCTORS"`, case-insensitively
- ☐ `enquiry_id` passed through from the enquiry card
- ☐ No `opd_id` / `doctorName` / `fees` sent anywhere
- ☐ No auto-retry on timeout
- ☐ Customer **My Appointments** screen built (`getMyAppointments`)
- ☐ Customer **Cancel** works from `pending` **and** `accepted`
- ☐ Booking appears in the doctor's Booking tab immediately

### 🟠 Notifications

- ☐ `healthcare_booking` added to the routing switch
- ☐ `healthcare_booking_update` added (`_update`, not `_status`)
- ☐ Tap verified from foreground / background / killed
- ☐ Hospital + lab booking pushes verified as a regression

### 🟡 Separate ticket

- ☐ `ALTERNATIVE_WELLNESS` routing raised as its own issue (do not bundle)

### ✅ Regression

- ☐ Hospital flow unchanged
- ☐ Lab flow unchanged
- ☐ Doctor panel unchanged
- ☐ Discover doctor list + card unchanged

---

## Appendix — the one-line summary for your standup

> The backend booking API works (verified 31/31 in production). The doctor panel and Discover
> are done. **The customer can only enquire, never book** — `createAppointment()` has zero
> callers, the profile has no Book CTA, and the enquiry card's Book button is hard-gated to
> `HOSPITAL`/`LABORATORY` so it never appears for doctors. Build the doctor appointment sheet,
> wire the two CTAs, add the `DOCTOR` category branch, and add two missing notification cases.
