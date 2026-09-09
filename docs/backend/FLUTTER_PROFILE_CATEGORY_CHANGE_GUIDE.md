# Flutter Integration Guide — Change Profile Category

**Audience**: Flutter mobile team (BlueEra_flutter)
**Service**: `be_user_service`
**Base URL**: `https://be.beapp.in/api/user-service`
**Admin counterpart**: `docs/ADMIN_PROFILE_CATEGORY_CHANGE_GUIDE.md`
**Backend reference**: `docs/PROFILE_CATEGORY_CHANGE_INTEGRATION_GUIDE.md`

---

## 1. What the app is getting

A user picks their category during onboarding — *Bike Rider*, *Bicycle Rider*, *Grocery
Store*, *Food & Restaurant* — and sometimes picks the wrong one. Until now the only fix
was for someone on the backend team to delete the account from the database so the person
could sign up again on the same phone number.

The app can now let them **change it themselves, once per account.**

After that one change the button stays visible but disabled, and they're told to contact
support. (Support can hand the change back — that's the admin panel's job, not yours.)

## 2. Scope — what can change into what

The change stays **inside** the account type. There is no path from INDIVIDUAL to
BUSINESS or back — that's a different feature and it is not part of this one.

| `account_type` | User picks from | Example |
|---|---|---|
| `INDIVIDUAL` | the professions list | Bike Rider → Bicycle Rider → Plumber |
| `BUSINESS` | the business categories list | Grocery Store → Food & Restaurant |
| `GUEST`, `BLUEFLY` | — | feature hidden entirely |

You do **not** need to branch your networking code on account type. It's one endpoint;
the backend works out which field to change. You only branch on **which catalog you show
in the picker** — and the API tells you which one (§4).

> **Do not send `profileType`.** For individuals the backend derives it from the chosen
> profession's catalog entry. If you send it, it's ignored. This is deliberate — it's how
> "Bicycle Rider" is guaranteed never to end up filed under the wrong `profileType`.

---

## 3. Where to put it

