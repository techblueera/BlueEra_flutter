// ignore_for_file: constant_identifier_names

import 'dart:core';
import 'dart:math' hide log;
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/business/visit_business_profile/view/visit_business_profile_new.dart';

class AppConstants {
  static const String rupeeSymbol = '\u20B9';

  static const String appName = 'BlueEra';
  static const String shareAppMsg = 'Created By BlueEra jobs app!\n\n'
      "Hey! I'm using BlueEraJobs and join me there. "
      "I'm sending you an invite—download the app, and let's connect! "
      "at https://bluecs.in/app";
  static const String iosAppId = "6745372448";
  static const String androidPackageName = "ai.bluecs.app";
  static const String androidPlayStoreUrl =
      "https://play.google.com/store/apps/details?id=$androidPackageName";
  static const String iosAppStoreUrl =
      "https://apps.apple.com/us/app/id$iosAppId";
  static const String restApiKey = "a6f5ddfd96e84ced3f33a8a3cafdb19c";
  static const String atlasClientId =
      "96dHZVzsAuvBjpRKk-XkdFPxMu6nuV_ogPhzHpnmnZbB_eW36B2pVC_mEz-N8dBhlKCLJ0ywLeDEfzlAB0sUDdrdDIdOLSmz";
  static const String atlasClientSecret =
      "lrFxI-iSEg-L0_lxA1gBnHlNVhgrO4gVhgfaG2JLq1HCR6kyMOTRZMc8_YcuTqdzn3I09RWsahz1OMwDOnJh55yHytA5u9FOprqt6OhzqY8=";
  static const String prod = 'production';
  static const String qa = 'QA';
  static const String dev = 'Dev';
  static const String baseImageAssetsPath = "assets/images/";
  static const String baseImageAssetsCategoryPath = "assets/category/";
  static const String baseImageAssetsGroceryCategoryPath =
      "assets/category/grocery/";
  static const String baseImageAssetsOnboardingIndividualPath =
      "assets/onboarding/individual/";
  static const String baseImageAssetsOnboardingBusinessPath =
      "assets/onboarding/business/";
  static const String baseIconAssetsPath = "assets/icons/";
  static const String baseSvgAssetsPath = "assets/svg/";
  static const String baseGifsAssetsPath = "assets/gifs/";
  static const String baseGroceryAssetsPath = "assets/category/grocery/menu/";
  static const String baseFoodAssetsPath = "assets/category/foods/menu/";
  static const String porterLink =
      "https://porter.in/two-wheelers/pune?gads=search&utm_source=google&utm_medium=cpc&utm_campaign=20818387432&utm_term=155699175106&utm_content=proter&click_id=CjwKCAjw0sfHBhB6EiwAQtv5qYha39Cvxfna--Z62rwj2oXy0dUbTfhiY_-AkfXSSz9nIFcXetJxHxoCzWgQAvD_BwE&gad_source=1&gad_campaignid=20818387432&gbraid=0AAAAAoulZ9ihaB8xOb2NnDAf_6AJckFkq&gclid=CjwKCAjw0sfHBhB6EiwAQtv5qYha39Cvxfna--Z62rwj2oXy0dUbTfhiY_-AkfXSSz9nIFcXetJxHxoCzWgQAvD_BwE";
  static const String rapidoLink = "https://www.rapido.bike/Home";

  ///CHANGE NAME : arial to open sans some conflict are there
  // static const String arial = "OpenSans";
  static const String OpenSans = "Open Sans";
  static const String Regular = "Regular";

  // static const String arial = "Arial";
  static const String androidDownloadPath = "/storage/emulated/0/Download/";

  static const List<String> qualificationList = [
    "10th",
    "12th",
    "Diploma",
    "Degree"
  ];
  static const List<String> stateList = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal"
  ];

  static const int inputCharterLimit = 150;
  static const int inputCharterLimit400 = 400;
  static const int inputCharterLimit250 = 250;
  static const int inputCharterLimit200 = 200;
  static const int inputCharterLimit50 = 50;
  static const int inputCharterLimit10 = 10;
  static const int inputCharterLimit16 = 16;
  static const int inputCharterLimit20 = 20;
  static const int inputCharterLimit30 = 30;
  static const int inputCharterLimit100 = 100;
  static const int inputCharterLimit120 = 120;
  static const int inputCharterLimit6 = 6;

  static const String back = 'Back';
  static const String REGISTER = 'REGISTER';
  static const String SMS = 'SMS';
  static const String WhatsApp = 'WhatsApp';
 static final List<Map<String, String>> aiChatTopics = [
    {"title": "News", "tag": "news"},
    {"title": "Jokes", "tag": "jokes"},
    {"title": "Debate", "tag": "debate"},
    {"title": "Personality", "tag": "personality"},
    {"title": "Finance", "tag": "finance"},
    {"title": "Politics", "tag": "politics"},
    {"title": "Health", "tag": "health"},
    {"title": "Event", "tag": "event"},
  ];

  static const String active = 'active';
  static const String created = 'created';
  static const String paused = 'paused';
  static const String completed = 'completed';
  static const String expired = 'expired';
  static const String halted = 'halted';
  static const String pending = 'pending';

  static const String veg = 'veg';
  static const String group_Chat_Type = 'group';
  static const String order_Chat_Type = 'order';
  static const String emergency = 'Emergency';
  static const String other = 'Other';
  static const String AiReply_Chat_Type = 'AiReply';
  static const String AiQuest_Chat_Type = 'AiQuest';

  static const String personal_Chat_Type = 'personal';
  static const String business_Chat_Type = 'business';

  /// Values for the optional `route` send-message param. The backend maps
  /// `contact -> personal` and `discover -> business` conversation lanes,
  /// deciding (and creating, if needed) the correct thread at send time
  /// instead of inferring it from contact state. See the route-override
  /// integration guide.
  static const String route_contact = 'contact';
  static const String route_discover = 'discover';
  static const String search_Chat_Type = 'search';
  static const String askInventory_Chat_Type = 'INVENTORY';
  static const String askFood_Chat_Type = 'FOOD';
  static const String askService_Chat_Type = 'SERVICES';
  static const String askHealthCare_Chat_Type = 'HEALTHCARE';
  static const String askEducation_Chat_Type = 'EDUCATION';
  static const String askHomeService_Chat_Type = 'HOME_SERVICES';
  static const String askTravelStay_Chat_Type = 'TRAVEL';
  static const String askConsultingTalk_Chat_Type = 'CONSULTING';

  // static const String business = 'business';
  // static const String company = 'company';
  static const String oneWay = 'One Way';
  static const String roundTrip = 'Round Trip';
  static const String sharing = 'Sharing';
  static const String mySelf = 'My Self';
  static const String myFriend = 'My Friend';

  static const String recruiter = 'recruiter';

  static const String deepLinkScreen = 'deepLinkScreen';
  static const String individual = 'INDIVIDUAL';
  static const String business = 'BUSINESS';
  static const String guest = 'GUEST';

  static const String businessName = "Eg. Friends Collections Center...";
  static const String name = "Eg. Rahul Sharma";
  static const String companyOrg = "Eg. Wipro,TCS";
  static const String myBio = "Eg. I m Computer Engineer";
  static const String companyOrgBusiness = "Eg. Fashion Collections";
  static const String highestEducation = "Eg. Phd";
  static const String education = 'E.g. Educational...';
  static const String selectProfession = "Eg. Manager...";
  static const String selectSelfEmployee = "Eg. Plumber...";
  static const String selectSelfArtist = "eg. Painter...";
  static const String designation = "Enter your job title(Eg. Manager)";
  static const String hrManager = "Eg. HR Manager";
  static const String typeOfService = "Type of service";
  static const String certiID = "Eg. 4343FD";
  static const String certificateName = "Eg. Sports,Coding";
  static const String links = "Eg. Linkedin";
  static const String address = "Eg. Shop no.15, Borivali...";
  static const String gender = "Select Gender";
  static const String chatHost = 'chat.beapp.in';
  static const String adminUserName = 'admin_blueera';
  static const String pdfIconUrl =
      "https://cdn-icons-png.flaticon.com/512/4726/4726010.png";
  static const short = "short";
  static const long = "long";
  static const Others = "OTHERS";
  static const MESSAGE_POST = "MESSAGE_POST";
  static const POLL_POST = "POLL_POST";
  static const PHOTO_POST = "PHOTO_POST";
  static const EDIT = "EDIT";
  static const ADD = "ADD";
  static const PUBLISH = "PUBLISH";
  static const DIRECTION = "DIRECTION";
  static const JOB_POST = "JOB_POST";
  static const APPLY_NOW = "APPLY_NOW";
  static const ON_HOLD = "On Hold";
  static const CLOSED = "Closed";
  static const OPEN = "Open";
  static const All = "All";
  static const IN_PROGRESS = "In Progress";
  static const INTERVIEW = "Interview";
  static const DELETE = "DELETE";
  static const REMOVE = "REMOVE";

  static const Applied = "Applied";
  static const Screening = "Screening";
  static const Hired = "Hired";
  static const InterviewScheduled = "Interview Scheduled";
  static const exportPDF = "ExportPDF";
  static const exportExcel = "ExportExcel";
  static const Shortlisted = "Shortlisted";
  static const Connect = "Connect";
  static const Offered = "Offered";
  static const Rejected = "Rejected";
  static const SCHEDULES = "SCHEDULES";
  static const Saved = "Saved";
  static const rescheduled = "rescheduled";
  static const String Interviewing = "Interviewing";
  static const String Withdrawn = "Withdrawn";
  static const String Landscape = "Landscape";
  static const String Square = "Square";
  static const String chatScreen = "chatScreen";
  static const String INDIVIDUAL = "INDIVIDUAL";
  static const String feedScreen = "feedScreen";
  static const String storeFeedScreen = "storeFeedScreen";
  static const String food = "food";
  static const String medical = "medical";
  static const String product = "product";
  static const String service = "service";
  static const String grocery = "grocery";
  static const String chatMsgBusinessType = "business";
  static const String channelFeedList = "channelFeedList";
  static const String channelOTTList = "channelOTTList";
  static const String prepaid = "prepaid";
  static const String postpaid = "postpaid";
  static const String manufacturingIndustry = "manufacturingIndustry";
  static const String personal = 'personal';

  static const String aiChat = 'aiChat';
  /// Services Category
  static const consulting = "Consulting Services";
  static const automotive = "Automotive Services";
  static const itCommunication = "IT & Communication";
  static const homeUtility = "Home Services & Utility";
  static const mediaCreative = "Media, Publicity & Creative";
  static const educationTraining = "Education & Training Services";
  static const tourTravel = "Tour, Travel & Tourism";
  static const beautyCare = "Beauty & Personal Care";
  static const serviceCenter = "Service Center & Essential Utility";
  static const logistics = "Logistics & Transportation";
  static const celebrationEvent = "Celebration & Event Services";
  static const financial = "Financial Services";
  static const healthcareMedicalServices = "Healthcare & Medical Services";
  static const hostelsStayService = "Hostels & Stay Service";
  static const HOSPITALS = "HOSPITAL SECTOR";
  static const HOSPITALS_SECTOR = "HOSPITAL_SECTOR";
  static const wellness = "ALTERNATIVE WELLNESS";
  static const clinic = "CLINIC DOCTORS";
  static const MEDICAL_EDUCATION_INSTITUTIONS =
      "Medical Education Institutions";
  static const DIAGNOSTIC_TESTING_CENTERSWith_ = "DIAGNOSTIC_SECTOR";
  static const DIAGNOSTIC_TESTING_CENTERS = "DIAGNOSTIC SECTOR";

  /// Automotive Categories
  static const SALES_SECTOR = "Sales Sector";
  static const PARTS_SECTOR = "Parts Sector";
  static const SERVICE_SECTOR = "Service Sector";
  static const SUPPORT_SECTOR = "Support Sector";
  static const TRANSPORT_LOGISTIC = "Transport Logistic";

  static const SUPPORT_SERVICES = "SUPPORT SERVICES";

  // static const DIAGNOSTIC_TESTING_CENTERS = "DIAGNOSTIC AND TESTING CENTERS";

  // static const hostelsStayService = "Hotels Hostels & Stay Service";

  /// Store(Products) Category
  static const furnitureHomeDecor = "Furniture & Home Decor Store";
  static const sportsFitness = "Sports & Fitness Store";
  static const jewelleryLuxury = "Jewelry & Luxury Store";
  static const automotiveStore = "Automotive Store";
  static const booksStationaryGifts = "Books, Stationery & Gifts Store";
  static const pharmacyMedical = "Pharmacy & Medical Store";
  static const petSupplies = "Pet Supplies Store";
  static const toysBabyProducts = "Toys & Baby Products Store";
  static const electronicsAppliances = "Electronics & Appliances Store";
  static const constructionHomeEssentials = "Construction & Home Essentials";
  static const fashionLifestyle = "Fashion & Lifestyle";

  /// Food Category
  static const String fastFoodQuickService = "Fast Food & Quick Service (QSR)";
  static const String multiCuisineRestaurants = "Multi-Cuisine Restaurants";
  static const String groceryVegetablesDairy = "Grocery / Vegetables & Dairy";
  static const String nonVegRestaurants = "Non-Veg Restaurants";
  static const String vegRestaurants = "Veg Restaurants";
  static const String sweetsBakeryDrinks = "Sweets / Bakery & Drinks";
  static const String otherRestaurantsDhaba = "Other Restaurants / Dhaba";
  static const String otherFoodServices = "Other Food Services";

  static const groceryServices = "Grocery";
  static const foodServices = "Food";
  static const storeServices = "Store";
  static const productsServices = "Products";
  static const stayServices = "Stay";
  static const taxiDriverServices = "Taxi-Car Driver";
  static const riderServices = "Rider";
  static const rentalServices = "Rental";
  static const bookingServices = "Booking";
  static const homeServices = "Home Services";

  //skilledWork ,consultant ,travel
  static const all = "All";
  static const skilledWork = "Skilled Work";
  static const consultant = "Consultant";
  static const travel = "Travel";

  static const storeAi = "StoreAi";
  static const hotelServiceScreen = "hotelServiceScreen";
  static const personalDocumentScreen = "personalDocumentScreen";
  static const businessDocumentScreen = "businessDocumentScreen";

  static const reject = "reject";
  static const accept = "accept";
  static const cancelled = "cancelled";

  static const InCity = "InCity";
  static const OutStation = "OutStation";
  static const HourlyRental = "HourlyRental";
  static const Parcel = "Parcel";

  /// Rental Service Types
  static const property = "Property";
  static const flat = "Flat";
  static const vehicle = "Vehicle";
}

