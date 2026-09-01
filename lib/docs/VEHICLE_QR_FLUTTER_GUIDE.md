# Vehicle-safety QR — Flutter app changes

**Service:** `be_emergency_service`
**Audience:** Flutter app team — and **only** the Flutter team.

Everything else in this campaign is the admin panel and the web page, and it is
all in `VEHICLE_QR_ADMIN_PANEL_GUIDE.md`. Nothing there needs the app.

---

## Status: the code change is already DONE

Landed on `Development-BlueEra` in **`eb8868d50`** (27 Aug, "release prod
build"), version **14.0.70+329** — `isNewChat`, the empty `conversationId`, the
`vehicle_qr` prefilled message, and the `/v/*` bounce are all in. The
implementation is more complete than this guide originally asked for.

**If parking still does not open the chat, it is almost certainly not the code.**
Jump to *Troubleshooting* below — the usual cause is App Links failing to verify
on a debug-signed build.

The rest of this section documents what was built, for reference.

---

## The short version

**One change, in one file. Routing only.**

`lib/features/common/onboarding/view/splash_screen.dart` — the deep-link
handler, around line 212.

| | |
|---|---|
| Deep-link routing change | ✅ **this is the whole scope** |
| Chat screen changes | ❌ none |
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

Today that link opens nothing, because `_handleDeepLink` rejects `new` before it
ever reaches the `case 'chat':` branch:

```dart
final id = segments[2];
if (!_isValidMongoId(id)) {   // "new" is not 24-hex → returns, nothing opens
  logs('Invalid ID format in deep link: $id');
  return;
}
```

---

## The change

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

## Optional polish

`prefilledMessage` is already a constructor parameter, so seeding the first
message costs nothing beyond passing it:

```dart
prefilledMessage: vehicleNumber != null
    ? 'Regarding your vehicle $vehicleNumber…'
    : null,
```

Read `source`, `code` and `vehicleNumber` from `uri.queryParameters`. Nice to
have, not required.

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

Expected: the app opens on a chat with that user, empty, with *"Regarding your
vehicle UP16FL4618 - "* already in the input. Sending creates the conversation
and the owner gets the usual push.

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

## What breaks without this

Only the parking button. Scanning, registration, OTP claim and the SOS flow all
work without any app change — those are entirely browser-side.

Until this ships, tapping "Report parking issue" records the tap and hands the
browser a link that opens nothing.

---

## If `new` is the wrong sentinel

It is our choice, not a platform requirement. If you would rather the backend
sent the owner's userId in that slot, or a different keyword, say so — it is a
one-line change on the backend and much cheaper to agree now than after stickers
are printed.
