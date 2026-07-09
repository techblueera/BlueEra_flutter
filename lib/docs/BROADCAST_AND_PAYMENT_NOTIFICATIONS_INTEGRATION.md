# Broadcast & Payment Notifications — Flutter Integration Guide

Backend date: 2026-07-09. Applies to `be_chat_service`, `be_user_service` (admin broadcast) and `be_subscribe_service` (payment reminder + payment success).

This guide documents new fields the backend now emits and the minimal frontend
work needed to render them. **All backend changes are additive and backward
compatible — shipping the app unchanged will not break anything.** The steps
below are opt-in upgrades to render admin broadcasts and payment messages as
proper BlueEra announcement cards.

---

## 1. What changed on the backend

1. **Admin broadcast** (`POST /admin/broadcast`) already delivered a read-only
   BlueEra chat message (`chat.service` → `ADMIN_BROADCAST`) plus push + in-app.
   The chat message and its `newMessageReceived` socket event now carry the
   **full broadcast context** as flat keys **and** under `metadata.*`:
   `title, body, link, media_url, media_type, media_thumbnail, image_url,
   category, broadcast_id, is_announcement`.

2. **Payment reminder** (`security_deposit_reminder`) and **payment success**
   (`security_deposit_held`, `subscription_activated`, `subscription_charged`,
   `recharge_activated`) now ALSO post a BlueEra chat announcement — same
   delivery shape as an admin broadcast (push + in-app + chat). Previously they
   were push + in-app only. These carry `category: "payments"`, a `title` +
   `body`, and `broadcast_id: "<operation>:<userId>"`. No media/link.

3. Push + in-app notifications are **unchanged** (still FCM data-only via
   `notification.service`). Nothing to do there for these features.

---

## 2. Socket payload — `newMessageReceived`

Handled today at
`lib/features/chat/auth/controller/chat_view_controller.dart` →
`Messages.fromJson(data['message'])`.

Text-only announcement (e.g. the payment reminder, or a broadcast with no media):

```jsonc
{
  "message": {
    "_id": "…",
    "conversation_id": "…",            // BlueEra "announcement" conversation
    "senderId": "…",                   // a BlueEra ADMIN user → sender renders "BlueEra"
    "message": "Flat 20% off for businesses this week!",  // body (+ link appended if any)
    "message_type": "text",            // text | image | video  (NOT "broadcast")
    "sub_type": "message",
    "url": [],                         // media array (see §4)

    // NEW flat keys (all nullable)
    "title": "Diwali Offer 🎉",
    "body": "Flat 20% off for businesses this week!",
    "link": null,
    "media_url": null,
    "media_type": null,
    "media_thumbnail": null,
    "image_url": null,
    "category": "offer",               // "payments" for payment messages
    "broadcast_id": "…",               // "<operation>:<userId>" for payment msgs

    // NEW metadata mirror (same values; matches REST history shape — see §3)
    "metadata": {
      "broadcast_id": "…",
      "category": "offer",
      "title": "Diwali Offer 🎉",
      "body": "Flat 20% off for businesses this week!",
      "link": null,
      "media_url": null,
      "media_type": null,
      "media_thumbnail": null,
      "image_url": null,
      "is_announcement": true
    },

    "status": "sent",
    "is_announcement": true,           // NEW — use this to route the card
    "readonly": true,
    "sender": {
      "id": "…",
      "name": "BlueEra",
      "profile_image": "https://…",
      "account_type": "ADMIN"
    },
    "created_at": "…"
  }
}
```

Broadcast **with a link + video**:

```jsonc
{
  "message": {
    "message": "Flat 20% off!\nhttps://blueera.ai/diwali",  // link appended to body
    "message_type": "video",
    "url": [
      { "url": "https://…/promo.mp4", "type": "video", "thumbnail": "https://…/thumb.jpg" }
    ],
    "title": "Diwali Offer 🎉",
    "link": "https://blueera.ai/diwali",
    "media_url": "https://…/promo.mp4",
    "media_type": "video",
    "media_thumbnail": "https://…/thumb.jpg",
    "image_url": "https://…/thumb.jpg",
    "category": "offer",
    "is_announcement": true,
    "metadata": { "…": "same values under metadata.*" }
  }
}
```

---

## 3. REST history parity

When the thread is loaded from history (GET messages), these fields come back
under **`message.metadata.*`** (they are persisted in the chat `message.metadata`
subdocument). The `title` and the `url` media array persist as real schema
fields; `link` is also appended into the `message` body text.

The socket payload now mirrors the same values under `metadata.*` **and** exposes
them flat. **Read from `metadata.*` for a single code path that works for both
live and history.** The flat keys are a convenience for live rendering.

---

## 4. Media array (`url[]`) — unchanged shape

Parsed today by `MessageMediaUrl.fromJson`
(`lib/features/chat/auth/model/messageMediaUrl.dart`):

```jsonc
{ "url": "https://…/promo.mp4", "type": "video", "thumbnail": "https://…/thumb.jpg" }
```

Images arrive as `type: "image"`; videos as `type: "video"` with a `thumbnail`.
No change needed — this already renders in `BroadcastMessageCard`.
> Note: `thumbnail` is not currently read by `MessageMediaUrl.fromJson`. Add it
> if you want to show a video poster frame (see §6).

---

## 5. Backward compatibility — verified

