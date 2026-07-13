# Reels Feed — Random Order (Frontend Integration)

**Endpoint:** `GET /videos/hot/short`
**Auth:** none (public)
**Change:** reels now come back in **random order** instead of by views. Ordering is
**stable per session via a `seed`**, so paginating never shows the same reel twice.

> Same change also applies to `GET /videos/hot/long` for long-form.

---

## What you need to do (1 change)

The API is stateless, so **the client carries the shuffle seed** between pages:

1. **First page:** call **without** `seed`. The server generates one and returns it at
   `pagination.seed`.
2. **Every next page:** send that **same `seed`** back, plus the incremented `page`.
3. **Refresh / re-shuffle (pull-to-refresh):** **drop the seed** and start again from
   page 1 — the server mints a new seed → a brand-new random order.

If you keep the same `seed` across pages, reels are **random with zero repeats**.
If you send a **new/no seed** on later pages, you'll get re-shuffling and possible repeats —
so always reuse the seed while scrolling a session.

---

## Request

| Param | In | Required | Notes |
|-------|-----|----------|-------|
| `page`  | query | no | default `1` |
| `limit` | query | no | default `10`, max `50` |
| `seed`  | query | no | **omit on page 1**, then reuse the value from `pagination.seed` |

### Calls in order
```
Page 1:  GET /videos/hot/short?limit=10
Page 2:  GET /videos/hot/short?limit=10&page=2&seed=728461935
Page 3:  GET /videos/hot/short?limit=10&page=3&seed=728461935
Refresh: GET /videos/hot/short?limit=10                 # no seed -> new order
```

---

## Response (shape unchanged, one new field)

`pagination` now includes **`seed`** and **`hasMore`**:

```json
{
  "success": true,
  "data": [
    { "videoId": "reel_01", "video": { "...": "full video object" }, "author": { "...": "..." } }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 240,
    "totalPages": 24,
    "hasMore": true,
    "seed": "728461935"
  }
}
```

- **`seed`** — store it; send it back on the next page. (String.)
- **`hasMore`** — `true` while more pages exist; stop paging when `false`.
- `data[]` items are unchanged from before (same video/author/interaction fields).

---

## Client pseudo-code

```js
let seed = null;      // reset to null on pull-to-refresh
let page = 1;

async function loadMoreReels() {
  const url = new URL(`${API_BASE}/videos/hot/short`);
  url.searchParams.set("limit", "10");
  url.searchParams.set("page", String(page));
  if (seed) url.searchParams.set("seed", seed);   // omit on the very first call

  const res = await fetch(url).then(r => r.json());

  seed = res.pagination.seed;                      // capture on page 1, reuse after
  page += 1;

  appendReels(res.data);
  return res.pagination.hasMore;                   // false => no more pages
}

function refreshReels() {
  seed = null;   // new session -> new random order
  page = 1;
  loadMoreReels();
}
```

---

## Verified behavior (tested)

Simulated the exact server flow over 12 reels, `limit=5`, one fixed seed:

| Page | Reel IDs returned |
|------|-------------------|
| 1 | reel_01, reel_09, reel_08, reel_04, reel_10 |
| 2 | reel_06, reel_11, reel_02, reel_12, reel_03 |
| 3 | reel_07, reel_05 |

- ✅ No repeats across pages (12/12 unique), full coverage
- ✅ Same seed → identical order every request (safe to retry a page)
- ✅ Different seed → different order (refresh reshuffles)
- ✅ `hasMore` = `true` on pages 1–2, `false` on the last page

---

## Notes / edge cases

- **Don't cache `seed` forever.** It's per browsing session. New session or refresh → new seed.
- **New reels published mid-session:** they may not appear until the next refresh (new seed).
  That's expected and normal for a stable shuffle.
- **Same limit while paging.** Keep `limit` constant across pages of one seed; changing it
  mid-session can misalign page boundaries.
- Nothing else about the payload changed — only ordering + the two new `pagination` fields.
