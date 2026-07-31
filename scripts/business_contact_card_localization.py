#!/usr/bin/env python3
"""Localization for `business/widgets/business_contact_map_card.dart`.

The Contact-Us card on the business profile carried nine hard-coded English
literals. Five of them map onto keys that already ship in all five languages
and were simply pointed at the existing keys in Dart:

  * 'Category of Business'      -> category_of_business
  * 'Select Category'           -> selectCategory
  * 'Sub-category'              -> subCategoryLabel
  * 'Select Sub-category'       -> select_sub_category
  * 'Please select a category'  -> please_select_category

The remaining four had no equivalent anywhere in the catalogue, so they are
NEW keys added here for en/hi/gu/mr/kn.

Everything else on the card (contactUs, na, update, save, cancel, confirm,
business_name, business_name_required, please_enter_business_details,
update_location, update_location_warning) was already complete in all five
languages -- verified, nothing to backfill.

Run:  python3 scripts/business_contact_card_localization.py
Then: bash scripts/business_contact_card_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "business_contact_card_lang_payloads")

T = {
    "en": {
        "business_update_category": "Update Category",
        "business_category_not_set": "Category not set",
        "business_location_not_set": "Location not set",
        "business_select_category_first": "Select a category first",
    },
    "hi": {
        "business_update_category": "श्रेणी अपडेट करें",
        "business_category_not_set": "श्रेणी सेट नहीं है",
        "business_location_not_set": "लोकेशन सेट नहीं है",
        "business_select_category_first": "पहले एक श्रेणी चुनें",
    },
    "gu": {
        "business_update_category": "કેટેગરી અપડેટ કરો",
        "business_category_not_set": "કેટેગરી સેટ કરેલી નથી",
        "business_location_not_set": "સ્થાન સેટ કરેલું નથી",
        "business_select_category_first": "પહેલા કેટેગરી પસંદ કરો",
    },
    "mr": {
        "business_update_category": "श्रेणी अपडेट करा",
        "business_category_not_set": "श्रेणी सेट केलेली नाही",
        "business_location_not_set": "स्थान सेट केलेले नाही",
        "business_select_category_first": "आधी श्रेणी निवडा",
    },
    "kn": {
        "business_update_category": "ವರ್ಗವನ್ನು ನವೀಕರಿಸಿ",
        "business_category_not_set": "ವರ್ಗ ಹೊಂದಿಸಿಲ್ಲ",
        "business_location_not_set": "ಸ್ಥಳ ಹೊಂದಿಸಿಲ್ಲ",
        "business_select_category_first": "ಮೊದಲು ವರ್ಗವನ್ನು ಆಯ್ಕೆಮಾಡಿ",
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
