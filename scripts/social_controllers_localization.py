#!/usr/bin/env python3
"""Localization for the Social module controllers
(lib/features/me/social/controller/*.dart) — snackbar results and form
validation copy.

Three groups of keys:
  * NEW      — result/validation messages that had no key at all.
  * BACKFILL — `genericSavedSuccess` / `genericImageUploadFailed`, which had
               only shipped in en+hi; existing values reused verbatim.
  * FALLBACK — "Something went wrong try after sometimes" is the literal VALUE
               of `AppStrings.somethingWentWrong`, so `.tr` looks that sentence
               up as a key and finds nothing. Registering it makes every
               `AppStrings.somethingWentWrong.tr` call site in the app resolve;
               the many call sites that omit `.tr` are unaffected.

Run:  python3 scripts/social_controllers_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "social_controllers_lang_payloads")

FALLBACK_KEY = "Something went wrong try after sometimes"

T = {
    "en": {
        # --- new ---
        "locationRequired": "Location is required",
        "profileSavedSuccessfully": "Profile saved successfully",
        "failedToSaveProfile": "Failed to save profile",
        "errorFetchingEvents": "Error fetching events",
        "errorFetchingData": "Error fetching data",
        "errorPickingImage": "Error picking image",
        "errorSaving": "Error saving",
        "errorDeleting": "Error deleting",
        "errorDeletingEvent": "Error deleting event",
        "eventScheduledSuccess": "Event scheduled successfully",
        "eventUpdatedSuccess": "Event updated successfully",
        "eventDeletedSuccess": "Event deleted successfully",
        "failedToScheduleEvent": "Failed to schedule event",
        "failedToUpdateEvent": "Failed to update event",
        "failedToDeleteEvent": "Failed to delete event",
        "activityCreatedSuccess": "Activity created successfully",
        "activityUpdatedSuccess": "Activity updated successfully",
        "activityDeletedSuccess": "Activity deleted successfully",
        "failedToSaveActivity": "Failed to save activity",
        "failedToDeleteActivity": "Failed to delete activity",
        "failedToSave": "Failed to save",
        "pleaseSelectImage": "Please select an image",
        "selectValidLocationFromSearch":
            "Please select a valid location from the search.",
        "enterCertificateTitle":
            "Please enter a title for the certificate.",
        "selectValidIssuedDate": "Please select a valid issued date.",
        "fullNameRequired": "Full name is required",
        "nameLengthRule":
            "Name must be 3-50 characters (letters, numbers, spaces)",
        "websiteUrlRequired": "Website URL is required",
        "enterValidWebsiteUrl":
            "Please enter a valid website URL (e.g. https://example.com)",
        "enterValidGmail":
            "Please enter a valid Gmail address (e.g. name@gmail.com)",
        "phoneNumberRequired": "Phone number is required",
        "enterValidMobileNumber":
            "Please enter a valid 10-digit mobile number (starts with 6-9)",
        "pleaseEnterValidDetails": "Please Enter Valid Details",
        # --- backfill (existing en values) ---
        "genericSavedSuccess": "Saved successfully",
        "genericImageUploadFailed": "Image upload failed",
        # --- fallback key (mirrors the `somethingWentWrong` copy) ---
        FALLBACK_KEY: "Something went wrong. Please try again.",
    },
    "hi": {
        "locationRequired": "स्थान आवश्यक है",
        "profileSavedSuccessfully": "प्रोफ़ाइल सफलतापूर्वक सहेजी गई",
        "failedToSaveProfile": "प्रोफ़ाइल सहेजने में विफल",
        "errorFetchingEvents": "कार्यक्रम लाने में त्रुटि",
        "errorFetchingData": "डेटा लाने में त्रुटि",
        "errorPickingImage": "छवि चुनने में त्रुटि",
        "errorSaving": "सहेजने में त्रुटि",
        "errorDeleting": "हटाने में त्रुटि",
        "errorDeletingEvent": "कार्यक्रम हटाने में त्रुटि",
        "eventScheduledSuccess": "कार्यक्रम सफलतापूर्वक निर्धारित किया गया",
        "eventUpdatedSuccess": "कार्यक्रम सफलतापूर्वक अपडेट किया गया",
        "eventDeletedSuccess": "कार्यक्रम सफलतापूर्वक हटाया गया",
        "failedToScheduleEvent": "कार्यक्रम निर्धारित करने में विफल",
        "failedToUpdateEvent": "कार्यक्रम अपडेट करने में विफल",
        "failedToDeleteEvent": "कार्यक्रम हटाने में विफल",
        "activityCreatedSuccess": "गतिविधि सफलतापूर्वक बनाई गई",
        "activityUpdatedSuccess": "गतिविधि सफलतापूर्वक अपडेट की गई",
        "activityDeletedSuccess": "गतिविधि सफलतापूर्वक हटाई गई",
        "failedToSaveActivity": "गतिविधि सहेजने में विफल",
        "failedToDeleteActivity": "गतिविधि हटाने में विफल",
        "failedToSave": "सहेजने में विफल",
        "pleaseSelectImage": "कृपया एक छवि चुनें",
        "selectValidLocationFromSearch":
            "कृपया सर्च से एक मान्य स्थान चुनें।",
        "enterCertificateTitle":
            "कृपया प्रमाणपत्र के लिए एक शीर्षक दर्ज करें।",
        "selectValidIssuedDate": "कृपया एक मान्य जारी तिथि चुनें।",
        "fullNameRequired": "पूरा नाम आवश्यक है",
        "nameLengthRule":
            "नाम 3-50 अक्षरों का होना चाहिए (अक्षर, अंक, स्पेस)",
        "websiteUrlRequired": "वेबसाइट URL आवश्यक है",
        "enterValidWebsiteUrl":
            "कृपया एक मान्य वेबसाइट URL दर्ज करें (उदा. https://example.com)",
        "enterValidGmail":
            "कृपया एक मान्य Gmail पता दर्ज करें (उदा. name@gmail.com)",
        "phoneNumberRequired": "फ़ोन नंबर आवश्यक है",
        "enterValidMobileNumber":
            "कृपया एक मान्य 10-अंकों का मोबाइल नंबर दर्ज करें (6-9 से शुरू)",
        "pleaseEnterValidDetails": "कृपया मान्य विवरण दर्ज करें",
        "genericSavedSuccess": "सफलतापूर्वक सेव हो गया",
        "genericImageUploadFailed": "इमेज अपलोड विफल",
        FALLBACK_KEY: "कुछ गलत हो गया। कृपया पुनः प्रयास करें।",
    },
    "gu": {
        "locationRequired": "સ્થળ જરૂરી છે",
        "profileSavedSuccessfully": "પ્રોફાઇલ સફળતાપૂર્વક સાચવવામાં આવી",
        "failedToSaveProfile": "પ્રોફાઇલ સાચવવામાં નિષ્ફળ",
        "errorFetchingEvents": "કાર્યક્રમો લાવવામાં ભૂલ",
        "errorFetchingData": "ડેટા લાવવામાં ભૂલ",
        "errorPickingImage": "છબી પસંદ કરવામાં ભૂલ",
        "errorSaving": "સાચવવામાં ભૂલ",
        "errorDeleting": "કાઢી નાખવામાં ભૂલ",
        "errorDeletingEvent": "કાર્યક્રમ કાઢી નાખવામાં ભૂલ",
        "eventScheduledSuccess": "કાર્યક્રમ સફળતાપૂર્વક નિર્ધારિત થયો",
        "eventUpdatedSuccess": "કાર્યક્રમ સફળતાપૂર્વક અપડેટ થયો",
        "eventDeletedSuccess": "કાર્યક્રમ સફળતાપૂર્વક કાઢી નાખવામાં આવ્યો",
        "failedToScheduleEvent": "કાર્યક્રમ નિર્ધારિત કરવામાં નિષ્ફળ",
        "failedToUpdateEvent": "કાર્યક્રમ અપડેટ કરવામાં નિષ્ફળ",
        "failedToDeleteEvent": "કાર્યક્રમ કાઢી નાખવામાં નિષ્ફળ",
        "activityCreatedSuccess": "પ્રવૃત્તિ સફળતાપૂર્વક બનાવવામાં આવી",
        "activityUpdatedSuccess": "પ્રવૃત્તિ સફળતાપૂર્વક અપડેટ થઈ",
        "activityDeletedSuccess": "પ્રવૃત્તિ સફળતાપૂર્વક કાઢી નાખવામાં આવી",
        "failedToSaveActivity": "પ્રવૃત્તિ સાચવવામાં નિષ્ફળ",
        "failedToDeleteActivity": "પ્રવૃત્તિ કાઢી નાખવામાં નિષ્ફળ",
        "failedToSave": "સાચવવામાં નિષ્ફળ",
        "pleaseSelectImage": "કૃપા કરીને એક છબી પસંદ કરો",
        "selectValidLocationFromSearch":
            "કૃપા કરીને શોધમાંથી માન્ય સ્થળ પસંદ કરો.",
        "enterCertificateTitle":
            "કૃપા કરીને પ્રમાણપત્ર માટે શીર્ષક દાખલ કરો.",
        "selectValidIssuedDate":
            "કૃપા કરીને માન્ય જારી તારીખ પસંદ કરો.",
        "fullNameRequired": "પૂરું નામ જરૂરી છે",
        "nameLengthRule":
            "નામ 3-50 અક્ષરોનું હોવું જોઈએ (અક્ષરો, અંકો, જગ્યા)",
        "websiteUrlRequired": "વેબસાઇટ URL જરૂરી છે",
        "enterValidWebsiteUrl":
            "કૃપા કરીને માન્ય વેબસાઇટ URL દાખલ કરો (દા.ત. https://example.com)",
        "enterValidGmail":
            "કૃપા કરીને માન્ય Gmail સરનામું દાખલ કરો (દા.ત. name@gmail.com)",
        "phoneNumberRequired": "ફોન નંબર જરૂરી છે",
        "enterValidMobileNumber":
            "કૃપા કરીને માન્ય 10-અંકનો મોબાઇલ નંબર દાખલ કરો (6-9 થી શરૂ)",
        "pleaseEnterValidDetails": "કૃપા કરીને માન્ય વિગતો દાખલ કરો",
        "genericSavedSuccess": "સફળતાપૂર્વક સાચવવામાં આવ્યું",
        "genericImageUploadFailed": "છબી અપલોડ નિષ્ફળ",
        FALLBACK_KEY: "કંઈક ખોટું થયું. કૃપા કરીને ફરી પ્રયાસ કરો.",
    },
    "mr": {
        "locationRequired": "स्थान आवश्यक आहे",
        "profileSavedSuccessfully": "प्रोफाइल यशस्वीरित्या जतन केली",
        "failedToSaveProfile": "प्रोफाइल जतन करण्यात अयशस्वी",
        "errorFetchingEvents": "कार्यक्रम आणण्यात त्रुटी",
        "errorFetchingData": "डेटा आणण्यात त्रुटी",
        "errorPickingImage": "प्रतिमा निवडण्यात त्रुटी",
        "errorSaving": "जतन करण्यात त्रुटी",
        "errorDeleting": "हटवण्यात त्रुटी",
        "errorDeletingEvent": "कार्यक्रम हटवण्यात त्रुटी",
        "eventScheduledSuccess": "कार्यक्रम यशस्वीरित्या नियोजित केला",
        "eventUpdatedSuccess": "कार्यक्रम यशस्वीरित्या अपडेट केला",
        "eventDeletedSuccess": "कार्यक्रम यशस्वीरित्या हटवला",
        "failedToScheduleEvent": "कार्यक्रम नियोजित करण्यात अयशस्वी",
        "failedToUpdateEvent": "कार्यक्रम अपडेट करण्यात अयशस्वी",
        "failedToDeleteEvent": "कार्यक्रम हटवण्यात अयशस्वी",
        "activityCreatedSuccess": "क्रियाकलाप यशस्वीरित्या तयार केला",
        "activityUpdatedSuccess": "क्रियाकलाप यशस्वीरित्या अपडेट केला",
        "activityDeletedSuccess": "क्रियाकलाप यशस्वीरित्या हटवला",
        "failedToSaveActivity": "क्रियाकलाप जतन करण्यात अयशस्वी",
        "failedToDeleteActivity": "क्रियाकलाप हटवण्यात अयशस्वी",
        "failedToSave": "जतन करण्यात अयशस्वी",
        "pleaseSelectImage": "कृपया एक प्रतिमा निवडा",
        "selectValidLocationFromSearch":
            "कृपया शोधातून वैध स्थान निवडा.",
        "enterCertificateTitle":
            "कृपया प्रमाणपत्रासाठी शीर्षक प्रविष्ट करा.",
        "selectValidIssuedDate": "कृपया वैध जारी तारीख निवडा.",
        "fullNameRequired": "पूर्ण नाव आवश्यक आहे",
        "nameLengthRule":
            "नाव 3-50 अक्षरांचे असावे (अक्षरे, अंक, जागा)",
        "websiteUrlRequired": "वेबसाइट URL आवश्यक आहे",
        "enterValidWebsiteUrl":
            "कृपया वैध वेबसाइट URL प्रविष्ट करा (उदा. https://example.com)",
        "enterValidGmail":
            "कृपया वैध Gmail पत्ता प्रविष्ट करा (उदा. name@gmail.com)",
        "phoneNumberRequired": "फोन नंबर आवश्यक आहे",
        "enterValidMobileNumber":
            "कृपया वैध 10-अंकी मोबाइल नंबर प्रविष्ट करा (6-9 ने सुरू)",
        "pleaseEnterValidDetails": "कृपया वैध तपशील प्रविष्ट करा",
        "genericSavedSuccess": "यशस्वीरित्या जतन केले",
        "genericImageUploadFailed": "प्रतिमा अपलोड अयशस्वी",
        FALLBACK_KEY: "काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.",
    },
    "kn": {
        "locationRequired": "ಸ್ಥಳ ಅಗತ್ಯವಿದೆ",
        "profileSavedSuccessfully": "ಪ್ರೊಫೈಲ್ ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ",
        "failedToSaveProfile": "ಪ್ರೊಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ",
        "errorFetchingEvents": "ಕಾರ್ಯಕ್ರಮಗಳನ್ನು ಪಡೆಯುವಲ್ಲಿ ದೋಷ",
        "errorFetchingData": "ಡೇಟಾ ಪಡೆಯುವಲ್ಲಿ ದೋಷ",
        "errorPickingImage": "ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡುವಲ್ಲಿ ದೋಷ",
        "errorSaving": "ಉಳಿಸುವಲ್ಲಿ ದೋಷ",
        "errorDeleting": "ಅಳಿಸುವಲ್ಲಿ ದೋಷ",
        "errorDeletingEvent": "ಕಾರ್ಯಕ್ರಮ ಅಳಿಸುವಲ್ಲಿ ದೋಷ",
        "eventScheduledSuccess": "ಕಾರ್ಯಕ್ರಮ ಯಶಸ್ವಿಯಾಗಿ ನಿಗದಿಪಡಿಸಲಾಗಿದೆ",
        "eventUpdatedSuccess": "ಕಾರ್ಯಕ್ರಮ ಯಶಸ್ವಿಯಾಗಿ ಅಪ್‌ಡೇಟ್ ಆಗಿದೆ",
        "eventDeletedSuccess": "ಕಾರ್ಯಕ್ರಮ ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ",
        "failedToScheduleEvent": "ಕಾರ್ಯಕ್ರಮ ನಿಗದಿಪಡಿಸಲು ವಿಫಲವಾಗಿದೆ",
        "failedToUpdateEvent": "ಕಾರ್ಯಕ್ರಮ ಅಪ್‌ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ",
        "failedToDeleteEvent": "ಕಾರ್ಯಕ್ರಮ ಅಳಿಸಲು ವಿಫಲವಾಗಿದೆ",
        "activityCreatedSuccess": "ಚಟುವಟಿಕೆ ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ",
        "activityUpdatedSuccess": "ಚಟುವಟಿಕೆ ಯಶಸ್ವಿಯಾಗಿ ಅಪ್‌ಡೇಟ್ ಆಗಿದೆ",
        "activityDeletedSuccess": "ಚಟುವಟಿಕೆ ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ",
        "failedToSaveActivity": "ಚಟುವಟಿಕೆ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ",
        "failedToDeleteActivity": "ಚಟುವಟಿಕೆ ಅಳಿಸಲು ವಿಫಲವಾಗಿದೆ",
        "failedToSave": "ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ",
        "pleaseSelectImage": "ದಯವಿಟ್ಟು ಒಂದು ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ",
        "selectValidLocationFromSearch":
            "ದಯವಿಟ್ಟು ಹುಡುಕಾಟದಿಂದ ಮಾನ್ಯ ಸ್ಥಳವನ್ನು ಆಯ್ಕೆಮಾಡಿ.",
        "enterCertificateTitle":
            "ದಯವಿಟ್ಟು ಪ್ರಮಾಣಪತ್ರಕ್ಕೆ ಶೀರ್ಷಿಕೆಯನ್ನು ನಮೂದಿಸಿ.",
        "selectValidIssuedDate":
            "ದಯವಿಟ್ಟು ಮಾನ್ಯ ವಿತರಣಾ ದಿನಾಂಕವನ್ನು ಆಯ್ಕೆಮಾಡಿ.",
        "fullNameRequired": "ಪೂರ್ಣ ಹೆಸರು ಅಗತ್ಯವಿದೆ",
        "nameLengthRule":
            "ಹೆಸರು 3-50 ಅಕ್ಷರಗಳಾಗಿರಬೇಕು (ಅಕ್ಷರಗಳು, ಅಂಕಿಗಳು, ಸ್ಥಳ)",
        "websiteUrlRequired": "ವೆಬ್‌ಸೈಟ್ URL ಅಗತ್ಯವಿದೆ",
        "enterValidWebsiteUrl":
            "ದಯವಿಟ್ಟು ಮಾನ್ಯ ವೆಬ್‌ಸೈಟ್ URL ನಮೂದಿಸಿ (ಉದಾ. https://example.com)",
        "enterValidGmail":
            "ದಯವಿಟ್ಟು ಮಾನ್ಯ Gmail ವಿಳಾಸ ನಮೂದಿಸಿ (ಉದಾ. name@gmail.com)",
        "phoneNumberRequired": "ಫೋನ್ ಸಂಖ್ಯೆ ಅಗತ್ಯವಿದೆ",
        "enterValidMobileNumber":
            "ದಯವಿಟ್ಟು ಮಾನ್ಯ 10-ಅಂಕಿಯ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ (6-9 ರಿಂದ ಪ್ರಾರಂಭ)",
        "pleaseEnterValidDetails": "ದಯವಿಟ್ಟು ಮಾನ್ಯ ವಿವರಗಳನ್ನು ನಮೂದಿಸಿ",
        "genericSavedSuccess": "ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ",
        "genericImageUploadFailed": "ಚಿತ್ರ ಅಪ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ",
        FALLBACK_KEY: "ಏದೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
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
