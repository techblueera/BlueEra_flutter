import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/business/auth/model/shop_open_status.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/shop_availability_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/shop_availability_host.dart';
import 'package:BlueEra/widgets/shop_availability_sheet.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/core/api/model/type_of_business_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/model/business_ratings_model.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/model/business_user_response_model.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../common/reel/models/channel_model.dart';
import '../model/GetParticularReviewListModel.dart';
import '../model/getAllProductDetailsModel.dart';
import '../model/getBusinessVerifyViewModel.dart';
import '../model/viewBusinessProfileModel.dart';
import '../repo/business_profile_repo.dart';
import 'package:geolocator/geolocator.dart' as geo;

Future<double?> getDistanceInKm(double targetLat, double targetLng) async {
  // 🔐 Check and request permission
  try {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return null;
    }

    if (permission == geo.LocationPermission.deniedForever) return null;

    // 📍 Get current position
    geo.Position position = await geo.Geolocator.getCurrentPosition(
      // desiredAccuracy: geo.LocationAccuracy.high,
      locationSettings: geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best, distanceFilter: 1),
    );

    // 📏 Calculate distance (meters)
    double distanceMeters = geo.Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );

    // Road factor ≈ 1.27 (very close to Google distance)
    const double roadFactor = 1.27;

    return (distanceMeters * roadFactor) / 1000;
  } finally {
    // TODO
  }
}

