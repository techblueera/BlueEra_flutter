import 'package:get/get.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/add_chat_symbol_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/ai_chat_profile_controller.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/about_organisation_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/management_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_blogs_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_branch_contact_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_downloads_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_news_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_privacy_condition_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_service_photo_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/staff_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/timing_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_more_details_screen/add_more_details_controller.dart';

/// Controllers read from widgets spread across MANY features, so no single route
/// can own them. Registered once here and reached everywhere with `Get.find`.
///
/// `lazyPut` so nothing is constructed until something asks for it.
///
/// `fenix: true`: GetX ties an instance to whichever route first CREATES it, so an
/// app-wide controller first touched inside a route would be disposed on that
/// route's pop. fenix keeps the builder registered and rebuilds on the next find.
///
/// HARD RULE: never add a controller here if anything calls
/// `Get.isRegistered<It>()`. `isRegistered` is `_singl.containsKey` and `lazyPut`
/// inserts the key immediately, so registering app-wide makes the guard true from
/// startup forever - `if (isRegistered)` always runs, `if (!isRegistered)` never.
/// 14 controllers (BottomBar, ChatView, Feed, Shorts, ...) were removed for exactly
/// this reason and put back on Get.put.
///
/// Also not here: main.dart pre-runApp registrations, permanent:true, and tagged
/// (`Get.put(X(), tag: id)`) controllers.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
    Get.lazyPut<SymbolFeedController>(() => SymbolFeedController(),
        fenix: true);
    Get.lazyPut<AddChatSymbolController>(() => AddChatSymbolController(),
        fenix: true);
    Get.lazyPut<AiChatProfileController>(() => AiChatProfileController(),
        fenix: true);
    Get.lazyPut<ChannelFeedController>(() => ChannelFeedController(),
        fenix: true);
    Get.lazyPut<CommentController>(() => CommentController(), fenix: true);
    Get.lazyPut<AddMoreDetailsController>(() => AddMoreDetailsController(),
        fenix: true);
    Get.lazyPut<AboutOrganisationController>(
        () => AboutOrganisationController(),
        fenix: true);
    Get.lazyPut<ManagementController>(() => ManagementController(),
        fenix: true);
    Get.lazyPut<OtherBlogsController>(() => OtherBlogsController(),
        fenix: true);
    Get.lazyPut<OtherBranchContactController>(
        () => OtherBranchContactController(),
        fenix: true);
    Get.lazyPut<OtherDownloadsController>(() => OtherDownloadsController(),
        fenix: true);
    Get.lazyPut<OtherNewsController>(() => OtherNewsController(), fenix: true);
    Get.lazyPut<OtherPrivacyConditionController>(
        () => OtherPrivacyConditionController(),
        fenix: true);
    Get.lazyPut<OtherServicePhotoPhotoController>(
        () => OtherServicePhotoPhotoController(),
        fenix: true);
    Get.lazyPut<StaffController>(() => StaffController(), fenix: true);
    Get.lazyPut<TimingController>(() => TimingController(), fenix: true);
    Get.lazyPut<PersonalCreateProfileController>(
        () => PersonalCreateProfileController(),
        fenix: true);
    Get.lazyPut<EmailVerificationController>(
        () => EmailVerificationController(),
        fenix: true);
  }
}
