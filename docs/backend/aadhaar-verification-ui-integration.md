# Aadhaar Verification (OKYC OTP) — UI Integration Guide

Generic per-user Aadhaar identity verification (KYC), owned by
**be_user_service**. Any logged-in user can verify their identity via an OTP
sent to their Aadhaar-linked mobile number (UIDAI OKYC, via Sandbox.co.in).

The verified result is stored against the user account — it is not tied to
business verification or any other flow. Screens that need a "KYC done" gate
can read the status endpoint.

**Flow:** screen load → `GET /user/aadhaar/status` (skip if already verified)
→ user enters 12-digit Aadhaar + ticks consent → `POST
/user/aadhaar/generate-otp` → user enters the 6-digit OTP received on their
Aadhaar-linked mobile → `POST /user/aadhaar/verify-otp` → show verified
identity.

All endpoints require `Authorization: Bearer <token>` (logged-in user).

---

## 1. Check current status

### `GET /user/aadhaar/status`

Call on screen load to decide whether to show the verification flow at all.

**Response — `200`:**

```json
{
  "success": true,
  "data": {
    "is_verified": true,
    "attempt_status": "VERIFIED",
    "aadhaar_last4": "9012",
    "name": "Ravi Kumar",
    "verified_at": "2026-07-03T10:12:45.000Z"
  }
}
```

- `is_verified: false` + `attempt_status: null` — user never started; show the
  Aadhaar entry screen.
- `is_verified: false` + `attempt_status: "OTP_SENT"` — an OTP flow was started
  but not completed. Treat as not verified; start fresh (a new generate-otp is
  always safe).
- `is_verified: true` — show the verified state (`name`, masked number
  `XXXX XXXX 9012`, `verified_at`). Re-verification is allowed but optional.

---

## 2. Send the OTP

### `POST /user/aadhaar/generate-otp`

```json
{
  "aadhaar_number": "123456789012",
  "consent": "Y",
  "reason": "For KYC"
}
```

- `aadhaar_number` — exactly 12 digits, numbers only. Strip spaces before
  sending.
- `consent` — must be `"Y"`. **Bind this to an explicit checkbox** the user
  ticks, with copy like: *"I voluntarily share my Aadhaar number and consent to
  its use for identity verification."* Do not pre-tick it.
- `reason` — optional, defaults to `"For KYC"`.

**Success — `200`:**

```json
{
  "success": true,
  "message": "OTP sent to the Aadhaar-linked mobile number",
  "data": { "reference_id": "1234567" },
  "_meta": {
    "provider": "sandbox",
    "providerMode": "prod",
    "transactionId": "7d75d9db-0870-4719-8884-a3eee7bd68d5"
  }
}
```

Keep `reference_id` in screen state — it must be sent back with the OTP.

**Business failures — `200` with `success: false`:** show `message` inline.

| `message` | Meaning / UI handling |
|---|---|
| `Invalid Aadhaar Card` | Number is well-formed but not a valid Aadhaar. Let the user re-enter. |
| `Please retry after 30 seconds` | UIDAI throttles OTP re-requests. Disable the resend button for 30–60 s. |

**Other statuses:**

| HTTP | Meaning | UI handling |
|---|---|---|
| `400` | Bad format (not 12 digits) or consent not given | Inline field error |
| `401` | Not logged in / token expired | Re-auth |
| `429` | Rate limited (max 5 OTP requests per 15 min per user) | Show "too many attempts, try later" |
| `502` / `503` | Verification provider down / not configured | Show "service temporarily unavailable, try later" |

---

## 3. Verify the OTP

### `POST /user/aadhaar/verify-otp`

```json
{
  "reference_id": "1234567",
  "otp": "123456"
}
```

- `otp` — the 6-digit code delivered to the Aadhaar-linked mobile. Note: the
  app cannot auto-read it reliably; the number may differ from the user's login
  mobile.
- `reference_id` — from step 2. Must belong to the logged-in user's latest
  OTP request.

**Success — `200`:**

```json
{
  "success": true,
  "is_verified": true,
  "message": "Aadhaar verified successfully",
  "data": {
    "name": "Ravi Kumar",
    "gender": "M",
    "date_of_birth": "01-01-1990",
    "care_of": "S/O Suresh Kumar",
    "full_address": "12, MG Road, Indiranagar, Bengaluru, Karnataka - 560038",
    "address": {
      "country": "India",
      "state": "Karnataka",
      "district": "Bengaluru",
      "subdistrict": "Bengaluru North",
      "post_office": "Indiranagar",
      "house": "12",
      "street": "MG Road",
      "vtc": "Bengaluru",
      "landmark": "",
      "pincode": "560038"
    },
    "aadhaar_last4": "9012"
  },
  "_meta": {
    "provider": "sandbox",
    "providerMode": "prod",
    "transactionId": "..."
  }
}
```

Show a success state with the verified `name` and masked number. The backend
stores only the last 4 digits and the verified identity fields — never the
full Aadhaar number or photo.

**Business failures — `200` with `success: false, is_verified: false`:**

| `message` | Meaning / UI handling |
|---|---|
| `Invalid OTP` | Wrong code. Let the user retype; keep the same `reference_id`. |
| `OTP expired` | Code timed out (~10 min). Offer "Resend OTP" → new generate-otp → new `reference_id`. |
| `Please retry after 30 seconds` | Provider busy. Retry the same call after 30 s. |
| `No pending OTP request found` | `reference_id` is stale/unknown (e.g. app restarted). Restart from step 2. |

**Other statuses:** same as step 2 (`400` missing fields, `401` auth, `429`
rate limit — max 10 verify attempts per 15 min, `502`/`503` provider down).

---

## UX notes

- **Consent is mandatory.** The API rejects the request without `consent: "Y"`;
  the checkbox cannot be skipped or pre-ticked (compliance requirement).
- **Resend button:** disable for 30–60 s after every generate-otp (UIDAI
  enforces a 30 s gap server-side and the app should not surface that error).
- **Rate limits are per user:** 5 OTP sends + 10 verify attempts per 15 min.
  After a `429`, show a cooldown message rather than retrying silently.
- **Re-verification:** calling generate-otp again is always safe — a previously
  verified result is kept until a new attempt fully succeeds, then replaced.
- **Masking:** never display or cache the full Aadhaar number after submission;
  use `XXXX XXXX <last4>` from the status/verify responses.
- **Test mode:** against the staging backend (`providerMode: "test"` in
  `_meta`), Sandbox's test environment accepts its published dummy Aadhaar
  numbers/OTPs — real numbers won't receive SMS there.
