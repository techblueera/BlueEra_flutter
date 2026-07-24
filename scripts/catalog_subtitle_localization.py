#!/usr/bin/env python3
"""Add catalog/inquiry carousel subtitle localization keys to local asset JSONs
(en/hi/gu/kn/mr) and emit per-language PUT payloads for the language API.

Run:  python3 scripts/catalog_subtitle_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "catalog_subtitle_lang_payloads")

T = {
    "en": {
        "listTheServicesYouOffer": "List the services you offer",
        "manageHospitalDepartments": "Manage hospital departments",
        "manageLabTests": "Manage lab tests",
        "manageRoomsAvailability": "Manage your rooms & availability",
        "manageVehicleListings": "Manage your vehicle listings",
        "setUpChannel": "Set up channel",
        "buildCreatorChannel": "Build your creator channel",
        "manageAcademicsCalendar": "Manage academics & calendar",
        "listItemsCustomersCanOrder": "List items customers can order",
        "newMessage": "New message",
    },
    "hi": {
        "listTheServicesYouOffer": "आप जो सेवाएँ देते हैं उन्हें सूचीबद्ध करें",
        "manageHospitalDepartments": "अस्पताल विभाग प्रबंधित करें",
        "manageLabTests": "लैब टेस्ट प्रबंधित करें",
        "manageRoomsAvailability": "अपने कमरे और उपलब्धता प्रबंधित करें",
        "manageVehicleListings": "अपनी वाहन सूची प्रबंधित करें",
        "setUpChannel": "चैनल सेट करें",
        "buildCreatorChannel": "अपना क्रिएटर चैनल बनाएं",
        "manageAcademicsCalendar": "शैक्षणिक और कैलेंडर प्रबंधित करें",
        "listItemsCustomersCanOrder": "ग्राहक जो ऑर्डर कर सकते हैं वे आइटम सूचीबद्ध करें",
        "newMessage": "नया संदेश",
    },
    "gu": {
        "listTheServicesYouOffer": "તમે આપો છો તે સેવાઓ સૂચિબદ્ધ કરો",
        "manageHospitalDepartments": "હોસ્પિટલ વિભાગોનું સંચાલન કરો",
        "manageLabTests": "લેબ ટેસ્ટનું સંચાલન કરો",
        "manageRoomsAvailability": "તમારા રૂમ અને ઉપલબ્ધતાનું સંચાલન કરો",
        "manageVehicleListings": "તમારા વાહન લિસ્ટિંગનું સંચાલન કરો",
        "setUpChannel": "ચેનલ સેટ કરો",
        "buildCreatorChannel": "તમારી ક્રિએટર ચેનલ બનાવો",
        "manageAcademicsCalendar": "શૈક્ષણિક અને કૅલેન્ડરનું સંચાલન કરો",
        "listItemsCustomersCanOrder": "ગ્રાહકો ઓર્ડર કરી શકે તેવી વસ્તુઓ સૂચિબદ્ધ કરો",
        "newMessage": "નવો સંદેશ",
    },
    "kn": {
        "listTheServicesYouOffer": "ನೀವು ನೀಡುವ ಸೇವೆಗಳನ್ನು ಪಟ್ಟಿ ಮಾಡಿ",
        "manageHospitalDepartments": "ಆಸ್ಪತ್ರೆ ವಿಭಾಗಗಳನ್ನು ನಿರ್ವಹಿಸಿ",
        "manageLabTests": "ಲ್ಯಾಬ್ ಪರೀಕ್ಷೆಗಳನ್ನು ನಿರ್ವಹಿಸಿ",
        "manageRoomsAvailability": "ನಿಮ್ಮ ಕೊಠಡಿಗಳು ಮತ್ತು ಲಭ್ಯತೆಯನ್ನು ನಿರ್ವಹಿಸಿ",
        "manageVehicleListings": "ನಿಮ್ಮ ವಾಹನ ಪಟ್ಟಿಗಳನ್ನು ನಿರ್ವಹಿಸಿ",
        "setUpChannel": "ಚಾನಲ್ ಹೊಂದಿಸಿ",
        "buildCreatorChannel": "ನಿಮ್ಮ ಕ್ರಿಯೇಟರ್ ಚಾನಲ್ ರಚಿಸಿ",
        "manageAcademicsCalendar": "ಶೈಕ್ಷಣಿಕ ಮತ್ತು ಕ್ಯಾಲೆಂಡರ್ ನಿರ್ವಹಿಸಿ",
        "listItemsCustomersCanOrder": "ಗ್ರಾಹಕರು ಆರ್ಡರ್ ಮಾಡಬಹುದಾದ ವಸ್ತುಗಳನ್ನು ಪಟ್ಟಿ ಮಾಡಿ",
        "newMessage": "ಹೊಸ ಸಂದೇಶ",
    },
    "mr": {
        "listTheServicesYouOffer": "तुम्ही देत असलेल्या सेवा सूचीबद्ध करा",
        "manageHospitalDepartments": "रुग्णालय विभाग व्यवस्थापित करा",
        "manageLabTests": "लॅब चाचण्या व्यवस्थापित करा",
        "manageRoomsAvailability": "तुमच्या खोल्या आणि उपलब्धता व्यवस्थापित करा",
        "manageVehicleListings": "तुमची वाहन सूची व्यवस्थापित करा",
        "setUpChannel": "चॅनेल सेट करा",
        "buildCreatorChannel": "तुमचे क्रिएटर चॅनेल तयार करा",
        "manageAcademicsCalendar": "शैक्षणिक आणि कॅलेंडर व्यवस्थापित करा",
        "listItemsCustomersCanOrder": "ग्राहक ऑर्डर करू शकतील अशा वस्तू सूचीबद्ध करा",
        "newMessage": "नवीन संदेश",
    },
}

BASE_URL = "https://be.beapp.in/api/language-service/languages"


def update_assets():
    for lang, kv in T.items():
        path = os.path.join(TRANS_DIR, f"{lang}.json")
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        added = sum(1 for k in kv if k not in data)
        data.update(kv)
        data = dict(sorted(data.items(), key=lambda x: x[0]))
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"{lang}.json: +{added} new keys (merged {len(kv)})")


def emit_payloads():
    os.makedirs(OUT_DIR, exist_ok=True)
    lines = []
    for lang, kv in T.items():
        body = json.dumps(kv, ensure_ascii=False, indent=2)
        with open(os.path.join(OUT_DIR, f"{lang}.json"), "w", encoding="utf-8") as f:
            f.write(body + "\n")
        lines.append(f"curl -X 'PUT' \\\n"
                     f"  '{BASE_URL}/{lang}' \\\n"
                     f"  -H 'accept: */*' \\\n"
                     f"  -H 'Content-Type: application/json' \\\n"
                     f"  -d @scripts/catalog_subtitle_lang_payloads/{lang}.json\n")
    with open(os.path.join(OUT_DIR, "curl_commands.sh"), "w", encoding="utf-8") as f:
        f.write("#!/usr/bin/env bash\nset -e\n\n" + "\n".join(lines))
    print(f"payloads + curl_commands.sh written to {OUT_DIR}")


if __name__ == "__main__":
    update_assets()
    emit_payloads()
