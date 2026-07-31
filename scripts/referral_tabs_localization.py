#!/usr/bin/env python3
"""Localization for the referral dashboard tab strip.

`referral_dashboard_page.dart` had a hard-coded
`['Overview', 'Tutorial', 'Creator', 'Statics']`.

NEW keys:
  * tutorialTab — 'Tutorial'. NOT `tutoringChip`, which reads "Tutoring"
    (a different word) and only ever shipped in en; and not
    `grocery_view_tutorial`, which is grocery-namespaced.
  * creatorTab  — 'Creator'. `contentCreator` is "Content Creator", too
    long for a 4-up pill tab.

BACKFILL — `overviewTab` and `staticsTab` are reused here rather than
duplicated, but both shipped in en/hi only. Backfilled for gu/mr/kn, which
also fixes the tab strips on the manufacturer, product, vehicle, grocery,
automotive-parts and food admin screens that share these two keys.

Run:  python3 scripts/referral_tabs_localization.py
Then: bash scripts/referral_tabs_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "referral_tabs_lang_payloads")

T = {
    "en": {
        "tutorialTab": "Tutorial",
        "creatorTab": "Creator",
    },
    "hi": {
        "tutorialTab": "ट्यूटोरियल",
        "creatorTab": "क्रिएटर",
    },
    "gu": {
        "tutorialTab": "ટ્યુટોરિયલ",
        "creatorTab": "ક્રિએટર",
        # --- backfill ---
        "overviewTab": "ઝાંખી",
        "staticsTab": "આંકડા",
    },
    "mr": {
        "tutorialTab": "ट्यूटोरियल",
        "creatorTab": "क्रिएटर",
        # --- backfill ---
        "overviewTab": "आढावा",
        "staticsTab": "आकडेवारी",
    },
    "kn": {
        "tutorialTab": "ಟ್ಯುಟೋರಿಯಲ್",
        "creatorTab": "ಕ್ರಿಯೇಟರ್",
        # --- backfill ---
        "overviewTab": "ಅವಲೋಕನ",
        "staticsTab": "ಅಂಕಿಅಂಶಗಳು",
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
