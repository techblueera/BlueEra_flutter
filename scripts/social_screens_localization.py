#!/usr/bin/env python3
"""Localization for the Social module screens under lib/features/me/social/view/:
event_schedule, social_activity_form, social_activity_list,
social_add_achievements, social_create_event, social_vision_mission,
social_achievements/social_certificates, social_contact_us/{form,view},
social_feed/{add_social_feed,social_feed}.

Two groups of keys:
  * NEW      — card titles, field hints and empty states that had no key at all.
  * BACKFILL — keys that already shipped in en+hi (and `toSeparator` in en only)
               but never got the remaining languages; the existing en/hi values
               are reused verbatim so the PUT is idempotent for those.

Run:  python3 scripts/social_screens_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "social_screens_lang_payloads")

T = {
    "en": {
        # --- new ---
        "noTitle": "No Title",
        "activityInfo": "Activity Info",
        "activityDetails": "Activity Details",
        "eventDetails": "Event Details",
        "dateAndTime": "Date & Time",
        "dateAndLocation": "Date & Location",
        "roleAndImpact": "Role & Impact",
        "venueAndRegistration": "Venue & Registration",
        "personalInfoTitle": "Personal Info",
        "contactDetailsTitle": "Contact Details",
        "selectStartDate": "Select start date",
        "selectStartDateFirst": "Select start date first",
        "selectEndDate": "Select end date",
        "tapToUploadImage": "Tap to upload image",
        "addCertificate": "Add Certificate",
        "editCertificate": "Edit Certificate",
        "locationSearchHint": "E.g. Lucknow, Uttar Pradesh...",
        "registrationLinkHint": "E.g. https://registrationlink...",
        "socialTapCreateFirstEvent": "Tap + to create your first event",
        "socialTapAddFirstActivity":
            "Tap + to add your first social activity",
        "socialTapAddFirstCertificate":
            "Tap + to add your first certificate",
        "socialTapCreateFirstFeed":
            "Tap + to create your first activity feed",
        "socialAddPhotoForActivity": "Add a photo for this activity",
        "socialAddUpToFivePhotos": "Add up to 5 photos",
        "socialFreeMedicinesHint": "Free medicines & doctor consultation",
        "socialActivityTypeHint": "E.g. Health Camp, Education...",
        "socialActivityTitleHint": "Give your activity a title...",
        "socialDescribeActivityHint": "Describe your activity...",
        "socialYourRoleHint": "E.g. Organizer, Chief Guest...",
        "socialOrganizerHint": "E.g. Organization Name...",
        "socialImpactHint": "E.g. 80 villagers / 1.2K Peoples benefited...",
        "socialShareAchievementHint": "Share your achievement...",
        "socialDescribeAchievementHint": "Describe your achievement...",
        "socialEventTitleHint": "E.g. Annual Meet 2025",
        "socialEventTypeHint": "E.g. Meeting / Show / Live...",
        "socialCertificateTitleHint": "E.g. Certificate of Excellence",
        "socialCertificatesBanner":
            "Showcase your certificates and achievements",
        "socialVisionMissionBanner":
            "Share your vision & mission to inspire your audience",
        "socialVisionMissionHint": "Tell us about your Vision & Mission...",
        "socialVisionImageHint": "Add an image to represent your vision",
        "socialDescribeYourAim": "Describe what you aim to achieve",
        "socialFullNameHint": "E.g. Rajesh Kr. Rajak",
        # --- backfill (existing en values) ---
        "activity_feed": "Activity Feed",
        "activity_title": "Activity Title",
        "activity_type": "Activity Type",
        "add_activity_feed": "Add Activity Feed",
        "beneficiaries_impact": "Beneficiaries/Impact (Forecast)",
        "create_event": "Create Event",
        "create_new": "Create New",
        "delete_event_confirm":
            "Are you sure you want to delete this event?\nThis action cannot be undone.",
        "description_message": "Description of Message",
        "edit_activity_feed": "Edit Activity Feed",
        "event_title": "Event Title",
        "event_type": "Event Type",
        "events_schedule": "Events / Schedule",
        "from": "From",
        "no_activities_found": "No activities found",
        "no_events_found": "No events found",
        "organizer_name": "Organizer Name",
        "registration_link": "Registration Link",
        "social_details": "Social Details",
        "starting_date": "Starting Date",
        "time": "Time",
        "timing": "Timing",
        "update_event": "Update Event",
        "venue": "Venue",
        "toLabel": "To",
        "toSeparator": "to",
        "user_fallback": "User",
        "certificate": "Certificate",
        "eg_free_health_checkup": "E.g. Free Health Check-up Camp...",
    },
    "hi": {
        "noTitle": "कोई शीर्षक नहीं",
        "activityInfo": "गतिविधि जानकारी",
        "activityDetails": "गतिविधि विवरण",
        "eventDetails": "कार्यक्रम विवरण",
        "dateAndTime": "तिथि और समय",
        "dateAndLocation": "तिथि और स्थान",
        "roleAndImpact": "भूमिका और प्रभाव",
        "venueAndRegistration": "स्थान और पंजीकरण",
        "personalInfoTitle": "व्यक्तिगत जानकारी",
        "contactDetailsTitle": "संपर्क विवरण",
        "selectStartDate": "प्रारंभ तिथि चुनें",
        "selectStartDateFirst": "पहले प्रारंभ तिथि चुनें",
        "selectEndDate": "समाप्ति तिथि चुनें",
        "tapToUploadImage": "छवि अपलोड करने के लिए टैप करें",
        "addCertificate": "प्रमाणपत्र जोड़ें",
        "editCertificate": "प्रमाणपत्र संपादित करें",
        "locationSearchHint": "उदा. लखनऊ, उत्तर प्रदेश...",
        "registrationLinkHint": "उदा. https://registrationlink...",
        "socialTapCreateFirstEvent":
            "अपना पहला कार्यक्रम बनाने के लिए + दबाएं",
        "socialTapAddFirstActivity":
            "अपनी पहली सामाजिक गतिविधि जोड़ने के लिए + दबाएं",
        "socialTapAddFirstCertificate":
            "अपना पहला प्रमाणपत्र जोड़ने के लिए + दबाएं",
        "socialTapCreateFirstFeed":
            "अपनी पहली एक्टिविटी फीड बनाने के लिए + दबाएं",
        "socialAddPhotoForActivity": "इस गतिविधि के लिए एक फ़ोटो जोड़ें",
        "socialAddUpToFivePhotos": "5 फ़ोटो तक जोड़ें",
        "socialFreeMedicinesHint": "मुफ्त दवाइयां और डॉक्टर परामर्श",
        "socialActivityTypeHint": "उदा. स्वास्थ्य शिविर, शिक्षा...",
        "socialActivityTitleHint": "अपनी गतिविधि को एक शीर्षक दें...",
        "socialDescribeActivityHint": "अपनी गतिविधि का वर्णन करें...",
        "socialYourRoleHint": "उदा. आयोजक, मुख्य अतिथि...",
        "socialOrganizerHint": "उदा. संगठन का नाम...",
        "socialImpactHint": "उदा. 80 ग्रामीण / 1.2K लोग लाभान्वित...",
        "socialShareAchievementHint": "अपनी उपलब्धि साझा करें...",
        "socialDescribeAchievementHint": "अपनी उपलब्धि का वर्णन करें...",
        "socialEventTitleHint": "उदा. वार्षिक सम्मेलन 2025",
        "socialEventTypeHint": "उदा. बैठक / शो / लाइव...",
        "socialCertificateTitleHint": "उदा. उत्कृष्टता प्रमाणपत्र",
        "socialCertificatesBanner":
            "अपने प्रमाणपत्र और उपलब्धियां प्रदर्शित करें",
        "socialVisionMissionBanner":
            "अपने दर्शकों को प्रेरित करने के लिए अपनी दृष्टि और लक्ष्य साझा करें",
        "socialVisionMissionHint":
            "हमें अपनी दृष्टि और लक्ष्य के बारे में बताएं...",
        "socialVisionImageHint":
            "अपनी दृष्टि को दर्शाने के लिए एक छवि जोड़ें",
        "socialDescribeYourAim":
            "आप क्या हासिल करना चाहते हैं, इसका वर्णन करें",
        "socialFullNameHint": "उदा. राजेश कु. रजक",
        # --- backfill (existing hi values) ---
        "activity_feed": "एक्टिविटी फीड",
        "activity_title": "गतिविधि का शीर्षक",
        "activity_type": "गतिविधि का प्रकार",
        "add_activity_feed": "एक्टिविटी फीड जोड़ें",
        "beneficiaries_impact": "लाभार्थी/प्रभाव (पूर्वानुमान)",
        "create_event": "कार्यक्रम बनाएं",
        "create_new": "नया बनाएं",
        "delete_event_confirm":
            "क्या आप वाकई इस कार्यक्रम को हटाना चाहते हैं?\nयह क्रिया पूर्ववत नहीं की जा सकती।",
        "description_message": "संदेश का विवरण",
        "edit_activity_feed": "एक्टिविटी फीड संपादित करें",
        "event_title": "कार्यक्रम का शीर्षक",
        "event_type": "कार्यक्रम का प्रकार",
        "events_schedule": "कार्यक्रम / समय सारणी",
        "from": "से",
        "no_activities_found": "कोई गतिविधि नहीं मिली",
        "no_events_found": "कोई कार्यक्रम नहीं मिला",
        "organizer_name": "आयोजक का नाम",
        "registration_link": "पंजीकरण लिंक",
        "social_details": "सामाजिक विवरण",
        "starting_date": "प्रारंभ तिथि",
        "time": "समय",
        "timing": "समय",
        "update_event": "कार्यक्रम अपडेट करें",
        "venue": "स्थान (वेन्यू)",
        "toLabel": "तक",
        "toSeparator": "से",
        "user_fallback": "उपयोगकर्ता",
        "certificate": "प्रमाणपत्र",
        "eg_free_health_checkup": "उदा. मुफ्त स्वास्थ्य जांच शिविर...",
    },
    "gu": {
        "noTitle": "કોઈ શીર્ષક નથી",
        "activityInfo": "પ્રવૃત્તિ માહિતી",
        "activityDetails": "પ્રવૃત્તિ વિગતો",
        "eventDetails": "કાર્યક્રમ વિગતો",
        "dateAndTime": "તારીખ અને સમય",
        "dateAndLocation": "તારીખ અને સ્થળ",
        "roleAndImpact": "ભૂમિકા અને પ્રભાવ",
        "venueAndRegistration": "સ્થળ અને નોંધણી",
        "personalInfoTitle": "વ્યક્તિગત માહિતી",
        "contactDetailsTitle": "સંપર્ક વિગતો",
        "selectStartDate": "શરૂઆતની તારીખ પસંદ કરો",
        "selectStartDateFirst": "પહેલા શરૂઆતની તારીખ પસંદ કરો",
        "selectEndDate": "સમાપ્તિ તારીખ પસંદ કરો",
        "tapToUploadImage": "છબી અપલોડ કરવા માટે ટૅપ કરો",
        "addCertificate": "પ્રમાણપત્ર ઉમેરો",
        "editCertificate": "પ્રમાણપત્ર સંપાદિત કરો",
        "locationSearchHint": "દા.ત. લખનૌ, ઉત્તર પ્રદેશ...",
        "registrationLinkHint": "દા.ત. https://registrationlink...",
        "socialTapCreateFirstEvent":
            "તમારો પ્રથમ કાર્યક્રમ બનાવવા માટે + દબાવો",
        "socialTapAddFirstActivity":
            "તમારી પ્રથમ સામાજિક પ્રવૃત્તિ ઉમેરવા માટે + દબાવો",
        "socialTapAddFirstCertificate":
            "તમારું પ્રથમ પ્રમાણપત્ર ઉમેરવા માટે + દબાવો",
        "socialTapCreateFirstFeed":
            "તમારી પ્રથમ પ્રવૃત્તિ ફીડ બનાવવા માટે + દબાવો",
        "socialAddPhotoForActivity": "આ પ્રવૃત્તિ માટે એક ફોટો ઉમેરો",
        "socialAddUpToFivePhotos": "5 ફોટા સુધી ઉમેરો",
        "socialFreeMedicinesHint": "મફત દવાઓ અને ડૉક્ટર પરામર્શ",
        "socialActivityTypeHint": "દા.ત. આરોગ્ય શિબિર, શિક્ષણ...",
        "socialActivityTitleHint": "તમારી પ્રવૃત્તિને શીર્ષક આપો...",
        "socialDescribeActivityHint": "તમારી પ્રવૃત્તિનું વર્ણન કરો...",
        "socialYourRoleHint": "દા.ત. આયોજક, મુખ્ય મહેમાન...",
        "socialOrganizerHint": "દા.ત. સંસ્થાનું નામ...",
        "socialImpactHint": "દા.ત. 80 ગ્રામજનો / 1.2K લોકોને લાભ...",
        "socialShareAchievementHint": "તમારી સિદ્ધિ શેર કરો...",
        "socialDescribeAchievementHint": "તમારી સિદ્ધિનું વર્ણન કરો...",
        "socialEventTitleHint": "દા.ત. વાર્ષિક સંમેલન 2025",
        "socialEventTypeHint": "દા.ત. બેઠક / શો / લાઇવ...",
        "socialCertificateTitleHint": "દા.ત. ઉત્કૃષ્ટતા પ્રમાણપત્ર",
        "socialCertificatesBanner":
            "તમારા પ્રમાણપત્રો અને સિદ્ધિઓ પ્રદર્શિત કરો",
        "socialVisionMissionBanner":
            "તમારા પ્રેક્ષકોને પ્રેરણા આપવા માટે તમારી દ્રષ્ટિ અને ધ્યેય શેર કરો",
        "socialVisionMissionHint":
            "અમને તમારી દ્રષ્ટિ અને ધ્યેય વિશે જણાવો...",
        "socialVisionImageHint":
            "તમારી દ્રષ્ટિ દર્શાવવા માટે એક છબી ઉમેરો",
        "socialDescribeYourAim":
            "તમે શું હાંસલ કરવા માંગો છો તેનું વર્ણન કરો",
        "socialFullNameHint": "દા.ત. રાજેશ કુ. રજક",
        "activity_feed": "પ્રવૃત્તિ ફીડ",
        "activity_title": "પ્રવૃત્તિનું શીર્ષક",
        "activity_type": "પ્રવૃત્તિનો પ્રકાર",
        "add_activity_feed": "પ્રવૃત્તિ ફીડ ઉમેરો",
        "beneficiaries_impact": "લાભાર્થીઓ/પ્રભાવ (અનુમાન)",
        "create_event": "કાર્યક્રમ બનાવો",
        "create_new": "નવું બનાવો",
        "delete_event_confirm":
            "શું તમે ખરેખર આ કાર્યક્રમ કાઢી નાખવા માંગો છો?\nઆ ક્રિયા પૂર્વવત્ કરી શકાતી નથી.",
        "description_message": "સંદેશનું વર્ણન",
        "edit_activity_feed": "પ્રવૃત્તિ ફીડ સંપાદિત કરો",
        "event_title": "કાર્યક્રમનું શીર્ષક",
        "event_type": "કાર્યક્રમનો પ્રકાર",
        "events_schedule": "કાર્યક્રમો / સમયપત્રક",
        "from": "થી",
        "no_activities_found": "કોઈ પ્રવૃત્તિ મળી નથી",
        "no_events_found": "કોઈ કાર્યક્રમ મળ્યો નથી",
        "organizer_name": "આયોજકનું નામ",
        "registration_link": "નોંધણી લિંક",
        "social_details": "સામાજિક વિગતો",
        "starting_date": "શરૂઆતની તારીખ",
        "time": "સમય",
        "timing": "સમય",
        "update_event": "કાર્યક્રમ અપડેટ કરો",
        "venue": "સ્થળ",
        "toLabel": "સુધી",
        "toSeparator": "થી",
        "user_fallback": "વપરાશકર્તા",
        "certificate": "પ્રમાણપત્ર",
        "eg_free_health_checkup": "દા.ત. મફત આરોગ્ય તપાસ શિબિર...",
    },
    "mr": {
        "noTitle": "शीर्षक नाही",
        "activityInfo": "क्रियाकलाप माहिती",
        "activityDetails": "क्रियाकलाप तपशील",
        "eventDetails": "कार्यक्रम तपशील",
        "dateAndTime": "तारीख आणि वेळ",
        "dateAndLocation": "तारीख आणि ठिकाण",
        "roleAndImpact": "भूमिका आणि प्रभाव",
        "venueAndRegistration": "ठिकाण आणि नोंदणी",
        "personalInfoTitle": "वैयक्तिक माहिती",
        "contactDetailsTitle": "संपर्क तपशील",
        "selectStartDate": "प्रारंभ तारीख निवडा",
        "selectStartDateFirst": "आधी प्रारंभ तारीख निवडा",
        "selectEndDate": "समाप्ती तारीख निवडा",
        "tapToUploadImage": "प्रतिमा अपलोड करण्यासाठी टॅप करा",
        "addCertificate": "प्रमाणपत्र जोडा",
        "editCertificate": "प्रमाणपत्र संपादित करा",
        "locationSearchHint": "उदा. लखनौ, उत्तर प्रदेश...",
        "registrationLinkHint": "उदा. https://registrationlink...",
        "socialTapCreateFirstEvent":
            "तुमचा पहिला कार्यक्रम तयार करण्यासाठी + दाबा",
        "socialTapAddFirstActivity":
            "तुमचा पहिला सामाजिक क्रियाकलाप जोडण्यासाठी + दाबा",
        "socialTapAddFirstCertificate":
            "तुमचे पहिले प्रमाणपत्र जोडण्यासाठी + दाबा",
        "socialTapCreateFirstFeed":
            "तुमची पहिली क्रियाकलाप फीड तयार करण्यासाठी + दाबा",
        "socialAddPhotoForActivity": "या क्रियाकलापासाठी फोटो जोडा",
        "socialAddUpToFivePhotos": "5 फोटोंपर्यंत जोडा",
        "socialFreeMedicinesHint": "मोफत औषधे आणि डॉक्टर सल्ला",
        "socialActivityTypeHint": "उदा. आरोग्य शिबिर, शिक्षण...",
        "socialActivityTitleHint": "तुमच्या क्रियाकलापाला शीर्षक द्या...",
        "socialDescribeActivityHint": "तुमच्या क्रियाकलापाचे वर्णन करा...",
        "socialYourRoleHint": "उदा. आयोजक, प्रमुख पाहुणे...",
        "socialOrganizerHint": "उदा. संस्थेचे नाव...",
        "socialImpactHint": "उदा. 80 गावकरी / 1.2K लोकांना लाभ...",
        "socialShareAchievementHint": "तुमचे यश शेअर करा...",
        "socialDescribeAchievementHint": "तुमच्या यशाचे वर्णन करा...",
        "socialEventTitleHint": "उदा. वार्षिक संमेलन 2025",
        "socialEventTypeHint": "उदा. बैठक / शो / लाइव्ह...",
        "socialCertificateTitleHint": "उदा. उत्कृष्टता प्रमाणपत्र",
        "socialCertificatesBanner":
            "तुमची प्रमाणपत्रे आणि यश प्रदर्शित करा",
        "socialVisionMissionBanner":
            "तुमच्या प्रेक्षकांना प्रेरणा देण्यासाठी तुमची दृष्टी आणि ध्येय शेअर करा",
        "socialVisionMissionHint":
            "आम्हाला तुमच्या दृष्टी आणि ध्येयाबद्दल सांगा...",
        "socialVisionImageHint":
            "तुमची दृष्टी दर्शवण्यासाठी एक प्रतिमा जोडा",
        "socialDescribeYourAim":
            "तुम्हाला काय साध्य करायचे आहे त्याचे वर्णन करा",
        "socialFullNameHint": "उदा. राजेश कु. रजक",
        "activity_feed": "क्रियाकलाप फीड",
        "activity_title": "क्रियाकलापाचे शीर्षक",
        "activity_type": "क्रियाकलापाचा प्रकार",
        "add_activity_feed": "क्रियाकलाप फीड जोडा",
        "beneficiaries_impact": "लाभार्थी/प्रभाव (अंदाज)",
        "create_event": "कार्यक्रम तयार करा",
        "create_new": "नवीन तयार करा",
        "delete_event_confirm":
            "तुम्हाला खात्री आहे की तुम्ही हा कार्यक्रम हटवू इच्छिता?\nही क्रिया पूर्ववत केली जाऊ शकत नाही.",
        "description_message": "संदेशाचे वर्णन",
        "edit_activity_feed": "क्रियाकलाप फीड संपादित करा",
        "event_title": "कार्यक्रमाचे शीर्षक",
        "event_type": "कार्यक्रमाचा प्रकार",
        "events_schedule": "कार्यक्रम / वेळापत्रक",
        "from": "पासून",
        "no_activities_found": "कोणताही क्रियाकलाप आढळला नाही",
        "no_events_found": "कोणताही कार्यक्रम आढळला नाही",
        "organizer_name": "आयोजकाचे नाव",
        "registration_link": "नोंदणी लिंक",
        "social_details": "सामाजिक तपशील",
        "starting_date": "प्रारंभ तारीख",
        "time": "वेळ",
        "timing": "वेळ",
        "update_event": "कार्यक्रम अपडेट करा",
        "venue": "ठिकाण",
        "toLabel": "पर्यंत",
        "toSeparator": "ते",
        "user_fallback": "वापरकर्ता",
        "certificate": "प्रमाणपत्र",
        "eg_free_health_checkup": "उदा. मोफत आरोग्य तपासणी शिबिर...",
    },
    "kn": {
        "noTitle": "ಶೀರ್ಷಿಕೆ ಇಲ್ಲ",
        "activityInfo": "ಚಟುವಟಿಕೆ ಮಾಹಿತಿ",
        "activityDetails": "ಚಟುವಟಿಕೆ ವಿವರಗಳು",
        "eventDetails": "ಕಾರ್ಯಕ್ರಮದ ವಿವರಗಳು",
        "dateAndTime": "ದಿನಾಂಕ ಮತ್ತು ಸಮಯ",
        "dateAndLocation": "ದಿನಾಂಕ ಮತ್ತು ಸ್ಥಳ",
        "roleAndImpact": "ಪಾತ್ರ ಮತ್ತು ಪ್ರಭಾವ",
        "venueAndRegistration": "ಸ್ಥಳ ಮತ್ತು ನೋಂದಣಿ",
        "personalInfoTitle": "ವೈಯಕ್ತಿಕ ಮಾಹಿತಿ",
        "contactDetailsTitle": "ಸಂಪರ್ಕ ವಿವರಗಳು",
        "selectStartDate": "ಪ್ರಾರಂಭ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ",
        "selectStartDateFirst": "ಮೊದಲು ಪ್ರಾರಂಭ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ",
        "selectEndDate": "ಅಂತಿಮ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ",
        "tapToUploadImage": "ಚಿತ್ರ ಅಪ್‌ಲೋಡ್ ಮಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ",
        "addCertificate": "ಪ್ರಮಾಣಪತ್ರ ಸೇರಿಸಿ",
        "editCertificate": "ಪ್ರಮಾಣಪತ್ರ ಸಂಪಾದಿಸಿ",
        "locationSearchHint": "ಉದಾ. ಲಕ್ನೋ, ಉತ್ತರ ಪ್ರದೇಶ...",
        "registrationLinkHint": "ಉದಾ. https://registrationlink...",
        "socialTapCreateFirstEvent":
            "ನಿಮ್ಮ ಮೊದಲ ಕಾರ್ಯಕ್ರಮ ರಚಿಸಲು + ಒತ್ತಿರಿ",
        "socialTapAddFirstActivity":
            "ನಿಮ್ಮ ಮೊದಲ ಸಾಮಾಜಿಕ ಚಟುವಟಿಕೆ ಸೇರಿಸಲು + ಒತ್ತಿರಿ",
        "socialTapAddFirstCertificate":
            "ನಿಮ್ಮ ಮೊದಲ ಪ್ರಮಾಣಪತ್ರ ಸೇರಿಸಲು + ಒತ್ತಿರಿ",
        "socialTapCreateFirstFeed":
            "ನಿಮ್ಮ ಮೊದಲ ಚಟುವಟಿಕೆ ಫೀಡ್ ರಚಿಸಲು + ಒತ್ತಿರಿ",
        "socialAddPhotoForActivity": "ಈ ಚಟುವಟಿಕೆಗೆ ಫೋಟೋ ಸೇರಿಸಿ",
        "socialAddUpToFivePhotos": "5 ಫೋಟೋಗಳವರೆಗೆ ಸೇರಿಸಿ",
        "socialFreeMedicinesHint": "ಉಚಿತ ಔಷಧಿಗಳು ಮತ್ತು ವೈದ್ಯರ ಸಮಾಲೋಚನೆ",
        "socialActivityTypeHint": "ಉದಾ. ಆರೋಗ್ಯ ಶಿಬಿರ, ಶಿಕ್ಷಣ...",
        "socialActivityTitleHint": "ನಿಮ್ಮ ಚಟುವಟಿಕೆಗೆ ಶೀರ್ಷಿಕೆ ನೀಡಿ...",
        "socialDescribeActivityHint": "ನಿಮ್ಮ ಚಟುವಟಿಕೆಯನ್ನು ವಿವರಿಸಿ...",
        "socialYourRoleHint": "ಉದಾ. ಸಂಘಟಕರು, ಮುಖ್ಯ ಅತಿಥಿ...",
        "socialOrganizerHint": "ಉದಾ. ಸಂಸ್ಥೆಯ ಹೆಸರು...",
        "socialImpactHint": "ಉದಾ. 80 ಗ್ರಾಮಸ್ಥರು / 1.2K ಜನರಿಗೆ ಪ್ರಯೋಜನ...",
        "socialShareAchievementHint": "ನಿಮ್ಮ ಸಾಧನೆಯನ್ನು ಹಂಚಿಕೊಳ್ಳಿ...",
        "socialDescribeAchievementHint": "ನಿಮ್ಮ ಸಾಧನೆಯನ್ನು ವಿವರಿಸಿ...",
        "socialEventTitleHint": "ಉದಾ. ವಾರ್ಷಿಕ ಸಮಾವೇಶ 2025",
        "socialEventTypeHint": "ಉದಾ. ಸಭೆ / ಪ್ರದರ್ಶನ / ಲೈವ್...",
        "socialCertificateTitleHint": "ಉದಾ. ಉತ್ಕೃಷ್ಟತೆ ಪ್ರಮಾಣಪತ್ರ",
        "socialCertificatesBanner":
            "ನಿಮ್ಮ ಪ್ರಮಾಣಪತ್ರಗಳು ಮತ್ತು ಸಾಧನೆಗಳನ್ನು ಪ್ರದರ್ಶಿಸಿ",
        "socialVisionMissionBanner":
            "ನಿಮ್ಮ ಪ್ರೇಕ್ಷಕರಿಗೆ ಸ್ಫೂರ್ತಿ ನೀಡಲು ನಿಮ್ಮ ದೃಷ್ಟಿ ಮತ್ತು ಧ್ಯೇಯವನ್ನು ಹಂಚಿಕೊಳ್ಳಿ",
        "socialVisionMissionHint":
            "ನಿಮ್ಮ ದೃಷ್ಟಿ ಮತ್ತು ಧ್ಯೇಯದ ಬಗ್ಗೆ ನಮಗೆ ತಿಳಿಸಿ...",
        "socialVisionImageHint":
            "ನಿಮ್ಮ ದೃಷ್ಟಿಯನ್ನು ಪ್ರತಿನಿಧಿಸಲು ಚಿತ್ರವನ್ನು ಸೇರಿಸಿ",
        "socialDescribeYourAim":
            "ನೀವು ಏನನ್ನು ಸಾಧಿಸಲು ಬಯಸುತ್ತೀರಿ ಎಂಬುದನ್ನು ವಿವರಿಸಿ",
        "socialFullNameHint": "ಉದಾ. ರಾಜೇಶ್ ಕು. ರಜಕ್",
        "activity_feed": "ಚಟುವಟಿಕೆ ಫೀಡ್",
        "activity_title": "ಚಟುವಟಿಕೆಯ ಶೀರ್ಷಿಕೆ",
        "activity_type": "ಚಟುವಟಿಕೆಯ ಪ್ರಕಾರ",
        "add_activity_feed": "ಚಟುವಟಿಕೆ ಫೀಡ್ ಸೇರಿಸಿ",
        "beneficiaries_impact": "ಫಲಾನುಭವಿಗಳು/ಪ್ರಭಾವ (ಮುನ್ಸೂಚನೆ)",
        "create_event": "ಕಾರ್ಯಕ್ರಮ ರಚಿಸಿ",
        "create_new": "ಹೊಸದನ್ನು ರಚಿಸಿ",
        "delete_event_confirm":
            "ಈ ಕಾರ್ಯಕ್ರಮವನ್ನು ಅಳಿಸಲು ನೀವು ಖಚಿತವಾಗಿ ಬಯಸುವಿರಾ?\nಈ ಕ್ರಿಯೆಯನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗುವುದಿಲ್ಲ.",
        "description_message": "ಸಂದೇಶದ ವಿವರಣೆ",
        "edit_activity_feed": "ಚಟುವಟಿಕೆ ಫೀಡ್ ಸಂಪಾದಿಸಿ",
        "event_title": "ಕಾರ್ಯಕ್ರಮದ ಶೀರ್ಷಿಕೆ",
        "event_type": "ಕಾರ್ಯಕ್ರಮದ ಪ್ರಕಾರ",
        "events_schedule": "ಕಾರ್ಯಕ್ರಮಗಳು / ವೇಳಾಪಟ್ಟಿ",
        "from": "ಇಂದ",
        "no_activities_found": "ಯಾವುದೇ ಚಟುವಟಿಕೆ ಕಂಡುಬಂದಿಲ್ಲ",
        "no_events_found": "ಯಾವುದೇ ಕಾರ್ಯಕ್ರಮ ಕಂಡುಬಂದಿಲ್ಲ",
        "organizer_name": "ಸಂಘಟಕರ ಹೆಸರು",
        "registration_link": "ನೋಂದಣಿ ಲಿಂಕ್",
        "social_details": "ಸಾಮಾಜಿಕ ವಿವರಗಳು",
        "starting_date": "ಪ್ರಾರಂಭ ದಿನಾಂಕ",
        "time": "ಸಮಯ",
        "timing": "ಸಮಯ",
        "update_event": "ಕಾರ್ಯಕ್ರಮ ಅಪ್‌ಡೇಟ್ ಮಾಡಿ",
        "venue": "ಸ್ಥಳ",
        "toLabel": "ವರೆಗೆ",
        "toSeparator": "ಇಂದ",
        "user_fallback": "ಬಳಕೆದಾರ",
        "certificate": "ಪ್ರಮಾಣಪತ್ರ",
        "eg_free_health_checkup": "ಉದಾ. ಉಚಿತ ಆರೋಗ್ಯ ತಪಾಸಣೆ ಶಿಬಿರ...",
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
