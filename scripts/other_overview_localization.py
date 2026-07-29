#!/usr/bin/env python3
"""Localization for lib/features/me/others/view/v2/tabs/other_overview_tab_v2.dart.

Adds the missing en/hi/gu/mr/kn strings to the local asset JSONs and emits
per-language PUT payloads for the language service.

Run:  python3 scripts/other_overview_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "other_overview_lang_payloads")

T = {
    "en": {
        # section titles / actions already used by this tab
        "otherManagementTitle": "Management",
        "otherJobsTitle": "Career / Jobs",
        "otherTimingTitle": "Timing",
        "otherAddEdit": "Add / Edit",
        "otherOpen": "Open",
        "otherClosed": "Closed",
        # Banking Information card (Finance business type)
        "otherBankingInfoTitle": "Banking Information",
        "otherRbiRegistered": "RBI Registered",
        "otherAccountTypes": "Account Types",
        "otherNoAccountTypesSelected": "No account types selected",
        "otherAccountTypeSavings": "Savings",
        "otherAccountTypeCurrent": "Current",
        "otherAccountTypeFixedDeposit": "Fixed Deposit",
        "otherAccountTypeRecurringDeposit": "Recurring Deposit",
        "otherAccountTypeSalary": "Salary",
        "otherAccountTypeNri": "NRI",
        "otherAccountTypeDemat": "Demat",
    },
    "hi": {
        "otherManagementTitle": "प्रबंधन",
        "otherJobsTitle": "करियर / नौकरियां",
        "otherTimingTitle": "समय",
        "otherAddEdit": "जोड़ें / संपादित करें",
        "otherOpen": "खुला",
        "otherClosed": "बंद",
        "otherBankingInfoTitle": "बैंकिंग जानकारी",
        "otherRbiRegistered": "आरबीआई पंजीकृत",
        "otherAccountTypes": "खाता प्रकार",
        "otherNoAccountTypesSelected": "कोई खाता प्रकार चयनित नहीं है",
        "otherAccountTypeSavings": "बचत खाता",
        "otherAccountTypeCurrent": "चालू खाता",
        "otherAccountTypeFixedDeposit": "सावधि जमा",
        "otherAccountTypeRecurringDeposit": "आवर्ती जमा",
        "otherAccountTypeSalary": "वेतन खाता",
        "otherAccountTypeNri": "एनआरआई",
        "otherAccountTypeDemat": "डीमैट",
    },
    "gu": {
        "otherManagementTitle": "વ્યવસ્થાપન",
        "otherJobsTitle": "કારકિર્દી / નોકરીઓ",
        "otherTimingTitle": "સમય",
        "otherAddEdit": "ઉમેરો / સંપાદિત કરો",
        "otherOpen": "ખુલ્લું",
        "otherClosed": "બંધ",
        "otherBankingInfoTitle": "બેંકિંગ માહિતી",
        "otherRbiRegistered": "આરબીઆઈ નોંધાયેલ",
        "otherAccountTypes": "ખાતાના પ્રકાર",
        "otherNoAccountTypesSelected": "કોઈ ખાતાનો પ્રકાર પસંદ કરેલ નથી",
        "otherAccountTypeSavings": "બચત ખાતું",
        "otherAccountTypeCurrent": "ચાલુ ખાતું",
        "otherAccountTypeFixedDeposit": "મુદતી થાપણ",
        "otherAccountTypeRecurringDeposit": "આવર્તક થાપણ",
        "otherAccountTypeSalary": "પગાર ખાતું",
        "otherAccountTypeNri": "એનઆરઆઈ",
        "otherAccountTypeDemat": "ડીમેટ",
    },
    "mr": {
        "otherManagementTitle": "व्यवस्थापन",
        "otherJobsTitle": "करिअर / नोकऱ्या",
        "otherTimingTitle": "वेळ",
        "otherAddEdit": "जोडा / संपादित करा",
        "otherOpen": "उघडे",
        "otherClosed": "बंद",
        "otherBankingInfoTitle": "बँकिंग माहिती",
        "otherRbiRegistered": "आरबीआय नोंदणीकृत",
        "otherAccountTypes": "खात्याचे प्रकार",
        "otherNoAccountTypesSelected": "कोणताही खाते प्रकार निवडलेला नाही",
        "otherAccountTypeSavings": "बचत खाते",
        "otherAccountTypeCurrent": "चालू खाते",
        "otherAccountTypeFixedDeposit": "मुदत ठेव",
        "otherAccountTypeRecurringDeposit": "आवर्ती ठेव",
        "otherAccountTypeSalary": "पगार खाते",
        "otherAccountTypeNri": "एनआरआय",
        "otherAccountTypeDemat": "डिमॅट",
    },
    "kn": {
        "otherManagementTitle": "ಆಡಳಿತ ಮಂಡಳಿ",
        "otherJobsTitle": "ವೃತ್ತಿ / ಉದ್ಯೋಗಗಳು",
        "otherTimingTitle": "ಸಮಯ",
        "otherAddEdit": "ಸೇರಿಸಿ / ಸಂಪಾದಿಸಿ",
        "otherOpen": "ತೆರೆದಿದೆ",
        "otherClosed": "ಮುಚ್ಚಲಾಗಿದೆ",
        "otherBankingInfoTitle": "ಬ್ಯಾಂಕಿಂಗ್ ಮಾಹಿತಿ",
        "otherRbiRegistered": "ಆರ್‌ಬಿಐ ನೋಂದಾಯಿತ",
        "otherAccountTypes": "ಖಾತೆ ಪ್ರಕಾರಗಳು",
        "otherNoAccountTypesSelected": "ಯಾವುದೇ ಖಾತೆ ಪ್ರಕಾರ ಆಯ್ಕೆ ಮಾಡಿಲ್ಲ",
        "otherAccountTypeSavings": "ಉಳಿತಾಯ ಖಾತೆ",
        "otherAccountTypeCurrent": "ಚಾಲ್ತಿ ಖಾತೆ",
        "otherAccountTypeFixedDeposit": "ನಿಶ್ಚಿತ ಠೇವಣಿ",
        "otherAccountTypeRecurringDeposit": "ಪುನರಾವರ್ತಿತ ಠೇವಣಿ",
        "otherAccountTypeSalary": "ಸಂಬಳ ಖಾತೆ",
        "otherAccountTypeNri": "ಎನ್‌ಆರ್‌ಐ",
        "otherAccountTypeDemat": "ಡಿಮ್ಯಾಟ್",
    },
}

os.makedirs(OUT_DIR, exist_ok=True)

for lang, entries in T.items():
    # 1. merge into the bundled asset translations, preserving each file's
    #    existing layout (gu/mr/kn are key-sorted, en/hi are append-ordered)
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

    # 2. emit the PUT payload for the language service
    out = os.path.join(OUT_DIR, f"{lang}.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"{lang}: {len(entries)} keys written ({len(added)} new locally)")
