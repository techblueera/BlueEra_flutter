#!/usr/bin/env python3
"""Localization for the referral share card headline + share-via label.

Covers `business/widgets/profile_share_banner.dart` — the card rendered on the
me-section profile screens, the Discover promo sheet and the share dialog.

NEW keys:
  * shareOneTimeEarnFullYear — the 24px two-line headline. The run wrapped in
    `{}` is the highlighted (blue) part; the widget parses the marker out and
    tints only that run. English trails it ("Earn {Full Year}"), but Hindi,
    Gujarati, Marathi and Kannada all place the duration BEFORE the verb, so
    the marker moves with the translation instead of pinning every language to
    English word order.
  * shareYourReferralCodeVia — the label above the WhatsApp / Instagram /
    system-sheet buttons.

Reused as-is (already complete in all five languages): `yourReferralCode`,
`learn_more`, `termsConditions`.

Run:  python3 scripts/referral_share_card_localization.py
Then: bash scripts/referral_share_card_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "referral_share_card_lang_payloads")

T = {
    "en": {
        "shareOneTimeEarnFullYear": "Share One-Time,\nEarn {Full Year}",
        "shareYourReferralCodeVia": "Share Your Referral Code Via",
    },
    "hi": {
        "shareOneTimeEarnFullYear": "एक बार शेयर करें,\n{पूरे साल} कमाएँ",
        "shareYourReferralCodeVia": "अपना रेफरल कोड इसके ज़रिए शेयर करें",
    },
    "gu": {
        "shareOneTimeEarnFullYear": "એક વાર શેર કરો,\n{આખું વર્ષ} કમાઓ",
        "shareYourReferralCodeVia": "તમારો રેફરલ કોડ આના દ્વારા શેર કરો",
    },
    "mr": {
        "shareOneTimeEarnFullYear": "एकदा शेअर करा,\n{वर्षभर} कमवा",
        "shareYourReferralCodeVia": "तुमचा रेफरल कोड याद्वारे शेअर करा",
    },
    "kn": {
        "shareOneTimeEarnFullYear": "ಒಮ್ಮೆ ಹಂಚಿಕೊಳ್ಳಿ,\n{ಪೂರ್ಣ ವರ್ಷ} ಗಳಿಸಿ",
        "shareYourReferralCodeVia": "ನಿಮ್ಮ ರೆಫರಲ್ ಕೋಡ್ ಇದರ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ",
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
