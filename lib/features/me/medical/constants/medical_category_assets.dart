/// Local tile art for medical **level-0** categories, keyed by the category
/// `key`. Shared by the snap-search category grid
/// (`add_medical_snap_search_screen.dart`) and the Products tab category rail
/// (`medical_products_tab.dart`).
///
/// The categories come from the API, which carries no image for them, so both
/// screens look the art up here and fall back to a placeholder (or the API's own
/// `image`, where a rail keeps one) for any key without a mapping.
const Map<String, String> kMedicalCategoryImages = {
  'AYURVEDA_NUTRITION': 'assets/category/medical/AyurvedaNutrition.png',
  'HOME_PATIENT_CARE': 'assets/category/medical/Home_Patient_Care.png',
  'MEDICAL_DEVICES': 'assets/category/medical/Medical_Devices.png',
  'OTC_MEDICINES': 'assets/category/medical/OTC_Medicines.png',
  'PERSONAL_BABY_CARE': 'assets/category/medical/Personal_Baby_Care.png',
  'WOUND_CARE_FIRST_AID': 'assets/category/medical/Wound_Care_First_Aid.png',
};
