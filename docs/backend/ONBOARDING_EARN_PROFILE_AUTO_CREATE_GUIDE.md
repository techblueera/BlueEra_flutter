# Onboarding Earn-Profile Auto-Create — Frontend Migration Guide

## What changed on the backend

`POST user-service/user/updateIndividualAccountUser/:id` now creates the earn
profile **itself**, server-side (via gRPC to earn-service), before promoting
the GUEST to INDIVIDUAL. The branch logic is identical to what the app did:

| Condition (same as app) | Profile created server-side |
|---|---|
| `profileType == PROFESSIONAL` | professionalProfile (categories synced from request) |
| `profileType == SELF_EMPLOYED` | minimal selfWork Service (`category = profession.toUpperCase()`) |
| else if `profession == ARTIST` or `CONTENT_CREATOR` | minimal EarnArtist (`type = profession`, `category = designation`) |
| anything else (STUDENT, …) | nothing |

**Failure semantics:** if earn-profile creation fails, the API returns
`502 { "status": false, "message": "Could not create your earn profile. Please try again in a moment." }`
and NOTHING is written — account stays GUEST, no token. The user can simply
retry. On retry the earn side is idempotent (an already-created profile is
reused, never duplicated).

**Response shape on success: unchanged.** Same `{ status, message, token, user }`.

## Required app change (one file)

`lib/features/common/auth/controller/auth_controller.dart` → `addIndividualUser()`:

DELETE the three earn-profile branches from the `pending` list — the
`if (reqData?['profileType'] == PROFESSIONAL) … else if (… == SELF_EMPLOYED) …
else if (… CONTENT_CREATOR || ARTIST) …` block that adds
`createServiceController` / `createMinimalEarnService` /
`createMinimalArtistProfile` to `pending`.

KEEP:

- `personalController.viewPersonalProfile(forceRefresh: true)` in `pending`
  (Add Bio screen still needs it).
- The error path: `!response.isSuccess` → snackbar with `response.message`.
  The new 502 message flows through this automatically — no new handling needed.
- ALL standalone create methods (`createMinimalProfessionalProfile`,
  `createMinimalEarnService`, `createMinimalArtistProfile`,
  `ensureArtistProfile`) — the Overview "Create profile" CTAs for
  pre-existing users still rely on them, and they remain valid fallbacks
  (earn REST endpoints are untouched).

After deletion the block reduces to:

```dart
final personalController = Get.put(ViewPersonalDetailsController(), permanent: true);
final pending = <Future<void>>[
  personalController.viewPersonalProfile(forceRefresh: true),
];
await Future.wait(pending);
```

Optional cleanup: `SelfWorkServiceController`'s
`controller.professionCategory = reqData?['profession'];` assignment in this
flow can go too — nothing in the trimmed flow reads it.

## Backward compatibility (already handled — nothing to do)

- **Old app + new backend:** the app's legacy second REST call still fires.
  Professional: upsert — harmless no-op. Artist: 409 — app already treats as
  success. SelfWork: 409 — app shows a harmless "already have a service"
  snackbar once during onboarding (cosmetic, rollout window only).
- **New app + old backend** (earn-service deployed late): user-service detects
  the missing RPC (UNIMPLEMENTED) and skips instead of failing — but then no
  earn profile exists until the user taps the Overview "Create profile" CTA.
  Deploy order **earn-service → user-service → app release** avoids this window.

## Verify after app change

1. Fresh guest → onboard as SELF_EMPLOYED (e.g. Electrician) → single API call
   → Service tab shows section cards (service exists) without the app ever
   calling `POST earn-service/services`.
2. Onboard as CONTENT_CREATOR → earn-artist Overview loads the profile.
3. Onboard as PROFESSIONAL → professional profile exists with
   professionCategory/designationCategory set.
4. Kill earn-service, attempt onboarding → snackbar with "Could not create
   your earn profile…", account still GUEST, retry after restart succeeds.
