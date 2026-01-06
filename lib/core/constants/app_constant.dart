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
import 'package:BlueEra/features/chat/contacts/view/contact_list_page.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/auth/model/mixed_profile_categrory.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../features/chat/auth/controller/add_chat_symbol_controller.dart';
import '../../features/chat/view/add_symbol/add_symbol_screen.dart';
import '../../features/chat/view/symbol_view/symbol_view_images.dart';
import '../../features/personal/personal_profile/view/widget/service_item.dart';

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
  static const String baseImageAssetsGroceryCategoryPath = "assets/category/grocery/";
  static const String baseIconAssetsPath = "assets/icons/";
  static const String baseSvgAssetsPath = "assets/svg/";
  static const String baseGifsAssetsPath = "assets/gifs/";
  static const String porterLink =
      "https://porter.in/two-wheelers/pune?gads=search&utm_source=google&utm_medium=cpc&utm_campaign=20818387432&utm_term=155699175106&utm_content=proter&click_id=CjwKCAjw0sfHBhB6EiwAQtv5qYha39Cvxfna--Z62rwj2oXy0dUbTfhiY_-AkfXSSz9nIFcXetJxHxoCzWgQAvD_BwE&gad_source=1&gad_campaignid=20818387432&gbraid=0AAAAAoulZ9ihaB8xOb2NnDAf_6AJckFkq&gclid=CjwKCAjw0sfHBhB6EiwAQtv5qYha39Cvxfna--Z62rwj2oXy0dUbTfhiY_-AkfXSSz9nIFcXetJxHxoCzWgQAvD_BwE";
  static const String rapidoLink = "https://www.rapido.bike/Home";

  ///CHANGE NAME : arial to open sans some conflict are there
  // static const String arial = "OpenSans";
  static const String OpenSans = "Open Sans";
  static const String Regular = "Regular";

  // static const String arial = "Arial";
  static const String androidDownloadPath = "/storage/emulated/0/Download/";

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

  static const String personal_Chat_Type = 'personal';
  static const String business_Chat_Type = 'business';
  static const String group_Chat_Type = 'group';
  static const String order_Chat_Type = 'order';
  static const String AiReply_Chat_Type = 'AiReply';
  static const String AiQuest_Chat_Type = 'AiQuest';
  static const String askInentory_Chat_Type = 'askInentory';
  // static const String business = 'business';
  // static const String company = 'company';
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
  static const String feedScreen = "feedScreen";
  static const String storeFeedScreen = "storeFeedScreen";
  static const String food = "food";
  static const String product = "product";
  static const String service = "service";
  static const String chatMsgBusinessType = "business";
  static const String channelFeedList = "channelFeedList";
  static const String channelOTTList = "channelOTTList";


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

  static const storeAi = "StoreAi";


}

class DocumentKeys {
  static const aadhar = "aadhar";
  static const pan = "pan";
  static const drivingLicense = "drivingLicense";
  static const vehicleRC = "vehicleRC";
  static const addressProof = "addressProof";
  static const noc = "noc";
  static const bankersCancelledCheque = "bankersCancelledCheque";

  // Business Keys
  static const gstCertificate = "gstCertificate";
  static const fssaiLicense = "fssaiLicense";
  static const medicalLicense = "medicalLicense";
  static const fireSafetyCertificate = "fireSafetyCertificate";
  static const municipalCorpCertificate = "municipalCorpCertificate";
  static const msmeCertificate = "msmeCertificate";
  static const shopActCertificate  = "shopActCertificate"; // Removed trailing space
}

