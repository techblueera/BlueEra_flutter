# Inactive-account data purge — Flutter integration guide

**Audience:** BlueEra Flutter app team
**Backend status:** built and merging now. **It is live from the day it
deploys — nobody flips a switch.** See §8.
**App status:** two screens and one API call required — §4 and §5

---

## 1. What is changing, in one paragraph

An account that goes untouched for **90 days** has its *content* erased across the
whole platform — posts, videos, orders, chats, business profile, documents, saved
addresses, media on S3, everything. **The account itself survives.** The same
phone number logs in exactly as before and lands on a real, empty profile. This
is not account deletion: `/user/account/deletion` is a different flow with its
own OTP and grace period, and it is unaffected.

Seven days before the purge the user gets one push notification. Opening the app
at any point resets the 90-day clock and cancels everything.

For the app this means exactly two new situations to handle:

1. A returning user whose data is **already gone** — their profile is blank and
   you must explain why instead of looking broken.
2. A user who is **about to be purged** — show a banner so they can save
   themselves by doing nothing more than opening the app.

---

## 2. Why the app has to do anything at all

Without a change, a purged user logs in successfully and sees an account with no
name-beyond-the-basics, no posts, no orders and no chats. That is
indistinguishable from "the app is broken" or "I'm in someone else's account",
and it will generate support tickets and one-star reviews.

The backend cannot solve this on its own: the account is deliberately valid, so
there is nothing for login to reject. The app needs to ask one question after
login and branch on the answer.

---

## 3. What survives the purge

Useful for deciding what your screens can rely on.

| Kept | Cleared |
|---|---|
| `_id`, `contact_no`, `username` | `profile_image`, `coverPicture`, `introVideo`, `qr_url` |
| `name`, `pre` (title) | `bio`, `email`, `date_of_birth`, `gender` |
| `account_type` (INDIVIDUAL / BUSINESS) | `profession`, `designation`, `city`, `pincode`, `address` |
| `language` | `skills`, `projects`, `experiences`, `objective` |
| `referral_code`, `referral_points`, `referred_by` | `social_links`, `user_location`, `marketing_card` |
| `created_at` | `device_token`, `voip_token` — **re-register FCM on next launch** |

Everything in every other service is gone: business profile, availability,
resume, followers, ratings, testimonials, KYC documents, posts, videos, orders,
chat history, saved addresses, emergency contacts.

> **One deliberate exception: money.** Wallet balance and transactions, reward
> earnings, rider cashback, invoices and active subscriptions are **kept** — a
> balance is the user's money, not their data, and since the account survives
> the money survives with it. Everything else goes, including orders, bookings
> and appointments.
>
> For the app that means: **a purged user may still have a wallet balance and an
> active subscription, but no order history.** Don't assume the two are
> consistent — a non-empty wallet with an empty orders list is a valid state.

**Note the push tokens.** `device_token` and `voip_token` are cleared, so a
purged user will not receive notifications until the app re-registers its FCM
token. Do that on the first launch after you see `data_purged: true`.

---

## 4. The one API you need

### `GET /api/user-service/user/account/inactivity/status`

Auth: standard `Authorization: Bearer <jwt>`. Call it **once right after login**
and on app resume.

Calling this endpoint also counts as activity, so it doubles as the "I'm alive"
ping — a user who opens the app is taken out of the purge cohort by this call
alone, even if every other signal fails.

**Response**

```json
{
  "success": true,
  "data_purged": true,
  "data_purged_at": "2026-06-14T05:10:33.120Z",
  "purge_count": 1,
  "last_activity_at": "2026-03-16T09:22:41.000Z",
  "inactive_days": 90,
  "threshold_days": 90,
  "warning_lead_days": 7,
  "days_until_purge": 0,
  "show_warning": false,
  "warning_sent_at": "2026-06-07T04:10:02.881Z"
}
```

| Field | Use it for |
|---|---|
| `data_purged` | **Branch on this.** `true` → show the "your data was removed" screen (§5.1). |
| `days_until_purge` | Copy for the warning banner: "… in N days". |
| `show_warning` | **Branch on this.** `true` → show the warning banner (§5.2). |
| `threshold_days`, `warning_lead_days` | Display only. Do **not** hardcode 90 or 7 — retention policy is server-side config and can change without an app release. |
| `purge_count` | Diagnostics. A user can be purged more than once over their lifetime. |

Do not compute `show_warning` yourself from `inactive_days`. Read the flag.

### `POST /api/user-service/user/account/inactivity/acknowledge`

Call this after the user taps through the "your data was removed" screen.
It clears `data_purged` so the screen does not reappear on every launch.

```json
{ "success": true, "acknowledged": true }
```

