# Backend Guide — Instagram Link Metadata (yt-dlp)

How to extract Instagram reel/post metadata (thumbnail, caption, author, video
stream) on the backend for the Referral "Add Link" feature, using **yt-dlp**.

Companion to `BACKEND_LINK_METADATA.md` (YouTube / X-Twitter / general). This
doc is Instagram-specific because it's the hardest of the three.

---

## TL;DR

- **yt-dlp already supports Instagram** — you are not missing a library.
- The reason you get no metadata is Instagram's **login wall**: anonymous
  requests are bounced to a login page. yt-dlp must send a **logged-in session
  cookie**.
- Fix = run yt-dlp **with `--cookies`** from a throwaway IG account.
- The returned MP4 URL is a **short-lived signed CDN link** — cache the
  *metadata*, not the stream URL.

```bash
yt-dlp -J --no-warnings --cookies ig_cookies.txt \
  "https://www.instagram.com/reel/<shortcode>/"
```

---

## Why anonymous yt-dlp returns nothing

Instagram serves a login/consent wall to unauthenticated clients for almost all
post data. So `yt-dlp <reel-url>` with no auth resolves the wall, not the post,
and comes back empty or errors with a login-required message. Nothing is wrong
with the tool or the URL — it just needs a session.

> The app already sends a clean canonical URL
> (`https://www.instagram.com/reel/<shortcode>/`, tracking tokens like `igsh`
> stripped), so you don't need to clean it again — but re-stripping server-side
> is fine as a backstop.

---

## Step 1 — Create the cookie file (one-time)

1. Create / use a **throwaway** Instagram account (NOT a real/important one —
   automated access can get accounts checkpointed or disabled).
2. Log into that account in a browser.
3. Export cookies in **Netscape format** (e.g. the "Get cookies.txt LOCALLY"
   browser extension) → save as `ig_cookies.txt`.
4. Place it where the backend can read it (mounted secret / secure path, not in
   the repo).

Dev shortcut (local only): `--cookies-from-browser chrome` instead of a file.
On a server, use the exported file.

---

## Step 2 — Extract metadata (no download)

### Full JSON

```bash
yt-dlp -J --no-warnings --cookies ig_cookies.txt \
  "https://www.instagram.com/reel/<shortcode>/"
```

`-J` prints the info JSON and downloads nothing.

### Or just the fields you need

```bash
yt-dlp --no-warnings --cookies ig_cookies.txt \
  --print "%(thumbnail)s|%(uploader)s|%(description)s|%(webpage_url)s" \
  "https://www.instagram.com/reel/<shortcode>/"
```

### Field mapping → card schema

| Card field            | yt-dlp JSON field                                             |
|-----------------------|--------------------------------------------------------------|
| `title`               | `description` (Instagram has no title — use caption, truncated)|
| `description`         | `description`                                                |
| `thumbnail`           | `thumbnail`                                                   |
| `videoUrl`            | `url` (resolved stream — **see expiry caveat below**)         |
| `authorName`          | `uploader` (fallback `channel`)                              |
| `url` (canonical)     | `webpage_url`                                                |

Target schema (same as the other platforms):

```jsonc
{
  "url":         "https://www.instagram.com/reel/<shortcode>/",
  "platform":    "instagram",
  "title":       "…",        // caption, truncated
  "description": "…",        // full caption
  "thumbnail":   "https://…",
  "videoUrl":    "https://…", // signed, short-lived — do not persist
  "authorName":  "…"
}
```

---

## Step 3 — Call it from the backend

Always pass the URL as an **argument array** (never string-interpolated into a
shell) to avoid command injection.

### Node.js

```js
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const execFileP = promisify(execFile);

async function instagramMeta(url) {
  const { stdout } = await execFileP("yt-dlp", [
    "-J", "--no-warnings",
    "--cookies", process.env.IG_COOKIES_PATH,  // e.g. /run/secrets/ig_cookies.txt
    url,
  ], { maxBuffer: 1024 * 1024 * 16, timeout: 30_000 });

  const info = JSON.parse(stdout);
  return {
    url:         info.webpage_url,
    platform:    "instagram",
    title:       (info.description || "").slice(0, 120),
    description: info.description || "",
    thumbnail:   info.thumbnail || null,
    videoUrl:    info.url || null,   // short-lived; see caveat
    authorName:  info.uploader || info.channel || null,
  };
}
```

