// ignore_for_file: constant_identifier_names

import 'dart:core';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/create_account_model.dart';
import 'package:BlueEra/core/api/model/onboarding_model.dart';
import 'package:BlueEra/core/api/model/service_category_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/l10n/app_localizations_en.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../l10n/app_localizations.dart';
import 'package:image/image.dart' as img;

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

  ///CHANGE NAME : arial to open sans some conflict are there
  // static const String arial = "OpenSans";
  static const String OpenSans = "OpenSans";

  // static const String arial = "Arial";
  static const String androidDownloadPath = "/storage/emulated/0/Download/";

  static const int inputCharterLimit = 150;
  static const int inputCharterLimit250 = 250;
  static const int inputCharterLimit200 = 200;
  static const int inputCharterLimit50 = 50;
  static const int inputCharterLimit10 = 10;
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
  static const String selectSelfArtist = "Eg. Painter...";
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
  static const rescheduled = "rescheduled";
  static const String Interviewing = "Interviewing";
  static const String Withdrawn = "Withdrawn";
  static const String Landscape = "Landscape";
  static const String Square = "Square";
  static const String chatScreen = "chatScreen";
  static const String feedScreen = "feedScreen";

  static Future<bool> checkInternet() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.ethernet)
        ? true
        : false;
  }
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

String formatNumberLikePost(int number) {
  if (number >= 1000000) {
    return "${(number / 1000000).toStringAsFixed(1)}M";
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(1)}K";
  } else {
    return number.toString();
  }
}

stringDateFormat({required int year, required int month, required int day}) {
  DateTime date = DateTime(year, month, day);

  return DateFormat("MMMM, d").format(date);
}

