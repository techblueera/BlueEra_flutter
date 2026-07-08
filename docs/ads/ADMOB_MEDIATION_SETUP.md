# AdMob + Meta Audience Network Mediation — Setup Guide

**Goal:** make **Google AdMob** the primary ad server and run **Meta Audience Network (AN)** as a *mediation demand source inside AdMob*. AdMob fills the impression; when AN has an ad it may win the auction, otherwise Google (or another source) backfills. This ends the chronic `1001 No fill` / `1002 re-loaded too frequently` you get from calling AN directly — those become AdMob's internal concern, not a user-facing error.

> Context: the app currently calls AN **directly** (`facebook_audience_network` plugin, see `lib/core/services/ads/`). AdMob was added then reverted on 2026-07-06; this guide re-adds it, this time as the *primary* with AN mediated behind it.

Formats in use: **Native** (feed + grocery lists) and **Interstitial** (call-end).

---

## TL;DR — who does what

| Step | Owner | Blocking? |
|---|---|---|
| 1. Create/confirm AdMob account + app | **You (console)** | Yes — everything depends on the AdMob App ID + unit ids |
| 2. Create Native + Interstitial ad units | **You (console)** | Yes |
| 3. Link Meta AN as a mediation source + mediation groups | **You (console)** | No (ads still fill via Google without it; AN just adds demand) |
| 4. Add packages, App ID, adapters, unit ids | **Me (code)** | — |
| 5. Swap the ad managers to AdMob-backed, keep the forwarder seam | **Me (code)** | — |
| 6. Test with Google test ids + mediation test suite | **Both** | before release |

You can unblock me with just **Steps 1–2** (AdMob App ID + the four unit ids). Step 3 (AN mediation) can be added after — the app will already be filling via Google.

---

## PART A — What YOU do in the consoles

### A1. AdMob account & app
1. Go to **AdMob console** → **Apps** → **Add app**.
2. Select **Android** (and **iOS** if you ship iOS), and link the store listing (`ai.bluecs.app`). If not on the store yet, choose "not listed" — you can link later.
3. Copy the **AdMob App ID** for each platform. It looks like:
   `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` (note the **`~`**).

### A2. Ad units (create these four)
Under the app → **Ad units** → **Add ad unit**:
1. **Native advanced** → name "Feed Native" → copy the unit id.
2. **Interstitial** → name "Call-End Interstitial" → copy the unit id.
3. Repeat both for **iOS** if applicable.

Unit ids look like `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ` (note the **`/`**).

**Send me:** the App ID(s) + the 2–4 unit ids. I'll wire them into `AdConfig`. (You can paste them here or drop them in `.env` — see Part B.)

### A3. Link Meta Audience Network as a mediation source *(can be done after launch)*
This is what carries your existing Meta demand into the AdMob auction.

**In Meta (Audience Network / Monetization Manager):**
1. Confirm the app + placement are **approved and Active** (this was your blocker before).
2. Grab: **Meta App ID**, the **Placement ID(s)** you already have (native + interstitial), and a **User Access Token** (Audience Network → Settings → generate the mediation token). AdMob needs this token to report revenue.

**In AdMob:**
1. **Mediation** → **Create mediation group** → choose **format = Native** → **Ad locations = your app**.
2. Add the **Native** ad unit created in A2.
3. **Add ad source** → **Meta Audience Network**.
   - Prefer **Bidding** (real-time auction) over Waterfall — bidding removes the "reload too frequently" class of problem entirely.
   - Enter Meta **App ID**, **App Secret / Access Token**, and map the **Placement ID**.
