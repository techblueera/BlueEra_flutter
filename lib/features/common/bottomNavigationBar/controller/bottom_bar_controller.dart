import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:get/get.dart';

import '../../auth/model/adminvideo_model.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;

  /// Drives bottom-nav + subscription-peek visibility from any descendant
  /// screen without prop-drilling. Default = visible. Screens flip this
  /// to false on reverse scroll (user reading further down) and back to
  /// true on forward scroll (user pulled back up).
  final RxBool isBottomNavVisible = true.obs;

  /// Set by the currently-mounted "Me" tab home screen (food, grocery,
  /// hospital, school, …) so the global back handler can collapse that
  /// screen's internal tabs back to the first (Order / Inquiry) tab before
  /// the bottom-nav back logic runs.
  ///
  /// Returns `true` when it consumed the back press (i.e. it moved off a
  /// non-first internal tab); `false` when it was already on the first tab
  /// and the press should fall through to the normal bottom-nav handling.
  /// Cleared by the owning screen on dispose.
  bool Function()? meTabBackHandler;

  /// Bottom-nav index of the "Me" tab.
  static const int meTabIndex = 0;

  /// DEFAULT internal tab index of the "Overview" tab inside a "Me" home
  /// screen — most of them order it second, right after Order/Inquiry.
  ///
  /// Screens that order their tabs differently declare their real index via
  /// [meOverviewTabIndexOverride] instead of moving this; see
  /// `MeTabBackHandlerMixin.registerMeTabBackHandler`.
  static const int meOverviewTabIndex = 1;

  /// Overview's index on the "Me" home screen that is CURRENTLY mounted, when
  /// that screen does not use the default. Set and cleared by
  /// `MeTabBackHandlerMixin` alongside [meTabSelectTabHandler], so a deep link
  /// lands on Overview whatever position the live screen gives it.
  ///
  /// Null means "use [meOverviewTabIndex]".
  int? meOverviewTabIndexOverride;

  /// Overview's index on the live "Me" screen — the override when one is
  /// registered, else the app-wide default.
  int get activeMeOverviewTabIndex =>
      meOverviewTabIndexOverride ?? meOverviewTabIndex;

  /// Set by the currently-mounted "Me" tab home screen (via
  /// `MeTabBackHandlerMixin`) so a deep-link / notification tap can jump that
  /// screen to a specific internal tab (e.g. Overview). Cleared on dispose.
  void Function(int index)? meTabSelectTabHandler;

  /// A request to open the "Me" → Overview tab that arrived before the "Me"
  /// screen was built (cold start, or a fresh switch onto the tab). The "Me"
  /// screen consumes and clears this once it registers its select handler.
  bool pendingMeOverview = false;

  /// Deep-link entry point: bring the user to the "Me" tab's Overview screen.
  /// Used by notification taps (e.g. profile_completion_reminder). If the "Me"
  /// screen is already live it jumps straight there; otherwise it flags the
  /// request so the screen opens Overview as soon as it (re)builds.
  void openMeOverviewTab() {
    final selectTab = meTabSelectTabHandler;
    if (currentIndex.value == meTabIndex && selectTab != null) {
      selectTab(activeMeOverviewTabIndex);
    } else {
      pendingMeOverview = true;
      onChangeIndex(meTabIndex);
    }
  }

  void onChangeIndex(int index) {
    // Pause and release feed video when leaving Home tab to free GPU buffers
    if (currentIndex.value == 0 && index != 0) {
      _pauseFeedVideo();
    }
    // Always reveal the bottom nav on a tab switch — otherwise a tab left
    // scrolled-down would hand the next tab a hidden bar.
    isBottomNavVisible.value = true;
    currentIndex.value = index;
  }
  void _pauseFeedVideo() {
    if (Get.isRegistered<SimplePriorityVideoManager>()) {
      Get.find<SimplePriorityVideoManager>().pauseAndRelease();
    }
  }

// already existing controller
  final RxBool adminVideoLoading = false.obs;
  final RxList<AdminVideo> adminVideos = <AdminVideo>[].obs;

List<CategoryData> businessCategoriesList = [];


  Future<void> fetchAllAdminVideoApiMenu() async {
    try {
      adminVideoLoading.value = true;

      final langCode = Get.isRegistered<LanguageListController>()
          ? Get.find<LanguageListController>().selectedCode.value
          : 'en';

      final res = await ChannelRepo().fetchAllAdminVideoRepo(
        queryParams: {
          ApiKeys.language: langCode.isEmpty ? 'en' : langCode,
        },
      );

      if (res.isSuccess) {
        // ✅ correct response model
        final response =
        AdminVideoResponse.fromJson(res.response?.data);

        adminVideos.clear();
        adminVideos.addAll(response.data ?? []);
      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
      log('[fetchAllAdminVideoApiMenu] $e');
    } finally {
      adminVideoLoading.value = false;
    }
  }
}