The audit trail on the backend is permanent, so nothing is lost by clearing it.

---

## 5. The two screens

### 5.1 "Your data was removed" — when `data_purged == true`

Show this **once**, immediately after login, before the home screen. Then call
`/acknowledge` and route the user into the normal profile-completion flow —
the same one a new user sees, because functionally that is what they now are.

Suggested copy:

> **Welcome back**
> You hadn't used BlueEra for over 90 days, so we removed your data as part of
> our data-retention policy. Your account and phone number are safe — let's set
> your profile up again.
> `[ Set up my profile ]`

What to do in code:

1. `data_purged == true` → push the screen above.
2. On tap → `POST /inactivity/acknowledge`.
3. Re-register the FCM token (it was cleared — see §3).
4. Route to profile setup. **Do not** send them to the guest/registration flow:
   they already have an account and `account_type` is intact. Use the same
   screens an existing user gets for editing an empty profile.
5. Clear every local cache you keep — Hive boxes, SharedPreferences profile
   blobs, cached chat lists, cached feeds. Stale local data over a purged
   server account is the one way to make this genuinely confusing.

### 5.2 "Your data will be removed" — when `show_warning == true`

A dismissible banner on the home screen. The user does **not** have to do
anything — simply having opened the app has already reset their clock — so the
copy should reassure, not alarm.

> Your BlueEra data will be removed in **{days_until_purge} days** of inactivity.
> Opening the app keeps everything — you're all set.

There is also a push notification (§6) carrying the same message.

---

## 6. The push notification

Sent once, 7 days before the purge, via the existing notification pipeline.

```json
{
  "operation": "inactivity_purge_warning",
  "title": "Your Blue Era data will be removed soon",
  "body": "You haven't used Blue Era for a while. In 7 day(s) your posts, videos, orders, chats and profile details will be permanently deleted. Your account stays — just open the app to keep everything.",
  "data": {
    "days_until_purge": 7,
    "warning_lead_days": 7,
    "purge_at": "2026-06-14T00:00:00.000Z",
    "deep_link": "blueera://account/inactivity"
  }
}
```

Handle `operation == "inactivity_purge_warning"`: tapping it should open the app
(which itself cancels the purge) and land on the home screen with the §5.2 banner
visible. Register the `blueera://account/inactivity` deep link.

---

## 7. What does NOT change

- No change to login, OTP, or session handling.
- No change to `/user/account/deletion` — that flow is untouched.
- No new required fields on any existing response.
- Every existing endpoint keeps its current contract. A purged user simply gets
  empty lists and null fields from them, which your existing empty states should
  already handle — **please verify that they do**, especially feed, orders and
  chat list, which are the three most likely to assume at least one row.

---

## 8. Rollout — what is live when

**Please ship your side before the backend deploys, not after.**

The backend is live from the day it deploys. There is no waiting period and no
switch for anyone to flip — the first nightly sweep runs that night.

Who it can touch on night one is narrow, and deliberately so. An account is
only purged when the backend has **real evidence** it has been dormant 90+
days (a live session record showing the last request). Accounts it has never
observed are dated "today" when the backend runs its backfill, so they get a
full 90 days and a warning at day 83 before anything happens to them.

But "narrow" is not "none". Some users will be purged in the first week.

| | |
|---|---|
| Before backend deploys | Ship §5.1 and §5.2. They are dead code — the API returns `false` for both flags until a real purge happens. |
| After backend deploys | Real values start arriving. |

If your side is not ready, ask backend to run
`PUT /admin/inactivity/mode {"mode":"off"}` — it stops the sweep immediately,
no deploy needed. Better to ask for that than to have the first purged user be
the one who discovers the screen is missing.

### Testing it before you ship

Ask backend to run, against staging, for a specific test account:

```
POST /api/user-service/admin/inactivity/purge/<userId>
{ "dry_run": true }     # counts what would go, deletes nothing
{ "confirm": true }     # actually purges that one account
```

That gives you a real purged account to test §5.1 against without waiting 90 days
or touching anyone else.

---

## 9. Checklist

- [ ] Call `/user/account/inactivity/status` after login and on resume
- [ ] `data_purged == true` → §5.1 screen → `/acknowledge` → profile setup
- [ ] Re-register FCM token after a purge (tokens are cleared server-side)
- [ ] Clear all local caches after a purge
- [ ] `show_warning == true` → §5.2 home banner
- [ ] Handle push `operation: "inactivity_purge_warning"`
- [ ] Register deep link `blueera://account/inactivity`
- [ ] Read `threshold_days` / `warning_lead_days` from the API, never hardcode
- [ ] Re-check empty states on feed, orders and chat list
