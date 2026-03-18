// ignore_for_file: constant_identifier_names

import 'dart:core';
import 'dart:math' hide log;
import 'package:BlueEra/core/api/model/create_account_model.dart';
import 'package:BlueEra/core/api/model/onboarding_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/auth/model/mixed_profile_categrory.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_plan_style_model.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../features/chat/auth/controller/add_chat_symbol_controller.dart';
import '../../features/chat/view/chat_theme/chat_background_screen.dart';
import '../../features/chat/view/contacts/view/contact_list_page.dart';
import '../../features/chat/view/symbol_view/symbol_view_images.dart';
import '../../features/chat/view/add_symbol/add_symbol_screen.dart';
import '../../features/personal/personal_profile/view/manage_notification/notification.dart';
import '../../features/chat/view/wallet_chat/wallet_chat_screen.dart';

class AppConstants {
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

  static List<SubscriptionPlanStyleModel> listOfSubsBg = [
    SubscriptionPlanStyleModel(
        bg: AppImageAssets.basic_subscription_plan_bg,
        color: AppColors.darkBlueShade),
    SubscriptionPlanStyleModel(
        bg: AppImageAssets.popular_subscription_plan_bg,
        color: AppColors.darkYellowShade),
    SubscriptionPlanStyleModel(
        bg: AppImageAssets.advance_subscription_plan_bg,
        color: AppColors.darkGreenShade),
    SubscriptionPlanStyleModel(
        bg: AppImageAssets.pro_subscription_plan_bg,
        color: AppColors.darkPurpleShade),
    SubscriptionPlanStyleModel(
        bg: AppImageAssets.pro_plus_subscription_plan_bg,
        color: AppColors.darkPinkShade),
  ];

  static const String group_Chat_Type = 'group';
  static const String order_Chat_Type = 'order';
  static const String emergency = 'Emergency';
  static const String other = 'Other';
  static const String AiReply_Chat_Type = 'AiReply';
  static const String AiQuest_Chat_Type = 'AiQuest';

  static const String personal_Chat_Type = 'personal';
  static const String business_Chat_Type = 'business';
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
  static const String chatHost = 'chat.blueera.ai';
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
  static const wellness = "ALTERNATIVE WELLNESS";
  static const clinic = "CLINIC DOCTORS";
  static const MEDICAL_EDUCATION_INSTITUTIONS =
      "Medical Education Institutions";
  static const DIAGNOSTIC_TESTING_CENTERS = "DIAGNOSTIC SECTOR";
  static const INSTRUMENTS_PHARMACY = "Instruments Pharmacy";

