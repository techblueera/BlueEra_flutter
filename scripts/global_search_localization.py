#!/usr/bin/env python3
"""Add global-search screen localization keys to local asset JSONs
(en/hi/gu/kn/mr) and emit per-language PUT payloads for the language API.

Covers the search field, the category scope chips (SearchCategory), the
discovery landing (recent / trending / popular), the sort sheet, the result
cards and the empty / error states of
`lib/features/common/search/view/global_search_screen.dart`.

Note: the trending / popular tiles keep their English *query* in Dart — only
their display labels live here, because the search index is English and a
translated term would come back empty.

Run:  python3 scripts/global_search_localization.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT, "assets", "translations")
OUT_DIR = os.path.join(ROOT, "scripts", "global_search_lang_payloads")

T = {
    "en": {
        # category scope chips
        "noResultsFound": "No results found",
        "searchCatAll": "All",
        "searchCatContent": "Content",
        "searchCatVideos": "Videos",
        "searchCatPosts": "Posts",
        "searchCatGrocery": "Grocery",
        "searchCatFood": "Food",
        "searchCatShopping": "Shopping",
        "searchCatHealthcare": "Healthcare",
        "searchCatAutomotive": "Automotive",
        "searchCatStay": "Stay",
        "searchCatHomemadeFood": "Homemade Food",
        "searchCatHomemadeProducts": "Homemade Products",
        "searchCatHomeServices": "Home Services",
        "searchCatConsultants": "Consultants",
        "searchCatServices": "Services",
        "searchCatRentals": "Rentals",
        "searchCatFinance": "Finance",
        "searchCatJobs": "Jobs",
        "searchCatEducation": "Education",
        "searchCatShops": "Shops",
        # entity-type labels
        "searchEntityProduct": "Product",
        "searchEntityGrocery": "Grocery",
        "searchEntityGroceryShop": "Grocery Shop",
        "searchEntityPeople": "People",
        "searchEntityBusiness": "Business",
        "searchEntityService": "Service",
        "searchEntityResult": "Result",
        # screen chrome
        "globalSearchHint": "Search anything",
        "globalSearchKeepTyping": "Keep typing to see suggestions",
        "globalSearchInCategoryFmt": "in @category",
        "globalSearchRecentSearches": "Recent Searches",
        "globalSearchTrendingSearches": "Trending Searches",
        "globalSearchPopularProducts": "Popular Products",
        "globalSearchSort": "Sort",
        "globalSearchFilter": "Filter",
        "globalSearchFiltersComingSoon": "Filters coming soon",
        "globalSearchSortBy": "Sort by",
        "globalSearchRelevance": "Relevance",
        "globalSearchPriceLowToHigh": "Price -- Low to High",
        "globalSearchPriceHighToLow": "Price -- High to Low",
        "globalSearchNoResultsFmt":
            "No results for \"@query\".\nTry a different search.",
        "globalSearchNoResultsInCategoryFmt":
            "No results for \"@query\" in @category.",
        "globalSearchSearchAllCategories": "Search all categories",
        "globalSearchSponsored": "Sponsored",
        "globalSearchDiscountFmt": "@percent% off",
        "globalSearchNearMe": "near me",
        # discovery landing tiles (display only — query stays English)
        "globalSearchTrendMobilesUnder15000": "Mobiles under 15000",
        "globalSearchTrendShoes": "Shoes",
        "globalSearchTrendBikeCovers": "Bike covers",
        "globalSearchTrendHomeCleaning": "Home cleaning",
        "globalSearchTrendSalonAtHome": "Salon at home",
        "globalSearchTrendMenAccessories": "Men accessories",
        "globalSearchPopMobiles": "Mobiles",
        "globalSearchPopMobilesSub": "Latest 5G phones",
        "globalSearchPopFashion": "Fashion",
        "globalSearchPopFashionSub": "Shoes & apparel",
        "globalSearchPopGrocery": "Grocery",
        "globalSearchPopGrocerySub": "Daily essentials",
        "globalSearchPopElectronics": "Electronics",
        "globalSearchPopElectronicsSub": "Gadgets & more",
        "globalSearchPopHome": "Home",
        "globalSearchPopHomeSub": "Kitchen & decor",
    },
    "hi": {
        "noResultsFound": "कोई परिणाम नहीं मिला",
        "searchCatAll": "सभी",
        "searchCatContent": "कंटेंट",
        "searchCatVideos": "वीडियो",
        "searchCatPosts": "पोस्ट",
        "searchCatGrocery": "किराना",
        "searchCatFood": "खाना",
        "searchCatShopping": "शॉपिंग",
        "searchCatHealthcare": "हेल्थकेयर",
        "searchCatAutomotive": "ऑटोमोटिव",
        "searchCatStay": "ठहरने की जगह",
        "searchCatHomemadeFood": "घर का बना खाना",
        "searchCatHomemadeProducts": "घर के बने उत्पाद",
        "searchCatHomeServices": "होम सर्विसेज",
        "searchCatConsultants": "सलाहकार",
        "searchCatServices": "सेवाएँ",
        "searchCatRentals": "किराया",
        "searchCatFinance": "वित्त",
        "searchCatJobs": "नौकरियाँ",
        "searchCatEducation": "शिक्षा",
        "searchCatShops": "दुकानें",
        "searchEntityProduct": "उत्पाद",
        "searchEntityGrocery": "किराना",
        "searchEntityGroceryShop": "किराना दुकान",
        "searchEntityPeople": "लोग",
        "searchEntityBusiness": "व्यवसाय",
        "searchEntityService": "सेवा",
        "searchEntityResult": "परिणाम",
        "globalSearchHint": "कुछ भी खोजें",
        "globalSearchKeepTyping": "सुझाव देखने के लिए टाइप करते रहें",
        "globalSearchInCategoryFmt": "@category में",
        "globalSearchRecentSearches": "हाल की खोजें",
        "globalSearchTrendingSearches": "ट्रेंडिंग खोजें",
        "globalSearchPopularProducts": "लोकप्रिय उत्पाद",
        "globalSearchSort": "क्रमबद्ध करें",
        "globalSearchFilter": "फ़िल्टर",
        "globalSearchFiltersComingSoon": "फ़िल्टर जल्द आ रहे हैं",
        "globalSearchSortBy": "इसके अनुसार क्रमबद्ध करें",
        "globalSearchRelevance": "प्रासंगिकता",
        "globalSearchPriceLowToHigh": "कीमत -- कम से ज़्यादा",
        "globalSearchPriceHighToLow": "कीमत -- ज़्यादा से कम",
        "globalSearchNoResultsFmt":
            "\"@query\" के लिए कोई परिणाम नहीं।\nकोई दूसरी खोज आज़माएँ।",
        "globalSearchNoResultsInCategoryFmt":
            "@category में \"@query\" के लिए कोई परिणाम नहीं।",
        "globalSearchSearchAllCategories": "सभी श्रेणियों में खोजें",
        "globalSearchSponsored": "प्रायोजित",
        "globalSearchDiscountFmt": "@percent% छूट",
        "globalSearchNearMe": "मेरे पास",
        "globalSearchTrendMobilesUnder15000": "15000 से कम के मोबाइल",
        "globalSearchTrendShoes": "जूते",
        "globalSearchTrendBikeCovers": "बाइक कवर",
        "globalSearchTrendHomeCleaning": "घर की सफ़ाई",
        "globalSearchTrendSalonAtHome": "घर पर सैलून",
        "globalSearchTrendMenAccessories": "पुरुषों की एक्सेसरीज़",
        "globalSearchPopMobiles": "मोबाइल",
        "globalSearchPopMobilesSub": "नवीनतम 5G फ़ोन",
        "globalSearchPopFashion": "फ़ैशन",
        "globalSearchPopFashionSub": "जूते और कपड़े",
        "globalSearchPopGrocery": "किराना",
        "globalSearchPopGrocerySub": "रोज़मर्रा की ज़रूरतें",
        "globalSearchPopElectronics": "इलेक्ट्रॉनिक्स",
        "globalSearchPopElectronicsSub": "गैजेट्स और बहुत कुछ",
        "globalSearchPopHome": "घर",
        "globalSearchPopHomeSub": "किचन और सजावट",
    },
    "gu": {
        "noResultsFound": "કોઈ પરિણામ મળ્યું નથી",
        "searchCatAll": "બધું",
        "searchCatContent": "કન્ટેન્ટ",
        "searchCatVideos": "વિડિઓ",
        "searchCatPosts": "પોસ્ટ",
        "searchCatGrocery": "કરિયાણું",
        "searchCatFood": "ખોરાક",
        "searchCatShopping": "શોપિંગ",
        "searchCatHealthcare": "હેલ્થકેર",
        "searchCatAutomotive": "ઓટોમોટિવ",
        "searchCatStay": "રહેવાની જગ્યા",
        "searchCatHomemadeFood": "ઘરે બનાવેલું ખાવાનું",
        "searchCatHomemadeProducts": "ઘરે બનાવેલી પ્રોડક્ટ્સ",
        "searchCatHomeServices": "હોમ સર્વિસ",
        "searchCatConsultants": "સલાહકારો",
        "searchCatServices": "સેવાઓ",
        "searchCatRentals": "ભાડે",
        "searchCatFinance": "ફાઇનાન્સ",
        "searchCatJobs": "નોકરીઓ",
        "searchCatEducation": "શિક્ષણ",
        "searchCatShops": "દુકાનો",
        "searchEntityProduct": "પ્રોડક્ટ",
        "searchEntityGrocery": "કરિયાણું",
        "searchEntityGroceryShop": "કરિયાણાની દુકાન",
        "searchEntityPeople": "લોકો",
        "searchEntityBusiness": "વ્યવસાય",
        "searchEntityService": "સેવા",
        "searchEntityResult": "પરિણામ",
        "globalSearchHint": "કંઈપણ શોધો",
        "globalSearchKeepTyping": "સૂચનો જોવા માટે ટાઇપ કરતા રહો",
        "globalSearchInCategoryFmt": "@category માં",
        "globalSearchRecentSearches": "તાજેતરની શોધ",
        "globalSearchTrendingSearches": "ટ્રેન્ડિંગ શોધ",
        "globalSearchPopularProducts": "લોકપ્રિય પ્રોડક્ટ્સ",
        "globalSearchSort": "સૉર્ટ કરો",
        "globalSearchFilter": "ફિલ્ટર",
        "globalSearchFiltersComingSoon": "ફિલ્ટર્સ ટૂંક સમયમાં આવી રહ્યા છે",
        "globalSearchSortBy": "આ પ્રમાણે સૉર્ટ કરો",
        "globalSearchRelevance": "સુસંગતતા",
        "globalSearchPriceLowToHigh": "કિંમત -- ઓછીથી વધુ",
        "globalSearchPriceHighToLow": "કિંમત -- વધુથી ઓછી",
        "globalSearchNoResultsFmt":
            "\"@query\" માટે કોઈ પરિણામ નથી.\nબીજી શોધ અજમાવો.",
        "globalSearchNoResultsInCategoryFmt":
            "@category માં \"@query\" માટે કોઈ પરિણામ નથી.",
        "globalSearchSearchAllCategories": "બધી શ્રેણીઓમાં શોધો",
        "globalSearchSponsored": "પ્રાયોજિત",
        "globalSearchDiscountFmt": "@percent% છૂટ",
        "globalSearchNearMe": "મારી નજીક",
        "globalSearchTrendMobilesUnder15000": "15000 થી ઓછી કિંમતના મોબાઇલ",
        "globalSearchTrendShoes": "પગરખાં",
        "globalSearchTrendBikeCovers": "બાઇક કવર",
        "globalSearchTrendHomeCleaning": "ઘરની સફાઈ",
        "globalSearchTrendSalonAtHome": "ઘરે સલૂન",
        "globalSearchTrendMenAccessories": "પુરુષોની એક્સેસરીઝ",
        "globalSearchPopMobiles": "મોબાઇલ",
        "globalSearchPopMobilesSub": "નવીનતમ 5G ફોન",
        "globalSearchPopFashion": "ફેશન",
        "globalSearchPopFashionSub": "પગરખાં અને કપડાં",
        "globalSearchPopGrocery": "કરિયાણું",
        "globalSearchPopGrocerySub": "રોજિંદી જરૂરિયાતો",
        "globalSearchPopElectronics": "ઇલેક્ટ્રોનિક્સ",
        "globalSearchPopElectronicsSub": "ગેજેટ્સ અને વધુ",
        "globalSearchPopHome": "ઘર",
        "globalSearchPopHomeSub": "રસોડું અને સજાવટ",
    },
    "mr": {
        "noResultsFound": "कोणतेही निकाल सापडले नाहीत",
        "searchCatAll": "सर्व",
        "searchCatContent": "कंटेंट",
        "searchCatVideos": "व्हिडिओ",
        "searchCatPosts": "पोस्ट",
        "searchCatGrocery": "किराणा",
        "searchCatFood": "खाणे",
        "searchCatShopping": "शॉपिंग",
        "searchCatHealthcare": "हेल्थकेअर",
        "searchCatAutomotive": "ऑटोमोटिव्ह",
        "searchCatStay": "राहण्याची सोय",
        "searchCatHomemadeFood": "घरगुती जेवण",
        "searchCatHomemadeProducts": "घरगुती उत्पादने",
        "searchCatHomeServices": "होम सर्व्हिसेस",
        "searchCatConsultants": "सल्लागार",
        "searchCatServices": "सेवा",
        "searchCatRentals": "भाड्याने",
        "searchCatFinance": "वित्त",
        "searchCatJobs": "नोकऱ्या",
        "searchCatEducation": "शिक्षण",
        "searchCatShops": "दुकाने",
        "searchEntityProduct": "उत्पादन",
        "searchEntityGrocery": "किराणा",
        "searchEntityGroceryShop": "किराणा दुकान",
        "searchEntityPeople": "लोक",
        "searchEntityBusiness": "व्यवसाय",
        "searchEntityService": "सेवा",
        "searchEntityResult": "निकाल",
        "globalSearchHint": "काहीही शोधा",
        "globalSearchKeepTyping": "सूचना पाहण्यासाठी टाइप करत रहा",
        "globalSearchInCategoryFmt": "@category मध्ये",
        "globalSearchRecentSearches": "अलीकडील शोध",
        "globalSearchTrendingSearches": "ट्रेंडिंग शोध",
        "globalSearchPopularProducts": "लोकप्रिय उत्पादने",
        "globalSearchSort": "क्रमवारी लावा",
        "globalSearchFilter": "फिल्टर",
        "globalSearchFiltersComingSoon": "फिल्टर लवकरच येत आहेत",
        "globalSearchSortBy": "यानुसार क्रमवारी लावा",
        "globalSearchRelevance": "सुसंगतता",
        "globalSearchPriceLowToHigh": "किंमत -- कमी ते जास्त",
        "globalSearchPriceHighToLow": "किंमत -- जास्त ते कमी",
        "globalSearchNoResultsFmt":
            "\"@query\" साठी कोणतेही निकाल नाहीत.\nदुसरा शोध वापरून पहा.",
        "globalSearchNoResultsInCategoryFmt":
            "@category मध्ये \"@query\" साठी कोणतेही निकाल नाहीत.",
        "globalSearchSearchAllCategories": "सर्व श्रेणींमध्ये शोधा",
        "globalSearchSponsored": "प्रायोजित",
        "globalSearchDiscountFmt": "@percent% सूट",
        "globalSearchNearMe": "माझ्या जवळ",
        "globalSearchTrendMobilesUnder15000": "15000 पेक्षा कमी किमतीचे मोबाइल",
        "globalSearchTrendShoes": "बूट",
        "globalSearchTrendBikeCovers": "बाईक कव्हर",
        "globalSearchTrendHomeCleaning": "घराची स्वच्छता",
        "globalSearchTrendSalonAtHome": "घरी सलून",
        "globalSearchTrendMenAccessories": "पुरुषांच्या अ‍ॅक्सेसरीज",
        "globalSearchPopMobiles": "मोबाइल",
        "globalSearchPopMobilesSub": "नवीनतम 5G फोन",
        "globalSearchPopFashion": "फॅशन",
        "globalSearchPopFashionSub": "बूट आणि कपडे",
        "globalSearchPopGrocery": "किराणा",
        "globalSearchPopGrocerySub": "दैनंदिन गरजा",
        "globalSearchPopElectronics": "इलेक्ट्रॉनिक्स",
        "globalSearchPopElectronicsSub": "गॅजेट्स आणि बरेच काही",
        "globalSearchPopHome": "घर",
        "globalSearchPopHomeSub": "स्वयंपाकघर आणि सजावट",
    },
    "kn": {
        "noResultsFound": "ಯಾವುದೇ ಫಲಿತಾಂಶಗಳು ಕಂಡುಬಂದಿಲ್ಲ",
        "searchCatAll": "ಎಲ್ಲಾ",
        "searchCatContent": "ವಿಷಯ",
        "searchCatVideos": "ವೀಡಿಯೊಗಳು",
        "searchCatPosts": "ಪೋಸ್ಟ್‌ಗಳು",
        "searchCatGrocery": "ದಿನಸಿ",
        "searchCatFood": "ಆಹಾರ",
        "searchCatShopping": "ಶಾಪಿಂಗ್",
        "searchCatHealthcare": "ಆರೋಗ್ಯ ಸೇವೆ",
        "searchCatAutomotive": "ಆಟೋಮೋಟಿವ್",
        "searchCatStay": "ವಸತಿ",
        "searchCatHomemadeFood": "ಮನೆಯ ಊಟ",
        "searchCatHomemadeProducts": "ಮನೆಯಲ್ಲಿ ತಯಾರಿಸಿದ ಉತ್ಪನ್ನಗಳು",
        "searchCatHomeServices": "ಹೋಮ್ ಸೇವೆಗಳು",
        "searchCatConsultants": "ಸಲಹೆಗಾರರು",
        "searchCatServices": "ಸೇವೆಗಳು",
        "searchCatRentals": "ಬಾಡಿಗೆ",
        "searchCatFinance": "ಹಣಕಾಸು",
        "searchCatJobs": "ಉದ್ಯೋಗಗಳು",
        "searchCatEducation": "ಶಿಕ್ಷಣ",
        "searchCatShops": "ಅಂಗಡಿಗಳು",
        "searchEntityProduct": "ಉತ್ಪನ್ನ",
        "searchEntityGrocery": "ದಿನಸಿ",
        "searchEntityGroceryShop": "ದಿನಸಿ ಅಂಗಡಿ",
        "searchEntityPeople": "ಜನರು",
        "searchEntityBusiness": "ವ್ಯವಹಾರ",
        "searchEntityService": "ಸೇವೆ",
        "searchEntityResult": "ಫಲಿತಾಂಶ",
        "globalSearchHint": "ಏನನ್ನಾದರೂ ಹುಡುಕಿ",
        "globalSearchKeepTyping": "ಸಲಹೆಗಳನ್ನು ನೋಡಲು ಟೈಪ್ ಮಾಡುತ್ತಿರಿ",
        "globalSearchInCategoryFmt": "@category ನಲ್ಲಿ",
        "globalSearchRecentSearches": "ಇತ್ತೀಚಿನ ಹುಡುಕಾಟಗಳು",
        "globalSearchTrendingSearches": "ಟ್ರೆಂಡಿಂಗ್ ಹುಡುಕಾಟಗಳು",
        "globalSearchPopularProducts": "ಜನಪ್ರಿಯ ಉತ್ಪನ್ನಗಳು",
        "globalSearchSort": "ವಿಂಗಡಿಸಿ",
        "globalSearchFilter": "ಫಿಲ್ಟರ್",
        "globalSearchFiltersComingSoon": "ಫಿಲ್ಟರ್‌ಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ",
        "globalSearchSortBy": "ಇದರ ಪ್ರಕಾರ ವಿಂಗಡಿಸಿ",
        "globalSearchRelevance": "ಪ್ರಸ್ತುತತೆ",
        "globalSearchPriceLowToHigh": "ಬೆಲೆ -- ಕಡಿಮೆಯಿಂದ ಹೆಚ್ಚು",
        "globalSearchPriceHighToLow": "ಬೆಲೆ -- ಹೆಚ್ಚಿನಿಂದ ಕಡಿಮೆ",
        "globalSearchNoResultsFmt":
            "\"@query\" ಗಾಗಿ ಯಾವುದೇ ಫಲಿತಾಂಶಗಳಿಲ್ಲ.\nಬೇರೆ ಹುಡುಕಾಟವನ್ನು ಪ್ರಯತ್ನಿಸಿ.",
        "globalSearchNoResultsInCategoryFmt":
            "@category ನಲ್ಲಿ \"@query\" ಗಾಗಿ ಯಾವುದೇ ಫಲಿತಾಂಶಗಳಿಲ್ಲ.",
        "globalSearchSearchAllCategories": "ಎಲ್ಲಾ ವರ್ಗಗಳಲ್ಲಿ ಹುಡುಕಿ",
        "globalSearchSponsored": "ಪ್ರಾಯೋಜಿತ",
        "globalSearchDiscountFmt": "@percent% ರಿಯಾಯಿತಿ",
        "globalSearchNearMe": "ನನ್ನ ಹತ್ತಿರ",
        "globalSearchTrendMobilesUnder15000": "15000 ಒಳಗಿನ ಮೊಬೈಲ್‌ಗಳು",
        "globalSearchTrendShoes": "ಶೂಗಳು",
        "globalSearchTrendBikeCovers": "ಬೈಕ್ ಕವರ್‌ಗಳು",
        "globalSearchTrendHomeCleaning": "ಮನೆ ಸ್ವಚ್ಛತೆ",
        "globalSearchTrendSalonAtHome": "ಮನೆಯಲ್ಲೇ ಸಲೂನ್",
        "globalSearchTrendMenAccessories": "ಪುರುಷರ ಪರಿಕರಗಳು",
        "globalSearchPopMobiles": "ಮೊಬೈಲ್‌ಗಳು",
        "globalSearchPopMobilesSub": "ಇತ್ತೀಚಿನ 5G ಫೋನ್‌ಗಳು",
        "globalSearchPopFashion": "ಫ್ಯಾಷನ್",
        "globalSearchPopFashionSub": "ಶೂ ಮತ್ತು ಉಡುಪು",
        "globalSearchPopGrocery": "ದಿನಸಿ",
        "globalSearchPopGrocerySub": "ದೈನಂದಿನ ಅಗತ್ಯ ವಸ್ತುಗಳು",
        "globalSearchPopElectronics": "ಎಲೆಕ್ಟ್ರಾನಿಕ್ಸ್",
        "globalSearchPopElectronicsSub": "ಗ್ಯಾಜೆಟ್‌ಗಳು ಮತ್ತು ಇನ್ನಷ್ಟು",
        "globalSearchPopHome": "ಮನೆ",
        "globalSearchPopHomeSub": "ಅಡುಗೆಮನೆ ಮತ್ತು ಅಲಂಕಾರ",
    },
}

BASE_URL = "https://be.beapp.in/api/language-service/languages"


def check_parity():
    """Every language must carry exactly the English key set — a missing key
    renders as its raw identifier in the UI."""
    base = set(T["en"])
    for lang, kv in T.items():
        missing = base - set(kv)
        extra = set(kv) - base
        assert not missing, f"{lang}: missing {sorted(missing)}"
        assert not extra, f"{lang}: unknown {sorted(extra)}"
    print(f"parity OK: {len(base)} keys x {len(T)} languages")


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
    for lang, kv in T.items():
        body = json.dumps(kv, ensure_ascii=False, indent=2)
        with open(os.path.join(OUT_DIR, f"{lang}.json"), "w", encoding="utf-8") as f:
            f.write(body + "\n")
    with open(os.path.join(OUT_DIR, "curl_commands.sh"), "w", encoding="utf-8") as f:
        f.write(
            "#!/usr/bin/env bash\n"
            "# Pushes the global-search screen strings (category chips, landing\n"
            "# sections, sort sheet, result cards, empty/error states) to the\n"
            "# language service. Run from the repo root:\n"
            "#   bash scripts/global_search_lang_payloads/curl_commands.sh\n"
            "set -e\n\n"
            "for lang in en hi gu mr kn; do\n"
            "  curl -X 'PUT' \\\n"
            f"    \"{BASE_URL}/$lang\" \\\n"
            "    -H 'accept: */*' \\\n"
            "    -H 'Content-Type: application/json' \\\n"
            "    -d @scripts/global_search_lang_payloads/$lang.json\n"
            "done\n"
        )
    print(f"payloads + curl_commands.sh written to {OUT_DIR}")


if __name__ == "__main__":
    check_parity()
    update_assets()
    emit_payloads()
