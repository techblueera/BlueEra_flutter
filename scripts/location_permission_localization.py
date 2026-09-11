#!/usr/bin/env python3
"""Add the location-access guidance sheet (lib/widgets/location_help_sheet.dart)
localization keys to the local asset JSONs (en/hi/gu/kn/mr) and emit per-language
PUT payloads for the language API.

Run:  python3 scripts/location_permission_localization.py

The sheet replaces a single snackbar ("Please enable your location permission
and GPS to access app features.") that covered four different failures with
four different fixes in two different settings screens. Each failure now has
its own title and its own numbered steps, which is why there are four sets of
them here rather than one.

The words in `Permissions` / `Location` steps are left in English on purpose:
they name what is written on the Android settings screen the user is being sent
to, and that screen is in English on most devices in these markets. Translating
the label would send people looking for a row that isn't there.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "location_permission_lang_payloads")

T = {
    "en": {
        "locationAllowTitle": "Allow location access",
        "locationBlockedTitle": "Location is blocked for BlueEra",
        "locationGpsOffTitle": "Your device location is off",
        "locationNotFoundTitle": "Couldn't get your location",
        "locationWhyGeneric": "BlueEra needs your location to continue. It's read once, right now — never in the background.",
        "locationWhyAccountSetup": "Your city and pincode are saved with your profile so people and businesses near you can find you. Your location is read once, right now — never in the background.",
        "locationWhyBusinessSetup": "Your shop's address and pincode are saved with the listing so nearby customers can find you. Your location is read once, right now — never in the background.",
        "locationWhyPickupPoint": "The pickup point is set from where you are right now, so the customer and the shop both see the right spot. Your location is read once, right now — never in the background.",
        "locationWhyAvailability": "The area you work in is saved with your booking profile so clients nearby can find you. Your location is read once, right now — never in the background.",
        "locationStepsHeading": "What to do",
        "locationAllowStep1": "Tap Allow location below",
        "locationAllowStep2": "Choose \"While using the app\" when your phone asks",
        "locationAllowStep3": "Your address fills in on its own — there is nothing to type",
        "locationBlockedStep1": "Tap Open Settings below",
        "locationBlockedStep2": "Open Permissions, then Location",
        "locationBlockedStep3": "Choose \"Allow only while using the app\"",
        "locationBlockedStep4": "Come back here and tap Try again",
        "locationGpsStep1": "Tap Turn on GPS below",
        "locationGpsStep2": "Switch Location on in your device settings",
        "locationGpsStep3": "Come back here and tap Try again",
        "locationRetryStep1": "Step outside or near a window so the GPS can get a signal",
        "locationRetryStep2": "Check that mobile data or Wi-Fi is on",
        "locationRetryStep3": "Tap Try again",
        "locationAllowAction": "Allow location",
        "locationTurnOnGps": "Turn on GPS",
        "locationTryAgain": "Try again"
    },
    "hi": {
        "locationAllowTitle": "लोकेशन की अनुमति दें",
        "locationBlockedTitle": "BlueEra के लिए लोकेशन ब्लॉक है",
        "locationGpsOffTitle": "आपके फ़ोन की लोकेशन बंद है",
        "locationNotFoundTitle": "आपकी लोकेशन नहीं मिल पाई",
        "locationWhyGeneric": "आगे बढ़ने के लिए BlueEra को आपकी लोकेशन चाहिए। यह सिर्फ़ अभी एक बार पढ़ी जाती है — बैकग्राउंड में कभी नहीं।",
        "locationWhyAccountSetup": "आपका शहर और पिनकोड आपकी प्रोफ़ाइल के साथ सेव होते हैं ताकि आस-पास के लोग और व्यवसाय आपको ढूँढ सकें। लोकेशन सिर्फ़ अभी एक बार पढ़ी जाती है — बैकग्राउंड में कभी नहीं।",
        "locationWhyBusinessSetup": "आपकी दुकान का पता और पिनकोड लिस्टिंग के साथ सेव होते हैं ताकि आस-पास के ग्राहक आपको ढूँढ सकें। लोकेशन सिर्फ़ अभी एक बार पढ़ी जाती है — बैकग्राउंड में कभी नहीं।",
        "locationWhyPickupPoint": "पिकअप पॉइंट आपकी अभी की जगह से सेट होता है, ताकि ग्राहक और दुकान दोनों सही जगह देखें। लोकेशन सिर्फ़ अभी एक बार पढ़ी जाती है — बैकग्राउंड में कभी नहीं।",
        "locationWhyAvailability": "आप जिस इलाके में काम करते हैं वह आपकी बुकिंग प्रोफ़ाइल के साथ सेव होता है ताकि आस-पास के ग्राहक आपको ढूँढ सकें। लोकेशन सिर्फ़ अभी एक बार पढ़ी जाती है — बैकग्राउंड में कभी नहीं।",
        "locationStepsHeading": "क्या करना है",
        "locationAllowStep1": "नीचे \"लोकेशन की अनुमति दें\" पर टैप करें",
        "locationAllowStep2": "फ़ोन पूछे तो \"ऐप इस्तेमाल करते समय\" चुनें",
        "locationAllowStep3": "आपका पता अपने आप भर जाएगा — कुछ टाइप नहीं करना है",
        "locationBlockedStep1": "नीचे \"सेटिंग खोलें\" पर टैप करें",
        "locationBlockedStep2": "Permissions खोलें, फिर Location",
        "locationBlockedStep3": "\"ऐप इस्तेमाल करते समय ही अनुमति दें\" चुनें",
        "locationBlockedStep4": "वापस यहाँ आकर \"फिर कोशिश करें\" पर टैप करें",
        "locationGpsStep1": "नीचे \"GPS चालू करें\" पर टैप करें",
        "locationGpsStep2": "फ़ोन की सेटिंग में Location चालू करें",
        "locationGpsStep3": "वापस यहाँ आकर \"फिर कोशिश करें\" पर टैप करें",
        "locationRetryStep1": "बाहर या खिड़की के पास जाएँ ताकि GPS को सिग्नल मिल सके",
        "locationRetryStep2": "देख लें कि मोबाइल डेटा या Wi-Fi चालू है",
        "locationRetryStep3": "\"फिर कोशिश करें\" पर टैप करें",
        "locationAllowAction": "लोकेशन की अनुमति दें",
        "locationTurnOnGps": "GPS चालू करें",
        "locationTryAgain": "फिर कोशिश करें"
    },
    "gu": {
        "locationAllowTitle": "લોકેશનની પરવાનગી આપો",
        "locationBlockedTitle": "BlueEra માટે લોકેશન બ્લોક છે",
        "locationGpsOffTitle": "તમારા ફોનનું લોકેશન બંધ છે",
        "locationNotFoundTitle": "તમારું લોકેશન મળી શક્યું નહીં",
        "locationWhyGeneric": "આગળ વધવા માટે BlueEra ને તમારું લોકેશન જોઈએ. તે ફક્ત અત્યારે એક વાર વંચાય છે — બેકગ્રાઉન્ડમાં ક્યારેય નહીં.",
        "locationWhyAccountSetup": "તમારું શહેર અને પિનકોડ તમારી પ્રોફાઇલ સાથે સેવ થાય છે જેથી નજીકના લોકો અને વ્યવસાયો તમને શોધી શકે. લોકેશન ફક્ત અત્યારે એક વાર વંચાય છે — બેકગ્રાઉન્ડમાં ક્યારેય નહીં.",
        "locationWhyBusinessSetup": "તમારી દુકાનનું સરનામું અને પિનકોડ લિસ્ટિંગ સાથે સેવ થાય છે જેથી નજીકના ગ્રાહકો તમને શોધી શકે. લોકેશન ફક્ત અત્યારે એક વાર વંચાય છે — બેકગ્રાઉન્ડમાં ક્યારેય નહીં.",
        "locationWhyPickupPoint": "પિકઅપ પોઇન્ટ તમે અત્યારે જ્યાં છો ત્યાંથી સેટ થાય છે, જેથી ગ્રાહક અને દુકાન બંને સાચી જગ્યા જુએ. લોકેશન ફક્ત અત્યારે એક વાર વંચાય છે — બેકગ્રાઉન્ડમાં ક્યારેય નહીં.",
        "locationWhyAvailability": "તમે જે વિસ્તારમાં કામ કરો છો તે તમારી બુકિંગ પ્રોફાઇલ સાથે સેવ થાય છે જેથી નજીકના ગ્રાહકો તમને શોધી શકે. લોકેશન ફક્ત અત્યારે એક વાર વંચાય છે — બેકગ્રાઉન્ડમાં ક્યારેય નહીં.",
        "locationStepsHeading": "શું કરવું",
        "locationAllowStep1": "નીચે \"લોકેશનની પરવાનગી આપો\" પર ટૅપ કરો",
        "locationAllowStep2": "ફોન પૂછે ત્યારે \"એપ વાપરતી વખતે\" પસંદ કરો",
        "locationAllowStep3": "તમારું સરનામું આપોઆપ ભરાઈ જશે — કંઈ ટાઇપ કરવાનું નથી",
        "locationBlockedStep1": "નીચે \"સેટિંગ ખોલો\" પર ટૅપ કરો",
        "locationBlockedStep2": "Permissions ખોલો, પછી Location",
        "locationBlockedStep3": "\"એપ વાપરતી વખતે જ પરવાનગી આપો\" પસંદ કરો",
        "locationBlockedStep4": "અહીં પાછા આવીને \"ફરી પ્રયાસ કરો\" પર ટૅપ કરો",
        "locationGpsStep1": "નીચે \"GPS ચાલુ કરો\" પર ટૅપ કરો",
        "locationGpsStep2": "ફોનની સેટિંગમાં Location ચાલુ કરો",
        "locationGpsStep3": "અહીં પાછા આવીને \"ફરી પ્રયાસ કરો\" પર ટૅપ કરો",
        "locationRetryStep1": "બહાર અથવા બારી પાસે જાઓ જેથી GPS ને સિગ્નલ મળે",
        "locationRetryStep2": "ચકાસો કે મોબાઇલ ડેટા અથવા Wi-Fi ચાલુ છે",
        "locationRetryStep3": "\"ફરી પ્રયાસ કરો\" પર ટૅપ કરો",
        "locationAllowAction": "લોકેશનની પરવાનગી આપો",
        "locationTurnOnGps": "GPS ચાલુ કરો",
        "locationTryAgain": "ફરી પ્રયાસ કરો"
    },
    "kn": {
        "locationAllowTitle": "ಸ್ಥಳದ ಅನುಮತಿ ನೀಡಿ",
        "locationBlockedTitle": "BlueEra ಗೆ ಸ್ಥಳ ನಿರ್ಬಂಧಿಸಲಾಗಿದೆ",
        "locationGpsOffTitle": "ನಿಮ್ಮ ಫೋನ್‌ನ ಸ್ಥಳ ಆಫ್ ಆಗಿದೆ",
        "locationNotFoundTitle": "ನಿಮ್ಮ ಸ್ಥಳ ಸಿಗಲಿಲ್ಲ",
        "locationWhyGeneric": "ಮುಂದುವರಿಯಲು BlueEra ಗೆ ನಿಮ್ಮ ಸ್ಥಳ ಬೇಕು. ಅದನ್ನು ಈಗ ಒಮ್ಮೆ ಮಾತ್ರ ಓದಲಾಗುತ್ತದೆ — ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಎಂದಿಗೂ ಇಲ್ಲ.",
        "locationWhyAccountSetup": "ನಿಮ್ಮ ಊರು ಮತ್ತು ಪಿನ್‌ಕೋಡ್ ನಿಮ್ಮ ಪ್ರೊಫೈಲ್‌ನೊಂದಿಗೆ ಉಳಿಸಲಾಗುತ್ತದೆ, ಇದರಿಂದ ಹತ್ತಿರದ ಜನರು ಮತ್ತು ವ್ಯವಹಾರಗಳು ನಿಮ್ಮನ್ನು ಹುಡುಕಬಹುದು. ಸ್ಥಳವನ್ನು ಈಗ ಒಮ್ಮೆ ಮಾತ್ರ ಓದಲಾಗುತ್ತದೆ — ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಎಂದಿಗೂ ಇಲ್ಲ.",
        "locationWhyBusinessSetup": "ನಿಮ್ಮ ಅಂಗಡಿಯ ವಿಳಾಸ ಮತ್ತು ಪಿನ್‌ಕೋಡ್ ಪಟ್ಟಿಯೊಂದಿಗೆ ಉಳಿಸಲಾಗುತ್ತದೆ, ಇದರಿಂದ ಹತ್ತಿರದ ಗ್ರಾಹಕರು ನಿಮ್ಮನ್ನು ಹುಡುಕಬಹುದು. ಸ್ಥಳವನ್ನು ಈಗ ಒಮ್ಮೆ ಮಾತ್ರ ಓದಲಾಗುತ್ತದೆ — ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಎಂದಿಗೂ ಇಲ್ಲ.",
        "locationWhyPickupPoint": "ನೀವು ಈಗ ಇರುವ ಸ್ಥಳದಿಂದ ಪಿಕಪ್ ಪಾಯಿಂಟ್ ಹೊಂದಿಸಲಾಗುತ್ತದೆ, ಇದರಿಂದ ಗ್ರಾಹಕ ಮತ್ತು ಅಂಗಡಿ ಎರಡೂ ಸರಿಯಾದ ಜಾಗವನ್ನು ನೋಡುತ್ತವೆ. ಸ್ಥಳವನ್ನು ಈಗ ಒಮ್ಮೆ ಮಾತ್ರ ಓದಲಾಗುತ್ತದೆ — ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಎಂದಿಗೂ ಇಲ್ಲ.",
        "locationWhyAvailability": "ನೀವು ಕೆಲಸ ಮಾಡುವ ಪ್ರದೇಶವನ್ನು ನಿಮ್ಮ ಬುಕಿಂಗ್ ಪ್ರೊಫೈಲ್‌ನೊಂದಿಗೆ ಉಳಿಸಲಾಗುತ್ತದೆ, ಇದರಿಂದ ಹತ್ತಿರದ ಗ್ರಾಹಕರು ನಿಮ್ಮನ್ನು ಹುಡುಕಬಹುದು. ಸ್ಥಳವನ್ನು ಈಗ ಒಮ್ಮೆ ಮಾತ್ರ ಓದಲಾಗುತ್ತದೆ — ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಎಂದಿಗೂ ಇಲ್ಲ.",
        "locationStepsHeading": "ಏನು ಮಾಡಬೇಕು",
        "locationAllowStep1": "ಕೆಳಗಿನ \"ಸ್ಥಳದ ಅನುಮತಿ ನೀಡಿ\" ಒತ್ತಿ",
        "locationAllowStep2": "ಫೋನ್ ಕೇಳಿದಾಗ \"ಆ್ಯಪ್ ಬಳಸುವಾಗ\" ಆಯ್ಕೆಮಾಡಿ",
        "locationAllowStep3": "ನಿಮ್ಮ ವಿಳಾಸ ತಾನಾಗಿಯೇ ತುಂಬುತ್ತದೆ — ಟೈಪ್ ಮಾಡುವ ಅಗತ್ಯವಿಲ್ಲ",
        "locationBlockedStep1": "ಕೆಳಗಿನ \"ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ\" ಒತ್ತಿ",
        "locationBlockedStep2": "Permissions ತೆರೆಯಿರಿ, ನಂತರ Location",
        "locationBlockedStep3": "\"ಆ್ಯಪ್ ಬಳಸುವಾಗ ಮಾತ್ರ ಅನುಮತಿಸಿ\" ಆಯ್ಕೆಮಾಡಿ",
        "locationBlockedStep4": "ಇಲ್ಲಿಗೆ ಹಿಂತಿರುಗಿ \"ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ\" ಒತ್ತಿ",
        "locationGpsStep1": "ಕೆಳಗಿನ \"GPS ಆನ್ ಮಾಡಿ\" ಒತ್ತಿ",
        "locationGpsStep2": "ಫೋನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ Location ಆನ್ ಮಾಡಿ",
        "locationGpsStep3": "ಇಲ್ಲಿಗೆ ಹಿಂತಿರುಗಿ \"ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ\" ಒತ್ತಿ",
        "locationRetryStep1": "GPS ಗೆ ಸಿಗ್ನಲ್ ಸಿಗಲು ಹೊರಗೆ ಅಥವಾ ಕಿಟಕಿಯ ಬಳಿ ಹೋಗಿ",
        "locationRetryStep2": "ಮೊಬೈಲ್ ಡೇಟಾ ಅಥವಾ Wi-Fi ಆನ್ ಇದೆಯೇ ಪರಿಶೀಲಿಸಿ",
        "locationRetryStep3": "\"ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ\" ಒತ್ತಿ",
        "locationAllowAction": "ಸ್ಥಳದ ಅನುಮತಿ ನೀಡಿ",
        "locationTurnOnGps": "GPS ಆನ್ ಮಾಡಿ",
        "locationTryAgain": "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ"
    },
    "mr": {
        "locationAllowTitle": "स्थानाची परवानगी द्या",
        "locationBlockedTitle": "BlueEra साठी स्थान ब्लॉक आहे",
        "locationGpsOffTitle": "तुमच्या फोनचे स्थान बंद आहे",
        "locationNotFoundTitle": "तुमचे स्थान मिळाले नाही",
        "locationWhyGeneric": "पुढे जाण्यासाठी BlueEra ला तुमचे स्थान हवे आहे. ते फक्त आत्ता एकदाच वाचले जाते — बॅकग्राउंडमध्ये कधीही नाही.",
        "locationWhyAccountSetup": "तुमचे शहर आणि पिनकोड तुमच्या प्रोफाइलसोबत सेव्ह होतात जेणेकरून जवळचे लोक आणि व्यवसाय तुम्हाला शोधू शकतील. स्थान फक्त आत्ता एकदाच वाचले जाते — बॅकग्राउंडमध्ये कधीही नाही.",
        "locationWhyBusinessSetup": "तुमच्या दुकानाचा पत्ता आणि पिनकोड लिस्टिंगसोबत सेव्ह होतात जेणेकरून जवळचे ग्राहक तुम्हाला शोधू शकतील. स्थान फक्त आत्ता एकदाच वाचले जाते — बॅकग्राउंडमध्ये कधीही नाही.",
        "locationWhyPickupPoint": "पिकअप पॉइंट तुम्ही आत्ता जिथे आहात तिथून सेट होतो, जेणेकरून ग्राहक आणि दुकान दोघांनाही योग्य जागा दिसेल. स्थान फक्त आत्ता एकदाच वाचले जाते — बॅकग्राउंडमध्ये कधीही नाही.",
        "locationWhyAvailability": "तुम्ही ज्या भागात काम करता तो तुमच्या बुकिंग प्रोफाइलसोबत सेव्ह होतो जेणेकरून जवळचे ग्राहक तुम्हाला शोधू शकतील. स्थान फक्त आत्ता एकदाच वाचले जाते — बॅकग्राउंडमध्ये कधीही नाही.",
        "locationStepsHeading": "काय करायचे",
        "locationAllowStep1": "खाली \"स्थानाची परवानगी द्या\" वर टॅप करा",
        "locationAllowStep2": "फोन विचारेल तेव्हा \"अ‍ॅप वापरत असताना\" निवडा",
        "locationAllowStep3": "तुमचा पत्ता आपोआप भरला जाईल — काही टाइप करायचे नाही",
        "locationBlockedStep1": "खाली \"सेटिंग्ज उघडा\" वर टॅप करा",
        "locationBlockedStep2": "Permissions उघडा, नंतर Location",
        "locationBlockedStep3": "\"अ‍ॅप वापरत असतानाच परवानगी द्या\" निवडा",
        "locationBlockedStep4": "इथे परत येऊन \"पुन्हा प्रयत्न करा\" वर टॅप करा",
        "locationGpsStep1": "खाली \"GPS चालू करा\" वर टॅप करा",
        "locationGpsStep2": "फोनच्या सेटिंग्जमध्ये Location चालू करा",
        "locationGpsStep3": "इथे परत येऊन \"पुन्हा प्रयत्न करा\" वर टॅप करा",
        "locationRetryStep1": "GPS ला सिग्नल मिळावा म्हणून बाहेर किंवा खिडकीजवळ जा",
        "locationRetryStep2": "मोबाइल डेटा किंवा Wi-Fi चालू आहे का तपासा",
        "locationRetryStep3": "\"पुन्हा प्रयत्न करा\" वर टॅप करा",
        "locationAllowAction": "स्थानाची परवानगी द्या",
        "locationTurnOnGps": "GPS चालू करा",
        "locationTryAgain": "पुन्हा प्रयत्न करा"
    }
}

BASE_URL = "https://be.beapp.in/api/language-service/languages"


def update_assets():
    """Add any missing key to each asset file, in place.

    Deliberately NOT a load / update / re-dump: the asset files are not sorted
    by any one rule (different generations of these scripts, plus hand edits),
    so re-serialising one rewrites thousands of lines that have nothing to do
    with this change. Inserting the missing lines among the existing
    `location*` run keeps the diff to what was actually added, and makes a
    second run a no-op.
    """
    for lang, kv in T.items():
        path = os.path.join(TRANS_DIR, "%s.json" % lang)
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().split("\n")

        run = [i for i, line in enumerate(lines)
               if _key_of(line) and _key_of(line).lower().startswith("location")]
        if not run:
            raise SystemExit("%s: no existing location* keys to anchor on" % lang)
        first, last = run[0], run[-1]
        if last - first + 1 != len(run):
            raise SystemExit("%s: location* keys are not contiguous" % lang)
        if not lines[last].rstrip().endswith(","):
            raise SystemExit("%s: location* run reaches the end of the object" % lang)

        entries = {_key_of(lines[i]): lines[i] for i in run}
        indent = lines[first][:len(lines[first]) - len(lines[first].lstrip())]
        added = 0
        for key, value in kv.items():
            if key in entries:
                continue
            entries[key] = "%s%s: %s," % (
                indent,
                json.dumps(key, ensure_ascii=False),
                json.dumps(value, ensure_ascii=False),
            )
            added += 1

        merged = [entries[k] for k in sorted(entries, key=lambda k: (k.lower(), k))]
        lines[first:last + 1] = merged
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(lines))
        print("%s.json: +%d new keys (merged %d)" % (lang, added, len(kv)))


def _key_of(line):
    stripped = line.lstrip()
    if not stripped.startswith('"'):
        return None
    end = stripped.find('"', 1)
    if end < 0 or not stripped[end + 1:].lstrip().startswith(":"):
        return None
    return stripped[1:end]


def emit_payloads():
    os.makedirs(OUT_DIR, exist_ok=True)
    commands = []
    for lang, kv in T.items():
        with open(os.path.join(OUT_DIR, "%s.json" % lang), "w", encoding="utf-8") as fh:
            fh.write(json.dumps(kv, ensure_ascii=False, indent=2) + "\n")
        commands.append(
            "curl -X 'PUT' \\\n"
            "  '%s/%s' \\\n"
            "  -H 'accept: */*' \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d @scripts/location_permission_lang_payloads/%s.json\n" % (BASE_URL, lang, lang)
        )
    with open(os.path.join(OUT_DIR, "curl_commands.sh"), "w", encoding="utf-8") as fh:
        fh.write("#!/usr/bin/env bash\nset -e\n\n" + "\n".join(commands))
    print("payloads + curl_commands.sh written to %s" % OUT_DIR)


if __name__ == "__main__":
    update_assets()
    emit_payloads()
