# Flutter bugs — account deletion & deleted-user rendering

Handoff for the BlueEra_flutter developer. Repo: `C:\BlueEra\BlueEra_flutter`

Backend work has changed two contracts in `be_user_service`. The app needs three
changes. Bug 1 and 2 are behavioural and will show wrong information to users;
bug 3 is cosmetic but on the same code path.

Backend reference: `be_user_service/docs/ACCOUNT_DELETION_CROSS_SERVICE.md`

---

## BUG 1 — "already in progress" is shown for unrelated 409s (HIGH)

**File:** `lib/features/common/account_deletion/controller/account_deletion_controller.dart`
**Lines:** 127-129

```dart
case 409:
  commonSnackBar(message: AppStrings.accountDeletionAlreadyPending.tr);
  break;
```

**Problem.** The handler branches on the HTTP status code alone and never reads
the `code` field in the body. `POST /user/account/deletion/init` now returns 409
for **two unrelated reasons**:

| `code` | Meaning |
|---|---|
| `already_pending_deletion` | A deletion is genuinely in progress (existing) |
| `deletion_blocked` | **NEW** — blocked by wallet balance, in-flight order, or active subscription |

So a user who cannot delete because they hold ₹240 in their wallet is told
*"A deletion request is already in progress for your account."* That is wrong,
and it hides the backend's per-reason messages, which are already written and
localisation-ready.

**`deletion_blocked` response body:**

```json
{
  "success": false,
  "code": "deletion_blocked",
  "message": "Your account can't be deleted yet. Please resolve the items below and try again.",
  "blockers": [
    { "type": "wallet_balance",      "amount": 240, "message": "You have ₹240 in your wallet. Withdraw it before deleting your account." },
    { "type": "active_order_buyer",  "count": 2,    "message": "You have 2 order(s) still in progress. Wait for them to be delivered or cancel them first." },
    { "type": "check_unavailable",   "service": "wallet", "message": "We couldn't check your wallet balance right now. Please try again in a few minutes." }
  ]
}
```

`blockers` is always a non-empty array when `code == "deletion_blocked"`. Every
entry has a human-readable `message`. Possible `type` values: `wallet_balance`,
`pending_balance`, `pending_withdrawal`, `active_order_buyer`,
`active_order_seller`, `active_subscription`, `active_account_plan`,
`check_unavailable`.

**Fix.** Inside `case 409:`, read `code` from the body and branch:

- `already_pending_deletion` → keep the current snackbar
- `deletion_blocked` → show a **dialog listing every `blockers[].message`**, not a
  snackbar; there can be several and a snackbar truncates
- anything else / missing `code` → fall back to the current snackbar

`check_unavailable` means a backend dependency was unreachable, not that the user
did something wrong. "Try again in a few minutes" is the right tone — do not tell
them to go withdraw money.

Note the body may arrive as a `String` needing `jsonDecode`, exactly as the 200
branch already handles at lines 115-119. Reuse that pattern.

**Timing.** This only misfires once the backend change is deployed. Today `/init`
only ever returns 409 for `already_pending_deletion`, so the current code is
correct until then. Ship this before or with the backend release.

---

## BUG 2 — no handling for deleted users anywhere (HIGH)

**Files:** every screen rendering another user — chat list, chat thread,
profile, comments, followers, search results.
**Confirmed:** `grep -rn "is_deleted" lib/` returns **no matches**. (The
`isDeleted` fields under `Discover/`, `food/` etc. are camelCase, belong to
product/business payloads, and are unrelated.)

**Problem.** When an account is hard-deleted, the backend no longer removes the
reference — it returns a **tombstone**, so old chats and orders still resolve.
The `User` gRPC message gained `bool is_deleted = 48`, surfaced on every user
payload. A tombstone looks like:

```json
{
  "id": "6a1fbcc215d42caef618aa0d",
  "name": "Deleted User",
  "is_deleted": true,
  "account_type": "INDIVIDUAL",
  "deleted_at": "2026-09-17T02:00:00.000Z",
  "contact_no": "", "email": "", "profile_image": "", "username": ""
}
```

Every other field is blank — proto3 has no null, so absent strings are `""`,
numbers `0`, booleans `false`. **`id` still resolves**, which is what keeps the
other person's chat history readable.

Because the app has no concept of this, it will currently let a user tap into a
deleted account's profile, start a new chat, or place a call against an id that
no longer belongs to anyone.

**Fix.**
1. Add `is_deleted` (JSON key is snake_case `is_deleted`) to the user model(s)
   used by chat, profile and search. Default it to `false` when absent, so older
   API responses keep working.
2. Where `is_deleted == true`:
   - render the name as "Deleted User" — the backend already sends this, so
     prefer a **localised string** rather than the server text
   - show the default person placeholder, never the avatar
   - **disable** tap-through to profile, "message", "call", and any
     order/enquiry action
   - keep existing messages visible — do not hide history

Do **not** treat a deleted user as an error or filter them out of the chat list;
that would make the conversation vanish for the surviving participant.

**Related:** after the 365-day retention window the backend stops returning the
user at all (gRPC `NOT_FOUND`, or absent from a batch lookup). Treat a
**missing** user the same as `is_deleted: true` so the UI degrades identically.

---

## BUG 3 — empty `profile_image` string is not treated as "no image" (MEDIUM)

**File:** `lib/widgets/cached_avatar_widget.dart`
**Line:** 38

```dart
child: (imageUrl != null)
```

**Problem.** The guard only catches `null`, not `""`. A tombstone sends
`profile_image: ""` (again, proto3 cannot send null), so this branch is entered
with an empty URL. `CachedNetworkImage` then fails and falls through to
`errorWidget`, which draws `Icon(Icons.person)` — so it degrades acceptably — but:

- every deleted-user avatar does a pointless failed image load and logs an error
- worse, when `showProfileOnFullScreen` is true, **tapping opens `ImageViewScreen`
  with `imageUrls: [""]`** (line 46) — a blank full-screen viewer

This is not specific to deleted users: any API returning `""` for an image hits
it today.

**Fix.** Change the guard to treat empty/whitespace as absent:

```dart
child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
```

Then check the sibling widgets for the same pattern:
`common_circular_profile_image.dart`, `profile_avatar_widget.dart`,
`fallback_network_image.dart`, `user_profile_widget.dart`.

---

## Quick verification

Without a deleted account to hand, stub it:

1. **Bug 1** — have the API layer return a fake 409 with
   `{"code":"deletion_blocked","blockers":[{"type":"wallet_balance","amount":240,"message":"You have ₹240 in your wallet…"}]}`
   and confirm the wallet message appears, not "already in progress".
2. **Bug 2** — force `is_deleted: true` on one user in a chat list response;
   confirm the row reads "Deleted User", shows the placeholder, and message/call
   are disabled while history stays readable.
3. **Bug 3** — set `profile_image: ""`; confirm the placeholder renders with no
   failed network request, and that tapping does nothing.
