# Account Deletion — Flutter Integration (User Side)

**Audience:** Flutter app developer
**Scope:** User-facing app only. The app just **starts** and **ends** the flow — OTP, terms, and the actual deletion all happen on a backend-hosted web page.

> Full reference (edge cases, testing checklist): [FLUTTER_ACCOUNT_DELETION_GUIDE.md](FLUTTER_ACCOUNT_DELETION_GUIDE.md)

---

## The flow at a glance

```
[1] User taps "Delete account"  (Settings → Privacy)
        │
[2] Confirm dialog  ──► cancel ─► stop
        │ continue
[3] POST /user/account/deletion/init   (JWT)
        │  ← { deletion_url, init_token, expires_at }
        │
[4] Open deletion_url in in-app browser (Custom Tabs / SFSafariVC)
        │
        ▼  ─────── WEB PAGE (not the app) ───────
        │   OTP  →  accept Terms  →  Confirm
        │   backend: soft-flag account, kill all sessions,
        │            schedule delete +24h
        ▼  ──────────────────────────────────────
        │
[5] User returns to app → next API call gets 401
        │  → global 401 handler → logout → login screen
        │
[6] (optional) User logs in again within 24h
        │  → login response has account_deletion_cancelled: true
        │  → show "we cancelled your deletion" banner
```

The app does **NOT** do: OTP UI, terms UI, status polling, session invalidation, or deep-link-back detection.

---

## Step 1 — The button

Settings → Privacy & Security → **Delete account** (destructive/red styling, existing settings pattern).

## Step 2 — Confirm dialog (before any network call)

```dart
final proceed = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Delete your account?'),
    content: const Text(
      "You'll be taken to a secure page to verify your phone number and "
      "accept the deletion terms. After you confirm, your account is deleted "
      "in 24 hours unless you log in again.",
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Continue', style: TextStyle(color: Colors.red)),
      ),
    ],
  ),
);
if (proceed != true) return;
```

## Step 3 — Call `init` (the ONLY deletion API the app calls)

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `{API_BASE}/user/account/deletion/init` |
| **Auth** | `Authorization: Bearer <JWT>` (standard app auth) |
| **Body** | none (send `{}` or nothing) |

**200 response:**
```json
{
  "success": true,
  "init_token": "eyJhbGciOi...",
  "deletion_url": "https://.../account-delete?init_token=eyJhbGciOi...",
  "expires_at": "2026-07-10T10:30:00.000Z"
}
```
Use `deletion_url` **as-is**. Do not build or hardcode the URL — the backend controls the host (`DELETION_WEB_BASE_URL`).

**Errors:**
| HTTP | code | App behavior |
|---|---|---|
| 401 | `unauthenticated` | Token dead → force re-login |
| 409 | `already_pending_deletion` | Already scheduled → show status, don't re-init (optionally call `/status`) |
| 429 | `rate_limited` | Toast: "Too many attempts. Try again in an hour." (max 3/hour) |
| 503 | `feature_disabled` | Feature off → "Not available yet, contact support." |
| 5xx | `server_error` | Toast: "Something went wrong. Please try again." |

```dart
Future<void> startAccountDeletion() async {
  final res = await http.post(
    Uri.parse('$apiBase/user/account/deletion/init'),
    headers: {
      'Authorization': 'Bearer ${auth.token}',
      'Content-Type': 'application/json',
    },
  );

  switch (res.statusCode) {
    case 200:
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      await _launchDeletionPage(body['deletion_url'] as String);
      break;
    case 409:
      _showToast('You already have a pending deletion.');
      break;
    case 429:
      _showToast('Too many attempts. Try again in an hour.');
      break;
    case 503:
      _showToast('Account deletion is unavailable right now.');
      break;
    default:
      _showToast('Something went wrong. Please try again.');
  }
}
```

## Step 4 — Open the web page in an in-app browser

Requires `url_launcher: ^6.3.0` (needs `LaunchMode.inAppBrowserView`, 6.1+).

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchDeletionPage(String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.inAppBrowserView,   // Custom Tabs (Android) / SFSafariViewController (iOS)
    webViewConfiguration: const WebViewConfiguration(
      enableJavaScript: true,   // page is JS-driven — required
      enableDomStorage: true,
    ),
  );
  if (!ok) {
    await launchUrl(uri, mode: LaunchMode.externalApplication); // fallback
  }
}
```

The web page handles OTP + Terms + Confirm entirely. The app needs no callback from it.

## Step 5 — Handle post-confirm 401 (session killed)

After the user confirms on the web page, the backend **immediately invalidates all sessions**. The app's JWT is now dead, so the next authenticated call returns **401**. Your global 401 interceptor must log the user out.

```dart
// Dio example — add once, globally
dio.interceptors.add(InterceptorsWrapper(
  onError: (e, handler) {
    if (e.response?.statusCode == 401) {
      auth.logout();
      router.go('/login');
    }
    handler.next(e);
  },
));
```

If the user just closes the browser without confirming → nothing changed; they can tap Delete again later (a fresh `init_token` auto-cancels the old one).

## Step 6 — Login within the 24h grace window (auto-cancel)

If the user logs back in within 24 hours of confirming, the backend **auto-cancels** the deletion. The **login/OTP-verify response** carries a new flag:

```json
{
  "success": true,
  "token": "...",
  "account_deletion_cancelled": true,   // present ONLY when auto-cancel fired
  "data": { ... }
}
```

Handle it null-safely (absent/false on all normal logins):

```dart
if (loginResponse['account_deletion_cancelled'] == true) {
  _showBanner(
    "Welcome back — we've cancelled your pending account deletion. "
    "To delete again, start over from Settings.",
  );
}
```

After 24h with no login, the account is archived by a backend cron and can no longer be recovered by the user (login will fall into the new-registration flow).

---

## Endpoint reference (app touches only these)

| Purpose | Method + Path | Auth |
|---|---|---|
| Start deletion | `POST {API_BASE}/user/account/deletion/init` | JWT |
| (optional) Check status | `GET {API_BASE}/user/account/deletion/status` | JWT |

> `{API_BASE}` is the user-service base your app already uses (e.g. `https://<host>/api/user-service`). The web page's own OTP/confirm endpoints are **not called by the app** — the page calls them itself.

## Do NOT

- ❌ Render OTP or Terms UI
- ❌ Hardcode the deletion web URL — use the returned `deletion_url`
- ❌ Poll deletion status in a loop
- ❌ Invalidate sessions yourself (backend does it)
- ❌ Try to detect browser-close "success" — rely on the 401 instead
