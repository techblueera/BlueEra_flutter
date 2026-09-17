# Login: existing users being treated as new accounts — Flutter integration guide

**Audience:** BlueEra Flutter app team
**Backend status:** fixed and ready (see §7 for the services to deploy)
**App status:** one change still required in `auth_controller.dart` — §4

---

## 1. The problem, in one paragraph

An existing user enters their number, gets the OTP, and the app lands them on the
home screen **signed out** — no token, no account type, no session. Their account
is untouched in the database; the app simply threw the session away. To the user
this is indistinguishable from a fresh install.

**This is an app-side defect and only an app-side change fixes it.** It currently
affects **26,831 of 66,913 accounts — 40.1% of the base.**

Measured on production, 2026-09-17:

| `account_type` | Rows | Share | Logs in correctly today? |
|---|---:|---:|---|
| `INDIVIDUAL` | 35,122 | 52.49% | yes |
| `BUSINESS` | 4,960 | 7.41% | yes |
| **`GUEST`** | **26,797** | **40.05%** | **no — session discarded** |
| **`Admin`** | **32** | **0.05%** | **no — session discarded** |
| **`NULL`** (literal string) | **2** | **0.00%** | **no — session discarded** |

---

## 2. Backend changes shipped (context — none of these is the fix you need)

> **Read this section for context only.** An audit of production on 2026-09-17
> showed **0 rows** affected by §2.1 and **0 rows** affected by §2.2. Both were
> genuine code defects, both are fixed, and neither was causing your reports.
> The live issue is §3.

### 2.1 Phone numbers stored in more than one spelling — *0 rows affected*

`users.contact_no` is a plain unique string. Over the years the same number has
been written in several shapes:

| Spelling | Typical origin |
|---|---|
| `9876543210` | what the current app sends |
| `+919876543210` | older clients, admin imports |
| `919876543210` | SMS-provider shaped writes |
| `09876543210` | trunk-zero entries |

Login did an **exact string match**. Worse, the newer gRPC login path stripped
non-digits from the *query* (`contact_no.replace(/\D/g, "")`) while still
exact-matching the *stored* value — so a `+91…` row became permanently
unfindable. The lookup returned "no such user" and the API answered
`{"user": false, "message": "No User Found. Create A New User"}`.

**Fixed.** All login lookups now match every known spelling of a number. The
exact string you send is still tried first, so behaviour for normal 10-digit
logins is byte-for-byte unchanged.

### 2.2 `account_type` could come back `null` — *0 rows affected*

Rows created before the `account_type` enum existed carry no `account_type` at
all. The API passed that through as `null`.

**Fixed.** `account_type` is now never null on a successful login. A row with no
stored value is resolved by what it owns — a business makes it `BUSINESS`,
otherwise `INDIVIDUAL`. Guests are always explicitly stamped `GUEST` at creation,
so a missing value can never mean "guest".

### 2.3 Signup could mint a second account

The duplicate guard on `POST /user/add`, the business signup and
`POST /user/create-guest-account` used the same exact-match. A user stored as
`+91…` who reached signup got a **second row** for the same human.

**Fixed.** All three guards use the tolerant match, and the guest→real promotion
is now keyed on the matched `_id` rather than on the raw phone string.

---

## 3. What the app is still doing wrong

`lib/features/common/auth/controller/auth_controller.dart`, `verifyOTP()`,
around lines **182–240**:

```dart
if (dataUser) {
  if (data.token != null && (data.token?.isNotEmpty ?? false)) {

    if (data.data?.accountType?.toUpperCase() == AppConstants.business) {
      await SharedPreferenceUtils.setSecureValue(..., data.token);   // saves session
      ...
    } else if (data.data?.accountType?.toUpperCase() == AppConstants.individual) {
      await SharedPreferenceUtils.setSecureValue(..., data.token);   // saves session
      ...
    }
    // ← no else. For any other account_type NOTHING is saved.

    Get.offNamedUntil(BottomNavigationBarScreen, ...);               // navigates anyway
  }
}
```

The session (`authToken`, `accountType`, `userLoginMobile`, `userBusinessId`) is
persisted **only inside those two branches**. A `GUEST` — 40.05% of all accounts —
matches neither, so nothing is saved, and the code falls straight through to
`Get.offNamedUntil(BottomNavigationBarScreen)` and navigates home anyway. The
user is on the home screen with no session at all.

### 3.1 The branch that used to catch guests is now dead code

The app *does* have correct GUEST handling — `auth_controller.dart:264`:

```dart
if (dataUser) {
  ...
}
///Guest create account but profile create.....
else if (data.data?.accountType?.toUpperCase() == AppConstants.guest) {
  await SharedPreferenceUtils.guestUserLoggedIn(...);   // ← saves the session
  Get.offAll(() => const CreateAccountTypeScreen());    // ← correct destination
}
```

Note it is an **`else` of `if (dataUser)`**. It only runs when the backend says
`user: false`.

That used to be the case: until September the backend computed
`user: ["INDIVIDUAL","BUSINESS"].includes(account_type)`, so every guest got
`user: false` and landed in this branch. The backend then fixed that whitelist —
correctly, since `user` is supposed to mean "does this account exist?" — and now
sends `user: true` for guests.

**The result is that the fix routed guests away from the only branch that saved
their session.** The `else if` above is now unreachable, and guests fall into the
`if (dataUser)` ladder that has no branch for them. The failure did not go away;
it moved, and got worse — guests used to reach a coherent onboarding screen, and
now reach a broken home screen.

`Admin` (32 rows) and the literal string `"NULL"` (2 rows) fail the same way.
`BLUEFLY` is in the backend enum but has **0 rows in production** — it is a
latent case, not a live one.

---

## 4. The change you need to make

**Rule: never branch on `account_type` to decide whether someone is logged in.
Always persist the session first; branch only to pick which profile controller
to warm.**

```dart
if (dataUser) {
  if (data.token != null && (data.token?.isNotEmpty ?? false)) {

    final accountType = (data.data?.accountType ?? '').toUpperCase();

    // 1. ALWAYS persist the session — every account type, no exceptions.
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.authToken, data.token);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.accountType, accountType);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.userLoginMobile, data.data?.contactNo);
    if (data.data?.business != null) {
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.userBusinessId, data.data?.business);
    }
    await getUserAuthToken();
    await getMobileNo();
    await getUserLoginAccountType();
    await getUserLoginBusinessId();

    unawaited(ChatSocketService().connectToSocket());

    // 2. Ask the BACKEND whether onboarding is needed. Do not infer it.
    if (data.needsOnboarding == true) {
      Get.offAll(() => const CreateAccountTypeScreen());
      return;
    }

    // 3. Branch only to warm the right profile controller.
    if (accountType == AppConstants.business) {
      final c = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
      await c.viewBusinessProfile();
    } else {
      // INDIVIDUAL, BLUEFLY, and anything the backend adds later.
      final c = Get.put(ViewPersonalDetailsController(), permanent: true);
      await c.viewPersonalProfile();
    }

    Get.offNamedUntil(
      RouteHelper.getBottomNavigationBarScreenRoute(),
      (route) => false,
      arguments: {ApiKeys.initialIndex: 1},
    );
  }
}
```

Add `BLUEFLY` to `AppConstants` while you are there:

```dart
static const String bluefly = 'BLUEFLY';
```

…but treat it as a label, not as a gate. The `else` above must stay a real
`else`, so that any account type added on the backend later still logs in
instead of silently failing.

### 4.1 `OtpVerifyModel` is missing fields

`lib/core/api/model/otp_verify_model.dart` does not parse `user`,
`account_type` or `needs_onboarding`. Today the controller reaches around the
model with `response.response?.data?[ApiKeys.user]`. Please add them:

```dart
class OtpVerifyModel {
  OtpVerifyModel.fromJson(dynamic json) {
    success                  = json['success'];
    message                  = json['message'];
    token                    = json['token'];
    data                     = json['data'] != null ? User.fromJson(json['data']) : null;
    userExists               = json['user'] == true;          // ← add
    accountType              = json['account_type'];          // ← add
    needsOnboarding          = json['needs_onboarding'] == true; // ← add
    isBlocked                = json['isBlocked'];
    blockedType              = json['blockedType'];
    accountDeletionCancelled = json['account_deletion_cancelled'];
  }

  bool? userExists;
  String? accountType;
  bool? needsOnboarding;
  // ...existing fields
}
```

---

## 5. The response contract

### `POST /auth-service/user/verify-otp`

Request:

```json
{
  "contact_no": "9876543210",
  "otp": "123456",
  "device_token": "<fcm token>",
  "one_signal_player_id": ""
}
```

Send the number however the user typed it. The backend now matches `9876543210`,
`+919876543210`, `919876543210` and `09876543210` to the same account. Sending a
bare 10-digit number stays the recommended default.

**Existing user — 200:**

```json
{
  "success": true,
  "message": "Login successful",
  "token": "<jwt>",
  "chat_token": null,
  "data": {
    "_id": "68763d966cbe951b99f684da",
    "account_type": "INDIVIDUAL",
    "contact_no": "9876543210",
    "business": null
  },
  "user": true,
  "account_type": "INDIVIDUAL",
  "needs_onboarding": false,
  "isBlocked": false,
  "blockedType": null,
  "account_deletion_cancelled": false
}
```