stringDateFormatDate({required String dateValue}) {
  DateTime date = DateTime.parse(dateValue);

  return DateFormat("MMMM, y").format(date);
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

class AccountType {
  static const String personal = 'PERSONAL';
  static const String company = 'COMPANY';
}

redirectToProfileScreen(
    {required String accountType, required String profileId}) {
  String? accountTypeData = accountType.toUpperCase();
  // logs("user.accountType?=== ${user.accountType}");
  if (accountType.toUpperCase() == AppConstants.individual) {
    if (userId == profileId) {
      Get.to(PersonalProfileSetupScreen());
    } else {
      Get.to(() => NewVisitProfileScreen(
            authorId: profileId ?? "",
            screenFromName: AppConstants.feedScreen,
            channelId: '',
          ));
    }
  }
  if (accountTypeData == AppConstants.business) {
    if (businessId == profileId) {
      Get.to(BusinessOwnProfileScreen());
    } else {
      Get.to(() => VisitBusinessProfileNew(
          businessId:profileId ?? ""));
    }
  }
}

List<String> generate24HoursAmPm() {
  return List.generate(24, (hour) {
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final String period = hour < 12 ? 'AM' : 'PM';
    return '${displayHour.toString().padLeft(2, '0')}:00 $period';
  });
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

List<String> daysOfWeek = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

List<String> selectGenderList = [
  "Male",
  "Female",
];

void createProfileScreen() {
  logs("userMobileGlobal=== ${userMobileGlobal}");
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

///API CALLING VALUE...
noticePeriodAPISending({String? keyName}) {
  return keyName == "Immediately (7 Days)"
      ? "IMMEDIATE"
      : keyName == "15 Days"
          ? "FIFTEEN_DAYS"
          : keyName == "30 Days"
              ? "ONE_MONTH"
              : keyName == "45 Days"
                  ? "FORTY_FIVE_DAYS"
                  : keyName == "60 Days"
                      ? "TWO_MONTHS"
                      : keyName == "90 Days"
                          ? "THREE_MONTHS"
                          : "";
}

String formatLastSeen(BuildContext context, int secondsAgo) {
  final localizations = AppLocalizations.of(context)!;

  if (secondsAgo == 0) {
    return localizations.online;
  }

  DateTime now = DateTime.now();
  DateTime lastSeenTime = now.subtract(Duration(seconds: secondsAgo));
  String formattedTime = DateFormat('hh:mm a').format(lastSeenTime);

  if (lastSeenTime.year == now.year &&
      lastSeenTime.month == now.month &&
      lastSeenTime.day == now.day) {
    return localizations.last_seen_today(formattedTime);
  } else if (lastSeenTime.year == now.year &&
      lastSeenTime.month == now.month &&
      lastSeenTime.day == now.day - 1) {
    return localizations.last_seen_yesterday(formattedTime);
  } else {
    String dayName = DateFormat('EEEE').format(lastSeenTime);
    return localizations.last_seen_on_day(dayName, formattedTime);
  }
}

///DISPLAY DROP DOWN VALUE...
setNoticePeriod({String? keyName}) {
  return keyName == "IMMEDIATE"
      ? "Immediately (7 Days)"
      : keyName == "FIFTEEN_DAYS"
          ? "15 Days"
          : keyName == "ONE_MONTH"
              ? "30 Days"
              : keyName == "FORTY_FIVE_DAYS"
                  ? "45 Days"
                  : keyName == "TWO_MONTHS"
                      ? "60 Days"
                      : keyName == "THREE_MONTHS"
                          ? "90 Days"
                          : "";
}

final List<String> noticePeriods = [
  'Immediately (7 Days)',
  '15 Days',
  '30 Days',
  '45 Days',
  '60 Days',
  '90 Days',
];
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

List<Locale> getSupportedLocales() {
  return [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('or'), // Odia
    Locale('bn'), // Bengali
    Locale('as'), // Assamese
    Locale('te'), // Telugu
    Locale('ta'), // Tamil
    Locale('ml'), // Malayalam
    Locale('mr'), // Marathi
    Locale('kn'), // Kannada
    Locale('gu'), // Gujarati
    Locale('pa'), // Punjabi
  ];
}

AppLocalizationsEn loc = AppLocalizationsEn();

List<OnboardingData> getOnboardingPages() => [
      OnboardingData(
        title: loc.onBoarding1Title,
        description: loc.onBoarding1SubTitle,
        imageAsset: AppIconAssets.on_boarding1,
      ),
      OnboardingData(
        title: loc.onBoarding2Title,
        description: loc.onBoarding2SubTitle,
        imageAsset: AppIconAssets.on_boarding2,
      ),
      OnboardingData(
        title: loc.onBoarding3Title,
        description: loc.onBoarding3SubTitle,
        imageAsset: AppIconAssets.on_boarding3,
      ),
      OnboardingData(
        title: loc.onBoarding4Title,
        description: loc.onBoarding4SubTitle,
        imageAsset: AppIconAssets.on_boarding4,
      ),
    ];

List<AccountOption> getCreateAccountType() => [
      AccountOption(
        id: AppConstants.individual,
        title: loc.accountType1Title,
        subtitle: loc.accountType1SubTitle,
        description: loc.accountType1Description,
        iconPath: AppIconAssets.personal_account,
      ),
      AccountOption(
        id: AppConstants.business,
        title: "Shop / Services / Business Listing",
        subtitle: loc.accountType2SubTitle,
        description: loc.accountType2Description,
        iconPath: AppIconAssets.business_account,
      ),
      // AccountOption(
      //   id: AppConstants.recruiter,
      //   title: loc.recruiter,
      //   subtitle: loc.forPostingJobOpeningsAndConnectingWithRightCandidates,
      //   iconPath: AppIconAssets.recruiter_account,
      // ),
    ];

///get and display time
employmentTypeTypeApiValue({String? keyName}) {
  return keyName == "FULL_TIME"
      ? "Full-time"
      : keyName == "Internship".toUpperCase()
          ? "Internship"
          : "";
}

///pass into api
employmentTypeTypePassApiValue({String? keyName}) {
  return keyName!.toLowerCase() == "Full-Time".toLowerCase()
      ? "FULL_TIME"
      : keyName.toLowerCase() == "Internship".toLowerCase()
          ? "Internship".toUpperCase()
          : "";
}

// IMMEDIATE, FIFTEEN_DAYS, ONE_MONTH, FORTY_FIVE_DAYS, TWO_MONTHS, THREE_MONTHS
final List<String> jobPostNoticePeriods = [
  'Immediate',
  '15 Days',
  '1 Month',
  '45 Days',
  '2 Month',
  '3 Month',
];

openBusinessProfile({required String? businessUserId}) {
  if (businessId == businessUserId) {
    Get.to(() => BusinessOwnProfileScreen);
  } else {
    Get.to(() => VisitBusinessProfileNew(businessId: businessUserId ?? ""));
  }
}

openPersonalProfile({required String? userID}) {
  if (userId == userID) {
    Get.to(PersonalProfileSetupScreen());
  } else {
    Get.to(() => VisitProfileScreen(authorId: userID ?? ""));
  }
}
// List<EmojiReaction> reactions = [
//   EmojiReaction(
//       emoji: LocalAssets(imagePath: AppIconAssets.emojiLikeIcon),
//       label: loc.liked),
//   EmojiReaction(
//       emoji: LocalAssets(imagePath: AppIconAssets.emojiCelebrateIcon),
//       label: loc.celebrate),
//   EmojiReaction(
//       emoji: LocalAssets(imagePath: AppIconAssets.emojiSupportIcon),
//       label: loc.support),
//   EmojiReaction(
//       emoji: LocalAssets(imagePath: AppIconAssets.emojiHeartIcon),
//       label: loc.heart),
//   EmojiReaction(
//       emoji: LocalAssets(imagePath: AppIconAssets.emojiInsightfulIcon),
//       label: loc.insightful),
// ];

final List<Map<String, dynamic>> drawerItems = [
  {
    "title": "Earn with BlueEra",
    "subtitle":
        "Add Bank Account, Linked UPI IDs, Payment Methods, Personal Info, Transaction History.",
    "icon": AppIconAssets.earnWithBEIcon,
  },
  {
    "title": "Orders & Bookings",
    "subtitle":
        "Add Bank Account, Linked UPI IDs, Payment Methods, Personal Info, Transaction History.",
    "icon": AppIconAssets.orderBookingIcon,
  },
  {
    "title": "=Payment Settings",
    "subtitle":
        "Add Bank Account, Linked UPI IDs, Payment Methods, Personal Info, Transaction History.",
    "icon": AppIconAssets.paymentIcon,
  },
  {
    "title": "Channel Settings",
    "subtitle":
        "Add Bank Account, Linked UPI IDs, Payment Methods, Personal Info, Transaction History.",
    "icon": AppIconAssets.channelIcon,
  },
  {
    "title": "My Documents",
    "subtitle":
        "Add Bank Account, Linked UPI IDs, Payment Methods, Personal Info, Transaction History.",
    "icon": AppIconAssets.documentIcon,
  },
  {
    "title": "Profile Settings",
    "subtitle":
        "Add Bank Account, Linked UPI IDs, Payment Methods, Personal Info, Transaction History.",
    "icon": AppIconAssets.personIcon,
  },
];

List<PopupMenuEntry<PostCreationMenu>> popupMenuItems() {
  final bool isBusiness =
      accountTypeGlobal.toUpperCase() == AppConstants.business;

  final List<PostCreationMenu> items = [
    PostCreationMenu.message,
    PostCreationMenu.poll,
    PostCreationMenu.photos,
    PostCreationMenu.videos,
    if (isBusiness) PostCreationMenu.jobPost,
    PostCreationMenu.place,
    // PostCreationMenu.travel,
  ];

  const iconMap = {
    PostCreationMenu.message: AppIconAssets.message_post,
    PostCreationMenu.poll: AppIconAssets.qa_ask_questionOutlinedIcon,
    PostCreationMenu.photos: AppIconAssets.photosOutlinedIcon,
    PostCreationMenu.videos: AppIconAssets.videoOutlinedIcon,
    PostCreationMenu.jobPost: AppIconAssets.uilSuitcaseOutlinedIcon,
    PostCreationMenu.place: AppIconAssets.locationOutlineIconGreyIcon,
    PostCreationMenu.travel: AppIconAssets.travelOutlinedIcon,
  };

  const titleMap = {
    PostCreationMenu.message: 'Message',
    PostCreationMenu.poll: 'Poll',
    PostCreationMenu.photos: 'Photos',
    PostCreationMenu.videos: 'Videos',
    PostCreationMenu.jobPost: 'Job Post',
    PostCreationMenu.place: 'Place',
    PostCreationMenu.travel: 'Travel',
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
    {"id": "EDIT", 'icon': AppIconAssets.tablerEditIcon, 'title': 'Edit'},
    {"id": "SHARE", 'icon': AppIconAssets.uploadIcon, 'title': 'Share'},
    {"id": "DOWNLOAD", 'icon': AppIconAssets.downloadIcon, 'title': 'Download'},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['title'],
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

List<PopupMenuEntry<String>> popupMenuVisitProfileItems() {
  final items = <Map<String, dynamic>>[
    // {"id": "EDIT", 'icon': AppIconAssets.tablerEditIcon, 'title': 'Edit'},
    {"id": "SHARE", 'icon': AppIconAssets.share_bold, 'title': 'Share'},
    // {"id": "DOWNLOAD", 'icon': AppIconAssets.downloadIcon, 'title': 'Download'},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['title'],
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
    {bool? isSavePost}) {
  final items = <Map<String, dynamic>>[
    // {"id": "REPOST", 'icon': AppIconAssets.repost_new, 'title': 'Repost'},
    {
      "id": "SAVE",
      'icon': AppIconAssets.save_new,
      'title': (isSavePost ?? false) ? "Unsave" : "Save"
    },
    // {"id": "FOLLOW", 'icon': AppIconAssets.follow_new, 'title': 'Follow'},
    {
      "id": "REPORT_POST",
      'icon': AppIconAssets.report_new,
      'title': 'Report Post'
    },
    {
      "id": "BLOCK_USER",
      'icon': AppIconAssets.block_user,
      'title': 'Block User'
    },
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['title'],
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

List<PopupMenuEntry<String>> popupJobCardItems() {
  final items = <Map<String, dynamic>>[
    {'icon': AppIconAssets.tablerEditIcon, 'title': 'Edit'},
    {'icon': AppIconAssets.eyeIcon, 'title': 'Hide'},
    {'icon': AppIconAssets.uploadIcon, 'title': 'Share'},
    {'icon': AppIconAssets.uilSuitcaseOutlinedIcon, 'title': 'Close Vacancy'},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['title'],
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

List<PopupMenuEntry<String>> popupPostMenuItems() {
  final items = <Map<String, dynamic>>[
    {'title': 'Edit Post'},
    {'title': 'Delete Post'},
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

List<PopupMenuEntry<String>> popupVideoMenuItems() {
  final items = <Map<String, dynamic>>[
    {'title': 'Edit Video'},
    {'title': 'Delete Video'},
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
    {'title': 'Edit Product'},
    {'title': 'Delete Product'},
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

List<PopupMenuEntry<String>> popupInventoryMenuItems() {
  final items = <Map<String, dynamic>>[
    {'icon': Icons.edit_outlined, 'title': 'Edit', 'isIcon': true},
    {
      'icon': 'assets/icons/unpublished_icon.png',
      'title': 'Unpublish',
      'isIcon': false
    },
    {'icon': Icons.copy_outlined, 'title': 'Copy Listing', 'isIcon': true},
    {
      'icon': 'assets/images/outOfStock.png',
      'title': 'Out of Stock',
      'isIcon': false
    },
    {'icon': Icons.delete_outline, 'title': 'Delete', 'isIcon': true},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size40,
        value: items[i]['title'],
        child: Row(
          children: [
            items[i]['isIcon']
                ? Icon(
                    items[i]['icon'],
                    size: 20,
                    color: AppColors.black30,
                  )
                : Image.asset(
                    items[i]['icon'],
                    width: 20,
                    height: 20,
                    color: AppColors.black30,
                  ),
            SizedBox(width: SizeConfig.size12),
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

List<PopupMenuEntry<String>> popupInventoryCategoryItems() {
  final items = <Map<String, dynamic>>[
    {'icon': Icons.edit_outlined, 'title': 'Edit', 'isIcon': true},
    {'icon': Icons.delete_outline, 'title': 'Delete', 'isIcon': true},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size40,
        value: items[i]['title'],
        child: Row(
          children: [
            items[i]['isIcon']
                ? Icon(
                    items[i]['icon'],
                    size: 20,
                    color: AppColors.black30,
                  )
                : Image.asset(
                    items[i]['icon'],
                    width: 20,
                    height: 20,
                    color: AppColors.black30,
                  ),
            SizedBox(width: SizeConfig.size12),
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

List<PopupMenuEntry<String>> photoPostMenuItems() {
  final items = <Map<String, dynamic>>[
    {'title': 'Square', 'icon': Icons.square_outlined},
    {'title': 'Portrait', 'icon': Icons.crop_portrait_outlined},
  ];

  final List<PopupMenuEntry<String>> entries = [];

  for (int i = 0; i < items.length; i++) {
    final menu = items[i];
    entries.add(
      PopupMenuItem<String>(
        height: SizeConfig.size35,
        value: items[i]['title'],
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
    name: 'YouTube',
    icon: 'assets/svg/youtube_grey.svg',
    linkController: TextEditingController(),
  ),
  // SocialInputFieldsModel(
  //   name: 'Twitter',
  //   icon: 'assets/svg/website.svg',
  //   linkController: TextEditingController(),
  // ),
  // SocialInputFieldsModel(
  //   name: 'LinkedIn',
  //   icon: 'assets/svg/website.svg',
  //   linkController: TextEditingController(),
  // ),
  // SocialInputFieldsModel(
  //   name: 'Instagram',
  //   icon: 'assets/svg/website.svg',
  //   linkController: TextEditingController(),
  // ),
  // SocialInputFieldsModel(
  //   name: 'Website',
  //   icon: 'assets/svg/website.svg',
  //   linkController: TextEditingController(),
  // ),
];

List<String>? currentDesignationResume = [
  ARTIST,
  GOVERNMENT_JOB,
  PRIVATE_JOB,
  SKILLED_WORKER,
  SELF_EMPLOYED,
  STUDENT,
  OTHERS,
];

bool isResumeShow({required String? designation}) {
  return currentDesignationResume?.contains(designation) ?? false;
}

List<ServiceCategoryBusinessModel> serviceCategoryBusinessModel = [
  ServiceCategoryBusinessModel(
    name: "Personal & Home Services",
    slug: "PERSONAL_AND_HOME_SERVICES",
    subCategories: [
      ServiceSubCategoryBusinessModel(
          name: "Home cleaning", slug: "HOME_CLEANING"),
      ServiceSubCategoryBusinessModel(
          name: "Pest control", slug: "PEST_CONTROL"),
      ServiceSubCategoryBusinessModel(name: "Plumbing", slug: "PLUMBING"),
      ServiceSubCategoryBusinessModel(
          name: "Electrical work", slug: "ELECTRICAL_WORK"),
      ServiceSubCategoryBusinessModel(
          name: "Appliance repair", slug: "APPLIANCE_REPAIR"),
      ServiceSubCategoryBusinessModel(
          name: "Gardening & landscaping", slug: "GARDENING_AND_LANDSCAPING"),
      ServiceSubCategoryBusinessModel(
          name: "Home renovation & interior design",
          slug: "HOME_RENOVATION_AND_INTERIOR_DESIGN"),
    ],
  ),
  ServiceCategoryBusinessModel(
    name: "Health & Wellness Services",
    slug: "HEALTH_AND_WELLNESS_SERVICES",
    subCategories: [
      ServiceSubCategoryBusinessModel(
          name: "Doctor consultations", slug: "DOCTOR_CONSULTATIONS"),
      ServiceSubCategoryBusinessModel(
          name: "Nursing & elder care", slug: "NURSING_AND_ELDER_CARE"),
      ServiceSubCategoryBusinessModel(
          name: "Physiotherapy", slug: "PHYSIOTHERAPY"),
      ServiceSubCategoryBusinessModel(
          name: "Fitness training", slug: "FITNESS_TRAINING"),
      ServiceSubCategoryBusinessModel(
          name: "Spa & salon services", slug: "SPA_AND_SALON_SERVICES"),
      ServiceSubCategoryBusinessModel(
          name: "Mental health counseling", slug: "MENTAL_HEALTH_COUNSELING"),
    ],
  ),
  ServiceCategoryBusinessModel(
    name: "Automotive Services",
    slug: "AUTOMOTIVE_SERVICES",
    subCategories: [
      ServiceSubCategoryBusinessModel(
          name: "Vehicle repair & maintenance",
          slug: "VEHICLE_REPAIR_AND_MAINTENANCE"),
      ServiceSubCategoryBusinessModel(
          name: "Car washing & detailing", slug: "CAR_WASHING_AND_DETAILING"),
      ServiceSubCategoryBusinessModel(name: "Bike repair", slug: "BIKE_REPAIR"),
      ServiceSubCategoryBusinessModel(
          name: "Roadside assistance", slug: "ROADSIDE_ASSISTANCE"),
    ],
  ),
  // ➕ Add other categories (Education, Food, Events, Delivery, Travel, etc.)
];

const String mapLightCode = '''[
    {
      "featureType": "all",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#333333"}]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.stroke",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry.fill",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry.stroke",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "landscape",
      "elementType": "all",
      "stylers": [{"color": "#f2f2f2"}]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "landscape.man_made",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi",
      "elementType": "all",
      "stylers": [{"visibility": "simplified"}]
    },
    {
      "featureType": "poi.business",
      "elementType": "all",
      "stylers": [{"visibility": "simplified"}]
    },
    {
      "featureType": "poi.government",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi.medical",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#e8f5e8"}]
    },
    {
      "featureType": "poi.place_of_worship",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi.school",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi.sports_complex",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road",
      "elementType": "all",
      "stylers": [{"saturation": -100}, {"lightness": 45}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#666666"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "all",
      "stylers": [{"visibility": "simplified"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#f7f7f7"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text",
      "stylers": [{"color": "#666666"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#666666"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#666666"}]
    },
    {
      "featureType": "transit",
      "elementType": "all",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "water",
      "elementType": "all",
      "stylers": [{"color": "#c2d4e6"}, {"visibility": "on"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#b8d4ea"}]
    }
  ]''';

String? getNativeAdUnitId() {
  // Replace these with your actual AdMob ad unit IDs
  // For testing, you can use the test ad unit IDs
  if (Platform.isAndroid) {
    return androidNativeAdUnitId; // Android test ad unit ID
  } else if (Platform.isIOS) {
    return iosNativeAdUnitId; // iOS test ad unit ID
  }
  return null;
}

String? getInterstitialAdUnitId() {
  if (Platform.isAndroid) {
    return androidInterstitialAdUnitId; // Android test ad unit ID
  } else if (Platform.isIOS) {
    return iosInterstitialAdUnitId; // iOS test ad unit ID
  } else {
    return androidInterstitialAdUnitId; // Default to Android test ad unit ID
  }
}

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
//
// Future<File> resizeAndCrop(File file, int targetWidth, int targetHeight) async {
//   // Read image bytes
//   Uint8List bytes = await file.readAsBytes();
//   img.Image? original = img.decodeImage(bytes);
//
//   if (original == null) return file;
//
//   // Resize & crop to exact aspect ratio
//   img.Image resized = img.copyResizeCropSquare(original, size: targetWidth);
//
//   // Save to temp file
//   final tempDir = await getTemporaryDirectory();
//   String outPath = "${tempDir.path}/resized_image.jpg";
//   File outFile = File(outPath)
//     ..writeAsBytesSync(img.encodeJpg(resized, quality: 90));
//   return outFile;
// }

Future<File> processImage(File file, String mode) async {
  Uint8List bytes = await file.readAsBytes();
  img.Image? original = img.decodeImage(bytes);
  if (original == null) return file;

  img.Image result;
  logs("modemodemodemode=== $mode");
  if (mode == AppConstants.Landscape) {
    // --- Target ratio 3:4 ---
    double targetRatio = 16 / 9;
    // double targetRatio = 3 / 4;
    double previewWidth = Get.width * targetRatio;

    // Resize first so the shortest side fits
    img.Image resized = img.copyResize(
      original,
      width: previewWidth.toInt(), // pick your desired width
    );

    // Now crop center to match 3:4
    int cropHeight = (resized.width / targetRatio).toInt();
    int offsetY =
        ((resized.height - cropHeight) / 2).clamp(0, resized.height).toInt();

    result = img.copyCrop(
      resized,
      x: 0,
      y: offsetY,
      width: resized.width,
      height: cropHeight,
    );
  } else {
    double previewWidth = Get.width * (1 / 1);
    // Square 1:1
    //   int size = 600;
    result = img.copyResizeCropSquare(original, size: previewWidth.toInt());
  }

  // Save processed file
  final tempDir = await getTemporaryDirectory();
  String outPath =
      "${tempDir.path}/image_${mode}${DateTime.now().microsecondsSinceEpoch}.jpg";
  File outFile = File(outPath)
    ..writeAsBytesSync(img.encodeJpg(result, quality: 90));

  return outFile;
}
