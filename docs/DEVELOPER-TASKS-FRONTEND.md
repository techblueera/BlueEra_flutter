# Frontend developer tasks (Flutter app + web panels) — after the move to the new server (2026-09-30)

**For:** BlueEra Flutter and web developers and their Claude assistant.
**Repos:** `BlueEra_flutter` (branch `main`, latest work on feature branches), `admin_dashboard`, `be_fe_admin_dashboard` (branch `blueera_website_nextjs`), `product_management`, `beapp-landing`, `react_delete_account`, `be_emergency_frontend`.
**Rules**
- One PR per repo. No change of API contracts. Keep the domain `beapp.in`.
- No hard-coded hosts, bucket names or secrets in app/web code — use the existing `.env` / `Env` values or values returned by the backend.
- Reply with a table: `repo | PR link | items done | needs new app release? (yes/no)`.

---

## 0. What changed for the clients (read first)

| Thing | Now |
|---|---|
| API base | `https://be.beapp.in/api/` (unchanged). `api.beapp.in` is routed the same way (temporary, see F2). |
| Sockets | Chat `wss://chat.beapp.in` path `/socket` ✅; live track `https://map.beapp.in/` (socket.io) ✅; `call.`, `rider.`, `emergency.` unchanged |
| Calls (TURN) | ICE servers come from call-service: `turn:65.0.158.70:3478` (UDP + TCP). **No TLS TURN (5349) any more.** |
| Front door | Cloudflare (proxy + SSL). **Max 100 MB per request body** on the free plan. |
| Media (images/videos) | New uploads go to new buckets `https://blueera-<name>-648617468896.s3.ap-south-1.amazonaws.com/...`. Old media links (`blu-*-bck`, `be-user-bkt`, `bluehr-public-prod`, `be-post-service-bck`, `be-video-service-01`, `ott-bucket-01`, `d*.cloudfront.net`) keep working **only until the old AWS account is closed**; the server team will copy needed files and rewrite DB links. |
| Logins | Old sessions that no longer exist in the DB get **401**. Users must log in again. |
| Base-URL cache in the app | ✅ no issue: `environment_config.dart` sets `baseUrl` from `.env` on every launch and saves it to secure storage. |
| Image cache in the app | ✅ `cached_network_image` is keyed by URL, so new URLs load fresh. |

---

## 🔴 Flutter (BlueEra_flutter)

### F1. Stop hammering the API after 401
Real traffic after the move: 43 devices sent `POST /api/map-service/api/provider/location` ~350 times in 40 minutes, all **401** (session no longer valid). The app keeps retrying instead of asking the user to log in.
- In the Dio interceptor (`lib/core/api/apiService/api_base_helper.dart`): on 401 → cancel background timers/uploads (location updates, workmanager), clear the session **once**, route to login. Never retry a 401.
- Background location/heartbeat tasks: exponential backoff on any error (5 s → 5 min), stop completely on 401/403.

### F2. `api.beapp.in` hard-coded for calls
`lib/video_calling/call_api_service.dart:7`: `static const String baseUrl = "https://api.beapp.in/api/chat-service/call/user";`
`api.beapp.in` never existed in the old DNS (these calls probably failed before). The server now routes it like `be.beapp.in`, but please change it to use the common `baseUrl` (`${baseUrl}chat-service/call/user`) so there is one API host.

### F3. OTT demo video URLs point to old buckets
`lib/features/common/ott/controller/ott_video_player_controller.dart:232-235` hard-codes `be-video-service-01` and `ott-bucket-01` S3 URLs (240p/360p/720p/1080p). These buckets will be deleted. Get the URLs from the backend (OTT/title API) or move to config; do not ship bucket URLs in the app.

### F4. Uploads bigger than 100 MB
Cloudflare rejects request bodies > 100 MB (HTTP 413). Check every upload path (reels, videos, documents, chat media):
- Prefer the existing **presigned S3 upload URLs** (the app already does this in chat — `Generate_Upload_Ulr_Model`). With presigned URLs the file goes directly to S3 and never passes Cloudflare.
- For any flow that POSTs the file body to `be.beapp.in`, either switch to presigned upload or compress/cap the file below 95 MB and show a clear message.