**Guest who has not finished onboarding — 200:**

```json
{
  "success": true,
  "token": "<jwt>",
  "data": { "_id": "...", "account_type": "GUEST", "contact_no": "9876543210", "business": null },
  "user": true,
  "account_type": "GUEST",
  "needs_onboarding": true,
  "isBlocked": false,
  "blockedType": null,
  "account_deletion_cancelled": false
}
```

**Genuinely new number — 200:**

```json
{
  "success": false,
  "user": false,
  "message": "No User Found. Create A New User"
}
```

Note this is a **200, not a 404**, and carries no `data` object.

### Field reference

| Field | Type | Meaning | How the app must use it |
|---|---|---|---|
| `user` | bool | Does an account exist for this number? | `false` → signup. `true` → log in. Nothing else. |
| `token` | string | Session JWT | **Always persist when `user` is `true`**, whatever `account_type` says. |
| `account_type` | string | Schema enum is `INDIVIDUAL` \| `BUSINESS` \| `BLUEFLY` \| `GUEST`, but production **also contains `Admin` (32 rows) and the literal string `NULL` (2 rows)** that predate the enum | Picks which profile screen/controller to use. **Never** a login gate, and never a whitelist — unrecognised values must fall through the `else`. Never null on success. |
| `needs_onboarding` | bool | Backend's verdict: send this person through signup | The **only** onboarding signal. Do not infer it from `account_type`. |
| `data.business` | string / null | Business `_id` when the account owns one | Store as `userBusinessId`. |
| `isBlocked` | bool | Admin-restricted | Show the restriction banner; the session is still valid. |
| `account_deletion_cancelled` | bool | Logging in reversed a pending deletion | Show the "your deletion was cancelled" banner. |

`account_type` is guaranteed non-null whenever `user` is `true`, but it is **not**
guaranteed to be one of the four enum values — production already holds `Admin`
and `NULL`. Treat any value you do not recognise as a normal logged-in user, not
as an error. This is exactly why §4 insists on a real `else`.

---

## 6. Test cases

Please run these against staging once the backend is deployed.

Ordered by how many real users each case represents.

| # | Setup | Rows in prod | Expected |
|---|---|---:|---|
| 1 | **`GUEST` account logs in** | **26,797** | `needs_onboarding: true` → `CreateAccountTypeScreen`, **token persisted**. **Fails today: lands on home screen signed out.** |
| 2 | Kill the app after case 1 and reopen | — | Still signed in. This is the check that actually proves the token was saved. |
| 3 | Existing `INDIVIDUAL` | 35,122 | Home screen, personal profile loaded |
| 4 | Existing `BUSINESS` | 4,960 | Home screen, business profile, `userBusinessId` populated |
| 5 | Account with `account_type: "Admin"` | 32 | Logs in as a normal user via the `else` branch — **fails today** |
| 6 | Account with `account_type: "NULL"` (literal string) | 2 | Same as case 5 — **fails today** |
| 7 | Genuinely new number | — | `user: false` → signup flow |
| 8 | Account with a pending deletion, inside the grace window | — | Logs in, `account_deletion_cancelled: true`, banner shown |
| 9 | `BLUEFLY` account | 0 | Logs in via the `else` branch. No production rows — cover it so the branch cannot rot. |
| 10 | Number stored as `+919876543210`, log in with `9876543210` | 0 | Same account. Backend-side, already fixed; no prod rows, listed for completeness. |

**Cases 1 and 2 are the release.** Everything else is regression cover.

---

## 7. Backend rollout

Two services must be deployed **together**. Deploy user-service first.

**`be_user_service`**
- `src/utils/contactNumber.js` *(new)*
- `src/repository/userDualRead.repository.js`
- `src/grpc/services/userService.js`
- `src/controllers/user.controller.js`
- `src/tests/contactNumber.test.js` *(new)*

**`be_auth_service`**
- `src/controllers/user.controller.js`

No schema change, no migration, no index change. Nothing is rewritten in the
database — the fix only widens what a lookup will match. Rolling back is safe.

> **Deploy-branch warning:** `be_auth_service`'s `origin/prod` branch is stuck at
> a July 2025 commit and does not contain the September `account_type` fix. If
> any environment deploys `prod` rather than `prod-staging`, it is still running
> the original whitelist bug. Confirm which branch each environment tracks.

### Checking the blast radius

```bash
node src/scripts/auditDuplicateContacts.js
```

Prints total rows, how many store a non-bare-10-digit number, how many are
missing `account_type`, and the full `account_type` breakdown, before any
result — so an empty result is never ambiguous.

