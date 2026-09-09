# "Contact Joined BlueEra" on Guest Signup + Chat "View Profile" — Backend Status & Frontend Guide

Covers two asks:

1. **Backend** — "notify my contacts when someone in my phonebook creates a
   **guest** account (not only when they finish a full profile)."
2. **Frontend (Flutter)** — tapping that notification should **open the chat**
   with that user, and because the chat starts empty (it shows the default
   "Namaste 🙏" prompt), show a small **View Profile** button at the top-centre.

> ⚠️ **Read §2 first.** There are **two** independent "joined BlueEra" systems in
> production, and **guest signup already fires one of them.** Understanding this
> avoids duplicate notifications and an accidental reversal of a documented
> safety rule.

---

## 1. TL;DR

| | System A — Enrollment | System B — Contact Directory |
|---|---|---|
| Operation | **`user_enrolled`** | **`contact_joined`** |
| Emitted by | `be_user_service` → `utils/enrollmentNotification.js` | `be_user_service` → `utils/accountFinalizedEvent.js` → **`be_contact_service`** |
| Fires when | **Guest signup** (`createGuestAccount`) **and** direct real-account create (`addUser`) | **Account finalisation only** (GUEST → INDIVIDUAL/BUSINESS) |
| Contact source | **chat-service** contacts (`GetContactsByContactNo` gRPC) | **be_contact_service phone directory** (phonebook uploads) |
| Guest included? | ✅ **Yes** | ❌ **No — blocked by a triple-enforced "guest rule"** |

**So the backend already notifies contacts on guest signup — via `user_enrolled`.**
If it isn't reaching people, the cause is almost certainly the **contact source**
(System A reads the *chat-service* contact store; if phonebooks now live in
*be_contact_service*, System A finds no matches). See §3.

**We intentionally do NOT make `contact_joined` fire on guests** (§4) — that
reverses a documented rule and causes real harm (spam + a latch that would then
suppress the *real* profile announcement). Extending it is possible but is a
product decision, laid out in §4.

---

## 2. How "X joined BlueEra" works today

### System A — `user_enrolled` (already covers guests)
`be_user_service/src/utils/enrollmentNotification.js`:
- `notifyContactsOnEnrollment({ id, name, contact_no })`
- Called from:
  - `createGuestAccount` (`user.controller.js:~4222`) → **guest signup** ✅
  - the direct real-account create path (`user.controller.js:~1332`)
- Looks up everyone who saved this number via the **chat service**
  (`getContactsByContactNo`), then emits one `notification.service` message per
  recipient with `operation: "user_enrolled"`, using the **recipient's saved
  name** ("Rahul just joined Blue Era!").

### System B — `contact_joined` (finalisation only, by design)
`be_user_service/src/utils/accountFinalizedEvent.js` publishes
`USER_ACCOUNT_FINALIZED` to the `user.lifecycle` topic **only for real accounts**;
`be_contact_service` consumes it (`kafka/handlers/userAccountFinalized.handler.js`
→ `services/contactJoinNotifier.service.js`) and fans out `contact_joined` using
its **own phone directory** with proper idempotency and WhatsApp-style saved-name
grouping.

The **guest rule** is enforced in **three** places and documented at each:
1. `accountFinalizedEvent.js` — refuses to publish for `GUEST`.
2. `userAccountFinalized.handler.js` — refuses to announce non-real account types.
3. The phone-directory `announced_at` latch — a number is announced **once ever**.

---

## 3. Backend: guest-signup notification — current state & what to verify

**No code change is required for guests to be notified — the path exists.** What
to verify (in this order) if contacts are not receiving it on guest signup:

1. **Is `user_enrolled` being emitted?** Check `be_user_service` logs for
   `ENROLLMENT NOTIFICATION TRIGGERED` right after a guest signup. If absent, the
   `notifyContactsOnEnrollment` call in `createGuestAccount` is not running
   (confirm the guest was newly created — it early-returns if the user exists).
2. **Does it find recipients?** Look for
   `No existing contacts found for this number` vs
   `Notified N contact(s)`. If it always says "no contacts", System A is reading
   an **empty/stale chat-service contact store** — this is the likely root cause.
3. **Is the template present?** `public/notification-templates.json` and
   `public/in-app-notifications.json` both contain `user_enrolled` ✅ (verified).
4. **Preferences:** `user_enrolled` is category `user_enrolled`, so a recipient
   who muted that category won't get it (expected).

### If the root cause is the contact source (step 2)
System A queries the **chat service**; the authoritative phonebook may now be in
**be_contact_service**. Two safe fixes (no guest-rule reversal):
- **Preferred:** point `notifyContactsOnEnrollment` at be_contact_service's
  contact lookup instead of (or in addition to) the chat-service gRPC, so guest
  signups match the same directory `contact_joined` uses. This keeps guests on
  System A (`user_enrolled`) but with the correct, populated data source.
- Or backfill/keep the chat-service contact store in sync.

> This is a data-source correction, not a behaviour reversal — safe to ship.

---

## 4. (OPTIONAL) Make the robust `contact_joined` pipeline fire on guests

**Only do this with explicit product sign-off.** It reverses the documented
guest rule. Consequences you are accepting:

- **Temporary accounts get announced.** A guest who never completes signup will
  still have "X joined BlueEra" sent to everyone who has their number.
- **The `announced_at` latch means announce-once.** If you announce at guest
  time, the later **finalisation announcement is skipped** — contacts are told
  about the guest and never again about the completed profile. (Arguably fine if
  you want the *earliest* "joined" signal, but it is a behaviour change.)
