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
in the picker** — and the API tells you which one (§5).

> **Do not send `profileType`.** For individuals the backend derives it from the chosen
> profession's catalog entry. If you send it, it's ignored. This is deliberate — it's how
> "Bicycle Rider" is guaranteed never to end up filed under the wrong `profileType`.
> But see §3.2 — the derived value is **not** in the app's `profileType` vocabulary today,
> and that has to be reconciled before this ships.

---

## 3. Prerequisites — app-side work that must land first

**Revised from the Flutter team's audit.** An earlier version of this section was written
against an older checkout and overstated the work; the corrections below are theirs.

The endpoints are live and correct, but the app cannot currently express the outcome of a
change. Shipping the UI without these items produces a user who successfully changes
category and then loses the screens for it.

### 3.1 Bicycle Rider — the helper already exists, the slug doesn't

Good news first: `kRiderProfessions` and `isRiderProfession()` already exist in
`lib/core/constants/app_constant.dart` (~818-848), alongside `isGigWorkerAccount()`. The
hard part is built.

What's missing:

1. **The constant.** There is no `BICYCLE_RIDER` anywhere in `lib/`. Adding it to the
   existing `kRiderProfessions` set is a one-line change.
2. **Five live gates still bypass the helper** and compare the raw slug:
   - `delivery_partner_controller.dart:445`
   - `delivery_partner_orders.dart:63`
   - `rider_me_screen.dart:132`
   - `personal_profile_setup_new_screen.dart:2327`
   - `order_actions_carousel.dart:125`

   Route each through `isRiderProfession()` — **after auditing it**. Some genuinely mean
   *motorbike* (vehicle documents, RC/DL verification) and must keep checking `BIKE_RIDER`
   specifically. "Is a delivery rider" and "rides a motorbike" are different questions and
   the raw comparison currently conflates them.

3. **The gig picker is server-driven now**, so the old advice to add a
   `gigWorkServiceList` entry is obsolete — that list is dead code, its only consumer is
   commented out. The real question is whether the server returns Bicycle Rider in the
   catalog for the environment you're testing against. It ships via
   `node src/scripts/addIndividualProfessions.js`; ask backend to confirm it has been run
   there. `gig_work_options_screen.dart:32` documents the slugs the screen expects.

### 3.2 `profileType` vocabulary — the mapping exists but isn't applied

The app's constants are the SCREAMING_SNAKE enum (`SOCIAL_PROFILE`, `GIG_WORKER`,
`SELF_EMPLOYED`, `PROFESSIONAL`). The backend profession catalog stores display strings
(`"Social Profile"`, `"GigWork"`, `"Self Employed"`, `"Professional"`), and the change
endpoint **derives `User.profileType` from the catalog**. So after a change,
`userProfileTypeGlobal` can hold `"GigWork"` and every comparison of this shape fails:

```dart
if (userProfileTypeGlobal == GIG_WORKER) { ... }   // drawer label, contribution type,
                                                   // gig-work gating, profile setup
```

**The mapping you need already exists**: `individualProfileTypeFor()` in
`lib/core/navigation/profile_taxonomy.dart:85` already handles `"GigWork"` /
`"Self Employed"` → the app enum. It is only wired into `visit_profile_config.dart`, for
**other people's** profiles — it is never applied to the logged-in user's globals.

So the app-side fix is to apply the existing mapping when writing the globals (§9.2),
not to write new normalization.

> **Backend status.** `canonicalProfileType` now folds both vocabularies for *comparison*
> server-side, which is what stops the §3.4 guard from rejecting a client that echoes back
> its own `profileType`. It does **not** change what is stored. Whether the backend
> canonicalizes on write is still open — until it does, apply
> `individualProfileTypeFor()` on read and don't assume the raw value matches your enum.

### 3.3 The globals that gate rider UI are login-only

Confirmed exactly as previously written. `userProfessionGlobal`, `userProfileTypeGlobal`
and `userDesignationGlobal` are written **only** by
`userLoggedInIndividualGuest(...)` (`shared_preference_utils.dart:285`) and read back into
memory **only** by `initGlobals` (`:794-796`). Nothing else touches them.

That means §9's "re-fetch the profile" is **not sufficient on its own** — see §9 step 2.

### 3.4 The profession dialog has to move to the new endpoint

`update_personal_profession_dialog.dart` currently posts the profession to
`PUT /user/updateIndividualAccountUser/:id`. That endpoint has no change counter and no
audit trail, so while it stays open the one-per-account limit is enforced nowhere.

**That door is now closed.** The legacy endpoint returns
`409 use_profile_category_endpoint` for a profession/profileType change on a non-GUEST
account. There is no flag and no opt-out — profession changes go through
`POST /user/me/profile-category/change` or they don't happen.

> ⚠️ **This is the one breaking item in this guide.** From the moment the backend ships,
> the existing profession dialog stops working until it points at the new endpoint. Please
> treat §5-§7 + §9.2 as the blocking work; everything else in §3 can follow.

Onboarding is unaffected. The guard never fires for:

- **GUEST accounts** — first-time profile fill still goes through the old endpoint
- **satellite-only edits** — bio, designation, photo, DOB, specialization: all unchanged
- **re-sending the same value** — profession is compared through the catalog and
  profileType across both vocabularies, so echoing back what you just read is not a change

That last point also fixes a live bug on your side: sending `"BIKE_RIDER"` to an account
stored as `"Bike Rider"` used to count as a profession change and wiped the user's
satellite fields and working hours for nothing.

### 3.5 `ProfessionTypeData` can't express the §6 filter yet

`personal_profession_model.dart:45` has `tagId` and `profileType` but **no `isActive` or
`deletedAt`**. §6 requires filtering retired professions client-side, and that filter
cannot be written until the model is extended — `GET /individual-professions` returns those
fields, the model just drops them.

Without it, any user can pick a retired profession that always returns
`422 unknown_category`.

---

## 4. Where to put it

