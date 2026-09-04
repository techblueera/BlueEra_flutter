# Vehicle-safety QR — Flutter app changes

**Service:** `be_emergency_service`
**Audience:** Flutter app team — and **only** the Flutter team.

Everything else in this campaign is the admin panel and the web page, and it is
all in `VEHICLE_QR_ADMIN_PANEL_GUIDE.md`. Nothing there needs the app.

---

## Status: complete

The routing landed on `Development-BlueEra` in **`eb8868d50`** (27 Aug), version
**14.0.70+329** — `isNewChat`, the empty `conversationId`, the `vehicle_qr`
prefilled message and the `/v/*` bounce.

The last gap — **the deep link was dropped when the user was not signed in** —
is now closed too. A link that arrives without a usable account is stashed in
secure storage and replayed the moment one exists, so the person who taps
*Report parking issue* on a stranger's windscreen lands on the owner's chat
after signing up, not on home.

Everything below this point is reference: what was built, and how to test it.

---

## What the signed-out / guest fix does

Three files, one idea: **read the link on every launch, and never throw it away
just because there is nobody to open it as yet.**

### `lib/core/services/deep_link_router.dart` (new)

The whole routing switch moved out of `SplashScreen` into `DeepLinkRouter`, so
the same routing can run from more than one place — splash on a cold start, and
the home shell when replaying a stashed link. Nothing in it touches
`BuildContext` (it navigates with `Get`), which is what lets it run from a
splash that is about to be torn down.

Three decisions sit in front of the switch:

| | |
|---|---|
| `isBrowserBounce(uri)` | the `emergency.beapp.in/v/{code}` sticker — handed to the browser, **before any session check**, because the scan page needs no BlueEra account |
| `requiresRealAccount(uri)` | `app/chat/*` — a guest has no profile for the owner to reply to |
| `routeOrDefer(uri)` | route it now, or stash it — used by the warm-state listener |

`DeepLinkService` in the same file now owns the `app_links` subscription. It
used to live on `SplashScreen` and survive only because it was never cancelled
— a leak the app depended on, since splash is torn down seconds after launch
and a link tapped an hour later still has to open. It is process-lifetime state
now, held deliberately.

### `SharedPreferenceUtils`

`saveDeferredDeepLink` / `getDeferredDeepLink` / `clearDeferredDeepLink`, the
same shape as the existing deferred referral code — plus a saved-at timestamp
and a 24-hour `deferredDeepLinkMaxAge`. A link nobody came back to finish
expires instead of reopening a stale parking report days later; a missing or
garbled timestamp counts as expired, because a link that cannot be aged is a
link that could reopen forever.

### `splash_screen.dart`

`_initDeepLinks()` now runs on **every** launch and **before every early
return** in `_openNextScreen` (share intent, notification launch, language
selection) — not inside the `isLoginStatus == "true"` branch. The link is then
either bounced to the browser, routed, or stashed.

### `chat_view_controller.dart` — the empty chat, and what `new` really means

Two fixes here, both about what the reporter sees once the chat opens.

**The message list sat on a spinner forever.** `getListOfMessageResponse` is
controller-level state, and for a chat with no conversation nothing ever
settles it: `loadOfflineMessages` returns early on an empty id, and no fetch
completes. So the list read "still loading" and painted a spinner that never
resolved — and on a warm app it would have painted the *previous* chat's
messages, since that Rx still held them. `listenUserNewMessages` now publishes
an empty `complete()` when the conversation id is empty, which both clears the
stale list and lets the screen render its "say Namaste 🙏" starter. Both chat
screens gate on the same condition, so the one change covers them.

**`new` does not mean "these two have never talked".** It means the backend
never looked — it has no conversation id to send. So the router no longer
assumes a blank thread. It calls `checkChatConnectionAndOpenChat`, the same
lookup behind every in-app "message this person" tap:

| Who scans | What comes back | What opens |
|---|---|---|
| first-time reporter | no conversation | initial-message mode → "say Namaste" starter, plate prefilled |
| repeat reporter, or the two have chatted before | the existing thread | that thread **with its history**, plate prefilled |

It also fills in the owner's avatar and contact number, which the link does not
carry. `checkChatConnectionAndOpenChat` now returns whether it opened anything,
so if the lookup fails (offline, empty cache) the router falls through and
opens the chat blind — a scanned sticker must never dead-end on a snackbar.

### `bottom_navigation_bar_screen.dart`

