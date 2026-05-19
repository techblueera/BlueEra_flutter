# BDM Registration — Document Field Cleanup (Frontend Integration Guide)

> Companion to the Swagger spec served at `/api-docs` (raw JSON: `/swagger.json`).
> Audience: frontend / mobile engineers integrating the BDM onboarding flow.
> Scope: **Step 2 of BDM registration only.** Step 1 is unchanged.

---

## Table of Contents

1. [TL;DR — What Changed](#1-tldr--what-changed)
2. [Why](#2-why)
3. [Backward Compatibility Contract](#3-backward-compatibility-contract)
4. [The New Request Shape](#4-the-new-request-shape)
5. [The Response Shape](#5-the-response-shape)
6. [Frontend Migration Checklist](#6-frontend-migration-checklist)
7. [UI Changes](#7-ui-changes)
8. [Edge Cases & Gotchas](#8-edge-cases--gotchas)
9. [Quick cURL Smoke Tests](#9-quick-curl-smoke-tests)
10. [Reference — Affected Server Files](#10-reference--affected-server-files)

---

## 1. TL;DR — What Changed

We are **no longer collecting Aadhar card, PAN card, or address-proof
documents** during BDM registration. Only **bank details** remain.

| Field                       | Before                | After     |
| --------------------------- | --------------------- | --------- |
| `documents.aadharCard`      | Accepted & persisted  | **Removed** (silently ignored if sent) |
| `documents.panCard`         | Accepted & persisted  | **Removed** (silently ignored if sent) |
| `documents.addressProof`    | Accepted & persisted  | **Removed** (silently ignored if sent) |
| `documents.bankDetails`     | Accepted & persisted  | **Unchanged** — still required for payout |

No other Step 2 behaviour changes — `referralCode` handling, the
`COMPLETED` status transition, and wallet linking all work exactly as
before.

---

## 2. Why

KYC for Aadhar / PAN / address-proof is being moved out of BDM
onboarding. The shorter form raises conversion and removes a dependency
on the document upload pipeline at sign-up time. Bank details stay
because they are the rails for BDM payouts.

---

## 3. Backward Compatibility Contract

The API is **fully backward compatible**. Old clients keep working with
no code changes — they will just stop having their Aadhar/PAN/address
docs persisted.

**Concretely, the backend now:**

- Accepts `documents.aadharCard`, `documents.panCard`,
  `documents.addressProof` **without erroring** — they are silently
  dropped before persistence.
- Persists `documents.bankDetails` exactly as before.
- Never returns the removed keys in responses (the schema no longer
  defines them, so Mongoose strips them on read).
- Leaves any already-stored legacy values in MongoDB untouched. We are
  not running a migration / cleanup — the data is simply no longer
  surfaced through the API.

**What this means for you:**

| Client version                             | Will it keep working? |
| ------------------------------------------ | --------------------- |
| Old build that sends all 4 doc fields      | ✅ Yes — 3 are ignored |
| Old build that sends bankDetails only      | ✅ Yes                |
| New build that sends only bankDetails      | ✅ Yes (recommended)  |
| Old build that doesn't send `documents`    | ✅ Yes (must send `referralCode`) |

You can therefore ship the frontend changes on your own timeline. No
backend cutover is required.

---

## 4. The New Request Shape

### Endpoint

```
POST /bdm/register/step2
Authorization: Bearer <jwt>
Content-Type: application/json
```

### Body — recommended (post-migration)

```json
{
  "documents": {
    "bankDetails": "<bankDetailsObjectId>"
  },
  "referralCode": "BDMUSER42"
}
```

Both top-level keys are optional **individually**, but **at least one
must be present** — sending an empty body still returns
`400 Bad Request` with:

```json
{
  "success": false,
  "message": "Please provide either documents or a referral code to update."
}
```

### Body — legacy (still accepted, do not build new code against this)

```json
{
  "documents": {
    "aadharCard": "<id>",
    "panCard": "<id>",
    "addressProof": "<id>",
    "bankDetails": "<id>"
  },
  "referralCode": "BDMUSER42"
}
```

The three removed fields are silently dropped. **Do not ship new code
that depends on them being stored.**

### Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `documents.bankDetails` | `string` (ObjectId of an uploaded document in the document service) | Optional — but needed for payouts | Persisted as-is |
| `referralCode` | `string` | Optional | Can be set **exactly once** per wallet. Subsequent calls with a different code return `400`. Use `GET /bdm/referral-suggestions` to pre-fill. |

---

## 5. The Response Shape

```json
{
  "success": true,
  "message": "BDM Registration completed successfully",
  "data": {
    "_id": "...",
    "userId": "...",
    "walletId": "...",
    "serialCode": "A100123",
    "fullName": "Jane Doe",
    "email": "jane@example.com",
    "dob": { "day": 1, "month": 1, "year": 1995 },
    "alternateMobileNo": "9999999999",
    "education": "GRADUATE",
    "location": {
      "pincode": "560001",
      "state": "Karnataka",
      "city": "Bengaluru",
      "addressString": "..."
    },
    "documents": {
      "bankDetails": "<bankDetailsObjectId>"
    },
    "status": "COMPLETED",
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

Note: `documents` now only contains `bankDetails`. Even for BDMs whose
legacy Aadhar/PAN/address values are still in the database, the API
will **not** return them.

---

## 6. Frontend Migration Checklist

In your BDM onboarding feature:

- [ ] **Remove the upload UI** for Aadhar, PAN, and address proof from
      the Step 2 screen.
- [ ] **Keep** the bank-details capture (whatever you call it —
      "Add bank account", "Where should we pay you?", etc.).
- [ ] **Stop sending** `documents.aadharCard`, `documents.panCard`,
      `documents.addressProof` in the Step 2 request body.
- [ ] **Remove any form validation** that required those three
      documents to be uploaded before continuing.
- [ ] **Update copy** on review/confirmation screens — remove "Aadhar
      uploaded ✓", "PAN uploaded ✓", "Address proof uploaded ✓" rows.
- [ ] **Update progress bars / step labels** if they mentioned
      document uploads (e.g. change "Documents (4)" → "Bank details").
- [ ] **Profile screen / "View my BDM details"** — stop reading the
      removed keys from the response (they will be `undefined`).
- [ ] **Re-test status flow** — `GET /bdm/status` still returns
      `NOT_STARTED → PENDING → COMPLETED`. No change.
- [ ] **Re-test referral suggestion flow** — `GET /bdm/referral-suggestions`
      unchanged.

If your codebase has shared types / models for `BDMProfile`, narrow the
`documents` type to:

```ts
type BDMDocuments = {
  bankDetails?: string;
};
```

and remove `aadharCard`, `panCard`, `addressProof` from that type.

---

## 7. UI Changes

### Before (Step 2 — 4 uploads + referral)

```
┌────────────────────────────────────┐
│  Become a BDM — Step 2 of 2        │
│                                    │
│  📎 Upload Aadhar Card             │
│  📎 Upload PAN Card                │
│  📎 Upload Address Proof           │
│  📎 Upload Bank Details            │
│                                    │
│  Choose your referral code:        │
│  ┌──────────────────────────────┐  │
│  │ BDMUSER42                    │  │
│  └──────────────────────────────┘  │
│  Suggestions: USER123, JANE7X, …   │
│                                    │
│           [ Complete ]             │
└────────────────────────────────────┘
```

### After (Step 2 — bank details + referral)

```
┌────────────────────────────────────┐
│  Become a BDM — Step 2 of 2        │
│                                    │
│  📎 Add bank account               │
│     (account number, IFSC, holder) │
│                                    │
│  Choose your referral code:        │
│  ┌──────────────────────────────┐  │
│  │ BDMUSER42                    │  │
│  └──────────────────────────────┘  │
│  Suggestions: USER123, JANE7X, …   │
│                                    │
│           [ Complete ]             │
└────────────────────────────────────┘
```

The flow stays a two-step wizard — we are not collapsing it down to a
single step, because Step 1 still owns the personal-info block
(name, email, DOB, education, location) and we want clear separation
for analytics + dropoff measurement.

---

## 8. Edge Cases & Gotchas

1. **Empty body still 400s.** If you remove documents entirely and the
   user also hasn't picked a referral code yet, don't fire the request.
   Either let them stay on the screen or pre-fetch a suggestion.

2. **Referral code is set-once.** The wallet has
   `referralCodeUpdateCount`. After the first successful set, sending a
   different `referralCode` returns
   `400 "Referral code can only be set once."` Sending the *same* code
   again is a no-op (also 200). This is unchanged.

3. **Status flips to `COMPLETED` on Step 2 success** even if the body
   only contained `bankDetails` (no referral code), or only a referral
   code (no bank details). This is the existing behaviour — Step 2 is
   the "finish line", not a validation gate.

4. **Existing users with legacy doc IDs in the DB.** Their stored
   `aadharCard` / `panCard` / `addressProof` values are not deleted, but
   they are no longer returned. If product later wants to surface them
   on an admin screen, we'll add a separate admin-only endpoint.

5. **No upload-service migration needed.** Bank details still flow
   through whatever upload pipeline you currently use. Step 2 just
   stores the resulting ObjectId.

6. **TypeScript / Flow type drift.** If you have generated types from
   the Swagger spec (e.g. via `openapi-typescript`), regenerate them
   after pulling — the `documents` shape has changed.

---

## 9. Quick cURL Smoke Tests

Replace `$TOKEN` with a valid bearer token whose user has completed
Step 1.

### 9.1 New-style request (bank details + referral)

```bash
curl -X POST "$HOST/bdm/register/step2" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "documents": { "bankDetails": "65f0a1b2c3d4e5f6a7b8c9d0" },
    "referralCode": "BDMUSER42"
  }'
```

### 9.2 Legacy request (should still 200, extras ignored)

```bash
curl -X POST "$HOST/bdm/register/step2" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "documents": {
      "aadharCard":   "65f0a1b2c3d4e5f6a7b8c9d1",
      "panCard":      "65f0a1b2c3d4e5f6a7b8c9d2",
      "addressProof": "65f0a1b2c3d4e5f6a7b8c9d3",
      "bankDetails":  "65f0a1b2c3d4e5f6a7b8c9d0"
    },
    "referralCode": "BDMUSER42"
  }'
```

Confirm in the response body that `data.documents` contains **only**
`bankDetails`.

### 9.3 Referral-only request (no documents at all)

```bash
curl -X POST "$HOST/bdm/register/step2" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "referralCode": "BDMUSER42" }'
```

### 9.4 Empty body — expected 400

```bash
curl -X POST "$HOST/bdm/register/step2" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 10. Reference — Affected Server Files

For the curious / for cross-referencing in PR reviews:

| File | Change |
|---|---|
| `src/models/BDMProfile.js` | `documents` sub-schema reduced to `{ bankDetails }` |
| `src/controllers/bdm.controller.js` | `registerStep2` no longer 400s on unknown doc keys; silently picks `bankDetails` |
| `src/routes/bdm.routes.js` | Swagger body schema for `POST /bdm/register/step2` trimmed; description updated |
| `src/config/swagger.js` | `BDMProfile` component `documents` trimmed |

Nothing else in the wallet service touches `bdmProfile.documents`, so
no further server-side fan-out is needed.

---

**Questions or surprises?** Ping #wallet-service on Slack with a link
to your PR and the exact request/response you're seeing.
