#!/usr/bin/env python3
"""Localization for the Social home screen
(lib/features/me/social/view/social_home_screen.dart).

Two groups of keys:
  * NEW      — the "Latest Post" chapter title and the ten per-section empty
               state messages, absent in all five languages.
  * BACKFILL — section titles, the Reception contact row, the post-action row
               and the relative-timestamp units that had only shipped in en+hi;
               the en/hi values here are the existing ones, kept verbatim so the
               PUT is idempotent.

Run:  python3 scripts/social_home_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "social_home_lang_payloads")

T = {
    "en": {
        # --- new ---
        "latestPost": "Latest Post",
        "socialEmptyActivities": "Showcase your activities and feed posts",
        "socialEmptyVisionMission":
            "Define your vision & mission to inspire others",
        "socialEmptyEvents": "Schedule and share your upcoming events",
        "socialEmptyAchievements":
            "Highlight your certificates & achievements",
        "socialEmptySocialActivities":
            "Share your social contributions & initiatives",
        "socialEmptyLatestPost":
            "Create your first post to engage with your audience",
        "socialEmptyGallery": "Your gallery is empty - add photos to showcase",
        "socialEmptyTestimonials":
            "Testimonials from people who know your work",
        "socialEmptyContact":
            "Add your contact details so people can reach you",
        "socialEmptyQuickLinks":
            "Add quick links to your important resources",
        # --- backfill (existing en values) ---
        "activities": "Activities",
        "vision_mission": "Vision & Mission",
        "social_activity": "Social Activity",
        "quickLinksLabel": "Quick Links",
        "reception": "Reception",
        "like": "Like",
        "comment": "Comment",
        "days_ago": "days ago",
        "hours_ago": "hours ago",
        "minutes_ago": "minutes ago",
    },
    "hi": {
        "latestPost": "नवीनतम पोस्ट",
        "socialEmptyActivities":
            "अपनी गतिविधियां और फ़ीड पोस्ट प्रदर्शित करें",
        "socialEmptyVisionMission":
            "दूसरों को प्रेरित करने के लिए अपनी दृष्टि और लक्ष्य निर्धारित करें",
        "socialEmptyEvents":
            "अपने आगामी कार्यक्रम शेड्यूल करें और साझा करें",
        "socialEmptyAchievements":
            "अपने प्रमाणपत्र और उपलब्धियां प्रदर्शित करें",
        "socialEmptySocialActivities":
            "अपने सामाजिक योगदान और पहल साझा करें",
        "socialEmptyLatestPost":
            "अपने दर्शकों से जुड़ने के लिए अपनी पहली पोस्ट बनाएं",
        "socialEmptyGallery":
            "आपकी गैलरी खाली है - प्रदर्शित करने के लिए फ़ोटो जोड़ें",
        "socialEmptyTestimonials":
            "उन लोगों के प्रशंसापत्र जो आपके काम को जानते हैं",
        "socialEmptyContact":
            "अपनी संपर्क जानकारी जोड़ें ताकि लोग आप तक पहुंच सकें",
        "socialEmptyQuickLinks":
            "अपने महत्वपूर्ण संसाधनों के लिए त्वरित लिंक जोड़ें",
        # --- backfill (existing hi values) ---
        "activities": "गतिविधियां",
        "vision_mission": "दृष्टि और लक्ष्य",
        "social_activity": "सामाजिक गतिविधि",
        "quickLinksLabel": "त्वरित लिंक",
        "reception": "रिसेप्शन (पूछताछ)",
        "like": "लाइक",
        "comment": "टिप्पणी",
        "days_ago": "दिन पहले",
        "hours_ago": "घंटे पहले",
        "minutes_ago": "मिनट पहले",
    },
    "gu": {
        "latestPost": "નવીનતમ પોસ્ટ",
        "socialEmptyActivities":
            "તમારી પ્રવૃત્તિઓ અને ફીડ પોસ્ટ પ્રદર્શિત કરો",
        "socialEmptyVisionMission":
            "બીજાને પ્રેરણા આપવા માટે તમારી દ્રષ્ટિ અને ધ્યેય નક્કી કરો",
        "socialEmptyEvents":
            "તમારા આગામી કાર્યક્રમો શેડ્યૂલ કરો અને શેર કરો",
        "socialEmptyAchievements":
            "તમારા પ્રમાણપત્રો અને સિદ્ધિઓ પ્રદર્શિત કરો",
        "socialEmptySocialActivities":
            "તમારા સામાજિક યોગદાન અને પહેલ શેર કરો",
        "socialEmptyLatestPost":
            "તમારા પ્રેક્ષકો સાથે જોડાવા માટે તમારી પ્રથમ પોસ્ટ બનાવો",
        "socialEmptyGallery":
            "તમારી ગેલેરી ખાલી છે - પ્રદર્શિત કરવા માટે ફોટા ઉમેરો",
        "socialEmptyTestimonials":
            "તમારા કામને જાણતા લોકોના પ્રશંસાપત્રો",
        "socialEmptyContact":
            "તમારી સંપર્ક વિગતો ઉમેરો જેથી લોકો તમારા સુધી પહોંચી શકે",
        "socialEmptyQuickLinks":
            "તમારા મહત્વપૂર્ણ સંસાધનો માટે ઝડપી લિંક્સ ઉમેરો",
        "activities": "પ્રવૃત્તિઓ",
        "vision_mission": "દ્રષ્ટિ અને ધ્યેય",
        "social_activity": "સામાજિક પ્રવૃત્તિ",
        "quickLinksLabel": "ઝડપી લિંક્સ",
        "reception": "રિસેપ્શન",
        "like": "લાઇક",
        "comment": "કોમેન્ટ",
        "days_ago": "દિવસ પહેલા",
        "hours_ago": "કલાક પહેલા",
        "minutes_ago": "મિનિટ પહેલા",
    },
    "mr": {
        "latestPost": "नवीनतम पोस्ट",
        "socialEmptyActivities":
            "तुमच्या क्रियाकलाप आणि फीड पोस्ट प्रदर्शित करा",
        "socialEmptyVisionMission":
            "इतरांना प्रेरणा देण्यासाठी तुमची दृष्टी आणि ध्येय निश्चित करा",
        "socialEmptyEvents":
            "तुमचे आगामी कार्यक्रम शेड्यूल करा आणि शेअर करा",
        "socialEmptyAchievements":
            "तुमची प्रमाणपत्रे आणि यश प्रदर्शित करा",
        "socialEmptySocialActivities":
            "तुमचे सामाजिक योगदान आणि उपक्रम शेअर करा",
        "socialEmptyLatestPost":
            "तुमच्या प्रेक्षकांशी जोडण्यासाठी तुमची पहिली पोस्ट तयार करा",
        "socialEmptyGallery":
            "तुमची गॅलरी रिकामी आहे - प्रदर्शित करण्यासाठी फोटो जोडा",
        "socialEmptyTestimonials":
            "तुमचे काम जाणणाऱ्या लोकांची प्रशंसापत्रे",
        "socialEmptyContact":
            "तुमचे संपर्क तपशील जोडा जेणेकरून लोक तुमच्यापर्यंत पोहोचू शकतील",
        "socialEmptyQuickLinks":
            "तुमच्या महत्त्वाच्या संसाधनांसाठी द्रुत लिंक जोडा",
        "activities": "क्रियाकलाप",
        "vision_mission": "दृष्टी आणि ध्येय",
        "social_activity": "सामाजिक क्रियाकलाप",
        "quickLinksLabel": "द्रुत लिंक",
        "reception": "रिसेप्शन",
        "like": "लाइक",
        "comment": "टिप्पणी",
        "days_ago": "दिवसांपूर्वी",
        "hours_ago": "तासांपूर्वी",
        "minutes_ago": "मिनिटांपूर्वी",
    },
    "kn": {
        "latestPost": "ಇತ್ತೀಚಿನ ಪೋಸ್ಟ್",
        "socialEmptyActivities":
            "ನಿಮ್ಮ ಚಟುವಟಿಕೆಗಳು ಮತ್ತು ಫೀಡ್ ಪೋಸ್ಟ್‌ಗಳನ್ನು ಪ್ರದರ್ಶಿಸಿ",
        "socialEmptyVisionMission":
            "ಇತರರಿಗೆ ಸ್ಫೂರ್ತಿ ನೀಡಲು ನಿಮ್ಮ ದೃಷ್ಟಿ ಮತ್ತು ಧ್ಯೇಯವನ್ನು ನಿರ್ಧರಿಸಿ",
        "socialEmptyEvents":
            "ನಿಮ್ಮ ಮುಂಬರುವ ಕಾರ್ಯಕ್ರಮಗಳನ್ನು ನಿಗದಿಪಡಿಸಿ ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಿ",
        "socialEmptyAchievements":
            "ನಿಮ್ಮ ಪ್ರಮಾಣಪತ್ರಗಳು ಮತ್ತು ಸಾಧನೆಗಳನ್ನು ಪ್ರದರ್ಶಿಸಿ",
        "socialEmptySocialActivities":
            "ನಿಮ್ಮ ಸಾಮಾಜಿಕ ಕೊಡುಗೆಗಳು ಮತ್ತು ಉಪಕ್ರಮಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಿ",
        "socialEmptyLatestPost":
            "ನಿಮ್ಮ ಪ್ರೇಕ್ಷಕರೊಂದಿಗೆ ತೊಡಗಿಸಿಕೊಳ್ಳಲು ನಿಮ್ಮ ಮೊದಲ ಪೋಸ್ಟ್ ರಚಿಸಿ",
        "socialEmptyGallery":
            "ನಿಮ್ಮ ಗ್ಯಾಲರಿ ಖಾಲಿಯಾಗಿದೆ - ಪ್ರದರ್ಶಿಸಲು ಫೋಟೋಗಳನ್ನು ಸೇರಿಸಿ",
        "socialEmptyTestimonials":
            "ನಿಮ್ಮ ಕೆಲಸವನ್ನು ತಿಳಿದಿರುವ ಜನರ ಪ್ರಶಂಸಾಪತ್ರಗಳು",
        "socialEmptyContact":
            "ಜನರು ನಿಮ್ಮನ್ನು ತಲುಪುವಂತೆ ನಿಮ್ಮ ಸಂಪರ್ಕ ವಿವರಗಳನ್ನು ಸೇರಿಸಿ",
        "socialEmptyQuickLinks":
            "ನಿಮ್ಮ ಪ್ರಮುಖ ಸಂಪನ್ಮೂಲಗಳಿಗೆ ತ್ವರಿತ ಲಿಂಕ್‌ಗಳನ್ನು ಸೇರಿಸಿ",
        "activities": "ಚಟುವಟಿಕೆಗಳು",
        "vision_mission": "ದೃಷ್ಟಿ ಮತ್ತು ಧ್ಯೇಯ",
        "social_activity": "ಸಾಮಾಜಿಕ ಚಟುವಟಿಕೆ",
        "quickLinksLabel": "ತ್ವರಿತ ಲಿಂಕ್‌ಗಳು",
        "reception": "ಸ್ವಾಗತ",
        "like": "ಲೈಕ್",
        "comment": "ಕಾಮೆಂಟ್",
        "days_ago": "ದಿನಗಳ ಹಿಂದೆ",
        "hours_ago": "ಗಂಟೆಗಳ ಹಿಂದೆ",
        "minutes_ago": "ನಿಮಿಷಗಳ ಹಿಂದೆ",
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
