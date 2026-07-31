#!/usr/bin/env python3
"""Localization for the customer-side doctor booking flow.

Covers the new screens/widgets built from
`docs/DOCTOR_FRONTEND_AUDIT_AND_FIX_GUIDE.md` §3:
  * `me/doctor/widget/doctor_appointment_sheet.dart`   (booking sheet)
  * `me/doctor/view/doctor_my_appointments_screen.dart` (customer inbox)
  * the second CTA on the doctor public profile
  * the DOCTOR branch of the healthcare enquiry chat card

  * NEW      — sheet field labels, validation copy, the fee notice, the
               customer inbox and its cancel confirmation.
  * BACKFILL — `bookAppointment` (shipped in gu/mr/kn only) and
               `optionalLabel` (en only). Both are read by the new sheet.

Reused as-is: `inquiry`, `cancel`, `noteLabel`, `photoLabel`, `from`,
`toLabel`, `doctorSelectDate`, `doctorPatient`, `doctorConsultationFee`,
`doctorStatus*`, `doctorNoAppointments`, `retry`, `somethingWentWrong`.

Run:  python3 scripts/doctor_booking_localization.py
Then: bash scripts/doctor_booking_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "doctor_booking_lang_payloads")

T = {
    "en": {
        "doctorAppointmentTitle": "Doctor Appointment",
        "doctorAppointmentDate": "Appointment Date",
        "doctorPreferredTime": "Preferred Time",
        "doctorPatientNameLabel": "Patient Name",
        "doctorPatientNameHint": "Who is the appointment for?",
        "doctorPickDate": "Pick a date",
        "doctorPickDateError": "Please pick an appointment date",
        "doctorEndTimeError": "End time must be after start time",
        "doctorFeeNoticeFmt": "You will be charged @fee at the clinic",
        "doctorMyAppointments": "My Appointments",
        "doctorNoMyAppointments": "You haven't booked any appointments yet",
        "doctorCancelAppointment": "Cancel Appointment",
        "doctorCancelConfirmTitle": "Cancel this appointment?",
        "doctorCancelConfirmBody":
            "The doctor will be notified that you cancelled.",
        "doctorKeepIt": "Keep it",
        "requiredLabel": "required",
        # --- backfill ---
        "bookAppointment": "Book Appointment",
        "optionalLabel": "optional",
    },
    "hi": {
        "doctorAppointmentTitle": "डॉक्टर अपॉइंटमेंट",
        "doctorAppointmentDate": "अपॉइंटमेंट की तिथि",
        "doctorPreferredTime": "पसंदीदा समय",
        "doctorPatientNameLabel": "मरीज़ का नाम",
        "doctorPatientNameHint": "अपॉइंटमेंट किसके लिए है?",
        "doctorPickDate": "तिथि चुनें",
        "doctorPickDateError": "कृपया अपॉइंटमेंट की तिथि चुनें",
        "doctorEndTimeError": "समाप्ति समय प्रारंभ समय के बाद होना चाहिए",
        "doctorFeeNoticeFmt": "क्लिनिक पर आपसे @fee लिया जाएगा",
        "doctorMyAppointments": "मेरे अपॉइंटमेंट",
        "doctorNoMyAppointments": "आपने अभी तक कोई अपॉइंटमेंट बुक नहीं किया",
        "doctorCancelAppointment": "अपॉइंटमेंट रद्द करें",
        "doctorCancelConfirmTitle": "यह अपॉइंटमेंट रद्द करें?",
        "doctorCancelConfirmBody":
            "डॉक्टर को सूचित किया जाएगा कि आपने रद्द कर दिया।",
        "doctorKeepIt": "रहने दें",
        "requiredLabel": "आवश्यक",
        "bookAppointment": "अपॉइंटमेंट बुक करें",
        "optionalLabel": "वैकल्पिक",
    },
    "gu": {
        "doctorAppointmentTitle": "ડૉક્ટર એપોઇન્ટમેન્ટ",
        "doctorAppointmentDate": "એપોઇન્ટમેન્ટ તારીખ",
        "doctorPreferredTime": "પસંદગીનો સમય",
        "doctorPatientNameLabel": "દર્દીનું નામ",
        "doctorPatientNameHint": "એપોઇન્ટમેન્ટ કોના માટે છે?",
        "doctorPickDate": "તારીખ પસંદ કરો",
        "doctorPickDateError": "કૃપા કરીને એપોઇન્ટમેન્ટની તારીખ પસંદ કરો",
        "doctorEndTimeError": "સમાપ્તિ સમય શરૂઆતના સમય પછી હોવો જોઈએ",
        "doctorFeeNoticeFmt": "ક્લિનિક પર તમારી પાસેથી @fee લેવામાં આવશે",
        "doctorMyAppointments": "મારી એપોઇન્ટમેન્ટ",
        "doctorNoMyAppointments":
            "તમે હજી સુધી કોઈ એપોઇન્ટમેન્ટ બુક કરી નથી",
        "doctorCancelAppointment": "એપોઇન્ટમેન્ટ રદ કરો",
        "doctorCancelConfirmTitle": "આ એપોઇન્ટમેન્ટ રદ કરવી છે?",
        "doctorCancelConfirmBody":
            "ડૉક્ટરને જાણ કરવામાં આવશે કે તમે રદ કરી છે.",
        "doctorKeepIt": "રહેવા દો",
        "requiredLabel": "જરૂરી",
        "bookAppointment": "અપોઇન્ટમેન્ટ બુક કરો",
        "optionalLabel": "વૈકલ્પિક",
    },
    "mr": {
        "doctorAppointmentTitle": "डॉक्टर अपॉइंटमेंट",
        "doctorAppointmentDate": "अपॉइंटमेंट तारीख",
        "doctorPreferredTime": "पसंतीची वेळ",
        "doctorPatientNameLabel": "रुग्णाचे नाव",
        "doctorPatientNameHint": "अपॉइंटमेंट कोणासाठी आहे?",
        "doctorPickDate": "तारीख निवडा",
        "doctorPickDateError": "कृपया अपॉइंटमेंटची तारीख निवडा",
        "doctorEndTimeError": "समाप्तीची वेळ सुरुवातीच्या वेळेनंतर असावी",
        "doctorFeeNoticeFmt": "क्लिनिकमध्ये तुमच्याकडून @fee आकारले जाईल",
        "doctorMyAppointments": "माझ्या अपॉइंटमेंट",
        "doctorNoMyAppointments":
            "तुम्ही अद्याप कोणतीही अपॉइंटमेंट बुक केलेली नाही",
        "doctorCancelAppointment": "अपॉइंटमेंट रद्द करा",
        "doctorCancelConfirmTitle": "ही अपॉइंटमेंट रद्द करायची?",
        "doctorCancelConfirmBody":
            "तुम्ही रद्द केल्याचे डॉक्टरांना कळवले जाईल.",
        "doctorKeepIt": "राहू द्या",
        "requiredLabel": "आवश्यक",
        "bookAppointment": "अपॉइंटमेंट बुक करा",
        "optionalLabel": "पर्यायी",
    },
    "kn": {
        "doctorAppointmentTitle": "ವೈದ್ಯರ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್",
        "doctorAppointmentDate": "ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ದಿನಾಂಕ",
        "doctorPreferredTime": "ಆದ್ಯತೆಯ ಸಮಯ",
        "doctorPatientNameLabel": "ರೋಗಿಯ ಹೆಸರು",
        "doctorPatientNameHint": "ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಯಾರಿಗಾಗಿ?",
        "doctorPickDate": "ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ",
        "doctorPickDateError": "ದಯವಿಟ್ಟು ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ",
        "doctorEndTimeError": "ಮುಕ್ತಾಯ ಸಮಯ ಪ್ರಾರಂಭದ ಸಮಯದ ನಂತರ ಇರಬೇಕು",
        "doctorFeeNoticeFmt": "ಕ್ಲಿನಿಕ್‌ನಲ್ಲಿ ನಿಮಗೆ @fee ಶುಲ್ಕ ವಿಧಿಸಲಾಗುತ್ತದೆ",
        "doctorMyAppointments": "ನನ್ನ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್‌ಗಳು",
        "doctorNoMyAppointments":
            "ನೀವು ಇನ್ನೂ ಯಾವುದೇ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಬುಕ್ ಮಾಡಿಲ್ಲ",
        "doctorCancelAppointment": "ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ರದ್ದುಮಾಡಿ",
        "doctorCancelConfirmTitle": "ಈ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ರದ್ದುಮಾಡುವುದೇ?",
        "doctorCancelConfirmBody":
            "ನೀವು ರದ್ದುಗೊಳಿಸಿದ್ದೀರಿ ಎಂದು ವೈದ್ಯರಿಗೆ ತಿಳಿಸಲಾಗುತ್ತದೆ.",
        "doctorKeepIt": "ಇರಲಿ",
        "requiredLabel": "ಅಗತ್ಯ",
        "bookAppointment": "ಎಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಬುಕ್ ಮಾಡಿ",
        "optionalLabel": "ಐಚ್ಛಿಕ",
    },
}

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
