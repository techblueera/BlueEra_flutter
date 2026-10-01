# Flutter app tasks (BlueEra_flutter) — after the move to the new server (2026-09-30)

**For:** BlueEra mobile (Flutter) developers and their Claude assistant.
**Repo:** `BlueEra_flutter` (branch `main`; latest work is on feature branches).
**Rules**
- One PR per change group. No change of API contracts. Keep the domain `beapp.in`.
- No hard-coded hosts, bucket names or secrets — use the existing `.env` / `Env` values or values returned by the backend.
- Reply with a table: `item | PR link | done? | needs new app release? (yes/no)`.

---

## 0. What changed for the app (read first)

| Thing | Now |
|---|---|
| API base | `https://be.beapp.in/api/` (unchanged, from `.env` → `PROD_BASE_URL`). `api.beapp.in` is also routed to the API (see F2). |
| Sockets | Chat `wss://chat.beapp.in`, path `/socket` ✅ (tested); live track `https://map.beapp.in/` socket.io ✅; `call.`, `rider.`, `emergency.` unchanged |
| Calls (TURN) | ICE servers come from call-service: `turn:65.0.158.70:3478` (UDP + TCP). **No TLS TURN (5349) any more.** |
| Front door | Cloudflare (proxy + SSL). **Max 100 MB per request body.** |
| Media | New uploads go to `https://blueera-<name>-648617468896.s3.ap-south-1.amazonaws.com/...`. Old links (`blu-*-bck`, `be-user-bkt`, `bluehr-public-prod`, `be-post-service-bck`, `be-video-service-01`, `ott-bucket-01`, `d*.cloudfront.net`) work **only until the old AWS account is closed**; the server team will copy needed files and rewrite DB links. |
| Logins | Old sessions that no longer exist get **401** → users must log in again. |
| Base-URL cache | ✅ no issue: `lib/environment_config.dart` sets `baseUrl` from `.env` on every launch and stores it in secure storage. |
| Image cache | ✅ `cached_network_image` is keyed by URL, so new URLs load fresh. |
| Already verified on the new server | OTP login, profile, plans, orders, wallet, notifications list, home feed, photo post upload, presigned direct upload, chat websocket |

---

## 🔴 Must fix

### F1. Stop hammering the API after 401
Real traffic after the move: 43 devices sent `POST /api/map-service/api/provider/location` ~350 times in 40 minutes, all **401**. The app keeps retrying instead of asking the user to log in.
- Dio interceptor (`lib/core/api/apiService/api_base_helper.dart`): on 401 → cancel background timers/uploads (location updates, workmanager), clear the session **once**, route to login. Never retry a 401.
- Background location/heartbeat tasks: exponential backoff on any error (5 s → 5 min), stop completely on 401/403.

### F2. `api.beapp.in` hard-coded for calls
`lib/video_calling/call_api_service.dart:7`: `static const String baseUrl = "https://api.beapp.in/api/chat-service/call/user";`
`api.beapp.in` never existed in the old DNS (these calls probably failed before). The server now routes it like `be.beapp.in`, but change it to the common base: `${baseUrl}chat-service/call/user`.

### F3. OTT demo video URLs point to old buckets
`lib/features/common/ott/controller/ott_video_player_controller.dart:232-235` hard-codes `be-video-service-01` and `ott-bucket-01` S3 URLs (240p/360p/720p/1080p). These buckets will be deleted. Get the URLs from the backend (OTT/title API) or remote config.

### F4. Uploads bigger than 100 MB
Cloudflare rejects bodies > 100 MB (HTTP 413). Check every upload path (reels, videos, documents, chat media):
- Prefer **presigned S3 upload URLs** (already used in chat — `Generate_Upload_Ulr_Model`): the file goes straight to S3, not through Cloudflare. Send only `Content-Type` on the PUT (extra headers break the signature — tested).
- Any flow that POSTs the file body to `be.beapp.in`: switch to presigned upload, or compress/cap under 95 MB with a clear message.

---

## 🟠 Should fix

### F5. TURN / calls
- Use the ICE server list returned by the backend; never hard-code `turn.beapp.in` or `turns:`/5349.
- Try both `turn:65.0.158.70:3478?transport=udp` and `?transport=tcp` (some mobile networks block UDP).
- Test: call between two phones on different networks (Jio ↔ Airtel, WiFi ↔ mobile data); audio and video; 5-minute call.

### F6. Media URL handling
- Never check or build bucket hostnames in the app. Treat any `https://` media URL as valid.
- After the server team rewrites old links, optionally clear the image cache once (`DefaultCacheManager().emptyCache()` on first launch of the next version).

### F7. Sockets resilience
- Chat (`wss://chat.beapp.in`, `/socket`) and live-track (`map.beapp.in`): reconnect with backoff (1 s → 30 s), re-authenticate after reconnect, resubscribe to rooms. Keep socket.io pings (25 s) on.

### F8. Secrets in the app
- `.env` is committed. It must contain **only public values** (API URLs, Razorpay **key_id**). Confirm no `key_secret`, server API keys or Firebase admin keys are in `.env`, assets or code.
- The backend endpoint `/api/product-service/api/products/fe/ai-key` (returns Google/Serper/Maps keys) will be removed. If the app uses it, switch to an **Android/iOS-restricted** Maps key in the app config (ask the owner for the new restricted key).

---

## F9. Release
F1–F4 need a new build (Play Store / App Store). Include them in the next release; no forced update needed today.

## Manual test checklist before release (two phones, two accounts)
| # | Flow | Expected |
|---|---|---|
| 1 | Logout → OTP login | OTP arrives, login works |
| 2 | Home feed, scroll | Posts/suggestions load |
| 3 | Open a profile | Name + photo |
| 4 | Chat text message (A → B) | Arrives instantly |
| 5 | Chat photo | Uploads, visible on B |
| 6 | Change profile photo | New photo shows |
| 7 | Audio call (WiFi ↔ mobile data) | Two-way audio |
| 8 | Video call | Two-way video |
| 9 | Push notification (message/like) | Arrives on the phone |
| 10 | Change language | List shows, strings change |
| 11 | Wallet / plan page | Opens, amounts shown |
| 12 | Payment page (do not pay) | Razorpay opens |
| 13 | Grocery / product list, search | Items load |
| 14 | Rider / map screen | Map and nearby load |
| 15 | Force-expire session (log out on another device) | App goes to login once, no retry loop |

Report problems with: time (IST), screen, API URL, HTTP status — the server team finds the request in the logs by time.
