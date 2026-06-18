# Fix Task: Notification Tap Redirects

## Goal
Every push notification, when tapped, must redirect to a sensible in-app screen.
Today many operations dead-end (no navigation) or land on the wrong page. Fix all
of them. No notification tap may silently do nothing.

## Single file to edit
`lib/core/services/app_notification.dart`

Primary function: `_onTapNotificationFromStatusBar(...)` — the `switch (operation)`
starting at **line ~2115**. This is the canonical router (handles foreground tap,
background tap, and cold-start tap). Secondary mirrors that should stay consistent
but are NOT required for the redirect fix: `_handleActionButtonTap` (~line 1207)
and `_handleBackgroundNotificationResponse` (~line 146).

## How redirects work (context)
- Backend sends FCM `data.operation` (string) — see
  `be_notification_service/src/utils/firebaseNotification.js:720`.
- Frontend lowercases it: `final operation = (data['operation'] ?? '').toString().toLowerCase();`
- `switch (operation)` routes. Unmatched op → `default:` → **empty → no redirect**.
- Backend operation names = template keys in
  `be_notification_service/public/notification-templates.json`. Uppercase variants
  (e.g. `RIDE_ORDER_RECEIVED`) exist but lowercasing makes them match.

## Design rule
`NotificationScreen` (`RouteHelper.getNotificationScreenRoute()`) is the **universal
safe fallback** — it has no required route args and is the natural hub. Use it for
any operation without a better dedicated screen. Keep the existing good specific
redirects (chat, post detail, ride, call, symbol, AI chat). Make the `default:` case
route to `NotificationScreen` so nothing can dead-end.

⚠️ Do NOT route to `AppliedJobsScreen` — it requires a non-null `headerHeight` arg
and will crash when launched from a notification. Jobs → `NotificationScreen`.

⚠️ Leave `session_displaced` with NO navigation — it is a forced-logout signal, not
a tap target. Do not add it.

---

## Fixes required

### 1. Jobs — currently DEAD (empty `break`, no nav)
Operations: `new_application`, `application_status_updated`, `interview_scheduled`,
`interview_rescheduled`, `interview_cancelled`, `job_closed`, `new_feedback_submitted`,
`applied_for_job`
**Fix:** route to `NotificationScreen`. Replace the empty body with
`Get.toNamed(RouteHelper.getNotificationScreenRoute());`

### 2. Admin — currently DEAD (empty `break`, no nav)
Operations: `admin_bulk_notification`, `admin_system_announcement`, `admin_urgent_broadcast`
**Fix:** route to `NotificationScreen`.

### 3. `encrypted_message` — NOT handled, is a real chat message
**Fix:** add it to the chat-message case group alongside `sent_message` (so it runs
`_persistFcmMessageToLocal(data)` + `_openChatWithUser(data['senderId'] ?? '')`).

### 4. Missing ride ops — NOT handled (templates exist)
Operations: `ride_completed`, `ride_order_all_rejected`
**Fix:** add to the ride case group → `RouteHelper.getRiderServiceScreenRoute()`.

### 5. Rider association — NOT handled
Operations: `rider_association_request`, `rider_association_accepted`,
`rider_association_rejected`, `rider_association_dissociated`, `rider_association_expired`
**Fix:** route to `NotificationScreen`.