///IS GUEST USER...
bool isGuestUser() => (accountTypeGlobal.toUpperCase() == AppConstants.guest);
A getOrPutController<A>(A Function() create) {
  if (Get.isRegistered<A>()) {
    return Get.find<A>();
  } else {
    return Get.put<A>(create());
  }
}

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
  Get.toNamed(
    RouteHelper.getCreateNewAccountScreenRoute(),
    // arguments: {ApiKeys.argMobileNumber: userMobileGlobal},
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
    {"id": "VIEW_SYMBOL", 'title': "View Symbol"},
    {"id": "CREATE_GROUP", 'title': AppStrings.createGroup},
    {"id": "THEME", 'title': AppStrings.theme},
    {"id": "WALLPAPER", 'title': AppStrings.wallpaper},
    {"id": "LOCK_CHAT", 'title': AppStrings.lockChat},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == "VIEW_SYMBOL") {
            final addSymbolController = Get.isRegistered<AddChatSymbolController>()
                ? Get.find<AddChatSymbolController>()
                : Get.put(AddChatSymbolController());
            Get.to(()=>SymbolViewImages(
              mySymbols: addSymbolController.mySymbols,
            ));
          }else
            if (items[i]['id'] == "CREATE_GROUP") {
            Get.to(()=>ContactsPage(
              from: "group",
            ));
          } else if (items[i]['id'] == "THEME") {
            commonSnackBar(message: "Coming soon....");
          } else if (items[i]['id'] == "WALLPAPER") {
            commonSnackBar(message: "Coming soon....");
          } else if (items[i]['id'] == "LOCK_CHAT") {
            commonSnackBar(message: "Coming soon....");
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
List<String> isShowProduct = ["product", "service", "both"];
List<String> isShowService = ["product", "service", "both", "food"];
List<String> isShowFood = ["food"];

String? businessType() {
  final controller = Get.find<ViewBusinessDetailsController>();
  return controller.businessProfileDetails?.data?.typeOfBusiness?.toLowerCase();
}

List<PopupMenuEntry<InventoryMenuItem>> popupMenuInventoryItems(
    String businessType) {
  final items = <InventoryMenuItem>[
    if (isShowProduct.contains(businessType)) InventoryMenuItem.addProduct,
    if (isShowService.contains(businessType)) InventoryMenuItem.addService,
    if (isShowFood.contains(businessType)) InventoryMenuItem.addFood,
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


// Constants
const String SELF_EMPLOYED = "SELF_EMPLOYED";
const String PRIVATE_JOB = "PRIVATE_JOB";
const String GOVERNMENT_JOB = "GOVERNMENT_JOB";
const String CONTENT_CREATOR = "CONTENT_CREATOR";
const String POLITICIAN = "POLITICIAN";
const String GOVTPSU = "GOVTPSU";
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
const String MAID_CLEANER = "MAID_CLEANER";
const String CARPENTER = "CARPENTER";
const String CAR_DRIVER_TAXI = "CAR_DRIVER_TAXI";
const String DELIVERY_RIDER = "DELIVERY_RIDER";
const String MECHANIC = "MECHANIC";
const String TAILOR = "TAILOR";
const String BEAUTICIAN = "BEAUTICIAN";
const String HOME_RENOVATION = "HOME_RENOVATION";
const String PAINTER = "PAINTER";
const String GARDENER = "GARDENER";
const String SECURITY = "SECURITY";
const String INTERIOR_DESIGNER = "INTERIOR_DESIGNER";
const String DIGITAL_MARKETING = "DIGITAL_MARKETING";
const String TUTOR = "TUTOR";
const String CONSULTANT = "CONSULTANT";
const String OTHER = "OTHER";

int kmRadius1000 = 1000;
int kmRadius1500 = 1500;

const HOME_MADE_PRODUCTS_OPTION = "HOME_MADE_PRODUCTS_OPTION";
const HOME_MADE_FOOD_ITEMS_OPTION = "HOME_MADE_FOOD_ITEMS_OPTION";
const HOME_SERVICES_OPTION = "HOME_SERVICES_OPTION";
const RENTAL_SERVICES_OPTION = "RENTAL_SERVICES_OPTION";
const TIFFIN = "TIFFIN";
const BAKERY = "BAKERY";
const SWEETS = "SWEETS";
const HOME_STAY = "HOME_STAY";
const Flat_ROOM = "Flat_ROOM";
const VEHICLE = "VEHICLE";




// biscuit & foods
 const String CHIPS_NAMKEEN       = 'CHIPS_NAMKEEN';
 const String BISCUITS_COOKIES    = 'BISCUITS_COOKIES';
 const String CHOCOLATES_CANDIES  = 'CHOCOLATES_CANDIES';
 const String INDIAN_SWEETS       = 'INDIAN_SWEETS';
 const String DRINKS_JUICES       = 'DRINKS_JUICES';
 const String BREAKFAST_CEREALS   = 'BREAKFAST_CEREALS';
 const String NOODLES_PASTA       = 'NOODLES_PASTA';
 const String READY_TO_COOK      = 'READY_TO_COOK';
 const String SPREAD              = 'SPREAD';
 const String PICKLES             = 'PICKLES';
 const String TEA                 = 'TEA';

// fruits & veg
 const String FRESH_FRUITS        = 'FRESH_FRUITS';
 const String BASIC_VEGETABLES    = 'BASIC_VEGETABLES';
 const String PREMIUM_FV          = 'PREMIUM_FV';

// cooking essentials
 const String RICE                = 'RICE';
 const String DALS_PULSES         = 'DALS_PULSES';
 const String GHEE                = 'GHEE';
 const String WHEAT_SOYA          = 'WHEAT_SOYA';
 const String SALT_SUGAR_JAGGERY  = 'SALT_SUGAR_JAGGERY';
 const String SNACK_BASES         = 'SNACK_BASES';
 const String ATTA_FLOURS         = 'ATTA_FLOURS';
 const String DRY_FRUITS          = 'DRY_FRUITS';
 const String EDIBLE_OILS         = 'EDIBLE_OILS';
 const String MILLET_ORGANIC      = 'MILLET_ORGANIC';

// dairy_items & bakery
 const String MILK_PRODUCTS       = 'MILK_PRODUCTS';
 const String CHEESE_PANEER_TOFU  = 'CHEESE_PANEER_TOFU';
 const String BUTTER_CHUTNEY      = 'BUTTER_CHUTNEY';
 const String TOAST_KHARI         = 'TOAST_KHARI';
 const String CAKES_MUFFINS       = 'CAKES_MUFFINS';
 const String BREADS_CHAPATIS     = 'BREADS_CHAPATIS';
 const String BAKERY_SNACKS       = 'BAKERY_SNACKS';

// mom & baby
 const String BABY_FOOD           = 'BABY_FOOD';
 const String BABY_HYGIENE        = 'BABY_HYGIENE';
 const String BABY_TOYS           = 'BABY_TOYS';
 const String BABY_HEALTH         = 'BABY_HEALTH';
 const String DIAPERS_WIPES       = 'DIAPERS_WIPES';

// kitchenware
 const String GAS_STOVE           = 'GAS_STOVE';
 const String STORAGE_CONTAINERS  = 'STORAGE_CONTAINERS';
 const String BOTTLES_FLASKS      = 'BOTTLES_FLASKS';
 const String CUTTING_CHOPPING    = 'CUTTING_CHOPPING';
 const String KITCHEN_TOOLS       = 'KITCHEN_TOOLS';
 const String BAKEWARE            = 'BAKEWARE';

// tableware
 const String DINING              = 'DINING';
 const String SERVEWARE           = 'SERVEWARE';
 const String BARWARE             = 'BARWARE';
 const String TABLE_ACCESSORIES   = 'TABLE_ACCESSORIES';
 const String CUPS_MUGS           = 'CUPS_MUGS';
 const String GLASSWARE           = 'GLASSWARE';

// gifts
 const String TEA_GIFTS           = 'TEA_GIFTS';
 const String CHOCOLATE_GIFTS     = 'CHOCOLATE_GIFTS';
 const String GOURMET_GIFTS       = 'GOURMET_GIFTS';

// home
 const String DETERGENTS          = 'DETERGENTS';
 const String FRESHENERS          = 'FRESHENERS';
 const String CLEANING_TOOLS      = 'CLEANING_TOOLS';
 const String FURNISHING          = 'FURNISHING';
 const String DISHWASH            = 'DISHWASH';
 const String POOJA_NEEDS         = 'POOJA_NEEDS';
 const String ELECTRICALS         = 'ELECTRICALS';
 const String SHOE_CARE           = 'SHOE_CARE';
 const String FURNITURE           = 'FURNITURE';
 const String BAGS_TRAVEL         = 'BAGS_TRAVEL';


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

final List<ServiceItem> earnWithBlueEraServiceList = [
  ServiceItem(
    name: AppStrings.selfWork,
    slugId: SELF_EMPLOYED,
    icon: AppIconAssets.plumberIcon,
    bgColor: const Color(0xFFCBEAFC),
    labelColor: const Color(0xFF004E7C),
  ),
  ServiceItem(
    name: AppStrings.deliveryPartner,
    slugId: DELIVERY_RIDER,
    icon: AppIconAssets.deliveryPartnerIcon,
    bgColor: const Color(0xFFDAEDCF),
    labelColor: const Color(0xFF204A08),
  ),
  ServiceItem(
    name: AppStrings.homeMadeProducts,
    slugId: HOME_MADE_PRODUCTS_OPTION,
    icon: AppIconAssets.homeMadeProductIcon,
    bgColor: const Color(0xFFFDD5A4),
    labelColor: const Color(0xFF8C4D00),
  ),
  ServiceItem(
    name: AppStrings.homeMadeFoodItems,
    slugId: HOME_MADE_FOOD_ITEMS_OPTION,
    icon: AppIconAssets.homeMadeFoodIcon,
    bgColor: const Color(0xFFFEF2B6),
    labelColor: const Color(0xFF856F00),
  ),
  ServiceItem(
    name: AppStrings.homeServices,
    slugId: HOME_SERVICES_OPTION,
    icon: AppIconAssets.homeServiceIcon,
    bgColor: const Color(0xFFDBD5F7),
    labelColor: const Color(0xFF140074),
  ),
  ServiceItem(
    name: AppStrings.rentalServices,
    slugId: RENTAL_SERVICES_OPTION,
    icon: AppIconAssets.rentalServiceIcon,
    bgColor: const Color(0xFFFAD7D3),
    labelColor: const Color(0xFF740C00),
  ),
  ServiceItem(
    name: AppStrings.counsellingConsulting,
    slugId: CONSULTANT,
    icon: AppIconAssets.counsellingServiceIcon,
    bgColor: const Color(0xFFBCEEE2),
    labelColor: const Color(0xFF006950),
  ),
  ServiceItem(
    name: AppStrings.tuitionClassesOnlineOffline,
    slugId: TUTOR,
    icon: AppIconAssets.teachingIcon,
    bgColor: const Color(0xFFEEBCE7),
    labelColor: const Color(0xFF8B0077),
  ),
];

final List<ServiceItem> selfWorkServiceList = [
  ServiceItem(
    name: AppStrings.electrician,
    slugId: ELECTRICIAN,
    icon: AppIconAssets.electricianIcon,
    bgColor: const Color(0xFFFFF2DF),
    labelColor: const Color(0xFFAF6800),
  ),
  ServiceItem(
    name: AppStrings.plumber,
    slugId: PLUMBER,
    icon: AppIconAssets.plumberIcon,
    bgColor: const Color(0xFFFFF2C3),
    labelColor: const Color(0xFF5D4900),
  ),
  ServiceItem(
    name: AppStrings.technician,
    slugId: TECHNICIAN,
    icon: AppIconAssets.technicianIcon,
    bgColor: const Color(0xFFF0F4C2),
    labelColor: const Color(0xFF4E5500),
  ),
  ServiceItem(
    name: AppStrings.maidCleaner,
    slugId: MAID_CLEANER,
    icon: AppIconAssets.mainCleanerIcon,
    bgColor: const Color(0xFFD7EAC9),
    labelColor: const Color(0xFF183A00),
  ),
  ServiceItem(
    name: AppStrings.carpenter,
    slugId: CARPENTER,
    icon: AppIconAssets.carpenterIcon,
    bgColor: const Color(0xFFE1FCB3),
    labelColor: const Color(0xFF375700),
  ),
  ServiceItem(
    name: AppStrings.taxiCarDriver,
    slugId: CAR_DRIVER_TAXI,
    icon: AppIconAssets.taxiDriverIcon,
    bgColor: const Color(0xFFB2DFDC),
    labelColor: const Color(0xFF00625C),
  ),
  ServiceItem(
    name: AppStrings.mechanic,
    slugId: MECHANIC,
    icon: AppIconAssets.mechanicIcon,
    bgColor: const Color(0xFFB3E5FC),
    labelColor: const Color(0xFF003E5B),
  ),
  ServiceItem(
    name: AppStrings.homeRenovator,
    slugId: HOME_RENOVATION,
    icon: AppIconAssets.mistryIcon,
    bgColor: const Color(0xFFD0C4E8),
    labelColor: const Color(0xFF24006D),
  ),
  ServiceItem(
    name: AppStrings.painter,
    slugId: PAINTER,
    icon: AppIconAssets.painterIcon,
    bgColor: const Color(0xFFF9BBD0),
    labelColor: const Color(0xFF84002D),
  ),
  ServiceItem(
    name: AppStrings.gardener,
    slugId: GARDENER,
    icon: AppIconAssets.gardenerIcon,
    bgColor: const Color(0xFFA3E7A3),
    labelColor: const Color(0xFF006300),
  ),
  ServiceItem(
    name: AppStrings.securityPerson,
    slugId: SECURITY,
    icon: AppIconAssets.securityPersonIcon,
    bgColor: const Color(0xFFD7CCC8),
    labelColor: const Color(0xFF5B3F38),
  ),
  ServiceItem(
    name: AppStrings.other,
    slugId: OTHER,
    icon: AppIconAssets.staggeredIcon,
    bgColor: const Color(0xFFCFD8DD),
    labelColor: const Color(0xFF36444D),
  ),
];

final List<ServiceItem> homeServicesList = [
  ServiceItem(
    name: AppStrings.beautyServices,
    slugId: BEAUTICIAN,
    icon: AppIconAssets.beautyServiceIcon,
    bgColor: const Color(0xFFFFF2DF),
    labelColor: const Color(0xFFAF6800),
  ),
  ServiceItem(
    name: AppStrings.tailoring,
    slugId: TAILOR,
    icon: AppIconAssets.tailoringIcon,
    bgColor: const Color(0xFFFFF2C3),
    labelColor: const Color(0xFF5D4900),
  ),
  ServiceItem(
    name: AppStrings.digitalMarketing,
    slugId: DIGITAL_MARKETING,
    icon: AppIconAssets.digitalMarketingIcon,
    bgColor: const Color(0xFFF0F4C2),
    labelColor: const Color(0xFF4E5500),
  ),
  ServiceItem(
    name:  AppStrings.interiorDecor,
    slugId: INTERIOR_DESIGNER,
    icon: AppIconAssets.interiorIcon,
    bgColor: const Color(0xFFD7EAC9),
    labelColor: const Color(0xFF183A00),
  ),
  ServiceItem(
    name: AppStrings.other,
    slugId: OTHER,
    icon: AppIconAssets.staggeredIcon,
    bgColor: const Color(0xFFCFD8DD),
    labelColor: const Color(0xFF36444D),
  ),
];

final List<ServiceItem> rentalServicesList = [
  ServiceItem(
    name: AppStrings.homeStay,
    slugId: HOME_STAY,
    icon: AppIconAssets.homeStayIcon,
    bgColor: const Color(0xFFFFF2DF),
    labelColor: const Color(0xFFAF6800),
  ),
  ServiceItem(
    name: AppStrings.flatRoom,
    slugId: Flat_ROOM,
    icon: AppIconAssets.roomIcon,
    bgColor: const Color(0xFFF0F4C2),
    labelColor: const Color(0xFF4E5500),
  ),
  ServiceItem(
    name: AppStrings.vehicle,
    slugId: VEHICLE,
    icon: AppIconAssets.vehicleIcon,
    bgColor: const Color(0xFFD7EAC9),
    labelColor: const Color(0xFF183A00),
  ),
  // ServiceItem(
  //   label: 'Other',
  //   name: AppConstants.OTHER,
  //   icon: AppIconAssets.staggeredIcon,
  //   bgColor: const Color(0xFFCFD8DD),
  //   labelColor: const Color(0xFF36444D),
  // ),
];

class ChatEmitEvents{
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

final List<IndividualProfileCategory> selfEmployedCategories = [
  IndividualProfileCategory(
    name: AppStrings.electrician,
    slugId: ELECTRICIAN,
    icon: AppIconAssets.electricianIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.plumber,
    slugId: PLUMBER,
    icon: AppIconAssets.plumberIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.technician,
    slugId: TECHNICIAN,
    icon: AppIconAssets.technicianIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.maidCleaner,
    slugId: MAID_CLEANER,
    icon: AppIconAssets.mainCleanerIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.carpenter,
    slugId: CARPENTER,
    icon: AppIconAssets.carpenterIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.painter,
    slugId: PAINTER,
    icon: AppIconAssets.painterIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.mechanic,
    slugId: MECHANIC,
    icon: AppIconAssets.mechanicIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.homeRenovator,
    slugId: HOME_RENOVATION,
    icon: AppIconAssets.mistryIcon,
  ),
];

/// Business Categories
final List<BusinessProfileCategory> businessServicesCategories = [
  BusinessProfileCategory(
      name: AppStrings.consulting,
      slugId: AppConstants.consulting,
      // categoryId: '68ce990deac48e6b0d497298',
      icon: AppIconAssets.consultingServiceIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.automotive,
      slugId: AppConstants.automotive,
      // categoryId: '68ce990beac48e6b0d49724f',
      icon: AppIconAssets.automativeServiceIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.itCommunication,
      slugId: AppConstants.itCommunication,
      // categoryId: '68ce9914eac48e6b0d497366',
      icon: AppIconAssets.itCommunicationIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.homeUtility,
      slugId: AppConstants.homeUtility,
      // categoryId: '68ce9912eac48e6b0d497328',
      icon: AppIconAssets.homeServiceUtilityIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.mediaCreative,
      slugId: AppConstants.mediaCreative,
      // categoryId: '68ce9915eac48e6b0d497382',
      icon: AppIconAssets.mediaPublicityIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.educationTraining,
      slugId: AppConstants.educationTraining,
      // categoryId: '68ce990eeac48e6b0d4972ad',
      icon: AppIconAssets.educationTrainingIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.tourTravel,
      slugId: AppConstants.tourTravel,
      // categoryId: '68ce9916eac48e6b0d4973aa',
      icon: AppIconAssets.tourTravelIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.beautyCare,
      slugId: AppConstants.beautyCare,
      // categoryId: '68ce990beac48e6b0d497260',
      icon: AppIconAssets.beautyPersonalCareIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.serviceCenter,
      slugId: AppConstants.serviceCenter,
      // categoryId: '68ce9915eac48e6b0d497397',
      icon: AppIconAssets.serviceCenterIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.logistics,
      slugId: AppConstants.logistics,
      // categoryId: '68ce9914eac48e6b0d497375',
      icon: AppIconAssets.logisticTransportationIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.celebrationEvent,
      slugId: AppConstants.celebrationEvent,
      // categoryId: '68ce990ceac48e6b0d49727f',
      icon: AppIconAssets.celebrationEventIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.financial,
      slugId: AppConstants.financial,
      // categoryId: '68ce990feac48e6b0d4972dc',
      icon: AppIconAssets.financialIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.healthcareMedicalServices,
      slugId: AppConstants.healthcareMedicalServices,
      // categoryId: '68ce9910eac48e6b0d4972ed',
      icon: AppIconAssets.healthCareIcon,
      type: AppConstants.service),
  BusinessProfileCategory(
      name: AppStrings.hostelsStayService,
      slugId: AppConstants.hostelsStayService,
      // categoryId: '68ce9912eac48e6b0d497341',
      icon: AppIconAssets.hostelIcon,
      type: AppConstants.service),
];

final List<BusinessProfileCategory> businessProductsCategories = [
  BusinessProfileCategory(
      name: AppStrings.furnitureHomeDecor,
      slugId: AppConstants.furnitureHomeDecor,
      // categoryId: '68ce9907eac48e6b0d4971f7',
      icon: AppImageAssets.furnitureHomeDecorIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.sportsFitness,
      slugId: AppConstants.sportsFitness,
      // categoryId: '68ce990aeac48e6b0d497235',
      icon: AppImageAssets.sportsFitnessStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.jewelleryLuxury,
      slugId: AppConstants.jewelleryLuxury,
      // categoryId: '68ce9908eac48e6b0d497204',
      icon: AppImageAssets.jewelleryLuxuryStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.automotiveStore,
      slugId: AppConstants.automotiveStore,
      // categoryId: '68ce9904eac48e6b0d497192',
      icon: AppImageAssets.automotiveStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.booksStationaryGifts,
      slugId: AppConstants.booksStationaryGifts,
      // categoryId: '68ce9905eac48e6b0d4971a5',
      icon: AppImageAssets.booksStationaryGiftsIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.pharmacyMedical,
      slugId: AppConstants.pharmacyMedical,
      // categoryId: '68ce9909eac48e6b0d497217',
      icon: AppImageAssets.pharmacyMedicalStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.petSupplies,
      slugId: AppConstants.petSupplies,
      // categoryId: '68ce9909eac48e6b0d497217',
      icon: AppImageAssets.petSuppliesStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.toysBabyProducts,
      slugId: AppConstants.toysBabyProducts,
      // categoryId: '68ce990aeac48e6b0d497244',
      icon: AppImageAssets.babyToysProductStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.electronicsAppliances,
      slugId: AppConstants.electronicsAppliances,
      // categoryId: '68ce9906eac48e6b0d4971c5',
      icon: AppImageAssets.electronicsApplianceStoreIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.constructionHomeEssentials,
      slugId: AppConstants.constructionHomeEssentials,
      // categoryId: '68ce9905eac48e6b0d4971b0',
      icon: AppImageAssets.constructionHomeEsseIcon,
      type: AppConstants.product),
  BusinessProfileCategory(
      name: AppStrings.fashionLifestyle,
      slugId: AppConstants.fashionLifestyle,
      // categoryId: '68ce9907eac48e6b0d4971dc',
      icon: AppImageAssets.fashionLifestyleIcon,
      type: AppConstants.product
  ),
];

final List<BusinessProfileCategory> businessFoodsCategories = [
  BusinessProfileCategory(
      name: AppStrings.fastFoodQuickService,
      slugId: AppConstants.fastFoodQuickService,
      // categoryId: '68ce9917eac48e6b0d4973cc',
      icon: AppIconAssets.fastFoodQuickServiceIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.multiCuisineRestaurants,
      slugId: AppConstants.multiCuisineRestaurants,
      // categoryId: '68ce9919eac48e6b0d49740a',
      icon: AppIconAssets.multiCuisineRestroIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.groceryVegetablesDairy,
      slugId: AppConstants.groceryVegetablesDairy,
      // categoryId: '68ce9917eac48e6b0d4973bf',
      icon: AppIconAssets.groceryVegetableDairyIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.nonVegRestaurants,
      slugId: AppConstants.nonVegRestaurants,
      // categoryId: '68ce9919eac48e6b0d4973e8',
      icon: AppIconAssets.nonVegRestaurantIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.vegRestaurants,
      slugId: AppConstants.vegRestaurants,
      // categoryId: '68ce9918eac48e6b0d4973d9',
      icon: AppIconAssets.vegRestaurantIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.otherRestaurantsDhaba,
      slugId: AppConstants.otherRestaurantsDhaba,
      // categoryId: '68ce991aeac48e6b0d497417',
      icon: AppIconAssets.restaurantIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.sweetsBakeryDrinks,
      slugId: AppConstants.sweetsBakeryDrinks,
      // categoryId: '68ce9918eac48e6b0d4973d9',
      icon: AppIconAssets.sweetBakeryDrinkIcon,
      type: AppConstants.food
  ),
  BusinessProfileCategory(
      name: AppStrings.otherFoodServices,
      slugId: AppConstants.otherFoodServices,
      // categoryId: '68ce991aeac48e6b0d497428',
      icon: AppIconAssets.staggeredIcon,
      type: AppConstants.food
  ),
];

/// Individual Categories
final List<IndividualProfileCategory> individualSocialProfileList = [
  IndividualProfileCategory(
    name: AppStrings.politician,
    slugId: POLITICIAN,
    icon: AppIconAssets.politicianIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.socialist,
    slugId: SOCIALIST,
    icon: AppIconAssets.socialistIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.journalist,
    slugId: MEDIA,
    icon: AppIconAssets.journalistIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.artist,
    slugId: ARTIST,
    icon: AppIconAssets.artistIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.director,
    slugId: DIRECTOR,
    icon: AppIconAssets.directorIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.homeMaker,
    slugId: HOMEMAKER,
    icon: AppIconAssets.homeMakerIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.govtEmployee,
    slugId: GOVERNMENT_JOB,
    icon: AppIconAssets.govtEmpIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.pvtEmployee,
    slugId: PRIVATE_JOB,
    icon: AppIconAssets.pvtEmpIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.ngoSociety,
    slugId: REG_UNION, //NGO
    icon: AppIconAssets.ngoSocietyIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.govtDepartment,
    slugId: GOVTPSU,
    icon: AppIconAssets.govtDeptIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.contentCreator,
    slugId: CONTENT_CREATOR,
    icon: AppIconAssets.contentCreaterIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.others,
    slugId: OTHERS,
    icon: AppIconAssets.staggeredIcon,
  ),
];

final List<IndividualProfileCategory> individualOtherSocialProfileList = [
  IndividualProfileCategory(
    name: AppStrings.student,
    slugId: STUDENT,
    icon: AppIconAssets.studentIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.skilledWorker,
    slugId: SKILLED_WORKER,
    icon: AppIconAssets.skilledWorkerIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.farmer,
    slugId: FARMER,
    icon: AppIconAssets.farmerIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.industrialist,
    slugId: INDUSTRIALIST,
    icon: AppIconAssets.industrialistIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.seniorCitizen,
    slugId: SENIOR_CITIZEN,
    icon: AppIconAssets.seniorCitizenIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.other,
    slugId: OTHERS,
    icon: AppIconAssets.staggeredIcon,
  ),
];

final List<IndividualProfileCategory> individualSelfEmployedList = [
  IndividualProfileCategory(
      name: AppStrings.rider,
      slugId: DELIVERY_RIDER,
      icon: AppIconAssets.riderIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.electrician,
    slugId: ELECTRICIAN,
    icon: AppIconAssets.electricianIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.plumber,
    slugId: PLUMBER,
    icon: AppIconAssets.plumberIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.technician,
    slugId: TECHNICIAN,
    icon: AppIconAssets.technicianIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.maidCleaner,
    slugId: MAID_CLEANER,
    icon: AppIconAssets.mainCleanerIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.carpenter,
    slugId: CARPENTER,
    icon: AppIconAssets.carpenterIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.taxiCarDriver,
    slugId: CAR_DRIVER_TAXI,
    icon: AppIconAssets.taxiDriverIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.mechanic,
    slugId: MECHANIC,
    icon: AppIconAssets.mechanicIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.homeRenovator,
    slugId: HOME_RENOVATION,
    icon: AppIconAssets.mistryIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.painter,
    slugId: PAINTER,
    icon: AppIconAssets.painterIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.gardener,
    slugId: GARDENER,
    icon: AppIconAssets.gardenerIcon,
  ),
  IndividualProfileCategory(
    name: AppStrings.securityPerson,
    slugId: SECURITY,
    icon: AppIconAssets.securityPersonIcon,
  )
];

List<PopupMenuEntry<String>> groceryPopupMenuItems() {
  final List<Map<String, String>> items = [
    {'id': AppConstants.EDIT, 'title': 'Edit Product', 'icon': AppIconAssets.pen_line},
    {'id': AppConstants.REMOVE, 'title': 'Remove From List', 'icon': AppIconAssets.removeOutlinedIcon},
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

List<PopupMenuEntry<String>> groceryPopUpMenuItems() {
  final items = <Map<String, dynamic>>[
    {
      "id": AppConstants.ADD,
      'title': AppStrings.addManually
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == AppConstants.ADD) {
            // Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
           }
          },
        child: CustomText(
          items[i]['title'],
          fontSize: SizeConfig.medium,
          color: AppColors.black30,
        ),

        // Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     LocalAssets(
        //         imagePath: items[i]['icon'],
        //         height: SizeConfig.size20,
        //         width: SizeConfig.size20),
        //     SizedBox(width: SizeConfig.size5),
        //     CustomText(
        //       items[i]['title'],
        //       fontSize: SizeConfig.medium,
        //       color: AppColors.black30,
        //     ),
        //   ],
        // ),

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


