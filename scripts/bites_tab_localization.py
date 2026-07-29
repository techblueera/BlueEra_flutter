#!/usr/bin/env python3
"""Localization for the order/chat main feed TabBar
(lib/features/chat/view/order_main_chat_screen.dart).

  * NEW      — `bites`, the reels tab label, which was hardcoded.
  * BACKFILL — `social` / `community`, the two sibling tabs in the same TabBar,
               which had only shipped in en+hi; existing values reused verbatim.

"Bites" is a feature name, so it is transliterated rather than translated —
matching how the existing `reels` key is handled in each language.

Run:  python3 scripts/bites_tab_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "bites_tab_lang_payloads")

T = {
    "en": {
        "bites": "Bites",
        "social": "Social",
        "community": "Community",
    },
    "hi": {
        "bites": "बाइट्स",
        "social": "सोशल",
        "community": "समुदाय",
    },
    "gu": {
        "bites": "બાઇટ્સ",
        "social": "સોશિયલ",
        "community": "સમુદાય",
    },
    "mr": {
        "bites": "बाइट्स",
        "social": "सोशल",
        "community": "समुदाय",
    },
    "kn": {
        "bites": "ಬೈಟ್ಸ್",
        "social": "ಸೋಶಿಯಲ್",
        "community": "ಸಮುದಾಯ",
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
