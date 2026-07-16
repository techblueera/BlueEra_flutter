import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/business/auth/model/shop_open_status.dart';
import 'package:BlueEra/features/me/grocery/view/admin/shop_availability_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/shop_availability_host.dart';
import 'package:BlueEra/widgets/shop_availability_sheet.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/services/keyed_json_cache.dart';
import '../../../chat/auth/service/location_update_service.dart';
import '../../personal_profile/view/widget/ai_suggestion_field.dart';
import '../../personal_profile/view/widget/introduction_video_widget.dart';
import '../../personal_profile/view/widget/update_personal_profession_dialog.dart';
import '../repo/personal_profile_repo.dart';

class _ProfileFieldStatus {
  final int id; // unique identifier
  final String title;
  final bool isCompleted;

  const _ProfileFieldStatus({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

class ViewPersonalDetailsController extends GetxController
    implements ShopAvailabilityHost {
  bool updateBtnLoading = false;

  @override
  void onInit() {
    // getAllPostApi();
    super.onInit();
    // Restore the provider's live state on every controller creation (app
    // start / bottom-nav mount). Previously the toggle Rx defaulted to false
    // after an app kill+restart, so the pill showed Offline and — because the
    // map-service auto-closes providers whose app stops pinging for 5 min —
    // the provider really was CLOSED on the backend even though they never
    // toggled off. If the cached status says OPEN, re-assert it.
    restoreProviderLiveState();
  }

  /// If the locally cached provider status is OPEN, the user went live and
  /// never chose to go offline — bring that state back: flip the toggle on,
  /// re-PATCH OPEN to the map-service (heals the auto-close that fired when
  /// the previous app session died), and restart the periodic location
  /// pinger. No-op for users who never went live (empty/CLOSED cache).
  Future<void> restoreProviderLiveState() async {
    await getServiceProviderStatusUtils();
    if (serviceProviderStatusGlobal.toUpperCase() ==
        AppConstants.OPEN.toUpperCase()) {
      shopStatusOpenClose.value = true;
      await toggleShopOnlyStatus(isActive: true);
    }
  }

  // ViewPersonalDetailsController() {
  //   print("🕵️‍♂️ Someone created a new instance!");
  //   print(StackTrace.current); // This prints the file & line number
  // }

  RxBool shopStatusOpenClose = false.obs;
  RxBool isShopStatusUpdating = false.obs;
  final LiveLocationService locationService = LiveLocationService();

  Future<void> toggleShopStatus() async {
    shopStatusOpenClose.value = !shopStatusOpenClose.value;
    // Persist the INTENT immediately — before the API round-trip. The cache
    // is what onInit's restoreProviderLiveState reads after a kill+restart;
    // writing it only on API success meant a kill (or any API hiccup) right
    // after toggling left the cache stale and the toggle came back OFF.
    await _persistLiveIntent(shopStatusOpenClose.value);
    if (shopStatusOpenClose.value) {
      locationService.start();
    } else {
      locationService.stop();
    }
    await callApiForChangeStatus();
  }

  Future<void> toggleShopOnlyStatus({required bool isActive}) async {
    shopStatusOpenClose.value = isActive;
    await _persistLiveIntent(isActive);
    await callApiForChangeStatus();
  }

  /// Write the user's go-live intent to secure storage + refresh the global
  /// so every reader (bottom-nav pill, rider screens, restart restore) agrees
  /// with what the user chose, independent of network state.
  Future<void> _persistLiveIntent(bool isOpen) async {
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.serviceProviderStatus,
        isOpen ? 'OPEN' : 'CLOSED');
    await getServiceProviderStatusUtils();
  }

  void getServiceProviderStatus() async {
    try {
      ResponseModel responseModel =
          await PersonalProfileRepo().getServiceStatusRepo();

      if (responseModel.isSuccess) {
        final statusData = responseModel.response?.data['availabilityStatus']
            .toString()
            .toUpperCase();
        if (statusData == AppConstants.OPEN.toUpperCase()) {
          shopStatusOpenClose.value = true;
          callLocationAPI();
          // Backend says OPEN — start the periodic location pinger. A single
          // ping is not enough: the map-service auto-closes providers whose
          // lastSeen goes stale for 5 minutes, so without the pinger the
          // provider silently dropped offline right after app restart.
          locationService.start();
        } else {
          shopStatusOpenClose.value = false;
        }
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.serviceProviderStatus, statusData);
        await getServiceProviderStatusUtils();
      } else {
        shopStatusOpenClose.value = false;
      }
    } catch (e) {
      shopStatusOpenClose.value = false;
    }
  }

  callLocationAPI() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      await MapServiceRepo().mapServiceLocationProviderRepo(queryParams: {
        ApiKeys.userId: userId,
        ApiKeys.lat: position.latitude,
        ApiKeys.lng: position.longitude,
      });
    }
  }

  callApiForChangeStatus() async {
    try {
      isShopStatusUpdating.value = true;
      changeShopStatusResponse.value = ApiResponse.initial("Initial");

      ResponseModel responseModel =
          await PersonalProfileRepo().setServiceStatusRepo(bodyReq: {
        ApiKeys.userId: userId,
        ApiKeys.status: shopStatusOpenClose.value ? "OPEN" : "CLOSED"
      });

      if (responseModel.isSuccess) {
        final statusData = responseModel
            .response?.data['provider']['availabilityStatus']
            .toString()
            .toUpperCase();
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.serviceProviderStatus, statusData);
        await getServiceProviderStatusUtils();
        if (statusData == AppConstants.OPEN.toUpperCase()) {
          callLocationAPI();
          // Keep the periodic pinger in lockstep with the confirmed backend
          // status — covers toggleShopOnlyStatus(), which (unlike
          // toggleShopStatus) never touched the location service.
          locationService.start();
        } else {
          locationService.stop();
        }
        changeShopStatusResponse.value = ApiResponse.complete(responseModel);
      }
    } catch (e) {
      changeShopStatusResponse.value = ApiResponse.error('error');
    } finally {
      isShopStatusUpdating.value = false;
    }
  }

  final RxInt postsCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxInt followersCount = 0.obs;

  Rx<ApiResponse> changeShopStatusResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> viewPersonalResponse = ApiResponse.initial('Initial').obs;

  /// Reactive gate for the "Me" tab after a navigate-first login (mirror of
  /// [ViewBusinessDetailsController.isBusinessProfileReady]). Flips true once
  /// the personal-profile fetch has SETTLED — driven by a whenComplete in the
  /// bottom-nav boot init, NOT by [viewPersonalResponse]'s status, because a
  /// non-success response (or the logged-out early return) can leave that
  /// status un-set and would otherwise strand the loader forever.
  final RxBool isPersonalProfileReady = false.obs;

  /// True while a personal-profile network fetch is in flight. The "Me" tab
  /// watches this so it can (a) show the loader when there's no data yet and a
  /// fetch is running, and (b) REBUILD to the correct screen class when the
  /// fetch completes — the type globals it switches on are non-reactive, so this
  /// true→false flip is the rebuild trigger. Toggled in [viewPersonalProfile].
  final RxBool isMeProfileFetching = false.obs;

  /// Joining-bonus object embedded in the `user/get` response. Drives the
  /// app-open claim popup; null until the profile loads (or when absent).
  final Rxn<JoiningBounce> joiningBounce = Rxn<JoiningBounce>();
  Rx<ApiResponse> getFollowerViewCountResponse =
      ApiResponse.initial('Initial').obs;
  Rx<PersonalProfileDetailsModel> personalProfileDetails =
      PersonalProfileDetailsModel().obs;

  /// Security-deposit go-live gate for this individual/self-employed provider.
  /// Sourced from the individual profile's `securityDeposit` (mirrors the
  /// business profile gate). Fail-open: blocked ONLY when the backend reports
  /// `required && !paid`. See docs/backend/SELF_WORK_GO_LIVE_GUIDE.md.
  bool get canGoLive => personalProfileDetails.value.canGoLive;

  /// First service free: the deposit gate is waived until the provider uses
  /// their first free go-live (`freeServiceUsed == false`). Mirrors the rider
  /// `isFirstRideFree`. Proxies the individual-profile flag. See
  /// docs/backend/SELF_WORK_GO_LIVE_GUIDE.md.
  bool get isFirstServiceFree =>
      personalProfileDetails.value.isFirstServiceFree;

  // ── Schedule-driven availability (auto open/close) ──────────────────
  // Individual analogue of the business availability flow — same UI (shared
  // shop-status sheet + weekly editor) but hitting the INDIVIDUAL endpoints.
  // Used by the professionals/consultant Go-Live pill.

  @override
  final RxList<Schedule> weeklySchedule = <Schedule>[].obs;

  final Rxn<SpecialOverrides> todayOverride = Rxn<SpecialOverrides>();

  @override
  final Rx<ShopOpenStatus> shopStatus = const ShopOpenStatus.closed().obs;

  @override
  final RxBool isAvailabilityUpdating = false.obs;

  /// Whether the shop is open right now (schedule ∩ clock). The pill also ANDs
  /// this with [canGoLive] so an unpaid provider is never shown live.
  final RxBool isShopOpenNow = false.obs;

  Timer? _availTimer;

  bool get hasSchedule => weeklySchedule.any((s) => (s.isOpen ?? false));

  void _hydrateAvailability(AvailabilityData? availability) {
    weeklySchedule.value = availability?.schedule ?? <Schedule>[];
    todayOverride.value = ShopOpenStatus.overrideForToday(
      availability?.specialOverrides,
      DateTime.now(),
    );
    _recomputeShopStatus();
    _ensureAvailTimer();
  }

  void _recomputeShopStatus() {
    final status = ShopOpenStatus.compute(
      schedule: weeklySchedule,
      todayOverride: todayOverride.value,
      now: DateTime.now(),
    );
    shopStatus.value = status;
    isShopOpenNow.value = status.isOpenNow;
  }

  void _ensureAvailTimer() {
    _availTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => _recomputeShopStatus(),
    );
  }

  @override
  void onClose() {
    _availTimer?.cancel();
    _availTimer = null;
    super.onClose();
  }

  /// Read the individual availability document and recompute.
  Future<void> loadHours() async {
    final res = await PersonalProfileRepo().getIndividualHours();
    if (!res.isSuccess) return;
    final body = res.response?.data;
    final data = (body is Map) ? body['data'] : null;
    if (data is Map<String, dynamic>) {
      _hydrateAvailability(AvailabilityData.fromJson(data));
    }
  }

  /// Entry point for the professional Go-Live pill. [gate] defaults to the
  /// personal deposit check; callers pass one that also routes to the deposit
  /// screen. First run (no schedule) opens the weekly editor via the sheet's
  /// empty state; otherwise the status sheet.
  Future<void> openAvailabilityControl({bool Function()? gate}) async {
    if (!(gate != null ? gate() : canGoLive)) return;
    if (!hasSchedule) await loadHours();
    await showShopAvailabilitySheet(this);
  }

  @override
  Future<void> setOpenToday() async {
    await _applyTodayOverride({
      'isOpen': true,
      'shopOpenTime': '00:00',
      'shopCloseTime': '23:59',
    });
  }

  @override
  Future<void> setClosedToday() async {
    await _applyTodayOverride({'isOpen': false});
  }

  Future<void> _applyTodayOverride(Map<String, dynamic> body) async {
    isAvailabilityUpdating.value = true;
    try {
      final res = await PersonalProfileRepo().setIndividualTodayHours(body);
      if (res.isSuccess) {
        await loadHours();
      } else {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } finally {
      isAvailabilityUpdating.value = false;
    }
  }

  @override
  Future<void> revertTodayOverride() async {
    isAvailabilityUpdating.value = true;
    try {
      final res = await PersonalProfileRepo().clearIndividualTodayHours();
      if (res.isSuccess) {
        await loadHours();
      } else {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } finally {
      isAvailabilityUpdating.value = false;
    }
  }

  @override
  Future<void> openWeeklyEditor() async {
    final result = await Get.to(
      () => ShopAvailabilityScreen(
        initialSchedule: weeklySchedule,
        onSave: _saveWeeklyHours,
      ),
    );
    if (result == true) await loadHours();
  }

  /// Persist the weekly schedule to the INDIVIDUAL endpoint. Returns null on
  /// success, else an error message for the editor to surface.
  Future<String?> _saveWeeklyHours(List<Schedule> schedule) async {
    final res = await PersonalProfileRepo().setIndividualHours({
      'timezone': 'Asia/Kolkata',
      'schedule': schedule.map((s) => s.toJson()).toList(),
    });
    return res.isSuccess
        ? null
        : (res.message ?? AppStrings.somethingWentWrong.tr);
  }
  RxBool isSocialEdit = false.obs, isSelfVideo = false.obs;
  RxString isYoutubeEdit = "".obs;
  RxString youtube = ''.obs;
  RxString verifiedEmail = ''.obs;
  RxString twitter = ''.obs;
  RxString linkedin = ''.obs;
  RxString instagram = ''.obs;
  RxString website = ''.obs;
  Rx<ApiResponse> postsResponse = ApiResponse.initial('Initial').obs;
  Rx<PostResponse?> postRes = Rx(null);

  SortBy selectedFilter = SortBy.Latest;

  Rx<File?> selectedVideo = Rx<File?>(null);

  // RxBool isLoading = false.obs;
  RxString introVideoUrl = ''.obs;

  // RxList<Projects>? projectsList = <Projects>[].obs;
  // RxList<Experiences>? experiencesList = <Experiences>[].obs;

  // RxList<Projects>? projectsList=<Projects>[].obs;
  RxString overView = ''.obs;
  RxBool isMyProfileShow = false.obs;
  RxBool isChannelCreated = false.obs;

  // Rxn<AvailabilityModel> availabilityDetails = Rxn<AvailabilityModel>();

  List<_ProfileFieldStatus> fields = [];
  RxDouble myProfileCompletionPercent = 0.0.obs;

  RxString userProfileType = userProfileTypeGlobal.obs;
  RxList<String> earnProfileType = <String>[].obs;

  /// Loads the personal profile (`/user/get`).
  ///
  /// **Cache-first, network only when it matters.** The `/user/get` call is
  /// made only right after login and after the user actually changes their
  /// profile — those callers pass [forceRefresh] `true`. Every other trigger
  /// (screen open, drawer, bottom-nav, app resume) serves the locally cached
  /// profile and skips the network entirely, so we don't fire the same request
  /// on every navigation. The cache is (re)written on each forced refresh and
  /// wiped on logout, so a re-login refetches once.
  Future<void> viewPersonalProfile({bool forceRefresh = false}) async {
    // Skip when logged out: stale screens / in-flight asyncs / Obx rebuilds
    // can re-enter this after token + userId globals were cleared, which
    // would otherwise hit /user/get?contact_no= with an invalidated token.
    if (!isLoggedIn()) return;

    // Mark the fetch in-flight so the "Me" tab can show its loader (when there's
    // no data yet) and rebuild to the correct screen class on completion.
    isMeProfileFetching.value = true;

    final personalController = Get.put(PersonalCreateProfileController());

    // 1. Hydrate from cache immediately so the UI isn't blank while
    //    the silent network refresh below is in flight. The repo call
    //    runs without a global progress dialog.
    final cacheKey = userId;
    final cached = await PersonalProfileCache.read(cacheKey);
    if (cached != null) {
      _applyPersonalProfileData(cached, personalController,
          persistPrefs: false);
      // Joining-bonus popup is driven off the cached payload too (its
      // `joining_bounce` sibling is stored with the profile), so it still
      // surfaces when we serve from cache without a network round-trip.
      final cachedJb = cached['joining_bounce'];
      joiningBounce.value = (cachedJb is Map)
          ? JoiningBounce.fromJson(Map<String, dynamic>.from(cachedJb))
          : null;

      // Cache-first: only login and post-update callers ask for fresh data.
      // Everyone else stops here — no `/user/get` request.
      if (!forceRefresh) {
        viewPersonalResponse.value = ApiResponse.complete();
        isMeProfileFetching.value = false;
        return;
      }
    }

    try {
      // 2. Silently refresh from the server.
      ResponseModel responseModel =
          await PersonalProfileRepo().viewParticularPersonalProfile();

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        // final upgraded = IndividualUserResponseModel.fromJson(data ?? {});
        // await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, upgraded.token);
        // await getUserAuthToken();
        if (data is Map<String, dynamic>) {
          await _applyPersonalProfileData(data, personalController,
              persistPrefs: true);
          // Capture the joining-bonus object (sibling of `user`) for the
          // app-open claim popup — no separate API call needed.
          final jb = data['joining_bounce'];
          logs("JOINING_BONUS: personal parse — raw joining_bounce=$jb "
              "(keys=${data.keys.toList()})");
          joiningBounce.value = (jb is Map)
              ? JoiningBounce.fromJson(Map<String, dynamic>.from(jb))
              : null;
          logs("JOINING_BONUS: personal stored shouldShow="
              "${joiningBounce.value?.shouldShow}");
          final freshKey = userId;
          await PersonalProfileCache.write(freshKey, data);

          /// The server lost this device's push token (null/empty). Restore
          /// a fresh FCM token and rebind it on the backend so notifications
          /// keep working. Fire-and-forget: this is backend push-token
          /// bookkeeping the UI never reads, and on a freshly-created account
          /// (empty server token) it fans out to getToken() + a PATCH — two
          /// serial round-trips that must NOT block login / signup navigation,
          /// which awaits this method.
          unawaited(_restoreDeviceTokenIfMissing(data));
        }
        viewPersonalResponse.value = ApiResponse.complete(responseModel);
      } else {
        if (cached == null) {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e, s) {
      log('stack trace -- $s');
      viewPersonalResponse.value = ApiResponse.error('error');
    } finally {
      // Cleared last — AFTER the globals + response were applied above — so the
      // "Me" tab's rebuild (driven by this true→false flip) reads fresh data.
      isMeProfileFetching.value = false;
    }
  }

  /// When the fetched profile's `device_token` is null/empty, the backend
  /// has no push token for this device. Regenerate the FCM token via
  /// [AppNotificationHandler.getFcmToken] and PATCH it back to
  /// `/user/me/device-token` so push delivery is restored.
  Future<void> _restoreDeviceTokenIfMissing(Map<String, dynamic> data) async {
    try {
      final user = data['user'];
      final serverToken =
          (user is Map) ? user['device_token']?.toString() : null;
      if (serverToken != null && serverToken.isNotEmpty) return;

      // Fetch the live FCM token and reconcile it into secure storage
      // (picks up a rotated token, not just an empty cache).
      await AppNotificationHandler.getFcmToken();
      final fcmToken = (await SharedPreferenceUtils.getSecureValue(
              SharedPreferenceUtils.notificationDeviceToken))
          ?.toString();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await PersonalProfileRepo().updateDeviceTokenRepo(deviceToken: fcmToken);
    } catch (e, s) {
      log('restore device token failed -- $e\n$s');
    }
  }

  /// Applies a personal-profile JSON map to all the reactive fields and
  /// optionally writes shared-preference snapshots / runs the side-effect
  /// helpers. `persistPrefs` is `true` only for fresh API responses — for
  /// cached data we skip prefs and the service-status fetch so we never
  /// overwrite newer values with stale ones.
  Future<void> _applyPersonalProfileData(
    Map<String, dynamic> data,
    PersonalCreateProfileController personalController, {
    required bool persistPrefs,
  }) async {
    personalProfileDetails.value =
        PersonalProfileDetailsModel.fromJson(data);

    ///SET MY PROFILE DATA
    final user = personalProfileDetails.value.user;
    if (user != null) {
      fields = [
        _ProfileFieldStatus(
          id: 1,
          title: AppStrings.profileVideo,
          isCompleted: user.introVideo?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 2,
          title: AppStrings.bio,
          isCompleted: user.bio?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 3,
          title: AppStrings.designation,
          isCompleted: user.designation?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 4,
          title: AppStrings.education,
          isCompleted: user.highestEducation?.isNotEmpty ?? false,
        ),
        _ProfileFieldStatus(
          id: 5,
          title: (user.emailVerified == true)
              ? AppStrings.emailVerified
              : AppStrings.emailUnverified,
          isCompleted: user.emailVerified ?? false,
        ),
      ];

      final int totalFields = fields.length;
      final int completedFields = fields.where((e) => e.isCompleted).length;
      final double percent =
          totalFields > 0 ? completedFields / totalFields : 0.0;

      myProfileCompletionPercent.value = percent;
    }

    if (user?.emailVerified ?? false) {
      verifiedEmail.value = user?.email ?? "";
    } else {
      verifiedEmail.value = "";
    }

    ///SET SOCIAL DATA LINK...
    setSocialLink(data);
    personalController.imagePath?.value = user?.profileImage ?? "";
    personalController.coverImagePath?.value = user?.coverPicture ?? "";

    ///SET SKILL...
    personalController.skillsList.clear();
    personalController.skillsList.addAll(user?.skills ?? []);

    ///SET OVERVIEW
    overView.value = user?.objective ?? "";

    /// SYNC GENDER, DOB AND PROFESSION TO CONTROLLER
    personalController.selectedGender.value =
        GenderTypeExtension.fromString(user?.gender ?? "male");
    personalController.selectedDay?.value = user?.dateOfBirth?.date ?? 0;
    personalController.selectedMonth?.value = user?.dateOfBirth?.month ?? 0;
    personalController.selectedYear?.value = user?.dateOfBirth?.year ?? 0;
    personalController.selectedProfession.value = user?.profession ?? "";

    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().imgPath.value = user?.profileImage ?? "";
    }

    /// Check Earn services
    earnProfileType.assignAll(personalProfileDetails.value.earnProfileType);
    debugPrint(
        '=== earnProfileType: $earnProfileType ===');

    /// Seed the location fallback from the personal profile so nearby APIs
    /// still work when device GPS is off.
    LocationService.setProfileLocation(
      personalProfileDetails.value.user?.userLocation?.lat,
      personalProfileDetails.value.user?.userLocation?.lon,
    );

    if (!persistPrefs) return;

    await SharedPreferenceUtils.userLoggedInIndividualGuest(
      businesId: "",
      loginUserId_: "${user?.id}",
      contactNo: "${user?.contactNo}",
      getUserName: "${user?.name}",
      profileImage: "${user?.profileImage}",
      profileType: "${user?.profileType}",
      profession: "${user?.profession}",
      designation: "${user?.designation}",
      userNameAt: "${user?.username}",
    );
    await getUserLoginData();
    userProfileType.value = userProfileTypeGlobal;
    debugPrint("userProfileTypeGlobal after api: ${userProfileType.value}");

    /// need to verify (for checking is service exists or not)
    // Cached-status restore applies to EVERY provider type — riders carry
    // professions like BIKE_RIDER / CAR_TAXI_DRIVER, not just SELF_EMPLOYED /
    // GIG_WORKER, and only providers ever write this cache. The profession
    // gate stays only on the empty-cache backend fetch below.
    await getServiceProviderStatusUtils();
    if (serviceProviderStatusGlobal.isNotEmpty) {
      if (serviceProviderStatusGlobal.toUpperCase() ==
          AppConstants.OPEN.toUpperCase()) {
        // Went live and never toggled off — re-assert OPEN + restart the
        // location pinger (map-service auto-closed the provider when the
        // previous app session stopped pinging).
        await restoreProviderLiveState();
      } else {
        shopStatusOpenClose.value = false;
      }
    } else if (user?.profession?.toUpperCase() == SELF_EMPLOYED ||
        user?.profession?.toUpperCase() == GIG_WORKER) {
      getServiceProviderStatus();
    }
  }


  ///SET SOCIAL LINK DATA
  setSocialLink(data) async {
    youtube.value = data['user']['social_links']['youtube'] ?? '';
    twitter.value = data['user']['social_links']['twitter'] ?? '';
    linkedin.value = data['user']['social_links']['linkedin'] ?? '';
    instagram.value = data['user']['social_links']['instagram'] ?? '';
    website.value = data['user']['social_links']['website'] ?? '';
    final introVideoController = getOrPut(() => IntroductionVideoController());


    // logs("personalProfileDetails.value.user?.introVideo=== 1 ${ personalProfileDetails.value.user?.introVideo }");
    introVideoController.videoUrl.value =
        personalProfileDetails.value.user?.introVideo ?? "";
    // logs("personalProfileDetails.value.user?.introVideo=== 2 ${   introVideoController.videoUrl.value }");

    if (introVideoController.videoUrl.value.isNotEmpty) {
      await introVideoController.initializeVideoPlayerFromNetwork(
          introVideoController.videoUrl.value);
    } else {
      introVideoController.hasUploadedVideo.value = false;
    }
  }

  /// Loads the logged-in user's followers / following / posts counts.
  ///
  /// Cache-first: serves the counts from the local cache and does NOT hit the
  /// network on normal screen opens (this is the same own-user data on every
  /// screen, so it was previously re-fetched redundantly on each open). The
  /// API is called only on a cache miss (once after login) or when
  /// [forceRefresh] is true — pull-to-refresh, or after the counts change
  /// (follow/unfollow or creating a post invalidate the cache; see
  /// [userCountsCache]). The cache is wiped on logout, so a re-login refetches.
  Future<void> UserFollowersAndPostsCount(String? userId,
      {bool forceRefresh = false}) async {
    if (!isLoggedIn()) return;
    try {
      if (!forceRefresh) {
        final cached = await userCountsCache.get(userId ?? '');
        if (cached != null) {
          followersCount.value = cached['followersCount'] ?? 0;
          followingCount.value = cached['followingCount'] ?? 0;
          postsCount.value = cached['totalPosts'] ?? 0;
          getFollowerViewCountResponse.value = ApiResponse.complete();
          return;
        }
      }

      ResponseModel responseModel =
          await PersonalProfileRepo().getUserWithFollowersAndPostsCount(userId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        if (data != null) {
          followersCount.value = data['followersCount'] ?? 0;
          followingCount.value = data['followingCount'] ?? 0;
          postsCount.value = data['totalPosts'] ?? 0;
          getFollowerViewCountResponse.value =
              ApiResponse.complete(responseModel);

          // Cache the counts so subsequent screen opens skip the network.
          await userCountsCache.save(userId ?? '', {
            'followersCount': followersCount.value,
            'followingCount': followingCount.value,
            'totalPosts': postsCount.value,
          });

          // if (data['user'] != null) {
          //   personalProfileDetails.value =
          //       PersonalProfileDetailsModel.fromJson(data);
          // }
        }
      } else {
        getFollowerViewCountResponse.value = ApiResponse.error();

        // commonSnackBar(
        //     message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getFollowerViewCountResponse.value = ApiResponse.error();

      print('Error fetching counts: $e');
      // commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {}
  }

  Future<void> getAllPostApi(String id) async {
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: 1,
      ApiKeys.limit: 10,
      ApiKeys.filter: "latest",
    };

    // if (query == null) {
    queryParams[ApiKeys.refresh] = refresh;
    // }
    queryParams[ApiKeys.authorId] = id;
    try {
      ResponseModel response =
          await FeedRepo().getAllOtherPosts(queryParams: queryParams);
      if (response.isSuccess) {
        postsResponse.value = ApiResponse.complete(response);
        postRes.value = PostResponse.fromJson(response.response?.data);
        update();
      } else {
        postsResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      postsResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  RxString isUserServiceExistsKey = 'false'.obs;

  ///GET STATUS OF USER EXISTENCE...
  Future<String> getUserServiceExistenceStatus() async {
    try {
      ResponseModel responseModel =
          await AuthRepo().getServiceExistenceStatusRepo();

      if (responseModel.isSuccess) {
        String isUserServiceExits =
            responseModel.response?.data['exists'].toString() ?? 'false';
        return isUserServiceExits;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return 'false';
      }
    } catch (e) {
      update();
      return 'false';
    }
  }

  void onFieldTap(_ProfileFieldStatus item) {
    switch (item.id) {
      case 1:
        showIntroductionVideoDialog();
        break;
      case 2:
        showBioUpdateDialog();
        break;
      case 3:
        showProfessionUpdateDialog();
        break;
      case 4:
        showEducationUpdateDialog();
        break;
      case 5:
        if (!item.isCompleted) {
          showEmailVerificationDialog();
        } else {
          commonSnackBar(message: AppStrings.emailAlreadyVerified);
        }
        break;
      default:
        commonSnackBar(message: 'Action Tapped on ${item.title}');
    }
  }

  void showEmailVerificationDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(
      text: personalProfileDetails.value.user?.email ?? '',
    );

    showDialog(
      context: Get.context!,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.verifyYourEmail,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),

                  /// Email Field
                  CommonTextField(
                    title: AppStrings.email,
                    hintText: AppStrings.enterEmailAddress,
                    textEditController: emailController,
                    validationType: ValidationTypeEnum.email,
                    validator: ValidationMethod.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  /// Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: CustomText(AppStrings.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          title: AppStrings.getVerify,
                          height: SizeConfig.size40,
                          bgColor: AppColors.primaryColor,
                          radius: 10.0,
                          onTap: () {
                            if (formKey.currentState?.validate() ?? false) {
                              final email = emailController.text.trim();
                              Navigator.pop(context); // Close dialog
                              final emailVerificationController =
                                  Get.isRegistered<
                                          EmailVerificationController>()
                                      ? Get.find<EmailVerificationController>()
                                      : Get.put(EmailVerificationController());

                              emailVerificationController.verifyEmail(email);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showBioUpdateDialog() {
    final formKey = GlobalKey<FormState>();
    final personalCreateProfileController =
        Get.put(PersonalCreateProfileController());
    final ViewPersonalDetailsController viewPersonalDetailsController =
        Get.find<ViewPersonalDetailsController>();
    final TextEditingController bioController = TextEditingController();
    bioController.text =
        viewPersonalDetailsController.personalProfileDetails.value.user?.bio ??
            '';

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Update Bio",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),
                  AiSuggestionField(
                    title: "About Me / Bio",
                    apiType: "bio",
                    textController: bioController,
                    bodyRequest: {
                      ApiKeys.profession: viewPersonalDetailsController
                          .personalProfileDetails.value.user?.profession,
                      ApiKeys.designation: viewPersonalDetailsController
                          .personalProfileDetails.value.user?.designation,
                      ApiKeys.date_of_birth_Obj: {
                        ApiKeys.year:
                            personalCreateProfileController.selectedYear?.value,
                        ApiKeys.month: personalCreateProfileController
                            .selectedMonth?.value,
                        ApiKeys.date:
                            personalCreateProfileController.selectedDay?.value,
                      },
                      ApiKeys.gender: personalCreateProfileController
                          .selectedGender.value?.name,
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const CustomText("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          title: "Save",
                          height: SizeConfig.size40,
                          bgColor: AppColors.primaryColor,
                          radius: 10.0,
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              personalCreateProfileController
                                  .updateUserProfileDetails(
                                params: {
                                  ApiKeys.bio: bioController.text.trim(),
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showEducationUpdateDialog() {
    final formKey = GlobalKey<FormState>();
    final personalCreateProfileController =
        Get.put(PersonalCreateProfileController());
    final viewPersonalDetailsController =
        Get.find<ViewPersonalDetailsController>();

    final TextEditingController educationController = TextEditingController();

    educationController.text = viewPersonalDetailsController
            .personalProfileDetails.value.user?.highestEducation ??
        '';

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Update Education",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    title: AppStrings.highestEducation,
                    hintText: "eg. 12th, B.A, M.A, PhD",
                    textEditController: educationController,
                    maxLength: 16,
                    onChange: (val) {},
                    validator: (value) {
                      if (value!.trim().length < 2) {
                        return AppStrings.educationMinLength.tr;
                      } else if (value.trim().length > 16) {
                        return AppStrings.educationMaxLength.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const CustomText("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomBtn(
                          title: "Save",
                          height: SizeConfig.size40,
                          bgColor: AppColors.primaryColor,
                          radius: 10.0,
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              personalCreateProfileController
                                  .updateUserProfileDetails(
                                params: {
                                  ApiKeys.highest_education:
                                      educationController.text.trim(),
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showIntroductionVideoDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500, // prevents overflow
              minHeight: 200,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          AppStrings.uploadIntroductionVideo,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const IntroductionVideoWidget(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showProfessionUpdateDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: UpdatePersonalProfessionDialog(),
        );
      },
    );
  }
}

//