class DocumentKeys {
  static const aadhar = "aadhar";
  static const pan = "pan";
  static const addressProof = "addressProof";
  static const noc = "noc";
  static const drivingLicense = "drivingLicense";
  static const bankDetails = "bankDetails";
  static const bankersCancelledCheque = "bankersCancelledCheque";

  // Vehicle Keys
  static const vehicleRC = "vehicleRC";
  static const insuranceDocument = "insuranceDocument";
  static const puc = "puc";
  static const vehicleFitnessCertificate = "fitnessCertificate";

  // Business Keys
  static const gstCertificate = "gstCertificate";
  static const fssaiLicense = "fssaiLicense";
  static const medicalLicense = "medicalLicense";
  static const fireSafetyCertificate = "fireSafetyCertificate";
  static const municipalCorpCertificate = "municipalCorpCertificate";
  static const msmeCertificate = "msmeCertificate";
  static const shopActCertificate = "shopActCertificate";

  // Hotel & Home Stay keys
  static const hotelTradeLicense = "hotelTradeLicense";
  static const hotelPanCard = "hotelPanCard";
  static const hotelGstCertificate = "hotelGstCertificate";
  static const hotelCancelledCheque = "hotelCancelledCheque";
  static const hotelPoliceVerification = "hotelPoliceVerification";
  static const hotelFireSafetyCertificate = "hotelFireSafetyCertificate";
  static const hotelFssaiLicense = "hotelFssaiLicense";
  static const hotelOwnerIdProof = "hotelOwnerIdProof";
  static const hotelOnboardingAgreement = "hotelOnboardingAgreement";
  static const hotelPropertyAgreement = "hotelPropertyAgreement";
}

class MedicalStoreType {
  static const pharmacy = "PHARMACY";
  static const hospital = "HOSPITAL";
}

///IS GUEST USER...
bool isGuestUser() => (accountTypeGlobal.toUpperCase() == AppConstants.guest);

/// Returns true only when an authenticated session is active. Used to
/// guard authenticated API calls so they no-op after logout (when the
/// token global has been cleared but stale controllers, in-flight
/// futures, or Obx-driven rebuilds may still try to fire requests).
/// Checks only the token: `userId` is populated *by* viewPersonalProfile
/// on first login, so requiring it here would block the post-login fetch.
bool isLoggedIn() => (authTokenGlobal?.isNotEmpty ?? false);

///IS individual USER...
bool isIndividualUser() =>
    (accountTypeGlobal.toUpperCase() == AppConstants.individual);

///IS business USER...
bool isBusinessUser() =>
    (accountTypeGlobal.toUpperCase() == AppConstants.business);

String formatNumber(int number) {
  final formatter = NumberFormat('#,###');
  return formatter.format(number);
}

String formatIndianNumber(num? number) {
  if (number == null) return "0";

  if (number >= 10000000) {
    return '${(number / 10000000).toStringAsFixed((number % 10000000 == 0) ? 0 : 1)}Cr';
  } else if (number >= 100000) {
    return '${(number / 100000).toStringAsFixed((number % 100000 == 0) ? 0 : 1)}L';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed((number % 1000 == 0) ? 0 : 1)}k';
  } else {
    return number.toString();
  }
}
final List<Map<String, String>> categories = [
  {
    "title": "Ayurveda & Nutrition",
    "key": "Ayurveda_Nutrition",
    "image": "assets/category/medical/AyurvedaNutrition.png"
  },
  {
    "title": "Home & Patient Care",
    "key": "Home_Patient_Care",
    "image": "assets/category/medical/lab_wellness_img.png"
  },
  {
    "title": "Medical Devices",
    "key": "Medical_Devices",
    "image": "assets/category/medical/Medical_Devices.png"
  },
  {
    "title": "OTC Medicines",
    "key": "OTC_Medicines",
    "image": "assets/category/medical/OTC_Medicines.png"
  },
  {
    "title": "Personal & Baby Care",
    "key": "Personal_Baby_Care",
    "image": "assets/category/medical/Personal_Baby_Care.png"
  },
  {
    "title": "Wound Care & First Aid",
    "key": "Wound_Care_First_Aid",
    "image": "assets/category/medical/Wound_Care_First_Aid.png"
  },
];

String formattedCreatedAt(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return "";

  DateTime date = DateTime.parse(createdAt);
  String day = date.day.toString().padLeft(2, '0');
  String month = date.month.toString().padLeft(2, '0');
  String year = date.year.toString();

  return "$day/$month/$year";
}

String formatTime(String utcString) {
  try {
    final date =
        DateTime.parse(utcString).toLocal(); // convert to local timezone
    return DateFormat('hh:mm a').format(date); // e.g., 11:40 AM
  } catch (e) {
    return '';
  }
}

String formatNumberLikePost(int number) {
  if (number >= 10000000) {
    return '${(number / 10000000).toStringAsFixed((number % 10000000 == 0) ? 0 : 1)}M';
  } else if (number >= 100000) {
    return '${(number / 100000).toStringAsFixed((number % 100000 == 0) ? 0 : 1)}L';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed((number % 1000 == 0) ? 0 : 1)}k';
  } else {
    return number.toString();
  }
}

String getTimeAgo(String isoTime) {
  DateTime dateTime = DateTime.parse(isoTime).toLocal();
  DateTime now = DateTime.now();

  Duration diff = now.difference(dateTime);

  if (diff.inMinutes < 1) {
    return 'just now';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} h ago';
  } else {
    return DateFormat("dd MMM yyyy 'at' hh:mm a").format(dateTime);
  }
}

class MakeOrderType {
  static const String porter = 'Porter';
  static const String self = 'Self';
  static const String rider = 'Rider';
}

redirectToProfileScreen(
    {required String accountType,
    required String profileId,
    String? screenName}) {
  String? accountTypeData = accountType.toUpperCase();

  if (accountTypeData == AppConstants.individual) {
    if (userId == profileId) {
      debugPrint("SEGMENTS==== IF");

      Get.to(() => PersonalProfileSetupNewScreen(
            isScreenName: screenName,
          ));
    } else {
      debugPrint("SEGMENTS==== ELSE");

      Get.to(() => NewVisitProfileScreen(
            authorId: profileId,
            screenFromName: AppConstants.feedScreen,
            isScreenName: screenName,
          ));
    }
  }
  if (accountTypeData == AppConstants.business) {
    if (businessId == profileId) {
      Get.to(BusinessOwnProfileScreen(
        isScreenFrom: screenName,
      ));
    } else {
      Get.to(() => VisitBusinessProfileNew(
            businessId: profileId,
            screenName: AppConstants.feedScreen,
            isScreenFrom: screenName,
          ));
    }
  }
}

String getInitials(String? name) {
  if (name == null || name.isEmpty) return 'U';
  return name
      .trim()
      .split(' ')
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

Future createProfileScreen() async {
  Get.toNamed(RouteHelper.getCreateAccountTypeScreenRoute());

  // Get.to(() => const ChooseAccountTypeScreen());
}

void navigatePushTo(BuildContext context, Widget destination) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => destination,
    ),
  );
}

final List<String> gradingOptions = [
  "PERCENTAGE",
  "CGPA",
  "GPA",
  "GRADE",
];
List<String> months = [
  'MM',
  '01',
  '02',
  '03',
  '04',
  '05',
  '06',
  '07',
  '08',
  '09',
  '10',
  '11',
  '12'
];
List<String> years = ['YYYY'] +
    List.generate(30, (index) => (DateTime.now().year + index).toString());

// AppLocalizationsEn loc = AppLocalizationsEn();



openBusinessProfile({required String? businessUserId}) {
  if (businessId == businessUserId) {
    Get.to(() => BusinessOwnProfileScreen());
  } else {
    Get.to(() => VisitBusinessProfileNew(
          businessId: businessUserId ?? "",
          screenName: AppConstants.feedScreen,
        ));
  }
}

openPersonalProfile({required String? userID}) {
  if (userId == userID) {
    Get.to(() => PersonalProfileSetupNewScreen());
  } else {
    // Get.to(() => NewVisitProfileScreen(authorId: userID ?? "", screenFromName: '', channelId: channelId,));
    Get.to(() => NewVisitProfileScreen(
          authorId: userID ?? "",
          screenFromName: AppConstants.feedScreen,
        ));
  }
}

// Popup menu builders moved to PopupMenuBuilders class in popup_menu_builders.dart

bool isIndividual() {
  return (accountTypeGlobal.toUpperCase() == AppConstants.individual);
}

bool isBusiness() {
  return (accountTypeGlobal.toUpperCase() == AppConstants.business);
}

///Month 07-Feb-2025 formate
String formatMonthStringDate(String inputDate) {
  DateTime parsedDate = DateTime.parse(inputDate);
  return DateFormat('dd-MMM-yyyy').format(parsedDate);
}

// List<String> isShowOther = ["product", "service", "both"];
// List<String> isShowProduct = ["product", "service", "both"];
// List<String> isShowService = ["product", "service", "both", "food"];
List<String> isShowProduct = [AppConstants.product];
List<String> isShowService = [AppConstants.service];
List<String> isShowFood = [AppConstants.food];

String? businessType() {
  final controller = Get.find<ViewBusinessDetailsController>();
  return controller.businessProfileDetails.value?.data?.typeOfBusiness?.toLowerCase();
}

final List<SocialInputFieldsModel> selectedInputFieldsPersonalProfile = [
  SocialInputFieldsModel(
    name: AppStrings.youtube,
    icon: 'assets/svg/youtube_grey.svg',
    linkController: TextEditingController(),
  ),
];

// Individual Profession
const String SELF_EMPLOYED = "SELF_EMPLOYED";
const String SKILL_WORKER = "SKILL_WORKER";
const String GIG_WORKER = "GIG_WORKER";
const String PROFESSIONAL = "PROFESSIONAL";

