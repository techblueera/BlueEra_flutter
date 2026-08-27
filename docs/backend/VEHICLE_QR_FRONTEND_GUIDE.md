# Vehicle-safety QR — frontend integration guide

**Service:** `be_emergency_service`
**Base URL:** `https://be.beapp.in/api/emergency-service/vehicle-qr`
**Audience:** Flutter app **and** the web landing page — both are needed.

Read `VEHICLE_QR_FLOW.md` first if you want the why. This is the how.

> **Generating and printing stickers is a different job** — see
> `VEHICLE_QR_ADMIN_PANEL_GUIDE.md`. This guide is only about what happens
> after someone scans one.

---

## 0. What you are building

**One client: the web page.** The sticker encodes
`https://emergency.beapp.in/v/{code}` — the web page owns that route and reads
`{code}` from it. Every scan lands there, in the phone's browser, whether or not
the app is installed. That single page runs every journey below.

The app claims `blueera.ai`, not `beapp.in`, so the phone's camera opens the
scan URL in the **browser** and the app is never invoked by the sticker itself.

> ⚠️ **Do not add App Links / Associated Domains for `emergency.beapp.in`.**
> That would make Android hand the scan URL to the app, which has no screen for
> it — a blank screen instead of a working page. The absence of that config is
> what makes this work.

### The one piece of app work

The **parking-issue** flow hands the browser a deep link into the app's chat, so
the reporter can message the owner with text, photos and video. The app's
deep-link router rejects that link today — it needs one small change, written
out in **§2a-app**. That is the whole Flutter scope.

Section 3b (`/assign`) documents the in-app claim. It is **built and tested on
the backend, but not wired up in the app** — there for a later release, so an
in-app path can be added without touching the data model. Ignore it for now.

---

## 1. Every scan starts here

```http
GET /vehicle-qr/{code}
Authorization: Bearer <token>      ← optional, app only
```

Public. Sending a token is optional and only changes `canClaimInApp`.

**Already claimed:**

```json
{
  "success": true,
  "status": "assigned",
  "code": "VQ7K3M9A",
  "vehicleNumber": "UP16••4618",
  "owner": { "name": "Devendra Kumar", "mobileMasked": "95•••••952" },
  "options": ["parking_issue", "sos"]
}
```

**Not claimed:**

```json
{ "success": true, "status": "unassigned", "code": "VQ7K3M9A", "canClaimInApp": false }
```

**Other responses:** `404` unknown code · `410` sticker disabled. Show a plain
"this QR is not valid" for both — do not retry.

### ⛔ Never render a blank screen

**Every branch below must put words on the page, including the error ones.** A
person is standing next to a car holding a phone. A blank screen ends the
campaign for them; they will not retry, and they will not install anything.

| Situation | Response | What to show |
|---|---|---|
| Fresh sticker | `200` `status: "unassigned"` | **क्या यह वाहन आपका है?** / Is this vehicle yours? |
| Claimed sticker | `200` `status: "assigned"` | masked plate + owner + the two buttons — **this is the working state, not an error** |
| Code not in the system | `404` | यह QR मान्य नहीं है / This QR is not valid |
| Sticker switched off | `410` | यह QR अब सक्रिय नहीं है / This QR is no longer active |
| Claiming a taken sticker | `409` from `/claim`, `/assign` or `/otp` | **यह QR पहले से रजिस्टर्ड है / This QR is already registered** |
| That vehicle already has one | `409` from `/claim` or `/assign` | इस वाहन का QR पहले से मौजूद है / This vehicle already has a registered QR |
| Backend unreachable | `500` or network failure | कुछ गलत हो गया / Something went wrong — please try again |

> **A claimed sticker is NOT "already used".** `status: "assigned"` is the
> success case — it is the sticker doing its job, and it must show parking and
> SOS. "Already registered" belongs only on a `409`, which happens when someone
> tries to *claim* a sticker that already belongs to a vehicle.

Write the code parser defensively too: if the URL has no code, or the fetch
throws, show the "not valid" message rather than an empty page.

> The vehicle number is **masked on purpose** so the scanner can confirm they
> scanned the right car without the sticker leaking a full plate to anyone who
> walks past. The owner's real number is never in this response.

---

## 2. Claimed → two options

Render exactly the two entries in `options`.

### 2a. Parking issue — opens a chat with the owner

```http
POST /vehicle-qr/{code}/report
{ "type": "parking_issue", "message": "Blocking my gate", "location": { "lat": 28.55, "lon": 77.37 } }
```

**Owner has the app** (`userId` on the sticker):

```json
{
  "success": true,
  "handledBy": "app",
  "chatAvailable": true,
  "message": "Open the app to message the owner directly.",
  "owner": { "userId": "6a1ea272…", "name": "संजय सदाशिव मेन" },
  "deepLink": "https://blueera.ai/app/chat/new?userId=6a1ea272…&chatType=personal&name=…&source=vehicle_qr&code=2MFH29JY&vehicleNumber=MH01AB2020",
  "appDownloadUrl": "https://blueera.ai/download"
}
```

