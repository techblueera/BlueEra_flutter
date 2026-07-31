#!/usr/bin/env python3
"""Localization for the Discover doctor public profile screen.

Covers the hardcoded strings in
  lib/features/common/Discover/view/healthcare/doctor_public_profile_screen.dart

  * NEW      — the "About the Doctor" section title, the only label on the
               screen with no existing key.
  * BACKFILL — `yearLabel`, which had only shipped in en+hi; the experience
               value ("1 Year" / "16 Years") reads it, so gu/mr/kn would
               otherwise render the raw key.

Every other label on the screen already has a key and is reused as-is:
`doctorDegree`, `doctorSpecialization`, `doctorExperience`,
`doctorRegistrationNumber`, `doctorConsultationFee`, `doctorLanguagesSpoken`,
`addressLabel`, `doctorExpertise`, `doctorCertificateAwards`, `doctorYears`,
`certificate`, `gallery` and `inquiry`.

Run:  python3 scripts/doctor_public_profile_localization.py
Then: bash scripts/doctor_public_profile_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "doctor_public_profile_lang_payloads")

T = {
    "en": {
        "doctorAboutTheDoctor": "About the Doctor",
        # --- backfill (existing en value) ---
        "yearLabel": "Year",
    },
    "hi": {
        "doctorAboutTheDoctor": "डॉक्टर के बारे में",
        "yearLabel": "वर्ष",
    },
    "gu": {
        "doctorAboutTheDoctor": "ડૉક્ટર વિશે",
        "yearLabel": "વર્ષ",
    },
    "mr": {
        "doctorAboutTheDoctor": "डॉक्टरांबद्दल",
        "yearLabel": "वर्ष",
    },
    "kn": {
        "doctorAboutTheDoctor": "ವೈದ್ಯರ ಬಗ್ಗೆ",
        "yearLabel": "ವರ್ಷ",
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