`_resumeDeferredDeepLink()` in the post-frame init. This is the one place every
route into a real session converges — login, signup, and a guest upgrading
their account all land on the home shell — so it is where the link is replayed.
It clears the link **before** routing, so a failure inside routing cannot leave
one that reopens on every launch. A guest hitting a chat link keeps the link
stashed and gets `createProfileScreen()` instead, once per process.

---

## The short version

**Five files:** `lib/core/services/deep_link_router.dart` (new),
`lib/features/common/onboarding/view/splash_screen.dart`,
`lib/core/constants/shared_preference_utils.dart`,
`lib/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart`,
`lib/features/chat/auth/controller/chat_view_controller.dart`.

| | |
|---|---|
| Deep-link routing (`chat/new`) | ✅ shipped |
| Deferred link across login | ✅ shipped |
| Guest → sign-up, then resume | ✅ shipped |
| `new` resolves an existing thread | ✅ shipped |
| Chat screen changes | ❌ none (the fix is in the controller) |
| New screens | ❌ none |
| AndroidManifest / iOS entitlements | ❌ none |
| QR scanner in the app | ❌ none — the phone camera does it |
| New packages | ❌ none |
| API work | ❌ none |

---

## Why the app is involved at all

The sticker on a windscreen encodes `https://emergency.beapp.in/v/{code}`, and
that page must open in the **browser**.

The app *does* claim that host — an unscoped `autoVerify` filter left over from
the emergency-profile QR feature — so Android hands the app every path on it,
sticker URLs included. That filter cannot simply be removed (intent filters
cannot exclude a path, and dropping it breaks the emergency-profile QR), so the
app detects `/v/*` and re-launches it externally. Handled; noted here only so
nobody "fixes" it back.

The one place the app enters the flow: when the person who scanned taps
**"Report parking issue"**, the web page redirects into a chat with the vehicle
owner, so they can send text, photos and video — and the owner gets the ordinary
chat push notification.

```
camera scans sticker
  → browser opens emergency.beapp.in/v/{code}
  → user taps "Report parking issue"
  → browser redirects to:
      https://beapp.in/app/chat/new?userId=<ownerId>&chatType=personal
        &name=<ownerName>&source=vehicle_qr&code=<qrCode>&vehicleNumber=<plate>
  → APP OPENS on the owner's chat        ← the only app involvement
```

**The host is `beapp.in`, not `blueera.ai`.** That matters, and it is verified,
not assumed:

| | `assetlinks.json` | `apple-app-site-association` |
|---|---|---|
| `beapp.in` | ✅ real, `ai.bluecs.app` | ✅ real, `46RN9MXMLM.ai.bluecs.app`, paths include `/app/chat/*` |
| `blueera.ai` | ❌ returns the SPA shell | ❌ returns the SPA shell |

`blueera.ai` cannot verify App Links at all — a link there opens a browser, not
the app. `beapp.in/app/chat/*` is already registered on both platforms, so **no
manifest or entitlement work is needed.**

---

## Why the link says `new`

The two people are strangers — **there is no conversation between them yet**. So
the backend cannot send a real `conversationId` and puts the literal `new` in
that slot. chat-service creates the conversation when the first message is
actually sent.

Before the fix, `_handleDeepLink` rejected `new` before it ever reached the
`case 'chat':` branch:

```dart
final id = segments[2];
if (!_isValidMongoId(id)) {   // "new" is not 24-hex → returned, nothing opened
  logs('Invalid ID format in deep link: $id');
  return;
}
```

That is now handled — the section below records what was done.

---

## The change that already shipped

Kept for reference. You do not need to do this again — it is in
`eb8868d50` onward.

**1 — let `new` past the ObjectId guard** (~line 215):

```dart
final id = segments[2];
// "new" = a chat that does not exist yet (vehicle-QR parking reports).
// chat-service creates the conversation when the first message is sent.
if (id != 'new' && !_isValidMongoId(id)) {
  logs('Invalid ID format in deep link: $id');
  return;
}
```

**2 — in `case 'chat':` (~line 227), open it in initial-message mode:**

```dart
final isNew = id == 'new';
Get.to(() => PersonalChatScreen(
  conversationId: isNew ? '' : id,
  userId: chatUserId,
  type: chatType,
  name: chatName,
  isInitialMessage: isNew,     // was hardcoded false
));
```

That is the entire change.

---

## Why nothing else needs touching

`PersonalChatScreen` **already** handles an empty `conversationId` — the app does
this in four places today. From `chat_view_controller.dart:3125`:

```dart
isInitialMessage: conversationId == '',
```

Exactly the pattern this link needs. The constructor already accepts everything:

```dart
PersonalChatScreen({
  required this.conversationId,     // '' is fine
  required this.userId,
  required this.isInitialMessage,   // true for a new chat
  this.prefilledMessage,            // optional, already supported
  ...
});
```

and `didChangeAppLifecycleState` already guards it with `if (id.isEmpty) return;`.

So this is a proven, working path — not something new being built.

---

## The prefilled first message — shipped

`prefilledMessage` was already a constructor parameter on both chat screens, so
seeding the first message cost nothing beyond passing it. In `case 'chat':`:

```dart
final vehicleNumber = queryParams['vehicleNumber']?.trim() ?? '';
final prefilledMessage = queryParams['source'] == 'vehicle_qr' &&
        vehicleNumber.isNotEmpty
    ? 'Regarding your vehicle $vehicleNumber - '
    : null;
```

Scoped to `source == 'vehicle_qr'` with a non-empty plate, so no other
`chat/new` link inherits vehicle wording and the sentence never renders with a
hole in it. `code` is carried by the link for support traceability; the app
does not need to read it.

---

## ⚠️ Keep `/v/*` on `emergency.beapp.in` going to the browser

That host is already claimed by an unscoped `autoVerify` filter from the
emergency-profile QR, so Android routes sticker URLs into the app. The app
detects `/v/*` and re-launches it externally, which is what makes the scan page
open in the browser.

**Do not remove that bounce, and do not add a scoped filter that swallows
`/v/*`.** The scan page is a full web journey — registration, OTP, terms, SOS —
and none of it exists in the app. Intercepting it means a blank screen.

---

## Every case you have to handle

The link only ever arrives in one shape. What differs is the state the app is in
when it lands.

| # | State when the link arrives | What must happen | Status |
|---|---|---|---|
| 1 | Signed in, app cold-started by the link | chat opens on the owner | ✅ works |
| 2 | Signed in, app already running (warm) | chat opens on the owner | ✅ works |
| 3 | **Signed out** | stash the link, open login, resume to the chat after sign-in | ✅ works |
| 4 | **Guest account** | chat needs a real account — send to sign-up, then resume | ✅ works |
| 5 | App not installed | web page shows the store link | ✅ web-side, nothing to do |
| 6 | Owner has no BlueEra account | web page shows "owner not on the app" | ✅ web-side, no link is sent |

Cases 5 and 6 never reach the app — the web page handles them and no deep link
is generated. They are listed so nobody goes looking for an app-side bug that
does not exist.

### Case 4 — guest accounts

`isLoginStatus == "true"` is also true for a **guest**, so a guest passes the
login gate. Verified against the rest of the app: every in-app chat entry point
already bounces a guest to account creation rather than into the chat (see
`DiscoverChatIcon`), because a guest has no profile for the owner to reply to.

The deep link now does the same. `DeepLinkRouter.requiresRealAccount` marks
`app/chat/*`, the link stays stashed, and the guest is sent to
`createProfileScreen()` — once per process, so backing out of account creation
does not re-open it on a loop. Finish signing up and the home shell replays the
link into the owner's chat.

### Case 3 — what "resume" should look like

The user tapped *Report parking issue* on someone's windscreen. After signing
in, they should land **on the chat**, with the plate already in the input:

```
Regarding your vehicle UP16FL4618 - 
```

Not on home. Not on a toast saying "link expired". The whole point of the
campaign is converting that scan into a first message.

---

### What the link carries

```
https://beapp.in/app/chat/new
  ?userId=6a0a9367b3b8327f72a28ce6     ← the vehicle owner. 24-hex, always present
  &chatType=personal                   ← "personal" | "business"
  &name=Priyanka%20Kumari              ← owner display name, for the app bar
  &source=vehicle_qr                   ← scopes the prefilled message
  &code=MFYRG8CT                       ← the sticker, for support traceability
  &vehicleNumber=UP16FL4618            ← the plate, seeds the first message
```

`userId` is guaranteed — the backend does not emit a link without one. If it is
ever missing or not 24-hex, that is a backend bug worth reporting rather than
working around; the current code correctly refuses to open a chat with nobody.

`source`, `code` and `vehicleNumber` are extras. Treat them as optional: a
future campaign may reuse `chat/new` without them, and the prefill is already
correctly scoped to `source == 'vehicle_qr'` with a non-empty plate.

---

## Testing

Two live stickers are set up on production right now:

| Code | Backend answers | Expected on device |
|---|---|---|
| `MFYRG8CT` | `chatAvailable: true` | app opens Priyanka's chat |
| `4KXYVKQP` | `chatAvailable: false` | web page shows "owner not registered", no chat |

