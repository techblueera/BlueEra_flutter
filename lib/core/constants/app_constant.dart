// ignore_for_file: constant_identifier_names

import 'dart:core';
import 'dart:math' hide log;
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/create_account_model.dart';
import 'package:BlueEra/core/api/model/onboarding_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/chat/contacts/view/contact_list_page.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
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
  static const String baseIconAssetsPath = "assets/icons/";
  static const String baseSvgAssetsPath = "assets/svg/";
  static const String baseGifsAssetsPath = "assets/gifs/";
  static const String porterLink =
      "https://porter.in/two-wheelers/pune?gads=search&utm_source=google&utm_medium=cpc&utm_campaign=20818387432&utm_term=155699175106&utm_content=proter&click_id=CjwKCAjw0sfHBhB6EiwAQtv5qYha39Cvxfna--Z62rwj2oXy0dUbTfhiY_-AkfXSSz9nIFcXetJxHxoCzWgQAvD_BwE&gad_source=1&gad_campaignid=20818387432&gbraid=0AAAAAoulZ9ihaB8xOb2NnDAf_6AJckFkq&gclid=CjwKCAjw0sfHBhB6EiwAQtv5qYha39Cvxfna--Z62rwj2oXy0dUbTfhiY_-AkfXSSz9nIFcXetJxHxoCzWgQAvD_BwE";
  static const String rapidoLink = "https://www.rapido.bike/Home";

  ///CHANGE NAME : arial to open sans some conflict are there
  // static const String arial = "OpenSans";
  static const String OpenSans = "Open Sans";

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

  // static const String personal = 'personal';
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

  static const SELF_WORK_OPTION = "SELF_WORK_OPTION";
  static const DELIVERY_PARTNER_OPTION = "DELIVERY_PARTNER_OPTION";
  static const HOME_MADE_PRODUCTS_OPTION = "HOME_MADE_PRODUCTS_OPTION";
  static const HOME_MADE_FOOD_ITEMS_OPTION = "HOME_MADE_FOOD_ITEMS_OPTION";
  static const HOME_SERVICES_OPTION = "HOME_SERVICES_OPTION";
  static const RENTAL_SERVICES_OPTION = "RENTAL_SERVICES_OPTION";
  static const COUNSELLING_CONSULTING_OPTION = "COUNSELLING_CONSULTING_OPTION";
  static const TUITION_CLASSES_ONLINE_OFFLINE_OPTION =
      "TUITION_CLASSES_ONLINE_OFFLINE_OPTION";

  static const ELECTRICIAN = "Electrician";
  static const PLUMBER = "Plumber";
  static const TECHNICIAN = "Technician";
  static const MAID_CLEANER = "Maid - Cleaner";
  static const CARPENTER = "Carpenter";
  static const CAR_DRIVER_TAXI = "Taxi - Car Driver";
  static const DELIVERY_PARTNER = "Delivery Partner";
  static const MECHANIC = "Mechanic";
  static const TAILOR = "Tailor";
  static const BEAUTICIAN = "Beautician";
  static const HOME_RENOVATION = "Home Renovator";
  static const PAINTER = "Painter";
  static const GARDENER = "Gardener";
  static const SECURITY = "Security Person";
  static const INTERIOR_DESIGNER = "Interior Designer";
  static const DIGITAL_MARKETING = "Digital Marketing";
  static const TUTOR = "Tutor";
  static const CONSULTANT = "Consultant";
  static const OTHER = "Other";
  static const TIFFIN = "Tiffin";
  static const BAKERY = "Bakery";
  static const SWEETS = "Sweets";
  static const HOME_STAY = "HOME STAY";
  static const Flat_ROOM = "Flat/Room";
  static const VEHICLE = "Vehicle";
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