| Area | Verdict | Why |
|---|---|---|
| `Messages.fromJson` | ✅ Safe | Manual parser, `json['x']` access, ignores unknown keys, no codegen |
| `MessageMetadata.fromJson` | ✅ Safe | Same — already reads `title`/`category`, ignores the rest |
| `MessageMediaUrl.fromJson` | ✅ Safe | Ignores unknown item keys |
| FCM data handlers (`showFromData`) | ✅ Safe | `data['x'] ?? default` access |
| Existing message rendering | ✅ Unchanged | `message`, `message_type`, `url`, `sender` untouched |

**Net:** an un-updated app keeps working — admin broadcasts and payment messages
simply render as ordinary text/image/video bubbles (title/link/metadata ignored).
The steps below upgrade them to the full announcement card.

---

## 6. Frontend changes to render the announcement card

### 6.1 Model — expose `is_announcement`

`lib/features/chat/auth/model/GetListOfMessageData.dart`

In `Messages` add a field and read it in `fromJson`:

```dart
bool? isAnnouncement;
// …
isAnnouncement = json['is_announcement'] == true;
```

In `MessageMetadata` (same file) add the announcement fields (all optional,
tolerant — matches history):

```dart
final bool? isAnnouncement;
final String? broadcastId;
final String? link;
final String? body;
final String? mediaType;
final String? mediaThumbnail;
final String? imageUrl;
// …in fromJson:
isAnnouncement: json['is_announcement'] == true,
broadcastId: json['broadcast_id']?.toString(),
link: json['link']?.toString(),
body: json['body']?.toString(),
mediaType: json['media_type']?.toString(),
mediaThumbnail: json['media_thumbnail']?.toString(),
imageUrl: json['image_url']?.toString(),
// title + category already parsed.
```

Prefer reading from `metadata` (history + live both populate it):
```dart
bool get _isAnnouncement =>
    (message.isAnnouncement ?? false) ||
    (message.metadata?.isAnnouncement ?? false);
```

### 6.2 Routing — send announcements to `BroadcastMessageCard`

`lib/features/chat/view/widget/message_card.dart` — the card switches on
`widget.message.messageType` (line ~153). Backend announcements use
`text`/`image`/`video`, so add an **early check before the switch**:

```dart
// Admin broadcast / BlueEra announcement (payment + offer messages).
// message_type stays text/image/video; route on the is_announcement flag.
final isAnnouncement = (widget.message.isAnnouncement ?? false) ||
    (widget.message.metadata?.isAnnouncement ?? false);
if (isAnnouncement) {
  return BroadcastMessageCard(message: widget.message);
}
switch (widget.message.messageType) { … }
```

(The existing `case "broadcast":` can stay for any legacy `broadcast`-typed
messages; the backend does not emit that `message_type` — the schema enum has no
`"broadcast"` value — so the early check is what fires.)

### 6.3 Card — prefer `metadata.title` as headline

`lib/features/chat/view/widget/broadcast_message_card.dart` currently derives the
headline from the first line of `message.message`. The backend keeps the body
clean and puts the headline in `metadata.title`. Prefer it, fall back to the
first-line behaviour:

```dart
final metaTitle = message.metadata?.title?.trim() ?? '';
final title = metaTitle.isNotEmpty
    ? metaTitle
    : (newlineIdx == -1 ? body : body.substring(0, newlineIdx)).trim();
final description = metaTitle.isNotEmpty
    ? body                                   // whole body is the description
    : (newlineIdx == -1 ? '' : body.substring(newlineIdx + 1).trim());
```

Link chip: use `message.metadata?.link` when present, else keep the existing
`_firstBodyLink` regex fallback. Media already renders from `message.url`.

### 6.4 Optional — video poster in `MessageMediaUrl`

`lib/features/chat/auth/model/messageMediaUrl.dart` — read the thumbnail so
videos show a poster instead of a black tile:

```dart
thumbnail = json['thumbnail'];   // add `String? thumbnail;`
```

---

## 7. Payment messages — behaviour notes

- Delivered as BlueEra announcements in the same read-only announcement thread,
  `category: "payments"`, `broadcast_id: "<operation>:<userId>"`, no media/link.
- `title` / `body` examples:
  - Reminder → `"Pay Your Security Deposit"` / `"Pay your refundable ₹X security
    deposit to activate your account and start receiving orders."`
  - Deposit success → `"…"` / `"Your security deposit has been held."`
- Optional deep-link: you can route a "Pay Now" tap from these announcements to
  the deposit/subscription screen using `metadata.category == "payments"` +
  `broadcast_id` prefix (`security_deposit_reminder`, `subscription_charged`, …).
- Push + in-app for these operations are unchanged (data-only FCM handled by
  `app_notification.dart`), so the user still gets the existing push.

---

## 8. Test checklist

1. Fire `POST /admin/broadcast` (text only) → thread shows BlueEra announcement
   card with `title` headline; un-updated build shows a plain BlueEra text bubble
   (no crash).
2. Broadcast with an image URL and a YouTube/article link → image/preview + link
   chip render; link tappable.
3. Broadcast with a raw video URL → video tile with poster (needs §6.4).
4. Reload the thread from history → same card renders (fields read from
   `metadata.*`).
5. Trigger a security-deposit payment / reminder → BlueEra "payments"
   announcement appears in-thread, plus the usual push + in-app.

> Backend prerequisite for the chat leg of payment messages:
> `BROADCAST_SENDER_USER_ID` (a BlueEra ADMIN user id) must be set in the
> subscribe-service secret. If unset, payment push + in-app still deliver but the
> chat announcement is skipped.
