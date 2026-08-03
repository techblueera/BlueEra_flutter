#!/usr/bin/env python3
"""Localization for the automotive-products CUSTOMER (consumer) flow.

Covers the nine files under `features/me/automotive_products/view/customer/`:
all-business products, category discover, self-pickup cart, store card, store
details, store list, store product card, visit-products, visit-store-details.

Like the admin flow, this module was cloned from grocery with a blanket
"Product" -> "AutomotiveProduct" rename that also hit display strings, so the
ENGLISH source read "Top Selling AutomotiveProduct", "AutomotivePrice: ",
"AutomotiveCategory", "On All AutomotiveItems". Fixed to plain English here.

Interpolated strings use the repo's `@param` convention. Counted nouns pass a
pre-composed "3 items" phrase into the slot rather than a bare number, because
item/shop/view/order pluralize as separate words in these languages.

Reused as-is (already complete in all five): `all`, `cancel`, `remove`,
`category`, `noProductsFound`, `offCaps`, `viewAll`, `other`, `store`, `skip`,
`no`, `na`, and the `automotiveProducts*` keys added for the admin flow.

BUG FIX — `placeOrder`, `placeOrderCartWarning` and `noStoresFoundForCategory`
are referenced by automotive_category_discover_screen.dart and
automotive_products_store_screen.dart but existed ONLY in the local hi asset:
absent from local en/gu/mr/kn AND absent from the language service entirely.
GetX `.tr` returns the key itself on a miss, so those screens were rendering
the literal strings "placeOrder" and "placeOrderCartWarning" on screen for
every language except Hindi. All three are defined for all five here (Hindi
keeps its existing wording, now also pushed to the server).

NOTE: the share-sheet payload in automotive_category_discover_screen
("Check out X on BlueEra: <link>") is deliberately left in English — it is
addressed to whoever RECEIVES the share, not to the sender picking the app
language. Same call as the referral share message.

Run:  python3 scripts/automotive_customer_localization.py
Then: bash scripts/automotive_customer_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "automotive_customer_lang_payloads")

KEYS = {
    # ---- counted-noun labels composed into the @param strings ----
    "automotiveItemLabel": {
        "en": "item", "hi": "आइटम", "gu": "આઇટમ", "mr": "आयटम",
        "kn": "ವಸ್ತು",
    },
    "automotiveItemsLabel": {
        "en": "items", "hi": "आइटम", "gu": "આઇટમ", "mr": "आयटम",
        "kn": "ವಸ್ತುಗಳು",
    },
    "automotiveShopLabel": {
        "en": "Shop", "hi": "दुकान", "gu": "દુકાન", "mr": "दुकान",
        "kn": "ಅಂಗಡಿ",
    },
    "automotiveShopsLabel": {
        "en": "Shops", "hi": "दुकानें", "gu": "દુકાનો", "mr": "दुकाने",
        "kn": "ಅಂಗಡಿಗಳು",
    },
    "automotiveViewLabel": {
        "en": "view", "hi": "व्यू", "gu": "વ્યૂ", "mr": "व्ह्यू",
        "kn": "ವೀಕ್ಷಣೆ",
    },
    "automotiveViewsLabel": {
        "en": "views", "hi": "व्यूज़", "gu": "વ્યૂઝ", "mr": "व्ह्यूज",
        "kn": "ವೀಕ್ಷಣೆಗಳು",
    },
    "automotiveOrderLabel": {
        "en": "order", "hi": "ऑर्डर", "gu": "ઓર્ડર", "mr": "ऑर्डर",
        "kn": "ಆರ್ಡರ್",
    },
    "automotiveOrdersLabel": {
        "en": "orders", "hi": "ऑर्डर", "gu": "ઓર્ડર", "mr": "ऑर्डर",
        "kn": "ಆರ್ಡರ್‌ಗಳು",
    },
    # ---- all-business products / visit products ----
    "automotiveNoCategoryProductsFmt": {
        "en": "No @category products found",
        "hi": "कोई @category प्रोडक्ट नहीं मिला",
        "gu": "કોઈ @category પ્રોડક્ટ મળ્યું નથી",
        "mr": "कोणतेही @category प्रॉडक्ट सापडले नाही",
        "kn": "ಯಾವುದೇ @category ಉತ್ಪನ್ನಗಳು ಸಿಗಲಿಲ್ಲ",
    },
    # ---- category discover ----
    "automotiveLeaveWithoutOrdering": {
        "en": "Leave without ordering?", "hi": "बिना ऑर्डर किए जाएँ?",
        "gu": "ઓર્ડર કર્યા વગર જવું છે?", "mr": "ऑर्डर न करता जायचे?",
        "kn": "ಆರ್ಡರ್ ಮಾಡದೆ ಹೊರಡಬೇಕೇ?",
    },
    "automotiveNoProductsInCategory": {
        "en": "No products in this category",
        "hi": "इस श्रेणी में कोई प्रोडक्ट नहीं",
        "gu": "આ શ્રેણીમાં કોઈ પ્રોડક્ટ નથી",
        "mr": "या श्रेणीत कोणतेही प्रॉडक्ट नाही",
        "kn": "ಈ ವರ್ಗದಲ್ಲಿ ಯಾವುದೇ ಉತ್ಪನ್ನಗಳಿಲ್ಲ",
    },
    # ---- self-pickup cart ----
    "automotiveSelfPickUpFmt": {
        "en": "Self Pick-Up (@count)", "hi": "सेल्फ पिक-अप (@count)",
        "gu": "સેલ્ફ પિક-અપ (@count)", "mr": "सेल्फ पिक-अप (@count)",
        "kn": "ಸ್ವಯಂ ಪಿಕ್-ಅಪ್ (@count)",
    },
    "automotiveNoItemsSelfPickup": {
        "en": "No items in self pick-up",
        "hi": "सेल्फ पिक-अप में कोई आइटम नहीं",
        "gu": "સેલ્ફ પિક-અપમાં કોઈ આઇટમ નથી",
        "mr": "सेल्फ पिक-अपमध्ये कोणतेही आयटम नाहीत",
        "kn": "ಸ್ವಯಂ ಪಿಕ್-ಅಪ್‌ನಲ್ಲಿ ಯಾವುದೇ ವಸ್ತುಗಳಿಲ್ಲ",
    },
    "automotiveUnknownStore": {
        "en": "Unknown Store", "hi": "अज्ञात स्टोर", "gu": "અજ્ઞાત સ્ટોર",
        "mr": "अज्ञात स्टोअर", "kn": "ಅಪರಿಚಿತ ಅಂಗಡಿ",
    },
    "automotiveRemoveFromCart": {
        "en": "Remove from cart?", "hi": "कार्ट से हटाएँ?",
        "gu": "કાર્ટમાંથી દૂર કરવું?", "mr": "कार्टमधून काढायचे?",
        "kn": "ಕಾರ್ಟ್‌ನಿಂದ ತೆಗೆಯಬೇಕೇ?",
    },
    "automotiveRemoveFromCartMsgFmt": {
        "en": "\"@name\" will be removed from your cart.",
        "hi": "\"@name\" आपके कार्ट से हटा दिया जाएगा।",
        "gu": "\"@name\" તમારા કાર્ટમાંથી દૂર કરવામાં આવશે.",
        "mr": "\"@name\" तुमच्या कार्टमधून काढले जाईल.",
        "kn": "\"@name\" ಅನ್ನು ನಿಮ್ಮ ಕಾರ್ಟ್‌ನಿಂದ ತೆಗೆಯಲಾಗುತ್ತದೆ.",
    },
    "automotiveThisProduct": {
        "en": "This product", "hi": "यह प्रोडक्ट", "gu": "આ પ્રોડક્ટ",
        "mr": "हे प्रॉडक्ट", "kn": "ಈ ಉತ್ಪನ್ನ",
    },
    "automotiveEachPriceFmt": {
        "en": "@price each", "hi": "@price प्रति नग",
        "gu": "@price પ્રતિ નંગ", "mr": "@price प्रति नग",
        "kn": "ಪ್ರತಿ ಘಟಕಕ್ಕೆ @price",
    },
    "automotiveOnAllItems": {
        "en": "On All Items", "hi": "सभी आइटम पर", "gu": "બધા આઇટમ પર",
        "mr": "सर्व आयटमवर", "kn": "ಎಲ್ಲಾ ವಸ್ತುಗಳ ಮೇಲೆ",
    },
    # Structural only — the slots carry the already-translated phrases, so the
    # value is identical in every language.
    "automotiveShopItemsFmt": {
        "en": "@shop (@items)", "hi": "@shop (@items)",
        "gu": "@shop (@items)", "mr": "@shop (@items)",
        "kn": "@shop (@items)",
    },
    "automotiveShopsProductsFmt": {
        "en": "@shops | @products", "hi": "@shops | @products",
        "gu": "@shops | @products", "mr": "@shops | @products",
        "kn": "@shops | @products",
    },
    # ---- store card ----
    "automotiveUnknownBusiness": {
        "en": "Unknown Business", "hi": "अज्ञात व्यवसाय",
        "gu": "અજ્ઞાત વ્યવસાય", "mr": "अज्ञात व्यवसाय",
        "kn": "ಅಪರಿಚಿತ ವ್ಯವಹಾರ",
    },
    "automotiveProductTitle": {
        "en": "Product", "hi": "प्रोडक्ट", "gu": "પ્રોડક્ટ",
        "mr": "प्रॉडक्ट", "kn": "ಉತ್ಪನ್ನ",
    },
    "automotiveKmAwayFmt": {
        "en": "@km Km Away", "hi": "@km किमी दूर", "gu": "@km કિમી દૂર",
        "mr": "@km किमी दूर", "kn": "@km ಕಿಮೀ ದೂರ",
    },
    "automotiveTotalOnStoreFmt": {
        "en": "Total @label on this store,",
        "hi": "इस स्टोर पर कुल @label,",
        "gu": "આ સ્ટોર પર કુલ @label,",
        "mr": "या स्टोअरवर एकूण @label,",
        "kn": "ಈ ಅಂಗಡಿಯಲ್ಲಿ ಒಟ್ಟು @label,",
    },
    "automotiveSinceFmt": {
        "en": "Since @year", "hi": "@year से", "gu": "@year થી",
        "mr": "@year पासून", "kn": "@year ರಿಂದ",
    },
    "automotivePriceLabel": {
        "en": "Price: ", "hi": "कीमत: ", "gu": "કિંમત: ",
        "mr": "किंमत: ", "kn": "ಬೆಲೆ: ",
    },
    # ---- store details / visit store details ----
    "automotiveLivePhotos": {
        "en": "Live Photos", "hi": "लाइव फ़ोटो", "gu": "લાઇવ ફોટા",
        "mr": "लाइव्ह फोटो", "kn": "ಲೈವ್ ಫೋಟೋಗಳು",
    },
    "automotiveTopSellingProduct": {
        "en": "Top Selling Product",
        "hi": "सबसे ज़्यादा बिकने वाला प्रोडक्ट",
        "gu": "સૌથી વધુ વેચાતું પ્રોડક્ટ",
        "mr": "सर्वाधिक विकले जाणारे प्रॉडक्ट",
        "kn": "ಅತಿ ಹೆಚ್ಚು ಮಾರಾಟವಾಗುವ ಉತ್ಪನ್ನ",
    },
    "automotiveStoreNoProducts": {
        "en": "This store has no products yet.",
        "hi": "इस स्टोर पर अभी कोई प्रोडक्ट नहीं है।",
        "gu": "આ સ્ટોર પર હજી કોઈ પ્રોડક્ટ નથી.",
        "mr": "या स्टोअरवर अजून कोणतेही प्रॉडक्ट नाही.",
        "kn": "ಈ ಅಂಗಡಿಯಲ್ಲಿ ಇನ್ನೂ ಯಾವುದೇ ಉತ್ಪನ್ನಗಳಿಲ್ಲ.",
    },
}

# ── Broken keys: referenced by these screens, defined almost nowhere. ──
# Hindi already had all three locally (kept verbatim); every other language
# was rendering the raw key name on screen. None were on the server at all.
BACKFILL = {
    "placeOrder": {
        "en": "Place Order", "hi": "ऑर्डर दें", "gu": "ઓર્ડર આપો",
        "mr": "ऑर्डर द्या", "kn": "ಆರ್ಡರ್ ಮಾಡಿ",
    },
    "placeOrderCartWarning": {
        "en": "Place your order, otherwise\nyour cart will be emptied and\n"
              "you won't be able to see the selected items",
        "hi": "ऑर्डर दें अन्यथा\nआपका कार्ट खाली हो जाएगा,\n"
              "आप चयनित आइटम नहीं देख पाएँगे",
        "gu": "ઓર્ડર આપો, નહીં તો\nતમારું કાર્ટ ખાલી થઈ જશે અને\n"
              "તમે પસંદ કરેલા આઇટમ જોઈ શકશો નહીં",
        "mr": "ऑर्डर द्या, अन्यथा\nतुमचे कार्ट रिकामे होईल आणि\n"
              "तुम्ही निवडलेले आयटम पाहू शकणार नाही",
        "kn": "ಆರ್ಡರ್ ಮಾಡಿ, ಇಲ್ಲದಿದ್ದರೆ\nನಿಮ್ಮ ಕಾರ್ಟ್ ಖಾಲಿಯಾಗುತ್ತದೆ ಮತ್ತು\n"
              "ಆಯ್ಕೆ ಮಾಡಿದ ವಸ್ತುಗಳನ್ನು ನೀವು ನೋಡಲಾಗುವುದಿಲ್ಲ",
    },
    "noStoresFoundForCategory": {
        "en": "No @category stores found",
        "hi": "कोई @category स्टोर नहीं मिला",
        "gu": "કોઈ @category સ્ટોર મળ્યા નથી",
        "mr": "कोणतेही @category स्टोअर सापडले नाही",
        "kn": "ಯಾವುದೇ @category ಅಂಗಡಿಗಳು ಸಿಗಲಿಲ್ಲ",
    },
}

T = {lang: {} for lang in ("en", "hi", "gu", "mr", "kn")}
for key, values in KEYS.items():
    for lang, text in values.items():
        T[lang][key] = text
for key, values in BACKFILL.items():
    for lang, text in values.items():
        T[lang][key] = text

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