**Production, 2026-09-17:** 66,913 rows; **0** non-bare-10-digit; **0** missing
`account_type`; **0** duplicate groups. That is why §2.1 and §2.2 have no
population. Re-run before each release; the numbers are the release criteria.

---

## 7.1 Duplicate accounts — checked, none exist

An earlier revision of this guide warned that users might already hold two
accounts for one number. **The audit found zero.** No merge tool, no support
queue, nothing outstanding. Re-run the script above if the situation changes;
the mechanics are below for reference only.

Had they existed, the lookup would have resolved them to the **newer, emptier**
row, because it tries the exact string the app sends first and the app sends the
bare national number — the spelling a new row is written in. Verified against a
live Mongo instance: rows `+919876543210` (BUSINESS, "Old Shop") and
`9876543210` (GUEST, "Guest3210"), login as `9876543210` → the GUEST row.

That ordering is deliberate. The alternative silently flips people onto a
different `_id`, and everything they have done since — posts, chats, orders,
wallet, followers, across every service — hangs off the `_id` they have been
using. It would trade one data-loss complaint for a worse one.

If duplicates ever do appear, list them first:

```bash
node src/scripts/auditDuplicateContacts.js                      # every duplicate pair
node src/scripts/auditDuplicateContacts.js --contact 9876543210 # one number
node src/scripts/auditDuplicateContacts.js --json               # for a ticket
```

The script is read-only. For each number it prints every row and marks two
things: `LOGIN→` the row a login reaches today, and `RICHEST` the row that
actually holds the account. **Both markers on the same row is healthy; split
across two rows is a user who is locked out of their own account.**

It only counts what lives in user-service (profile fields and business
ownership). Posts, chats, orders and wallet balances hang off the `_id` in other
services and must be checked there before anyone merges or deletes anything.

For the app team: nothing to implement here. If a user reports "my old profile
is gone" *after* this release, capture their phone number and send it to the
backend team — do not have the app create or re-link anything.

---

## 8. Contact

Backend owner for this change: user-service / auth-service team. Raise anything
that still reproduces after §4 ships with the `contact_no` as stored in Mongo and
the full `verify-otp` response body.

---

## 9. What shipped in the app (filled in by the Flutter team)

§4 is implemented. Three files, plus a test:

| File | Change |
|---|---|
| `lib/core/api/model/otp_verify_model.dart` | Parses `user` → `userExists`, top-level `account_type`, and `needs_onboarding`. Tolerates stringified booleans. |
| `lib/features/common/auth/model/login_destination.dart` *(new)* | `resolveLoginDestination()` — the whole routing decision as one pure function. |
| `lib/features/common/auth/controller/auth_controller.dart` | `verifyOTP()` branches on that decision; new `_completeGuestLogin()` persists a guest session; the account-type ladder now ends in a real `else`. |
| `test/login_destination_test.dart` *(new)* | The §6 case table (1, 3–7, 9) plus the response contracts from §5. |
| `lib/core/constants/app_constant.dart` | `AppConstants.bluefly`. |

The decision is a pure function precisely because it is the thing that broke:
it is now covered by tests that need no Dio, GetX navigation or secure storage,
and `account_type` cannot quietly become a login gate again without a test
going red.

### Two deliberate deviations from §4

1. **A guest lands on the bottom nav, not `CreateAccountTypeScreen`.** This app
   already decided a guest browses first and enters account creation from
   inside the app via `createProfileScreen()` — that is what
   `createGuestAccountUserController` does for a guest who has just been
   created, and the two guest entry points now share one implementation. The
   session is persisted exactly as §4 requires; only the destination differs.
2. **An unrecognised `account_type` is stored locally as `INDIVIDUAL`.** It
   still logs in through the real `else`, as §4 insists. But the app gates
   screens on `accountTypeGlobal == INDIVIDUAL | BUSINESS` in dozens of places,
   so persisting `Admin` verbatim would log those 32 users into a state that is
   neither. The value the server sent is logged, not dropped.

### Not implemented

`isBlocked` / `blockedType` are parsed but no restriction banner exists in the
app yet — the session is valid and the user logs in normally, which is the part
§5 cares about. Tell us what the banner should say and we will add it.

### Waiting on the backend

Cases 1 and 2 cannot be verified end-to-end until `be_user_service` and
`be_auth_service` are on staging (§7) — the app change is what makes a guest's
token survive, and confirming it means logging in as a real `GUEST` row and
killing the app. Please confirm which branch each environment tracks before
that run; §7's warning is that `be_auth_service`'s `prod` branch still has the
original whitelist.