- **Possible duplication with System A** — a guest signup would then trigger both
  `user_enrolled` (System A) and `contact_joined` (System B). You'd want to drop
  one to avoid two "joined" pushes.

If accepted, the change is:
1. `be_user_service/src/utils/accountFinalizedEvent.js` — allow `GUEST` (remove it
   from the `REAL_ACCOUNT_TYPES` gate, or add a separate `emitGuestJoined`), and
   call it from `createGuestAccount`.
2. `be_contact_service/src/kafka/handlers/userAccountFinalized.handler.js` — relax
   `isRealAccountType` gate for the guest case.
3. Decide the latch policy: keep announce-once (guest wins) **or** allow a second
   announcement on finalisation (requires a schema/idempotency change in the
   phone directory — non-trivial).
4. Remove the System A `user_enrolled` call on guest signup to avoid duplicates.

**Recommendation:** don't reverse System B. Use §3 (fix System A's data source)
so guests are notified through the path already built for them.

---

## 5. Frontend (Flutter) guide — open chat + "View Profile" button

Applies to **both** `contact_joined` and `user_enrolled` (treat them the same —
both mean "someone you know joined").

> No backend change is needed for this section — the payload already carries
> everything the app needs.

### 5.1 Payload the app receives (FCM `data`)

| Field | `user_enrolled` | `contact_joined` | Use |
|---|---|---|---|
| `senderId` | ✅ joiner's userId | ✅ joiner's userId | **open chat / open profile** |
| `senderName` | ✅ saved name | ✅ saved name | display |
| `new_user_id` | ✅ | — | same as `senderId` |
| `contactUserId` | — | ✅ | same as `senderId` |
| `operation` | `user_enrolled` | `contact_joined` | routing |

**The peer user id is `data['senderId']`** for both (fall back to
`new_user_id` / `contactUserId` if ever absent).

### 5.2 Route the tap to the chat (not the notification hub)

Today both operations fall into `Get.toNamed(RouteHelper.getNotificationScreenRoute())`.
File: `lib/core/services/app_notification.dart`, in `routeNotificationData`'s
`switch (operation)`.

Change the two cases to open the chat via the existing helper `_openChatWithUser`
(the same one `sent_message` uses):

```dart
// lib/core/services/app_notification.dart  (reference — apply in the Flutter app)
case 'user_enrolled':
case 'contact_joined': {
  final peerId = (data['senderId'] ??
                  data['contactUserId'] ??
                  data['new_user_id'] ?? '').toString();
  if (peerId.isNotEmpty) {
    _openChatWithUser(peerId);          // opens PersonalChatScreen for that user
  } else {
    Get.toNamed(RouteHelper.getNotificationScreenRoute()); // safe fallback
  }
  break;
}
```

Cold start, background, and foreground taps all funnel through
`routeNotificationData`, so this one change covers every state.

### 5.3 "View Profile" button in the empty chat

`lib/features/chat/view/personal_chat/personal_chat_screen.dart`, the
`if (messages.isEmpty) { ... }` block (~line 278) that currently renders the
**"No conversation yet. Say Namaste 🙏"** prompt.

The peer's id is already on the screen as **`widget.userId`** (and
`widget.name` / `widget.profileImage`). Add a small **View Profile** button
**above** the Namaste prompt, centred at the top:

```dart
// reference layout — replace the single Center(child: InkWell(...)) with:
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // ── small "View Profile" pill at top-centre ──
    if ((widget.userId ?? '').isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: OutlinedButton.icon(
          onPressed: () => _openPeerProfile(widget.userId!), // see below
          icon: const Icon(Icons.person_outline, size: 16),
          label: const Text('View Profile'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    // ── existing "Say Namaste" prompt (unchanged) ──
    InkWell(
      onTap: () { /* existing sendInitialMessage(...) code */ },
      child: /* existing container */,
    ),
  ],
)
```

For `_openPeerProfile`, reuse the app's existing profile-visit navigation
(the resolver at `lib/core/navigation/visit_profile_resolver.dart`, or whatever
`view_profile_*` notification actions already route to) so a contact's profile
opens by `userId`. Do **not** invent a new route — call the same one the rest of
the app uses to open another user's profile.

> If you want the button on **every** empty chat (not just contact-joined ones),
> this placement already achieves that, since it keys off `widget.userId`. If it
> should appear **only** for contact-joined chats, pass a flag when
> `_openChatWithUser` is invoked from the notification tap and gate the button on it.

---

## 6. Testing

**Backend (guest notification):**
1. Ensure user B has user A's number saved (in whichever contact store System A
   reads — see §3).
2. Create a guest account for user A (`createGuestAccount`).
3. Confirm `be_user_service` logs `ENROLLMENT NOTIFICATION TRIGGERED` and
   `Notified 1 contact(s)`, and user B receives a `user_enrolled` push.

**Frontend (tap → chat → View Profile):**
1. Tap the "joined BlueEra" push from the notification tray.
2. App opens `PersonalChatScreen` for the joiner.
3. Chat is empty → the **View Profile** button shows top-centre above "Say Namaste".
4. Tapping it opens the joiner's profile.

---

## Summary

- **Guest signup already notifies contacts** via `user_enrolled` — no reversal
  needed. If it's not arriving, fix the **contact data source** (§3), not the
  guest rule.
- **Do not** make `contact_joined` fire on guests without product sign-off (§4).
- **Frontend:** route `contact_joined` / `user_enrolled` taps to
  `_openChatWithUser(senderId)`, and add a **View Profile** button to the empty
  chat's Namaste state (§5). No backend change required for the frontend part.
