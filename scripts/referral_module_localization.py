#!/usr/bin/env python3
"""Localization for the whole referral module — screens, tabs and widgets.

Covers `lib/features/common/referral/`:
  view/         referral_page, referral_history_screen, all_testimonials_screen
  view/tabs/    overview_tab, tutorial_tab, creator_tab, statics_tab
  widgets/      my_code_header, post_empty_state, referral_share_card,
                admin_post_card, add_link_bottom_sheet, testimonials_section

Two groups:

NEW      — keys added for copy that had no catalogue entry anywhere.
BACKFILL — keys that already shipped in en (+ sometimes hi) but were
           missing in gu/mr/kn, so those users saw English. Several are
           shared with other modules, so the backfill fixes them too:
           `history`, `withdraw`, `balance`, `totalEarn`, `estdEarning`,
           `joiningBonus`, `bonusLabel`, `filterLabel`, `labelName`,
           `professionLabel`, `noTestimonialsYet`, `export`, `applyLabel`,
           `copiedLabel`.

`myCode` is a special case: the Dart constant existed but had NO catalogue
entry in any language, so the referral app bar rendered the raw key. Added
for all five here.

Deliberately NOT translated — proper nouns and API identifiers:
  * "BlueEra", "Google Play", "App Store", "YouTube", "Instagram",
    "Facebook", "X / Twitter", "INSTAGRAM" (brand names)
  * `ReferralController.filters` values ('All', 'Pending', 'Subscribe',
    'Un-Subscribe', 'Expired') — they drive the query-param switch in
    `fetchHistory`; only their rendered labels are localized, via
    `_filterLabelKey`.

Run:  python3 scripts/referral_module_localization.py
Then: bash scripts/referral_module_lang_payloads/curl_commands.sh
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "referral_module_lang_payloads")

# Keys that already exist in en (and usually hi) — only the missing
# languages get an entry, so we never overwrite shipped en/hi copy.
BACKFILL_ONLY = {
    "history", "withdraw", "balance", "totalEarn", "estdEarning",
    "joiningBonus", "bonusLabel", "filterLabel", "labelName",
    "professionLabel", "noTestimonialsYet", "export", "applyLabel",
    "copiedLabel",
}

T = {
    "en": {
        "myCode": "My code",
        "allTestimonials": "All Testimonials",
        "noTestimonialsSubtitle":
            "Check back later — new stories from BlueEra land here.",
        "noReferralsInDateRange": "No referrals in the selected date range.",
        "noFilterResultsFmt": "No @filter found.",
        "filterByDate": "Filter by date",
        "dateFilterOn": "Date filter on",
        "dateFilterOptions": "Date filter options",
        "dateFilterRemoved": "Date filter removed",
        "dateFilterCleared": "Date filter cleared",
        "changeDateRange": "Change date range",
        "removeFilter": "Remove filter",
        "filterByDateRange": "Filter by date range",
        "dateFilter": "Date filter",
        "tapToChangeLabel": "Tap to change",
        "nothingToExport": "Nothing to export.",
        "exportReferralHistory": "Export referral history",
        "saveToDevice": "Save to device",
        "saveToDeviceSubtitle": "Store the PDF in your app files",
        "sharePdf": "Share PDF",
        "sharePdfSubtitle": "Send via WhatsApp, Email, etc.",
        "savedToFmt": "Saved to @path",
        "exportFailedFmt": "Export failed: @error",
        "referralHistory": "Referral History",
        "allDates": "All dates",
        "pdfFilterFmt": "Filter: @filter",
        "pdfRangeFmt": "Range: @range",
        "statusLabel": "Status",
        "earnedLabel": "Earned",
        "planLabel": "Plan",
        "statusSubscribed": "Subscribed",
        "statusUnsubscribed": "Un-subscribed",
        "statusExpired": "Expired",
        "pendingUser": "Pending User",
        "subscribeUser": "Subscribe User",
        "unSubscribeUser": "Un-Subscribe User",
        "referredUsersFmt": "Referred users (@count)",
        "noReferredUsersYet": "No referred users yet.",
        "referredCountFmt": "@count referred",
        "filterAll": "All",
        "filterSubscribe": "Subscribe",
        "filterUnSubscribe": "Un-Subscribe",
        "subscriptionOutOfReferralFmt":
            "@subscribed Subscription Out of @total Referral",
        "noOverviewPostsYet": "No overview posts yet.",
        "noTutorialsYet": "No tutorials yet.",
        "welcomeContentCreator": "Welcome Content Creator",
        "yayYouWon": "Yay! You've won",
        "creditedToWalletNote":
            "This will be credited to your wallet. You can use it at the "
            "time of order payment.",
        "byClickingYouAccept": "By Clicking You Accept the",
        "joinNow": "Join Now",
        "creatorProgram": "Creator Program",
        "creatorEarnPerVideoFmt":
            "Earn @amount per approved video, up to @total.",
        "addYourVideo": "Add Your Video",
        "addYourLinks": "Add Your Links",
        "myVideos": "My Videos",
        "noVideosYet": "No videos yet — add your first link above.",
        "creditedAmountFmt": "Credited @amount",
        "myStatics": "My Statics",
        "directReferralIncome": "Direct Referral Income",
        "orderIncome": "Order Income",
        "contentCreationIncome": "Content Creation Income",
        "totalBonus": "Total Bonus",
        "daysLabel": "Days",
        "workHours": "Work Hours",
        "assignTask": "Assign Task",
        "hrsUnit": "hrs.",
        "tasksUnit": "Tasks",
        "totalAmountLabel": "Total Amount",
        "referralOrder": "Referral Order",
        "totalIncomeLabel": "Total Income",
        "totalVideo": "Total Video",
        "viewCount": "View Count",
        "balanceDashFmt": "Balance - @amount",
        "referralCodeCopiedToClipboard": "Referral code copied to clipboard",
        "copyCode": "Copy code",
        "shareCode": "Share code",
        "noVideosYetTitle": "No videos yet",
        "addYourLinksHint":
            "Tap \"Add Your Links\" above to add your first one.",
        "referAndEarnCaps": "REFER & EARN",
        "yourReferralCodeCaps": "YOUR REFERRAL CODE",
        "applyAtSignupRewarded": "Apply at sign-up & get rewarded",
        "downloadBlueEraEnterCode":
            "Download BlueEra & enter this code at sign-up",
        "previewNotAvailable": "Preview not available",
        "instagramLink": "Instagram link",
        "instagramPreviewLimitSaved":
            "Instagram limits link previews, so the thumbnail and caption "
            "couldn’t be loaded. Your link is saved and opens in the "
            "Instagram app.",
        "openInInstagram": "Open in Instagram",
        "pickAPlatform": "PICK A PLATFORM",
        "pasteYourUrl": "PASTE YOUR URL",
        "addAVideoLink": "Add a video link",
        "bringYourReels": "Bring your reels in from anywhere.",
        "pasteYourLinkHere": "Paste your link here",
        "platformMismatchFmt":
            "You picked @picked, but this looks like a @detected link. "
            "Switch the platform above or paste a @picked URL.",
        "unsupportedLinkPlatform":
            "We can only add Instagram, X / Twitter, Facebook or YouTube "
            "links right now.",
        "willBeSavedAs": "Will be saved as",
        "instagramPreviewLimitWillSave":
            "Instagram limits link previews, so the thumbnail and caption "
            "may not load. Your link will still be saved and will open in "
            "Instagram.",
    },
    "hi": {
        "myCode": "मेरा कोड",
        "allTestimonials": "सभी प्रशंसापत्र",
        "noTestimonialsSubtitle":
            "बाद में देखें — BlueEra की नई कहानियाँ यहाँ आएँगी।",
        "noReferralsInDateRange": "चुनी गई तिथि सीमा में कोई रेफरल नहीं।",
        "noFilterResultsFmt": "कोई @filter नहीं मिला।",
        "filterByDate": "तिथि से फ़िल्टर करें",
        "dateFilterOn": "तिथि फ़िल्टर चालू",
        "dateFilterOptions": "तिथि फ़िल्टर विकल्प",
        "dateFilterRemoved": "तिथि फ़िल्टर हटाया गया",
        "dateFilterCleared": "तिथि फ़िल्टर साफ़ किया गया",
        "changeDateRange": "तिथि सीमा बदलें",
        "removeFilter": "फ़िल्टर हटाएँ",
        "filterByDateRange": "तिथि सीमा से फ़िल्टर करें",
        "dateFilter": "तिथि फ़िल्टर",
        "tapToChangeLabel": "बदलने के लिए टैप करें",
        "nothingToExport": "निर्यात करने के लिए कुछ नहीं।",
        "exportReferralHistory": "रेफरल इतिहास निर्यात करें",
        "saveToDevice": "डिवाइस में सहेजें",
        "saveToDeviceSubtitle": "PDF को अपनी ऐप फ़ाइलों में सहेजें",
        "sharePdf": "PDF साझा करें",
        "sharePdfSubtitle": "WhatsApp, Email आदि से भेजें",
        "savedToFmt": "@path पर सहेजा गया",
        "exportFailedFmt": "निर्यात विफल: @error",
        "referralHistory": "रेफरल इतिहास",
        "allDates": "सभी तिथियाँ",
        "pdfFilterFmt": "फ़िल्टर: @filter",
        "pdfRangeFmt": "सीमा: @range",
        "statusLabel": "स्थिति",
        "earnedLabel": "अर्जित",
        "planLabel": "प्लान",
        "statusSubscribed": "सब्सक्राइब्ड",
        "statusUnsubscribed": "अनसब्सक्राइब्ड",
        "statusExpired": "समाप्त",
        "pendingUser": "लंबित उपयोगकर्ता",
        "subscribeUser": "सब्सक्राइब उपयोगकर्ता",
        "unSubscribeUser": "अनसब्सक्राइब उपयोगकर्ता",
        "referredUsersFmt": "रेफर किए गए उपयोगकर्ता (@count)",
        "noReferredUsersYet": "अभी तक कोई रेफर किया गया उपयोगकर्ता नहीं।",
        "referredCountFmt": "@count रेफर किए",
        "filterAll": "सभी",
        "filterSubscribe": "सब्सक्राइब",
        "filterUnSubscribe": "अनसब्सक्राइब",
        "subscriptionOutOfReferralFmt":
            "@total रेफरल में से @subscribed सब्सक्रिप्शन",
        "noOverviewPostsYet": "अभी तक कोई अवलोकन पोस्ट नहीं।",
        "noTutorialsYet": "अभी तक कोई ट्यूटोरियल नहीं।",
        "welcomeContentCreator": "कॉन्टेंट क्रिएटर का स्वागत है",
        "yayYouWon": "वाह! आपने जीता",
        "creditedToWalletNote":
            "यह आपके वॉलेट में जमा किया जाएगा। आप इसे ऑर्डर भुगतान के समय "
            "उपयोग कर सकते हैं।",
        "byClickingYouAccept": "क्लिक करके आप स्वीकार करते हैं",
        "joinNow": "अभी जुड़ें",
        "creatorProgram": "क्रिएटर प्रोग्राम",
        "creatorEarnPerVideoFmt":
            "प्रति स्वीकृत वीडियो @amount कमाएँ, @total तक।",
        "addYourVideo": "अपना वीडियो जोड़ें",
        "addYourLinks": "अपने लिंक जोड़ें",
        "myVideos": "मेरे वीडियो",
        "noVideosYet": "अभी तक कोई वीडियो नहीं — ऊपर अपना पहला लिंक जोड़ें।",
        "creditedAmountFmt": "@amount जमा किया गया",
        "myStatics": "मेरे आँकड़े",
        "directReferralIncome": "प्रत्यक्ष रेफरल आय",
        "orderIncome": "ऑर्डर आय",
        "contentCreationIncome": "कॉन्टेंट क्रिएशन आय",
        "totalBonus": "कुल बोनस",
        "daysLabel": "दिन",
        "workHours": "कार्य घंटे",
        "assignTask": "सौंपे गए कार्य",
        "hrsUnit": "घंटे",
        "tasksUnit": "कार्य",
        "totalAmountLabel": "कुल राशि",
        "referralOrder": "रेफरल ऑर्डर",
        "totalIncomeLabel": "कुल आय",
        "totalVideo": "कुल वीडियो",
        "viewCount": "व्यू संख्या",
        "balanceDashFmt": "बैलेंस - @amount",
        "referralCodeCopiedToClipboard":
            "रेफरल कोड क्लिपबोर्ड पर कॉपी हो गया",
        "copyCode": "कोड कॉपी करें",
        "shareCode": "कोड साझा करें",
        "noVideosYetTitle": "अभी तक कोई वीडियो नहीं",
        "addYourLinksHint":
            "अपना पहला लिंक जोड़ने के लिए ऊपर \"अपने लिंक जोड़ें\" पर टैप करें।",
        "referAndEarnCaps": "रेफर करें और कमाएँ",
        "yourReferralCodeCaps": "आपका रेफरल कोड",
        "applyAtSignupRewarded": "साइन-अप पर लगाएँ और इनाम पाएँ",
        "downloadBlueEraEnterCode":
            "BlueEra डाउनलोड करें और साइन-अप पर यह कोड डालें",
        "previewNotAvailable": "पूर्वावलोकन उपलब्ध नहीं",
        "instagramLink": "Instagram लिंक",
        "instagramPreviewLimitSaved":
            "Instagram लिंक पूर्वावलोकन सीमित करता है, इसलिए थंबनेल और "
            "कैप्शन लोड नहीं हो सके। आपका लिंक सहेजा गया है और Instagram "
            "ऐप में खुलेगा।",
        "openInInstagram": "Instagram में खोलें",
        "pickAPlatform": "प्लेटफ़ॉर्म चुनें",
        "pasteYourUrl": "अपना URL पेस्ट करें",
        "addAVideoLink": "वीडियो लिंक जोड़ें",
        "bringYourReels": "कहीं से भी अपनी रील्स लाएँ।",
        "pasteYourLinkHere": "अपना लिंक यहाँ पेस्ट करें",
        "platformMismatchFmt":
            "आपने @picked चुना, लेकिन यह @detected लिंक लगता है। ऊपर "
            "प्लेटफ़ॉर्म बदलें या @picked URL पेस्ट करें।",
        "unsupportedLinkPlatform":
            "हम अभी केवल Instagram, X / Twitter, Facebook या YouTube लिंक "
            "जोड़ सकते हैं।",
        "willBeSavedAs": "इस रूप में सहेजा जाएगा",
        "instagramPreviewLimitWillSave":
            "Instagram लिंक पूर्वावलोकन सीमित करता है, इसलिए थंबनेल और "
            "कैप्शन लोड नहीं हो सकते। आपका लिंक फिर भी सहेजा जाएगा और "
            "Instagram में खुलेगा।",
        # backfill
        "noTestimonialsYet": "अभी तक कोई प्रशंसापत्र नहीं",
    },
    "gu": {
        "myCode": "મારો કોડ",
        "allTestimonials": "બધા પ્રશંસાપત્રો",
        "noTestimonialsSubtitle":
            "પછી તપાસો — BlueEra ની નવી વાર્તાઓ અહીં આવશે.",
        "noReferralsInDateRange": "પસંદ કરેલી તારીખ શ્રેણીમાં કોઈ રેફરલ નથી.",
        "noFilterResultsFmt": "કોઈ @filter મળ્યું નથી.",
        "filterByDate": "તારીખ પ્રમાણે ફિલ્ટર કરો",
        "dateFilterOn": "તારીખ ફિલ્ટર ચાલુ",
        "dateFilterOptions": "તારીખ ફિલ્ટર વિકલ્પો",
        "dateFilterRemoved": "તારીખ ફિલ્ટર દૂર કર્યું",
        "dateFilterCleared": "તારીખ ફિલ્ટર સાફ કર્યું",
        "changeDateRange": "તારીખ શ્રેણી બદલો",
        "removeFilter": "ફિલ્ટર દૂર કરો",
        "filterByDateRange": "તારીખ શ્રેણી પ્રમાણે ફિલ્ટર કરો",
        "dateFilter": "તારીખ ફિલ્ટર",
        "tapToChangeLabel": "બદલવા માટે ટૅપ કરો",
        "nothingToExport": "નિકાસ કરવા માટે કંઈ નથી.",
        "exportReferralHistory": "રેફરલ ઇતિહાસ નિકાસ કરો",
        "saveToDevice": "ડિવાઇસમાં સેવ કરો",
        "saveToDeviceSubtitle": "PDF ને તમારી ઍપ ફાઇલોમાં સ્ટોર કરો",
        "sharePdf": "PDF શેર કરો",
        "sharePdfSubtitle": "WhatsApp, Email વગેરે દ્વારા મોકલો",
        "savedToFmt": "@path પર સેવ થયું",
        "exportFailedFmt": "નિકાસ નિષ્ફળ: @error",
        "referralHistory": "રેફરલ ઇતિહાસ",
        "allDates": "બધી તારીખો",
        "pdfFilterFmt": "ફિલ્ટર: @filter",
        "pdfRangeFmt": "શ્રેણી: @range",
        "statusLabel": "સ્થિતિ",
        "earnedLabel": "કમાયેલ",
        "planLabel": "પ્લાન",
        "statusSubscribed": "સબ્સ્ક્રાઇબ્ડ",
        "statusUnsubscribed": "અનસબ્સ્ક્રાઇબ્ડ",
        "statusExpired": "સમાપ્ત",
        "pendingUser": "બાકી વપરાશકર્તા",
        "subscribeUser": "સબ્સ્ક્રાઇબ વપરાશકર્તા",
        "unSubscribeUser": "અનસબ્સ્ક્રાઇબ વપરાશકર્તા",
        "referredUsersFmt": "રેફર કરેલા વપરાશકર્તાઓ (@count)",
        "noReferredUsersYet": "હજી સુધી કોઈ રેફર કરેલ વપરાશકર્તા નથી.",
        "referredCountFmt": "@count રેફર કર્યા",
        "filterAll": "બધા",
        "filterSubscribe": "સબ્સ્ક્રાઇબ",
        "filterUnSubscribe": "અનસબ્સ્ક્રાઇબ",
        "subscriptionOutOfReferralFmt":
            "@total રેફરલમાંથી @subscribed સબ્સ્ક્રિપ્શન",
        "noOverviewPostsYet": "હજી સુધી કોઈ ઝાંખી પોસ્ટ નથી.",
        "noTutorialsYet": "હજી સુધી કોઈ ટ્યુટોરિયલ નથી.",
        "welcomeContentCreator": "કોન્ટેન્ટ ક્રિએટરનું સ્વાગત છે",
        "yayYouWon": "વાહ! તમે જીત્યા",
        "creditedToWalletNote":
            "આ તમારા વૉલેટમાં જમા થશે. તમે તેનો ઉપયોગ ઓર્ડર ચુકવણી સમયે "
            "કરી શકો છો.",
        "byClickingYouAccept": "ક્લિક કરીને તમે સ્વીકારો છો",
        "joinNow": "હમણાં જોડાઓ",
        "creatorProgram": "ક્રિએટર પ્રોગ્રામ",
        "creatorEarnPerVideoFmt":
            "દરેક મંજૂર વિડિયો દીઠ @amount કમાઓ, @total સુધી.",
        "addYourVideo": "તમારો વિડિયો ઉમેરો",
        "addYourLinks": "તમારી લિંક ઉમેરો",
        "myVideos": "મારા વિડિયો",
        "noVideosYet":
            "હજી સુધી કોઈ વિડિયો નથી — ઉપર તમારી પહેલી લિંક ઉમેરો.",
        "creditedAmountFmt": "@amount જમા થયું",
        "myStatics": "મારા આંકડા",
        "directReferralIncome": "સીધી રેફરલ આવક",
        "orderIncome": "ઓર્ડર આવક",
        "contentCreationIncome": "કોન્ટેન્ટ ક્રિએશન આવક",
        "totalBonus": "કુલ બોનસ",
        "daysLabel": "દિવસ",
        "workHours": "કામના કલાકો",
        "assignTask": "સોંપેલ કાર્ય",
        "hrsUnit": "કલાક",
        "tasksUnit": "કાર્યો",
        "totalAmountLabel": "કુલ રકમ",
        "referralOrder": "રેફરલ ઓર્ડર",
        "totalIncomeLabel": "કુલ આવક",
        "totalVideo": "કુલ વિડિયો",
        "viewCount": "વ્યૂ સંખ્યા",
        "balanceDashFmt": "બેલેન્સ - @amount",
        "referralCodeCopiedToClipboard":
            "રેફરલ કોડ ક્લિપબોર્ડ પર કૉપિ થયો",
        "copyCode": "કોડ કૉપિ કરો",
        "shareCode": "કોડ શેર કરો",
        "noVideosYetTitle": "હજી સુધી કોઈ વિડિયો નથી",
        "addYourLinksHint":
            "તમારી પહેલી લિંક ઉમેરવા ઉપર \"તમારી લિંક ઉમેરો\" પર ટૅપ કરો.",
        "referAndEarnCaps": "રેફર કરો અને કમાઓ",
        "yourReferralCodeCaps": "તમારો રેફરલ કોડ",
        "applyAtSignupRewarded": "સાઇન-અપ પર લાગુ કરો અને ઇનામ મેળવો",
        "downloadBlueEraEnterCode":
            "BlueEra ડાઉનલોડ કરો અને સાઇન-અપ પર આ કોડ દાખલ કરો",
        "previewNotAvailable": "પૂર્વાવલોકન ઉપલબ્ધ નથી",
        "instagramLink": "Instagram લિંક",
        "instagramPreviewLimitSaved":
            "Instagram લિંક પૂર્વાવલોકન મર્યાદિત કરે છે, તેથી થંબનેલ અને "
            "કૅપ્શન લોડ થઈ શક્યા નથી. તમારી લિંક સેવ થઈ છે અને Instagram "
            "ઍપમાં ખૂલશે.",
        "openInInstagram": "Instagram માં ખોલો",
        "pickAPlatform": "પ્લેટફોર્મ પસંદ કરો",
        "pasteYourUrl": "તમારું URL પેસ્ટ કરો",
        "addAVideoLink": "વિડિયો લિંક ઉમેરો",
        "bringYourReels": "ગમે ત્યાંથી તમારી રીલ્સ લાવો.",
        "pasteYourLinkHere": "તમારી લિંક અહીં પેસ્ટ કરો",
        "platformMismatchFmt":
            "તમે @picked પસંદ કર્યું, પણ આ @detected લિંક લાગે છે. ઉપર "
            "પ્લેટફોર્મ બદલો અથવા @picked URL પેસ્ટ કરો.",
        "unsupportedLinkPlatform":
            "અમે અત્યારે ફક્ત Instagram, X / Twitter, Facebook અથવા "
            "YouTube લિંક ઉમેરી શકીએ છીએ.",
        "willBeSavedAs": "આ રીતે સેવ થશે",
        "instagramPreviewLimitWillSave":
            "Instagram લિંક પૂર્વાવલોકન મર્યાદિત કરે છે, તેથી થંબનેલ અને "
            "કૅપ્શન લોડ ન પણ થાય. તમારી લિંક તો પણ સેવ થશે અને Instagram "
            "માં ખૂલશે.",
        # backfill
        "noTestimonialsYet": "હજી સુધી કોઈ પ્રશંસાપત્ર નથી",
        "history": "ઇતિહાસ",
        "withdraw": "ઉપાડો",
        "balance": "બેલેન્સ",
        "totalEarn": "કુલ કમાણી",
        "estdEarning": "અંદાજિત કમાણી",
        "joiningBonus": "જોડાવાનું બોનસ",
        "bonusLabel": "બોનસ",
        "filterLabel": "ફિલ્ટર",
        "labelName": "નામ",
        "professionLabel": "વ્યવસાય",
        "export": "નિકાસ",
        "applyLabel": "લાગુ કરો",
        "copiedLabel": "કૉપિ થયું",
    },
    "mr": {
        "myCode": "माझा कोड",
        "allTestimonials": "सर्व प्रशंसापत्रे",
        "noTestimonialsSubtitle":
            "नंतर तपासा — BlueEra च्या नवीन कथा इथे येतील.",
        "noReferralsInDateRange": "निवडलेल्या तारीख श्रेणीत कोणतेही रेफरल नाही.",
        "noFilterResultsFmt": "कोणतेही @filter सापडले नाही.",
        "filterByDate": "तारखेनुसार फिल्टर करा",
        "dateFilterOn": "तारीख फिल्टर चालू",
        "dateFilterOptions": "तारीख फिल्टर पर्याय",
        "dateFilterRemoved": "तारीख फिल्टर काढले",
        "dateFilterCleared": "तारीख फिल्टर साफ केले",
        "changeDateRange": "तारीख श्रेणी बदला",
        "removeFilter": "फिल्टर काढा",
        "filterByDateRange": "तारीख श्रेणीनुसार फिल्टर करा",
        "dateFilter": "तारीख फिल्टर",
        "tapToChangeLabel": "बदलण्यासाठी टॅप करा",
        "nothingToExport": "निर्यात करण्यासाठी काहीही नाही.",
        "exportReferralHistory": "रेफरल इतिहास निर्यात करा",
        "saveToDevice": "डिव्हाइसवर सेव्ह करा",
        "saveToDeviceSubtitle": "PDF तुमच्या ॲप फाइल्समध्ये साठवा",
        "sharePdf": "PDF शेअर करा",
        "sharePdfSubtitle": "WhatsApp, Email इत्यादीद्वारे पाठवा",
        "savedToFmt": "@path वर सेव्ह केले",
        "exportFailedFmt": "निर्यात अयशस्वी: @error",
        "referralHistory": "रेफरल इतिहास",
        "allDates": "सर्व तारखा",
        "pdfFilterFmt": "फिल्टर: @filter",
        "pdfRangeFmt": "श्रेणी: @range",
        "statusLabel": "स्थिती",
        "earnedLabel": "कमावले",
        "planLabel": "प्लॅन",
        "statusSubscribed": "सबस्क्राइब्ड",
        "statusUnsubscribed": "अनसबस्क्राइब्ड",
        "statusExpired": "कालबाह्य",
        "pendingUser": "प्रलंबित वापरकर्ता",
        "subscribeUser": "सबस्क्राइब वापरकर्ता",
        "unSubscribeUser": "अनसबस्क्राइब वापरकर्ता",
        "referredUsersFmt": "रेफर केलेले वापरकर्ते (@count)",
        "noReferredUsersYet": "अद्याप कोणताही रेफर केलेला वापरकर्ता नाही.",
        "referredCountFmt": "@count रेफर केले",
        "filterAll": "सर्व",
        "filterSubscribe": "सबस्क्राइब",
        "filterUnSubscribe": "अनसबस्क्राइब",
        "subscriptionOutOfReferralFmt":
            "@total रेफरलपैकी @subscribed सबस्क्रिप्शन",
        "noOverviewPostsYet": "अद्याप कोणतीही आढावा पोस्ट नाही.",
        "noTutorialsYet": "अद्याप कोणतेही ट्यूटोरियल नाही.",
        "welcomeContentCreator": "कंटेंट क्रिएटरचे स्वागत आहे",
        "yayYouWon": "व्वा! तुम्ही जिंकलात",
        "creditedToWalletNote":
            "हे तुमच्या वॉलेटमध्ये जमा होईल. तुम्ही ते ऑर्डर पेमेंटच्या "
            "वेळी वापरू शकता.",
        "byClickingYouAccept": "क्लिक करून तुम्ही स्वीकारता",
        "joinNow": "आता सामील व्हा",
        "creatorProgram": "क्रिएटर प्रोग्राम",
        "creatorEarnPerVideoFmt":
            "प्रत्येक मंजूर व्हिडिओमागे @amount कमवा, @total पर्यंत.",
        "addYourVideo": "तुमचा व्हिडिओ जोडा",
        "addYourLinks": "तुमच्या लिंक जोडा",
        "myVideos": "माझे व्हिडिओ",
        "noVideosYet":
            "अद्याप कोणताही व्हिडिओ नाही — वर तुमची पहिली लिंक जोडा.",
        "creditedAmountFmt": "@amount जमा केले",
        "myStatics": "माझी आकडेवारी",
        "directReferralIncome": "थेट रेफरल उत्पन्न",
        "orderIncome": "ऑर्डर उत्पन्न",
        "contentCreationIncome": "कंटेंट क्रिएशन उत्पन्न",
        "totalBonus": "एकूण बोनस",
        "daysLabel": "दिवस",
        "workHours": "कामाचे तास",
        "assignTask": "नेमून दिलेली कामे",
        "hrsUnit": "तास",
        "tasksUnit": "कामे",
        "totalAmountLabel": "एकूण रक्कम",
        "referralOrder": "रेफरल ऑर्डर",
        "totalIncomeLabel": "एकूण उत्पन्न",
        "totalVideo": "एकूण व्हिडिओ",
        "viewCount": "व्ह्यू संख्या",
        "balanceDashFmt": "शिल्लक - @amount",
        "referralCodeCopiedToClipboard":
            "रेफरल कोड क्लिपबोर्डवर कॉपी झाला",
        "copyCode": "कोड कॉपी करा",
        "shareCode": "कोड शेअर करा",
        "noVideosYetTitle": "अद्याप कोणताही व्हिडिओ नाही",
        "addYourLinksHint":
            "तुमची पहिली लिंक जोडण्यासाठी वर \"तुमच्या लिंक जोडा\" वर टॅप करा.",
        "referAndEarnCaps": "रेफर करा आणि कमवा",
        "yourReferralCodeCaps": "तुमचा रेफरल कोड",
        "applyAtSignupRewarded": "साइन-अप वर लागू करा आणि बक्षीस मिळवा",
        "downloadBlueEraEnterCode":
            "BlueEra डाउनलोड करा आणि साइन-अप वर हा कोड टाका",
        "previewNotAvailable": "पूर्वावलोकन उपलब्ध नाही",
        "instagramLink": "Instagram लिंक",
        "instagramPreviewLimitSaved":
            "Instagram लिंक पूर्वावलोकन मर्यादित करते, त्यामुळे थंबनेल आणि "
            "कॅप्शन लोड होऊ शकले नाहीत. तुमची लिंक सेव्ह झाली आहे आणि "
            "Instagram ॲपमध्ये उघडेल.",
        "openInInstagram": "Instagram मध्ये उघडा",
        "pickAPlatform": "प्लॅटफॉर्म निवडा",
        "pasteYourUrl": "तुमचे URL पेस्ट करा",
        "addAVideoLink": "व्हिडिओ लिंक जोडा",
        "bringYourReels": "कुठूनही तुमच्या रील्स आणा.",
        "pasteYourLinkHere": "तुमची लिंक इथे पेस्ट करा",
        "platformMismatchFmt":
            "तुम्ही @picked निवडले, पण ही @detected लिंक दिसते. वर "
            "प्लॅटफॉर्म बदला किंवा @picked URL पेस्ट करा.",
        "unsupportedLinkPlatform":
            "आम्ही सध्या फक्त Instagram, X / Twitter, Facebook किंवा "
            "YouTube लिंक जोडू शकतो.",
        "willBeSavedAs": "असे सेव्ह होईल",
        "instagramPreviewLimitWillSave":
            "Instagram लिंक पूर्वावलोकन मर्यादित करते, त्यामुळे थंबनेल आणि "
            "कॅप्शन लोड होणार नाहीत. तरीही तुमची लिंक सेव्ह होईल आणि "
            "Instagram मध्ये उघडेल.",
        # backfill
        "noTestimonialsYet": "अद्याप कोणतेही प्रशंसापत्र नाही",
        "history": "इतिहास",
        "withdraw": "काढा",
        "balance": "शिल्लक",
        "totalEarn": "एकूण कमाई",
        "estdEarning": "अंदाजित कमाई",
        "joiningBonus": "जॉइनिंग बोनस",
        "bonusLabel": "बोनस",
        "filterLabel": "फिल्टर",
        "labelName": "नाव",
        "professionLabel": "व्यवसाय",
        "export": "निर्यात",
        "applyLabel": "लागू करा",
        "copiedLabel": "कॉपी झाले",
    },
    "kn": {
        "myCode": "ನನ್ನ ಕೋಡ್",
        "allTestimonials": "ಎಲ್ಲಾ ಪ್ರಶಂಸಾಪತ್ರಗಳು",
        "noTestimonialsSubtitle":
            "ನಂತರ ಪರಿಶೀಲಿಸಿ — BlueEra ದ ಹೊಸ ಕಥೆಗಳು ಇಲ್ಲಿ ಬರುತ್ತವೆ.",
        "noReferralsInDateRange":
            "ಆಯ್ಕೆಮಾಡಿದ ದಿನಾಂಕ ವ್ಯಾಪ್ತಿಯಲ್ಲಿ ಯಾವುದೇ ರೆಫರಲ್ ಇಲ್ಲ.",
        "noFilterResultsFmt": "ಯಾವುದೇ @filter ಕಂಡುಬಂದಿಲ್ಲ.",
        "filterByDate": "ದಿನಾಂಕದ ಪ್ರಕಾರ ಫಿಲ್ಟರ್ ಮಾಡಿ",
        "dateFilterOn": "ದಿನಾಂಕ ಫಿಲ್ಟರ್ ಆನ್",
        "dateFilterOptions": "ದಿನಾಂಕ ಫಿಲ್ಟರ್ ಆಯ್ಕೆಗಳು",
        "dateFilterRemoved": "ದಿನಾಂಕ ಫಿಲ್ಟರ್ ತೆಗೆದುಹಾಕಲಾಗಿದೆ",
        "dateFilterCleared": "ದಿನಾಂಕ ಫಿಲ್ಟರ್ ತೆರವುಗೊಳಿಸಲಾಗಿದೆ",
        "changeDateRange": "ದಿನಾಂಕ ವ್ಯಾಪ್ತಿ ಬದಲಾಯಿಸಿ",
        "removeFilter": "ಫಿಲ್ಟರ್ ತೆಗೆದುಹಾಕಿ",
        "filterByDateRange": "ದಿನಾಂಕ ವ್ಯಾಪ್ತಿಯ ಪ್ರಕಾರ ಫಿಲ್ಟರ್ ಮಾಡಿ",
        "dateFilter": "ದಿನಾಂಕ ಫಿಲ್ಟರ್",
        "tapToChangeLabel": "ಬದಲಾಯಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ",
        "nothingToExport": "ರಫ್ತು ಮಾಡಲು ಏನೂ ಇಲ್ಲ.",
        "exportReferralHistory": "ರೆಫರಲ್ ಇತಿಹಾಸ ರಫ್ತು ಮಾಡಿ",
        "saveToDevice": "ಸಾಧನದಲ್ಲಿ ಉಳಿಸಿ",
        "saveToDeviceSubtitle": "PDF ಅನ್ನು ನಿಮ್ಮ ಆ್ಯಪ್ ಫೈಲ್‌ಗಳಲ್ಲಿ ಸಂಗ್ರಹಿಸಿ",
        "sharePdf": "PDF ಹಂಚಿಕೊಳ್ಳಿ",
        "sharePdfSubtitle": "WhatsApp, Email ಇತ್ಯಾದಿ ಮೂಲಕ ಕಳುಹಿಸಿ",
        "savedToFmt": "@path ಗೆ ಉಳಿಸಲಾಗಿದೆ",
        "exportFailedFmt": "ರಫ್ತು ವಿಫಲವಾಗಿದೆ: @error",
        "referralHistory": "ರೆಫರಲ್ ಇತಿಹಾಸ",
        "allDates": "ಎಲ್ಲಾ ದಿನಾಂಕಗಳು",
        "pdfFilterFmt": "ಫಿಲ್ಟರ್: @filter",
        "pdfRangeFmt": "ವ್ಯಾಪ್ತಿ: @range",
        "statusLabel": "ಸ್ಥಿತಿ",
        "earnedLabel": "ಗಳಿಸಿದ",
        "planLabel": "ಪ್ಲಾನ್",
        "statusSubscribed": "ಚಂದಾದಾರರಾಗಿದ್ದಾರೆ",
        "statusUnsubscribed": "ಚಂದಾದಾರಿಕೆ ರದ್ದು",
        "statusExpired": "ಅವಧಿ ಮುಗಿದಿದೆ",
        "pendingUser": "ಬಾಕಿ ಬಳಕೆದಾರ",
        "subscribeUser": "ಚಂದಾದಾರ ಬಳಕೆದಾರ",
        "unSubscribeUser": "ಚಂದಾದಾರಿಕೆ ರದ್ದು ಬಳಕೆದಾರ",
        "referredUsersFmt": "ರೆಫರ್ ಮಾಡಿದ ಬಳಕೆದಾರರು (@count)",
        "noReferredUsersYet": "ಇನ್ನೂ ಯಾವುದೇ ರೆಫರ್ ಮಾಡಿದ ಬಳಕೆದಾರರಿಲ್ಲ.",
        "referredCountFmt": "@count ರೆಫರ್ ಮಾಡಿದ್ದಾರೆ",
        "filterAll": "ಎಲ್ಲಾ",
        "filterSubscribe": "ಚಂದಾದಾರರಾಗಿ",
        "filterUnSubscribe": "ಚಂದಾದಾರಿಕೆ ರದ್ದು",
        "subscriptionOutOfReferralFmt":
            "@total ರೆಫರಲ್‌ಗಳಲ್ಲಿ @subscribed ಚಂದಾದಾರಿಕೆ",
        "noOverviewPostsYet": "ಇನ್ನೂ ಯಾವುದೇ ಅವಲೋಕನ ಪೋಸ್ಟ್ ಇಲ್ಲ.",
        "noTutorialsYet": "ಇನ್ನೂ ಯಾವುದೇ ಟ್ಯುಟೋರಿಯಲ್ ಇಲ್ಲ.",
        "welcomeContentCreator": "ಕಂಟೆಂಟ್ ಕ್ರಿಯೇಟರ್‌ಗೆ ಸ್ವಾಗತ",
        "yayYouWon": "ಭೇಷ್! ನೀವು ಗೆದ್ದಿದ್ದೀರಿ",
        "creditedToWalletNote":
            "ಇದು ನಿಮ್ಮ ವಾಲೆಟ್‌ಗೆ ಜಮಾ ಆಗುತ್ತದೆ. ಆರ್ಡರ್ ಪಾವತಿಯ ಸಮಯದಲ್ಲಿ "
            "ನೀವು ಇದನ್ನು ಬಳಸಬಹುದು.",
        "byClickingYouAccept": "ಕ್ಲಿಕ್ ಮಾಡುವ ಮೂಲಕ ನೀವು ಒಪ್ಪುತ್ತೀರಿ",
        "joinNow": "ಈಗ ಸೇರಿ",
        "creatorProgram": "ಕ್ರಿಯೇಟರ್ ಪ್ರೋಗ್ರಾಂ",
        "creatorEarnPerVideoFmt":
            "ಪ್ರತಿ ಅನುಮೋದಿತ ವೀಡಿಯೊಗೆ @amount ಗಳಿಸಿ, @total ವರೆಗೆ.",
        "addYourVideo": "ನಿಮ್ಮ ವೀಡಿಯೊ ಸೇರಿಸಿ",
        "addYourLinks": "ನಿಮ್ಮ ಲಿಂಕ್‌ಗಳನ್ನು ಸೇರಿಸಿ",
        "myVideos": "ನನ್ನ ವೀಡಿಯೊಗಳು",
        "noVideosYet":
            "ಇನ್ನೂ ಯಾವುದೇ ವೀಡಿಯೊ ಇಲ್ಲ — ಮೇಲೆ ನಿಮ್ಮ ಮೊದಲ ಲಿಂಕ್ ಸೇರಿಸಿ.",
        "creditedAmountFmt": "@amount ಜಮಾ ಆಗಿದೆ",
        "myStatics": "ನನ್ನ ಅಂಕಿಅಂಶಗಳು",
        "directReferralIncome": "ನೇರ ರೆಫರಲ್ ಆದಾಯ",
        "orderIncome": "ಆರ್ಡರ್ ಆದಾಯ",
        "contentCreationIncome": "ಕಂಟೆಂಟ್ ಕ್ರಿಯೇಶನ್ ಆದಾಯ",
        "totalBonus": "ಒಟ್ಟು ಬೋನಸ್",
        "daysLabel": "ದಿನಗಳು",
        "workHours": "ಕೆಲಸದ ಗಂಟೆಗಳು",
        "assignTask": "ನಿಯೋಜಿತ ಕಾರ್ಯ",
        "hrsUnit": "ಗಂಟೆ",
        "tasksUnit": "ಕಾರ್ಯಗಳು",
        "totalAmountLabel": "ಒಟ್ಟು ಮೊತ್ತ",
        "referralOrder": "ರೆಫರಲ್ ಆರ್ಡರ್",
        "totalIncomeLabel": "ಒಟ್ಟು ಆದಾಯ",
        "totalVideo": "ಒಟ್ಟು ವೀಡಿಯೊ",
        "viewCount": "ವೀಕ್ಷಣೆ ಸಂಖ್ಯೆ",
        "balanceDashFmt": "ಬಾಕಿ - @amount",
        "referralCodeCopiedToClipboard":
            "ರೆಫರಲ್ ಕೋಡ್ ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ನಕಲಿಸಲಾಗಿದೆ",
        "copyCode": "ಕೋಡ್ ನಕಲಿಸಿ",
        "shareCode": "ಕೋಡ್ ಹಂಚಿಕೊಳ್ಳಿ",
        "noVideosYetTitle": "ಇನ್ನೂ ಯಾವುದೇ ವೀಡಿಯೊ ಇಲ್ಲ",
        "addYourLinksHint":
            "ನಿಮ್ಮ ಮೊದಲ ಲಿಂಕ್ ಸೇರಿಸಲು ಮೇಲೆ \"ನಿಮ್ಮ ಲಿಂಕ್‌ಗಳನ್ನು ಸೇರಿಸಿ\" "
            "ಒತ್ತಿರಿ.",
        "referAndEarnCaps": "ರೆಫರ್ ಮಾಡಿ ಮತ್ತು ಗಳಿಸಿ",
        "yourReferralCodeCaps": "ನಿಮ್ಮ ರೆಫರಲ್ ಕೋಡ್",
        "applyAtSignupRewarded": "ಸೈನ್-ಅಪ್‌ನಲ್ಲಿ ಅನ್ವಯಿಸಿ ಮತ್ತು ಬಹುಮಾನ ಪಡೆಯಿರಿ",
        "downloadBlueEraEnterCode":
            "BlueEra ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ ಮತ್ತು ಸೈನ್-ಅಪ್‌ನಲ್ಲಿ ಈ ಕೋಡ್ ನಮೂದಿಸಿ",
        "previewNotAvailable": "ಪೂರ್ವವೀಕ್ಷಣೆ ಲಭ್ಯವಿಲ್ಲ",
        "instagramLink": "Instagram ಲಿಂಕ್",
        "instagramPreviewLimitSaved":
            "Instagram ಲಿಂಕ್ ಪೂರ್ವವೀಕ್ಷಣೆಯನ್ನು ಮಿತಿಗೊಳಿಸುತ್ತದೆ, ಆದ್ದರಿಂದ "
            "ಥಂಬ್‌ನೇಲ್ ಮತ್ತು ಶೀರ್ಷಿಕೆ ಲೋಡ್ ಆಗಲಿಲ್ಲ. ನಿಮ್ಮ ಲಿಂಕ್ ಉಳಿಸಲಾಗಿದೆ "
            "ಮತ್ತು Instagram ಆ್ಯಪ್‌ನಲ್ಲಿ ತೆರೆಯುತ್ತದೆ.",
        "openInInstagram": "Instagram ನಲ್ಲಿ ತೆರೆಯಿರಿ",
        "pickAPlatform": "ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಆಯ್ಕೆಮಾಡಿ",
        "pasteYourUrl": "ನಿಮ್ಮ URL ಅಂಟಿಸಿ",
        "addAVideoLink": "ವೀಡಿಯೊ ಲಿಂಕ್ ಸೇರಿಸಿ",
        "bringYourReels": "ಎಲ್ಲಿಂದಾದರೂ ನಿಮ್ಮ ರೀಲ್ಸ್ ತನ್ನಿ.",
        "pasteYourLinkHere": "ನಿಮ್ಮ ಲಿಂಕ್ ಇಲ್ಲಿ ಅಂಟಿಸಿ",
        "platformMismatchFmt":
            "ನೀವು @picked ಆಯ್ಕೆಮಾಡಿದ್ದೀರಿ, ಆದರೆ ಇದು @detected ಲಿಂಕ್‌ನಂತೆ "
            "ಕಾಣುತ್ತದೆ. ಮೇಲೆ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಬದಲಾಯಿಸಿ ಅಥವಾ @picked URL ಅಂಟಿಸಿ.",
        "unsupportedLinkPlatform":
            "ನಾವು ಸದ್ಯಕ್ಕೆ Instagram, X / Twitter, Facebook ಅಥವಾ YouTube "
            "ಲಿಂಕ್‌ಗಳನ್ನು ಮಾತ್ರ ಸೇರಿಸಬಹುದು.",
        "willBeSavedAs": "ಹೀಗೆ ಉಳಿಸಲಾಗುತ್ತದೆ",
        "instagramPreviewLimitWillSave":
            "Instagram ಲಿಂಕ್ ಪೂರ್ವವೀಕ್ಷಣೆಯನ್ನು ಮಿತಿಗೊಳಿಸುತ್ತದೆ, ಆದ್ದರಿಂದ "
            "ಥಂಬ್‌ನೇಲ್ ಮತ್ತು ಶೀರ್ಷಿಕೆ ಲೋಡ್ ಆಗದಿರಬಹುದು. ನಿಮ್ಮ ಲಿಂಕ್ ಆದರೂ "
            "ಉಳಿಸಲಾಗುತ್ತದೆ ಮತ್ತು Instagram ನಲ್ಲಿ ತೆರೆಯುತ್ತದೆ.",
        # backfill
        "noTestimonialsYet": "ಇನ್ನೂ ಯಾವುದೇ ಪ್ರಶಂಸಾಪತ್ರ ಇಲ್ಲ",
        "history": "ಇತಿಹಾಸ",
        "withdraw": "ಹಿಂಪಡೆಯಿರಿ",
        "balance": "ಬಾಕಿ",
        "totalEarn": "ಒಟ್ಟು ಗಳಿಕೆ",
        "estdEarning": "ಅಂದಾಜು ಗಳಿಕೆ",
        "joiningBonus": "ಸೇರುವ ಬೋನಸ್",
        "bonusLabel": "ಬೋನಸ್",
        "filterLabel": "ಫಿಲ್ಟರ್",
        "labelName": "ಹೆಸರು",
        "professionLabel": "ವೃತ್ತಿ",
        "export": "ರಫ್ತು",
        "applyLabel": "ಅನ್ವಯಿಸಿ",
        "copiedLabel": "ನಕಲಿಸಲಾಗಿದೆ",
    },
}

os.makedirs(OUT_DIR, exist_ok=True)

for lang, entries in T.items():
    path = os.path.join(TRANS_DIR, f"{lang}.json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    # Never clobber copy that already shipped for a backfill-only key.
    payload = {
        k: v for k, v in entries.items()
        if not (k in BACKFILL_ONLY and k in data)
    }
    skipped = len(entries) - len(payload)

    added = [k for k in payload if k not in data]
    existing = [k for k in data if k not in added]
    data.update(payload)
    if existing == sorted(existing):
        data = {k: data[k] for k in sorted(data)}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    out = os.path.join(OUT_DIR, f"{lang}.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"{lang}: {len(payload)} keys written "
          f"({len(added)} new, {skipped} already-shipped skipped)")
