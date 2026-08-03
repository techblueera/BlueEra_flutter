# Where Google Places Is Used — Usage Map

**Branch:** `himanshu-google-maps-backup`
**Purpose:** a precise inventory of every place this app touches the Google
Places API, so you can find what to change without hunting.

This is a *map*, not a proposal. It says where things are and how they connect.

---

## 1. The short version

Every Places call in the app goes through **one file**:

```
lib/core/common_bloc/place/repo/place_repo.dart
```

No screen calls `maps.googleapis.com` directly. That single chokepoint is the
most important fact in this document — it means provider changes, debounce
changes, or caching changes are edits to one file, not forty.

---

## 2. The three endpoints

Defined once, in `lib/environment_config.dart:29–34`:

| Line | Constant | URL | Billed as |
|---|---|---|---|
| 29 | `googleAutocomplete` | `place/autocomplete/json` | Autocomplete |
| 31 | `googlePlaceId` | `place/details/json` | Place Details |
| 33 | `googleGeoCode` | `geocode/json` | Geocoding |

A fourth Google product exists in the app but is **not Places** — the Maps
Static API in `lib/widgets/static_map_preview.dart:93`, used for non-interactive
map pictures.

---

## 3. Search and resolve are two different calls

This is the thing that surprises people reading the bill.

Google's autocomplete returns a **name and an opaque `place_id` — no
coordinates.** To turn a tapped suggestion into a lat/lng you must make a
second, separately-billed call to Place Details.

```
user types  →  autocomplete/json     →  "Rajpur Road, Dehradun" + place_id
user taps   →  details/json          →  { lat: 30.33, lng: 78.05 }
```

So one address entry = **two SKUs on the invoice**. That is why the call-site
counts below are lopsided: fewer screens *search* than *resolve*, because many
forms store a `place_id` and resolve it later.

---

## 4. The wrapper methods

All in `place_repo.dart`:

| Method | Line | Hits | Purpose |
|---|---|---|---|
| `autoCompleteSearch()` | 132 | Autocomplete | **The search.** Location-biased, India-only. |
| `getCitiesByState()` | 168 | Autocomplete | City list for a state (`types=(cities)`). |
| `getCompletePlaceDetails()` | ~210 | Place Details | `place_id` → coordinates + address components. |
| `resolvePlace()` | ~267 | Place Details | Cached wrapper over the above. **Prefer this.** |
| `getGeoCode()` | ~232 | Geocoding | Coordinates → address. One caller only. |

---

## 5. Who searches — 8 call sites

| # | File | Line |
|---|---|---|
| 1 | `widgets/common_location_search_field.dart` | 86 |
| 2 | `features/common/map/widget/search_place_list.dart` | 109 |
| 3 | `features/ride_booking/controller/ride_booking_controller.dart` | 526 |
| 4 | `features/common/Discover/view/book_your_transport/search_address_screen.dart` | 147 |
| 5 | `features/common/Discover/view/book_your_transport/search_transport_address.dart` | 465 |
| 6 | `features/common/Discover/view/book_your_transport/quick_rider_book_screen.dart` | 153 |
| 7 | `features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart` | 95 |
| 8 | `features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart` | 1038 |

### Rows 1 and 2 are where the volume actually is

They are **shared widgets**, not screens:

- `CommonLocationSearchField` — embedded in **30 files**
- `SearchPlaceList` — embedded in **3 files**

Those ~30 screens contain no reference to Places at all; they just drop in the
widget. They include business onboarding, rentals (flat / homestay / vehicle),
the hotel / hospital / school / laboratory / social / automotive contact-us and
branch forms, professional-consultant profiles, and the delivery-partner
screens.

**If you are looking for where the Autocomplete spend comes from, it is
overwhelmingly these two widgets — not the six named screens.**

---

## 6. Who resolves — 17 call sites

`getCompletePlaceDetails()` / `resolvePlace()` are called from:

