# Vehicle-safety QR — Flutter app changes

**Service:** `be_emergency_service`
**Audience:** Flutter app team — and **only** the Flutter team.

Everything else in this campaign is the admin panel and the web page, and it is
all in `VEHICLE_QR_ADMIN_PANEL_GUIDE.md`. Nothing there needs the app.

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

With the app installed, paste this into Chrome on the device:

```
https://beapp.in/app/chat/new?userId=<any real userId>&chatType=personal&name=Test%20Owner&source=vehicle_qr&code=TEST1234&vehicleNumber=MH01AB2020
```

Expected: the app opens on a chat with that user, empty, ready to type. Sending
a message creates the conversation as normal, and the other person gets the
usual push.

Before the change: nothing happens, and logcat shows
`Invalid ID format in deep link: new`.

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