  /// Automotive Categories
  static const SALES_SECTOR = "Sales Sector";
  static const PARTS_SECTOR = "Parts Sector";
  static const RENTAL_SECTOR = "Rental Sector";
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

void createProfileScreen() {
  // Get.toNamed(
  //   RouteHelper.getSelectAccountScreenRoute(),
  //   arguments: {ApiKeys.argMobileNumber: userMobileGlobal},
  // );
  // Get.toNamed(
  //   RouteHelper.getCreateNewAccountScreenRoute(),
  //   // arguments: {ApiKeys.argMobileNumber: userMobileGlobal},
  // );
  Get.toNamed(
    RouteHelper.getCreateAccountTypeScreenRoute(),
  );
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

List<OnboardingData> getOnboardingPages() => [
      OnboardingData(
        title: 'Shop from Verified Local Businesses',
        description:
            'Explore and buy products and services from Verified Local Businesses near you.',
        imageAsset: AppIconAssets.on_boarding1,
      ),
      OnboardingData(
        title: 'Monetize your Influence using Chat Feature',
        description: 'Promote businesses and earn from your social reach.',
        imageAsset: AppIconAssets.on_boarding2,
      ),
      OnboardingData(
        title: 'Find Talent or Your Dream Job in Maps',
        description:
            'Recruiters can post jobs. Job seekers can apply with ease.',
        imageAsset: AppIconAssets.on_boarding3,
      ),
      OnboardingData(
        title: 'Earn via Reels and Videos',
        description: 'Earn using Reels and Videos on your own using BlueEra.',
        imageAsset: AppIconAssets.on_boarding4,
      ),
    ];

List<AccountOption> getCreateAccountType() => [
      AccountOption(
        id: AppConstants.individual,
        title: AppStrings.individualAccount,
        subtitle: 'Self employed, social worker, job seeker',
        description: 'Build your presence. Connect. Get noticed!',
        iconPath: AppIconAssets.personal_account,
      ),
      AccountOption(
        id: AppConstants.business,
        title: AppStrings.businessListing,
        subtitle: 'Store, Salon, Cafe, Hospitals, Manufacturing',
        description: 'List your shop, office, or service and get discovered!',
        iconPath: AppIconAssets.business_account,
      ),
    ];

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

List<PopupMenuEntry<PostCreationMenu>> popupMenuItems() {
  final bool isBusiness =
      accountTypeGlobal.toUpperCase() == AppConstants.business;

  final List<PostCreationMenu> items = [
    PostCreationMenu.message,
    PostCreationMenu.poll,
    // PostCreationMenu.photos,
    // if (isBusiness || channelId.isNotEmpty) PostCreationMenu.videos,

    /// for individual user if user has channel then only video section will shown
    if (isBusiness) PostCreationMenu.jobPost,
    // PostCreationMenu.place,
    // PostCreationMenu.travel,
  ];

  const iconMap = {
    PostCreationMenu.message: AppIconAssets.message_post,
    PostCreationMenu.poll: AppIconAssets.qa_ask_questionOutlinedIcon,
    // PostCreationMenu.photos: AppIconAssets.photosOutlinedIcon,
    // PostCreationMenu.videos: AppIconAssets.videoOutlinedIcon,
    PostCreationMenu.jobPost: AppIconAssets.uilSuitcaseOutlinedIcon,
    // PostCreationMenu.place: AppIconAssets.locationOutlineIconGreyIcon,
    // PostCreationMenu.travel: AppIconAssets.travelOutlinedIcon,
  };

  const titleMap = {
    PostCreationMenu.message: AppStrings.lekha,
    PostCreationMenu.poll: AppStrings.poll,
    // PostCreationMenu.photos: AppStrings.symbol,
    PostCreationMenu.jobPost: AppStrings.jobPost,
    // PostCreationMenu.travel: AppStrings.travel,
  };

  final List<PopupMenuEntry<PostCreationMenu>> entries = [];

  for (var i = 0; i < items.length; i++) {
    final menu = items[i];
    entries.add(
      PopupMenuItem<PostCreationMenu>(
        height: SizeConfig.size35,
        value: menu,
        child: Row(
          children: [
            LocalAssets(imagePath: iconMap[menu]!),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              titleMap[menu]!,
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<PostCreationMenu>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> inventoryPopupMenuItems() {
  final items = <Map<String, dynamic>>[
    {"id": "BUSINESS CARDS", 'title': AppStrings.myBusinessCard}
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == "BUSINESS CARDS") {
            Get.toNamed(RouteHelper.getInventoryBusinessCardsScreenRoute());
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              items[i]['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.6,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

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

List<PopupMenuEntry<String>> popupMenuResumeCardItems() {
  final items = <Map<String, dynamic>>[
    {
      "id": "EDIT",
      'icon': AppIconAssets.tablerEditIcon,
      'title': AppStrings.edit
    },
    {
      "id": "SHARE",
      'icon': AppIconAssets.uploadIcon,
      'title': AppStrings.share
    },
    {
      "id": "DOWNLOAD",
      'icon': AppIconAssets.downloadIcon,
      'title': AppStrings.download
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == "EDIT") {
            Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
          }
          if (items[i]['id'] == "SHARE") {}
          if (items[i]['id'] == "DOWNLOAD") {
            // Get.toNamed(RouteHelper.getResumeTemplateScreenRoute());
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
                imagePath: items[i]['icon'],
                height: SizeConfig.size20,
                width: SizeConfig.size20),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              items[i]['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupMenuOrderTabItems() {
  final items = <Map<String, dynamic>>[
    {"id": "PENDING", 'title': AppStrings.pending},
    {"id": "COMPLETED", 'title': AppStrings.completed},
    {"id": "CANCELED", 'title': AppStrings.canceled},
    {"id": "LATEST", 'title': AppStrings.latest},
    {"id": "OLDEST", 'title': AppStrings.oldest},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == "EDIT") {
            Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
          }
          if (items[i]['id'] == "SHARE") {}
          if (items[i]['id'] == "DOWNLOAD") {
            // Get.toNamed(RouteHelper.getResumeTemplateScreenRoute());
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              items[i]['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.6,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupMenuChatCardItems() {
  final items = <Map<String, dynamic>>[
    {"id": "ADD_SYMBOL", 'title': "Add Symbol", 'icon': Icons.add_circle_outline},
    {"id": "VIEW_SYMBOL", 'title': "View Symbol", 'icon': Icons.auto_awesome},
    {"id": "CREATE_GROUP", 'title': AppStrings.createGroup, 'icon': Icons.group_add},
    {"id": "BACKGROUND", 'title': AppStrings.background, 'icon': Icons.wallpaper},
    {"id": "LOCK_CHAT", 'title': AppStrings.lockChat, 'icon': Icons.lock_outline},
    {"id": "LINKED_DEVICE", 'title': "Linked Device", 'icon': Icons.devices},
    {"id": "NOTIFICATION", 'title': "Notification", 'icon': Icons.notifications_outlined},
    {"id": "INVITE_FRIEND", 'title': "Invite Friend", 'icon': Icons.person_add_alt_1_outlined},
    {"id": "WALLET", 'title': "Wallet", 'icon': Icons.account_balance_wallet_outlined},
    {"id": "PRIVATE_ROOM", 'title': "Private Room", 'icon': Icons.meeting_room_outlined},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == "ADD_SYMBOL") {
            Get.to(() => AddChatSymbolScreen());
          } else if (items[i]['id'] == "VIEW_SYMBOL") {
            final addSymbolController =
                Get.isRegistered<AddChatSymbolController>()
                    ? Get.find<AddChatSymbolController>()
                    : Get.put(AddChatSymbolController());
            Get.to(() => SymbolViewImages(
                  mySymbols: addSymbolController.mySymbols,
                ));
          } else if (items[i]['id'] == "CREATE_GROUP") {
            Get.to(() => ContactsPage(
                  from: "group",
                ));
          } else if (items[i]['id'] == "BACKGROUND") {
            Get.to(() => ChatBackgroundScreen());
          } else if (items[i]['id'] == "LOCK_CHAT") {
            commonSnackBar(message: "Coming soon....");
          } else if (items[i]['id'] == "LINKED_DEVICE") {
            commonSnackBar(message: "Coming soon....");
          } else if (items[i]['id'] == "NOTIFICATION") {
            Get.to(() => NotificationSettingScreen());
          } else if (items[i]['id'] == "INVITE_FRIEND") {
            commonSnackBar(message: "Coming soon....");
          } else if (items[i]['id'] == "WALLET") {
            Get.to(() => const WalletChatScreen());
          } else if (items[i]['id'] == "PRIVATE_ROOM") {
            commonSnackBar(message: "Coming soon....");
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(items[i]['icon'], size: 18, color: AppColors.black30),
            const SizedBox(width: 8),
            CustomText(
              items[i]['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

// List<String> isShowOther = ["product", "service", "both"];
// List<String> isShowProduct = ["product", "service", "both"];
// List<String> isShowService = ["product", "service", "both", "food"];
List<String> isShowProduct = [AppConstants.product];
List<String> isShowService = [AppConstants.service];
List<String> isShowFood = [AppConstants.food];

String? businessType() {
  final controller = Get.find<ViewBusinessDetailsController>();
  return controller.businessProfileDetails?.data?.typeOfBusiness?.toLowerCase();
}

List<PopupMenuEntry<InventoryMenuItem>> popupMenuInventoryItems(
    String businessType) {
  final items = <InventoryMenuItem>[
    InventoryMenuItem.addProduct,
    // if (isShowProduct.contains(businessType)) InventoryMenuItem.addProduct,
    // if (isShowService.contains(businessType)) InventoryMenuItem.addService,
    // if (isShowFood.contains(businessType)) InventoryMenuItem.addFood,
  ];

  final List<PopupMenuEntry<InventoryMenuItem>> entries = [];

  for (int i = 0; i < items.length; i++) {
    final item = items[i];

    entries.add(
      PopupMenuItem<InventoryMenuItem>(
        padding: const EdgeInsets.all(10),
        height: 35,
        value: item,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              item.title,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<InventoryMenuItem>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupMenuVisitProfileItems() {
  final items = <Map<String, dynamic>>[
    {
      "id": "SHARE",
      'icon': AppIconAssets.share_bold,
      'slud_id': 'Share',
      'title': AppStrings.share
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        // onTap: () {
        //
        //   if (items[i]['id'] == "SHARE") {}
        //
        // },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: items[i]['icon'],
              height: SizeConfig.size20,
              width: SizeConfig.size20,
            ),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              items[i]['title'],
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupMenuVisitProfileActionItems(
    {bool? isSavePost, bool? isShowSaveOption = true}) {
  final items = <Map<String, dynamic>>[
    if (isShowSaveOption == true)
      {
        "id": "SAVE",
        'icon': AppIconAssets.save_new,
        'title': (isSavePost ?? false) ? AppStrings.unsave : AppStrings.save,
        'slud_id': (isSavePost ?? false) ? "Unsave" : "Save"
      },
    {
      "id": "REPORT_POST",
      'icon': AppIconAssets.report_new,
      'slud_id': 'Report Post',
      'title': AppStrings.reportPost,
    },
    {
      "id": "BLOCK_USER",
      'icon': AppIconAssets.block_user,
      'slud_id': 'Block User',
      'title': AppStrings.blockUser
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: items[i]['icon'],
              height: SizeConfig.size20,
              width: SizeConfig.size20,
            ),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              items[i]['title'],
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupPostMenuItems(bool? is_reposted) {
  final items = <Map<String, dynamic>>[
    if ((is_reposted == null) || (is_reposted == false))
      {'title': AppStrings.editPost, "slud_id": 'Edit Post'},
    {'title': AppStrings.deletePost, "slud_id": "Delete Post"},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}
List<PopupMenuEntry<String>> popPupMenuForAiChat() {
  final items = <Map<String, dynamic>>[
      {'title':"Change Profile", "slud_id": 'change_profile'},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popPupMenuForPersonalChat() {
  final items = <Map<String, dynamic>>[
    {'title': "Report", "slud_id": 'report'},
    {'title': "Block", "slud_id": 'block'},
    {'title': "Clear Chat", "slud_id": 'clear_chat'},
    {'title': "Media ", "slud_id": 'media'},
    {'title': "Docs ", "slud_id": 'docs'},
    {'title': "Chat Theme", "slud_id": 'chat_theme'},
    {'title': "Add Shortcut", "slud_id": 'add_shortcut'},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popPupMenuForGroupChat() {
  final items = <Map<String, dynamic>>[
    {'title': "Clear Chat", "slud_id": 'clear_chat'},
    {'title': "Background Change", "slud_id": "background_change"},
    {'title': "Exit Group", "slud_id": "exit_group"},
    {'title': "Pin Group", "slud_id": "pin_group"},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupVideoMenuItems() {
  final items = <Map<String, dynamic>>[
    {
      'slud_id': 'Edit Video',
      'title': AppStrings.editVideo,
    },
    {'slud_id': 'Delete Video', 'title': AppStrings.deleteVideo},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupShortsMenuItems() {
  final items = <Map<String, dynamic>>[
    {'title': 'Edit Short'},
    {'title': 'Delete Short'},
    {'title': 'Change Thumbnail'},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['title'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupProductMenuItems() {
  final items = <Map<String, dynamic>>[
    {'slud_id': 'Edit Product', 'title': AppStrings.editProduct},
    {'slud_id': 'Delete Product', 'title': AppStrings.deleteProduct},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> photoPostMenuItems() {
  final items = <Map<String, dynamic>>[
    {'id': "Square", 'title': AppStrings.square, 'icon': Icons.square_outlined},
    {
      'id': "Portrait",
      'title': AppStrings.portrait,
      'icon': Icons.crop_portrait_outlined
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    final menu = items[i];
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        child: Row(
          children: [
            Icon(menu['icon'], color: AppColors.grey5B),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              menu['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
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
const String DELIVERY_RIDER = "DELIVERY_RIDER";
const String CAR_TAXI = "CAR_DRIVER_TAXI";
const String GOODS_TAXI = "GOODS_TAXI";
const String AUTO_TAXI = "AUTO_TAXI";
const String MECHANIC = "MECHANIC";
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
const String KIRANA_STORE = "KIRANA_STORE";
const String GENERAL_STORE = "GENERAL_STORE";
const String VEGETABLE_FRUIT = "VEGETABLE_FRUIT";
const String DAIRY_BAKERY = "DAIRY_BAKERY";
const String HOME_ESSENTIALS = "HOME_ESSENTIALS";
const String STATIONARY_SHOP = "STATIONARY_SHOP";

// Food
const String MULTI_CUISINE_RESTAURANTS = "MULTI_CUISINE_RESTAURANTS";
const String PURE_VEG_RESTAURANT = "PURE_VEG_RESTAURANT";
const String NON_VEG_RESTAURANT = "NON_VEG_RESTAURANT";
const String ECONOMY_DHABA = "ECONOMY_DHABA";
const String GARDEN_BUFFET_RESTAURANT = "GARDEN_BUFFET_RESTAURANT";
const String CLOUD_KITCHEN = "CLOUD_KITCHEN ";
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
const String JEWELRY_LUXURY_STORE = "JEWELRY_LUXURY_STORE";
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

//
const String BABY_PRODUCTS = "BABY_PRODUCTS";
const String CELL_PHONES_ACCESSORIES = "CELL_PHONES_ACCESSORIES";
const String MUSICAL_INSTRUMENTS = "MUSICAL_INSTRUMENTS";
const String BOOKS_STATIONERY = "BOOKS_STATIONERY";
const String TOOLS_AND_HOME_IMPROVEMENT = "TOOLS_HOME_IMPROVEMENT";
const String TOYS_GAMES = "TOYS_GAMES";
const String ARTS_CRAFTS_SEWING = "ARTS_CRAFTS_SEWING";
const String CLOTHING_SHOWS_JEWELRY = "CLOTHING_SHOES_JEWELRY";
const String FARMING_LAWN_GARDEN = "FARMING_LAWN_GARDEN";

const String ALL_INDIVIDUAL = "ALL_INDIVIDUAL";
const String skilledWork = "skilledWork";
const String consultant = "consultant";
const String travel = "travel";

const String ALL_PRODUCT_PROFILE = "ALL_PRODUCT_PROFILE";
const String ALL_SERVICE_PROFILE = "ALL_SERVICE_PROFILE";

// Services
const String CONSULTING_HR_SERVICE = "CONSULTING_HR_SERVICE";
const String HEALTHCARE_MEDICAL_SERVICES = "HEALTHCARE_MEDICAL_SERVICES";
const String INSTRUMENTS_PHARMACY_ = "INSTRUMENTS PHARMACY";
const String EDUCATION_TRAINING = "EDUCATION_TRAINING";
const String HOTELS_STAY_SERVICE = "HOTELS_STAY_SERVICE";
const String BEAUTY_PERSONAL_CARE = "BEAUTY_PERSONAL_CARE";
const String FINANCIAL_SERVICES = "FINANCIAL_SERVICES";
const String SERVICE_CENTRE_ESSENTIAL_UTILITY =
    "SERVICE_CENTRE_ESSENTIAL_UTILITY";
const String HOME_SERVICES_UTILITY = "HOME_SERVICES_UTILITY";
const String IT_COMMUNICATION = "IT_COMMUNICATION";
const String MEDIA_PUBLICITY_CREATIVE = "MEDIA_PUBLICITY_CREATIVE";
const String AUTOMOTIVE_SERVICES = "AUTOMOTIVE_SERVICES";
const String LOGISTICS_TRANSPORTATION = "LOGISTICS_TRANSPORTATION";
// const String CELEBRATION_EVENT_SERVICES = "CELEBRATION_EVENT_SERVICES";
const String TOUR_TRAVEL_TOURISM = "TOUR_TRAVEL_TOURISM";
const String REAL_ESTATE_PROPERTY_SERVICES = "REAL_ESTATE_PROPERTY_SERVICES";
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
const String HOSPITAL_SECTOR = "HOSPITAL_SECTOR";
const String INSTRUMENTS_PHARMACY = "INSTRUMENTS_PHARMACY";
const String DIAGNOSTIC_SECTOR = "DIAGNOSTIC_SECTOR";
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
const String ALTERNATIVE_STAYS = "ALTERNATIVE";
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

// Finance
const String BANKING_SECTOR = "BANKING_SECTOR";
const String LOAN_SECTOR = "LOAN_SECTOR";
const String INSURANCE_SECTOR = "INSURANCE_SECTOR";
const String CAPITAL_MARKET = "CAPITAL_MARKET";
const String DATA_SECTOR = "DATA_SECTOR";
const String ADVISORY_SECTOR = "ADVISORY_SECTOR";

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

final Set<String> _viewedBusinessIds = {};

void trackBusinessStoreView(String storeId) {
  if (kReleaseMode) {
    // call API asynchronously without blocking UI
    Future.microtask(() async {
      try {
        if (!_viewedBusinessIds.contains(storeId)) {
          _viewedBusinessIds.add(storeId);
          StoreRepo().businessByViewCountIDApi(businessId: storeId);
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
  CommentTypeModel("Motivation / Hope", AppStrings.motivationHope,
      AppIconAssets.emotionHope),
  CommentTypeModel("Protest / Rebellion", AppStrings.protestRebellion,
      AppIconAssets.emotionRebellion),
  CommentTypeModel("Empathy / Humanity", AppStrings.empathyHumanity,
      AppIconAssets.emotionHumanity),
  CommentTypeModel(
      "Humor / Sarcasm", AppStrings.humorSarcasm, AppIconAssets.emotionSarcasm),
  CommentTypeModel("Poetic / Storytelling", AppStrings.poeticStorytelling,
      AppIconAssets.emotionStorytelling),
  CommentTypeModel(
      "Latest / Update", AppStrings.latestUpdate, AppIconAssets.emotionUpdate),
  CommentTypeModel("Informative / Educational",
      AppStrings.informativeEducational, AppIconAssets.emotionEducational),
  CommentTypeModel("Trending / Current Events",
      AppStrings.trendingCurrentEvents, AppIconAssets.emotionInformative),
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
  CommentTypeModel("Agree", AppStrings.agree, AppIconAssets.commentAgree),
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
  CommentTypeModel("Shock", AppStrings.shock, AppIconAssets.commentCapa),
  CommentTypeModel(
      "Inspired", AppStrings.inspired, AppIconAssets.commentInspired),
  CommentTypeModel("Angry", AppStrings.angry, AppIconAssets.commentAngry),
  CommentTypeModel("Curious", AppStrings.curious, AppIconAssets.commentCurious),
  CommentTypeModel("Suggest", AppStrings.suggest, AppIconAssets.commentSuggest),
  CommentTypeModel("Empathy", AppStrings.empathy, AppIconAssets.commentEmpathy),
  CommentTypeModel(
      "Celebrate", AppStrings.celebrate, AppIconAssets.commentCelebrate),
  CommentTypeModel("Warn", AppStrings.warn, AppIconAssets.commentWarn),
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

/// STORE FEED
final List<MixedProfileCategory> mainCategories = [
  MixedProfileCategory(
    name: AppStrings.groceryVegetablesDairy,
    slugId: AppConstants.groceryVegetablesDairy,
    icon: AppIconAssets.groceryIcon,
    // type: AppConstants.service,
  ),
  MixedProfileCategory(
    name: AppStrings.food,
    slugId: AppConstants.foodServices,
    icon: AppIconAssets.foodIcon,
    // type: AppConstants.food,
  ),
  MixedProfileCategory(
    name: AppStrings.store,
    slugId: AppConstants.storeServices,
    icon: AppIconAssets.storeIcon,
    // type: AppConstants.storeServices,
  ),
  MixedProfileCategory(
    name: AppStrings.tab_product,
    slugId: AppConstants.productsServices,
    icon: AppIconAssets.productIcon,
    // type: AppConstants.product,
  ),
  MixedProfileCategory(
    name: AppStrings.rider,
    slugId: AppConstants.riderServices,
    icon: AppIconAssets.riderIcon,
    // type: AppConstants.service,
  ),
  MixedProfileCategory(
    name: AppStrings.taxiCarDriver,
    slugId: AppConstants.taxiDriverServices,
    icon: AppIconAssets.taxiDriverIcon,
    // type: AppConstants.service,
  ),
  MixedProfileCategory(
    name: AppStrings.rentalServices,
    slugId: AppConstants.rentalServices,
    icon: AppIconAssets.rentKeyIcon,
    // type: AppConstants.service,
  ),
  MixedProfileCategory(
    name: AppStrings.homeServices,
    slugId: AppConstants.homeServices,
    icon: AppIconAssets.homeServiceIcon,
    // type: AppConstants.service,
  ),
];

/// New....

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
      slugId: CONSULTING_HR_SERVICE,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Beauty',
      slugId: BEAUTY_PERSONAL_CARE,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Financial',
      slugId: FINANCIAL_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Service Centre',
      slugId: SERVICE_CENTRE_ESSENTIAL_UTILITY,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Home & Utility',
      slugId: HOME_SERVICES_UTILITY,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'IT & Comm',
      slugId: IT_COMMUNICATION,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Publicity',
      slugId: MEDIA_PUBLICITY_CREATIVE,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Automotive',
      slugId: AUTOMOTIVE_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Logistics',
      slugId: LOGISTICS_TRANSPORTATION,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Events',
      slugId: CELEBRATION_EVENT_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Tourism',
      slugId: TOUR_TRAVEL_TOURISM,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Real Estate',
      slugId: REAL_ESTATE_PROPERTY_SERVICES,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Quality Labs',
      slugId: TECHNICAL_TESTING_QUALITY_SERVICE,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
];

// --- OnBoarding Category ---

final List<OnboardingCategoryModel> businessOnboardingProfilesCategory = [
  OnboardingCategoryModel(
    name: 'Grocery, Food\nRestaurant',
    slugId: FOOD,
    icon: OnboardingBusinessAssets.groceryFoodRestaurant,
    accountType: AppConstants.business,
  ),
  OnboardingCategoryModel(
    name: 'Shop Or Store',
    slugId: PRODUCT,
    icon: OnboardingBusinessAssets.shopOrStore,
    accountType: AppConstants.business,
  ),
  OnboardingCategoryModel(
    name: 'Sectors',
    slugId: SERVICE_OTHERS,
    icon: OnboardingBusinessAssets.services,
    accountType: AppConstants.business,
  ),
  OnboardingCategoryModel(
    name: 'Services',
    slugId: SERVICE,
    icon: OnboardingBusinessAssets.services,
    accountType: AppConstants.business,
  ),
  OnboardingCategoryModel(
    name: 'Manufacturing /\nIndustry',
    slugId: MANUFACTURING,
    icon: OnboardingBusinessAssets.manufacturingIndustry,
    accountType: AppConstants.business,
  ),
];

final List<OnboardingCategoryModel> businessOnboardingServicesCategories = [
  OnboardingCategoryModel(
      name: 'Beauty &\nPersonal Care',
      slugId: BEAUTY_PERSONAL_CARE,
      icon: OnboardingBusinessAssets.beautyAndPersonalCare,
      // flagIcon: AppImageAssets.beautyPersonalCare,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Consulting\nFirm / Org.',
      slugId: CONSULTING_HR_SERVICE,
      icon: OnboardingBusinessAssets.consultingFirm,
      // flagIcon: AppImageAssets.consultingService,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Home Services\n& Utility',
      slugId: HOME_SERVICES_UTILITY,
      icon: OnboardingBusinessAssets.homeServiceAndUtility,
      // flagIcon: AppImageAssets.homeServiceUtility,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Service Centre\n& Utility',
      slugId: SERVICE_CENTRE_ESSENTIAL_UTILITY,
      icon: OnboardingBusinessAssets.serviceCenterAndEssentialUtils,
      // flagIcon: AppImageAssets.serviceCenter,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Media, Publicity\n& Creative',
      slugId: MEDIA_PUBLICITY_CREATIVE,
      icon: OnboardingBusinessAssets.mediaPublicityAndCreative,
      // flagIcon: AppImageAssets.mediaPublicityIcon,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Real Estate &\nProperty',
      slugId: REAL_ESTATE_PROPERTY_SERVICES,
      icon: OnboardingBusinessAssets.realEstateProperty,
      // flagIcon: AppImageAssets.tourTravel,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Healthcare\nServices',
  //     slugId: HEALTHCARE_MEDICAL_SERVICES,
  //     icon: OnboardingBusinessAssets.healthcareMedicalServices,
  //     flagIcon: AppConstants.healthcareMedicalServices,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Healthcare),
  // OnboardingCategoryModel(
  //     name: 'Education &\nTraining',
  //     slugId: EDUCATION_TRAINING,
  //     icon: OnboardingBusinessAssets.educationAndTraining,
  //     flagIcon: AppImageAssets.educationTraining,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Siksha),
  // OnboardingCategoryModel(
  //     name: 'Hotels & Stay\nService',
  //     slugId: HOTELS_STAY_SERVICE,
  //     icon: OnboardingBusinessAssets.hostelsAndStayService,
  //     flagIcon: AppImageAssets.hostel,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Motel),

  // OnboardingCategoryModel(
  //     name: 'Financial\nServices',
  //     slugId: FINANCIAL_SERVICES,
  //     icon: OnboardingBusinessAssets.financialServices,
  //     flagIcon: AppImageAssets.financial,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),


  OnboardingCategoryModel(
      name: 'IT &\nCommunication',
      slugId: IT_COMMUNICATION,
      icon: OnboardingBusinessAssets.itAndCommunication,
      // flagIcon: AppImageAssets.itCommunication,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Automotive\nServices',
  //     slugId: AUTOMOTIVE_SERVICES,
  //     icon: OnboardingBusinessAssets.automotiveServices,
  //     flagIcon: AppImageAssets.automativeService,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Logistics &\nTransportation',
  //     slugId: LOGISTICS_TRANSPORTATION,
  //     icon: OnboardingBusinessAssets.logisticsAndTransport,
  //     flagIcon: AppImageAssets.logisticTransportation,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Celebration &\nEvent Services',
  //     slugId: CELEBRATION_EVENT_SERVICES,
  //     icon: OnboardingBusinessAssets.celebrationAndEventServices,
  //     flagIcon: AppImageAssets.celebrationEvent,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Tour, Travel\n& Tourism',
      slugId: TOUR_TRAVEL_TOURISM,
      icon: OnboardingBusinessAssets.tourTravelsAndTourism,
      // flagIcon: AppImageAssets.tourTravel,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
  // OnboardingCategoryModel(
  //     name: 'Real Estate &\nProperty Services',
  //     slugId: REAL_ESTATE_PROPERTY_SERVICES,
  //     icon: OnboardingBusinessAssets.realEstateProperty,
  //     // flagIcon: AppImageAssets.tourTravel,
  //     accountType: AppConstants.business,
  //     businessType: BusinessType.Service),
  OnboardingCategoryModel(
      name: 'Technical Testing\n& Quality Labs',
      slugId: TECHNICAL_TESTING_QUALITY_SERVICE,
      icon: OnboardingBusinessAssets.technicalTestingAndQualityLabs,
      // flagIcon: AppImageAssets.tourTravel,
      accountType: AppConstants.business,
      businessType: BusinessType.Service),
];

final List<OnboardingCategoryModel> businessOnboardingFoodsCategories = [
  OnboardingCategoryModel(
      name: 'Multicuisine\nRestaurant',
      slugId: MULTI_CUISINE_RESTAURANTS,
      icon: OnboardingBusinessAssets.multicuisineRestaurant,
      accountType: AppConstants.business,
      colorCode: Color(0xffFFF8EC),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Pure Veg\nRestaurant',
      slugId: PURE_VEG_RESTAURANT,
      icon: OnboardingBusinessAssets.pureVegRestaurant,
      accountType: AppConstants.business,
      colorCode: Color(0xffF0FFF4),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Coffee / Beverages\nShop',
      slugId: COFFEE_BEVERAGES_SHOP,
      icon: OnboardingBusinessAssets.coffeeBeveragesShop,
      accountType: AppConstants.business,
      colorCode: Color(0xffFFF2EF),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Economy\nDhaba',
      slugId: ECONOMY_DHABA,
      icon: OnboardingBusinessAssets.economyDhaba,
      accountType: AppConstants.business,
      colorCode: Color(0xffFFF2E3),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Sweet & Namkeen\nShop',
      slugId: SWEET_NAMKEEN_SHOP,
      icon: OnboardingBusinessAssets.sweetNamkeenShop,
      accountType: AppConstants.business,
      colorCode: Color(0xffF0F6FF),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Breakfast/\nFast-food',
      slugId: BREAKFAST_FAST_FOOD,
      icon: OnboardingBusinessAssets.breakfastFastFood,
      accountType: AppConstants.business,
      colorCode: Color(0xffFFF8EC),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Garden/Buffet\nRestaurant',
      slugId: GARDEN_BUFFET_RESTAURANT,
      icon: OnboardingBusinessAssets.gardenBuffetRestaurant,
      accountType: AppConstants.business,
      colorCode: Color(0xffF0FFF4),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Cloud Kitchen,\nMess',
      slugId: CLOUD_KITCHEN,
      icon: OnboardingBusinessAssets.cloudKitchenMess,
      accountType: AppConstants.business,
      colorCode: Color(0xffFFF2EF),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Non-Veg\nRestaurant',
      slugId: NON_VEG_RESTAURANT,
      icon: OnboardingBusinessAssets.nonVegRestaurant,
      accountType: AppConstants.business,
      colorCode: Color(0xffFFF2E3),

      businessType: BusinessType.Food),
  OnboardingCategoryModel(
      name: 'Ice Cream\nCorner',
      slugId: ICE_CREAM_CORNER,
      icon: OnboardingBusinessAssets.iceCreamCorner,
      accountType: AppConstants.business,
      colorCode: Color(0xffF0F6FF),

      businessType: BusinessType.Food),
];

final List<OnboardingCategoryModel>
businessOnboardingEducationTrainingCategories = [
  OnboardingCategoryModel(
      name: 'School\nEducation',
      slugId: SCHOOL_EDUCATION,
      icon: OnboardingBusinessAssets.EduSchoolEducation,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: 'Collage/\nUniversity',
      slugId: COLLEGE_UNIVERSITY,
      icon: OnboardingBusinessAssets.EduUniversity,
      accountType: AppConstants.business,

      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: 'Coaching/\nInstitute',
      slugId: COACHING_EXAM_PREPARATION,
      icon: OnboardingBusinessAssets.EduCoaching,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: 'Sports &\nHobby',
      slugId: CREATIVE_SPORT_HOBBY,
      icon: OnboardingBusinessAssets.EduSports,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: 'Professional\nLearn',
      slugId: PROFESSIONAL_SUPPORT_EDUCATION,
      icon: OnboardingBusinessAssets.EduProfessional,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
  OnboardingCategoryModel(
      name: 'Skill\nTraining',
      slugId: TECHNICAL_SKILL_TRAINING,
      icon: OnboardingBusinessAssets.EduSkill,
      accountType: AppConstants.business,
      businessType: BusinessType.Siksha),
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
      slugId: JEWELRY_LUXURY_STORE,
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

final List<OnboardingCategoryModel> businessProductStoreCategories = [
  OnboardingCategoryModel(
      // name: AppStrings.fashionLifestyle,
      name: 'Fashion',
      slugId: FASHION_LIFESTYLE,
      icon: AppImageAssets.fashionLifestyle,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.electronicsAppliances,
      name: 'Electronics',
      slugId: ELECTRONICS_APPLIANCES_STORE,
      icon: AppImageAssets.electronicsApplianceStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.automotiveStore,
      name: 'Spare Parts',
      slugId: AUTOMOTIVE_STORE_SHOWROOM,
      icon: AppImageAssets.automotiveStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Construction',
      slugId: CONSTRUCTION_HOME_ESSENTIALS,
      icon: AppImageAssets.constructionHardware,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Appliances',
      slugId: HOME_APPLIANCES_STORE,
      icon: AppImageAssets.homeAppliances,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.furnitureHomeDecor,
      name: 'Furniture',
      slugId: FURNITURE_HOME_DECOR,
      icon: AppImageAssets.furnitureHomeDecor,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Jewellery',
      slugId: JEWELRY_LUXURY_STORE,
      icon: AppImageAssets.jewelleryLuxuryStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Cosmetics',
      slugId: BEAUTY_COSMETICS,
      icon: AppImageAssets.beautyAndCosmetics,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.booksStationaryGifts,
      name: 'Stationery',
      slugId: BOOKS_STATIONERY_GIFTS_STORE,
      icon: AppImageAssets.booksStationary,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.toysBabyProducts,
      name: 'Toys',
      slugId: TOYS_BABY_PRODUCTS_STORE,
      icon: AppImageAssets.babyToysProductStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Home Kitchen',
      slugId: HOME_APPLIANCES_STORE,
      icon: AppImageAssets.homeKitchenAndUtensils,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.sportsFitness,
      name: 'Sports',
      slugId: SPORTS_FITNESS_STORE,
      icon: AppImageAssets.sportsFitnessStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      // name: AppStrings.petSupplies,
      name: 'Pets',
      slugId: PET_SUPPLIES_STORE,
      icon: AppImageAssets.petSuppliesStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Religious',
      slugId: RELIGIOUS_SPECIALTY,
      icon: AppImageAssets.religiousAndSpeciality,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Packaging',
      slugId: PACKAGING_DISPOSABLE,
      icon: AppImageAssets.packagingAndDisposable,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Agriculture',
      slugId: AGRICULTURE_FARMING,
      icon: AppImageAssets.agricultureAndFarming,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Industrials',
      slugId: INDUSTRIAL_WHOLESALE,
      icon: AppImageAssets.industrialWholesale,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
];

final List<OnboardingCategoryModel> businessProductsCategories = [
  OnboardingCategoryModel(
      name: 'Mobiles &\nAccessories',
      slugId: CELL_PHONES_ACCESSORIES,
      icon: AppImageAssets.mobileAccessories,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Electronics &\nGadgets',
      slugId: ELECTRONICS_APPLIANCES_STORE,
      icon: AppImageAssets.electronicsApplianceStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Fashion & Jewelry',
      slugId: FASHION_LIFESTYLE,
      icon: AppImageAssets.jewelleryLuxuryStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Beauty &\nCare',
      slugId: BEAUTY_COSMETICS,
      icon: AppImageAssets.beautyAndCosmetics,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Books &\nStationery',
      slugId: BOOKS_STATIONERY,
      icon: AppImageAssets.booksStationary,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Auto Spare\nParts',
      slugId: AUTOMOTIVE_STORE_SHOWROOM,
      icon: AppImageAssets.automotiveStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Tools &\nHardware',
      slugId: TOOLS_AND_HOME_IMPROVEMENT,
      icon: AppImageAssets.constructionHardware,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Kids\nProducts',
      slugId: BABY_PRODUCTS,
      icon: AppImageAssets.babyToysProductStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Home\nAppliances',
      slugId: HOME_APPLIANCES_STORE,
      icon: AppImageAssets.homeAppliances,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Furniture &\nDecor',
      slugId: FURNITURE_HOME_DECOR,
      icon: AppImageAssets.furnitureHomeDecor,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Home\nKitchen',
      slugId: HOME_KITCHEN_UTENSILS,
      icon: AppImageAssets.homeKitchenAndUtensils,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Industrial\nSupplies',
      slugId: INDUSTRIAL_WHOLESALE,
      icon: AppImageAssets.industrialWholesale,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Musical\nInstruments',
      slugId: MUSICAL_INSTRUMENTS,
      icon: AppImageAssets.musicalInstruments,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Books &\nStationery',
      slugId: BOOKS_STATIONERY,
      icon: AppImageAssets.booksStationary,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Pet\nCare',
      slugId: PET_SUPPLIES_STORE,
      icon: AppImageAssets.petSuppliesStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Sports &\nFitness',
      slugId: SPORTS_FITNESS_STORE,
      icon: AppImageAssets.sportsFitnessStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Tools &\nHardware',
      slugId: TOOLS_AND_HOME_IMPROVEMENT,
      icon: AppImageAssets.constructionHardware,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Toys &\nGames',
      slugId: TOYS_GAMES,
      icon: AppImageAssets.toysAndGames,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Arts, Crafts &\nSewing',
      slugId: ARTS_CRAFTS_SEWING,
      icon: AppImageAssets.artAndCraft,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Clothing, Shows &\njewelery',
      slugId: CLOTHING_SHOWS_JEWELRY,
      icon: AppImageAssets.jewelleryLuxuryStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
  OnboardingCategoryModel(
      name: 'Farming, Lawn &\nGarden',
      slugId: FARMING_LAWN_GARDEN,
      icon: AppImageAssets.agricultureAndFarming,
      accountType: AppConstants.business,
      businessType: BusinessType.Product),
];

/// Individual Categories

// --- OnBoarding Category ---
final List<OnboardingCategoryModel> individualOnboardingProfilesCategory = [
  OnboardingCategoryModel(
    name: 'Social profile',
    slugId: SOCIAL_PROFILE,
    icon: OnboardingIndividualAssets.socialProfile,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Skill Work/\nSelf Employee',
    slugId: SELF_EMPLOYED,
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

final List<OnboardingCategoryModel> individualOnboardingSocialProfileList = [
  OnboardingCategoryModel(
    name: AppStrings.politician,
    slugId: POLITICIAN,
    // icon: OnboardingIndividualAssets.politician,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.contentCreator,
    slugId: CONTENT_CREATOR,
    // icon: OnboardingIndividualAssets.contentCreator,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.govtEmployee,
    slugId: GOVERNMENT_JOB,
    // icon: OnboardingIndividualAssets.govtEmp,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.pvtEmployee,
    slugId: PRIVATE_JOB,
    // icon: OnboardingIndividualAssets.pvtEmp,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.journalist,
    slugId: MEDIA,
    // icon: OnboardingIndividualAssets.journalist,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.artist,
    slugId: ARTIST,
    // icon: OnboardingIndividualAssets.artist,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.director,
    slugId: DIRECTOR,
    // icon: OnboardingIndividualAssets.director,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.industrialist,
    slugId: INDUSTRIALIST,
    // icon: OnboardingIndividualAssets.industrialist,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.socialist,
    slugId: SOCIALIST,
    // icon: OnboardingIndividualAssets.socialist,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.student,
    slugId: STUDENT,
    // icon: OnboardingIndividualAssets.student,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.homeMaker,
    slugId: HOMEMAKER,
    // icon: OnboardingIndividualAssets.homeMaker,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.farmer,
    slugId: FARMER,
    // icon: OnboardingIndividualAssets.farmer,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.ngo,
    slugId: NGO,
    // icon: OnboardingIndividualAssets.ngo,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.societyOrUnion,
    slugId: REG_UNION,
    // icon: OnboardingIndividualAssets.society,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.govtDepartment,
    slugId: GOVTPSU,
    // icon: OnboardingIndividualAssets.govtDept,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: AppStrings.seniorCitizen,
    slugId: SENIOR_CITIZEN,
    // icon: OnboardingIndividualAssets.seniorCitizen,
    individualType: IndividualProfileType.SOCIAL_PROFILE,
    accountType: AppConstants.individual,
  ),
];

final List<OnboardingCategoryModel> individualOnboardingGigWorkList = [
  OnboardingCategoryModel(
    name: 'Bike Rider',
    slugId: DELIVERY_RIDER,
    icon: OnboardingIndividualAssets.bikeRider,
    individualType: IndividualProfileType.GIG_WORKER,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Car Driver',
    slugId: CAR_TAXI,
    icon: OnboardingIndividualAssets.taxiCarDriver,
    individualType: IndividualProfileType.GIG_WORKER,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Goods Transporter',
    slugId: GOODS_TAXI,
    icon: OnboardingIndividualAssets.goodsSupplier,
    individualType: IndividualProfileType.GIG_WORKER,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Auto Driver',
    slugId: AUTO_TAXI,
    icon: OnboardingIndividualAssets.autoERickshaw,
    individualType: IndividualProfileType.GIG_WORKER,
    accountType: AppConstants.individual,
  ),
];

final List<OnboardingCategoryModel> individualSkillWorkList = [
  OnboardingCategoryModel(
    name: 'Electrician',
    slugId: ELECTRICIAN,
    icon: OnboardingIndividualAssets.electrician,
    // flagIcon: AppImageAssets.electrician,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Plumber',
    slugId: PLUMBER,
    icon: OnboardingIndividualAssets.plumber,
    // flagIcon: AppImageAssets.plumber,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Maid (Female)',
    slugId: MAID_FEMALE,
    icon: OnboardingIndividualAssets.maid,
    // flagIcon: AppImageAssets.maid,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),

  OnboardingCategoryModel(
    name: 'Mechanic',
    slugId: MECHANIC,
    icon: OnboardingIndividualAssets.mechanic,
    // flagIcon: AppImageAssets.mechanic,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Technician',
    slugId: TECHNICIAN,
    icon: OnboardingIndividualAssets.technician,
    // flagIcon: AppImageAssets.technician,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Painter',
    slugId: PAINTER,
    icon: OnboardingIndividualAssets.painter,
    // flagIcon: AppImageAssets.painter,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Carpenter',
    slugId: CARPENTER,
    icon: OnboardingIndividualAssets.carpenter,
    // flagIcon: AppImageAssets.carpenter,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Home Renovator',
    slugId: HOME_RENOVATOR,
    icon: OnboardingIndividualAssets.homeRenovator,
    // flagIcon: AppImageAssets.homeRenovator,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Labour',
    slugId: LABOUR,
    icon: OnboardingIndividualAssets.labour,
    // flagIcon: AppImageAssets.homeRenovator,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Gardener',
    slugId: GARDENER,
    icon: OnboardingIndividualAssets.gardener,
    // flagIcon: AppImageAssets.gardener,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Security Person',
    slugId: SECURITY_PERSON,
    icon: OnboardingIndividualAssets.securityPerson,
    // flagIcon: AppImageAssets.securityPerson,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Cleaner',
    slugId: CLEANER,
    icon: OnboardingIndividualAssets.cleaner,
    // flagIcon: AppImageAssets.cleaner,
    individualType: IndividualProfileType.SELF_EMPLOYED,
    accountType: AppConstants.individual,
  ),

  // OnboardingCategoryModel(
  //   name: AppStrings.beautyCare,
  //   slugId: BEAUTICIAN,
  //   icon: OnboardingIndividualAssets.beautician,
  //   individualType: IndividualProfileType.SOCIAL_PROFILE,
  //   accountType: AppConstants.individual,
  // ),
  // OnboardingCategoryModel(
  //   name: AppStrings.tailoring,
  //   slugId: TAILOR,
  //   icon: OnboardingIndividualAssets.tailoring,
  //   individualType: IndividualProfileType.SOCIAL_PROFILE,
  //   accountType: AppConstants.individual,
  // ),

];

final List<OnboardingCategoryModel> individualOnboardingConsultationList = [
  OnboardingCategoryModel(
    name: 'Legal & Govt.\nConsultant',
    slugId: LEGAL_GOVT_CONSULTANT,
    icon: OnboardingIndividualAssets.legalGovtConsultant,
    // flagIcon: AppImageAssets.legalGovtConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Finance & Tax\nConsultant',
    slugId: FINANCE_TAX_CONSULTANT,
    icon: OnboardingIndividualAssets.financeTaxConsultant,
    // flagIcon: AppImageAssets.financeTaxConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Spiritual\nConsultant',
    slugId: SPIRITUAL_CONSULTANT,
    icon: OnboardingIndividualAssets.spiritualConsultant,
    // flagIcon: AppImageAssets.spiritualConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Trainee & Career\nConsultant',
    slugId: TRAINEE_CAREER_CONSULTANT,
    icon: OnboardingIndividualAssets.traineeCareerConsultant,
    // flagIcon: AppImageAssets.traineeCareerConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Advertising\nConsultant',
    slugId: ADVERTISING_CONSULTANT,
    icon: OnboardingIndividualAssets.advertisingConsultant,
    // flagIcon: AppImageAssets.advertisingConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Event Planner &\nDetective',
    slugId: EVENT_PLANNER_DETECTIVE,
    icon: OnboardingIndividualAssets.eventPlanDetective,
    // flagIcon: AppImageAssets.eventPlanDetective,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Property Broker &\nArchitect',
    slugId: PROPERTY_BROKER_ARCHITECT,
    icon: OnboardingIndividualAssets.propertyBrokerArchitect,
    // flagIcon: AppImageAssets.propertyBrokerArchitect,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Business & HR\nConsultant',
    slugId: BUSINESS_HR_CONSULTANT,
    icon: OnboardingIndividualAssets.businessHrConsultant,
    // flagIcon: AppImageAssets.businessHrConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Industry & Quality\nConsultant',
    slugId: INDUSTRY_QUALITY_CONSULTANT,
    icon: OnboardingIndividualAssets.industryQualityConsultant,
    // flagIcon: AppImageAssets.industryQualityConsultant,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
  OnboardingCategoryModel(
    name: 'Tech & Digital\nFreelancer',
    slugId: TECH_DIGITAL_FREELANCER,
    icon: OnboardingIndividualAssets.techDigitalFreelancer,
    // flagIcon: AppImageAssets.techDigitalFreelancer,
    individualType: IndividualProfileType.PROFESSIONAL,
    accountType: AppConstants.individual,
  ),
];

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

// Ean Service Lists
final List<CollapsibleGridModel> earnWithBlueEraServiceList = [
  CollapsibleGridModel(
    name: AppStrings.selfWork,
    slugId: SELF_EMPLOYED,
    icon: AppImageAssets.plumber,
  ),
  CollapsibleGridModel(
      name: 'Transport Work',
      slugId: GIG_WORKER,
      icon: AppImageAssets.deliveryPartner),
  CollapsibleGridModel(
      name: AppStrings.homeMadeProducts,
      slugId: HOME_MADE_PRODUCTS,
      icon: AppImageAssets.homeMadeProduct),
  CollapsibleGridModel(
      name: 'Home Made\nFood Items',
      slugId: HOME_MADE_FOOD,
      icon: AppImageAssets.homeMadeFood),
  CollapsibleGridModel(
      name: '${AppStrings.homeServices.tr}\n(Work From Home)',
      slugId: HOME_SERVICES,
      icon: AppImageAssets.homeService),
  CollapsibleGridModel(
      name: AppStrings.rentalServices,
      slugId: RENTAL_SERVICES,
      icon: AppImageAssets.rentalService),
  CollapsibleGridModel(
      name: AppStrings.counsellingConsulting,
      slugId: PROFESSIONAL,
      icon: AppImageAssets.consultation),
  CollapsibleGridModel(
      name: AppStrings.contentCreator,
      slugId: CONTENT_CREATOR,
      icon: AppImageAssets.contentCreator),
  CollapsibleGridModel(
      name: AppStrings.tuitionClassesOnlineOffline,
      slugId: TUTOR,
      icon: AppImageAssets.tutor),
];

final List<CollapsibleGridModel> gigWorkServiceList = [
  CollapsibleGridModel(
      name: 'Bike Rider',
      slugId: DELIVERY_RIDER,
      icon: AppImageAssets.deliveryPartner),
  CollapsibleGridModel(
      name: 'Car Driver', slugId: CAR_TAXI, icon: AppImageAssets.taxiDriver),
  CollapsibleGridModel(
      name: 'Goods Transporter',
      slugId: GOODS_TAXI,
      icon: AppImageAssets.goodsTransporter),
  CollapsibleGridModel(
      name: 'Auto Driver', slugId: AUTO_TAXI, icon: AppImageAssets.autoDriver),
];

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

final List<OnboardingCategoryModel> homeMadeFoodCategories = [
  OnboardingCategoryModel(
      name: AppStrings.tiffin,
      slugId: TIFFIN,
      icon: AppImageAssets.tiffin,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: AppStrings.bakery,
      slugId: BAKERY,
      icon: AppImageAssets.bakery,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: AppStrings.sweets,
      slugId: SWEETS,
      icon: AppImageAssets.sweets,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: AppStrings.other,
      slugId: OTHER,
      icon: AppIconAssets.staggeredIcon,
      accountType: AppConstants.individual),
];

final List<CollapsibleGridModel> rentalServiceCategories = [
  CollapsibleGridModel(
      name: 'Hotel', slugId: Flat_ROOM, icon: AppImageAssets.hotelStay),
  CollapsibleGridModel(
      name: 'Homestay', slugId: HOME_STAY, icon: AppImageAssets.homeStay),
  CollapsibleGridModel(name: 'Cabs', slugId: VEHICLE, icon: AppImageAssets.cab),
];

final List<OnboardingCategoryModel> homeMadeProductCategories = [
  OnboardingCategoryModel(
      name: 'Home Made Product',
      slugId: TIFFIN,
      icon: AppImageAssets.tiffin,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: 'Handicrafts',
      slugId: BAKERY,
      icon: AppImageAssets.bakery,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: 'Gift Items',
      slugId: SWEETS,
      icon: AppImageAssets.sweets,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: 'Textile & Fashion',
      slugId: OTHER,
      icon: AppIconAssets.staggeredIcon,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: 'Utility Products',
      slugId: OTHER,
      icon: AppIconAssets.staggeredIcon,
      accountType: AppConstants.individual),
  OnboardingCategoryModel(
      name: 'Other Products',
      slugId: OTHER,
      icon: AppIconAssets.staggeredIcon,
      accountType: AppConstants.individual),
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

final List<OnboardingCategoryModel> stayHomeItemsCategories = [

  OnboardingCategoryModel(
      name: 'House On Rent',
      slugId: AppConstants.flat,
      icon: AppImageAssets.houseOnRent,
      accountType: AppConstants.individual
  ),
  OnboardingCategoryModel(
      name: 'Other Rental',
      slugId: AppConstants.property,
      icon: AppImageAssets.homeStay,
      accountType: AppConstants.individual
  ),
];

final List<OnboardingCategoryModel> stayItemsCategories = [
  OnboardingCategoryModel(
      name: 'Hotel Stay',
      slugId: HOTELS_RESORT,
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

/// food Categories (Discover)
 List<CollapsibleGridModel> foodCategories = [
  CollapsibleGridModel(
     name: 'Breakfast',
     slugId: 'BREAKFAST',
     icon: AppImageAssets.breakfast,
  ),
  CollapsibleGridModel(
     name: 'Fast-Food',
     slugId: 'FAST_FOOD',
    icon: AppImageAssets.fastFood,
  ),
  CollapsibleGridModel(
     name: 'Lunch, Dinner',
     slugId: 'LUNCH_DINNER',
    icon: AppImageAssets.lunchDinner,
  ),
  // CollapsibleGridModel(
  //    name: 'Tiffin',
  //    slugId: 'TIFFIN',
  //   icon: AppImageAssets.tiffin,
  // ),
  // CollapsibleGridModel(
  //    name: 'Sweets',
  //    slugId: 'SWEETS',
  //    icon: AppImageAssets.sweets,
  // ),
  // CollapsibleGridModel(
  //   name: 'Restaurant',
  //   slugId: 'RESTAURANT',
  //   icon: AppImageAssets.restaurant,
  // ),
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

final List<CollapsibleGridModel> financeCategories = [
  CollapsibleGridModel(
      name: 'Advisory Sector',
      slugId: 'ADVISORY_SECTOR',
      icon: AppImageAssets.bankingSector
      // icon: 'https://be-user-bucket.../advisory_sector.png'
  ),
  CollapsibleGridModel(
      name: 'Banking Sector',
      slugId: 'BANKING_SECTOR',
      icon: AppImageAssets.loanSector),
  CollapsibleGridModel(
      name: 'Capital Market',
      slugId: 'CAPITAL_MARKET',
      icon: AppImageAssets.insuranceSector),
  CollapsibleGridModel(
      name: 'Data Sector',
      slugId: 'DATA_SECTOR',
      icon: AppImageAssets.capitalMarket),
  CollapsibleGridModel(
      name: 'Insurance Sector',
      slugId: 'INSURANCE_SECTOR',
      icon: AppImageAssets.dataSector),
  CollapsibleGridModel(
      name: 'Loan Sector',
      slugId: 'LOAN_SECTOR',
      icon: AppImageAssets.advisorySector),
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

final List<CollapsibleGridModel> earnWithBlueEraAddOptionsList = [
  CollapsibleGridModel(
      name: 'Home Made\nProducts',
      // name: AppStrings.homeMadeProducts,
      slugId: HOME_MADE_PRODUCTS,
      icon: AppImageAssets.homeMadeProduct),
  CollapsibleGridModel(
      name: 'Home Made\nFood Items',
      slugId: HOME_MADE_FOOD,
      icon: AppImageAssets.homeMadeFood),
  CollapsibleGridModel(
      name: 'Rental\nServices',
      // name: AppStrings.rentalServices,
      slugId: RENTAL_SERVICES,
      icon: AppImageAssets.rentalService),
];

final List<OnboardingCategoryModel> groceriesCategories = [
  OnboardingCategoryModel(
      name: 'Kirana Store',
      slugId: KIRANA_STORE,
      icon: AppImageAssets.kiranaStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Grocery),
  OnboardingCategoryModel(
      name: 'General Store',
      slugId: GENERAL_STORE,
      icon: AppImageAssets.generalStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Grocery),
  OnboardingCategoryModel(
      name: 'Vegetable & Fruit',
      slugId: VEGETABLE_FRUIT,
      icon: AppImageAssets.vegFruitStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Grocery),
  OnboardingCategoryModel(
      name: 'Dairy & Bakery',
      slugId: DAIRY_BAKERY,
      icon: AppImageAssets.dairyBakeryStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Grocery),
  OnboardingCategoryModel(
      name: 'Home Essentials',
      slugId: HOME_ESSENTIALS,
      icon: AppImageAssets.homeEssentialsStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Grocery),
  OnboardingCategoryModel(
      name: 'Stationary Shop',
      slugId: STATIONARY_SHOP,
      icon: AppImageAssets.stationaryStore,
      accountType: AppConstants.business,
      businessType: BusinessType.Grocery),
];

final List<CollapsibleGridModel> cloudKitchenHomeMadeFood = [
  CollapsibleGridModel(
      name: 'Cloud Kitchen,\nMess',
      slugId: 'CLOUD_KITCHEN_MESS',
      icon: AppImageAssets.lunchDinner,
     ),
  CollapsibleGridModel(
      name: 'Tiffin,\nLunch & Dinner',
      slugId: 'TIFFIN_LUNCH_DINNER',
      icon: AppImageAssets.tiffin,
      ),
  CollapsibleGridModel(
      name: 'Home Made\nFood',
      slugId: 'HOME_MADE_FOOD',
      icon: AppImageAssets.homeMadeFood,
    ),
];



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
//     slugId: DELIVERY_RIDER,
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

final List<Map<String, String>> chooseDeliveryOptions = [
  {
    "id": "SELF",
    "icon": AppImageAssets.selfPickupIcon,
    "title": "Self Pick-Up",
    "subtitle": "Save Your Money & Time"
  },
  {
    "id": "RIDER",
    "icon": AppIconAssets.riderIconColorful,
    "title": "Book Rider",
    "subtitle": "Quick, Personalize, ₹8/Km"
  },
  {
    "id": "PARTNER",
    "icon": AppImageAssets.transporterIcon,
    "title": "Order Via Partner",
    "subtitle": "Safe, Low Chargeable, Deliver in 1-3 Hours"
  },
];

List<PopupMenuEntry<String>> groceryPopUpMenuItems() {
  final List<Map<String, String>> items = [
    {
      'id': AppConstants.EDIT,
      'title': 'Edit Product',
      'icon': AppIconAssets.pen_line
    },
    {
      'id': AppConstants.REMOVE,
      'title': 'Remove From List',
      'icon': AppIconAssets.removeOutlinedIcon
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (var i = 0; i < items.length; i++) {
    final menu = items[i];
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: menu['id'],
        child: Row(
          children: [
            LocalAssets(imagePath: menu['icon']!),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              menu['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> medicalPopUpMenuItems() {
  final List<Map<String, String>> items = [
    {
      'id': AppConstants.EDIT,
      'title': 'Edit Product',
      'icon': AppIconAssets.pen_line
    },
    {
      'id': AppConstants.REMOVE,
      'title': 'Remove From List',
      'icon': AppIconAssets.removeOutlinedIcon
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (var i = 0; i < items.length; i++) {
    final menu = items[i];
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: menu['id'],
        child: Row(
          children: [
            LocalAssets(imagePath: menu['icon']!),
            SizedBox(width: SizeConfig.size5),
            CustomText(
              menu['title'],
              fontSize: SizeConfig.medium,
              color: AppColors.black30,
            ),
          ],
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

List<PopupMenuEntry<String>> popupSchoolDepartmentMenuItems() {
  final items = <Map<String, dynamic>>[
    {'title': AppStrings.editPost, "slud_id": 'Edit'},
    {'title': AppStrings.deletePost, "slud_id": "Delete"},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['slud_id'],
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),
      ),
    );

    if (i != items.length - 1) {
      entries.add(
        const PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(
            indent: 10,
            endIndent: 10,
            height: 1,
            thickness: 0.2,
            color: AppColors.grey99,
          ),
        ),
      );
    }
  }

  return entries;
}

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