- `widgets/common_location_search_field.dart:242`
- `features/common/map/widget/search_place_list.dart:150`
- `features/ride_booking/controller/ride_booking_controller.dart:558`
- `features/common/Discover/view/book_your_transport/search_address_screen.dart:191, 676`
- `features/common/Discover/view/book_your_transport/search_transport_address.dart:1374`
- `features/common/Discover/view/book_your_transport/quick_rider_book_screen.dart:189`
- `features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart:123`
- `features/me/laboratory/view/health_camp_form_screen.dart:166`
- `features/me/laboratory/view/lab_contact_us_screen.dart:192`
- `features/me/automotive_service/view/other_contact_us/other_branch_details_form_screen.dart:80`
- `features/me/automotive_service/view/other_contact_us/other_branch_only_screen.dart:96`
- `features/me/others/view/other_contact_us/other_branch_details_form_screen.dart:80`
- `features/me/others/view/other_contact_us/other_branch_only_screen.dart:96`
- `features/me/professionals_consultant/view/basic_profile_screen.dart:147`
- `features/me/professionals_consultant/view/professional_contact_us_screen.dart:207`
- `features/me/social/view/social_activity_form_screen.dart:181`
- `features/me/social/view/social_contact_us/social_contact_us_screen.dart:317`
- `features/me/social/view/social_create_event_screen.dart:211`
- `features/personal/personal_profile/view/rental/view/add_flat_room_rental_service_screen.dart:175`
- `features/personal/personal_profile/view/rental/view/home_stay_rental_service.dart:236`
- `features/personal/personal_profile/view/rental/view/vehicle_rental_service.dart:301`

### `resolvePlace()` vs `getCompletePlaceDetails()`

`resolvePlace()` caches by `place_id` for the app session, so the same landmark
resolved twice costs one call. `getCompletePlaceDetails()` does not.

Most of the `me/` form screens above call the **uncached** one directly. That is
the cheapest available cleanup in this list.

---

## 7. Who geocodes — 1 call site

`getGeoCode()` → `lib/core/controller/location_controller.dart:37`

It reads two things out of the response: `locality` (city) and `postal_code`
(pincode).

**Geocoding spend should be near zero.** Everywhere else, the app uses the
free on-device geocoder (`placemarkFromCoordinates`). If the Cloud Console shows
meaningful Geocoding volume, it is not coming from this app — check for a
backend job, an old app version, or a leaked key.

---

## 8. The throttles already in place

Worth knowing before you add more:

| Guard | Where | Value |
|---|---|---|
| Search debounce | `common_location_search_field.dart:64` | 600 ms |
| Search debounce | `ride_booking_controller.dart:494` | 600 ms |
| Minimum characters | `ride_booking_controller.dart:487` | 3 |
| Autocomplete cache | `place_repo.dart` | query + ~1 km location, 100 entries |
| `place_id` cache | `place_repo.dart` | session lifetime |
| Session token | `place_repo.dart` | 3 min, threaded search → details |

### About the session token

Google bills Places two ways. Without a token, every keystroke bills as
*Autocomplete – Per Request* **and** the closing Place Details bills separately.
With one token threaded through the whole typing session, the lot bills once as
*Autocomplete – Per Session*.

`place_repo.dart` owns that token lifecycle so no screen has to. If you add a new
search call site, route it through `PlaceRepo` and you inherit this for free —
bypass it and you will silently double-bill that flow.

---

## 9. If you want to change something

| Goal | Edit |
|---|---|
| Swap the search provider entirely | `place_repo.dart:132` |
| Change search behaviour for most screens | `common_location_search_field.dart` |
| Change the endpoints | `environment_config.dart:29–34` |
| Stop uncached Place Details in `me/` forms | replace `getCompletePlaceDetails` with `resolvePlace` |
| Reduce Autocomplete volume | raise debounce / min-chars in the two shared widgets |

---

## 10. The rule that matters most

**Never call Place Details in a loop over autocomplete predictions.**

Four screens used to do this — resolving *every* suggestion to render an
"x km away" label, at ~5 billed lookups per keystroke burst, to answer a question
the user asks about exactly one row. It was the single most expensive pattern in
the app. It is fixed, but the shape is easy to reintroduce.

Resolve on the row's **tap handler**, via `resolvePlace()`.

Background on that and the other cost work: `docs/GOOGLE_MAPS_COST_GUIDE.md`.