4. Keep **Google AdMob Network** in the same group (it's the automatic backfill).
5. Repeat for a second mediation group with **format = Interstitial**.

> If AN still shows 0% fill inside mediation, that's fine now — Google backfills the slot. You lose nothing by leaving AN in as a bidding source.

### A4. Privacy / consent (required for Play + iOS)
- **Android/iOS:** you need a consent solution (Google **UMP SDK** or a CMP) for EEA/UK users, and **App Tracking Transparency** on iOS. AN as a bidder requires the user's consent signal to be passed. I'll wire the UMP consent flow in code; you just confirm the app's privacy policy URL is set in both stores.

---

## PART B — What I do in code

Keeping the existing seam: call sites already use `NativeAdWidget` and `InterstitialAdManager` (thin forwarders). I only swap what they forward to — **no call site changes**.

### B1. Packages & native config
- Add `google_mobile_ads` to `pubspec.yaml`.
- **Android** (`android/app/build.gradle`): add the Meta mediation adapter
  `implementation 'com.google.ads.mediation:facebook:<latest>'`
  and the AdMob App ID meta-data in `AndroidManifest.xml`:
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ```
- **iOS** (`ios/Podfile`): add the adapter pod
  `pod 'GoogleMobileAdsMediationFacebook'`, and `GADApplicationIdentifier` in `Info.plist` + the `SKAdNetworkItems` AN provides.
- Initialize once at startup: `MobileAds.instance.initialize()` (idempotent; the current `MetaAds.ensureInitialized()` pattern maps straight over).

### B2. Config
- Extend `AdConfig` with AdMob unit ids (test + live, per platform), pulled from `.env` via `envied` (same as the current Meta ids). Add Google's **test unit ids** for debug builds:
  - Native (Android test): `ca-app-pub-3940256099942544/2247696110`
  - Interstitial (Android test): `ca-app-pub-3940256099942544/1033173712`
  - (iOS test ids differ — I'll include both.)
- `metaTestMode`-style switch becomes `admobTestMode` = debug always test; release live only when `useLiveAdsInRelease`.

### B3. Managers
- Replace `MetaNativeAdWidget` internals with a `google_mobile_ads` **NativeAd** (`NativeAd` + `NativeAdListener`), keeping the same public widget shape (height/chrome/collapse-on-fail) and `keepAlive`.
- Replace `MetaInterstitialManager` internals with `InterstitialAd.load` + full-screen content callbacks. AdMob handles reload timing internally, so the hand-rolled `_MetaNativeLoadGate` / backoff / session-cap become **unnecessary** and get retired (AdMob doesn't emit 1002 to us).
- Keep the `adsEnabled` master kill-switch and the feed cadence.

### B4. Retire direct-AN calls
- The vendored `facebook_audience_network` plugin is **no longer called directly** — it stays only as the mediation adapter's transitive dependency (or is removed if the Google adapter bundles the AN SDK). I'll confirm during integration.

---

## PART C — Testing checklist

- [ ] Debug build shows **Google test ads** (always fill) for native + interstitial → proves integration.
- [ ] AdMob **Mediation test suite** (`MobileAds.instance.openAdInspector`) lists AN as a source and can load a test ad from it.
- [ ] Register the physical device as an AdMob **test device** so live-config test loads don't count as real impressions.
- [ ] Interstitial shows once at call-end, not repeatedly; native slots render in the feed at the current cadence.
- [ ] Consent/ATT prompt appears where required; ads still load after consent.

---

## PART D — Rollout & safety
- Ship behind the existing `adsEnabled` flag and `useLiveAdsInRelease` so you can dark-launch.
- Fill won't be 100% AN — and that's the point: Google backfills. Expect the 1001/1002 log lines to **disappear** (they're internal to AdMob now).
- If you ever want AN-only again, the forwarder seam lets us flip back without touching call sites.

---

## What I need from you to start coding
1. **AdMob App ID** (Android, + iOS if shipping iOS).
2. The **Native** and **Interstitial** ad unit ids (per platform).
3. Confirm the app's **privacy policy URL** is set in the store listing (for consent).

Give me #1–#2 and I'll do Part B end-to-end; Part A3 (AN mediation) you can complete in parallel or right after.