**Owner claimed on the web, no account** — nobody to chat with:

```json
{
  "success": true,
  "handledBy": "web",
  "chatAvailable": false,
  "message": "Report recorded. This vehicle's owner has not installed the app, so a chat cannot be opened.",
  "appDownloadUrl": "https://blueera.ai/download"
}
```

**Branch on `chatAvailable`, not on `handledBy`:**

| `chatAvailable` | Web page shows |
|---|---|
| `true` | **[ Message the owner ]** → `deepLink`, and below it *"Don't have the app? Download"* → `appDownloadUrl` |
| `false` | the confirmation text only — **no chat button**, since there is no account behind the sticker |

The chat carries text, photos and video, and the owner gets a push notification
because it is the app's normal chat. That is why this routes into the app rather
than posting a one-way form: a parking complaint is a conversation — *"which
car?"*, *"coming in 2 minutes"*, a photo of the blocked gate.

`message` and `location` are optional but send them — they are recorded against
the sticker even when the reporter never opens the chat.

> ⚠️ **The app does not handle this link yet.** Its deep-link router requires
> segment 3 to be a 24-hex ObjectId and rejects the literal `new`. See §2a-app
> below — one small change in `splash_screen.dart`.

### 2a-app. What the Flutter app must add

This is the **only** app work in the whole campaign, and it is small.

The app already routes `https://blueera.ai/app/chat/{conversationId}` into
`PersonalChatScreen`. Two strangers have no conversation yet, so the backend
sends `new` in that slot. Today `_handleDeepLink` rejects it:

```dart
final id = segments[2];
if (!_isValidMongoId(id)) {   // "new" fails here → return, nothing opens
  logs('Invalid ID format in deep link: $id');
  return;
}
```

**The change:** let `new` through, and open the chat in initial-message mode.

```dart
final id = segments[2];
// "new" = a chat that does not exist yet (vehicle-QR parking reports).
// chat-service creates the conversation when the first message is sent.
if (id != 'new' && !_isValidMongoId(id)) {
  logs('Invalid ID format in deep link: $id');
  return;
}
...
case 'chat':
  final isNew = id == 'new';
  Get.to(() => PersonalChatScreen(
    conversationId: isNew ? '' : id,
    userId: chatUserId,
    type: chatType,
    name: chatName,
    isInitialMessage: isNew,     // ← already a supported parameter
  ));
```

Optional polish: read `source`, `code` and `vehicleNumber` from the query and
prefill the first message — *"Regarding your vehicle MH01AB2020…"*.

**No manifest change.** The link is on `blueera.ai/app/...`, which the app
already claims. Do **not** add App Links for `emergency.beapp.in` — that host
must stay with the browser.

### 2b. SOS — works with no app

```http
POST /vehicle-qr/{code}/report
{ "type": "sos" }
```

```json
{ "success": true, "contact": { "available": true, "masked": false, "mobile": "9582415952" } }
```

**Check `contact.available` first, then `contact.masked`.** They answer two
different questions, and confusing them puts a dead call button on an emergency
screen:

| `available` | `masked` | What to render |
|---|---|---|
| `true` | `false` | the real number, with a working call button |
| `true` | `true` | the masked number as **text only** — no call button |
| `false` | `false` | "Alert recorded. The owner has been notified." No number, no call button. |

`available: false` means the owner never filled in their emergency profile, so
there is no number to give and `mobile` is `null`. The alert is recorded either
way. **Never test `masked` on its own** — it is `false` in that case too, and a
call button wired to `null` does nothing in an emergency.

Both calls need no auth. `404` means the sticker is not claimed — you should not
have shown these options at all.

---

## 3. Not claimed → registration

### 3a. ALWAYS ask this first — app or no app

Before anything else, in **Hindi and English on the same screen**:

> **क्या यह वाहन आपका है?**
> Is this vehicle yours?

- **No / नहीं** → close quietly. **Call nothing** — no follow-up request, no
  analytics ping. A short "Thanks for checking" and dismiss.
- **Yes / हाँ** → continue below, splitting on whether the app is installed.

**This applies to signed-in app users too.** Being signed in proves who they
are, not which vehicle is theirs — the person scanning is just as likely to be
the passer-by who spotted the sticker. Skipping the question in the app would
let anyone bind a stranger's sticker to their own car with one tap.

### 3b. Answered yes, app installed

```http
POST /vehicle-qr/{code}/assign
Authorization: Bearer <token>
{ "vehicleNumber": "UP16FL4618", "confirmedOwnership": true }
```

`200` done · `400` `confirmedOwnership` not `true` · `409` someone else
already claimed it.

**`confirmedOwnership` must be literally `true`** — it is the recorded answer to
the question above. Do not hardcode it; set it from what the user actually
tapped. No OTP here: signing in already proved the phone number.

### 3c. Answered yes, no app — the web journey

*Register now / अभी रजिस्टर करें*, with the terms and conditions visible and an
explicit agree control, then:

**Step 1 — mobile number → OTP:**

```http
POST /vehicle-qr/{code}/otp
{ "mobileNumber": "9876543210" }
```

`200` sent · `409` already registered · `503` OTP service down, let them retry.

**Step 2 — verify and register:**

```http
POST /vehicle-qr/{code}/claim
{
  "mobileNumber": "9876543210",
  "otp": "123456",
  "vehicleNumber": "UP16FL4618",
  "ownerName": "Devendra Kumar",
  "termsAccepted": true
}
```

```json
{
  "success": true,
  "message": "QR registered to your vehicle",
  "vehicleNumber": "UP16FL4618",
  "appDownloadUrl": "https://blueera.ai/download"
}
```

**Then show the download link.** Converting the registration into an install is
the entire point of the campaign — make it the most prominent thing on the
success screen.

**`termsAccepted` must be literally `true`.** Anything else is a `400`. Do not
default it — the user has to tick it.

#### Where the terms text comes from

```http
GET /vehicle-qr/terms
```

```json
{
  "success": true,
  "version": "2026-08-1",
  "updatedAt": "2026-08-26",
  "terms": {
    "en": {
      "title": "Vehicle Safety QR — Terms of Use",
      "sections": [ { "heading": "1. You confirm this vehicle is yours", "body": "…" } ]
    },
    "hi": {
      "title": "वाहन सुरक्षा QR — उपयोग की शर्तें",
      "sections": [ { "heading": "1. आप पुष्टि करते हैं कि यह वाहन आपका है", "body": "…" } ]
    }
  }
}
```


Public, no token. **Render this — do not hardcode the wording in the page.** The
claim records which `version` the user accepted, and a consent record that
cannot say *what* was agreed to is not a record. Hardcoded text drifts from the
stored version and the audit trail silently becomes fiction.

Eight sections, Hindi and English. **Section 3 is the one that must be visible
without scrolling or expanding** — it discloses that the owner's phone number is
shown to anyone who scans the sticker and taps Emergency. Burying it is how a
consent becomes worthless.

**Errors:** `400` bad mobile / bad plate / terms not accepted · `409` sticker or
vehicle already registered · `503` OTP service unreachable.

**No BlueEra account is needed.** If the number has no account the OTP still
verifies and registration completes. Do not send anyone to sign-up first.

---

## 4. Input rules

**Mobile** — 10 digits, starting 6–9. Strip `+91`, spaces and hyphens before
sending; the server does too, but validate client-side to save a round trip.

**Vehicle number** — send it however the user typed it. The server strips spaces
and hyphens and uppercases, so `up 16 fl 4618` and `UP16FL4618` are the same
value. It must match `^[A-Z]{2}\d{1,2}[A-Z]{0,3}\d{1,4}$` once normalised —
BH-series and older formats both pass.

Suggested Dart:

```dart
final mobile  = RegExp(r'^[6-9]\d{9}$');
final plate   = RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{0,3}\d{1,4}$');
String norm(String v) => v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
```

---

## 5. Language

The web page must be **Hindi and English together**, not one or the other behind
a toggle — the person is standing next to their car and will not go looking for a
language switch. Show both on the same screen:

> **क्या यह वाहन आपका है?**
> Is this vehicle yours?

Same for the terms link, the buttons and the OTP prompt. The API returns English
messages; do not surface them raw — map status codes to your own bilingual
strings.

---

## 6. Endpoint summary

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/vehicle-qr/{code}` | optional | resolve a scan |
| `GET` | `/vehicle-qr/terms` | none | registration terms, EN + HI, versioned |
| `POST` | `/vehicle-qr/{code}/report` | none | parking issue or SOS |
| `POST` | `/vehicle-qr/{code}/otp` | none | send OTP (web claim) |
| `POST` | `/vehicle-qr/{code}/claim` | none | verify OTP + register |
| `POST` | `/vehicle-qr/{code}/assign` | **bearer** | register from the app (needs `confirmedOwnership`) |
| `POST` | `/vehicle-qr/batch` | **admin/franchise** | mint codes — see the admin guide |
| `GET` | `/vehicle-qr/batches` | **admin/franchise** | print runs — see the admin guide |

---

## 7. Things that will trip you up

- **Do not call anything when the user answers "No".** No scan follow-up, no
  analytics ping. That is a deliberate privacy rule, not an oversight.
- **Do not trust `owner.mobileMasked` as a dialable number.** It never is. Only
  `/report` with `type: "sos"` returns a real one, and only when unmasked.
- **`GET /vehicle-qr/{code}` counts a scan every time you call it.** Call it once
  per landing, not on every rebuild or retry.
- **`contact.available: false` is not an error.** The alert was recorded; there
  is simply no number to show. Render the confirmation, not a failure state.
- **`owner.mobileMasked` can be `null`** when the owner has no emergency
  profile. Handle it — do not print "null" on the page.
- **The ownership question is not skippable**, even for a signed-in user. It is
  the answer that `confirmedOwnership: true` records.
