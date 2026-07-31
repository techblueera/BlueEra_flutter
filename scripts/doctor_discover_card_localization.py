#!/usr/bin/env python3
"""Localization for the Discover doctor list + card.

Covers every hardcoded string in
  * lib/features/common/Discover/view/healthcare/doctor_discover_list_screen.dart
  * lib/features/common/Discover/widget/doctor_discover_card.dart

  * NEW      — screen title, empty state, name fallback, availability header,
               "Timing not set" / "Closed today", the experience line, the
               "+N More" chip counter and the share sheet text.
  * BACKFILL — `bookNow`, which had only shipped in en+hi; the card's footer
               CTA reads it, so gu/mr/kn would otherwise render the raw key.

Everything else the card draws already has a key — `viewProfile`, `share`,
`doctorConsultationFee`, `closed`, `doctorExperience` and `monday`..`sunday`
are reused as-is rather than duplicated here.

Run:  python3 scripts/doctor_discover_card_localization.py
Then: bash scripts/doctor_discover_card_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "doctor_discover_card_lang_payloads")

T = {
    "en": {
        "doctorDiscoverTitle": "Clinic Doctors",
        "doctorDiscoverEmpty": "No doctors found",
        "doctorDiscoverFallbackName": "Doctor",
        "doctorDiscoverAvailability": "Availability",
        "doctorDiscoverTimingNotSet": "Timing not set",
        "doctorDiscoverClosedToday": "Closed today",
        "doctorDiscoverExperienceYearFmt": "@count Year Experience",
        "doctorDiscoverExperienceYearsFmt": "@count Years Experience",
        "doctorDiscoverMoreFmt": "+@count More",
        "doctorDiscoverShareFmt": "Check out @name on BlueEra",
        # --- backfill (existing en value) ---
        "bookNow": "Book Now",
    },
    "hi": {
        "doctorDiscoverTitle": "क्लिनिक डॉक्टर",
        "doctorDiscoverEmpty": "कोई डॉक्टर नहीं मिला",
        "doctorDiscoverFallbackName": "डॉक्टर",
        "doctorDiscoverAvailability": "उपलब्धता",
        "doctorDiscoverTimingNotSet": "समय निर्धारित नहीं",
        "doctorDiscoverClosedToday": "आज बंद",
        "doctorDiscoverExperienceYearFmt": "@count वर्ष का अनुभव",
        "doctorDiscoverExperienceYearsFmt": "@count वर्ष का अनुभव",
        "doctorDiscoverMoreFmt": "+@count और",
        "doctorDiscoverShareFmt": "BlueEra पर @name को देखें",
        "bookNow": "अभी बुक करें",
    },
    "gu": {
        "doctorDiscoverTitle": "ક્લિનિક ડૉક્ટર",
        "doctorDiscoverEmpty": "કોઈ ડૉક્ટર મળ્યા નથી",
        "doctorDiscoverFallbackName": "ડૉક્ટર",
        "doctorDiscoverAvailability": "ઉપલબ્ધતા",
        "doctorDiscoverTimingNotSet": "સમય સેટ કરેલ નથી",
        "doctorDiscoverClosedToday": "આજે બંધ",
        "doctorDiscoverExperienceYearFmt": "@count વર્ષનો અનુભવ",
        "doctorDiscoverExperienceYearsFmt": "@count વર્ષનો અનુભવ",
        "doctorDiscoverMoreFmt": "+@count વધુ",
        "doctorDiscoverShareFmt": "BlueEra પર @name ને જુઓ",
        "bookNow": "હમણાં બુક કરો",
    },
    "mr": {
        "doctorDiscoverTitle": "क्लिनिक डॉक्टर",
        "doctorDiscoverEmpty": "कोणतेही डॉक्टर आढळले नाहीत",
        "doctorDiscoverFallbackName": "डॉक्टर",
        "doctorDiscoverAvailability": "उपलब्धता",
        "doctorDiscoverTimingNotSet": "वेळ सेट केलेली नाही",
        "doctorDiscoverClosedToday": "आज बंद",
        "doctorDiscoverExperienceYearFmt": "@count वर्षाचा अनुभव",
        "doctorDiscoverExperienceYearsFmt": "@count वर्षांचा अनुभव",
        "doctorDiscoverMoreFmt": "+@count अधिक",
        "doctorDiscoverShareFmt": "BlueEra वर @name पहा",
        "bookNow": "आता बुक करा",
    },
    "kn": {
        "doctorDiscoverTitle": "ಕ್ಲಿನಿಕ್ ವೈದ್ಯರು",
        "doctorDiscoverEmpty": "ಯಾವುದೇ ವೈದ್ಯರು ಕಂಡುಬಂದಿಲ್ಲ",
        "doctorDiscoverFallbackName": "ವೈದ್ಯರು",
        "doctorDiscoverAvailability": "ಲಭ್ಯತೆ",
        "doctorDiscoverTimingNotSet": "ಸಮಯ ಹೊಂದಿಸಿಲ್ಲ",
        "doctorDiscoverClosedToday": "ಇಂದು ಮುಚ್ಚಲಾಗಿದೆ",
        "doctorDiscoverExperienceYearFmt": "@count ವರ್ಷದ ಅನುಭವ",
        "doctorDiscoverExperienceYearsFmt": "@count ವರ್ಷಗಳ ಅನುಭವ",
        "doctorDiscoverMoreFmt": "+@count ಇನ್ನಷ್ಟು",
        "doctorDiscoverShareFmt": "BlueEra ನಲ್ಲಿ @name ಅನ್ನು ನೋಡಿ",
        "bookNow": "ಈಗ ಬುಕ್ ಮಾಡಿ",
    },
}

os.makedirs(OUT_DIR, exist_ok=True)

for lang, entries in T.items():
    path = os.path.join(TRANS_DIR, f"{lang}.json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    added = [k for k in entries if k not in data]
    existing = [k for k in data if k not in added]
    data.update(entries)
    if existing == sorted(existing):
        data = {k: data[k] for k in sorted(data)}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    out = os.path.join(OUT_DIR, f"{lang}.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"{lang}: {len(entries)} keys written ({len(added)} new locally)")
