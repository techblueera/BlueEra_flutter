#!/usr/bin/env python3
"""Add Aadhaar OKYC sheet (aadhar_card_widget.dart) localization keys to local
asset JSONs (en/hi/gu/kn/mr) and emit per-language PUT payloads for the
language API.

Run:  python3 scripts/aadhaar_okyc_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "aadhaar_okyc_lang_payloads")

# `verifyOtp` / `didntGetOtpCode` already exist in en+hi but are missing from
# gu/mr/kn — carried here for every language so the sheet is complete in all
# five. `resendInFmt` uses GetX's `@seconds` placeholder (`.trParams`), so the
# countdown can sit wherever the language needs it.
T = {
    "en": {
        "aadhaarConsentDeclaration": "I voluntarily share my Aadhaar number and consent to its use for identity verification.",
        "sendOtp": "Send OTP",
        "aadhaarOtpFallbackNote": "If the OTP isn't coming through, verify with your Aadhaar photos instead — upload the front and back below.",
        "verifyUsingAadhaarPhoto": "Verify using Aadhaar photo",
        "uploadAadhaarPhotoHint": "Upload a clear photo of the front of your Aadhaar card. The back is optional.",
        "uploadAadhaarFront": "Upload Aadhaar Front",
        "uploadAadhaarBackOptional": "Upload Aadhaar Back (Optional)",
        "submitAadhaarImages": "Submit Aadhaar Images",
        "enterSixDigitOtp": "Enter the 6-digit OTP",
        "sentToAadhaarLinkedMobile": "Sent to your Aadhaar-linked mobile number",
        "resendInFmt": "Resend in @seconds",
        "resendOtp": "Resend OTP",
        "editAadhaarNumber": "Edit Aadhaar number",
        "aadhaarVerified": "Aadhaar Verified",
        "verifyOtp": "Verify OTP",
        "didntGetOtpCode": "Didn't get OTP code?",
        "orLabel": "OR",
    },
    "hi": {
        "aadhaarConsentDeclaration": "मैं स्वेच्छा से अपना आधार नंबर साझा करता/करती हूँ और पहचान सत्यापन के लिए इसके उपयोग की सहमति देता/देती हूँ।",
        "sendOtp": "OTP भेजें",
        "aadhaarOtpFallbackNote": "अगर OTP नहीं आ रहा है, तो अपने आधार की फ़ोटो से सत्यापित करें — नीचे आगे और पीछे की फ़ोटो अपलोड करें।",
        "verifyUsingAadhaarPhoto": "आधार फ़ोटो से सत्यापित करें",
        "uploadAadhaarPhotoHint": "अपने आधार कार्ड के आगे के हिस्से की साफ़ फ़ोटो अपलोड करें। पीछे का हिस्सा वैकल्पिक है।",
        "uploadAadhaarFront": "आधार का अगला हिस्सा अपलोड करें",
        "uploadAadhaarBackOptional": "आधार का पिछला हिस्सा अपलोड करें (वैकल्पिक)",
        "submitAadhaarImages": "आधार फ़ोटो सबमिट करें",
        "enterSixDigitOtp": "6 अंकों का OTP दर्ज करें",
        "sentToAadhaarLinkedMobile": "आपके आधार से जुड़े मोबाइल नंबर पर भेजा गया",
        "resendInFmt": "@seconds में पुनः भेजें",
        "resendOtp": "OTP पुनः भेजें",
        "editAadhaarNumber": "आधार नंबर बदलें",
        "aadhaarVerified": "आधार सत्यापित",
        "verifyOtp": "OTP सत्यापित करें",
        "didntGetOtpCode": "OTP कोड नहीं मिला?",
        "orLabel": "या",
    },
    "gu": {
        "aadhaarConsentDeclaration": "હું સ્વેચ્છાએ મારો આધાર નંબર શેર કરું છું અને ઓળખ ચકાસણી માટે તેના ઉપયોગની સંમતિ આપું છું.",
        "sendOtp": "OTP મોકલો",
        "aadhaarOtpFallbackNote": "જો OTP ન આવી રહ્યો હોય, તો તમારા આધારના ફોટાથી ચકાસો — નીચે આગળ અને પાછળનો ફોટો અપલોડ કરો.",
        "verifyUsingAadhaarPhoto": "આધાર ફોટોથી ચકાસો",
        "uploadAadhaarPhotoHint": "તમારા આધાર કાર્ડની આગળની બાજુનો સ્પષ્ટ ફોટો અપલોડ કરો. પાછળની બાજુ વૈકલ્પિક છે.",
        "uploadAadhaarFront": "આધાર ફ્રન્ટ અપલોડ કરો",
        "uploadAadhaarBackOptional": "આધાર બેક અપલોડ કરો (વૈકલ્પિક)",
        "submitAadhaarImages": "આધાર ફોટા સબમિટ કરો",
        "enterSixDigitOtp": "6 અંકનો OTP દાખલ કરો",
        "sentToAadhaarLinkedMobile": "તમારા આધાર સાથે જોડાયેલા મોબાઇલ નંબર પર મોકલાયો",
        "resendInFmt": "@seconds માં ફરી મોકલો",
        "resendOtp": "OTP ફરી મોકલો",
        "editAadhaarNumber": "આધાર નંબર બદલો",
        "aadhaarVerified": "આધાર ચકાસાયેલ",
        "verifyOtp": "OTP ચકાસો",
        "didntGetOtpCode": "OTP કોડ મળ્યો નથી?",
        "orLabel": "અથવા",
    },
    "mr": {
        "aadhaarConsentDeclaration": "मी स्वेच्छेने माझा आधार क्रमांक सामायिक करतो/करते आणि ओळख पडताळणीसाठी त्याच्या वापरास संमती देतो/देते.",
        "sendOtp": "OTP पाठवा",
        "aadhaarOtpFallbackNote": "OTP येत नसेल, तर तुमच्या आधारच्या फोटोंनी पडताळणी करा — खाली पुढील आणि मागील फोटो अपलोड करा.",
        "verifyUsingAadhaarPhoto": "आधार फोटोने पडताळणी करा",
        "uploadAadhaarPhotoHint": "तुमच्या आधार कार्डाच्या पुढील बाजूचा स्पष्ट फोटो अपलोड करा. मागील बाजू ऐच्छिक आहे.",
        "uploadAadhaarFront": "आधार पुढील बाजू अपलोड करा",
        "uploadAadhaarBackOptional": "आधार मागील बाजू अपलोड करा (ऐच्छिक)",
        "submitAadhaarImages": "आधार फोटो सबमिट करा",
        "enterSixDigitOtp": "6 अंकी OTP प्रविष्ट करा",
        "sentToAadhaarLinkedMobile": "तुमच्या आधारशी जोडलेल्या मोबाइल क्रमांकावर पाठवला",
        "resendInFmt": "@seconds मध्ये पुन्हा पाठवा",
        "resendOtp": "OTP पुन्हा पाठवा",
        "editAadhaarNumber": "आधार क्रमांक बदला",
        "aadhaarVerified": "आधार पडताळले",
        "verifyOtp": "OTP सत्यापित करा",
        "didntGetOtpCode": "OTP कोड मिळाला नाही?",
        "orLabel": "किंवा",
    },
    "kn": {
        "aadhaarConsentDeclaration": "ನಾನು ಸ್ವಇಚ್ಛೆಯಿಂದ ನನ್ನ ಆಧಾರ್ ಸಂಖ್ಯೆಯನ್ನು ಹಂಚಿಕೊಳ್ಳುತ್ತೇನೆ ಮತ್ತು ಗುರುತಿನ ಪರಿಶೀಲನೆಗಾಗಿ ಅದರ ಬಳಕೆಗೆ ಸಮ್ಮತಿ ನೀಡುತ್ತೇನೆ.",
        "sendOtp": "OTP ಕಳುಹಿಸಿ",
        "aadhaarOtpFallbackNote": "OTP ಬರುತ್ತಿಲ್ಲವಾದರೆ, ನಿಮ್ಮ ಆಧಾರ್ ಫೋಟೋಗಳ ಮೂಲಕ ಪರಿಶೀಲಿಸಿ — ಕೆಳಗೆ ಮುಂಭಾಗ ಮತ್ತು ಹಿಂಭಾಗದ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ.",
        "verifyUsingAadhaarPhoto": "ಆಧಾರ್ ಫೋಟೋ ಮೂಲಕ ಪರಿಶೀಲಿಸಿ",
        "uploadAadhaarPhotoHint": "ನಿಮ್ಮ ಆಧಾರ್ ಕಾರ್ಡ್‌ನ ಮುಂಭಾಗದ ಸ್ಪಷ್ಟ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ. ಹಿಂಭಾಗ ಐಚ್ಛಿಕ.",
        "uploadAadhaarFront": "ಆಧಾರ್ ಮುಂಭಾಗ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ",
        "uploadAadhaarBackOptional": "ಆಧಾರ್ ಹಿಂಭಾಗ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ (ಐಚ್ಛಿಕ)",
        "submitAadhaarImages": "ಆಧಾರ್ ಫೋಟೋಗಳನ್ನು ಸಲ್ಲಿಸಿ",
        "enterSixDigitOtp": "6 ಅಂಕಿಯ OTP ನಮೂದಿಸಿ",
        "sentToAadhaarLinkedMobile": "ನಿಮ್ಮ ಆಧಾರ್‌ಗೆ ಲಿಂಕ್ ಆಗಿರುವ ಮೊಬೈಲ್ ಸಂಖ್ಯೆಗೆ ಕಳುಹಿಸಲಾಗಿದೆ",
        "resendInFmt": "@seconds ನಲ್ಲಿ ಮತ್ತೆ ಕಳುಹಿಸಿ",
        "resendOtp": "OTP ಮತ್ತೆ ಕಳುಹಿಸಿ",
        "editAadhaarNumber": "ಆಧಾರ್ ಸಂಖ್ಯೆ ಬದಲಾಯಿಸಿ",
        "aadhaarVerified": "ಆಧಾರ್ ಪರಿಶೀಲಿಸಲಾಗಿದೆ",
        "verifyOtp": "OTP ಪರಿಶೀಲಿಸಿ",
        "didntGetOtpCode": "OTP ಕೋಡ್ ಬಂದಿಲ್ಲವೇ?",
        "orLabel": "ಅಥವಾ",
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
                     f"  -d @scripts/aadhaar_okyc_lang_payloads/{lang}.json\n")
    with open(os.path.join(OUT_DIR, "curl_commands.sh"), "w", encoding="utf-8") as f:
        f.write("#!/usr/bin/env bash\nset -e\n\n" + "\n".join(lines))
    print(f"payloads + curl_commands.sh written to {OUT_DIR}")


if __name__ == "__main__":
    update_assets()
    emit_payloads()
