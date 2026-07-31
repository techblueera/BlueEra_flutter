#!/usr/bin/env python3
"""Localization for the `healthCareList` category tiles.

Covers the five `name` values in `healthCareList`
(lib/core/constants/app_constant.dart) — the Discover healthcare grid tiles
and the healthcare listing's sticky category header.

`healthCareList` is a top-level `final`, so it is built once on first access
and cached for the process lifetime. Calling `.tr` inside the list would
freeze each label in whatever language was active at that moment and never
follow a language change, so `name` holds the KEY and the three render sites
call `.tr` instead. Labels are kept short — the grid is five columns wide.

Run:  python3 scripts/healthcare_categories_localization.py
Then: bash scripts/healthcare_categories_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "healthcare_categories_lang_payloads")

T = {
    "en": {
        "healthcareHospitals": "Hospitals",
        "healthcareDoctors": "Doctors",
        "healthcareLabs": "Labs",
        "healthcarePharmacy": "Pharmacy",
        "healthcareSurgical": "Surgical",
    },
    "hi": {
        "healthcareHospitals": "अस्पताल",
        "healthcareDoctors": "डॉक्टर",
        "healthcareLabs": "प्रयोगशालाएं",
        "healthcarePharmacy": "फार्मेसी",
        "healthcareSurgical": "सर्जिकल",
    },
    "gu": {
        "healthcareHospitals": "હોસ્પિટલ",
        "healthcareDoctors": "ડૉક્ટર",
        "healthcareLabs": "લેબ",
        "healthcarePharmacy": "ફાર્મસી",
        "healthcareSurgical": "સર્જિકલ",
    },
    "mr": {
        "healthcareHospitals": "रुग्णालये",
        "healthcareDoctors": "डॉक्टर",
        "healthcareLabs": "प्रयोगशाळा",
        "healthcarePharmacy": "फार्मसी",
        "healthcareSurgical": "सर्जिकल",
    },
    "kn": {
        "healthcareHospitals": "ಆಸ್ಪತ್ರೆಗಳು",
        "healthcareDoctors": "ವೈದ್ಯರು",
        "healthcareLabs": "ಪ್ರಯೋಗಾಲಯಗಳು",
        "healthcarePharmacy": "ಔಷಧಾಲಯ",
        "healthcareSurgical": "ಶಸ್ತ್ರಚಿಕಿತ್ಸಾ",
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
