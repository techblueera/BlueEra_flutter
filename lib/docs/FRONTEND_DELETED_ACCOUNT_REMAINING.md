# Deleted-account handling — what's left on Flutter

Handoff for the BlueEra_flutter developer. Repo: `C:\BlueEra\BlueEra_flutter`

**Read this first: nothing here is outstanding any more.** An earlier handoff
(`FRONTEND_ACCOUNT_DELETION_BUGS.md`) listed three bugs; all three were already
fixed when this document was written on 2026-09-21. The three items it then
raised — the missing locale strings, the search and call surfaces, and treating
a missing user as a deleted one — landed the same day. Each section below now
records what was done and why, so the next person reads the reasoning rather
than re-deriving it.

Do not re-implement anything in this document. The behaviour is covered by
`test/account_deletion_and_tombstone_test.dart`.

---

## Already done — do not redo

| Item | Where | Status |
|---|---|---|
| 409 split: `already_pending_deletion` vs `deletion_blocked` | `account_deletion_controller.dart` ~line 129 | ✅ parses `DeletionBlockedResponse`, renders per-blocker messages |
| `is_deleted` on chat models | `GetChatListModel.dart:500`, `GetListOfMessageData.dart:1403` | ✅ `parseIsDeleted()` |
| "Deleted Account" in the chat app bar status line | `component_widgets.dart:2130` | ✅ branches on `isDeleted` before online/offline |
| Block profile tap-through | `chat_profile_navigation.dart:74` | ✅ `blockDeletedUserAction()` |
| Hide the message input | `business_chat_screen_updated.dart:447` | ✅ |
| Group member placeholder avatar | `group_members_list.dart:65` | ✅ |
| Comment author / replier | `comment_bottom_sheet.dart:263` | ✅ |
| Empty `profile_image` treated as absent | `cached_avatar_widget.dart:38` | ✅ |

The backend side is deployed and verified in production: a real re-emit cleared
344 leftover references down to 96, and the 96 that remain are deliberate
(financial records, and the counterparty's call history).

---

## 1. Five strings existed in only ONE of 20 locales — DONE

`AppStrings.<key>.tr` with GetX falls back to **the key itself** when a locale
is missing the entry, so a Hindi, Bengali, Gujarati, Tamil or Marathi user
opening a chat with a deleted account saw the literal text
`deletedUserUnavailable` in the app bar instead of a sentence.

All five keys are now in all 20 shipped locale files (`ta_demo.json` and
`test.json` are demo/test fixtures and stay out, matching the older deletion
strings). `hi.json` carries real Hindi; the other 18 carry the English text,
which is what every one of them already does for
`accountDeletionAlreadyPending` and friends — one convention, not two.

One wording change came with it: `deletedUser` now reads **"Deleted Account"**
rather than "Deleted User". The account is what went, and it is the noun the
rest of the deletion copy (`deletedUserUnavailable`,
`deletedUserCannotMessage`) already uses.

The check from the original handoff prints nothing:

```bash
for f in assets/translations/*.json; do
  case "$f" in *ta_demo*|*test*) continue;; esac
  for k in accountDeletionBlockedTitle accountDeletionBlockedIntro \
           deletedUser deletedUserCannotMessage deletedUserUnavailable; do
    grep -q "\"$k\"" "$f" || echo "MISSING $k in $f"
  done
done
```

---

## 2. Surfaces that didn't branch on `is_deleted` — DONE

**Search results** — `SearchResultItem` now parses `is_deleted` (accepting
`isDeleted` too) and exposes `isDeletedAccount`, which is true for a `user` or
`business` row that is flagged **or** has no title at all. `SearchResultCard`
renders that row as the tombstone with the placeholder avatar, and
`_openResult` stops on it via `blockDeletedUserAction()`.

Person rows only: an untitled *product* is a catalogue defect, not a deleted
account, and keeps its existing "Untitled" treatment.

> This stays defence-in-depth, as the backend note said — a deleted user is
> removed from the index on deletion. It earns its place because the index
> lags and a backfill can reintroduce a stale row.

**Call screens** — `call_history_screen.dart` now names a gone peer as the
tombstone, drops their avatar, greys the call button and stops both
`_showCallPicker` and `_placeCall` with `blockDeletedUserAction()`. The button
stays tappable on purpose: the tap is what explains why nothing happens.

A conversation the chat list hasn't loaded is explicitly *not* this — no
sender means nothing was looked up, and the row keeps its "Unknown" label.

The chat app bar's call button was already blocked (`component_widgets.dart`,
the `disableCallButton || isDeleted` branch).

---

## 3. A MISSING user is treated like a deleted one — DONE

After the 365-day retention window the backend stops returning the account at
all — gone from the archive too, so gRPC answers `NOT_FOUND` and batch lookups
omit it. There is no `is_deleted: true` to read, because there is no record
left to set it on. What the client sees is an id and a row of blanks.

`lib/core/constants/deleted_user.dart` gained two pieces:

- `isBlankUserField(v)` — `null`, `""`, whitespace and the stringified
  `"null"` all count as blank.
- `isDeletedOrMissingUser({isDeleted, name, fallbacks})` — the flag, OR a name
  and *every* fallback identity blank. One surviving identity (a number, a
  username, a business name) means somebody is still there.

`displayUserName` takes `blankMeansDeleted` for the same reason. It is opt-in,
and deliberately so: a screen still fetching its user has blank fields too,
and must not accuse a live account of being deleted. The chat app bar passes
it; the visiting-profile screen does not.

Each model that renders another user now carries an `isDeletedOrGone` getter
built on that helper, and the widgets read the getter instead of the raw flag:

| Model | Fallback identities | Read by |
|---|---|---|
| `GetChatListModel.Sender` | contact_no, username | chat list row, call history |
| `GetListOfMessageData.Sender` | contact_no, username | group message byline |
| `GroupMembersListModel` | contact | group member list + sheet |
| `CreatedBy` (comments) | business_name, username | comment/reply tile |
| `User` (feed posts) | business_name, username | post byline |
| `FollowingFollower` | business_name, username | follower/following row |

Group rows and order threads are exempt in the chat list: they are identified
by the group or the order, never by the embedded sender, so an empty sender on
one of those means nothing.

---

## Contract reference

A tombstoned user arrives like this on every user payload:

```json
{
  "id": "6a8e73a5f1331440ed37bdd9",
  "name": "Deleted User",
  "is_deleted": true,
  "account_type": "BUSINESS",
  "deleted_at": "2026-09-21T05:30:05.291Z",
  "contact_no": "", "email": "", "profile_image": "", "username": ""
}
```

Two things that trip people up:

- **`id` still resolves.** That is deliberate — it is what keeps the other
  person's chat history readable. Do not filter deleted users out of the chat
  list; the conversation would vanish for the surviving participant.
- **Blank, not null.** proto3 has no null, so absent strings arrive as `""`,
  numbers as `0`, booleans as `false`. Guard on empty, not just null.

**The chat header name usually comes from the viewer's own phonebook**
(`contacts.name` in chat-service), so it keeps showing whatever they saved —
same as WhatsApp — and the status line is the right place for the deleted
signal. But a peer the viewer never saved, whose account is then gone, leaves
the header with nothing at all: no name, no number. That is the case
`blankMeansDeleted` covers, and the header reads "Deleted Account" rather than
rendering an empty line.
