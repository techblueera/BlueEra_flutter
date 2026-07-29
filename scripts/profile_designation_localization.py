#!/usr/bin/env python3
"""Localization for the "Profile Data" designation bottom sheet
(lib/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart)
and the `profileTypeList` labels it renders
(lib/core/api/model/individual_profile_type_model.dart).

Two groups of keys:
  * NEW      — sheet title / dropdown labels / profile-type cards, absent in all
               five languages.
  * BACKFILL — keys that already shipped in en+hi but never got gu/mr/kn; the
               en/hi values here are the existing ones, kept verbatim so the PUT
               is idempotent.

Run:  python3 scripts/profile_designation_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "profile_designation_lang_payloads")

T = {
    "en": {
        # --- new ---
        "profileDataTitle": "Profile Data",
        "selectProfileType": "Select Profile Type",
        "selectProfession": "Select Profession",
        "selectExpertiseHint": "Select expertise",
        "socialProfileSubTitle": "Eg. Politician, Student, Artist...",
        "skilledServicesTitle": "Skilled Services",
        "skilledServicesSubTitle": "Eg. Electrician, Plumber, Carpenter...",
        "selfEmployedGigTitle": "Self-Employed (Delivery / Taxi)",
        "selfEmployedGigSubTitle": "Eg. Driver, Delivery Rider...",
        "professionalConsultantTitle": "Professional Consultant",
        "professionalConsultantSubTitle": "Eg. Doctor, Lawyer, Consultant...",
        # --- backfill (existing en values) ---
        "specialization": "Specialization",
        "selectYourField": "Select your Field",
        "selectYourSpecification": "Select Your Specification",
        "autoUnionExample": "eg. Auto Union",
        "enterYourEducation": "Enter your Education",
        "nameOfGovtPSU": "Name of Government/PSU",
        "govtPSUExample": "Eg. ONGC",
        "enterNameOfGovtPSU": "Please enter your Name of Government/PSU",
        "govtPSUMaxLength":
            "Name of Government/PSU must not exceed 24 characters",
        "designationExpertise": "Designation / Expertise",
        "enterDesignationExpertise": "Enter your designation/expertise",
    },
    "hi": {
        "profileDataTitle": "प्रोफ़ाइल डेटा",
        "selectProfileType": "प्रोफ़ाइल प्रकार चुनें",
        "selectProfession": "पेशा चुनें",
        "selectExpertiseHint": "विशेषज्ञता चुनें",
        "socialProfileSubTitle": "उदा. राजनेता, छात्र, कलाकार...",
        "skilledServicesTitle": "कुशल सेवाएं",
        "skilledServicesSubTitle": "उदा. इलेक्ट्रीशियन, प्लंबर, बढ़ई...",
        "selfEmployedGigTitle": "स्व-रोज़गार (डिलीवरी / टैक्सी)",
        "selfEmployedGigSubTitle": "उदा. ड्राइवर, डिलीवरी राइडर...",
        "professionalConsultantTitle": "पेशेवर सलाहकार",
        "professionalConsultantSubTitle": "उदा. डॉक्टर, वकील, सलाहकार...",
        # --- backfill (existing hi values) ---
        "specialization": "विशेषज्ञता",
        "selectYourField": "अपना क्षेत्र चुनें",
        "selectYourSpecification": "अपनी विशिष्टता चुनें",
        "autoUnionExample": "उदा. ऑटो यूनियन",
        "enterYourEducation": "अपनी शिक्षा दर्ज करें",
        "nameOfGovtPSU": "सरकारी/PSU का नाम",
        "govtPSUExample": "उदा. ONGC",
        "enterNameOfGovtPSU": "कृपया अपने सरकारी/PSU का नाम दर्ज करें",
        "govtPSUMaxLength":
            "सरकारी/PSU का नाम 24 अक्षरों से अधिक नहीं होना चाहिए",
        "designationExpertise": "पदनाम / विशेषज्ञता",
        "enterDesignationExpertise": "अपना पदनाम/विशेषज्ञता दर्ज करें",
    },
    "gu": {
        "profileDataTitle": "પ્રોફાઇલ ડેટા",
        "selectProfileType": "પ્રોફાઇલ પ્રકાર પસંદ કરો",
        "selectProfession": "વ્યવસાય પસંદ કરો",
        "selectExpertiseHint": "નિપુણતા પસંદ કરો",
        "socialProfileSubTitle": "દા.ત. રાજકારણી, વિદ્યાર્થી, કલાકાર...",
        "skilledServicesTitle": "કુશળ સેવાઓ",
        "skilledServicesSubTitle": "દા.ત. ઇલેક્ટ્રિશિયન, પ્લમ્બર, સુથાર...",
        "selfEmployedGigTitle": "સ્વ-રોજગાર (ડિલિવરી / ટેક્સી)",
        "selfEmployedGigSubTitle": "દા.ત. ડ્રાઇવર, ડિલિવરી રાઇડર...",
        "professionalConsultantTitle": "વ્યાવસાયિક સલાહકાર",
        "professionalConsultantSubTitle": "દા.ત. ડૉક્ટર, વકીલ, સલાહકાર...",
        "specialization": "વિશેષજ્ઞતા",
        "selectYourField": "તમારું ક્ષેત્ર પસંદ કરો",
        "selectYourSpecification": "તમારી વિશિષ્ટતા પસંદ કરો",
        "autoUnionExample": "દા.ત. ઓટો યુનિયન",
        "enterYourEducation": "તમારું શિક્ષણ દાખલ કરો",
        "nameOfGovtPSU": "સરકારી/PSU નું નામ",
        "govtPSUExample": "દા.ત. ONGC",
        "enterNameOfGovtPSU": "કૃપા કરીને તમારા સરકારી/PSU નું નામ દાખલ કરો",
        "govtPSUMaxLength":
            "સરકારી/PSU નું નામ 24 અક્ષરોથી વધુ ન હોવું જોઈએ",
        "designationExpertise": "હોદ્દો / નિપુણતા",
        "enterDesignationExpertise": "તમારો હોદ્દો/નિપુણતા દાખલ કરો",
    },
    "mr": {
        "profileDataTitle": "प्रोफाइल डेटा",
        "selectProfileType": "प्रोफाइल प्रकार निवडा",
        "selectProfession": "व्यवसाय निवडा",
        "selectExpertiseHint": "कौशल्य निवडा",
        "socialProfileSubTitle": "उदा. राजकारणी, विद्यार्थी, कलाकार...",
        "skilledServicesTitle": "कुशल सेवा",
        "skilledServicesSubTitle": "उदा. इलेक्ट्रिशियन, प्लंबर, सुतार...",
        "selfEmployedGigTitle": "स्वयंरोजगार (डिलिव्हरी / टॅक्सी)",
        "selfEmployedGigSubTitle": "उदा. ड्रायव्हर, डिलिव्हरी रायडर...",
        "professionalConsultantTitle": "व्यावसायिक सल्लागार",
        "professionalConsultantSubTitle": "उदा. डॉक्टर, वकील, सल्लागार...",
        "specialization": "विशेषज्ञता",
        "selectYourField": "तुमचे क्षेत्र निवडा",
        "selectYourSpecification": "तुमची विशिष्टता निवडा",
        "autoUnionExample": "उदा. ऑटो युनियन",
        "enterYourEducation": "तुमचे शिक्षण प्रविष्ट करा",
        "nameOfGovtPSU": "सरकारी/PSU चे नाव",
        "govtPSUExample": "उदा. ONGC",
        "enterNameOfGovtPSU": "कृपया तुमच्या सरकारी/PSU चे नाव प्रविष्ट करा",
        "govtPSUMaxLength":
            "सरकारी/PSU चे नाव 24 अक्षरांपेक्षा जास्त नसावे",
        "designationExpertise": "पदनाम / कौशल्य",
        "enterDesignationExpertise": "तुमचे पदनाम/कौशल्य प्रविष्ट करा",
    },
    "kn": {
        "profileDataTitle": "ಪ್ರೊಫೈಲ್ ಡೇಟಾ",
        "selectProfileType": "ಪ್ರೊಫೈಲ್ ಪ್ರಕಾರ ಆಯ್ಕೆಮಾಡಿ",
        "selectProfession": "ವೃತ್ತಿಯನ್ನು ಆಯ್ಕೆಮಾಡಿ",
        "selectExpertiseHint": "ಪರಿಣತಿಯನ್ನು ಆಯ್ಕೆಮಾಡಿ",
        "socialProfileSubTitle": "ಉದಾ. ರಾಜಕಾರಣಿ, ವಿದ್ಯಾರ್ಥಿ, ಕಲಾವಿದ...",
        "skilledServicesTitle": "ನುರಿತ ಸೇವೆಗಳು",
        "skilledServicesSubTitle": "ಉದಾ. ಎಲೆಕ್ಟ್ರಿಷಿಯನ್, ಪ್ಲಂಬರ್, ಬಡಗಿ...",
        "selfEmployedGigTitle": "ಸ್ವಯಂ ಉದ್ಯೋಗ (ಡೆಲಿವರಿ / ಟ್ಯಾಕ್ಸಿ)",
        "selfEmployedGigSubTitle": "ಉದಾ. ಚಾಲಕ, ಡೆಲಿವರಿ ರೈಡರ್...",
        "professionalConsultantTitle": "ವೃತ್ತಿಪರ ಸಲಹೆಗಾರ",
        "professionalConsultantSubTitle": "ಉದಾ. ವೈದ್ಯರು, ವಕೀಲರು, ಸಲಹೆಗಾರರು...",
        "specialization": "ಪರಿಣತಿ",
        "selectYourField": "ನಿಮ್ಮ ಕ್ಷೇತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ",
        "selectYourSpecification": "ನಿಮ್ಮ ವಿಶೇಷತೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ",
        "autoUnionExample": "ಉದಾ. ಆಟೋ ಯೂನಿಯನ್",
        "enterYourEducation": "ನಿಮ್ಮ ಶಿಕ್ಷಣವನ್ನು ನಮೂದಿಸಿ",
        "nameOfGovtPSU": "ಸರ್ಕಾರಿ/PSU ಹೆಸರು",
        "govtPSUExample": "ಉದಾ. ONGC",
        "enterNameOfGovtPSU": "ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸರ್ಕಾರಿ/PSU ಹೆಸರನ್ನು ನಮೂದಿಸಿ",
        "govtPSUMaxLength":
            "ಸರ್ಕಾರಿ/PSU ಹೆಸರು 24 ಅಕ್ಷರಗಳನ್ನು ಮೀರಬಾರದು",
        "designationExpertise": "ಹುದ್ದೆ / ಪರಿಣತಿ",
        "enterDesignationExpertise": "ನಿಮ್ಮ ಹುದ್ದೆ/ಪರಿಣತಿಯನ್ನು ನಮೂದಿಸಿ",
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
