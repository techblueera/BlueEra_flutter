#!/usr/bin/env python3
"""Localization for the referral code card + "Update Referral Code" screen.

Covers:
  * `common/referral/widgets/generate_referral_section.dart`
  * `common/referral/view/update_referral_page.dart`   (app bar title)
  * `common/referral/view/referral_dashboard_page.dart` (the affordance)

NEW keys:
  * updateReferralCode            — the screen title and the dashboard row
  * referralCodeAlphanumericError — third validator branch on the code field

BACKFILL — the whole referral card shipped in en/hi only, so every label on
it was falling back to English for Gujarati/Marathi/Kannada users. Seven keys
backfilled for gu/mr/kn: generateYourReferralCode, enterYourReferralCode,
referralTip, referralSuggestions, iAcceptAll, termsAndCondition,
authorizationMessage.

Reused as-is (already complete in all five languages): `update`, `submit`,
`referralCodeLengthError`, `pleaseEnterReferralCode` (the empty-field
validator branch), `termsConditions`.

Run:  python3 scripts/referral_section_localization.py
Then: bash scripts/referral_section_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "referral_section_lang_payloads")

T = {
    "en": {
        "updateReferralCode": "Update Referral Code",
        "referralCodeAlphanumericError":
            "Code must contain both letters and numbers",
    },
    "hi": {
        "updateReferralCode": "रेफरल कोड अपडेट करें",
        "referralCodeAlphanumericError":
            "कोड में अक्षर और संख्या दोनों होने चाहिए",
    },
    "gu": {
        "updateReferralCode": "રેફરલ કોડ અપડેટ કરો",
        "referralCodeAlphanumericError":
            "કોડમાં અક્ષરો અને અંકો બંને હોવા જોઈએ",
        # --- backfill ---
        "generateYourReferralCode": "તમારો રેફરલ કોડ જનરેટ કરો",
        "enterYourReferralCode": "તમારો રેફરલ કોડ દાખલ કરો",
        "referralTip":
            "ટિપ: 4-10 અક્ષરો વાપરો, અક્ષરો અને અંકો મિક્સ કરીને "
            "(દા.ત., SAVE50).",
        "referralSuggestions": "રેફરલ સૂચનો",
        "iAcceptAll": "હું બધું સ્વીકારું છું",
        "termsAndCondition": "નિયમો અને શરતો",
        "authorizationMessage":
            "અને હું તમને SMS/RCS સંદેશા/પ્રમોશનલ/માહિતીપ્રદ સંદેશા દ્વારા "
            "સૂચનાઓ મોકલવા માટે અધિકૃત કરું છું.",
    },
    "mr": {
        "updateReferralCode": "रेफरल कोड अपडेट करा",
        "referralCodeAlphanumericError":
            "कोडमध्ये अक्षरे आणि अंक दोन्ही असणे आवश्यक आहे",
        # --- backfill ---
        "generateYourReferralCode": "तुमचा रेफरल कोड तयार करा",
        "enterYourReferralCode": "तुमचा रेफरल कोड टाका",
        "referralTip":
            "टिप: 4-10 अक्षरे वापरा, अक्षरे आणि अंक मिसळून "
            "(उदा., SAVE50).",
        "referralSuggestions": "रेफरल सूचना",
        "iAcceptAll": "मी सर्व स्वीकारतो",
        "termsAndCondition": "नियम व अटी",
        "authorizationMessage":
            "आणि मी तुम्हाला SMS/RCS संदेश/प्रचारात्मक/माहितीपर संदेशांद्वारे "
            "सूचना पाठवण्यास अधिकृत करतो.",
    },
    "kn": {
        "updateReferralCode": "ರೆಫರಲ್ ಕೋಡ್ ನವೀಕರಿಸಿ",
        "referralCodeAlphanumericError":
            "ಕೋಡ್‌ನಲ್ಲಿ ಅಕ್ಷರಗಳು ಮತ್ತು ಸಂಖ್ಯೆಗಳು ಎರಡೂ ಇರಬೇಕು",
        # --- backfill ---
        "generateYourReferralCode": "ನಿಮ್ಮ ರೆಫರಲ್ ಕೋಡ್ ರಚಿಸಿ",
        "enterYourReferralCode": "ನಿಮ್ಮ ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ",
        "referralTip":
            "ಸಲಹೆ: 4-10 ಅಕ್ಷರಗಳನ್ನು ಬಳಸಿ, ಅಕ್ಷರಗಳು ಮತ್ತು ಸಂಖ್ಯೆಗಳನ್ನು "
            "ಬೆರೆಸಿ (ಉದಾ., SAVE50).",
        "referralSuggestions": "ರೆಫರಲ್ ಸಲಹೆಗಳು",
        "iAcceptAll": "ನಾನು ಎಲ್ಲವನ್ನೂ ಒಪ್ಪುತ್ತೇನೆ",
        "termsAndCondition": "ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು",
        "authorizationMessage":
            "ಮತ್ತು SMS/RCS ಸಂದೇಶಗಳು/ಪ್ರಚಾರ/ಮಾಹಿತಿ ಸಂದೇಶಗಳ ಮೂಲಕ ಅಧಿಸೂಚನೆಗಳನ್ನು "
            "ಕಳುಹಿಸಲು ನಾನು ನಿಮಗೆ ಅಧಿಕಾರ ನೀಡುತ್ತೇನೆ.",
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
