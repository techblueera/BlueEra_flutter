# Finance profiles — GST & Branch UI Integration Guide

Creating a **finance** business profile now requires a **GST number** and a
**branch**, and the GST number is verified against the government GST provider
before the profile is saved. Every other profile type (`other`, `support`) is
unchanged — no new required fields there.

**Flow:** user picks the finance category → fills the profile form incl. GSTIN +
branch → app POSTs to other-service → other-service verifies the GSTIN through
be_user_service → profile is created, or the app gets a field-level validation
error to show on the form.

> ⚠️ **Two rules that surprise people.** The GSTIN is **not** unique on its own —
> it is the **(GST number + branch) pair** that must be unique, so one bank can
> list many branches (§4). And `gst.verified: false` in a success response is
> **not** a rejection (§5).

Base URL: `https://be.beapp.in/api/other-service/`

---

## 0. ⚠️ Breaking change — read before you ship

**A finance profile can no longer be created without `gstNumber` and `branch`.**
Any app build that posts a finance profile without them now gets a `400` and the
profile is not created. Existing builds in the field will start failing the
moment the backend deploys, so the app release needs to go out with it.

Nothing else is affected — `other` / `support` profiles are unchanged, and every
read endpoint keeps working exactly as before.

### Must change (otherwise finance creation breaks)

| # | Change | Where |
|---|---|---|
| 1 | Add **GST number** and **branch** inputs, send them as `gstNumber` + `branch` | §1, §2 |
| 2 | Handle the new `400`s — field errors and provider rejection | §3 |
| 3 | Handle `409` duplicate GST+branch, and tell it apart from the *other* `409` | §4 |

### Should change (quality, not breakage)

| # | Change | Where |
|---|---|---|
| 4 | Stop asking for the company name — it is replaced by the registered name | §2 |
| 5 | Re-read `profileName` from the response; it will differ from what you sent | §2 |
| 6 | Validate the GSTIN format client-side before submitting | §1 |
| 7 | Don't treat `gst.verified: false` as an error | §5 |

### Rollout order

`be_user_service` ships the GST verification first, then `be_other_service`, then
the app. If the app goes out early, finance creation fails on the missing fields.
If verification is not reachable yet, profiles are still created — just with
`gst.verified: false` and the typed name kept (§5).

---

## 1. The two new fields

| Field | Sent as | Required when | Rules |
|---|---|---|---|
| GST number | `gstNumber` (flat, top level) | `type == "finance"` | 15-char statutory GSTIN |
| Branch | `branch` (flat, top level) | `type == "finance"` | non-empty, max 120 chars |

**GSTIN format:** `2 digits + 5 letters + 4 digits + 1 letter + 1 alphanumeric +
"Z" + 1 alphanumeric` — e.g. `27AAPFU0939F1ZV`.

Regex, if you want to validate before sending (recommended — saves a round trip):

```dart
final gstinPattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
```

You do **not** need to uppercase or trim — the server does both before it
validates, stores and compares. `" 27aapfu0939f1zv "` is accepted and stored as
`27AAPFU0939F1ZV`.

---

## 2. Create a finance profile

### `POST /business-profile`

```json
{
  "profileName": "HDFC Bank",
  "type": "finance",
  "gstNumber": "27AAPFU0939F1ZV",
  "branch": "Andheri West",
  "description": "…",
  "financeDetails": { "minBalance": 5000, "savingRatePA": 3.0 }
}
```

### Success — `201`

Note the **asymmetry**: you *send* `gstNumber` flat, you *read it back* nested
under `gst`, together with the verification result.

```json
{
  "success": true,
  "message": "Business profile created successfully.",
  "data": {
    "_id": "6a7…",
    "type": "finance",
    "branch": "Andheri West",
    "gst": {
      "number": "27AAPFU0939F1ZV",
      "verified": true,
      "legalName": "UNITED BREWERIES LIMITED",
      "tradeName": "UB LIMITED",
      "verifiedAt": "2026-08-18T09:12:44.031Z"
    }
  }
}
```

### ⚠️ The profile name is set from the GST record, not from your form

When the GSTIN verifies, the server **overwrites** `profileName` /
`business_name` with the registered name - `tradeName` if present, otherwise
`legalName`. Whatever the user typed is discarded.

This is deliberate: owners were typing their own account name, which is how the
directory filled up with listings called `Nothing`, `good` and `delivery boy`.

**What this means for the form:**

- Don't ask the user to type a company name on the finance form - show the
  verified name back to them instead ("Registered as: ...").