### F5. TURN / calls
- Always use the ICE server list returned by the backend; do not hard-code `turn.beapp.in` or port 5349 (`turns:`).
- Make sure both `turn:65.0.158.70:3478?transport=udp` and `?transport=tcp` are tried (some mobile networks block UDP).
- Test: call between two phones on different networks (Jio ↔ Airtel, WiFi ↔ mobile data).

### F6. Media URL handling
- Never check or build bucket hostnames in the app (e.g. regex on `bluehr-public-prod` / `be-user-bkt`). Treat any `https://` media URL as valid.
- After the server team rewrites old links, optionally clear the image cache once (`DefaultCacheManager().emptyCache()` on first launch of the next version) so users don't keep broken old-host images.

### F7. Sockets resilience
- Chat (`wss://chat.beapp.in`, path `/socket`) and live-track (`map.beapp.in`): reconnect with backoff (1 s → 30 s), re-authenticate after reconnect, resubscribe to rooms. Cloudflare may close idle sockets; socket.io ping (25 s) keeps them alive — do not disable pings.

### F8. Secrets in the app
- `.env` is committed to the repo. It must contain **only public values** (API URLs, Razorpay **key_id**). Confirm no `key_secret`, server API keys, or Firebase admin keys are in `.env`, assets or code.
- The backend endpoint `/api/product-service/api/products/fe/ai-key` (returns Google/Serper/Maps keys) will be removed by the backend team. If the app uses it, switch to an **Android/iOS-restricted** Maps key in the app config (ask the owner for the new restricted key).

### F9. Release
F1, F2, F3, F4 need a new app build (Play Store / App Store). Include them in the next release; no forced update needed today.

---

## 🟠 Web panels and websites

### W1. `admin_dashboard` (Next.js) — `admin.beapp.in`
- Image domains: `next.config` builds `remotePatterns` from `IMAGE_S3_BUCKETS` (`${bucket}.s3.ap-south-1.amazonaws.com`) and also lists `be.blueera.ai`. Add the new buckets (`blueera-user-648617468896`, `blueera-post-…`, `blueera-product-…`, `blueera-grocery-…`, `blueera-education-…`, etc.) to `IMAGE_S3_BUCKETS`; keep the old ones until the media migration is done; remove `be.blueera.ai` if unused.
- `AUTH_SECRET` and `SESSION_SIGNING_SECRET` are hard-coded in `docker_files_microservices/frontend/admin-service/Dockerfile.admin` → remove; read from runtime env. The owner will set new values.
- API base must be `https://be.beapp.in/api/` (build-time `NEXT_PUBLIC_API_BASE_URL`).

### W2. Websites that will be hosted on the new server
The server team will build and run these; please confirm for each: **production branch**, **build command**, **all env vars needed at build time** (names + example values, no secrets in git):

| Site | Repo (branch) | Old port | Notes |
|---|---|---|---|
| `beapp.in` | `be_fe_admin_dashboard` (`blueera_website_nextjs`) | 3000 | Next.js standalone, deep-link pages `beapp.in/app/...` |
| `admin.beapp.in` | `admin_dashboard` (`main`) | 3002 | W1 |
| `product-management.beapp.in` | `product_management` (`main`) | 3003 | Next.js |
| `app.beapp.in` | `beapp-landing` (`main`) | 4173 | Vite static → will be served by nginx |
| `delete.beapp.in` | `react_delete_account` (`main`) | 4174 | Vite static; `VITE_USER_SERVICE_URL` baked at build |
| `emergency.beapp.in` | `be_emergency_frontend` (`prod-staging`) | 3001 | Vite static; has `deploy/nginx-emergency.conf` |

Until they are deployed, these hosts show a "We'll be right back" page.

### W3. Sites on Hostinger (`Franchise_Admin_web`, `blueera.ai`, `bluecs_website`)
Nothing to change unless they call an old API host; they must use `https://be.beapp.in/api/`.

### W4. Caching
- Static assets (JS/CSS/images) may be cached by Cloudflare — use hashed file names (default in Next.js/Vite) so a deploy is visible immediately.
- Never put user-specific data in URLs ending with `.pdf/.png/.jpg` without auth headers; the backend will send `Cache-Control: no-store` for private responses.

---

## How to test against production safely
- Use your own test account; read-only screens first.
- Report bugs with: time (IST), screen, API URL, HTTP status. The server team can find the exact request in the logs by time.