// Constants
const String PRIVATE_JOB = "PRIVATE_JOB";
const String GOVERNMENT_JOB = "GOVERNMENT_JOB";
const String CONTENT_CREATOR = "CONTENT_CREATOR";
const String POLITICIAN = "POLITICIAN";
const String GOVTPSU = "GOVTPSU";
const String NGO = "NGO";
const String REG_UNION = "REG_UNION";
const String MEDIA = "MEDIA";
const String ARTIST = "ARTIST";
const String INDUSTRIALIST = "INDUSTRIALIST";
const String SOCIALIST = "SOCIALIST";
const String HOMEMAKER = "HOMEMAKER";
const String SKILLED_WORKER = "SKILLED_WORKER";
const String DIRECTOR = "DIRECTOR";
const String FARMER = "FARMER";
const String SENIOR_CITIZEN = "SENIOR_CITIZEN";
const String STUDENT = "STUDENT";
const String OTHERS = "OTHERS"; // keep Others last

// Self - Emplyed
const String ELECTRICIAN = "ELECTRICIAN";
const String PLUMBER = "PLUMBER";
const String TECHNICIAN = "TECHNICIAN";
const String MAID_FEMALE = "MAID_FEMALE";
const String CLEANER = "CLEANER";
const String CARPENTER = "CARPENTER";
const String BIKE_RIDER = "BIKE_RIDER";
const String CAR_TAXI = "CAR_DRIVER_TAXI";
const String GOODS_TAXI = "GOODS_TAXI";
const String AUTO_TAXI = "AUTO_TAXI";
const String MECHANIC = "MECHANIC";
const String CAR_TAXI_DRIVER = "CAR_TAXI_DRIVER";
const String TAILOR = "TAILOR";
const String BEAUTICIAN = "BEAUTICIAN";
const String HOME_RENOVATOR = "HOME_RENOVATOR";
const String PAINTER = "PAINTER";
const String LABOUR = "LABOUR";
const String GARDENER = "GARDENER";
const String SECURITY_PERSON = "SECURITY_PERSON";
const String INTERIOR_DESIGNER = "INTERIOR_DESIGNER";
const String DIGITAL_MARKETING = "DIGITAL_MARKETING";
const String TUTOR = "TUTOR";
const String CONSULTANT = "CONSULTANT";
const String OTHER = "OTHER";

const String HOSPITAL = "HOSPITAL";
const String PHARMACY = "PHARMACY";
const String LABTEST = "LABTEST";

// Consulatant
const String LEGAL_GOVT_CONSULTANT = "LEGAL_GOVT_CONSULTANT";
const String FINANCE_TAX_CONSULTANT = "FINANCE_TAX_CONSULTANT";
const String SPIRITUAL_CONSULTANT = "SPIRITUAL_CONSULTANT";
const String TRAINEE_CAREER_CONSULTANT = "TRAINEE_CAREER_CONSULTANT";
const String ADVERTISING_CONSULTANT = "ADVERTISING_CONSULTANT";
const String EVENT_PLANNER_DETECTIVE = "EVENT_PLANNER_DETECTIVE";
const String PROPERTY_BROKER_ARCHITECT = "PROPERTY_BROKER_ARCHITECT";
const String BUSINESS_HR_CONSULTANT = "BUSINESS_HR_CONSULTANT";
const String INDUSTRY_QUALITY_CONSULTANT = "INDUSTRY_QUALITY_CONSULTANT";
const String TECH_DIGITAL_FREELANCER = "TECH_DIGITAL_FREELANCER";

// Onboarding Category Constant
const String SOCIAL_PROFILE = "SOCIAL_PROFILE";
const String MANUFACTURING = "MANUFACTURING";

// Grocery
const String MOHALLA_KIRANA = "MOHALLA_KIRANA";
const String GENERAL_STORE = "GENERAL_STORE";
const String VEGETABLE_FRUIT = "VEGETABLE_FRUIT";
const String DAIRY_BAKERY = "DAIRY_BAKERY";
const String HOME_ESSENTIALS = "HOME_ESSENTIALS";
const String STATIONARY_SHOP = "STATIONARY_SHOP";

// Food
const String MULTI_CUISINE_RESTAURANT = "MULTI_CUISINE_RESTAURANT";
const String PURE_VEG_RESTAURANT = "PURE_VEG_RESTAURANT";
const String NON_VEG_RESTAURANT = "NON_VEG_RESTAURANT";
const String ECONOMY_DHABA = "ECONOMY_DHABA";
const String GARDEN_BUFFET_RESTAURANT = "GARDEN_BUFFET_RESTAURANT";
const String CLOUD_KITCHEN_MESS = "CLOUD_KITCHEN_MESS";
const String BREAKFAST_FAST_FOOD = "BREAKFAST_FAST_FOOD";
const String SWEET_NAMKEEN_SHOP = "SWEET_NAMKEEN_SHOP";
const String ICE_CREAM_CORNER = "ICE_CREAM_CORNER";
const String COFFEE_BEVERAGES_SHOP = "COFFEE_BEVERAGES_SHOP";


// Product
const String FURNITURE_HOME_DECOR = "FURNITURE_HOME_DECOR";
const String FASHION_LIFESTYLE = "FASHION_LIFESTYLE";
const String ELECTRONICS_APPLIANCES_STORE = "ELECTRONICS_APPLIANCES_STORE";
const String BOOKS_STATIONERY_GIFTS_STORE = "BOOKS_STATIONERY_GIFTS_STORE";
const String SPORTS_FITNESS_STORE = "SPORTS_FITNESS_STORE";
const String TOYS_BABY_PRODUCTS_STORE = "TOYS_BABY_PRODUCTS_STORE";
const String JEWELLERY_LUXURY_STORE = "JEWELLERY_LUXURY_STORE";
const String CONSTRUCTION_HOME_ESSENTIALS = "CONSTRUCTION_HOME_ESSENTIALS";
const String AUTOMOTIVE_STORE_SHOWROOM = "AUTOMOTIVE_STORE_SHOWROOM";
const String PET_SUPPLIES_STORE = "PET_SUPPLIES_STORE";
const String BEAUTY_COSMETICS = "BEAUTY_COSMETICS";
const String RELIGIOUS_SPECIALTY = "RELIGIOUS_SPECIALTY";
const String PACKAGING_DISPOSABLE = "PACKAGING_DISPOSABLE";
const String INDUSTRIAL_WHOLESALE = "INDUSTRIAL_WHOLESALE";
const String AGRICULTURE_FARMING = "AGRICULTURE_FARMING";
const String HOME_KITCHEN_UTENSILS = "HOME_KITCHEN_UTENSILS";
const String HOME_APPLIANCES_STORE = "HOME_APPLIANCES_STORE";
const String RELIGIOUS_AGRI_PETS = "RELIGIOUS_AGRI_PETS";
const String HOME_APPLIANCES_KITCHEN = "HOME_APPLIANCES_KITCHEN";
const String ELECTRONICS_MOBILE_STORE = "ELECTRONICS_MOBILE_STORE";
const String FURNITURE_CONSTRUCTION = "FURNITURE_CONSTRUCTION";
const String BEAUTY_WELLNESS = "BEAUTY_WELLNESS";
const String BOOKS_TOYS_BABY = "BOOKS_TOYS_BABY";

const String ALL_INDIVIDUAL = "ALL_INDIVIDUAL";
const String skilledWork = "skilledWork";
const String consultant = "consultant";
const String travel = "travel";

const String ALL_PRODUCT_PROFILE = "ALL_PRODUCT_PROFILE";
const String ALL_SERVICE_PROFILE = "ALL_SERVICE_PROFILE";

// Products Categories
const String ELECTRONICS_TECHNOLOGY = "ELECTRONICS_TECHNOLOGY";
const String HOME_KITCHEN_FURNITURE = "HOME_KITCHEN_FURNITURE";
const String FASHION_BEAUTY_PERSONAL_CARE = "FASHION_BEAUTY_PERSONAL_CARE";
const String BABY_KIDS_TOYS = "BABY_KIDS_TOYS";
const String SPORTS_HEALTH_OFFICE = "SPORTS_HEALTH_OFFICE";
const String TOOLS_GARDEN_PET = "TOOLS_GARDEN_PET";

// Services
const String CONSULTING_BUSINESS_SERVICES = "CONSULTING_BUSINESS_SERVICES";
const String BEAUTY_FITNESS_PERSONAL_CARE = "BEAUTY_FITNESS_PERSONAL_CARE";
const String HEALTHCARE_MEDICAL_SERVICES = "HEALTHCARE_MEDICAL_SERVICES";
const String REPAIR_ESSENTIAL_SERVICES = "REPAIR_ESSENTIAL_SERVICES";
const String HOME_SERVICES_CONTRACTORS = "HOME_SERVICES_CONTRACTORS";
const String IT_DIGITAL_SERVICES = "IT_DIGITAL_SERVICES";
const String MEDIA_NEWS_CREATIVE = "MEDIA_NEWS_CREATIVE";
const String TRAVEL_HOSPITALITY = "TRAVEL_HOSPITALITY";
const String REAL_ESTATE_PROPERTY = "REAL_ESTATE_PROPERTY";


const String INSTRUMENTS_PHARMACY_ = "INSTRUMENTS PHARMACY";
const String EDUCATION_TRAINING = "EDUCATION_TRAINING";
const String HOTELS_STAY_SERVICE = "HOTELS_STAY_SERVICE";
const String FINANCIAL_SERVICES = "FINANCIAL_SERVICES";
const String AUTOMOTIVE_SERVICES = "AUTOMOTIVE_SERVICES";
const String LOGISTICS_TRANSPORTATION = "LOGISTICS_TRANSPORTATION";
// const String CELEBRATION_EVENT_SERVICES = "CELEBRATION_EVENT_SERVICES";
const String TECHNICAL_TESTING_QUALITY_SERVICE =
    "TECHNICAL_TESTING_QUALITY_SERVICE";

// Manufacturing
const String FASHION_WEARABLES = "FASHION_WEARABLES";
const String FOOTWEAR = "FOOTWEAR";
const String HEALTH_WELLNESS_SELF_CARE = "HEALTH_WELLNESS_SELF_CARE";
const String TOOLS_HOME_IMPROVEMENT = "TOOLS_HOME_IMPROVEMENT";
const String BAGS_LUGGAGE = "BAGS_LUGGAGE";
const String BEAUTY_PERSONAL_CARE_MFG = "BEAUTY_PERSONAL_CARE_MFG";
const String HOUSEHOLD_CONSUMABLES = "HOUSEHOLD_CONSUMABLES";
const String CLEANING_UTILITY = "CLEANING_UTILITY";
const String HOME_LIVING = "HOME_LIVING";
const String FURNITURE = "FURNITURE";
const String BED_BATH_FURNISHINGS = "BED_BATH_FURNISHINGS";
const String ELECTRICAL_LIGHTING = "ELECTRICAL_LIGHTING";
const String HOME_APPLIANCES = "HOME_APPLIANCES";
const String MOBILES_SMART_GADGETS = "MOBILES_SMART_GADGETS";
const String COMPUTERS_ACCESSORIES = "COMPUTERS_ACCESSORIES";
const String GAMING_ENTERTAINMENT = "GAMING_ENTERTAINMENT";
const String TOYS_KIDS_BABY_PRODUCTS = "TOYS_KIDS_BABY_PRODUCTS";
const String SPORTS_FITNESS_OUTDOOR = "SPORTS_FITNESS_OUTDOOR";
const String JEWELLERY_ORNAMENTS = "JEWELLERY_ORNAMENTS";
const String WATCHES_EYEWEAR = "WATCHES_EYEWEAR";
const String STATIONERY_SCHOOL_OFFICE = "STATIONERY_SCHOOL_OFFICE";
const String AUTO_BIKE_ACCESSORIES = "AUTO_BIKE_ACCESSORIES";
const String GARDEN_OUTDOOR_LIVING = "GARDEN_OUTDOOR_LIVING";
const String GIFTS_FESTIVE_LIFESTYLE = "GIFTS_FESTIVE_LIFESTYLE";
const String TRAVEL_PERSONAL_UTILITY = "TRAVEL_PERSONAL_UTILITY";
const String SAFETY_SECURITY_PROTECTION = "SAFETY_SECURITY_PROTECTION";
const String MISCELLANEOUS_RETAIL = "MISCELLANEOUS_RETAIL";

int kmRadius1000 = 1000;
int kmRadius1500 = 1500;
int kmRadius5000 = 5000;

const HOME_MADE_PRODUCTS = "HOME_MADE_PRODUCTS";
const HOME_MADE_FOOD = "HOME_MADE_FOOD";
const HOME_SERVICES = "HOME_SERVICES";
const RENTAL_SERVICES = "RENTAL_SERVICES";
const TIFFIN = "TIFFIN";
const BAKERY = "BAKERY";
const SWEETS = "SWEETS";
const HOME_STAY = "HOME_STAY";
const Flat_ROOM = "Flat_ROOM";
const VEHICLE = "VEHICLE";
const FOOD = "FOOD";
const PRODUCT = "PRODUCT";
const SERVICE = "SERVICE";
const SERVICE_OTHERS = "SERVICE_OTHERS";