Settings → Account → **Change category** (or wherever the profile edit entry points
already live — follow the existing Settings pattern, don't invent a layout).

Show a subtitle with the current category name, e.g. *"Grocery Store"*.

---

## 4. Step 1 — read the state

Call this when the Settings/Profile screen loads. It answers *"should I show this row at
all, and is the change still available?"*

```http
GET /user/me/profile-category
Authorization: Bearer <token>
```

**BUSINESS response**

```json
{
  "success": true,
  "data": {
    "account_type": "BUSINESS",
    "supported": true,
    "current": {
      "tag_id": "GROCERY_STORE",
      "name": "Grocery Store",
      "category_type": "Grocery",
      "sub_category_id": "6a088aeccc4c93f8e56649f0"
    },
    "changes_used": 0,
    "changes_remaining": 1,
    "can_change": true,
    "last_changed_at": null,
    "last_changed_by": null,
    "options_endpoint": "/business/getAllcategories"
  }
}
```

**INDIVIDUAL response** — same envelope, different `current` and `options_endpoint`:

```json
{
  "current": {
    "tag_id": "BIKE_RIDER",
    "name": "Bike Rider",
    "profile_type": "GigWork",
    "designation": "Delivery"
  },
  "options_endpoint": "/individual-professions"
}
```

### How to drive the UI from it

| Field | What to do |
|---|---|
| `supported == false` | **Hide the row entirely.** GUEST / BLUEFLY have no category. |
| `current.name` | Subtitle under the row |
| `can_change == true` | Row tappable |
| `can_change == false` | Row visible but **disabled**, with "You've already changed your category. Contact support to change it again." |
| `changes_remaining` | The "1 change left" hint, if you want to show it |
| `options_endpoint` | Which catalog to load in step 2 — use it instead of hardcoding an `account_type` check |

---

## 5. Step 2 — show the picker

**No new endpoint.** Use the same catalog calls you already make during onboarding:

| `options_endpoint` | Call | Take from each item |
|---|---|---|
| `/individual-professions` | `GET /individual-professions` | `tag_id`, `name`, `image_url` |
| `/business/getAllcategories` | `GET /business/getAllcategories` | `tag_id`, `name`, `subCategories[]` |

> ⚠️ **Filter the professions list yourself.** `GET /individual-professions` returns
> **every** row, including retired ones (`isActive: false`) and soft-deleted ones
> (`deletedAt != null`). The change endpoint rejects those with `422 unknown_category`, so
> drop them client-side or the user can pick an option that always fails:
>
> ```dart
> professions.where((p) => p.isActive != false && p.deletedAt == null)
> ```
>
> `GET /business/getAllcategories` already filters to `active: true` server-side, so the
> business list needs no filtering.

Pre-select the item matching `current.tag_id` and disable it (picking the same one is
rejected — see `same_category` in §7).

Show a confirmation sheet before submitting, because this is one-time and destructive to
some of their data:

> **Change your category to "Food & Restaurant"?**
> You can only do this once. Some details tied to your current category will be cleared
> and you'll need to fill them in again.

---

## 6. Step 3 — submit

```http
POST /user/me/profile-category/change
Authorization: Bearer <token>
Content-Type: application/json
```

```jsonc
// INDIVIDUAL
{ "tag_id": "BICYCLE_RIDER", "designation": "Delivery Partner" }

// BUSINESS
{ "tag_id": "FOOD_RESTAURANT", "sub_category_id": "6a08...f0" }

// BUSINESS moving into a medical category
// (PHARMACY, HOSPITALS, CLINICS, DOCTORS, DIAGNOSTIC, ALTERNATIVE_HEALTH)
{ "tag_id": "PHARMACY", "license_number": "MH-DRUG-12345" }
```

| Field | For | Required | If you omit it |
|---|---|---|---|
| `tag_id` | both | **yes** | `400 missing_tag_id` |
| `designation` | INDIVIDUAL | no | cleared |
| `sub_category_id` | BUSINESS | no | cleared — the old sub-category belonged to the old category's tree |
| `license_number` | BUSINESS | only for the 6 medical categories | `400 license_required`, unless one is already on file |

There is **no `userId` in the body.** The endpoint always acts on the token's own account.

**Success — `200`**

```json
{
  "success": true,
  "message": "Your category has been updated.",
  "data": {
    "from": "GROCERY_STORE",
    "to": "FOOD_RESTAURANT",
    "current": {
      "tag_id": "FOOD_RESTAURANT",
      "name": "Food & Restaurant",
      "category_type": "Food",
      "sub_category_id": null
    },
    "state": { "can_change": false, "changes_used": 1, "changes_remaining": 0 }
  }
}
```

`data.state` is the same shape as §4 — use it to update the screen without a second GET.

---

## 7. Errors

Every failure has a stable `code`. **Switch on `code`, never on the message text.**

| HTTP | `code` | What to show | Spends the change? |
|---|---|---|---|
| 400 | `missing_tag_id` | Keep the sheet open, nothing selected | no |
| 400 | `license_required` | Inline field error on the licence input; `errors[]` has the detail | no |
| 401 | `unauthenticated` | Re-auth | no |
| 404 | `user_not_found` | Generic failure | no |
| 409 | `same_category` | "That's already your category" — just close the sheet | **no** |
| 409 | `change_limit_reached` | "You've already changed your category. Contact support." Then disable the row. | already spent |
| 422 | `unknown_category` | Reload the picker — that option was removed or deactivated | no |
| 422 | `unsupported_account_type` | Hide the feature | no |
| 422 | `business_not_found` | "Complete your business profile first" | no |
| 502 | `earn_profile_sync_failed` | "Something went wrong, please try again in a moment" — **offer Retry** | no |
| 500 | `server_error` | Generic retry | no |

### Retry is safe

The one-time allowance is claimed **before** the backend does any work and given back if
that work fails. So a `502` or `500` costs the user nothing and **you should offer a
Retry button.** Validation errors and `same_category` don't count either.

Only a `200` decrements `changes_remaining`. If you get `409 change_limit_reached` on a
first attempt, it means the change genuinely already happened (another device, or
support) — refresh from §4 rather than showing a confusing error.

---

## 8. What to do after a successful change

The user's profile has materially changed on the server. **Do not just pop the sheet.**

1. **Re-fetch the profile** with whichever authenticated profile call the app already
   uses on the profile screen — `GET /user/getUserProfileOverview/{id}` or
   `GET /user/getUserById/{id}` for individuals, `GET /business/{businessId}` for
   businesses — and rebuild local state. Don't patch it locally.

   > Don't use `GET /user/get?contact_no=` for this. That is the unauthenticated
   > login-time lookup, and calling it outside login runs side effects you don't want
   > here (it cancels a pending account deletion and fans out to the rider / earn /
   > inventory services).

2. **For INDIVIDUAL, these fields are now cleared** — they described the old profession
   and were deliberately wiped so they can't leak into the new one:

   `designation` (unless you re-sent it), `specilization`, `department`, `subDivision`,
   `art`, `sector`, `schoolOrCollegeName`, `skills`

   If your profile-completion meter reads any of these, it will drop. That's expected —
   route the user to fill them in again for the new category.

3. **For INDIVIDUAL, working hours are gone.** `IndividualAvailability` is deleted,
   because the old profession's hours don't describe the new one. Prompt them to set
   hours again if their new category uses them.

4. **For BUSINESS, `sub_category_Of_Business` is now `null`** unless you sent a new
   `sub_category_id`. Prompt for a sub-category if the new category has them.

5. **Invalidate anything cached off the old category** — home feed, discovery filters,
   go-live state, earn/service screens.

---

## 9. Example (Dart)

Adapt to whatever HTTP layer the project uses; this is shape, not house style.

```dart
class ProfileCategoryState {
  final bool supported, canChange;
  final int changesRemaining;
  final String? tagId, name, optionsEndpoint;
  // ... fromJson
}

Future<ProfileCategoryState> fetchProfileCategory() async {
  final res = await api.get('/user/me/profile-category');
  return ProfileCategoryState.fromJson(res.data['data']);
}

/// Returns null on success; a `code` string on failure.
Future<String?> changeProfileCategory({
  required String tagId,
  String? designation,
  String? subCategoryId,
  String? licenseNumber,
}) async {
  try {
    await api.post('/user/me/profile-category/change', data: {
      'tag_id': tagId,
      if (designation != null) 'designation': designation,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (licenseNumber != null) 'license_number': licenseNumber,
    });
    return null;
  } on DioException catch (e) {
    return e.response?.data?['code'] as String? ?? 'server_error';
  }
}
```

Handling, including the retryable set:

```dart
const retryable = {'earn_profile_sync_failed', 'server_error'};

final code = await changeProfileCategory(tagId: selected.tagId);
if (code == null) {
  await refreshProfile();                 // §8 — full re-fetch
  Navigator.pop(context);
  showSnack('Your category has been updated.');
} else if (retryable.contains(code)) {
  showRetryDialog(onRetry: () => /* call again — safe, nothing was spent */);
} else if (code == 'change_limit_reached') {
  await refreshProfileCategoryState();    // §4 — disable the row
  showSnack('You have already changed your category. Please contact support.');
} else if (code == 'same_category') {
  Navigator.pop(context);
} else {
  showSnack(messageFor(code));
}
```

---

## 10. QA checklist

- [ ] Row hidden for GUEST / BLUEFLY (`supported: false`)
- [ ] INDIVIDUAL sees the professions picker; BUSINESS sees the categories picker
- [ ] Current category is pre-selected and not re-selectable
- [ ] Confirmation sheet warns that it's one-time
- [ ] Successful change → profile re-fetched, satellite fields and hours shown as empty
- [ ] Second attempt → row disabled, support message shown
- [ ] Airplane-mode / backend-down mid-request → Retry offered, and the retry **succeeds**
      (proves the allowance wasn't spent)
- [ ] BUSINESS → Pharmacy without a licence → inline field error, sheet stays open
- [ ] BUSINESS → Pharmacy with a licence → succeeds
- [ ] Change on device A → device B shows the row disabled after refresh
