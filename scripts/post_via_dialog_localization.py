#!/usr/bin/env python3
"""Localization for the "Post Via" chooser dialog.

Covers `widgets/post_via_dialog.dart` — the channel-vs-profile sheet shown to
individual users who already have a channel, before a message / poll / reel is
composed.

NEW keys — the two option subtitles, the only strings on the dialog still
hard-coded in English:
  * shareWithYourChannelFollowers — under the Channel option
  * postFromYourPersonalProfile   — under the Profile option

Reused as-is (already complete in all five languages): `postVia`,
`chooseWhereToPost`, `channel`, `profile`, `cancel`, `post`.

Run:  python3 scripts/post_via_dialog_localization.py
Then: bash scripts/post_via_dialog_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "post_via_dialog_lang_payloads")

T = {
    "en": {
        "shareWithYourChannelFollowers": "Share with your channel followers",
        "postFromYourPersonalProfile": "Post from your personal profile",
    },
    "hi": {
        "shareWithYourChannelFollowers":
            "अपने चैनल फ़ॉलोअर्स के साथ शेयर करें",
        "postFromYourPersonalProfile":
            "अपनी पर्सनल प्रोफ़ाइल से पोस्ट करें",
    },
    "gu": {
        "shareWithYourChannelFollowers":
            "તમારા ચેનલ ફોલોઅર્સ સાથે શેર કરો",
        "postFromYourPersonalProfile":
            "તમારી પર્સનલ પ્રોફાઇલ પરથી પોસ્ટ કરો",
    },
    "mr": {
        "shareWithYourChannelFollowers":
            "तुमच्या चॅनल फॉलोअर्ससोबत शेअर करा",
        "postFromYourPersonalProfile":
            "तुमच्या पर्सनल प्रोफाइलवरून पोस्ट करा",
    },
    "kn": {
        "shareWithYourChannelFollowers":
            "ನಿಮ್ಮ ಚಾನೆಲ್ ಫಾಲೋವರ್‌ಗಳೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ",
        "postFromYourPersonalProfile":
            "ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಪ್ರೊಫೈಲ್‌ನಿಂದ ಪೋಸ್ಟ್ ಮಾಡಿ",
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