Paste this into Chrome on the device:

```
https://beapp.in/app/chat/new?userId=6a0a9367b3b8327f72a28ce6&chatType=personal&name=Priyanka&source=vehicle_qr&code=MFYRG8CT&vehicleNumber=UP16FL4618
```

Expected: the app opens on a chat with that user, showing the **"say Namaste
🙏" starter** (not a spinner), with *"Regarding your vehicle UP16FL4618 - "*
already in the input. Sending creates the conversation and the owner gets the
usual push.

Send once, then open the same link again: the second time it must open the
**existing thread with that first message in it**, not a blank chat.

### The four states to test, not just the easy one

Cases 1 and 2 are what you get by pasting the link with the app installed and
signed in. The two that used to fail need setting up deliberately:

| # | Setup | Expected |
|---|---|---|
| 1 | signed in, app killed | link opens the chat, prefilled |
| 2 | signed in, app in background | same |
| 3 | **signed out** (log out first, then paste the link) | login screen → sign in → **lands on the chat**, prefilled. Not home. |
| 4 | **guest account** | account-creation screen → finish signup → **lands on the chat**, prefilled |

For case 3 the link is only replayable for 24 hours
(`SharedPreferenceUtils.deferredDeepLinkMaxAge`); abandon the login for longer
than that and the app correctly opens on home with nothing pending.

Also check the sticker URL itself still leaves the app while signed out:

```
https://emergency.beapp.in/v/MFYRG8CT
```

Expected: the browser opens the scan page. It must **not** be stashed for after
login — that page needs no BlueEra account.

---

## Troubleshooting — read this before suspecting the code

### Tell the three failure modes apart

| What you see | Meaning | Go to |
|---|---|---|
| **Browser** opens (or a download page) | App Links not verified | A |
| App opens on **home/splash**, no chat | Build predates the fix | B |
| App opens **on the chat** | Working | — |

### A. App Links not verified — the most common cause

```bash
adb shell pm get-app-links ai.bluecs.app
```

Look for `beapp.in`. It must say **`verified`**. `legacy_failure`, `1024` or
`none` means Android will never hand the link to the app — on Android 12+ a
failed `autoVerify` filter is not even offered, the link goes straight to the
browser.

**Why a debug build fails.** `https://beapp.in/.well-known/assetlinks.json`
registers exactly **one** SHA-256 fingerprint (`A4:6A:1F:C9:38:AC:75:9B:86:F3…`)
for `ai.bluecs.app`. A debug APK is signed with the debug keystore, so the
fingerprint does not match and verification fails — with correct code, on a
correct device.

**Only a Play-signed build verifies automatically.** Play Store, or an internal
testing track install. A locally built debug or self-signed release APK will
not.

To force it on for a debug build:

```bash
adb shell pm set-app-links-user-selection --user 0 --package ai.bluecs.app true beapp.in
```

or on the device: **Settings → Apps → BlueEra → Open by default → Open
supported links**.

To have the debug key verify permanently, send this fingerprint to whoever owns
`beapp.in` and have it added as a second entry in `assetlinks.json`:

```bash
keytool -list -v -keystore ~/.android/debug.keystore \
        -alias androiddebugkey -storepass android -keypass android
```

### B. The installed build predates the fix

```bash
adb shell dumpsys package ai.bluecs.app | grep versionName
```

Needs **14.0.70+329** or later. Older builds open the app but the router rejects
`new` — logcat shows `Invalid ID format in deep link: new`.

### C. Package name mismatch to check separately

The manifest and `assetlinks.json` both say **`ai.bluecs.app`**. But
`emergency_profileScreen.dart:526` hardcodes `ai.blueera.app` in a Play Store
URL, which points at a listing that does not exist. Unrelated to this feature,
but worth fixing.

---

## What this used to break

Only the parking button, and only for **signed-out users** — which was most of
them, since the person scanning a stranger's windscreen is rarely signed in.

They tapped *Report parking issue*, the app opened on login, they signed in, and
landed on home with no chat and no explanation. From their side the button
simply did not work. That is what the deferred-link fix above closes.

Scanning, registration, OTP claim and SOS all work with no app involvement at
all — those are entirely browser-side.

---

## If `new` is the wrong sentinel

It is our choice, not a platform requirement. If you would rather the backend
sent the owner's userId in that slot, or a different keyword, say so — it is a
one-line change on the backend and much cheaper to agree now than after stickers
are printed.