### Python (embedded, no subprocess)

```python
from yt_dlp import YoutubeDL

def instagram_meta(url: str) -> dict:
    opts = {"cookiefile": "ig_cookies.txt", "skip_download": True, "quiet": True}
    with YoutubeDL(opts) as ydl:
        info = ydl.extract_info(url, download=False)
    return {
        "url":         info.get("webpage_url"),
        "platform":    "instagram",
        "title":       (info.get("description") or "")[:120],
        "description": info.get("description") or "",
        "thumbnail":   info.get("thumbnail"),
        "videoUrl":    info.get("url"),   # short-lived; see caveat
        "authorName":  info.get("uploader") or info.get("channel"),
    }
```

---

## ⚠️ Critical caveat — the video URL expires

The `url` / `videoUrl` yt-dlp returns is a **signed Instagram CDN link valid for
only a short time** (minutes–hours). If you store it as a permanent `videoUrl`,
it will start returning **403** later. Choose one:

1. **Store the shortcode, resolve lazily** — re-run yt-dlp when the user actually
   plays the video (then the signed URL is fresh). Best default.
2. **Download + re-host** the MP4 on your own storage/CDN at ingest time, and
   store that permanent URL. Heavier, but the link never rots.
3. **Cache the metadata (thumbnail/caption/author) long-term, the stream URL
   short-term** — show the card immediately, resolve the stream on demand.

Do **not** cache the signed stream URL as if it were permanent.

---

## Operational requirements (these are what actually break in production)

- **Burner account + clean IP.** Datacenter IPs (AWS/GCP/Azure) get challenged or
  blocked quickly. A residential/mobile proxy IP is far more stable. Never use a
  real/important account.
- **Cookies expire and get challenged.** Treat `ig_cookies.txt` as rotatable:
  detect the "login required / rate-limited" error and have a refresh path. Don't
  assume one cookie lasts forever.
- **Rate-limit + cache hard.** Cache resolved metadata by canonical URL (TTL
  24h+) so each link hits yt-dlp once, not once per view. Throttle concurrent
  extractions.
- **Keep yt-dlp auto-updated.** Instagram changes its internals often and breaks
  extractors; a stale yt-dlp silently returns nothing. Run `yt-dlp -U` (or track
  nightly builds) on a schedule.
- **Timeouts + graceful degradation.** On failure, still persist
  `{platform, url, thumbnail?, caption?}` with `videoUrl: null` so the card
  renders a basic state instead of failing the whole POST.

---

## Free fallback when you can't risk cookies (no login, no video stream)

If running a logged-in cookie is not acceptable, Instagram's **embed endpoint**
is served publicly (no auth) and gives thumbnail + caption + author — but **not**
the MP4:

```
GET https://www.instagram.com/reel/<shortcode>/embed/captioned/
User-Agent: <desktop browser UA>
```

The HTML contains a JSON blob (search for `"contextJSON"` / `gql_data` inside a
`<script>` tag) and/or an `<img class="EmbeddedMediaImage" src="…">` (the
thumbnail). Parse the JSON if present, else fall back to the `<img>` + caption.

**Recommended combined strategy:**

```
1. Try the embed endpoint        -> thumbnail + caption + author, no login
2. If a playable stream is needed -> yt-dlp + burner cookies (resolve lazily)
3. Cache metadata 24h+, resolve the signed stream URL on demand
4. On failure -> persist {platform, url, thumbnail?, caption?, videoUrl:null}
```

There is **no** reliable, fully-anonymous, free way to get the playable
Instagram reel MP4 — that is an Instagram limitation, not a gap in your stack.
Anonymous + free buys thumbnail/caption/author; the stream needs a session.

---

## References

- yt-dlp — https://github.com/yt-dlp/yt-dlp
- yt-dlp Instagram extractor notes / cookies — https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp
- Exporting cookies (Netscape format) — https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp
