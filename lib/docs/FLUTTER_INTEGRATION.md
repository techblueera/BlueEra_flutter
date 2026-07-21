# Flutter Integration Guide — Contacts & "Contact Joined"

Written against the actual BlueEra Flutter app (`C:\BlueEra\BlueEra_flutter`), using its existing
conventions: `BaseService` mixins, `ApiBaseHelper`, `ResponseModel`, GetX + `ApiResponse`,
`LocalStorageHelper`, and `AppNotificationHandler`.

---

## ⚠️ 0. READ THIS FIRST — do not change the existing contact sync

The app already syncs contacts to the **chat service**:

| | |
|---|---|
| Endpoint | `POST chat-service/connections/sync` |
| Constant | `connectionsSync` in `lib/core/api/apiService/chat_service_api.dart` |
| Owner | `ChatViewRepo` → `ChatViewController.uploadContacts()` / `refreshContacts()` |
| Triggered | `ConnectMainPage.initState` → `_syncContactsIfNeeded()` |
| Response | `ContactListModel` → `existingNotConnected` + `nonExistingContacts` |

**Leave all of that exactly as it is.**

- ❌ Do **not** modify `connectionsSync` or any `chat-service/connections/*` call.
- ❌ Do **not** change `ChatViewController.uploadContacts` / `refreshContacts` / `findServiceByContacts`.
- ❌ Do **not** change `ContactListModel`, the Connect tab, or the existing Hive contacts cache.
- ✅ **Add** a new, separate `contact-service` integration alongside it.

The two serve different purposes and must coexist:

| | `chat-service/connections/sync` (existing) | `contact-service` (new) |
|---|---|---|
| Purpose | Connect tab: connections + invite list | "Contacts on BlueEra" + join notifications |
| Powers notifications | No | **Yes** — feeds the `contact_joined` push |
| Phone normalisation | None | Full E.164 |
| Keep? | **Yes, unchanged** | New, additive |

Once both are live and stable, product can decide whether to retire the old path. **That is not part of this task.**

---

## 1. Base URL

The app uses a **single API gateway host**, with every microservice reachable under a path prefix.

```
Gateway (prod) : https://be.beapp.in/api/
Pattern        : {baseUrl}<service-slug>/<internal-path>
```

`baseUrl` is a global set in `lib/environment_config.dart` from obfuscated `envied` values:

```dart
// lib/environment_config.dart
if (environmentType == AppConstants.prod) {
  baseUrl = Env.prodBaseUrl;   // .env -> PROD_BASE_URL
} else {
  baseUrl = Env.devBaseUrl;    // .env -> DEV_BASE_URL
}
```

`ApiBaseHelper.opts.baseUrl` picks this up, so **you never write a host in code** — only the
path suffix.

### Full URLs for this feature

| Method | Endpoint constant (what you write) | Full production URL |
|---|---|---|
| `POST` | `contact-service/api/contacts/sync` | `https://be.beapp.in/api/contact-service/api/contacts/sync` |
| `GET` | `contact-service/api/contacts` | `https://be.beapp.in/api/contact-service/api/contacts` |
| `GET` | `contact-service/api/contacts/on-blueera` | `https://be.beapp.in/api/contact-service/api/contacts/on-blueera` |
| `GET` | `contact-service/api/contacts/sync-state` | `https://be.beapp.in/api/contact-service/api/contacts/sync-state` |
| `POST` | `contact-service/api/contacts/rebuild` | `https://be.beapp.in/api/contact-service/api/contacts/rebuild` |
| `DELETE` | `contact-service/api/contacts` | `https://be.beapp.in/api/contact-service/api/contacts` |

> The doubled `api` is correct and matches `food-service/api/orders/...`: the first `api` belongs to
> the gateway, the second is the service's own route mount.

**Swagger:** `https://be.beapp.in/api/contact-service/api-docs`

Auth, `Content-Type`, `X-Device-Type`, `X-Device-OS` and the `Bearer` token are injected
automatically by the `ApiBaseHelper` interceptor. **Add no headers yourself.**

---

## 2. Wiring the endpoints in (step 1)

Follow the existing per-service mixin pattern.

### 2.1 New file — `lib/core/api/apiService/contact_service_api.dart`

```dart
/// All `contact-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// NOTE: this is separate from `chat-service/connections/*` (see
/// [ChatServiceApi]). Both exist on purpose — the chat-service sync powers the
/// Connect tab, this one powers "Contacts on BlueEra" and the
/// "your contact joined" push notification.
mixin ContactServiceApi {
  final String contactsSync = 'contact-service/api/contacts/sync';
  final String contactsList = 'contact-service/api/contacts';
  final String contactsOnBlueEra = 'contact-service/api/contacts/on-blueera';
  final String contactsSyncState = 'contact-service/api/contacts/sync-state';
  final String contactsRebuild = 'contact-service/api/contacts/rebuild';
}
```

### 2.2 Register it in `lib/core/api/apiService/base_service.dart`

Add the import and the mixin to the `with` clause — same as every other service. **Change nothing else in that file.**

```dart
import 'package:BlueEra/core/api/apiService/contact_service_api.dart';
// ...
class BaseService with
    // ... existing mixins, untouched ...
    ContactServiceApi { }
```

---

## 3. Repository (step 2)

New file — `lib/features/contacts/repo/contact_repo.dart`:

```dart
class ContactRepo extends BaseService {
  /// Upload the device phonebook. Idempotent — safe to retry.
  Future<ResponseModel> syncContacts(Map<String, dynamic> params) async {
    return ApiBaseHelper().postHTTP(
      contactsSync,
      params: params,
      showProgress: false,           // background operation, never block the UI
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getContactsOnBlueEra(Map<String, dynamic> query) async {
    return ApiBaseHelper().getHTTP(
      contactsOnBlueEra,
      params: query,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getSyncState() async {
    return ApiBaseHelper().getHTTP(
      contactsSyncState,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> rebuildMatches() async {
    return ApiBaseHelper().postHTTP(
      contactsRebuild,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> deleteAllContacts() async {
    return ApiBaseHelper().deleteHTTP(
      contactsList,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
```

> Unlike the chat-service sync (which posts a **bare JSON array** with `isArrayReq`), this endpoint
> takes a **JSON object**. Use the default `postHTTP` — do not set `isArrayReq`.

---

## 4. The API

### 4.1 `POST contact-service/api/contacts/sync`

**Request**

```json
{
  "contacts": [
    { "name": "Rahul Sharma", "phone": "+91 98765 43210" },
    { "name": "Priya",        "phone": "9123456780" }
  ],
  "full_sync": true,
  "country_code": "91",
  "digest": "a3f9c1e8"
}
```

| Field | Required | Notes |
|---|---|---|
| `contacts` | ✅ | Max **2000** per request |
| `contacts[].phone` | ✅ | **Any format.** Server normalises to E.164 — do not clean it yourself |
| `contacts[].name` | ❌ | Device name. **This is what the user sees in the notification** — always send it |
| `full_sync` | ❌ | `true` = complete phonebook; anything missing is removed. Default `false` |
| `country_code` | ❌ | SIM calling code, e.g. `"91"` |
| `digest` | ❌ | Your fingerprint of the phonebook — lets you skip future uploads (§6) |

The server also accepts `number` or `contact_no` instead of `phone`, so you can reuse the map you
already build for the chat-service sync.

**Response** — `res.data` (`ResponseModel.data` reads the `data` field for you)

```json
{
  "sync_version": 7,
  "received_count": 850,
  "accepted_count": 812,
  "invalid_count": 30,
  "duplicate_count": 8,
  "inserted_count": 12,
  "updated_count": 800,
  "removed_count": 0,
  "total_contacts": 812,
  "matched_count": 43,
  "duration_ms": 412,
  "synced_at": "2026-07-21T09:12:44.101Z"
}
```

`matched_count` = contacts on BlueEra. `invalid_count` is normal (`*123#`, `112`, junk) — don't surface it.

### 4.2 `GET contact-service/api/contacts/on-blueera`

Query: `page`, `limit` (max 200), `search` (name prefix).

```json
{
  "success": true,
  "data": [
    {
      "phone": "+919876543210",
      "name": "Rahul Sharma",
      "is_on_blueera": true,
      "user_id": "665a1b2c3d4e5f6a7b8c9d01",
      "matched_at": "2026-07-21T09:12:44.101Z",
      "added_at": "2026-06-02T11:00:00.000Z"
    }
  ],
  "pagination": {
    "currentPage": 1, "totalPages": 1, "totalContacts": 43,
    "hasNextPage": false, "hasPrevPage": false
  }
}
```

- `name` is **the user's own phonebook name** — render as-is. That's what makes it feel like Telegram.
- `user_id` is the BlueEra user id — feed it straight into your existing profile / chat navigation.
- Read pagination with `res.getExtraData('pagination')`.

### 4.3 `GET contact-service/api/contacts/sync-state`

```json
{
  "has_synced": true,
  "last_sync_at": "2026-07-21T09:12:44.101Z",
  "contacts_count": 812,
  "matched_count": 43,
  "digest": "a3f9c1e8",
  "sync_version": 7
}
```

### 4.4 `POST contact-service/api/contacts/rebuild`

Re-checks matches without an upload. Good for pull-to-refresh. Max 10/hour per user. Never notifies.

### 4.5 `DELETE contact-service/api/contacts`

Body `{"phones": ["+919876543210"]}`, or **no body at all to delete everything**. Call this when
contacts permission is revoked. Soft-delete, so re-granting restores history.

---

## 5. Controller (step 3)

GetX + `ApiResponse`, matching `ChatViewController`:

```dart
class ContactSyncController extends GetxController {
  final ContactRepo _repo = ContactRepo();

  Rx<ApiResponse> blueEraContactsResponse = ApiResponse.initial('Initial').obs;
  RxList<BlueEraContact> blueEraContacts = <BlueEraContact>[].obs;
  RxInt matchedCount = 0.obs;

  /// Upload the phonebook. Never throws; never blocks the UI.
  Future<void> syncContacts(
    List<Map<String, dynamic>> contacts, {
    bool fullSync = false,
    String? digest,
  }) async {
    try {
      final res = await _repo.syncContacts({
        'contacts': contacts,
        'full_sync': fullSync,
        if (digest != null) 'digest': digest,
        'country_code': '91',
      });

      if (res.isSuccess) {
        matchedCount.value = res.data?['matched_count'] ?? 0;
      } else {
        // Silent: this runs in the background, a toast here would be noise.
        logs('contact sync failed: ${res.message}');
      }
    } catch (e) {
      // ApiBaseHelper throws a raw String for non-badResponse Dio errors
      // (timeouts, no internet) — swallow, a background sync must never crash.
      logs('contact sync threw: $e');
    }
  }

  Future<void> loadBlueEraContacts({int page = 1, String? search}) async {
    blueEraContactsResponse.value = ApiResponse.initial('Initial');
    try {
      final res = await _repo.getContactsOnBlueEra({
        'page': page,
        'limit': 50,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      if (res.isSuccess) {
        final list = (res.data as List? ?? [])
            .map((e) => BlueEraContact.fromJson(e as Map<String, dynamic>))
            .toList();
        if (page == 1) {
          blueEraContacts.value = list;
        } else {
          blueEraContacts.addAll(list);
        }
        blueEraContactsResponse.value = ApiResponse.complete(blueEraContacts);
      } else {
        blueEraContactsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      blueEraContactsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
```

Model:

```dart
class BlueEraContact {
  final String phone;
  final String name;
  final bool isOnBlueEra;
  final String? userId;

  BlueEraContact({
    required this.phone,
    required this.name,
    required this.isOnBlueEra,
    this.userId,
  });

  factory BlueEraContact.fromJson(Map<String, dynamic> json) => BlueEraContact(
        phone: json['phone'] ?? '',
        name: json['name'] ?? '',
        isOnBlueEra: json['is_on_blueera'] ?? false,
        userId: json['user_id'],
      );
}
```

---

## 6. When to sync

**Reuse the phonebook read the app already does — don't read contacts twice.**

`ConnectMainPage._syncContactsIfNeeded()` already requests permission and calls
`FlutterContacts.getContacts(...)`. Add **one extra call** there, right after the existing
`uploadContacts(...)`. Do not restructure that method.

```dart
// inside _syncContactsIfNeeded(), AFTER the existing chat-service upload

// ADDITIVE: mirror the same phonebook to the contact service. Independent of
// the chat-service sync above — a failure here must not affect the Connect tab.
unawaited(
  contactSyncController.syncContacts(
    formatted,                      // the SAME list already built above
    fullSync: true,
    digest: computeDigest(formatted),
  ),
);
```

`formatted` is already `[{contact_no, name}, ...]`; the contact service accepts `contact_no`, so it
can be passed through unchanged.

### Cadence

| Moment | Action |
|---|---|
| Permission granted / Connect tab first entry | `syncContacts(fullSync: true)` |
| App resumed **and** > 24h since `last_sync_at` | `syncContacts(fullSync: true)` |
| Pull-to-refresh on the BlueEra-contacts screen | `POST /rebuild` |
| Every app launch | ❌ never — you'll hit the 20-per-15-min limit |

### Skip the upload when nothing changed

```dart
String computeDigest(List<Map<String, dynamic>> contacts) {
  final entries = contacts
      .map((c) => '${c['contact_no']}:${c['name']}')
      .toList()
    ..sort();
  return sha256.convert(utf8.encode(entries.join('|')))
      .toString()
      .substring(0, 16);
}
```

Compare against `sync-state.digest` and skip the upload when identical.

### Batching > 2000 contacts

Set `full_sync: true` on the **last batch only** — otherwise each batch prunes the previous one.

```dart
for (var i = 0; i < contacts.length; i += 2000) {
  final batch = contacts.skip(i).take(2000).toList();
  final isLast = i + 2000 >= contacts.length;
  await controller.syncContacts(batch, fullSync: isLast,
      digest: isLast ? digest : null);
}
```

---

## 7. Permissions

The app already handles this in `ConnectMainPage._syncContactsIfNeeded()`:

```dart
PermissionStatus status = await Permission.contacts.status;
if (!status.isGranted) {
  status = await Permission.contacts.request();
  if (!status.isGranted) return;
}
```

**Reuse it.** The only thing to add: when the user **revokes** contacts permission, call
`DELETE contact-service/api/contacts` so the server drops their phonebook. Both app stores expect
this, and it's the right thing to do.

```dart
if (status.isPermanentlyDenied) {
  await ContactRepo().deleteAllContacts();   // withdraw consent server-side
}
```

---

## 8. Handling the `contact_joined` notification

Sent automatically when someone in the user's phonebook completes their BlueEra account. **You
never trigger it.**

### 8.1 Payload

```jsonc
{
  "operation": "contact_joined",
  "senderName": "Rahul Bhai",                 // the name THIS user saved
  "contactUserId": "665a1b2c3d4e5f6a7b8c9d01",
  "contactPlatformName": "Rahul Sharma",
  "contactUsername": "rahul_92",
  "contactProfileImage": "https://cdn.blueera.in/…",
  "profileDeepLink": "blueera://profile/665a1b2c3d4e5f6a7b8c9d01",
  "chatDeepLink": "blueera://chat/665a1b2c3d4e5f6a7b8c9d01",
  "buttons": [
    { "id": "view_profile_665a1b2c3d4e5f6a7b8c9d01", "text": "View Profile" },
    { "id": "message_665a1b2c3d4e5f6a7b8c9d01",      "text": "Message" }
  ]
}
```

Title: **"Your contact joined BlueEra"** · Body: **"Rahul Bhai is now on BlueEra"**

### 8.2 Action buttons — already working ✅

`lib/core/services/app_notification.dart` already routes `view_profile_*` and `message_*`
(lines ~333 and ~1416, in both the foreground and background response handlers):

```dart
if (actionId.startsWith('accept_connection_') ||
    actionId.startsWith('decline_connection_') ||
    actionId.startsWith('view_profile_') ||
    actionId.startsWith('message_')) {
  Get.toNamed(RouteHelper.getNotificationScreenRoute());
  return;
}
```

**No change required for the buttons to function.** They currently land on the notification hub.

*Optional improvement* (do it only if product asks) — route them directly, ahead of the existing
block:

```dart
// contact_joined: go straight to the person rather than the hub.
if (data['operation'] == 'contact_joined') {
  final userId = (data['contactUserId'] ?? '').toString();
  if (userId.isNotEmpty) {
    if (actionId.startsWith('view_profile_')) {
      Get.toNamed(RouteConstant.OtherProfileScreen,
          arguments: {'user_id': userId});
      return;
    }
    if (actionId.startsWith('message_')) {
      AppNotificationHandler._openChatWithUser(userId);
      return;
    }
  }
}
```

`_openChatWithUser` is the existing helper used by chat notifications.

### 8.3 Body tap — one line to add

In `AppNotificationHandler._onTapNotificationFromStatusBar` (app_notification.dart ~line 2535), the
`switch (operation)` already lowercases `operation`/`type`. Add `contact_joined` to the existing
"Connection operations" group:

```dart
      // Connection operations
      case 'sent_connection_request':
      case 'received_connection_request':
      case 'accepted_connection_request':
      case 'followed_profile':
      case 'user_enrolled':
      case 'contact_joined':          // <-- ADD
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;
```

And mirror it in `PendingDeepLink.deriveTarget`
(`lib/core/services/notification/pending_deep_link.dart`) so cold-start boot decisions match:

```dart
      case 'followed_profile':
      case 'user_enrolled':
      case 'contact_joined':          // <-- ADD
        return DeepLinkTarget.connection;
```

> Without these two lines it still works — the `default:` branch already sends unknown operations to
> the notification hub. Adding them makes the intent explicit and keeps `deriveTarget` in sync with
> the switch, which that file's own comment requires.

### 8.4 In-app notification list

The notification also lands in the in-app list with `type: "CONTACT_JOINED"` and the same two
actions. Add an icon/label for that type wherever the list renders notification types.

### 8.5 Muting

Users can toggle it under notification settings, category **`contacts`**, via the existing
notification-preferences API. Just make sure the new category renders in the settings screen.

---

## 9. Error handling

`ApiBaseHelper` already handles the hard parts:

- **401** → interceptor performs a full logout and routes to login. **Don't handle 401 yourself.**
- **Non-`badResponse` errors** (timeout, no internet) → `postHTTP` **throws a raw `String`**.
  Always wrap background syncs in `try/catch`.
- **`badResponse`** (4xx/5xx) → returned as a `ResponseModel` with `isSuccess == false`.

| Code | Meaning | Do |
|---|---|---|
| `400` | Bad payload (empty, > 2000, malformed) | **Never retry** — fix the request |
| `429` | Rate limited (20 syncs / 15 min) | Stop. Don't loop. |
| `5xx` | Server issue | Retry with backoff, max 3 |

Sync is **idempotent** — retrying the same payload is always safe.

```dart
Future<void> syncWithRetry(List<Map<String, dynamic>> contacts) async {
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      final res = await _repo.syncContacts({'contacts': contacts, 'full_sync': true});
      if (res.isSuccess) return;
      if (res.statusCode == 400 || res.statusCode == 429) return; // permanent
    } catch (_) {
      // network-level failure — fall through to backoff
    }
    await Future.delayed(Duration(seconds: 2 << attempt)); // 4s, 8s, 16s
  }
}
```

> There is **no `connectTimeout`/`sendTimeout`** on the shared Dio client (only `receiveTimeout: 60s`)
> and no built-in retry — hence the explicit loop above.

---

## 10. Edge cases

| Situation | Behaviour | Your job |
|---|---|---|
| Number saved 3 ways (`98765 43210`, `+919876543210`, `09876543210`) | Server dedupes to one | Nothing |
| Junk entries (`*123#`, `112`) | Counted in `invalid_count`, dropped | Nothing |
| User has own number saved | Never matched, never notified | Nothing |
| Contact is a **guest** account | `is_on_blueera: false`, no notification | Nothing — intentional |
| Contact later completes signup | Notification fires **then** | Nothing |
| Same contact joins twice (redelivery) | Notified exactly once, ever | Nothing |
| Contact deletes their account | Flag clears on next sync/rebuild | Refresh the list |
| Contact saved with no name | Falls back to their platform name | Nothing |
| Existing user who never re-syncs | Contacts migrated server-side | Nothing |
| Offline | `postHTTP` throws a `String` | `try/catch`, retry later |

---

## 11. Checklist

**Do not touch**
- [ ] `chat_service_api.dart` — unchanged
- [ ] `ChatViewRepo` / `ChatViewController` contact methods — unchanged
- [ ] `ContactListModel`, Connect tab, existing Hive contacts cache — unchanged

**Add**
- [ ] `lib/core/api/apiService/contact_service_api.dart` (new mixin)
- [ ] `ContactServiceApi` registered in `base_service.dart`
- [ ] `ContactRepo` + `ContactSyncController` + `BlueEraContact` model
- [ ] One additive `syncContacts(...)` call in `_syncContactsIfNeeded()`, reusing the existing `formatted` list
- [ ] Digest computed and compared before background syncs
- [ ] "Contacts on BlueEra" screen using `/on-blueera` with pagination
- [ ] `DELETE contact-service/api/contacts` when permission is revoked
- [ ] `case 'contact_joined':` in `_onTapNotificationFromStatusBar`
- [ ] `case 'contact_joined':` in `PendingDeepLink.deriveTarget`
- [ ] `CONTACT_JOINED` rendered in the in-app notification list
- [ ] `contacts` category shown in notification settings
- [ ] Background syncs wrapped in `try/catch` (raw `String` throws)