// Home Made Products
const HANDICRAFTS = "HANDICRAFTS";
const GIFT_ITEMS = "GIFT_ITEMS";
const TEXTILE_FASHION = "TEXTILE_FASHION";
const UTILITY_PRODUCTS = "UTILITY_PRODUCTS";
const ART_CRAFT = "ART_CRAFT";

// Bookings
const PARCEL_COURIER = "PARCEL_COURIER";
const TRANSPORT_VEHICLE = "TRANSPORT_VEHICLE";
const HOTEL_HOME_STAY = "HOTEL_HOME_STAY";

// Automotive Services
const String SALES_SECTOR = "SALES_SECTOR";
const String PARTS_SECTOR = "PARTS_SECTOR";
const String SERVICE_SECTOR = "SERVICE_SECTOR";
const String TRANSPORT_LOGISTIC = "TRANSPORT_LOGISTIC";
const String RENTAL_SECTOR = "RENTAL_SECTOR";
const String SUPPORT_SECTOR = "SUPPORT_SECTOR";

// Health Care
const String INSTRUMENTS_PHARMACY = "INSTRUMENTS_PHARMACY";
const String CLINIC_DOCTORS = "CLINIC_DOCTORS";
const String ALTERNATIVE_WELLNESS = "ALTERNATIVE_WELLNESS";
const String SURGICAL = "SURGICAL";
const String SUPPORT_SERVICES = "SUPPORT_SERVICES";

// Hotel
const String HOTELS_RESORT = "HOTELS";
// const String HOTELS_RESORT = "HOTELSRESORT";
const String ECONOMIC_STAYS = "ECONOMIC";
// const String ECONOMIC_STAYS = "ECONOMIC_STAYS";
const String HOSTELS_PAYING_GUEST = "PAYING";
// const String HOSTELS_PAYING_GUEST = "HOSTELS_PAYING_GUEST";
// const String ALTERNATIVE_STAYS = "ALTERNATIVE_STAYS";
// const String FUNCTIONS_VACATION = "FUNCTIONS_VACATION";
const String FUNCTIONS_VACATION = "FUNCTIONS";
const String CELEBRATION_EVENT_SERVICES = "CELEBRATION";
// const String CELEBRATION_EVENT_SERVICES = "CELEBRATION_EVENT_SERVICES";

// Education
const String SCHOOL_EDUCATION = "SCHOOL_EDUCATION";
const String COLLEGE_UNIVERSITY = "COLLEGE_UNIVERSITY";
const String TECHNICAL_SKILL_TRAINING = "TECHNICAL_SKILL_TRAINING";
const String COACHING_EXAM_PREPARATION = "COACHING_EXAM_PREPARATION";
const String CREATIVE_SPORT_HOBBY = "CREATIVE_SPORT_HOBBY";
const String PROFESSIONAL_SUPPORT_EDUCATION = "PROFESSIONAL_SUPPORT_EDUCATION";

double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Radius of Earth in kilometers
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final distance = R * c;

  return distance; // in kilometers
}

double _deg2rad(double deg) {
  return deg * pi / 180;
}

Set<String> isTempList = {};

void trackPostView(String postID) {
  if (kReleaseMode) {
    // call API asynchronously without blocking UI
    Future.microtask(() async {
      try {
        if (!isTempList.contains(postID)) {
          isTempList.add(postID);
          PostRepo().postByViewCountIDApi(id: postID);
        }
      } catch (e) {
        print("Failed to track view: $e");
      }
    });
  }
}

canGoogleMapOpen({required double latitude, required double longitude}) async {
  if (latitude != 0.0 && longitude != 0.0) {
    final Uri googleMapUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}");

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open Google Maps";
    }
  }
}

var SUPPORTED_LANGUAGES = [
  'Bengali',
  'Bhojpuri',
  'Dogri',
  'English',
  'Gujarati',
  'Hindi',
  'Kannada',
  'Kashmiri',
  'Konkani',
  'Malayalam',
  'Manipuri (Meitei)',
  'Marathi',
  'Nepali',
  'Odia',
  'Punjabi',
  'Sanskrit',
  'Santali',
  'Sindhi',
  'Tamil',
  'Telugu',
  'Urdu',
  'Marwadi',
  'Haryanvi'
];

final List<CommentTypeModel> emotionList = [
  CommentTypeModel(
      "Anger / Outrage", AppStrings.angerOutrage, AppIconAssets.emotionAnger),
  CommentTypeModel("Pride / Patriotism", AppStrings.pridePatriotism,
      AppIconAssets.emotionPatriotism),
  CommentTypeModel("Happiness / Celebration", AppStrings.happinessCelebration,
      AppIconAssets.emotionStorytelling),
  CommentTypeModel("Sadness / Sympathy", AppStrings.sadnessSympathy,
      AppIconAssets.emotionSympathy),
  CommentTypeModel("Protest / Rebellion", AppStrings.protestRebellion,
      AppIconAssets.emotionRebellion),
  CommentTypeModel(
      "Humor / Sarcasm", AppStrings.humorSarcasm, AppIconAssets.emotionSarcasm),
  CommentTypeModel("Poetic / Storytelling", AppStrings.poeticStorytelling,
      AppIconAssets.emotionStorytelling),
  CommentTypeModel("Informative / Educational",
      AppStrings.informativeEducational, AppIconAssets.emotionEducational),
  CommentTypeModel("Political / Opinionated", AppStrings.politicalOpinionated,
      AppIconAssets.emotionOpinionated),
];

class CommentTypeModel {
  final String sludId;
  final String name;
  final String icon;

  const CommentTypeModel(this.sludId, this.name, this.icon);
}

final List<CommentTypeModel> commentTypes = [
  CommentTypeModel(
      "Disagree", AppStrings.disagree, AppIconAssets.commentDisagree),
  CommentTypeModel(
      "Appreciate", AppStrings.appreciate, AppIconAssets.commentAppreciate),
  CommentTypeModel(
      "Criticise", AppStrings.criticise, AppIconAssets.commentCriticise),
  CommentTypeModel(
      "Question", AppStrings.question, AppIconAssets.commentQuestion),
  CommentTypeModel("Support", AppStrings.support, AppIconAssets.commentSupport),
  CommentTypeModel("Funny", AppStrings.funny, AppIconAssets.commentFunny),
  CommentTypeModel(
      "Inspired", AppStrings.inspired, AppIconAssets.commentInspired),
  CommentTypeModel("Angry", AppStrings.angry, AppIconAssets.commentAngry),
  CommentTypeModel("Suggest", AppStrings.suggest, AppIconAssets.commentSuggest),
  CommentTypeModel("Poetic / Storytelling", AppStrings.poeticStorytelling,
      AppIconAssets.emotionStorytelling),
];

bool isImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.tiff') ||
      lower.endsWith('.tif') ||
      lower.endsWith('.heic') ||
      lower.endsWith('.heif');
}

bool isVideoUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.flv') ||
      lower.endsWith('.wmv') ||
      lower.endsWith('.3gp');
}

class ChatEmitEvents {
  static const ChatList = "ChatList";
  static const screenRoom = "screenRoom";
  static const messageReceived = "messageReceived";
  static const messageViewed = "messageViewed";
  static const isOnlineFromChatList = "isOnlineFromChatList";
  static const newMessageReceived = "newMessageReceived";
  static const isOnLine = "isOnLine";
  static const messageStatusUpdate = "messageStatusUpdate";
  static const update_data = "update_data";
  static const newSelfPickupOrderReceived = "newSelfPickupOrderReceived";
  static const selfPickupOrderReady = "selfPickupOrderReady";
  static const newFoodPickupOrderReceived = "newFoodPickupOrderReceived";
  static const foodPickupOrderReady = "foodPickupOrderReady";
  static const newProductPickupOrderReceived = "newProductPickupOrderReceived";
  static const productPickupOrderReady = "productPickupOrderReady";

  // Signaling events
  static const isTyping = "isTyping";
  static const markConversationRead = "markConversationRead";
  static const unreadCountCleared = "unreadCountCleared";
  static const userLastSeenList = "userLastSeenList";

  // ── E2E Encryption Events (Phase 1–4) ─────────────────────────────────────
  // Events this client EMITS → server
  static const e2eMessageSend       = "message:send";         // Phase 3: send encrypted msg
  static const e2eMessageAck        = "message:ack";          // Phase 3: delivery ACK
  static const e2eMessageSyncComplete = "message:sync-complete"; // Phase 4: cursor advance

  // Events this client RECEIVES ← server
  static const e2eProtocolResolved      = "protocol:resolved";       // Phase 1
  static const e2eProtocolUpgrade       = "protocol:upgrade_available"; // Phase 1
  static const e2ePrekeyLow             = "prekey:low";              // Phase 2
  static const e2eMessageNew            = "message:new";             // Phase 3
  static const e2eMessageStatus         = "message:status";          // Phase 3
  static const e2eSyncComplete          = "sync:complete";           // Phase 4
}

class LiveTrackEmitEvents {
  static const updateLocation = "updateLocation";
  static const subscribeToProviders = "subscribeToProviders";
  static const locationUpdate = "locationUpdate";
}

final List<String> timeOptions = [
  '12:00 AM',
  '12:30 AM',
  '01:00 AM',
  '01:30 AM',
  '02:00 AM',
  '02:30 AM',
  '03:00 AM',
  '03:30 AM',
  '04:00 AM',
  '04:30 AM',
  '05:00 AM',
  '05:30 AM',
  '06:00 AM',
  '06:30 AM',
  '07:00 AM',
  '07:30 AM',
  '08:00 AM',
  '08:30 AM',
  '09:00 AM',
  '09:30 AM',
  '10:00 AM',
  '10:30 AM',
  '11:00 AM',
  '11:30 AM',
  '12:00 PM',
  '12:30 PM',
  '01:00 PM',
  '01:30 PM',
  '02:00 PM',
  '02:30 PM',
  '03:00 PM',
  '03:30 PM',
  '04:00 PM',
  '04:30 PM',
  '05:00 PM',
  '05:30 PM',
  '06:00 PM',
  '06:30 PM',
  '07:00 PM',
  '07:30 PM',
  '08:00 PM',
  '08:30 PM',
  '09:00 PM',
  '09:30 PM',
  '10:00 PM',
  '10:30 PM',
  '11:00 PM',
  '11:30 PM',
];

String formatClaimedAt(String claimedAt) {
  DateTime date = DateTime.parse(claimedAt).toLocal();
  DateTime now = DateTime.now();

  Duration diff = now.difference(date);
  int diffHours = diff.inHours;

  String formatTime(DateTime d) {
    int hour = d.hour;
    int minute = d.minute;
    String period = hour >= 12 ? "pm" : "am"; // lowercase

    hour = hour % 12;
    if (hour == 0) hour = 12;

    String minuteStr = minute.toString().padLeft(2, '0');

    return "$hour:$minuteStr $period";
  }

  // Less than 24 hours → show time
  if (diffHours < 24) {
    return formatTime(date);
  }

  // Between 24 and 48 hours → Yesterday
  if (diffHours >= 24 && diffHours < 48) {
    return "Yesterday";
  }

  // More than 48 hours → dd/MM/yy
  String day = date.day.toString().padLeft(2, '0');
  String month = date.month.toString().padLeft(2, '0');
  String year = date.year.toString().substring(2); // last 2 digits

  return "$day/$month/$year"; // WhatsApp-like
}

/// Business Categories