class ViewBusinessDetailsController extends GetxController
    implements ShopAvailabilityHost {
  ApiResponse viewBusinessResponse = ApiResponse.initial('Initial');
  ApiResponse viewBusinessResponseNew = ApiResponse.initial('Initial');

  /// Reactive gate for the "Me" tab after a navigate-first login. Flips true
  /// once [viewBusinessProfile] has populated the profile AND the login
  /// globals (businessTypeGlobal / businessCategoryGlobal …) via
  /// getUserLoginData(). The bottom-nav Me tab watches this to swap its
  /// loading placeholder for the resolved business screen — needed because
  /// resolveBusinessScreen() reads the non-reactive `businessTypeGlobal`, so
  /// without a reactive signal it would render the fallback once and never
  /// rebuild when the background fetch lands.
  final RxBool isBusinessProfileReady = false.obs;

  /// True while a business-profile network fetch is in flight. The "Me" tab
  /// watches this so it can (a) show the loader when there's no data yet and a
  /// fetch is running, and (b) REBUILD to the correct screen class when the
  /// fetch completes — `businessTypeGlobal` is non-reactive, so this true→false
  /// flip is the rebuild trigger. Toggled in [_fetchBusinessProfile].
  final RxBool isMeProfileFetching = false.obs;

  /// Non-empty when the last own-profile fetch could not produce a usable
  /// profile — the request failed, or there is no businessId to request with
  /// (login can return `business: null` / `business_id: null`).
  ///
  /// Without this the "Me" tab shimmered forever: it keys off
  /// `businessTypeGlobal` being empty, and a failed fetch leaves it empty just
  /// like a fetch that has not finished. Set in [_fetchBusinessProfile],
  /// cleared when a fetch starts and on success.
  final RxString meProfileError = ''.obs;

  Rx<ApiResponse> businessProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessFoodResponse = ApiResponse.initial('Initial').obs;

  final Rx<ViewBusinessProfileModel?> businessProfileDetails =
      Rx<ViewBusinessProfileModel?>(null);

  /// Security-deposit go-live gate for this business. Sourced from the business
  /// profile's `securityDeposit` (GET business profile). Fail-open when absent:
  /// blocked ONLY when the backend reports `required && !paid`. Mirrors the
  /// selfWork gate — see docs/backend/BUSINESS_GO_LIVE_BACKEND_INTEGRATION.md.
  bool get canGoLive =>
      businessProfileDetails.value?.data?.canGoLive ?? true;
  // bool get canGoLive =>
  //     businessProfileDetails.value?.data?.canGoLive ?? false;

  /// The single go-live truth: an ACCOUNT PLAN is held, OR the legacy deposit
  /// is satisfied. Every consumer of the gate must use THIS, not bare
  /// [canGoLive] — the pill's live state, the sheet gate and the today-override
  /// all read it, and if they disagree the pill lies about being live.
  ///
  /// The plan is the gate going forward (the contribution screen sells plans
  /// now, not deposits). The deposit term stays as an OR so a merchant who
  /// already paid one is not knocked offline by the migration — there is no
  /// longer any way for them to buy it back.
  ///
  /// The third term is the FREE INTRO QUOTA — a business gets its first N
  /// orders / enquiries on the house, so it can go live and start trading
  /// before it pays anything. Once the quota is spent the plan gate applies on
  /// every subsequent go-live.
  bool get isGoLiveAllowed =>
      AccountPlanEntitlement.to.hasActivePlan.value ||
      isFreeQuotaAvailable ||
      canGoLive;

  /// Free intro quota (first N orders / enquiries) — waives the payment gate
  /// while it lasts. Fail-CLOSED: only an explicit `freeOrdersUsed == false`
  /// waives, so an absent flag leaves payment required. The individual
  /// analogue is `ViewPersonalDetailsController.isFirstServiceFree`; the rider
  /// one is `DeliveryPartnerController.isFirstRideFree`.
  bool get isFreeQuotaAvailable =>
      businessProfileDetails.value?.data?.isFreeQuotaAvailable ?? false;

  /// Free orders / enquiries left, for display copy only — never gate on this
  /// ([isFreeQuotaAvailable] is the authority). Null when the backend ships the
  /// boolean without a count.
  int? get freeOrdersRemaining =>
      businessProfileDetails.value?.data?.freeOrdersRemaining;

  /// Joining-bonus object embedded in the `business/:id` response. Drives the
  /// app-open claim popup; null until the profile loads (or when absent).
  final Rxn<JoiningBounce> joiningBounce = Rxn<JoiningBounce>();

  Rx<GetBusinessVerifyViewModel>? viewBusinessVerifyStatus =
      GetBusinessVerifyViewModel().obs;

  ViewBusinessProfileModel? visitedBusinessProfileDetails;

  RxList<String> imgLocalL3 = <String>[].obs;
  RxList<int> imgDeleteL3 = <int>[].obs;
  RxInt selectedIndex = 0.obs;
  RxDouble distanceFromKm = 0.0.obs;
  Rx<BusinessType>? selectedBusinessType = BusinessType.Both.obs;
  RxString? imagePath = "".obs;
  RxString? referralId = "".obs;
  RxString? coverImage = "".obs;
  RxString conversationId = "".obs;
  RxString? otherUserId = "".obs;
  RxString shopOpenTime = "".obs;
  RxString shopCloseTime = "".obs;
  RxInt? selectDay = 0.obs, selectMonth = 0.obs, selectYear = 0.obs;
  RxBool isImageUpdated = false.obs;

  // Rx<CategoryData?> selectedCategoryOfBusiness = Rx<CategoryData?>(null);
  //
  // Rx<SubCategories?> selectedSubCategoryOfBusinessNew =
  //     Rx<SubCategories?>(null);

  RxBool isListingDescriptionEdit = true.obs;
  RxString businessDescription = "".obs;
  RxBool isBusinessVerified = false.obs;
  RxString tempDescription = ''.obs;
  SortBy selectedFilter = SortBy.Latest;

  // Added variables to store location data
  RxDouble? addressLat = 0.0.obs;
  RxDouble? addressLong = 0.0.obs;
  RxString businessAddress = "".obs;
  Rx<GetAllProductDetailsModel>? getAllProductDetails =
      GetAllProductDetailsModel().obs;
  Rx<GetParticularReviewListModel>? getParticularReviewListModel =
      GetParticularReviewListModel().obs;
  Rx<ChannelModel>? channelModel;
  Rx<TextEditingController> listingDescriptionController =
      TextEditingController().obs;

  // Loading Local Photo
  final RxMap<int, String> localUploadingPhotos = <int, String>{}.obs;

  String? getLivePhotoAt(int index) {
    final serverPhotos = businessProfileDetails.value?.data?.livePhotos ?? [];

    // 1. If the server has a valid photo URL at this index, prioritize it
    if (index < serverPhotos.length && serverPhotos[index].trim().isNotEmpty) {
      return serverPhotos[index];
    }

    // 2. Fallback to the local path if the background upload is still running
    if (localUploadingPhotos.containsKey(index)) {
      return localUploadingPhotos[index];
    }

    return null;
  }

  // Method to set start location data
  void setStartLocation(double? lat, double? lng, String address) {
    if (lat != null && lat != 0.0) addressLat?.value = lat;
    if (lng != null && lng != 0.0) addressLong?.value = lng;
    businessAddress.value = address;
  }

  final controllerVisit = Get.put(VisitProfileController());
  final isLoading = false.obs;
  final isProfileLoading = false.obs;

  /// Bumped whenever [visitedBusinessProfileDetails] is replaced with a
  /// fresh fetch — even in `silent: true` mode. `Obx` consumers that
  /// read plain fields on the model can touch this to subscribe.
  final RxInt profileVersion = 0.obs;

  /// business rating list
  RxList<BusinessRatingsData> businessRatingsList = <BusinessRatingsData>[].obs;
  RxBool isBusinessRatingsLoadingMore = false.obs;
  RxBool isBusinessRatingsFirstLoading = false.obs;
  int businessRatingsPage = 1;
  bool businessRatingsHasMore = true;

  loadInitData({required String visitBusinessId}) async {
    try {
      isLoading.value = true;

      await Future.wait([
        viewBusinessProfileById(visitBusinessId),
        fetchProducts(visitBusinessId: visitBusinessId),
        fetchServices(visitBusinessId: visitBusinessId),
        fetchFoods(visitBusinessId: visitBusinessId),
      ]);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Tracks an in-flight non-silent profile fetch so concurrent callers
  /// can piggy-back on it instead of firing a duplicate request.
  Future<void>? _inFlightProfileFetch;

  /// Fetches the current business profile.
  ///
  /// [silent] = true skips the cache-replay step (used after an update
  /// so the cover/avatar UI doesn't flash the stale cached version
  /// between "shimmer off" and the server confirming the new asset).
  ///
  /// Concurrent non-silent callers are coalesced: app startup triggers
  /// this from more than one place (the bottom-nav init and the
  /// joining-bonus pre-check), which used to fire two identical
  /// `GET user-service/business/{id}` requests back-to-back. While a
  /// non-silent fetch is in flight, later non-silent callers await the
  /// same request. Silent post-update refreshes always run fresh so they
  /// never return pre-update data.
  Future<void> viewBusinessProfile({bool silent = false}) {
    if (silent) return _fetchBusinessProfile(silent: true);
    final existing = _inFlightProfileFetch;
    if (existing != null) return existing;
    final future = _fetchBusinessProfile(silent: false);
    _inFlightProfileFetch =
        future.whenComplete(() => _inFlightProfileFetch = null);
    return _inFlightProfileFetch!;
  }

  Future<void> _fetchBusinessProfile({bool silent = false}) async {
    // Mark the fetch in-flight so the "Me" tab can show its loader (when there's
    // no data yet) and rebuild to the correct screen class on completion.
    isMeProfileFetching.value = true;
    meProfileError.value = '';
    try {
    await getUserLoginBusinessId();
logs("BUSINESS ID=== ${businessId}");

    // No businessId to fetch with. Login can legitimately return
    // `business: null` / `business_id: null` for a BUSINESS account whose
    // profile was never created (or was removed server-side). Requesting
    // `/user-service/business/` with an empty id just 404s, so stop here and
    // let the "Me" tab show a retry state instead of shimmering forever.
    if (businessId.trim().isEmpty) {
      meProfileError.value = AppStrings.businessProfileNotFound.tr;
      return;
    }
    // 1. Paint the cached business profile (if any) immediately so the UI
    //    isn't blank while the network call is in flight.
    //
    //    Stale-while-revalidate, NOT cache-first: the snapshot only decides
    //    what is on screen for the first few hundred milliseconds — step 2
    //    below always runs and always replaces it. That is the opposite of
    //    the per-vertical caches (e.g. other-service), where a cache hit
    //    REPLACES the request; this profile is the one every Me screen reads,
    //    so it must never be more than one round-trip stale.
    //
    //    `persistPrefs: false` — cached data must not overwrite the
    //    shared-preference snapshot, which may hold newer values.
    //
    //    Skipped in `silent` mode: that caller is a post-update refresh and
    //    already holds fresher in-memory state, so replaying the cache would
    //    visibly revert the change it just made.
    final cacheKey = businessId.isNotEmpty ? businessId : userId;
    final cached = silent ? null : await BusinessProfileCache.read(cacheKey);
    if (cached != null) {
      await _applyBusinessProfileData(cached, persistPrefs: false);
    }

    // 2. Silently refresh from the server and replace state + cache on
    //    success.
    ResponseModel responseModel =
        await BusinessProfileRepo().viewParticularBusinessProfile();
    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      if (data is Map<String, dynamic>) {
        await _applyBusinessProfileData(data, persistPrefs: true);
        // Persist for next launch.
        final freshKey = businessId.isNotEmpty ? businessId : userId;
        await BusinessProfileCache.write(freshKey, data);
      }
      viewBusinessResponse = ApiResponse.complete(responseModel);
      // A 200 that carries no usable body leaves businessTypeGlobal empty,
      // which is indistinguishable from "still loading" to the Me tab.
      if (businessTypeGlobal.trim().isEmpty) {
        meProfileError.value = AppStrings.businessProfileNotFound.tr;
      }
    } else if (cached == null) {
      // Only surface the failure when there is nothing on screen. With a cache
      // hit the merchant is already looking at their profile, and flipping
      // `meProfileError` would replace it with the Me tab's retry state —
      // trading working (one-launch-old) data for an error screen.
      meProfileError.value =
          responseModel.message ?? AppStrings.somethingWentWrong.tr;
      // logs(
      //     "ERROR BUSINESS PROFILE ${responseModel.message ?? AppStrings.somethingWentWrong}");

      // Only surface the error to the user when we have nothing cached
      // to fall back on — otherwise the cached UI is already showing.
      // if (cached == null) {
      //   commonSnackBar(
      //       message: responseModel.message ?? AppStrings.somethingWentWrong);
      // }
    }
    } finally {
      // Cleared last — AFTER the globals were applied above — so the "Me" tab's
      // rebuild (driven by this true→false flip) reads fresh data.
      isMeProfileFetching.value = false;
    }
  }

  /// Applies a business-profile JSON map to all the reactive fields and
  /// optionally writes the related shared-preference snapshot. The
  /// `persistPrefs` flag is `true` only for fresh API responses — for
  /// cached data we skip writing prefs so we never overwrite newer
  /// values with stale ones.
  Future<void> _applyBusinessProfileData(
    Map<String, dynamic> data, {
    required bool persistPrefs,
  }) async {
    businessProfileDetails.value = ViewBusinessProfileModel.fromJson(data);

    // Capture the joining-bonus object for the app-open claim popup — no
    // separate API call needed.
    final jb = data['joining_bounce'];
    logs("JOINING_BONUS: business parse — raw joining_bounce=$jb "
        "(keys=${data.keys.toList()})");
    joiningBounce.value = (jb is Map)
        ? JoiningBounce.fromJson(Map<String, dynamic>.from(jb))
        : null;
    logs("JOINING_BONUS: business stored shouldShow="
        "${joiningBounce.value?.shouldShow}");

    /// Seed the location fallback from the business profile so nearby APIs
    /// still work when device GPS is off.
    LocationService.setProfileLocation(
      businessProfileDetails.value?.data?.businessLocation?.lat?.toDouble(),
      businessProfileDetails.value?.data?.businessLocation?.lon?.toDouble(),
    );

    selectDay?.value =
        businessProfileDetails.value?.data?.dateOfIncorporation?.date ?? 0;
    selectMonth?.value =
        businessProfileDetails.value?.data?.dateOfIncorporation?.month ?? 0;
    selectYear?.value =
        businessProfileDetails.value?.data?.dateOfIncorporation?.year ?? 0;
    imagePath?.value = businessProfileDetails.value?.data?.logo ?? "";
    coverImage?.value = businessProfileDetails.value?.data?.coverimage ?? "";

    businessDescription.value =
        businessProfileDetails.value?.data?.businessDescription ?? "";
    tempDescription.value = businessDescription.value;
    controllerVisit.isFollow.value =
        businessProfileDetails.value?.data?.is_following ?? false;
    isBusinessVerified.value =
        businessProfileDetails.value?.data?.businessIsVerified ?? false;

    // Hydrate the schedule-driven auto open/close from the profile so the pill
    // reflects the real state on load and starts flipping itself at the open /
    // close boundaries. The availability document carries the weekly hours and
    // any same-day override; `isLive` is then a *computed* value (open now),
    // not a manual flag.
    _hydrateAvailability(businessProfileDetails.value?.data?.availability);

    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().imgPath.value =
          businessProfileDetails.value?.data?.logo ?? "";
    }

    if (!persistPrefs) return;

    // Never let a missing/empty value from the response overwrite the
    // id we already hold — an empty `_id`/`user_id` in the payload would
    // otherwise wipe `userBusinessId` in secure storage and, after the
    // `getUserLoginData()` re-read below, blank out the `businessId`
    // global that every downstream business API depends on.
    final resolvedBusinessId =
        (businessProfileDetails.value?.data?.id?.trim().isNotEmpty ?? false)
            ? businessProfileDetails.value!.data!.id!
            : businessId;
    final resolvedBusinessUserId =
        (businessProfileDetails.value?.data?.userId?.trim().isNotEmpty ?? false)
            ? businessProfileDetails.value!.data!.userId!
            : userId;

    // Bail out rather than persisting an empty businessId we can't use.
    if (resolvedBusinessId.isEmpty) return;

    log('business type -- ${businessProfileDetails.value?.data?.typeOfBusiness}');
    await SharedPreferenceUtils.userLoggedInBusiness(
      email: businessProfileDetails.value?.data?.ownerDetails?[0].email ?? '',
      profileImage: businessProfileDetails.value?.data?.logo ?? '',
      businessName: businessProfileDetails.value?.data?.businessName ?? '',
      businessOwnerName:
          businessProfileDetails.value?.data?.ownerDetails?[0].name ?? '',
      businessId: resolvedBusinessId,
      loginBusinessUserId: resolvedBusinessUserId,
      userNameAt: "",
      businessAddress: businessProfileDetails.value?.data?.address ?? '',
      categoryOfBusiness:
          businessProfileDetails.value?.data?.categoryDetails?.name ?? '',
      subCategoryOfBusiness:
          businessProfileDetails.value?.data?.subCategoryDetails?.name ?? '',
      typeOfBusiness:
          businessProfileDetails.value?.data?.typeOfBusiness ?? '',
    );
    await getUserLoginData();
    // Globals (businessTypeGlobal etc.) are now populated — signal the Me tab
    // (navigate-first login) that it can render the real business screen.
    isBusinessProfileReady.value = true;
  }

  ///UPDATE BUSINESS IMAGES....
  Future<void> saveBusinessImages(
      String imagePath, ViewBusinessDetailsController controller) async {
    dio.MultipartFile? imageByPart;

    String fileName = imagePath.split('/').last;
    imageByPart =
        await dio.MultipartFile.fromFile(imagePath, filename: fileName);

    Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};

    await controller.uploadLiveStoreImage(params);
    controller.imgDeleteL3.clear();
  }

  RxBool isUpdateBusinessDetailsLoading = false.obs;

  /// True while [updateBusinessProfileDetails] is in flight — callers
  /// (e.g. the cover-photo edit on each *HomeScreen) overlay a shimmer
  /// on the affected UI section instead of relying on the global
  /// progress dialog.
  final RxBool isUpdateBusinessProfileLoading = false.obs;

  /// Updates the business account. Returns true on a successful save.
  /// [silent] suppresses the success snackbar for callers that show their
  /// own confirmation (e.g. the live-photo GPS capture toast).
  Future<bool> updateBusinessDetails(Map<String, dynamic> params,
      {bool? showProgress, bool silent = false}) async {
    try {
      isUpdateBusinessDetailsLoading.value = true;
      ResponseModel responseModel = await AuthRepo()
          .updateBusinessAccountUserRepo(
              bodyRequest: params, showProgress: showProgress);

      // ResponseModel responseModel =
      //     await BusinessProfileRepo().updateBusinessProfileDetails(params);
      if (responseModel.isSuccess) {
        if (!silent) {
          commonSnackBar(message: responseModel.response?.data['message']);
        }
        viewBusinessResponse = ApiResponse.complete(responseModel);
        final upgraded = BusinessUserResponseModel.fromJson(
            responseModel.response?.data ?? {});
logs("upgraded.businessId=== ${upgraded.businessId}");
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.userBusinessId, upgraded.businessId);

        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.authToken, upgraded.token);

        await getUserLoginBusinessId();
        await getUserAuthToken();

        viewBusinessProfile();
        update();
        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
      return false;
    } finally {
      isUpdateBusinessDetailsLoading.value = false;
    }
  }

  /// Snapshot of `business_location` (lat/lon) captured just before a silent
  /// live-photo GPS overwrite, so the confirmation toast's "Undo" can restore
  /// it. Null when there's nothing to roll back.
  double? _preLivePhotoLat;
  double? _preLivePhotoLon;
  bool _hasPreLivePhotoLocation = false;

  /// Silently reads the on-site device GPS after the merchant adds their first
  /// live photo and saves it as `business_location`. A live photo is shot at
  /// the store, so this is the most accurate location signal we get. Returns
  /// true when a fresh location was saved (the caller then shows the confirm /
  /// undo toast). Never throws — GPS/permission/network failures just return
  /// false so the photo flow is never interrupted. Only lat/lon is touched;
  /// the textual address is left for the merchant to edit via the toast.
  Future<bool> captureLocationFromLivePhoto() async {
    try {
      final locationController = Get.isRegistered<LocationController>()
          ? Get.find<LocationController>()
          : Get.put(LocationController());
      // Bounded wait — a GPS fix / reverse-geocode can stall indefinitely
      // (weak signal, pending permission dialog). On timeout we simply skip the
      // silent location update rather than leave a dangling operation.
      final locationData = await locationController
          .checkPermissionAndSetData()
          .timeout(const Duration(seconds: 20), onTimeout: () => null);
      if (locationData == null) return false;

      final lat = double.tryParse(locationData.lat);
      final lng = double.tryParse(locationData.long);
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return false;

      // Remember the previous location for Undo before overwriting.
      final prevLoc = businessProfileDetails.value?.data?.businessLocation;
      _preLivePhotoLat = prevLoc?.lat;
      _preLivePhotoLon = prevLoc?.lon;
      _hasPreLivePhotoLocation = true;

      final params = {
        ApiKeys.business_location: jsonEncode({
          ApiKeys.lat: lat.toString(),
          ApiKeys.lon: lng.toString(),
        }),
      };
      return await updateBusinessDetails(params,
          silent: true, showProgress: false);
    } catch (_) {
      return false;
    }
  }

  /// Restore the location captured before the last live-photo GPS overwrite
  /// (the toast's "Undo"). No-op when there's nothing to restore.
  Future<void> undoLivePhotoLocation() async {
    if (!_hasPreLivePhotoLocation) return;
    final lat = _preLivePhotoLat;
    final lon = _preLivePhotoLon;
    _hasPreLivePhotoLocation = false;
    _preLivePhotoLat = null;
    _preLivePhotoLon = null;
    final params = {
      ApiKeys.business_location: jsonEncode({
        ApiKeys.lat: (lat ?? 0.0).toString(),
        ApiKeys.lon: (lon ?? 0.0).toString(),
      }),
    };
    await updateBusinessDetails(params, silent: true, showProgress: false);
  }

  Future<void> updateBusinessProfileDetails(
    Map<String, dynamic> params, {
    bool showProgress = false,
  }) async {
    try {
      isUpdateBusinessProfileLoading.value = true;
      final responseModel = await BusinessProfileRepo()
          .updateBusinessProfileDetails(params, showProgress: showProgress);

      if (responseModel.isSuccess) {
        commonSnackBar(message: "${responseModel.message}");
        await viewBusinessProfile(silent: true);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    } finally {
      isUpdateBusinessProfileLoading.value = false;
    }
  }

  final RxBool isCategoriesLoading = false.obs;
  final RxBool isSubCategoriesLoading = false.obs;
  RxList<CategoryData> businessCategoriesList = <CategoryData>[].obs;
  RxList<SubCategories> businessSubCategoriesList = <SubCategories>[].obs;
  RxString categorySpecializationText = "".obs;
  RxString errorMessage = "".obs;

  /// Step 1 – Nature of Business
  Rx<BusinessCategory?> selectedTypeOfBusiness = Rx<BusinessCategory?>(null);

  /// Step 2 – Parent Categories
  RxList<CategoryData> categoryList = <CategoryData>[].obs;
  Rx<CategoryData?> selectedCategory = Rx<CategoryData?>(null);

  /// Step 3 – Sub Categories
  RxList<SubCategories> subCategoryList = <SubCategories>[].obs;
  Rx<SubCategories?> selectedSubCategory = Rx<SubCategories?>(null);

  /// API CALL BASED ON BUSINESS TYPE
  Future<void> getAllCategories() async {
    isCategoriesLoading.value = true;
    categoryList.clear();
    subCategoryList.clear();
    selectedCategory.value = null;
    selectedSubCategory.value = null;

    try {
      final response = await AuthRepo().getBusinessCategoriesByTypeRepo(
          selectedTypeOfBusiness.value?.type ?? "");

      if (response.isSuccess) {
        categoryList.value =
            CategoryModel.fromJson(response.response?.data).data ?? [];
      }
    } catch (e) {
      logs("ERROR: $e");
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  /// ON CATEGORY SELECT
  void onCategorySelected(CategoryData category) {
    selectedCategory.value = category;
    selectedSubCategory.value = null;
    subCategoryList.value = category.subCategories ?? [];
  }

  // Future<void> getAllCategories() async {
  //   businessSubCategoriesList.clear();
  //   isCategoriesLoading.value = true;
  //   try {
  //     ResponseModel responseModel =
  //         await AuthRepo().getBusinessCategoriesByTypeRepo("Food");
  //         // await AuthRepo().getBusinessCategoriesRepo();
  //
  //     if (responseModel.isSuccess) {
  //       final data = responseModel.response?.data;
  //       businessCategoriesList.value = CategoryModel.fromJson(data).data ?? [];
  //       final dataList = businessCategoriesList
  //           .where((e) =>
  //               e.type?.toLowerCase() ==
  //               selectedCategoryOfBusiness.value?.type.toString())
  //           .toList();
  //       if (dataList.isNotEmpty) {
  //         businessSubCategoriesList.addAll(dataList.first.subCategories ?? []);
  //       }
  //     } else {
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     logs("ERRO ${e}");
  //   } finally {
  //     isCategoriesLoading.value = false;
  //   }
  // }

  Future<void> postVerifyBusinessDocs(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().uploadVerifyBusinessDocs(params);

      if (responseModel.isSuccess) {
        getBusinessVerification();
        viewBusinessProfile();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

// fsdfnksdjnf
  Future<void> postVerifyOwnerBusinessDocs(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().uploadVerificationOwnerDocs(params);
      if (responseModel.isSuccess) {
        getBusinessVerification();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<void> getBusinessVerification() async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getBusinessVerificationStatus();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        GetBusinessVerifyViewModel value =
            GetBusinessVerifyViewModel.fromJson(data['data']);
        viewBusinessVerifyStatus?.value = value;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<void> updateBusinessDescription(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().uploadBusinessDescription(params);
      if (responseModel.isSuccess) {
        viewBusinessResponse = ApiResponse.complete(responseModel);
        viewBusinessProfile();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

  Future<void> deleteLiveStoreImage(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().deleteLiveStoreImage(params);
      if (responseModel.isSuccess) {
        viewBusinessResponse = ApiResponse.complete(responseModel);
        viewBusinessProfile();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

  /// Count of non-empty live photos currently on the profile (server truth).
  int get _serverLivePhotoCount =>
      businessProfileDetails.value?.data?.livePhotos
          ?.where((p) => p.trim().isNotEmpty)
          .length ??
      0;

  Future<void> uploadLiveStoreImage(Map<String, dynamic> params) async {
    try {
      // Snapshot the count BEFORE the upload. If it was 0 and this upload
      // succeeds, this IS the first live photo — no need to wait on the
      // refetch to know that.
      final wasFirstPhoto = _serverLivePhotoCount == 0;

      ResponseModel responseModel =
          await BusinessProfileRepo().uploadLiveStoreImages(params);
      if (responseModel.isSuccess) {
        viewBusinessResponse = ApiResponse.complete(responseModel);
        // Refresh the profile in the BACKGROUND (not awaited). The caller
        // wraps this in an "Uploading Photo" loader, and the optimistic local
        // preview already shows the photo — awaiting the full refetch here
        // just kept that loader spinning after the photo had visibly landed.
        viewBusinessProfile();

        // First live photo (0 → 1). Re-fires every time photos are cleared
        // back to 0 and a fresh first photo is added — and works from BOTH the
        // live-photo bottom sheet and the inline profile widget, since every
        // upload funnels through here. Fire-and-forget so the slow GPS fix /
        // reverse-geocode never blocks the loader.
        if (wasFirstPhoto) {
          _handleFirstLivePhotoAdded();
        }
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

  /// After the merchant's first live photo, silently capture the on-site GPS
  /// as the business location and, on success, show the confirm / undo notice.
  Future<void> _handleFirstLivePhotoAdded() async {
    final saved = await captureLocationFromLivePhoto();
    if (saved) _showLiveLocationNotice();
  }

  /// Persistent, action-required notice shown after the silent live-photo GPS
  /// save. Stays put (distinct alert-orange, no auto-dismiss / swipe) until the
  /// merchant taps Undo (restore previous location) or Edit (open the full
  /// location sheet to correct the address / pincode).
  void _showLiveLocationNotice() {
    // Use GetSnackBar directly (not Get.snackbar) so there's no forced empty
    // title slot — that title/message gap was pushing the row above center.
    // With only messageText, the content row centers vertically in the bar.
    Get.showSnackbar(
      GetSnackBar(
        messageText: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded,
                color: AppColors.primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                AppStrings.locationUpdatedFromLivePhoto.tr,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size(0, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () {
                Get.closeCurrentSnackbar();
                undoLivePhotoLocation();
              },
              child: CustomText(
                AppStrings.undo.tr,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size(0, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () {
                Get.closeCurrentSnackbar();
                _openLiveLocationEditor();
              },
              child: CustomText(
                AppStrings.edit.tr,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        snackPosition: SnackPosition.BOTTOM,
        snackStyle: SnackStyle.FLOATING,
        // Light glassmorphism: a translucent white bar + `barBlur` frosts the
        // content behind it, a hairline white border and a soft shadow lift it
        // off the page. Dark text keeps it readable over the frosted glass.
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        barBlur: 18,
        borderRadius: 16,
        borderColor: Colors.white.withValues(alpha: 0.5),
        borderWidth: 1.2,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        // Action-required: no auto-dismiss, no swipe-away — closed only by the
        // Undo / Edit buttons above.
        duration: null,
        isDismissible: false,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  /// Open the full business-location sheet (prefilled with the current profile)
  /// so the merchant can review / correct the auto-captured location.
  void _openLiveLocationEditor() {
    final ctx = Get.context;
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BusinessLocationBottomSheet(
        prevBusinessDetails: businessProfileDetails.value?.data,
      ),
    );
  }

  final visitingController = Get.put(VisitProfileController());

  // ── Schedule-driven availability (auto open/close) ──────────────────
  // The shop opens & closes automatically within the weekly hours the merchant
  // sets once; a same-day override can force it open/closed for today only and
  // auto-reverts tomorrow. `isLive` is COMPUTED (open right now) from
  // [weeklySchedule] + [todayOverride] + the wall clock — not a manual flag.

  /// Whether the shop is open *right now* (the pill's value). Recomputed on a
  /// minute timer so it flips at the scheduled open / close times on its own.
  final RxBool isLive = false.obs;

  /// The full weekly open/close schedule (one row per weekday).
  final RxList<Schedule> weeklySchedule = <Schedule>[].obs;

  /// Today's manual override, if any (force open / closed for today only).
  final Rxn<SpecialOverrides> todayOverride = Rxn<SpecialOverrides>();

  /// Rich effective status (open-now, open-today, close time, override flag)
  /// consumed by the availability sheet.
  final Rx<ShopOpenStatus> shopStatus =
      const ShopOpenStatus.closed().obs;

  /// True while a today-override / hours call is in flight (drives the pill
  /// spinner and disables the sheet controls).
  final RxBool isAvailabilityUpdating = false.obs;

  Timer? _statusTimer;

  /// True once the merchant has saved a weekly schedule with at least one open
  /// day. Until then the pill routes straight to the hours editor.
  bool get hasSchedule =>
      weeklySchedule.any((s) => (s.isOpen ?? false));

  /// Pull the weekly schedule + today's override off an availability document
  /// and recompute the live state, (re)starting the minute recompute timer.
  void _hydrateAvailability(AvailabilityData? availability) {
    weeklySchedule.value = availability?.schedule ?? <Schedule>[];
    todayOverride.value = ShopOpenStatus.overrideForToday(
      availability?.specialOverrides,
      DateTime.now(),
    );
    _recomputeShopStatus();
    _ensureStatusTimer();
  }

  /// Recompute [shopStatus] / [isLive] from the current schedule + override and
  /// the wall clock. Cheap and pure — safe to call from the minute timer.
  void _recomputeShopStatus() {
    final status = ShopOpenStatus.compute(
      schedule: weeklySchedule,
      todayOverride: todayOverride.value,
      now: DateTime.now(),
    );
    shopStatus.value = status;
    // Payment is the FIRST wall: an unpaid business is never shown as live,
    // even inside its scheduled hours (e.g. the deposit was set up, hours
    // saved, then the deposit later became unpaid/refunded). `canGoLive`
    // fail-opens when the backend doesn't report a deposit requirement — so
    // this must use the same [isGoLiveAllowed] the pill's gate uses, or the two
    // would disagree and the pill would lie about being live.
    isLive.value = status.isOpenNow && isGoLiveAllowed;
  }

  /// Start the once-a-minute recompute so the pill crosses open/close
  /// boundaries without a network call. Idempotent (permanent controller).
  void _ensureStatusTimer() {
    _statusTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => _recomputeShopStatus(),
    );
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    _statusTimer = null;
    super.onClose();
  }

  /// Re-read the availability document (schedule + override + effective hours)
  /// and recompute. Called after editing hours or changing today's override.
  Future<void> loadHours() async {
    final res = await BusinessProfileRepo().getBusinessHours();
    if (!res.isSuccess) return;
    final body = res.response?.data;
    final data = (body is Map) ? body['data'] : null;
    if (data is Map<String, dynamic>) {
      _hydrateAvailability(AvailabilityData.fromJson(data));
    }
  }


  bool ensureCanGoLive() {
    if (isGoLiveAllowed) return true;
    commonSnackBar(
      message:
          'Your payment is incomplete. Please choose a plan to go live and receive service enquiries.',
    );
    // Refresh on return so a freshly-bought PLAN (reconciled server-side by
    // the Razorpay webhook, with no in-app trigger) and the updated
    // `freeOrdersUsed` are both picked up.
    openContributionScreen().then((_) {
      viewBusinessProfile(silent: true);
      AccountPlanEntitlement.to.refresh();
    });
    return false;
  }

  /// Entry point for the shared "Go live" pill. First run (no schedule yet)
  /// opens the weekly hours editor; once hours exist it opens the availability
  /// sheet (status + today override + edit hours). Deposit-gated up front.
  /// [gate] overrides the deposit check — pass a custom gate for callers whose
  /// deposit lives elsewhere (e.g. professionals gate on the personal profile,
  /// not the business one). Defaults to the business [ensureCanGoLive].
  Future<void> openAvailabilityControl({bool Function()? gate}) async {
    // 1. Payment gate FIRST — an unpaid provider is told why and routed to the
    //    security-deposit flow; the sheet never opens.
    if (!(gate != null ? gate() : ensureCanGoLive())) return;

    // 2. Safety net: hydrate the hours if the profile hasn't populated them yet
    //    so the sheet shows the correct state (set-hours prompt vs live status).
    if (!hasSchedule) await loadHours();

    // 3. Always open the shop-status sheet. With no weekly hours it shows a
    //    "Set visiting hours" prompt; once hours exist it shows the live status
    //    + the today-only override + edit-hours.
    await showShopAvailabilitySheet(this);
  }

  /// Entry point for the header CLOCK button — visiting HOURS only (no live
  /// status, no today open/closed switch; the pill beside the clock is that
  /// switch), and no deposit gate, because this is where hours are *set and
  /// edited*, not where the shop goes live. A merchant who hasn't paid yet can
  /// still lay out their week; the gate then bites on [toggleLiveNow] (and
  /// again server-side on the today-override call), so nothing actually opens
  /// without it.
  Future<void> openScheduleControl() async {
    if (!hasSchedule) await loadHours();
    await showShopAvailabilitySheet(this, timingsOnly: true);
  }

  /// Entry point for the Go-Live PILL — a plain on/off switch once hours exist.
  ///
  /// The pill used to open the status sheet on every tap, which meant going
  /// live was "tap pill → read sheet → find the today switch → flip it". Hours
  /// now live behind the header clock ([openScheduleControl]), so the pill can
  /// do the one thing its toggle promises:
  ///   • no weekly hours yet → the sheet's "Set visiting hours" prompt (there is
  ///     nothing to switch on until a schedule exists), else
  ///   • flip today's override — open now, or closed for the rest of today.
  ///
  /// The order of the checks is deliberate — cheapest and most fixable first:
  ///
  ///   1. (on the catalogue screens) anything to sell — see
  ///      `ensureCatalogueBeforeGoLive`, which runs before this is called;
  ///   2. visiting HOURS — no schedule yet opens the weekly editor;
  ///   3. PAYMENT — the plan / security-deposit gate;
  ///   4. flip today's open/closed state.
  ///
  /// Hours come BEFORE payment because setting them is free, is the merchant's
  /// own work, and is required either way: sending someone to a payment screen
  /// first, taking their money and only then telling them the shop has no
  /// opening hours is the wrong way round.
  ///
  /// Saving hours does NOT go live. It is a separate step and it ends here —
  /// the merchant taps the pill again when they actually want to open, and from
  /// then on the clock button beside the pill ([openScheduleControl]) is where
  /// hours are edited. Rolling the two together would put a shop online the
  /// moment its opening times were written down, which is not what typing them
  /// in means.
  ///
  /// [gate] overrides the deposit check for callers whose deposit lives
  /// elsewhere (see [openAvailabilityControl]).
  Future<void> toggleLiveNow({bool Function()? gate}) async {
    if (isAvailabilityUpdating.value) return;

    // 2. Hydrate before deciding — an un-loaded schedule looks identical to an
    //    empty one, and would send an established merchant to the hours editor.
    if (!hasSchedule) await loadHours();
    if (!hasSchedule) {
      await openWeeklyEditor();
      // Say why the shop did not just open: the pill was tapped, a screen
      // appeared, hours were saved, and nothing went live. Without this the
      // silence reads as a failure.
      if (hasSchedule) {
        commonSnackBar(message: AppStrings.goLiveHoursSavedHint.tr);
      }
      return;
    }

    // 3. Payment — only now, with something to sell and hours to sell it in.
    if (!(gate != null ? gate() : ensureCanGoLive())) return;

    // 4. Flip today.
    if (shopStatus.value.isOpenNow) {
      await setClosedToday();
    } else {
      await setOpenToday();
    }
  }

  /// Open the weekly hours editor and re-hydrate on save. Used by both the
  /// sheet's "Set visiting hours" empty state and its "Edit weekly hours" row.
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

  /// Persist the weekly schedule to the BUSINESS endpoint. Returns null on
  /// success, else an error message for the editor to surface.
  Future<String?> _saveWeeklyHours(List<Schedule> schedule) async {
    final res = await BusinessProfileRepo().setBusinessHours({
      'timezone': 'Asia/Kolkata',
      'schedule': schedule.map((s) => s.toJson()).toList(),
    });
    return res.isSuccess
        ? null
        : (res.message ?? AppStrings.somethingWentWrong.tr);
  }

  /// Force the shop OPEN for today only (open all remaining day). Reverts to
  /// the weekly schedule automatically tomorrow.
  Future<void> setOpenToday() async {
    await _applyTodayOverride({
      'isOpen': true,
      'shopOpenTime': '00:00',
      'shopCloseTime': '23:59',
    });
  }

  /// Force the shop CLOSED for today only. Reverts tomorrow.
  Future<void> setClosedToday() async {
    await _applyTodayOverride({'isOpen': false});
  }

  Future<void> _applyTodayOverride(Map<String, dynamic> body) async {
    if (!ensureCanGoLive()) return;
    isAvailabilityUpdating.value = true;
    try {
      final res = await BusinessProfileRepo().setTodayHours(body);
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

  /// Clear today's override and fall back to the weekly schedule immediately.
  Future<void> revertTodayOverride() async {
    isAvailabilityUpdating.value = true;
    try {
      final res = await BusinessProfileRepo().clearTodayHours();
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

  /// Freshness guard for the visited business profile, keyed per business id.
  final FetchCache _visitedProfileCache = FetchCache();

  /// Load the visited business profile only when it isn't already loaded &
  /// fresh for this [userId]. Use on screen (re)entry; call
  /// [viewBusinessProfileById] directly for explicit/silent refreshes.
  Future<void> viewBusinessProfileByIdIfNeeded(String userId) async {
    final hasData = visitedBusinessProfileDetails?.data != null;
    if (_visitedProfileCache.isFresh('profile|$userId', hasData: hasData)) {
      return;
    }
    await viewBusinessProfileById(userId);
  }

  Future<void> viewBusinessProfileById(String userId,
      {bool silent = false}) async {
    try {
      // Silent mode skips the loading flag so consumers (e.g. the
      // rate / follow callbacks) can refresh in the background without
      // tearing down the UI behind a shimmer.
      if (!silent) isProfileLoading.value = true;
      ResponseModel responseModel =
          await BusinessProfileRepo().viewBusinessProfileById(userId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        visitedBusinessProfileDetails = ViewBusinessProfileModel.fromJson(data);
        profileVersion.value++;
        // Stamp freshness (covers both normal & silent refreshes) so a screen
        // re-entry for the same business reuses the profile.
        _visitedProfileCache.mark('profile|$userId');
        // visitedBusinessProfileDetails = visitedBusinessProfileDetails_ as ViewBusinessProfileModel?;
        imagePath?.value = visitedBusinessProfileDetails?.data?.logo ?? "";
        businessDescription.value =
            visitedBusinessProfileDetails?.data?.businessDescription ?? "";

        viewBusinessResponseNew = ApiResponse.complete(responseModel);
        visitingController.isFollow.value =
            visitedBusinessProfileDetails?.data?.is_following ?? false;
        distanceFromKm.value = await getDistanceInKm(
                visitedBusinessProfileDetails?.data?.businessLocation?.lat ?? 0,
                visitedBusinessProfileDetails?.data?.businessLocation?.lon ??
                    0) ??
            0.0;
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      logs("Stack trace ${s}");
      viewBusinessResponseNew = ApiResponse.error('error');
    } finally {
      if (!silent) isProfileLoading.value = false;
    }
  }

  Future<void> getBusinessDetailedRatings(String businessId,
      {bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isBusinessRatingsLoadingMore.value || !businessRatingsHasMore) return;
      isBusinessRatingsLoadingMore.value = true;
    } else {
      isBusinessRatingsFirstLoading.value = true;
      businessRatingsPage = 1;
      businessRatingsHasMore = true;
      businessRatingsList.clear();
    }

    try {
      Map<String, dynamic> queryParams = {
        ApiKeys.page: businessRatingsPage,
        ApiKeys.limit: 10,
      };

      ResponseModel responseModel = await BusinessProfileRepo()
          .getBusinessRatings(businessId: businessId, queryParams: queryParams);
      if (responseModel.isSuccess) {

        BusinessRatingsModel businessRatingsModel =
            BusinessRatingsModel.fromJson(responseModel.response?.data);
        final List<BusinessRatingsData> newBusinessRatingsData =
            businessRatingsModel.data ?? [];

        if (newBusinessRatingsData.isNotEmpty) {
          if (isLoadMore) {
            businessRatingsList.addAll(newBusinessRatingsData);
          } else {
            businessRatingsList.assignAll(newBusinessRatingsData);
          }
          businessRatingsPage++;
        }
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        businessRatingsHasMore = false;
      }
    } catch (e) {
    } finally {
      if (isLoadMore) {
        isBusinessRatingsLoadingMore.value = false;
      } else {
        isBusinessRatingsFirstLoading.value = false;
      }
    }
  }

  Future<bool> submitPersonalRating({
    required String userId,
    required int rating,
    required String comment,
  }) async {
    try {
      Map<String, dynamic> params = {
        "rating": rating,
        "comment": comment,
      };

      ResponseModel? responseModel;

      responseModel =
          await BusinessProfileRepo().submitRatingToPersonal(userId, params);

      if (responseModel.isSuccess) {
        commonSnackBar(message: "Thank you for your rating!");
        return true;
      } else {
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  Future<bool> submitBusinessRatingController({
    required String businessId,
    required int rating,
    required String comment,
  }) async {
    try {
      Map<String, dynamic> params = {
        "rating": rating,
        "comment": comment,
      };

      ResponseModel? responseModel;

      responseModel = await BusinessProfileRepo()
          .submitRatingToBusinessAccount(businessId, params);

      if (responseModel.isSuccess) {
        commonSnackBar(message: "Thank you for your rating!");
        return true;
      } else {
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  // Fetch products from API
  final RxList<GetProductData> products = <GetProductData>[].obs;

  Future<void> fetchProducts(
      {required String visitBusinessId, bool? isSilent}) async {
    try {
      if (isSilent != true) {
        products.clear();
      }

      errorMessage.value = '';
      final Map<String, dynamic> queryParams = {
        ApiKeys.ownerType: ProviderType.business.title,
      };
      queryParams[ApiKeys.businessId] = visitBusinessId;

      final responseModel = await ProductRepo().fetchProductsRepo(queryParams: queryParams);

      final getOwnProductModel =
          GetProductModel.fromJson(responseModel.response!.data);
      if (isSilent != true) {
        products.addAll(getOwnProductModel.data);
      } else {
        products.value = getOwnProductModel.data;
      }

      businessProductResponse.value = ApiResponse.complete(responseModel);
    } catch (e) {
      businessProductResponse.value = ApiResponse.error('error');
      errorMessage.value = e.toString();
    } finally {}
  }

  // Fetch service from API
  final RxList<GetServiceModel> services = <GetServiceModel>[].obs;

  Future<void> fetchServices({required String visitBusinessId}) async {
    errorMessage.value = '';
    final response = await BusinessProfileRepo().getServices(
        businessId: visitBusinessId, queryParam: {'type': 'service'});
    final queryParam = {
      'type': 'service',
    };

    await BusinessProfileRepo().getServices(
      businessId: visitBusinessId,
      queryParam: queryParam,
    );

    if (response.isSuccess) {
      businessServiceResponse.value = ApiResponse.complete(response);
      List<dynamic> jsonData = [];

      if (response.response?.data is List) {
        jsonData = json.decode(jsonEncode(response.response?.data));
      } else if (response.response?.data is Map) {
        jsonData = json.decode(jsonEncode(response.response?.data['services']));
      }

      services.value =
          jsonData.map((e) => GetServiceModel.fromJson(e)).toList();
    } else {
      businessServiceResponse.value = ApiResponse.error('error');
    }
  }

  // Fetch foods from API
  final RxList<GetFoodDetailsModel> foods = <GetFoodDetailsModel>[].obs;

  Future<void> fetchFoods(
      {required String visitBusinessId, bool? isSilent}) async {
    try {
      if (isSilent != true) {
        foods.clear();
      }

      errorMessage.value = '';
      final responseModel = await BusinessProfileRepo()
          .getFoods(businessId: visitBusinessId, queryParam: {'type': 'food'});
      if (responseModel.isSuccess) {
        businessFoodResponse.value = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        if (data is List) {
          // if API returns a raw array
          foods.value =
              data.map((e) => GetFoodDetailsModel.fromJson(e)).toList();
        } else if (data is Map && data['services'] is List) {
          // if API returns { "data": [...] }
          foods.value = (data['services'] as List)
              .map((e) => GetFoodDetailsModel.fromJson(e))
              .toList();
        }
      } else {
        businessFoodResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      businessFoodResponse.value = ApiResponse.error('error');
      errorMessage.value = e.toString();
    } finally {}
  }
}
