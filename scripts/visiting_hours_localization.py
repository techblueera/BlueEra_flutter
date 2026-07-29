#!/usr/bin/env python3
"""Localization for the redesigned weekly visiting-hours selector
(lib/widgets/visiting_hour_selector.dart) and the business-hours sheet that
hosts it (lib/features/business/widgets/business_hours_sheet_content.dart).

`statusOpen` / `statusClosed` are deliberately NOT the existing `open` /
`closed` keys: those translate to the imperative verb in gu/mr/kn ("ખોલો" =
*open it*), which reads wrong as a state label next to a toggle.

`hoursCopiedToAllDays` uses GetX `trParams` with an `@day` placeholder.

Run:  python3 scripts/visiting_hours_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "visiting_hours_lang_payloads")

T = {
    "en": {
        "statusOpen": "Open",
        "statusClosed": "Closed",
        "updateBusinessHours": "Update Business Hours",
        "loadingBusinessHours": "Loading business hours...",
        "applyHoursToAllDays": "Apply these hours to all days",
        "hoursCopiedToAllDays": "@day's hours copied to all days",
    },
    "hi": {
        "statusOpen": "खुला",
        "statusClosed": "बंद",
        "updateBusinessHours": "व्यापार के घंटे अपडेट करें",
        "loadingBusinessHours": "व्यापार के घंटे लोड हो रहे हैं...",
        "applyHoursToAllDays": "ये घंटे सभी दिनों पर लागू करें",
        "hoursCopiedToAllDays": "@day के घंटे सभी दिनों में कॉपी किए गए",
    },
    "gu": {
        "statusOpen": "ખુલ્લું",
        "statusClosed": "બંધ",
        "updateBusinessHours": "વ્યવસાયના કલાકો અપડેટ કરો",
        "loadingBusinessHours": "વ્યવસાયના કલાકો લોડ થઈ રહ્યા છે...",
        "applyHoursToAllDays": "આ કલાકો બધા દિવસો પર લાગુ કરો",
        "hoursCopiedToAllDays": "@day ના કલાકો બધા દિવસોમાં કૉપિ થયા",
    },
    "mr": {
        "statusOpen": "उघडे",
        "statusClosed": "बंद",
        "updateBusinessHours": "व्यवसायाचे तास अपडेट करा",
        "loadingBusinessHours": "व्यवसायाचे तास लोड होत आहेत...",
        "applyHoursToAllDays": "हे तास सर्व दिवसांना लागू करा",
        "hoursCopiedToAllDays": "@day चे तास सर्व दिवसांमध्ये कॉपी केले",
    },
    "kn": {
        "statusOpen": "ತೆರೆದಿದೆ",
        "statusClosed": "ಮುಚ್ಚಲಾಗಿದೆ",
        "updateBusinessHours": "ವ್ಯವಹಾರದ ಸಮಯ ಅಪ್‌ಡೇಟ್ ಮಾಡಿ",
        "loadingBusinessHours": "ವ್ಯವಹಾರದ ಸಮಯ ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
        "applyHoursToAllDays": "ಈ ಸಮಯವನ್ನು ಎಲ್ಲಾ ದಿನಗಳಿಗೆ ಅನ್ವಯಿಸಿ",
        "hoursCopiedToAllDays": "@day ರ ಸಮಯವನ್ನು ಎಲ್ಲಾ ದಿನಗಳಿಗೆ ನಕಲಿಸಲಾಗಿದೆ",
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