final List<OnboardingCategoryModel> serviceContactCategories = [
  OnboardingCategoryModel(
      name: 'All Service',
      slugId: ALL_PRODUCT_PROFILE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  ...findServiceByContactSubCate
];

final List<OnboardingCategoryModel> findServiceByContactSubCate = [
  OnboardingCategoryModel(
      name: 'Consulting',
      slugId: CONSULTING_BUSINESS_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Beauty',
      slugId: BEAUTY_FITNESS_PERSONAL_CARE,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Financial',
  //     slugId: FINANCIAL_SERVICES,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Service Centre',
      slugId: REPAIR_ESSENTIAL_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Home & Utility',
      slugId: HOME_SERVICES_CONTRACTORS,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'IT & Comm',
      slugId: IT_DIGITAL_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Publicity',
      slugId: MEDIA_NEWS_CREATIVE,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Automotive',
  //     slugId: AUTOMOTIVE_SERVICES,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Logistics',
  //     slugId: LOGISTICS_TRANSPORTATION,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Events',
  //     slugId: CELEBRATION_EVENT_SERVICES,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Tourism',
      slugId: TRAVEL_HOSPITALITY,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Real Estate',
      slugId: REAL_ESTATE_PROPERTY,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Quality Labs',
  //     slugId: TECHNICAL_TESTING_QUALITY_SERVICE,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
];

// --- OnBoarding Category ---

final List<OnboardingCategoryModel>
businessOnboardingEducationTrainingCategories = [
  OnboardingCategoryModel(
      name: AppStrings.schoolEducation,
      slugId: SCHOOL_EDUCATION,
      icon: OnboardingBusinessAssets.EduSchoolEducation,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: AppStrings.collageUniversity,
      slugId: COLLEGE_UNIVERSITY,
      icon: OnboardingBusinessAssets.EduUniversity,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: AppStrings.coachingInstitute,
      slugId: COACHING_EXAM_PREPARATION,
      icon: OnboardingBusinessAssets.EduCoaching,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: AppStrings.sportsAndHobby,
      slugId: CREATIVE_SPORT_HOBBY,
      icon: OnboardingBusinessAssets.EduSports,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: AppStrings.professionalLearn,
      slugId: PROFESSIONAL_SUPPORT_EDUCATION,
      icon: OnboardingBusinessAssets.EduProfessional,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: AppStrings.skillTraining,
      slugId: TECHNICAL_SKILL_TRAINING,
      icon: OnboardingBusinessAssets.EduSkill,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
];

final List<OnboardingCategoryModel>  jobCategories = [
  OnboardingCategoryModel(
      name: 'Full Time',
      slugId: '',
      icon: AppImageAssets.job_full_time,
      accountType: AppConstants.business,
     ),
  OnboardingCategoryModel(
      name: 'Part Time',
      slugId: '',
      icon: AppImageAssets.job_part_time,
      accountType: AppConstants.business,

      ),
  OnboardingCategoryModel(
      name: 'Remote',
      slugId: '',
      icon: AppImageAssets.job_remote,
      accountType: AppConstants.business,
     ),
  OnboardingCategoryModel(
      name: 'Onsite',
      slugId: '',
      icon: AppImageAssets.job_onsite,
      accountType: AppConstants.business,
),
  OnboardingCategoryModel(
      name: 'Near By',
      slugId: '',
      icon: AppImageAssets.job_near_by,
      accountType: AppConstants.business,
      ),

];

// final List<OnboardingCategoryModel> businessOnboardingProductsCategories = [
//   OnboardingCategoryModel(
//       name: 'Fashion, Footwear\n& Lifestyle',
//       slugId: FASHION_LIFESTYLE,
//       icon: OnboardingBusinessAssets.fashionAndLifestyle,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Electronics &\nGadgets',
//       slugId: ELECTRONICS_APPLIANCES_STORE,
//       icon: OnboardingBusinessAssets.electronicsAndAppliances,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Automotive &\nSpares',
//       slugId: AUTOMOTIVE_STORE_SHOWROOM,
//       icon: OnboardingBusinessAssets.automotiveShowroom,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Construction &\nHardware',
//       slugId: CONSTRUCTION_HOME_ESSENTIALS,
//       icon: OnboardingBusinessAssets.constructionAndHomeEssentials,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Home\nAppliances',
//       slugId: HOME_APPLIANCES_STORE,
//       icon: OnboardingBusinessAssets.homeAppliancesStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Furniture &\nFurnishing',
//       slugId: FURNITURE_HOME_DECOR,
//       icon: OnboardingBusinessAssets.furnitureAndHomedecor,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Jewellery &\nLuxury',
//       slugId: JEWELRY_LUXURY_STORE,
//       icon: OnboardingBusinessAssets.jeweleryAndLuxury,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Beauty &\nCosmetics',
//       slugId: BEAUTY_COSMETICS,
//       icon: OnboardingBusinessAssets.beautyAndCosmetics,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Books, Stationery\n&Gifts',
//       slugId: BOOKS_STATIONERY_GIFTS_STORE,
//       icon: OnboardingBusinessAssets.booksStationaryAndGifts,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Toys & Baby\nProducts',
//       slugId: TOYS_BABY_PRODUCTS_STORE,
//       icon: OnboardingBusinessAssets.toysAndBabyProducts,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Home Kitchen &\nUtensils',
//       slugId: HOME_KITCHEN_UTENSILS,
//       icon: OnboardingBusinessAssets.homeKitchenAndUtensils,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Sports &\nFitness',
//       slugId: SPORTS_FITNESS_STORE,
//       icon: OnboardingBusinessAssets.sportsAndFitnessStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Pet\nSupplies',
//       slugId: PET_SUPPLIES_STORE,
//       icon: OnboardingBusinessAssets.petAgricultureStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Religious &\nSpecialty',
//       slugId: RELIGIOUS_SPECIALTY,
//       icon: OnboardingBusinessAssets.religiousAndSpeciality,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Packaging &\nDisposable',
//       slugId: PACKAGING_DISPOSABLE,
//       icon: OnboardingBusinessAssets.packagingAndDisposable,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Agriculture &\nFarming',
//       slugId: AGRICULTURE_FARMING,
//       icon: OnboardingBusinessAssets.agricultureAndFarming,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Industrials &\nWholesale',
//       slugId: INDUSTRIAL_WHOLESALE,
//       icon: OnboardingBusinessAssets.industrialsSupplies,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
// ];

// final List<OnboardingCategoryModel> businessOnboardingGroceriesCategories = [
//   OnboardingCategoryModel(
//       name: 'Kirana Store',
//       slugId: KIRANA_STORE,
//       icon: OnboardingBusinessAssets.kiranaStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'General Store',
//       slugId: GENERAL_STORE,
//       icon: OnboardingBusinessAssets.generalStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Vegetable & Fruit',
//       slugId: VEGETABLE_FRUIT,
//       icon: OnboardingBusinessAssets.vegFruitStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Dairy & Bakery',
//       slugId: DAIRY_BAKERY,
//       icon: OnboardingBusinessAssets.dairyBakeryStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Home Essentials',
//       slugId: HOME_ESSENTIALS,
//       icon: OnboardingBusinessAssets.homeEssentialsStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Stationary Shop',
//       slugId: STATIONARY_SHOP,
//       icon: OnboardingBusinessAssets.stationaryStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
// ];

// final List<OnboardingCategoryModel>businessOnboardingHealthcareSectorsCategories = [
//   OnboardingCategoryModel(
//       name: 'Hospital',
//       slugId: HOSPITAL_SECTOR,
//       icon: OnboardingBusinessAssets.healthcareMedicalServices,
//       // Use your relevant asset
//       accountType: AppConstants.business,
//       businessType: BusinessType.Healthcare),
//   OnboardingCategoryModel(
//       name: 'Pharmacy',
//       slugId: INSTRUMENTS_PHARMACY,
//       icon: OnboardingBusinessAssets.healthcareMedicalServices,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Healthcare),
//   OnboardingCategoryModel(
//       name: 'Diagonals',
//       slugId: DIAGNOSTIC_SECTOR,
//       icon: OnboardingBusinessAssets.healthcareMedicalServices,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Healthcare),
//   OnboardingCategoryModel(
//       name: 'Clinic/Doctors',
//       slugId: CLINIC_DOCTORS,
//       icon: OnboardingBusinessAssets.healthcareMedicalServices,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Healthcare),
//   OnboardingCategoryModel(
//       name: 'Alternative',
//       slugId: ALTERNATIVE_WELLNESS,
//       icon: OnboardingBusinessAssets.healthcareMedicalServices,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Healthcare),
//   OnboardingCategoryModel(
//       name: 'Support Services',
//       slugId: SUPPORT_SERVICES,
//       icon: OnboardingBusinessAssets.healthcareMedicalServices,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Healthcare),
// ];

// final List<OnboardingCategoryModel> businessOnboardingManufacturingCategories =
//     [
//   OnboardingCategoryModel(
//       name: 'Fashion &\nWearables',
//       slugId: FASHION_WEARABLES,
//       icon: OnboardingBusinessAssets.fashionAndWearables,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Footwear\nProduct',
//       slugId: FOOTWEAR,
//       icon: OnboardingBusinessAssets.footwear,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Health, Wellness\n& Self-Care',
//       slugId: HEALTH_WELLNESS_SELF_CARE,
//       icon: OnboardingBusinessAssets.healthWellnessAndSelfcare,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Tools &\nHome Improvement',
//       slugId: TOOLS_HOME_IMPROVEMENT,
//       icon: OnboardingBusinessAssets.toolsAndHomeImprovement,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Bags &\nLuggage',
//       slugId: BAGS_LUGGAGE,
//       icon: OnboardingBusinessAssets.bagsAndLuggage,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Beauty &\nPersonal Care',
//       slugId: BEAUTY_PERSONAL_CARE_MFG,
//       icon: OnboardingBusinessAssets.beautyAndPersonalCareMfg,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Household\nConsumables',
//       slugId: HOUSEHOLD_CONSUMABLES,
//       icon: OnboardingBusinessAssets.householdConsumables,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Cleaning &\nUtility',
//       slugId: CLEANING_UTILITY,
//       icon: OnboardingBusinessAssets.cleaningAndUtility,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Home &\nLiving',
//       slugId: HOME_LIVING,
//       icon: OnboardingBusinessAssets.homeAndLiving,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Furniture\nStore',
//       slugId: FURNITURE,
//       icon: OnboardingBusinessAssets.furniture,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Bed, Bath\n& Furnishings',
//       slugId: BED_BATH_FURNISHINGS,
//       icon: OnboardingBusinessAssets.bedBathAndFurnishing,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Electrical\n& Lighting',
//       slugId: ELECTRICAL_LIGHTING,
//       icon: OnboardingBusinessAssets.electricalAndLightning,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Home Appliances\n(Small)',
//       slugId: HOME_APPLIANCES,
//       icon: OnboardingBusinessAssets.homeAppliances,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Mobiles & Smart\nGadgets',
//       slugId: MOBILES_SMART_GADGETS,
//       icon: OnboardingBusinessAssets.mobileAndSmartGadgets,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Computers &\nAccessories',
//       slugId: COMPUTERS_ACCESSORIES,
//       icon: OnboardingBusinessAssets.computerAndAccessories,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Gaming &\nEntertainment',
//       slugId: GAMING_ENTERTAINMENT,
//       icon: OnboardingBusinessAssets.gamingAndEntertainment,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Toys, Kids &\nBaby Products',
//       slugId: TOYS_KIDS_BABY_PRODUCTS,
//       icon: OnboardingBusinessAssets.toysKidsAndBabyProducts,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Sports Fitness\n& Outdoor',
//       slugId: SPORTS_FITNESS_OUTDOOR,
//       icon: OnboardingBusinessAssets.sportsFitnessAndOutdoors,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Jewellery &\nOrnaments',
//       slugId: JEWELLERY_ORNAMENTS,
//       icon: OnboardingBusinessAssets.jewelleryAndOrnaments,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Watches &\nEyewear',
//       slugId: WATCHES_EYEWEAR,
//       icon: OnboardingBusinessAssets.watchesAndEyewear,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Stationery School\n& office',
//       slugId: STATIONERY_SCHOOL_OFFICE,
//       icon: OnboardingBusinessAssets.stationarySchoolAndOffice,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Auto & Bike\nAccessories',
//       slugId: AUTO_BIKE_ACCESSORIES,
//       icon: OnboardingBusinessAssets.autoAndBikeAccessories,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Garden, Balcony\n& Outdoor Living',
//       slugId: GARDEN_OUTDOOR_LIVING,
//       icon: OnboardingBusinessAssets.gardenBalconyAndOutdoorLiving,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Gifts, Festive\n& Lifestyle',
//       slugId: GIFTS_FESTIVE_LIFESTYLE,
//       icon: OnboardingBusinessAssets.giftsFestiveAndLifestyle,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Travel &\nPersonal Utility',
//       slugId: TRAVEL_PERSONAL_UTILITY,
//       icon: OnboardingBusinessAssets.travelAndPersonalUtility,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Safety, Security\n& Protection (Home)',
//       slugId: SAFETY_SECURITY_PROTECTION,
//       icon: OnboardingBusinessAssets.safetySecurityAndProtection,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
//   OnboardingCategoryModel(
//       name: 'Miscellaneous\nRetail',
//       slugId: MISCELLANEOUS_RETAIL,
//       icon: OnboardingBusinessAssets.miscellaneousRetails,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Manufacturing),
// ];

/*
final List<OnboardingCategoryModel> businessOnboardingHospitalityStayCategories = [
  OnboardingCategoryModel(
      name: 'Hotel/\nResort',
      slugId: HOTELS_RESORT,
      icon: AppImageAssets.hotelStay,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
  OnboardingCategoryModel(
      name: 'Economic\nStay',
      slugId: ECONOMIC_STAYS,
      icon: AppImageAssets.economyStay,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
  OnboardingCategoryModel(
      name: 'Function &\nVacation',
      slugId: FUNCTIONS_VACATION,
      icon: AppImageAssets.functionsVacation,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
  OnboardingCategoryModel(
      name: 'Hostel/\nPG',
      slugId: HOSTELS_PAYING_GUEST,
      icon: AppImageAssets.hostelsAndPG,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
  OnboardingCategoryModel(
      name: 'Alternative\nStay',
      slugId: ALTERNATIVE_STAYS,
      icon: AppImageAssets.alternativeStays,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
  OnboardingCategoryModel(
      name: 'Celebration\n& Event',
      slugId: CELEBRATION_EVENT_SERVICES,
      icon: AppImageAssets.celebrationEvent,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
];
*/

// final List<OnboardingCategoryModel>
//     businessOnboardingFinancialSectorsCategories = [
//   OnboardingCategoryModel(
//       name: 'Banking\nSector',
//       slugId: BANKING_SECTOR,
//       icon: OnboardingBusinessAssets.consultingFirm,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Finance),
//   OnboardingCategoryModel(
//       name: 'Loan\nSector',
//       slugId: LOAN_SECTOR,
//       icon: OnboardingBusinessAssets.consultingFirm,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Finance),
//   OnboardingCategoryModel(
//       name: 'Insurance\nSector',
//       slugId: INSURANCE_SECTOR,
//       icon: OnboardingBusinessAssets.consultingFirm,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Finance),
//   OnboardingCategoryModel(
//       name: 'Capital\nMarket',
//       slugId: CAPITAL_MARKET,
//       icon: OnboardingBusinessAssets.consultingFirm,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Finance),
//   OnboardingCategoryModel(
//       name: 'Data\nSector',
//       slugId: DATA_SECTOR,
//       icon: OnboardingBusinessAssets.consultingFirm,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Finance),
//   OnboardingCategoryModel(
//       name: 'Advisory\nSector',
//       slugId: ADVISORY_SECTOR,
//       icon: OnboardingBusinessAssets.consultingFirm,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Finance),
// ];

// --- End ---

// final List<OnboardingCategoryModel> businessProductStoreCategories = [
//   OnboardingCategoryModel(
//     // name: AppStrings.fashionLifestyle,
//       name: 'Fashion LifeStyle Store',
//       slugId: FASHION_LIFESTYLE,
//       icon: AppImageAssets.fashionLifestyle,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//     // name: AppStrings.electronicsAppliances,
//       name: 'Electronics Mobile Store',
//       slugId: ELECTRONICS_MOBILE_STORE,
//       icon: AppImageAssets.electronicsApplianceStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//     // name: AppStrings.furnitureHomeDecor,
//       name: 'Furniture Construction Store',
//       slugId: FURNITURE_CONSTRUCTION,
//       icon: AppImageAssets.furnitureHomeDecor,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Jewellery Luxury Store',
//       slugId: JEWELRY_LUXURY_STORE,
//       icon: AppImageAssets.jewelleryLuxuryStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Beauty Wellness Store',
//       slugId: BEAUTY_WELLNESS,
//       icon: AppImageAssets.beautyAndCosmetics,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//     // name: AppStrings.booksStationaryGifts,
//       name: 'Books Toys & Baby Products',
//       slugId: BOOKS_TOYS_BABY,
//       icon: AppImageAssets.booksStationary,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Home Kitchen',
//       slugId: HOME_APPLIANCES_KITCHEN,
//       icon: AppImageAssets.homeKitchenAndUtensils,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Sports & Fitness Store',
//       slugId: SPORTS_FITNESS_STORE,
//       icon: AppImageAssets.sportsFitnessStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Religious, Agriculture & Pets',
//       slugId: RELIGIOUS_AGRI_PETS,
//       icon: AppImageAssets.petSuppliesStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
//   OnboardingCategoryModel(
//       name: 'Industrials Wholesale',
//       slugId: INDUSTRIAL_WHOLESALE,
//       icon: AppImageAssets.industrialWholesale,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Product),
// ];

// businessProductsCategories moved to dynamic API list in AuthController.businessOnboardingProductsCategories

/// tagId → local icon mapping for product categories
final Map<String, String> productCategoryIcons = {
  ELECTRONICS_MOBILE_STORE: AppImageAssets.electronicsApplianceStore,
  FURNITURE_CONSTRUCTION: AppImageAssets.furnitureHomeDecor,
  // FASHION_LIFESTYLE: AppImageAssets.fashionLifestyle, // will changed
  FASHION_LIFESTYLE: AppImageAssets.artsCraftsSewing, // will changed
  JEWELLERY_LUXURY_STORE: AppImageAssets.jewelleryLuxuryStore,
  BEAUTY_WELLNESS: AppImageAssets.beautyAndCosmetics,
  BOOKS_TOYS_BABY: AppImageAssets.booksStationary,
  HOME_APPLIANCES_KITCHEN: AppImageAssets.homeKitchenUtensils,
  SPORTS_FITNESS_STORE: AppImageAssets.sportsFitnessStore,
  RELIGIOUS_AGRI_PETS: AppImageAssets.farmingLawnGarden,
  INDUSTRIAL_WHOLESALE: AppImageAssets.industrialWholesale,
};

String getProductCategoryIcon(String? tagId) {
  return productCategoryIcons[tagId] ?? '';
}

/// tagId → local icon mapping for service categories (Find Services
/// grid on the Discover home).
final Map<String, String> serviceCategoryIcons = {
  BEAUTY_FITNESS_PERSONAL_CARE: OnboardingBusinessAssets.beautyAndPersonalCare,
  CONSULTING_BUSINESS_SERVICES: OnboardingBusinessAssets.consultingFirm,
  REPAIR_ESSENTIAL_SERVICES: OnboardingBusinessAssets.serviceCenterAndEssentialUtils,
  HOME_SERVICES_CONTRACTORS: OnboardingBusinessAssets.homeServiceAndUtility,
  IT_DIGITAL_SERVICES: OnboardingBusinessAssets.itAndCommunication,
  MEDIA_NEWS_CREATIVE: OnboardingBusinessAssets.mediaPublicityAndCreative,
  TRAVEL_HOSPITALITY: OnboardingBusinessAssets.tourTravelsAndTourism,
  REAL_ESTATE_PROPERTY: OnboardingBusinessAssets.realEstateProperty,
  // TECHNICAL_TESTING_QUALITY_SERVICE: OnboardingBusinessAssets.technicalTestingAndQualityLabs,
};

String getServiceCategoryIcon(String? tagId) {
  return serviceCategoryIcons[tagId] ?? '';
}

final List<OnboardingCategoryModel> professionalContactCategories = [
  OnboardingCategoryModel(
      name: 'All',
      slugId: ALL_INDIVIDUAL,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Skilled Work',
      slugId: skilledWork,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Consultant',
      slugId: consultant,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Travel',
      slugId: travel,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
];

final List<OnboardingCategoryModel> othersContactCategories = [
  OnboardingCategoryModel(
      name: 'Healthcare',
      slugId: HEALTHCARE_MEDICAL_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Healthcare),
  OnboardingCategoryModel(
      name: 'Hotels & Stay',
      slugId: HOTELS_STAY_SERVICE,
      accountType: AppConstants.business,
      businessType: BusinessType.Motel),
  OnboardingCategoryModel(
      name: 'Education',
      slugId: EDUCATION_TRAINING,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: 'Social',
      slugId: "social",
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
];

final List<OnboardingCategoryModel> fashionContactCategories = [
  OnboardingCategoryModel(
      name: 'All Product',
      slugId: ALL_PRODUCT_PROFILE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  ...findShoppingByContactCate
];

final List<OnboardingCategoryModel> findShoppingByContactCate = [
  OnboardingCategoryModel(
      name: 'Fashion',
      slugId: FASHION_LIFESTYLE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Electronics',
      slugId: ELECTRONICS_APPLIANCES_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Spare Parts',
      slugId: AUTOMOTIVE_STORE_SHOWROOM,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Construction',
      slugId: CONSTRUCTION_HOME_ESSENTIALS,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Appliances',
      slugId: HOME_APPLIANCES_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Furniture',
      slugId: FURNITURE_HOME_DECOR,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Jewellery',
      slugId: JEWELLERY_LUXURY_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Cosmetics',
      slugId: BEAUTY_COSMETICS,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Stationery',
      slugId: BOOKS_STATIONERY_GIFTS_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Toys',
      slugId: TOYS_BABY_PRODUCTS_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Home Kitchen',
      slugId: HOME_APPLIANCES_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Sports',
      slugId: SPORTS_FITNESS_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Pets',
      slugId: PET_SUPPLIES_STORE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Religious',
      slugId: RELIGIOUS_SPECIALTY,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Packaging',
      slugId: PACKAGING_DISPOSABLE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Agriculture',
      slugId: AGRICULTURE_FARMING,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Industrials',
      slugId: INDUSTRIAL_WHOLESALE,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
];


/// Individual Categories

// --- OnBoarding Category ---
/*
final List<OnboardingCategoryModel> individualOnboardingProfilesCategory = [
  OnboardingCategoryModel(
    name: 'Social profile',
    slugId: SOCIAL_PROFILE,
    icon: OnboardingIndividualAssets.socialProfile,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Skill Work',
    slugId: SKILL_WORKER,
    icon: OnboardingIndividualAssets.plumber,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Self Employed',
    slugId: GIG_WORKER,
    icon: OnboardingIndividualAssets.selfEmployee,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Professional/\nConsultant',
    slugId: CONSULTANT,
    icon: OnboardingIndividualAssets.consultant,
    accountType: AppConstants.individual,
  ),
];
*/

// final List<OnboardingCategoryModel> individualOnboardingSocialProfileList = [
//   OnboardingCategoryModel(
//     name: AppStrings.politician,
//     slugId: POLITICIAN,
//     // icon: OnboardingIndividualAssets.politician,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.contentCreator,
//     slugId: CONTENT_CREATOR,
//     // icon: OnboardingIndividualAssets.contentCreator,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.govtEmployee,
//     slugId: GOVERNMENT_JOB,
//     // icon: OnboardingIndividualAssets.govtEmp,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.pvtEmployee,
//     slugId: PRIVATE_JOB,
//     // icon: OnboardingIndividualAssets.pvtEmp,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.journalist,
//     slugId: MEDIA,
//     // icon: OnboardingIndividualAssets.journalist,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.artist,
//     slugId: ARTIST,
//     // icon: OnboardingIndividualAssets.artist,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.director,
//     slugId: DIRECTOR,
//     // icon: OnboardingIndividualAssets.director,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.industrialist,
//     slugId: INDUSTRIALIST,
//     // icon: OnboardingIndividualAssets.industrialist,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.socialist,
//     slugId: SOCIALIST,
//     // icon: OnboardingIndividualAssets.socialist,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.student,
//     slugId: STUDENT,
//     // icon: OnboardingIndividualAssets.student,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.homeMaker,
//     slugId: HOMEMAKER,
//     // icon: OnboardingIndividualAssets.homeMaker,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.farmer,
//     slugId: FARMER,
//     // icon: OnboardingIndividualAssets.farmer,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.ngo,
//     slugId: NGO,
//     // icon: OnboardingIndividualAssets.ngo,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.societyOrUnion,
//     slugId: REG_UNION,
//     // icon: OnboardingIndividualAssets.society,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.govtDepartment,
//     slugId: GOVTPSU,
//     // icon: OnboardingIndividualAssets.govtDept,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: AppStrings.seniorCitizen,
//     slugId: SENIOR_CITIZEN,
//     // icon: OnboardingIndividualAssets.seniorCitizen,
//     individualType: IndividualProfileType.SOCIAL_PROFILE,
//     accountType: AppConstants.individual,
//   ),
// ];
//
// final List<OnboardingCategoryModel> individualOnboardingGigWorkList = [
//   OnboardingCategoryModel(
//     name: 'Bike Rider',
//     slugId: BIKE_RIDER,
//     icon: OnboardingIndividualAssets.bikeRider,
//     individualType: IndividualProfileType.GIG_WORKER,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: 'Car Driver',
//     slugId: CAR_TAXI,
//     icon: OnboardingIndividualAssets.taxiCarDriver,
//     individualType: IndividualProfileType.GIG_WORKER,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: 'Goods Transporter',
//     slugId: GOODS_TAXI,
//     icon: OnboardingIndividualAssets.goodsSupplier,
//     individualType: IndividualProfileType.GIG_WORKER,
//     accountType: AppConstants.individual,
//   ),
//   OnboardingCategoryModel(
//     name: 'Auto Driver',
//     slugId: AUTO_TAXI,
//     icon: OnboardingIndividualAssets.autoERickshaw,
//     individualType: IndividualProfileType.GIG_WORKER,
//     accountType: AppConstants.individual,
//   ),
// ];

/// tagId → local icon mapping for individual professions
final Map<String, String> individualProfessionIcons = {
  // Skill Work / Self Employed
  ELECTRICIAN: OnboardingIndividualAssets.electrician,
  PLUMBER: OnboardingIndividualAssets.plumber,
  MAID_FEMALE: OnboardingIndividualAssets.maid,
  MECHANIC: OnboardingIndividualAssets.mechanic,
  TECHNICIAN: OnboardingIndividualAssets.technician,
  PAINTER: OnboardingIndividualAssets.painter,
  CARPENTER: OnboardingIndividualAssets.carpenter,
  HOME_RENOVATOR: OnboardingIndividualAssets.homeRenovator,
  LABOUR: OnboardingIndividualAssets.labour,
  GARDENER: OnboardingIndividualAssets.gardener,
  SECURITY_PERSON: OnboardingIndividualAssets.securityPerson,
  CLEANER: OnboardingIndividualAssets.cleaner,
  // Gig Work
  BIKE_RIDER: OnboardingIndividualAssets.bikeRider,
  CAR_TAXI: OnboardingIndividualAssets.taxiCarDriver,
  GOODS_TAXI: OnboardingIndividualAssets.goodsSupplier,
  AUTO_TAXI: OnboardingIndividualAssets.autoERickshaw,
  // Professional / Consultation
  LEGAL_GOVT_CONSULTANT: OnboardingIndividualAssets.legalGovtConsultant,
  FINANCE_TAX_CONSULTANT: OnboardingIndividualAssets.financeTaxConsultant,
  SPIRITUAL_CONSULTANT: OnboardingIndividualAssets.spiritualConsultant,
  TRAINEE_CAREER_CONSULTANT: OnboardingIndividualAssets.traineeCareerConsultant,
  ADVERTISING_CONSULTANT: OnboardingIndividualAssets.advertisingConsultant,
  EVENT_PLANNER_DETECTIVE: OnboardingIndividualAssets.eventPlanDetective,
  PROPERTY_BROKER_ARCHITECT: OnboardingIndividualAssets.propertyBrokerArchitect,
  BUSINESS_HR_CONSULTANT: OnboardingIndividualAssets.businessHrConsultant,
  INDUSTRY_QUALITY_CONSULTANT: OnboardingIndividualAssets.industryQualityConsultant,
  TECH_DIGITAL_FREELANCER: OnboardingIndividualAssets.techDigitalFreelancer,
};

String getIndividualProfessionIcon(String? tagId) {
  return individualProfessionIcons[tagId] ?? '';
}

final List<OnboardingCategoryModel> healthCareList = [
  OnboardingCategoryModel(
    name: 'Hospitals',
    slugId: HOSPITAL,
    icon: "assets/category/medical/health_hospitals.png",
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Doctors',
    slugId: CLINIC_DOCTORS,
    icon: "assets/category/medical/health_doctors.png",
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Labs',
    slugId: LABTEST,
    icon: "assets/category/medical/health_labs.png",
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Pharmacy',
    slugId: PHARMACY,
    icon: "assets/category/medical/health_pharmacy.png",
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Surgical',
    slugId: SURGICAL,
    icon: "assets/category/medical/health_surgical.png",
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  // OnboardingCategoryModel(
  //   name: 'Others',
  //   slugId: EVENT_PLANNER_DETECTIVE,
  //   icon: OnboardingIndividualAssets.eventPlanDetective,
  //   flagIcon: AppImageAssets.eventPlanDetective,
  //   individualType: IndividualType.PROFESSIONAL,
  //   accountType: AppConstants.individual,
  // ),
];

// --- End ---

final homeServiceLiteCategories = [BEAUTICIAN, TAILOR, OTHER];

final List<OnboardingCategoryModel> homeServicesCategories = [
  // CollapsibleGridModel(
  //     name: AppStrings.counsellingConsulting,
  //     slugId: CONSULTANT,
  //     icon: AppImageAssets.consultation
  // ),
  // OnboardingCategoryModel(
  //     name: AppStrings.tuitionClassesOnlineOffline,
  //     slugId: TUTOR,
  //     icon: AppImageAssets.tutor,
  //     accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: AppStrings.beautyServices,
      slugId: BEAUTICIAN,
      icon: OnboardingIndividualAssets.beautician,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: AppStrings.tailoring,
      slugId: TAILOR,
      icon: OnboardingIndividualAssets.tailoring,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: 'Other Services',
      slugId: OTHER,
      icon: AppIconAssets.staggeredIcon,
      accountType: AppConstants.individual),
  // OnboardingCategoryModel(
  //     name: 'Matchmaking Consultant',
  //     slugId: DIGITAL_MARKETING,
  //     icon: AppImageAssets.digitalMarketing,
  //     accountType: AppConstants.individual
  // ),
  // OnboardingCategoryModel(
  //     name: 'Event Planner',
  //     slugId: INTERIOR_DESIGNER,
  //     icon: AppImageAssets.interiorDesigner,
  //     accountType: AppConstants.individual
  // ),
  // OnboardingCategoryModel(
  //     name: 'Interior Designer',
  //     slugId: INTERIOR_DESIGNER,
  //     icon: AppImageAssets.interiorDesigner,
  //     accountType: AppConstants.individual
  // ),
  // OnboardingCategoryModel(
  //     name: 'Designer Planner',
  //     slugId: INTERIOR_DESIGNER,
  //     icon: AppImageAssets.interiorDesigner,
  //     accountType: AppConstants.individual
  // ),
  // OnboardingCategoryModel(
  //     name: 'Astrologer',
  //     slugId: INTERIOR_DESIGNER,
  //     icon: AppImageAssets.interiorDesigner,
  //     accountType: AppConstants.individual
  // ),
];

final List<CollapsibleGridModel> homeMadeProductsCategories = [
  CollapsibleGridModel(
    name: 'Handicrafts',
    slugId: HANDICRAFTS,
    icon: AppImageAssets.handicraft,
  ),
  CollapsibleGridModel(
    name: 'Gift Items',
    slugId: GIFT_ITEMS,
    icon: AppImageAssets.giftItems,
  ),
  CollapsibleGridModel(
    name: 'Textile & Fashion',
    slugId: TEXTILE_FASHION,
    icon: AppImageAssets.fashionLifestyle,
  ),
  CollapsibleGridModel(
    name: 'Utility Products',
    slugId: UTILITY_PRODUCTS,
    icon: AppImageAssets.utilityProducts,
  ),
  CollapsibleGridModel(
    name: 'Art & Craft',
    slugId: ART_CRAFT,
    icon: AppImageAssets.artCrafts,
  ),
];

final List<CollapsibleGridModel> homeMadeItemsCategories = [
  // CollapsibleGridModel(
  //     name: 'Home Made\nFood',
  //     slugId: FOOD,
  //     icon: AppImageAssets.homeMadeFoodBanner),
  CollapsibleGridModel(
      name: 'Home Made\nProducts',
      slugId: PRODUCT,
      icon: AppImageAssets.homeMadeProductsBanner),
  CollapsibleGridModel(
      name: 'Home\nServices',
      slugId: SERVICE,
      icon: AppImageAssets.homeServicesBanner),
];

final discoverShownStayCategories = [
  HOTELS_RESORT,
  FUNCTIONS_VACATION, HOSTELS_PAYING_GUEST, ECONOMIC_STAYS
  // AppConstants.property,
  // AppConstants.flat,
  // AppConstants.vehicle
];

class PropertyTileData {
  final String image;
  final String label;
  final bool isSale;
  final String listingType;
  final String propertyType;

  const PropertyTileData({
    required this.image,
    required this.label,
    required this.isSale,
    required this.listingType,
    required this.propertyType,
  });
}

final List<PropertyTileData> propertyDiscoverTiles = [
  PropertyTileData(image: AppImageAssets.propertyHouseSell, label: 'Houses & Apartments', isSale: true, listingType: 'Sell', propertyType: 'HouseAndApartment'),
  PropertyTileData(image: AppImageAssets.propertyHouseRent, label: 'Houses & Apartments', isSale: false, listingType: 'Rent', propertyType: 'HouseAndApartment'),
  PropertyTileData(image: AppImageAssets.propertyNewProjectSell, label: 'New Projects & Properties', isSale: true, listingType: 'Sell', propertyType: 'NewProjectsAndProperties'),
  PropertyTileData(image: AppImageAssets.propertyLandPlotSell, label: 'Lands & Plots', isSale: true, listingType: 'Sell', propertyType: 'LandAndPlots'),
  PropertyTileData(image: AppImageAssets.propertyShopOfficeRent, label: 'Shops & Offices', isSale: false, listingType: 'Rent', propertyType: 'ShopAndOffices'),
  PropertyTileData(image: AppImageAssets.propertyShopOfficeSell, label: 'Shops & Offices', isSale: true, listingType: 'Sell', propertyType: 'ShopAndOffices'),
  PropertyTileData(image: AppImageAssets.propertyLandPlotRent, label: 'Lands & Plots', isSale: false, listingType: 'Rent', propertyType: 'LandAndPlots'),
  PropertyTileData(image: AppImageAssets.propertyPgRent, label: 'PG & Guest House', isSale: false, listingType: 'Rent', propertyType: 'PGAndGuestHouse'),
];

final List<OnboardingCategoryModel> stayItemsCategories = [
  OnboardingCategoryModel(
      name: 'Hotel Stay',
      slugId: "HOTEL",
      // slugId: HOTELS_RESORT,
      icon: AppImageAssets.hotelStay,
      colorCode: Color(0xFFEBF5FF),
      subtitle: "Premium Rooms",
      accountType: AppConstants.business),
  OnboardingCategoryModel(
      name: 'Home Stay',
      slugId: ECONOMIC_STAYS,
      icon: AppImageAssets.economyStay,
      colorCode: Color(0xFFE6FAF3),
      subtitle: "Cozy & local",
      accountType: AppConstants.business),
  OnboardingCategoryModel(
      name: 'Hostels & PG',
      slugId: HOSTELS_PAYING_GUEST,
      icon: AppImageAssets.hostelsAndPG,
      colorCode: Color(0xFFFFE8E8),
      subtitle: "Long term stay",
      accountType: AppConstants.business),
  OnboardingCategoryModel(
      name: 'Functions & Vacation',
      slugId: FUNCTIONS_VACATION,
      icon: AppImageAssets.functionsVacation,
      colorCode: Color(0xFFFFF2E3),
      subtitle: "Function Hall",
      accountType: AppConstants.business),
  // OnboardingCategoryModel(
  //     name: 'Alternative Stays',
  //     slugId: ALTERNATIVE_STAYS,
  //     icon: AppImageAssets.alternative_stays,
  //     accountType: AppConstants.business),
  // OnboardingCategoryModel(
  //     name: 'Celebration\n& Event',
  //     slugId: CELEBRATION_EVENT_SERVICES,
  //     icon: AppImageAssets.hotel_event,
  //     accountType: AppConstants.business),
  /*  OnboardingCategoryModel(
      name: 'Home Stay',
      slugId: AppConstants.property,
      icon: AppImageAssets.homeStay,
      accountType: AppConstants.individual
  ),
  OnboardingCategoryModel(
      name: 'House On Rent',
      slugId: AppConstants.flat,
      icon: AppImageAssets.houseOnRent,
      accountType: AppConstants.individual
  ),
  OnboardingCategoryModel(
      name: 'Other Rental',
      slugId: AppConstants.vehicle,
      icon: AppImageAssets.otherRental,
      accountType: AppConstants.individual
  ),*/
];

final List<CollapsibleGridModel> transportItemsCategories = [
  CollapsibleGridModel(
      name: '2 Wheeler',
      slugId: 'TWO_WHEELER',
      icon: AppImageAssets.twoWheelerBike),
  CollapsibleGridModel(
      name: 'Passenger',
      slugId: 'PASSENGER',
      icon: AppImageAssets.passengerCar),
  CollapsibleGridModel(
      name: 'Goods', slugId: 'GOODS', icon: AppImageAssets.goodsMiniBus),
  CollapsibleGridModel(
      name: 'Out Station', slugId: 'OUR_STATION', icon: AppImageAssets.car),
  CollapsibleGridModel(
      name: 'Rental', slugId: 'RENTAL', icon: AppImageAssets.car_rental),
  CollapsibleGridModel(
      name: 'Logistics', slugId: 'LOGISTICS', icon: AppImageAssets.logistics),
];

final List<OnboardingCategoryModel> financeCategories = [
  OnboardingCategoryModel(
    name: 'Banking Sector',
    slugId: 'BANKING_SECTOR',
    icon: AppImageAssets.bankingSector,
    subtitle: "Accounts, FD,\nsavings",
    accountType: AppConstants.business,
  ),
  OnboardingCategoryModel(
    name: 'Loan Sector',
    slugId: 'LOAN_SECTOR',
    icon: AppImageAssets.loanSector,
    subtitle: "Home, vehicle,\npersonal",
    accountType: AppConstants.business,),
  OnboardingCategoryModel(
    name: 'Insurance Sector',
    slugId: 'INSURANCE_SECTOR',
    icon: AppImageAssets.insuranceSector,
    subtitle: "Health.\nlife, vehicle",
    accountType: AppConstants.business,),
  OnboardingCategoryModel(
    name: 'Capital Market',
    slugId: 'CAPITAL_MARKET',
    icon: AppImageAssets.capitalMarket,
    subtitle: "Stocks, mutual\nfunds, trading",
    accountType: AppConstants.business,),
  OnboardingCategoryModel(
    name: 'Data Sector',
    slugId: 'DATA_SECTOR',
    icon: AppImageAssets.dataSector,
    subtitle: " Analytics, insights,\nreporting",
    accountType: AppConstants.business,),
  OnboardingCategoryModel(
    name: 'Advisory Sector',
    slugId: 'ADVISORY_SECTOR',
    icon: AppImageAssets.advisorySector,
    subtitle: "Financial planning, consultation",
    accountType: AppConstants.business,),
];

final List<CollapsibleGridModel> automotiveServiceItemsCategories = [
  CollapsibleGridModel(
      name: 'Vehicle Sales',
      slugId: 'Vehicle_Sales',
      icon: AppImageAssets.VehicleSales),
  CollapsibleGridModel(
      name: 'Vehicle Parts',
      slugId: 'Vehicle_parts',
      icon: AppImageAssets.Vehicleparts),
  CollapsibleGridModel(
      name: 'Vehicle\nService',
      slugId: 'VEHICLE_SERVICE',
      icon: AppImageAssets.vehicleService),
  CollapsibleGridModel(
      name: 'Transport Logistic',
      slugId: 'Transport_Logistic',
      icon: AppImageAssets.TransportLogistic),
  CollapsibleGridModel(
      name: 'Vehicle Rental',
      slugId: 'Vehicle_Rental',
      icon: AppImageAssets.VehicleRental),
  CollapsibleGridModel(
      name: 'Vehicle Support',
      slugId: 'VehicleSupport',
      icon: AppImageAssets.VehicleSupport),
  //
  // CollapsibleGridModel(
  //     name: '2 Wheeler\nShowroom',
  //     slugId: 'TWO_WHEELER_SHOWROOM',
  //     icon: AppImageAssets.twoWheelerBike),
  // CollapsibleGridModel(
  //     name: '4 Wheeler\nShowroom',
  //     slugId: 'FOUR_WHEELER_SHOWROOM',
  //     icon: AppImageAssets.vehicleShowroom),
  // CollapsibleGridModel(
  //     name: 'Pre Owned\nShowroom',
  //     slugId: 'PRE_OWNED_SHOWROOM',
  //     icon: AppImageAssets.preOwnedShowroom),
  //
  // CollapsibleGridModel(
  //     name: 'Auto Parts\nShop',
  //     slugId: 'AUTO_PARTS_SHOP',
  //     icon: AppImageAssets.autoPartsShop),
  // CollapsibleGridModel(
  //     name: 'Vehicle\nAccessories',
  //     slugId: 'VEHICLE_ACCESSORIES',
  //     icon: AppImageAssets.vehicleAccessories),
];

final List<CollapsibleGridModel> bookingList = [
  CollapsibleGridModel(
      name: 'Parcel/\nCourier',
      slugId: PARCEL_COURIER,
      icon: AppImageAssets.courierParcel),
  CollapsibleGridModel(
      name: 'Transport & Vehicle',
      slugId: TRANSPORT_VEHICLE,
      icon: AppImageAssets.transportVehicle),
  CollapsibleGridModel(
      name: 'Hotel & Home Stay',
      slugId: HOTEL_HOME_STAY,
      icon: AppImageAssets.hotelAndHomeStay),
];

// final List<OnboardingCategoryModel> groceriesCategories = [
//   OnboardingCategoryModel(
//       name: 'Kirana Store',
//       slugId: KIRANA_STORE,
//       icon: AppImageAssets.kiranaStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'General Store',
//       slugId: GENERAL_STORE,
//       icon: AppImageAssets.generalStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Vegetable & Fruit',
//       slugId: VEGETABLE_FRUIT,
//       icon: AppImageAssets.vegFruitStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Dairy & Bakery',
//       slugId: DAIRY_BAKERY,
//       icon: AppImageAssets.dairyBakeryStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Home Essentials',
//       slugId: HOME_ESSENTIALS,
//       icon: AppImageAssets.homeEssentialsStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
//   OnboardingCategoryModel(
//       name: 'Stationary Shop',
//       slugId: STATIONARY_SHOP,
//       icon: AppImageAssets.stationaryStore,
//       accountType: AppConstants.business,
//       businessType: BusinessType.Grocery),
// ];



// final List<CollapsibleGridModel> cloudKitchenHomeMadeFood = [
//   CollapsibleGridModel(
//       name: 'Cloud Kitchen,\nMess',
//       slugId: 'CLOUD_KITCHEN_MESS',
//       icon: AppImageAssets.lunchDinner,
//      ),
//   CollapsibleGridModel(
//       name: 'Tiffin,\nLunch & Dinner',
//       slugId: 'TIFFIN_LUNCH_DINNER',
//       icon: AppImageAssets.tiffin,
//       ),
//   CollapsibleGridModel(
//       name: 'Home Made\nFood',
//       slugId: 'HOME_MADE_FOOD',
//       icon: AppImageAssets.homeMadeFood,
//     ),
// ];

// final List<CollapsibleGridModel> individualSocialProfileList = [
//   IndividualProfileCategory(
//     name: AppStrings.politician,
//     slugId: POLITICIAN,
//     icon: AppIconAssets.politicianIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.socialist,
//     slugId: SOCIALIST,
//     icon: AppIconAssets.socialistIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.journalist,
//     slugId: MEDIA,
//     icon: AppIconAssets.journalistIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.artist,
//     slugId: ARTIST,
//     icon: AppIconAssets.artistIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.director,
//     slugId: DIRECTOR,
//     icon: AppIconAssets.directorIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.homeMaker,
//     slugId: HOMEMAKER,
//     icon: AppIconAssets.homeMakerIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.govtEmployee,
//     slugId: GOVERNMENT_JOB,
//     icon: AppIconAssets.govtEmpIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.pvtEmployee,
//     slugId: PRIVATE_JOB,
//     icon: AppIconAssets.pvtEmpIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.ngoSociety,
//     slugId: REG_UNION, //NGO
//     icon: AppIconAssets.ngoSocietyIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.govtDepartment,
//     slugId: GOVTPSU,
//     icon: AppIconAssets.govtDeptIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.contentCreator,
//     slugId: CONTENT_CREATOR,
//     icon: AppIconAssets.contentCreaterIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.others,
//     slugId: OTHERS,
//     icon: AppIconAssets.staggeredIcon,
//   ),
// ];
//
// final List<IndividualProfileCategory> individualOtherSocialProfileList = [
//   IndividualProfileCategory(
//     name: AppStrings.student,
//     slugId: STUDENT,
//     icon: AppIconAssets.studentIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.skilledWorker,
//     slugId: SKILLED_WORKER,
//     icon: AppIconAssets.skilledWorkerIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.farmer,
//     slugId: FARMER,
//     icon: AppIconAssets.farmerIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.industrialist,
//     slugId: INDUSTRIALIST,
//     icon: AppIconAssets.industrialistIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.seniorCitizen,
//     slugId: SENIOR_CITIZEN,
//     icon: AppIconAssets.seniorCitizenIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.other,
//     slugId: OTHERS,
//     icon: AppIconAssets.staggeredIcon,
//   ),
// ];
//
// final List<IndividualProfileCategory> individualSelfEmployedList = [
//   IndividualProfileCategory(
//     name: AppStrings.rider,
//     slugId: BIKE_RIDER,
//     icon: AppIconAssets.riderIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.electrician,
//     slugId: ELECTRICIAN,
//     icon: AppIconAssets.electricianIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.plumber,
//     slugId: PLUMBER,
//     icon: AppIconAssets.plumberIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.technician,
//     slugId: TECHNICIAN,
//     icon: AppIconAssets.technicianIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.maid,
//     slugId: MAID_FEMALE,
//     icon: AppIconAssets.mainCleanerIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.cleaner,
//     slugId: CLEANER,
//     icon: AppIconAssets.mainCleanerIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.carpenter,
//     slugId: CARPENTER,
//     icon: AppIconAssets.carpenterIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.taxiCarDriver,
//     slugId: CAR_TAXI,
//     icon: AppIconAssets.taxiDriverIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.mechanic,
//     slugId: MECHANIC,
//     icon: AppIconAssets.mechanicIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.homeRenovator,
//     slugId: HOME_RENOVATOR,
//     icon: AppIconAssets.mistryIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.painter,
//     slugId: PAINTER,
//     icon: AppIconAssets.painterIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.gardener,
//     slugId: GARDENER,
//     icon: AppIconAssets.gardenerIcon,
//   ),
//   IndividualProfileCategory(
//     name: AppStrings.securityPerson,
//     slugId: SECURITY_PERSON,
//     icon: AppIconAssets.securityPersonIcon,
//   )
// ];

const List<CollapsibleGridModel> groceryOrFoodCategories = [
  CollapsibleGridModel(
    name: AppStrings.groceryNdStationary,
    slugId: AppConstants.grocery,
    icon: AppImageAssets.groceryItemsDiscover,
  ),
  CollapsibleGridModel(
    name: AppStrings.foodAndRestaurant,
    slugId: AppConstants.food,
    icon: AppImageAssets.foodItemsDiscover,
  ),
  CollapsibleGridModel(
    name: AppStrings.homeMadeFood,
    slugId: "HOME_MADE_FOOD",
    icon: AppImageAssets.homeMadeFoodDiscover,
  ),
];

final List<Map<String, String>> chooseDeliveryOptions = [
  {
    "id": "SELF",
    "icon": AppImageAssets.selfPickupIcon,
    "title": AppStrings.selfPickUpTitle,
    "subtitle": AppStrings.selfPickUpSubtitle,
  },
  {
    "id": "RIDER",
    "icon": AppIconAssets.riderIconColorful,
    "title": AppStrings.bookRiderTitle,
    "subtitle": AppStrings.bookRiderSubtitle,
  },
  // {
  //   "id": "PARTNER",
  //   "icon": AppImageAssets.transporterIcon,
  //   "title": "Order Via Partner",
  //   "subtitle": "Safe, Low Chargeable, Deliver in 1-3 Hours"
  // },
];

extension UrlTypeChecker on String {
  bool get isPdf => lowerCase.endsWith('.pdf');

  bool get isImageUrl {
    final extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return extensions.any((ext) => lowerCase.endsWith(ext));
  }

  String get lowerCase => this.toLowerCase();
}

const timeTable = "timeTable";
const syllabus = "syllabus";
const examSchedule = "examSchedule";
const results = "results";
const downloads = "downloads";
