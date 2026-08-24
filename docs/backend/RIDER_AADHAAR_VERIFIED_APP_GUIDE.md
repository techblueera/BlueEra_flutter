# Rider app — Aadhaar verified vs Aadhaar entered

**Service:** `be_rider_service` · **Endpoint:** `GET /rider-service/riders/onboarding/status`
**Status:** two new fields, fully additive. Nothing you send changes.

---

## 0. The bug, in one line

The app renders a **verified** tick from `aadhar`, but `aadhar` means **"an Aadhaar has been provided"**, not "it is verified".

**1,591 riders are currently told their Aadhaar is verified when it is still pending.**

Every one of those 1,591 typed an Aadhaar number and never uploaded the card images, so the backend cannot verify them — and it never will until they finish. The app shows them a green tick, they believe they are done, and then they cannot understand why they still can't go live.

Concrete example — rider `9582415952`:

```
aadharNo         = 630521013693     ← number typed
isAadharVerified = pending          ← NOT verified
aadharImages     = front ✗  back ✗  ← never uploaded
OKYC record      = none
```

The app shows this rider as verified. The admin panel shows him as pending. **The admin panel is right.**

---

## 1. What to change

```diff
- verified: status.aadhar            // "provided", not "verified"
+ verified: status.aadharVerified    // NEW — the real state
```

Two new fields on the status response:

| field | type | meaning |
|---|---|---|
| `aadharVerified` | `boolean` | Aadhaar is actually verified. **This is what a tick reads.** |
| `aadharStatus` | `"pending" \| "verified" \| "rejected"` | the raw per-document state |

`aadhar` keeps its existing meaning and value — use it only for *"have we got an Aadhaar on file at all"*.

---

## 2. Show three states, not two

Collapsing "entered" and "verified" into one tick is what caused this. There are three real states:

| condition | show |
|---|---|
| `aadhar === false` | **Not entered** — prompt to add Aadhaar |
| `aadhar && !aadharVerified` | **Pending** — "we have your Aadhaar, verification in progress". If `aadharStatus === "rejected"`, show rejected + the re-upload action instead. |
| `aadharVerified === true` | **Verified** ✅ — show `aadharMasked`, and `aadharVerifiedThrough` for how |

The pending state is the one missing today, and it is the state 1,591 riders are actually in.

### Tell them what is missing

A rider stuck in pending usually just hasn't uploaded both card images. Say that. The document route needs **the number plus BOTH front and back**; a one-sided or number-only submission stays pending forever.

---

## 3. Sample payloads

Pending — number typed, images missing:

```json
{
  "aadhar": true,
  "aadharVerified": false,
  "aadharStatus": "pending",
  "aadharVerifiedThrough": null,
  "aadharMasked": "XXXX XXXX 3693"
}
```

Verified through OTP — no number stored here at all:

```json
{
  "aadhar": true,
  "aadharVerified": true,
  "aadharStatus": "verified",
  "aadharVerifiedThrough": "otp",
  "aadharNo": null,
  "aadharMasked": "XXXX XXXX 2211"
}
```

Note `aadharNo` is `null` on the OTP route and always will be — be_user_service stores a SHA-256 hash plus the last 4 digits and never the raw Aadhaar. **Never gate anything on `aadharNo`.** `aadharMasked` is what you display.

---

## 4. Aadhaar verified ≠ onboarding complete

Three independent states. Don't render one as another:

| field | means | true for |
|---|---|---|
| `aadharVerified` | Aadhaar verified | 7,272 riders |
| `verificationStatus: "approved"` | Aadhaar **+ RC + DL** all verified | 4,132 riders |
| `isOnboardingComplete` | all 6 sections **+ security deposit paid** | see below |

A rider can be Aadhaar-verified and still legitimately mid-onboarding because they haven't added vehicle images. When you show "onboarding pending", show **which section** is missing — never let it read as "your KYC failed".

### The address section was broken and is now fixed

`address` is gated on a pincode that the app writes to be_user_service and never to this service, so it failed for **12,245 of 12,247 riders** — meaning `isOnboardingComplete` could not become true for **anyone**, whatever they uploaded.

Fixed in two places: the pincode is now backfilled from the user record on every onboarding call, and a one-off sweep has already filled it for **11,950 riders**. Current state:

```
address.pincode missing   12,245  →  297
riders passing all 6 sections   1  →  2,946
```

Of those 2,946, **206 have a paid security deposit** and will flip to `isOnboardingComplete: true` on their next status poll. The rest are genuinely waiting on the deposit, which is correct behaviour — not a bug to work around.

The remaining 297 have no pincode anywhere in the platform; they must enter an address before they can complete.

---

## 5. Rollout

`aadharVerified` and `aadharStatus` ship with the next be_rider_service deploy. Both are additive — no existing field changes value or disappears.

Until the backend is deployed you can get the same answer from a field that already exists:

```
verified = status.aadharVerifiedThrough != null
```

`aadharVerifiedThrough` is `"otp"` / `"manual"` only when verified, and `null` otherwise. Switching to that today fixes the 1,591 immediately; move to `aadharVerified` once deployed.