Settings → Account → **Change category** (or wherever the profile edit entry points
already live — follow the existing Settings pattern, don't invent a layout).

Show a subtitle with the current category name, e.g. *"Grocery Store"*.

---

## 5. Step 1 — read the state

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
| `current.tag_id` | Always the canonical catalog `tag_id`, safe to compare against the picker (see note below) |
| `can_change == true` | Row tappable |
| `can_change == false` | Row visible but **disabled**, with "You've already changed your category. Contact support to change it again." |
| `changes_remaining` | The "1 change left" hint, if you want to show it |
| `options_endpoint` | Which catalog to load in step 2 — use it instead of hardcoding an `account_type` check |

> **Note on `current.tag_id`.** `User.profession` exists in two conventions in the live
> data — the display name (`"Bike Rider"`) for accounts created through the older
> onboarding path, and the `tag_id` (`"BIKE_RIDER"`) elsewhere. This endpoint resolves
> both and **always returns the canonical `tag_id`**, so you can compare it against the
> picker's `tag_id` directly. Do **not** use the raw `profession` field from
> `GET /user/get` for that comparison — it may be either form. Use `profession_tag_id`
> from the profile response, or `current.tag_id` from here.

---

## 6. Step 2 — show the picker

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

> ⚠️ **The professions catalog is larger than the app's hardcoded lists.** The server
> returns every profession, including ones the app has no constant, icon or screen for
> (Bicycle Rider is the current example — see §3.1). Either add app support for each
> profession you expose in the picker, or restrict the picker to the slugs the app
> actually handles. Showing an unhandled profession lets the user strand themselves.

Pre-select the item matching `current.tag_id` and disable it (picking the same one is
rejected — see `same_category` in §8).

Show a confirmation sheet before submitting, because this is one-time and destructive to
some of their data:

> **Change your category to "Food & Restaurant"?**
> You can only do this once. Some details tied to your current category will be cleared
> and you'll need to fill them in again.

---

## 7. Step 3 — submit

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

**Send the `tag_id`.** The backend also accepts the catalog `_id` or the exact display
name for both account types, so an older client that sends one of those still works — but
`tag_id` is the contract and the only form you should send in new code.

There is **no `userId` in the body.** The endpoint always acts on the token's own account.

**Success → `200`**

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

`data.from` and `data.to` are always canonical `tag_id`s, whichever form you sent.
`data.state` is the same shape as §5 — use it to update the screen without a second GET.

---

## 8. Errors

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

`same_category` is returned whether the account stores the display name or the `tag_id`
internally, so pre-selecting and disabling the current item (§6) is enough to avoid it.

### Retry is safe

The one-time allowance is claimed **before** the backend does any work and given back if
that work fails. So a `502` or `500` costs the user nothing and **you should offer a
Retry button.** Validation errors and `same_category` don't count either.

Only a `200` decrements `changes_remaining`. If you get `409 change_limit_reached` on a
first attempt, it means the change genuinely already happened (another device, or
support) — refresh from §5 rather than showing a confusing error.

---

## 9. What to do after a successful change

The user's profile has materially changed on the server. **Do not just pop the sheet.**

1. **Re-fetch the profile** with whichever authenticated profile call the app already
   uses on the profile screen — `GET /user/getUserProfileOverview/{id}` or
   `GET /user/getUserById/{id}` for individuals, `GET /business/{businessId}` for
   businesses — and rebuild local state. Don't patch it locally.

   > Don't use `GET /user/get?contact_no=` for this. That is the unauthenticated
   > login-time lookup, and calling it outside login runs side effects you don't want
   > here (it cancels a pending account deletion and fans out to the rider / earn /
   > inventory services).

2. **Refresh the cached globals — this step is mandatory and easy to miss.**

   `userProfessionGlobal`, `userProfileTypeGlobal` and `userDesignationGlobal` gate the
   rider tab, gig-work options, delivery-partner orders, inventory, contribution type and
   the drawer label. They live in secure storage and are only written at login by
   `userLoggedInIndividualGuest(...)`, then loaded into memory once at app start. Step 1
   does **not** touch them.

   So after a successful change, write both the stored values and the in-memory globals:

   ```dart
   await SharedPreferenceUtils.setSecureValue(
       SharedPreferenceUtils.userProfession, newProfessionTagId);
   await SharedPreferenceUtils.setSecureValue(
       SharedPreferenceUtils.userProfileType, newProfileType);
   await SharedPreferenceUtils.setSecureValue(
       SharedPreferenceUtils.userDesignation, newDesignation ?? "");

   userProfessionGlobal  = newProfessionTagId;
   userProfileTypeGlobal = newProfileType;
   userDesignationGlobal = newDesignation ?? "";
   ```

   Take `newProfessionTagId` from `data.current.tag_id` and `newProfileType` from
   `data.current.profile_type` in the change response (subject to §3.2 — normalize if the
   backend has not been changed to emit the app's enum).

   Then rebuild any widget tree that branches on them. Without this the change appears to
   succeed and the rider UI stays on the **old** profession until the next full app
   restart *and* re-login.

3. **For INDIVIDUAL, these fields are now cleared** — they described the old profession
   and were deliberately wiped so they can't leak into the new one:

   `designation` (unless you re-sent it), `specilization`, `department`, `subDivision`,
   `art`, `sector`, `schoolOrCollegeName`, `skills`

   If your profile-completion meter reads any of these, it will drop. That's expected —
   route the user to fill them in again for the new category.

4. **For INDIVIDUAL, working hours are gone.** `IndividualAvailability` is deleted,
   because the old profession's hours don't describe the new one. Prompt them to set
   hours again if their new category uses them.

5. **For BUSINESS, `sub_category_Of_Business` is now `null`** unless you sent a new
   `sub_category_id`. Prompt for a sub-category if the new category has them.

6. **Invalidate anything cached off the old category** — home feed, discovery filters,
   go-live state, earn/service screens.

---

## 10. Example (Dart)

Adapt to whatever HTTP layer the project uses; this is shape, not house style.

```dart
class ProfileCategoryState {
  final bool supported, canChange;
  final int changesRemaining;
  final String? tagId, name, profileType, optionsEndpoint;
  // ... fromJson
}

Future<ProfileCategoryState> fetchProfileCategory() async {
  final res = await api.get('/user/me/profile-category');
  return ProfileCategoryState.fromJson(res.data['data']);
}

/// Returns the new state on success; throws with a `code` string on failure.
Future<Map<String, dynamic>> changeProfileCategory({
  required String tagId,
  String? designation,
  String? subCategoryId,
  String? licenseNumber,
}) async {
  final res = await api.post('/user/me/profile-category/change', data: {
    'tag_id': tagId,
    if (designation != null) 'designation': designation,
    if (subCategoryId != null) 'sub_category_id': subCategoryId,
    if (licenseNumber != null) 'license_number': licenseNumber,
  });
  return res.data['data'] as Map<String, dynamic>;
}
```

Handling, including the retryable set and the §9.2 globals refresh:

```dart
const retryable = {'earn_profile_sync_failed', 'server_error'};

try {
  final data = await changeProfileCategory(tagId: selected.tagId);

  await refreshProfile();                      // §9.1 — full re-fetch
  await applyProfileGlobals(                   // §9.2 — MANDATORY
    professionTagId: data['current']['tag_id'],
    profileType:     data['current']['profile_type'],
    designation:     data['current']['designation'],
  );

  Navigator.pop(context);
  showSnack('Your category has been updated.');
} on DioException catch (e) {
  final code = e.response?.data?['code'] as String? ?? 'server_error';
  if (retryable.contains(code)) {
    showRetryDialog(onRetry: () => /* call again — safe, nothing was spent */);
  } else if (code == 'change_limit_reached') {
    await refreshProfileCategoryState();       // §5 — disable the row
    showSnack('You have already changed your category. Please contact support.');
  } else if (code == 'same_category') {
    Navigator.pop(context);
  } else {
    showSnack(messageFor(code));
  }
}
```

---

## 11. QA checklist

**Prerequisites (§3) — verify before testing the feature itself**

- [ ] `BICYCLE_RIDER` added to the existing `kRiderProfessions` set
- [ ] The 5 raw gates listed in §3.1 route through `isRiderProfession()`; the ones that
      genuinely mean motorbike (vehicle docs, RC/DL) still check `BIKE_RIDER` only
- [ ] Backend confirms `addIndividualProfessions.js` has been run in the test environment,
      so `BICYCLE_RIDER` is actually in the catalog
- [ ] `individualProfileTypeFor()` is applied when writing the logged-in user's globals,
      not just to other people's profiles (§3.2) — test with an account that has been
      through a category change
- [ ] `ProfessionTypeData` carries `isActive` / `deletedAt` so the §6 filter compiles (§3.5)

**The feature**

- [ ] Row hidden for GUEST / BLUEFLY (`supported: false`)
- [ ] INDIVIDUAL sees the professions picker; BUSINESS sees the categories picker
- [ ] Picker excludes `isActive: false` / `deletedAt != null` professions
- [ ] Picker excludes any profession the app has no screens for
- [ ] Current category is pre-selected and not re-selectable
- [ ] Confirmation sheet warns that it's one-time
- [ ] Successful change → profile re-fetched, satellite fields and hours shown as empty
- [ ] **Bike Rider → Bicycle Rider: rider tab, gig-work options and delivery orders are
      still reachable immediately, without restarting the app** (this is the §9.2 check —
      it is the one most likely to fail)
- [ ] **Bike Rider → Plumber: rider UI disappears immediately, without restarting**
- [ ] Drawer label and contribution type are correct right after a change (§3.2)
- [ ] Second attempt → row disabled, support message shown
- [ ] Airplane-mode / backend-down mid-request → Retry offered, and the retry **succeeds**
      (proves the allowance wasn't spent)
- [ ] BUSINESS → Pharmacy without a licence → inline field error, sheet stays open
- [ ] BUSINESS → Pharmacy with a licence → succeeds
- [ ] Change on device A → device B shows the row disabled after refresh
- [ ] Profession dialog posts to the new endpoint, not `updateIndividualAccountUser` (§3.4)
- [ ] Onboarding (GUEST) still completes, including picking a profession
- [ ] Editing bio / designation / photo / DOB still works on the old endpoint
- [ ] No screen sends `profession` to `updateIndividualAccountUser` any more — a leftover
      call returns `409 use_profile_category_endpoint`
- [ ] Kill and relaunch the app after a change — gating matches what was shown before the
      restart (proves secure storage was written, not just the in-memory globals)