- `profileName` is still required by the API. Send anything (the branch, a
  placeholder); it is only kept as a fallback if the GST provider was
  unreachable and no registered name could be fetched.
- Expect the `data.profileName` you get back to differ from what you sent.

---

## 3. Validation errors — `400`

Same envelope as the rest of this service: a `message` plus an `errors` array you
can map straight onto form fields.

```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": [
    { "field": "gstNumber", "message": "GST number is required for a finance profile" },
    { "field": "branch",    "message": "Branch is required for a finance profile" }
  ]
}
```

| Situation | `field` | `message` |
|---|---|---|
| GST missing | `gstNumber` | `GST number is required for a finance profile` |
| Branch missing | `branch` | `Branch is required for a finance profile` |
| Malformed GSTIN | `gstNumber` | `GST number must be a valid 15-character GSTIN (e.g. 27AAPFU0939F1ZV)` |
| Branch too long | `branch` | `Branch cannot exceed 120 characters` |

### GSTIN rejected by the provider

Also `400`, but `message` is the human-readable reason (there is no
`"Validation failed."` wrapper):

```json
{
  "success": false,
  "message": "No GST records found for this GST number",
  "errors": [{ "field": "gstNumber", "message": "No GST records found for this GST number" }]
}
```

Two possible messages:

- `Invalid GST number` — the provider does not recognise it.
- `No GST records found for this GST number` — well-formed, but not registered.

Both mean: keep the user on the form, focus the GST field.

---

## 4. Duplicate GST + branch — `409`

The **pair** must be unique. The same GSTIN with a *different* branch is fine —
that is the normal case for a bank or NBFC, which has one GSTIN per state
covering many branches.

```json
{
  "success": false,
  "message": "A profile already exists for GST number 27AAPFU0939F1ZV with branch \"Andheri West\". Use a different branch for this GST number.",
  "errors": [
    { "field": "gstNumber", "message": "This GST number and branch combination is already registered" },
    { "field": "branch",    "message": "This branch is already registered under this GST number" }
  ]
}
```

`message` is already user-presentable - show it as-is and let the user change
the branch.

**Branch matching ignores case and extra spaces.** `"Andheri West"`,
`"andheri west"` and `"Andheri  West"` are the **same branch** - the second is
rejected as a duplicate. The casing the user typed is still what gets stored and
displayed; only the comparison is normalised.

> There is a second, unrelated `409` on this endpoint:
> `"Business profile already exists. Use PUT to update."` — that one means *this
> user* already has a profile of this type, and the app should switch to the edit
> flow. Distinguish the two by `message` / presence of `errors`.

---

## 5. `gst.verified` — what false actually means

`verified: false` on a **successful** create does **not** mean the GSTIN was
rejected. A rejected GSTIN never gets saved at all — it comes back as the `400`
in §3.

`false` means *we could not check right now* — the GST provider or user-service
was unreachable. The profile is deliberately still created, because blocking a
legitimate signup on our own downtime is the worse outcome.

**UI guidance:**

| `gst.verified` | Show |
|---|---|
| `true` | ✅ verified badge, optionally `legalName` |
| `false` | nothing, or a neutral "verification pending" — **never** an error or "invalid GST" |

Do not block the user, retry automatically, or re-submit the form on `false`.

---

## 6. Editing — `PUT /business-profile`

PUT is a **partial** update. You only send what changed.

- Editing anything else on a finance profile (description, timings, …) does
  **not** require resending `gstNumber` or `branch`.
- Sending `branch` alone renames the branch. It is re-checked for a duplicate,
  but the GSTIN is **not** re-verified and `gst.verified` is left as it is.
- Sending a **different** `gstNumber` re-verifies it and can return the same
  `400` / `409` responses as create.
- Format validation still applies whenever a value *is* sent.

---

## 7. Checklist for the finance form

- [ ] GSTIN field: uppercase-as-you-type is nice, but not required
- [ ] Client-side regex check before submit (§1)
- [ ] Branch field: required, max 120 chars
- [ ] Map `errors[].field` → form fields (`gstNumber`, `branch`)
- [ ] Handle `409` duplicate by showing `message` and focusing branch
- [ ] Treat the two `409` variants differently (§4)
- [ ] Show the verified name back as confirmation — don't ask them to type it
- [ ] Re-read `profileName` from the response; it is server-set (§2)
- [ ] Do **not** treat `gst.verified: false` as an error (§5)

---

## 8. Not affected

- `type: "other"` / `"support"` profiles — no new required fields.
- Existing finance profiles created before this change — they have no GST or
  branch stored, and reading them is unchanged. The rules apply only when a
  profile is created or when GST/branch is edited.