### 6. Symbol — only `symbol_created` handled
Operations: `symbol_viewed`, `symbol_liked`, `symbol_commented`
**Fix:** route to `NotificationScreen` (these reference an existing symbol; the
viewer needs full payload we don't have for these events, so the hub is correct).

### 7. Channels / tags — NOT handled
Operations: `channel_created`, `channel_claimed`, `channel_updated`,
`channel_verified_owner`, `channel_verified_follower`, `channel_deleted_owner`,
`channel_deleted_follower`, `channel_followed`, `channel_unfollowed`,
`channel_reported`, `channel_report_resolved`, `channel_moderation_action`,
`channel_profile_significant_update`, `channel_weekly_summary`
**Fix:** route to `NotificationScreen`.

### 8. Follower milestones / engagement — NOT handled
Operations: `follower_milestone_10`, `follower_milestone_50`, `follower_milestone_100`,
`follower_milestone_500`, `follower_milestone_1000`, `follower_milestone_5000`,
`follower_milestone_10000`, `follower_milestone_50000`, `follower_milestone_100000`,
`engagement_spike`
**Fix:** route to `NotificationScreen`.

### 9. Social / profile — NOT handled
Operations: `social_links_added`, `social_links_updated`, `social_links_removed`,
`bank_details_updated`, `experience_verification`, `profile_updated`,
`profile_completion_reminder`, `new_user`
**Fix:** route to `NotificationScreen`.

### 10. Reports — NOT handled
Operations: `reported_post`, `reported_reel`, `reported_message`
**Fix:** route to `NotificationScreen`.

### 11. Referrals — NOT handled
Operations: `process_referral`, `credit_referral_reward`
**Fix:** route to `NotificationScreen`.

### 12. `default:` case — currently empty
**Fix:** change `default:` body to `Get.toNamed(RouteHelper.getNotificationScreenRoute());`
so any future/unknown op still lands on the hub instead of dead-ending.

### 13. (Optional, lower priority) Reels & answered_question
`liked_reel`, `commented_on_reel`, `reposted_reel`, `tagged_in_reel`, `answered_question`
already go to `NotificationScreen`. Acceptable. Leave as-is unless a dedicated reel
viewer route is wired — do not invent one.

---

## Keep unchanged (already correct)
- `incoming_call` → `_openIncomingCallScreen`
- `missed_call` → chat with caller
- `fare_ride_incoming_call` → `_showRiderOrderScreen`
- `sent_message`, `message_reminder`, `tagged_in_message`, `commented_on_message`,
  `liked_message` → persist + open chat
- `send_morning_greeting`, `send_nightly_greeting` → `AiChatScreen`
- `created_post`, `liked_post`, `commented_on_post`, `reposted_post`, `tagged_on_post`,
  `reacted_to_post`, `reacted_to_comment`, `replied_on_comment` → `_handlePostNavigation`
- connection ops, `followed_profile`, `user_enrolled` → `NotificationScreen`
- all `ride_order_*`, `ride_started`, `ride_cancelled_by_rider`,
  `ride_payment_confirmed`, `rider_onboarding_complete` → `RiderServiceScreen`
- `selfpickup_order`, `selfpickup_order_ready` → chat
- `symbol_created` → `_openSymbolFromNotification`

---

## Acceptance criteria
1. No `case` in the switch has an empty body except `session_displaced` (which must
   have NO navigation — add it as an explicit no-op `break;` with a comment, or leave
   it unhandled deliberately).
2. `default:` routes to `NotificationScreen`.
3. Every operation key present in
   `be_notification_service/public/notification-templates.json` either has a
   dedicated redirect or falls through to `NotificationScreen` via an explicit case
   or the default — confirm by cross-checking the template key list against the switch.
4. No route is given that requires non-null arguments the payload doesn't carry
   (no crashes). Specifically: do not use `AppliedJobsScreen`.
5. `flutter analyze` passes with no new errors.
6. Existing correct redirects (listed above) are unchanged.

## Verification step
After editing, list the template keys and grep the switch to prove coverage:
```bash
# template operation keys
node -e "const t=require('./be_notification_service/public/notification-templates.json'); console.log(Object.keys(t).join('\n'))" | sort -u > /tmp/ops.txt
# operations referenced in the switch
grep -oE "case '[a-z_]+'" lib/core/services/app_notification.dart | sed "s/case '//;s/'//" | sort -u > /tmp/handled.txt
# any template op NOT handled (should only be intentional ones like session_displaced)
comm -23 /tmp/ops.txt <(tr 'A-Z' 'a-z' < /tmp/handled.txt | sort -u)
```
Anything that prints must be intentional (e.g. `session_displaced`) or covered by `default:`.
