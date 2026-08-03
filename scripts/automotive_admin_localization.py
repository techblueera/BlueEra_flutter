#!/usr/bin/env python3
"""Localization for the automotive-products ADMIN (merchant) flow.

Covers the ten UI files under `features/me/automotive_products/view/admin/`:
add-product landing, super-category rails, category browser, product selection
+ variant sheet, text/snap search, AI step 1, cart, review & publish, my
products, and top-selling. (`model/automotive_product_nested_category_response
.dart` was in scope but carries no user-facing strings — it is pure JSON
mapping, so nothing there to localize.)

The whole module was cloned from grocery/food with a blanket
"Product" -> "AutomotiveProduct" rename that also hit display strings, so the
ENGLISH source read "Add AutomotiveProducts", "5 AutomotiveItems Found",
"Your Selling AutomotivePrice", "Choose AutomotiveCategory" etc. Those are
fixed to plain English here — you cannot translate a string that is wrong in
the source language.

Interpolated strings use the repo's existing `@param` convention (see the
`grocery_view_*` keys) so each language can place the number where its own
grammar wants it. Counted nouns pass a pre-composed "@count @label" string in
rather than a bare number, because product/variant pluralize differently
across these five languages.

Reused as-is (already complete in all five languages): `all`, `retry`, `mrp`,
`sellingPrice`, `publish`, `optional`, `upload`, `more`, `cancel`, `save`,
`edit`, `noProductsFound`, `somethingWentWrong`, `productVariants`,
`useListedPrices`, `continueText`, `offCaps`, `addProduct`, `category`.

BACKFILL — three existing keys these screens already reference were missing in
some languages and were silently falling back to English:
  * addProducts  — missing gu/mr/kn (app bar title on the landing screen)
  * category     — missing mr
  * off          — missing mr

NOTE on `off`: it is NOT used for discounts here. Its Hindi value is "बंद"
(switched-off) and Kannada "ರಿಯಾಯಿತಿ", so "20% off" rendered as "20% बंद".
Every discount label in these screens now uses `offCaps` (hi "छूट"), which is
complete in all five languages and actually means a discount.

Run:  python3 scripts/automotive_admin_localization.py
Then: bash scripts/automotive_admin_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "automotive_admin_lang_payloads")

# ── New automotive-admin keys, one row per key across the five languages ──
KEYS = {
    # ---- shared counted-noun labels (composed into the @param strings) ----
    "automotiveProductLabel": {
        "en": "product", "hi": "प्रोडक्ट", "gu": "પ્રોડક્ટ",
        "mr": "प्रॉडक्ट", "kn": "ಉತ್ಪನ್ನ",
    },
    "automotiveProductsLabel": {
        "en": "products", "hi": "प्रोडक्ट", "gu": "પ્રોડક્ટ્સ",
        "mr": "प्रॉडक्ट्स", "kn": "ಉತ್ಪನ್ನಗಳು",
    },
    "automotiveVariantLabel": {
        "en": "variant", "hi": "वेरिएंट", "gu": "વેરિઅન્ટ",
        "mr": "व्हेरिएंट", "kn": "ರೂಪಾಂತರ",
    },
    "automotiveVariantsLabel": {
        "en": "variants", "hi": "वेरिएंट", "gu": "વેરિઅન્ટ્સ",
        "mr": "व्हेरिएंट्स", "kn": "ರೂಪಾಂತರಗಳು",
    },
    # ---- variant picker sheet ----
    "automotiveDefaultLabel": {
        "en": "Default", "hi": "डिफ़ॉल्ट", "gu": "ડિફૉલ્ટ",
        "mr": "डीफॉल्ट", "kn": "ಡೀಫಾಲ್ಟ್",
    },
    "automotiveCountInCart": {
        "en": "@count in cart", "hi": "@count कार्ट में",
        "gu": "@count કાર્ટમાં", "mr": "@count कार्टमध्ये",
        "kn": "ಕಾರ್ಟ್‌ನಲ್ಲಿ @count",
    },
    # ---- text / snap search screen ----
    "automotiveTextSearch": {
        "en": "Text Search", "hi": "टेक्स्ट सर्च", "gu": "ટેક્સ્ટ સર્ચ",
        "mr": "टेक्स्ट सर्च", "kn": "ಪಠ್ಯ ಹುಡುಕಾಟ",
    },
    "automotiveSnapSearch": {
        "en": "Snap Search", "hi": "स्नैप सर्च", "gu": "સ્નૅપ સર્ચ",
        "mr": "स्नॅप सर्च", "kn": "ಸ್ನ್ಯಾಪ್ ಹುಡುಕಾಟ",
    },
    "automotiveQuickAdd": {
        "en": "Quick Add", "hi": "क्विक ऐड", "gu": "ઝડપી ઉમેરો",
        "mr": "झटपट जोडा", "kn": "ತ್ವರಿತ ಸೇರಿಸಿ",
    },
    "automotiveUploadBulkProducts": {
        "en": "Upload Bulk Products",
        "hi": "बल्क प्रोडक्ट अपलोड करें",
        "gu": "બલ્ક પ્રોડક્ટ્સ અપલોડ કરો",
        "mr": "बल्क प्रॉडक्ट्स अपलोड करा",
        "kn": "ಬೃಹತ್ ಉತ್ಪನ್ನಗಳನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ",
    },
    "automotiveUploadPhotoHelper": {
        "en": "Upload a photo of products or menu to add them instantly",
        "hi": "प्रोडक्ट या मेन्यू की फ़ोटो अपलोड करें और उन्हें तुरंत जोड़ें",
        "gu": "પ્રોડક્ટ્સ કે મેનૂનો ફોટો અપલોડ કરી તેમને તરત ઉમેરો",
        "mr": "प्रॉडक्ट्स किंवा मेनूचा फोटो अपलोड करा आणि ते लगेच जोडा",
        "kn": "ಉತ್ಪನ್ನಗಳು ಅಥವಾ ಮೆನುವಿನ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ಮತ್ತು ಅವುಗಳನ್ನು ತಕ್ಷಣ ಸೇರಿಸಿ",
    },
    "automotiveUploadLimitNote": {
        "en": "Upload picture/menu containing up to 20 products at a time",
        "hi": "एक बार में 20 तक प्रोडक्ट वाली तस्वीर/मेन्यू अपलोड करें",
        "gu": "એક સમયે 20 સુધીના પ્રોડક્ટ ધરાવતું ચિત્ર/મેનૂ અપલોડ કરો",
        "mr": "एका वेळी 20 पर्यंत प्रॉडक्ट असलेले चित्र/मेनू अपलोड करा",
        "kn": "ಒಂದು ಬಾರಿಗೆ 20 ಉತ್ಪನ್ನಗಳವರೆಗೆ ಇರುವ ಚಿತ್ರ/ಮೆನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ",
    },
    "automotiveSnapNoProductsIdentified": {
        "en": "We couldn't identify any products from this photo. \n"
              "Try capturing a clearer shot or searching for individual items!",
        "hi": "हम इस फ़ोटो से कोई प्रोडक्ट नहीं पहचान सके। \n"
              "साफ़ तस्वीर लें या आइटम अलग-अलग खोजें!",
        "gu": "અમે આ ફોટોમાંથી કોઈ પ્રોડક્ટ ઓળખી શક્યા નહીં. \n"
              "સ્પષ્ટ ફોટો લો અથવા આઇટમ અલગ-અલગ શોધો!",
        "mr": "आम्ही या फोटोमधून कोणतेही प्रॉडक्ट ओळखू शकलो नाही. \n"
              "स्पष्ट फोटो घ्या किंवा आयटम वेगवेगळे शोधा!",
        "kn": "ಈ ಫೋಟೋದಿಂದ ನಾವು ಯಾವುದೇ ಉತ್ಪನ್ನಗಳನ್ನು ಗುರುತಿಸಲಾಗಲಿಲ್ಲ. \n"
              "ಸ್ಪಷ್ಟವಾದ ಚಿತ್ರ ತೆಗೆಯಿರಿ ಅಥವಾ ಪ್ರತ್ಯೇಕ ವಸ್ತುಗಳನ್ನು ಹುಡುಕಿ!",
    },
    "automotiveItemsFoundFmt": {
        "en": "@count Items Found", "hi": "@count आइटम मिले",
        "gu": "@count આઇટમ મળ્યાં", "mr": "@count आयटम सापडले",
        "kn": "@count ವಸ್ತುಗಳು ಸಿಕ್ಕಿವೆ",
    },
    "automotiveItemsMissingFmt": {
        "en": "@count Items missing", "hi": "@count आइटम मौजूद नहीं",
        "gu": "@count આઇટમ ખૂટે છે", "mr": "@count आयटम गहाळ",
        "kn": "@count ವಸ್ತುಗಳು ಕಾಣೆಯಾಗಿವೆ",
    },
    "automotiveKeepTyping": {
        "en": "Keep typing…", "hi": "टाइप करते रहें…", "gu": "ટાઇપ કરતા રહો…",
        "mr": "टाइप करत राहा…", "kn": "ಟೈಪ್ ಮಾಡುತ್ತಿರಿ…",
    },
    "automotiveOneMoreCharacter": {
        "en": "Just 1 more character to start searching",
        "hi": "खोज शुरू करने के लिए बस 1 अक्षर और",
        "gu": "શોધ શરૂ કરવા માટે ફક્ત 1 અક્ષર વધુ",
        "mr": "शोध सुरू करण्यासाठी फक्त 1 अक्षर आणखी",
        "kn": "ಹುಡುಕಾಟ ಪ್ರಾರಂಭಿಸಲು ಇನ್ನೂ 1 ಅಕ್ಷರ ಸಾಕು",
    },
    "automotiveMoreCharactersFmt": {
        "en": "Type @count more characters to start searching",
        "hi": "खोज शुरू करने के लिए @count अक्षर और टाइप करें",
        "gu": "શોધ શરૂ કરવા માટે @count અક્ષરો વધુ ટાઇપ કરો",
        "mr": "शोध सुरू करण्यासाठी आणखी @count अक्षरे टाइप करा",
        "kn": "ಹುಡುಕಾಟ ಪ್ರಾರಂಭಿಸಲು ಇನ್ನೂ @count ಅಕ್ಷರಗಳನ್ನು ಟೈಪ್ ಮಾಡಿ",
    },
    "automotiveNoMatchingProducts": {
        "en": "We couldn't find any matching products.\n"
              "Try different keywords or check the spelling.",
        "hi": "हमें कोई मिलता-जुलता प्रोडक्ट नहीं मिला।\n"
              "दूसरे कीवर्ड आज़माएँ या स्पेलिंग जाँचें।",
        "gu": "અમને કોઈ મેળ ખાતું પ્રોડક્ટ મળ્યું નહીં.\n"
              "બીજા કીવર્ડ અજમાવો અથવા સ્પેલિંગ તપાસો.",
        "mr": "आम्हाला जुळणारे कोणतेही प्रॉडक्ट सापडले नाही.\n"
              "दुसरे कीवर्ड वापरून पहा किंवा स्पेलिंग तपासा.",
        "kn": "ಹೊಂದಾಣಿಕೆಯಾಗುವ ಯಾವುದೇ ಉತ್ಪನ್ನ ಸಿಗಲಿಲ್ಲ.\n"
              "ಬೇರೆ ಕೀವರ್ಡ್‌ಗಳನ್ನು ಪ್ರಯತ್ನಿಸಿ ಅಥವಾ ಕಾಗುಣಿತ ಪರಿಶೀಲಿಸಿ.",
    },
    "automotiveNoProductsForKeywordFmt": {
        "en": "We couldn't find any products for \"@keyword\".\n"
              "Try different keywords or check the spelling.",
        "hi": "\"@keyword\" के लिए कोई प्रोडक्ट नहीं मिला।\n"
              "दूसरे कीवर्ड आज़माएँ या स्पेलिंग जाँचें।",
        "gu": "\"@keyword\" માટે કોઈ પ્રોડક્ટ મળ્યું નહીં.\n"
              "બીજા કીવર્ડ અજમાવો અથવા સ્પેલિંગ તપાસો.",
        "mr": "\"@keyword\" साठी कोणतेही प्रॉडक्ट सापडले नाही.\n"
              "दुसरे कीवर्ड वापरून पहा किंवा स्पेलिंग तपासा.",
        "kn": "\"@keyword\" ಗಾಗಿ ಯಾವುದೇ ಉತ್ಪನ್ನ ಸಿಗಲಿಲ್ಲ.\n"
              "ಬೇರೆ ಕೀವರ್ಡ್‌ಗಳನ್ನು ಪ್ರಯತ್ನಿಸಿ ಅಥವಾ ಕಾಗುಣಿತ ಪರಿಶೀಲಿಸಿ.",
    },
    "automotiveClearSearch": {
        "en": "Clear search", "hi": "खोज हटाएँ", "gu": "શોધ સાફ કરો",
        "mr": "शोध साफ करा", "kn": "ಹುಡುಕಾಟ ತೆರವುಗೊಳಿಸಿ",
    },
    "automotiveCouldntLoadResults": {
        "en": "Couldn't load results", "hi": "नतीजे लोड नहीं हो सके",
        "gu": "પરિણામો લોડ થઈ શક્યાં નહીં",
        "mr": "निकाल लोड होऊ शकले नाहीत",
        "kn": "ಫಲಿತಾಂಶಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗಲಿಲ್ಲ",
    },
    "automotiveServerTimeout": {
        "en": "The server is taking too long to respond. "
              "Please check your connection and try again.",
        "hi": "सर्वर जवाब देने में बहुत समय ले रहा है। "
              "कृपया अपना कनेक्शन जाँचें और फिर कोशिश करें।",
        "gu": "સર્વર જવાબ આપવામાં ઘણો સમય લઈ રહ્યું છે. "
              "કૃપા કરીને તમારું કનેક્શન તપાસો અને ફરી પ્રયાસ કરો.",
        "mr": "सर्व्हर प्रतिसाद देण्यास खूप वेळ घेत आहे. "
              "कृपया तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.",
        "kn": "ಸರ್ವರ್ ಪ್ರತಿಕ್ರಿಯಿಸಲು ಬಹಳ ಸಮಯ ತೆಗೆದುಕೊಳ್ಳುತ್ತಿದೆ. "
              "ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
    },
    # ---- review & publish / cart ----
    "automotiveReviewAndPublish": {
        "en": "Review & Publish", "hi": "समीक्षा करें और प्रकाशित करें",
        "gu": "સમીક્ષા કરો અને પ્રકાશિત કરો",
        "mr": "पुनरावलोकन करा आणि प्रकाशित करा",
        "kn": "ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಪ್ರಕಟಿಸಿ",
    },
    "automotiveConfirmYourPrices": {
        "en": "Confirm your prices", "hi": "अपनी कीमतें पक्की करें",
        "gu": "તમારી કિંમતોની ખાતરી કરો", "mr": "तुमच्या किमती निश्चित करा",
        "kn": "ನಿಮ್ಮ ಬೆಲೆಗಳನ್ನು ಖಚಿತಪಡಿಸಿ",
    },
    "automotiveReadyToPublishFmt": {
        "en": "@products • @variants ready to publish",
        "hi": "@products • @variants प्रकाशित करने के लिए तैयार",
        "gu": "@products • @variants પ્રકાશિત કરવા માટે તૈયાર",
        "mr": "@products • @variants प्रकाशित करण्यासाठी तयार",
        "kn": "@products • @variants ಪ್ರಕಟಿಸಲು ಸಿದ್ಧ",
    },
    "automotiveNoVariantsInCart": {
        "en": "No variants in cart", "hi": "कार्ट में कोई वेरिएंट नहीं",
        "gu": "કાર્ટમાં કોઈ વેરિઅન્ટ નથી",
        "mr": "कार्टमध्ये कोणतेही व्हेरिएंट नाहीत",
        "kn": "ಕಾರ್ಟ್‌ನಲ್ಲಿ ಯಾವುದೇ ರೂಪಾಂತರಗಳಿಲ್ಲ",
    },
    "automotiveNoVariantsInCartHint": {
        "en": "Pick products and variants from your inventory to publish "
              "them to your store.",
        "hi": "अपने स्टोर पर प्रकाशित करने के लिए इन्वेंट्री से प्रोडक्ट और "
              "वेरिएंट चुनें।",
        "gu": "તમારા સ્ટોર પર પ્રકાશિત કરવા માટે ઇન્વેન્ટરીમાંથી પ્રોડક્ટ અને "
              "વેરિઅન્ટ પસંદ કરો.",
        "mr": "तुमच्या स्टोअरवर प्रकाशित करण्यासाठी इन्व्हेंटरीमधून प्रॉडक्ट "
              "आणि व्हेरिएंट निवडा.",
        "kn": "ನಿಮ್ಮ ಅಂಗಡಿಯಲ್ಲಿ ಪ್ರಕಟಿಸಲು ದಾಸ್ತಾನಿನಿಂದ ಉತ್ಪನ್ನಗಳು ಮತ್ತು "
              "ರೂಪಾಂತರಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ.",
    },
    "automotiveTotalPayable": {
        "en": "Total payable", "hi": "कुल देय", "gu": "કુલ ચૂકવવાપાત્ર",
        "mr": "एकूण देय", "kn": "ಒಟ್ಟು ಪಾವತಿಸಬೇಕಾದದ್ದು",
    },
    "automotiveSavesFmt": {
        "en": "Saves @amount", "hi": "@amount की बचत", "gu": "@amount ની બચત",
        "mr": "@amount ची बचत", "kn": "@amount ಉಳಿತಾಯ",
    },
    "automotivePublishCountFmt": {
        "en": "Publish @variants", "hi": "@variants प्रकाशित करें",
        "gu": "@variants પ્રકાશિત કરો", "mr": "@variants प्रकाशित करा",
        "kn": "@variants ಪ್ರಕಟಿಸಿ",
    },
    "automotivePublishProductsFmt": {
        "en": "Publish @products", "hi": "@products प्रकाशित करें",
        "gu": "@products પ્રકાશિત કરો", "mr": "@products प्रकाशित करा",
        "kn": "@products ಪ್ರಕಟಿಸಿ",
    },
    "automotiveDefaultVariant": {
        "en": "Default variant", "hi": "डिफ़ॉल्ट वेरिएंट",
        "gu": "ડિફૉલ્ટ વેરિઅન્ટ", "mr": "डीफॉल्ट व्हेरिएंट",
        "kn": "ಡೀಫಾಲ್ಟ್ ರೂಪಾಂತರ",
    },
    "automotiveEnterValidMrp": {
        "en": "Enter a valid MRP", "hi": "मान्य MRP दर्ज करें",
        "gu": "માન્ય MRP દાખલ કરો", "mr": "वैध MRP टाका",
        "kn": "ಮಾನ್ಯ MRP ನಮೂದಿಸಿ",
    },
    "automotiveEnterValidSellingPrice": {
        "en": "Enter a valid selling price",
        "hi": "मान्य विक्रय मूल्य दर्ज करें",
        "gu": "માન્ય વેચાણ કિંમત દાખલ કરો", "mr": "वैध विक्री किंमत टाका",
        "kn": "ಮಾನ್ಯ ಮಾರಾಟ ಬೆಲೆ ನಮೂದಿಸಿ",
    },
    "automotiveSellingCannotExceedMrpFmt": {
        "en": "Selling price can’t exceed MRP (@mrp)",
        "hi": "विक्रय मूल्य MRP (@mrp) से ज़्यादा नहीं हो सकता",
        "gu": "વેચાણ કિંમત MRP (@mrp) કરતાં વધુ ન હોઈ શકે",
        "mr": "विक्री किंमत MRP (@mrp) पेक्षा जास्त असू शकत नाही",
        "kn": "ಮಾರಾಟ ಬೆಲೆ MRP (@mrp) ಮೀರುವಂತಿಲ್ಲ",
    },
    "automotiveSellingCannotExceedMrp": {
        "en": "Selling price can’t exceed MRP",
        "hi": "विक्रय मूल्य MRP से ज़्यादा नहीं हो सकता",
        "gu": "વેચાણ કિંમત MRP કરતાં વધુ ન હોઈ શકે",
        "mr": "विक्री किंमत MRP पेक्षा जास्त असू शकत नाही",
        "kn": "ಮಾರಾಟ ಬೆಲೆ MRP ಮೀರುವಂತಿಲ್ಲ",
    },
    "automotiveEditPrice": {
        "en": "EDIT PRICE", "hi": "कीमत बदलें", "gu": "કિંમત બદલો",
        "mr": "किंमत बदला", "kn": "ಬೆಲೆ ಬದಲಿಸಿ",
    },
    "automotiveVariantPrice": {
        "en": "Variant price", "hi": "वेरिएंट की कीमत",
        "gu": "વેરિઅન્ટની કિંમત", "mr": "व्हेरिएंटची किंमत",
        "kn": "ರೂಪಾಂತರದ ಬೆಲೆ",
    },
    "automotiveYouSaveFmt": {
        "en": "You save @amount", "hi": "आपकी बचत @amount",
        "gu": "તમારી બચત @amount", "mr": "तुमची बचत @amount",
        "kn": "ನೀವು @amount ಉಳಿಸುತ್ತೀರಿ",
    },
    "automotiveAddValidMrp": {
        "en": "Add a valid MRP", "hi": "मान्य MRP जोड़ें",
        "gu": "માન્ય MRP ઉમેરો", "mr": "वैध MRP जोडा",
        "kn": "ಮಾನ್ಯ MRP ಸೇರಿಸಿ",
    },
    "automotiveAddValidSellingPrice": {
        "en": "Add a valid selling price", "hi": "मान्य विक्रय मूल्य जोड़ें",
        "gu": "માન્ય વેચાણ કિંમત ઉમેરો", "mr": "वैध विक्री किंमत जोडा",
        "kn": "ಮಾನ್ಯ ಮಾರಾಟ ಬೆಲೆ ಸೇರಿಸಿ",
    },
    "automotiveCheckPricesFmt": {
        "en": "Check MRP & selling price — @error.",
        "hi": "MRP और विक्रय मूल्य जाँचें — @error।",
        "gu": "MRP અને વેચાણ કિંમત તપાસો — @error.",
        "mr": "MRP आणि विक्री किंमत तपासा — @error.",
        "kn": "MRP ಮತ್ತು ಮಾರಾಟ ಬೆಲೆ ಪರಿಶೀಲಿಸಿ — @error.",
    },
    "automotiveNoProductsSelected": {
        "en": "No products selected", "hi": "कोई प्रोडक्ट नहीं चुना गया",
        "gu": "કોઈ પ્રોડક્ટ પસંદ કર્યું નથી",
        "mr": "कोणतेही प्रॉडक्ट निवडलेले नाही",
        "kn": "ಯಾವುದೇ ಉತ್ಪನ್ನ ಆಯ್ಕೆಯಾಗಿಲ್ಲ",
    },
    "automotiveSetSellingPriceHint": {
        "en": "Set selling price for each variant",
        "hi": "हर वेरिएंट के लिए विक्रय मूल्य तय करें",
        "gu": "દરેક વેરિઅન્ટ માટે વેચાણ કિંમત નક્કી કરો",
        "mr": "प्रत्येक व्हेरिएंटसाठी विक्री किंमत ठरवा",
        "kn": "ಪ್ರತಿ ರೂಪಾಂತರಕ್ಕೂ ಮಾರಾಟ ಬೆಲೆ ನಿಗದಿಪಡಿಸಿ",
    },
    "automotiveYourSellingPrice": {
        "en": "Your Selling Price", "hi": "आपका विक्रय मूल्य",
        "gu": "તમારી વેચાણ કિંમત", "mr": "तुमची विक्री किंमत",
        "kn": "ನಿಮ್ಮ ಮಾರಾಟ ಬೆಲೆ",
    },
    "automotiveVariantsSelectedFmt": {
        "en": "@variants selected", "hi": "@variants चुने गए",
        "gu": "@variants પસંદ કર્યાં", "mr": "@variants निवडले",
        "kn": "@variants ಆಯ್ಕೆಯಾಗಿವೆ",
    },
    "automotiveReadyToPublish": {
        "en": "Ready to publish", "hi": "प्रकाशित करने के लिए तैयार",
        "gu": "પ્રકાશિત કરવા તૈયાર", "mr": "प्रकाशित करण्यासाठी तयार",
        "kn": "ಪ್ರಕಟಿಸಲು ಸಿದ್ಧ",
    },
    "automotiveFixPricesBeforePublish": {
        "en": "Fix selling prices that exceed MRP before publishing.",
        "hi": "प्रकाशित करने से पहले MRP से ज़्यादा वाले विक्रय मूल्य ठीक करें।",
        "gu": "પ્રકાશિત કરતાં પહેલાં MRP કરતાં વધુ હોય તેવી વેચાણ કિંમતો સુધારો.",
        "mr": "प्रकाशित करण्यापूर्वी MRP पेक्षा जास्त असलेल्या विक्री किमती "
              "दुरुस्त करा.",
        "kn": "ಪ್ರಕಟಿಸುವ ಮೊದಲು MRP ಮೀರಿದ ಮಾರಾಟ ಬೆಲೆಗಳನ್ನು ಸರಿಪಡಿಸಿ.",
    },
    # ---- AI step 1 ----
    "automotiveAiHeaderSubtitle": {
        "en": "Enter a few details and let AI build your listing",
        "hi": "कुछ जानकारी भरें और AI को अपनी लिस्टिंग बनाने दें",
        "gu": "થોડી વિગતો ભરો અને AI ને તમારું લિસ્ટિંગ બનાવવા દો",
        "mr": "थोडी माहिती भरा आणि AI ला तुमचे लिस्टिंग तयार करू द्या",
        "kn": "ಕೆಲವು ವಿವರಗಳನ್ನು ನಮೂದಿಸಿ ಮತ್ತು AI ನಿಮ್ಮ ಪಟ್ಟಿಯನ್ನು ರಚಿಸಲಿ",
    },
    "automotiveAddProductPhoto": {
        "en": "Add product photo", "hi": "प्रोडक्ट फ़ोटो जोड़ें",
        "gu": "પ્રોડક્ટ ફોટો ઉમેરો", "mr": "प्रॉडक्ट फोटो जोडा",
        "kn": "ಉತ್ಪನ್ನದ ಫೋಟೋ ಸೇರಿಸಿ",
    },
    "automotiveSearchGoogle": {
        "en": "Search Google", "hi": "Google पर खोजें", "gu": "Google પર શોધો",
        "mr": "Google वर शोधा", "kn": "Google ನಲ್ಲಿ ಹುಡುಕಿ",
    },
    "automotiveAddAnotherPhoto": {
        "en": "Add another photo", "hi": "एक और फ़ोटो जोड़ें",
        "gu": "બીજો ફોટો ઉમેરો", "mr": "आणखी एक फोटो जोडा",
        "kn": "ಇನ್ನೊಂದು ಫೋಟೋ ಸೇರಿಸಿ",
    },
    "automotiveSearchFromGoogle": {
        "en": "Search from Google", "hi": "Google से खोजें",
        "gu": "Google માંથી શોધો", "mr": "Google मधून शोधा",
        "kn": "Google ನಿಂದ ಹುಡುಕಿ",
    },
    "automotiveSearchFromGoogleHint": {
        "en": "Find a photo by product name / brand",
        "hi": "प्रोडक्ट नाम / ब्रांड से फ़ोटो ढूँढें",
        "gu": "પ્રોડક્ટ નામ / બ્રાન્ડ દ્વારા ફોટો શોધો",
        "mr": "प्रॉडक्ट नाव / ब्रँडने फोटो शोधा",
        "kn": "ಉತ್ಪನ್ನದ ಹೆಸರು / ಬ್ರ್ಯಾಂಡ್ ಮೂಲಕ ಫೋಟೋ ಹುಡುಕಿ",
    },
    "automotiveCameraOrGallery": {
        "en": "Camera or Gallery", "hi": "कैमरा या गैलरी",
        "gu": "કૅમેરા કે ગૅલેરી", "mr": "कॅमेरा किंवा गॅलरी",
        "kn": "ಕ್ಯಾಮೆರಾ ಅಥವಾ ಗ್ಯಾಲರಿ",
    },
    "automotiveCameraOrGalleryHint": {
        "en": "Capture or pick from your device",
        "hi": "अपने डिवाइस से खींचें या चुनें",
        "gu": "તમારા ડિવાઇસમાંથી ખેંચો કે પસંદ કરો",
        "mr": "तुमच्या डिव्हाइसवरून घ्या किंवा निवडा",
        "kn": "ನಿಮ್ಮ ಸಾಧನದಿಂದ ಸೆರೆಹಿಡಿಯಿರಿ ಅಥವಾ ಆಯ್ಕೆಮಾಡಿ",
    },
    "automotiveTapImageToUse": {
        "en": "Tap an image to use it",
        "hi": "इस्तेमाल करने के लिए किसी तस्वीर पर टैप करें",
        "gu": "વાપરવા માટે કોઈ ચિત્ર પર ટૅપ કરો",
        "mr": "वापरण्यासाठी एखाद्या चित्रावर टॅप करा",
        "kn": "ಬಳಸಲು ಚಿತ್ರವನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ",
    },
    "automotiveChooseCategory": {
        "en": "Choose Category", "hi": "श्रेणी चुनें", "gu": "શ્રેણી પસંદ કરો",
        "mr": "श्रेणी निवडा", "kn": "ವರ್ಗ ಆಯ್ಕೆಮಾಡಿ",
    },
    "automotiveSelectCategory": {
        "en": "Select Category", "hi": "श्रेणी चुनें", "gu": "શ્રેણી પસંદ કરો",
        "mr": "श्रेणी निवडा", "kn": "ವರ್ಗ ಆಯ್ಕೆಮಾಡಿ",
    },
    # ---- my products / top selling / category browser ----
    "automotiveTopSellingProducts": {
        "en": "Top Selling Products",
        "hi": "सबसे ज़्यादा बिकने वाले प्रोडक्ट",
        "gu": "સૌથી વધુ વેચાતા પ્રોડક્ટ્સ",
        "mr": "सर्वाधिक विकले जाणारे प्रॉडक्ट्स",
        "kn": "ಅತಿ ಹೆಚ್ಚು ಮಾರಾಟವಾಗುವ ಉತ್ಪನ್ನಗಳು",
    },
    "automotiveNoTopSellingYet": {
        "en": "No top selling products yet.",
        "hi": "अभी कोई टॉप सेलिंग प्रोडक्ट नहीं है।",
        "gu": "હજી કોઈ ટોપ સેલિંગ પ્રોડક્ટ નથી.",
        "mr": "अजून कोणतेही टॉप सेलिंग प्रॉडक्ट नाही.",
        "kn": "ಇನ್ನೂ ಯಾವುದೇ ಹೆಚ್ಚು ಮಾರಾಟವಾಗುವ ಉತ್ಪನ್ನಗಳಿಲ್ಲ.",
    },
    "automotiveSearchProductsHint": {
        "en": "Search products...", "hi": "प्रोडक्ट खोजें...",
        "gu": "પ્રોડક્ટ શોધો...", "mr": "प्रॉडक्ट शोधा...",
        "kn": "ಉತ್ಪನ್ನಗಳನ್ನು ಹುಡುಕಿ...",
    },
    "automotiveProducts": {
        "en": "Products", "hi": "प्रोडक्ट", "gu": "પ્રોડક્ટ્સ",
        "mr": "प्रॉडक्ट्स", "kn": "ಉತ್ಪನ್ನಗಳು",
    },
    "automotiveNoCategoriesFound": {
        "en": "No categories found", "hi": "कोई श्रेणी नहीं मिली",
        "gu": "કોઈ શ્રેણી મળી નથી", "mr": "कोणतीही श्रेणी सापडली नाही",
        "kn": "ಯಾವುದೇ ವರ್ಗಗಳು ಸಿಗಲಿಲ್ಲ",
    },
    "automotiveCategoryCountFmt": {
        "en": "@count Categories", "hi": "@count श्रेणियाँ",
        "gu": "@count શ્રેણીઓ", "mr": "@count श्रेणी",
        "kn": "@count ವರ್ಗಗಳು",
    },
    "automotiveMaxLimitWarningFmt": {
        "en": "You can't select more than @count products at a time.",
        "hi": "आप एक बार में @count से ज़्यादा प्रोडक्ट नहीं चुन सकते।",
        "gu": "તમે એક સમયે @count થી વધુ પ્રોડક્ટ પસંદ કરી શકતા નથી.",
        "mr": "तुम्ही एका वेळी @count पेक्षा जास्त प्रॉडक्ट निवडू शकत नाही.",
        "kn": "ಒಂದು ಬಾರಿಗೆ @count ಕ್ಕಿಂತ ಹೆಚ್ಚು ಉತ್ಪನ್ನಗಳನ್ನು ಆಯ್ಕೆಮಾಡಲಾಗದು.",
    },
    # ---- add-product landing ----
    "automotiveQuickUpload": {
        "en": "Quick Upload", "hi": "क्विक अपलोड", "gu": "ઝડપી અપલોડ",
        "mr": "झटपट अपलोड", "kn": "ತ್ವರಿತ ಅಪ್‌ಲೋಡ್",
    },
    "automotiveSearchByPhoto": {
        "en": "Search products by photo", "hi": "फ़ोटो से प्रोडक्ट खोजें",
        "gu": "ફોટોથી પ્રોડક્ટ શોધો", "mr": "फोटोने प्रॉडक्ट शोधा",
        "kn": "ಫೋಟೋ ಮೂಲಕ ಉತ್ಪನ್ನ ಹುಡುಕಿ",
    },
    "automotiveSearchByPhotoHint": {
        "en": "Upload a picture to find products instantly.",
        "hi": "प्रोडक्ट तुरंत ढूँढने के लिए तस्वीर अपलोड करें।",
        "gu": "પ્રોડક્ટ તરત શોધવા માટે ચિત્ર અપલોડ કરો.",
        "mr": "प्रॉडक्ट लगेच शोधण्यासाठी चित्र अपलोड करा.",
        "kn": "ಉತ್ಪನ್ನಗಳನ್ನು ತಕ್ಷಣ ಹುಡುಕಲು ಚಿತ್ರ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ.",
    },
}

# ── Backfill: keys these screens already use that were missing languages ──
BACKFILL = {
    "addProducts": {
        "gu": "પ્રોડક્ટ્સ ઉમેરો", "mr": "प्रॉडक्ट्स जोडा",
        "kn": "ಉತ್ಪನ್ನಗಳನ್ನು ಸೇರಿಸಿ",
    },
    "category": {"mr": "श्रेणी"},
    "off": {"mr": "बंद"},
}

# Flip the by-key table into the per-language payloads the API takes.
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