String formatIndianNumber(num number) {
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
  Get.toNamed(
    RouteHelper.getSelectAccountScreenRoute(),
    arguments: {ApiKeys.argMobileNumber: userMobileGlobal},
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
    PostCreationMenu.photos,
    // if (isBusiness || channelId.isNotEmpty) PostCreationMenu.videos,

    /// for individual user if user has channel then only video section will shown
    if (isBusiness) PostCreationMenu.jobPost,
    // PostCreationMenu.place,
    // PostCreationMenu.travel,
  ];

  const iconMap = {
    PostCreationMenu.message: AppIconAssets.message_post,
    PostCreationMenu.poll: AppIconAssets.qa_ask_questionOutlinedIcon,
    PostCreationMenu.photos: AppIconAssets.photosOutlinedIcon,
    // PostCreationMenu.videos: AppIconAssets.videoOutlinedIcon,
    PostCreationMenu.jobPost: AppIconAssets.uilSuitcaseOutlinedIcon,
    // PostCreationMenu.place: AppIconAssets.locationOutlineIconGreyIcon,
    PostCreationMenu.travel: AppIconAssets.travelOutlinedIcon,
  };

  const titleMap = {
    PostCreationMenu.message: AppStrings.lekha,
    PostCreationMenu.poll: AppStrings.poll,
    PostCreationMenu.photos: AppStrings.symbol,
    PostCreationMenu.jobPost: AppStrings.jobPost,
    PostCreationMenu.travel: AppStrings.travel,
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
    {"id": "BUSINESS CARD", 'title': AppStrings.myBusinessCard}
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['id'],
        onTap: () {
          if (items[i]['id'] == "BUSINESS CARD") {
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
          if (items[i]['id'] == "CREATE_GROUP") {
            Get.to(ContactsPage(
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
const String SKILLED_WORKER = "SKILLED_WORKER";
const String CONTENT_CREATOR = "CONTENT_CREATOR";
const String POLITICIAN = "POLITICIAN";
const String GOVTPSU = "GOVTPSU";
const String REG_UNION = "REG_UNION";
const String MEDIA = "MEDIA";
const String ARTIST = "ARTIST";
const String INDUSTRIALIST = "INDUSTRIALIST";
const String SOCIALIST = "SOCIALIST";
const String HOMEMAKER = "HOMEMAKER";
const String FARMER = "FARMER";
const String SENIOR_CITIZEN_RETIRED = "SENIOR_CITIZEN_RETIRED";
const String STUDENT = "STUDENT";
const String OTHERS = "OTHERS"; // keep Others last

int kmRadius1000 = 1000;

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

final List<String> bgAssetsForProductSharing = [
  'assets/products_cards/blueera_aatmnirbhar_product_card1.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card2.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card3.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card4.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card5.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card6.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card7.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card8.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card9.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card10.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card11.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card12.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card13.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card14.jpeg',
  'assets/products_cards/blueera_aatmnirbhar_product_card15.jpeg',
];

final List<String> bgAssetsForServices = [
  'assets/services_cards/blueera_aatmnirbhar_service_card1.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card2.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card3.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card4.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card5.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card6.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card7.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card8.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card9.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card10.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card11.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card12.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card13.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card14.jpeg',
  'assets/services_cards/blueera_aatmnirbhar_service_card15.jpeg',
];

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
    slugId: AppConstants.SELF_WORK_OPTION,
    icon: AppIconAssets.plumberIcon,
    bgColor: const Color(0xFFCBEAFC),
    labelColor: const Color(0xFF004E7C),
  ),
  ServiceItem(
    name: AppStrings.deliveryPartner,
    slugId: AppConstants.DELIVERY_PARTNER_OPTION,
    icon: AppIconAssets.deliveryPartnerIcon,
    bgColor: const Color(0xFFDAEDCF),
    labelColor: const Color(0xFF204A08),
  ),
  ServiceItem(
    name: AppStrings.homeMadeProducts,
    slugId: AppConstants.HOME_MADE_PRODUCTS_OPTION,
    icon: AppIconAssets.homeMadeProductIcon,
    bgColor: const Color(0xFFFDD5A4),
    labelColor: const Color(0xFF8C4D00),
  ),
  ServiceItem(
    name: AppStrings.homeMadeFoodItems,
    slugId: AppConstants.HOME_MADE_FOOD_ITEMS_OPTION,
    icon: AppIconAssets.homeMadeFoodIcon,
    bgColor: const Color(0xFFFEF2B6),
    labelColor: const Color(0xFF856F00),
  ),
  ServiceItem(
    name: AppStrings.homeServices,
    slugId: AppConstants.HOME_SERVICES_OPTION,
    icon: AppIconAssets.homeServiceIcon,
    bgColor: const Color(0xFFDBD5F7),
    labelColor: const Color(0xFF140074),
  ),
  ServiceItem(
    name: AppStrings.rentalServices,
    slugId: AppConstants.RENTAL_SERVICES_OPTION,
    icon: AppIconAssets.rentalServiceIcon,
    bgColor: const Color(0xFFFAD7D3),
    labelColor: const Color(0xFF740C00),
  ),
  ServiceItem(
    name: AppStrings.counsellingConsulting,
    slugId: AppConstants.COUNSELLING_CONSULTING_OPTION,
    icon: AppIconAssets.consultingIcon,
    bgColor: const Color(0xFFBCEEE2),
    labelColor: const Color(0xFF006950),
  ),
  ServiceItem(
    name: AppStrings.tuitionClassesOnlineOffline,
    slugId: AppConstants.TUITION_CLASSES_ONLINE_OFFLINE_OPTION,
    icon: AppIconAssets.teachingIcon,
    bgColor: const Color(0xFFEEBCE7),
    labelColor: const Color(0xFF8B0077),
  ),
];
final List<ServiceItem> selfWorkServiceList = [
  ServiceItem(
    name: AppStrings.electrician,
    slugId: AppConstants.ELECTRICIAN,
    icon: AppIconAssets.electricianIcon,
    bgColor: const Color(0xFFFFF2DF),
    labelColor: const Color(0xFFAF6800),
  ),
  ServiceItem(
    name: AppStrings.plumber,
    slugId: AppConstants.PLUMBER,
    icon: AppIconAssets.plumberIcon,
    bgColor: const Color(0xFFFFF2C3),
    labelColor: const Color(0xFF5D4900),
  ),
  ServiceItem(
    name: AppStrings.technician,
    slugId: AppConstants.TECHNICIAN,
    icon: AppIconAssets.technicianIcon,
    bgColor: const Color(0xFFF0F4C2),
    labelColor: const Color(0xFF4E5500),
  ),
  ServiceItem(
    name: AppStrings.maidCleaner,
    slugId: AppConstants.MAID_CLEANER,
    icon: AppIconAssets.mainCleanerIcon,
    bgColor: const Color(0xFFD7EAC9),
    labelColor: const Color(0xFF183A00),
  ),
  ServiceItem(
    name: AppStrings.carpenter,
    slugId: AppConstants.CARPENTER,
    icon: AppIconAssets.carpenterIcon,
    bgColor: const Color(0xFFE1FCB3),
    labelColor: const Color(0xFF375700),
  ),
  ServiceItem(
    name: AppStrings.taxiCarDriver,
    slugId: AppConstants.CAR_DRIVER_TAXI,
    icon: AppIconAssets.taxiDriverIcon,
    bgColor: const Color(0xFFB2DFDC),
    labelColor: const Color(0xFF00625C),
  ),
  ServiceItem(
    name: AppStrings.mechanic,
    slugId: AppConstants.MECHANIC,
    icon: AppIconAssets.mechanicIcon,
    bgColor: const Color(0xFFB3E5FC),
    labelColor: const Color(0xFF003E5B),
  ),
  ServiceItem(
    name: AppStrings.homeRenovator,
    slugId: AppConstants.HOME_RENOVATION,
    icon: AppIconAssets.mistryIcon,
    bgColor: const Color(0xFFD0C4E8),
    labelColor: const Color(0xFF24006D),
  ),
  ServiceItem(
    name: AppStrings.painter,
    slugId: AppConstants.PAINTER,
    icon: AppIconAssets.painterIcon,
    bgColor: const Color(0xFFF9BBD0),
    labelColor: const Color(0xFF84002D),
  ),
  ServiceItem(
    name: AppStrings.gardener,
    slugId: AppConstants.GARDENER,
    icon: AppIconAssets.gardenerIcon,
    bgColor: const Color(0xFFA3E7A3),
    labelColor: const Color(0xFF006300),
  ),
  ServiceItem(
    name: AppStrings.securityPerson,
    slugId: AppConstants.SECURITY,
    icon: AppIconAssets.securityPersonIcon,
    bgColor: const Color(0xFFD7CCC8),
    labelColor: const Color(0xFF5B3F38),
  ),
  ServiceItem(
    name: AppStrings.other,
    slugId: AppConstants.OTHER,
    icon: AppIconAssets.staggeredIcon,
    bgColor: const Color(0xFFCFD8DD),
    labelColor: const Color(0xFF36444D),
  ),
];
final List<ServiceItem> homeServicesList = [
  ServiceItem(
    name: 'Beauty Services',
    slugId: AppConstants.BEAUTICIAN,
    icon: AppIconAssets.beautyServiceIcon,
    bgColor: const Color(0xFFFFF2DF),
    labelColor: const Color(0xFFAF6800),
  ),
  ServiceItem(
    name: 'Tailoring',
    slugId: AppConstants.TAILOR,
    icon: AppIconAssets.tailoringIcon,
    bgColor: const Color(0xFFFFF2C3),
    labelColor: const Color(0xFF5D4900),
  ),
  ServiceItem(
    name: 'Digital Marketing',
    slugId: AppConstants.DIGITAL_MARKETING,
    icon: AppIconAssets.digitalMarketingIcon,
    bgColor: const Color(0xFFF0F4C2),
    labelColor: const Color(0xFF4E5500),
  ),
  ServiceItem(
    name: 'Interior Decor',
    slugId: AppConstants.INTERIOR_DESIGNER,
    icon: AppIconAssets.interiorIcon,
    bgColor: const Color(0xFFD7EAC9),
    labelColor: const Color(0xFF183A00),
  ),
  ServiceItem(
    name: 'Other',
    slugId: AppConstants.OTHER,
    icon: AppIconAssets.staggeredIcon,
    bgColor: const Color(0xFFCFD8DD),
    labelColor: const Color(0xFF36444D),
  ),
];

final List<ServiceItem> rentalServicesList = [
  ServiceItem(
    name: 'Home Stay',
    slugId: AppConstants.HOME_STAY,
    icon: AppIconAssets.homeStayIcon,
    bgColor: const Color(0xFFFFF2DF),
    labelColor: const Color(0xFFAF6800),
  ),
  ServiceItem(
    name: 'Flat/Room',
    slugId: AppConstants.Flat_ROOM,
    icon: AppIconAssets.roomIcon,
    bgColor: const Color(0xFFF0F4C2),
    labelColor: const Color(0xFF4E5500),
  ),
  ServiceItem(
    name: 'Vehicle',
    slugId: AppConstants.VEHICLE,
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
