import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/business_user_response_model.dart';
import 'package:BlueEra/core/api/model/gst_verify_model.dart';
import 'package:BlueEra/core/api/model/individual_user_response_model.dart';
import 'package:BlueEra/core/api/model/otp_verify_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/socket/chat_socket.dart';
import 'package:BlueEra/features/common/auth/model/business_category_response_model.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/guest_res_model.dart';
import 'package:BlueEra/features/common/auth/model/individual_field_response_model.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/model/single_business_category_response.dart';
import 'package:BlueEra/features/common/auth/model/username_res_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/views/screens/complete_guest_profile_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_account_type_v2_screen.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart';
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_service_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import '../../bottomNavigationBar/controller/bottom_bar_controller.dart';

class AuthController extends GetxController {
  final Rx<ApiResponse> mobileNoOtpSendResponse =
      Rx<ApiResponse>(ApiResponse.initial('Initial'));
  ApiResponse businessCategoryResponse = ApiResponse.initial('Initial');
  ApiResponse professionListingResponse = ApiResponse.initial('Initial');
  final Rx<ApiResponse> otpVerificationResponse = Rx<ApiResponse>(ApiResponse.initial('Initial'));
  final Rx<ApiResponse> addUserResponse = Rx<ApiResponse>(ApiResponse.initial('Initial'));
  Rx<ApiResponse> gstVerifyResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getUserNameCheckResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteUserAccountResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessSubCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> contentCreatorFieldResponse = ApiResponse.initial('Initial').obs;
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');
  final mobileNumberEditController = TextEditingController(text: '');
  final referralCodeController = TextEditingController();
  final otherNatureOfBusinessTextController = TextEditingController();
  final subCategorySpecializationTextController = TextEditingController();
  Rx<String> imgPath = "".obs;
  RxString isOtpType = "".obs;
  RxString errorMessage = "".obs;
  RxString categorySpecializationText = ''.obs;
  RxBool isSearchOpen = false.obs;
  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;

  RxString selectedParentSlug = AppConstants.individual.obs;
  Rxn<OnboardingCategoryModel> selectedIndividualOnboardingProfile = Rxn<OnboardingCategoryModel>();
  Rxn<OnboardingCategoryModel> selectedBusinessOnboardingProfile = Rxn<OnboardingCategoryModel>();

  RxBool isAppLoading = false.obs;

  // CategoryData? selectedCategoryData;
  String? selectedCategorySlugId;
  String? selectedCategoryName;
  SubCategories? selectedSubCategoryData;
  BusinessType? selectedTypeOfBusiness;
  NatureOfBusiness? selectedNatureOfBusiness;
  String? selectedNumberOfEmployees;
  String? selectedNumberOfBranch;

  final List<String> employeeRangeOptions = [
    "1–10 Employees",
    "11–50 Employees",
    "51–100 Employees",
    "100+ Employees",
    "200+ Employees",
    "500+ Employees",
    "1000+ Employees",
    "1500+ Employees",
    "2000+ Employees",
    "5000+ Employees",
    "9999+ Employees",
  ];

  final List<String> branchUnitOptions = [
    "Single Branch/Unit",
    "2-5 Branch/Units",
    "5–10 Branch/Units",
    "10+ Branch/Units",
    "15+ Branch/Units",
    "20+ Branch/Units",
    "50+ Branch/Units",
    "100+ Branch/Units",
    "150+ Branch/Units",
    "200+ Branch/Units",
    "500+ Branch/Units",
  ];

  ///SEND OTP...
  Future<void> sendOTP() async {
    Map<String, dynamic> requestData = {
      ApiKeys.contact_no: mobileNumberEditController.text,
      ApiKeys.action: AppConstants.REGISTER,
      ApiKeys.type: isOtpType.value,
    };
    // Drive the mobile screen's loader + dim overlay while the send is in
    // flight. Every exit path below resolves this (complete/error) so the
    // overlay can never get stuck up.
    mobileNoOtpSendResponse.value = ApiResponse.loading('loading');
    try {
      ResponseModel responseModel = await AuthRepo().authMobileOtpSendRepo(bodyRequest: requestData);
      // logs("responseModel: ${responseModel.statusCode}");
      if (responseModel.isSuccess) {
        mobileNoOtpSendResponse.value = ApiResponse.complete(responseModel);
        commonSnackBar(message: responseModel.message ?? AppStrings.success);
        Get.offNamed(
          RouteHelper.getOtpPageScreenRoute(),
          arguments: {ApiKeys.argMobileNumber: mobileNumberEditController.text},
        );
      } else {
        mobileNoOtpSendResponse.value =
            ApiResponse.error(responseModel.message ?? AppStrings.somethingWentWrong);
        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      mobileNoOtpSendResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    }
  }

  ///VERIFY OTP...
  Future<void> verifyOTP({required String? otp}) async {
    otpVerificationResponse.value = ApiResponse.loading('loading');
    String? token;
    try {
      // Always force-refresh on login so the backend gets the latest FCM
      // token bound to this user. Relying on the cached value caused the
      // previous user's stale token to be re-sent after a 401 auto-logout
      // when the cleanup path hadn't successfully rotated it.
      token = await AppNotificationHandler.refreshFcmToken();
      if (token == null || token.isEmpty) {
        // Refresh failed (GMS unavailable, APNs not ready, etc.) — fall
        // back to whatever is in cache so verifyOTP still sends something.
        token = await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.notificationDeviceToken);
      }
      print("TOKEN = $token");

      Map<String, dynamic> requestData = {
        ApiKeys.contact_no: mobileNumberEditController.text,
        ApiKeys.otp: otp,
        ApiKeys.device_token: token,
        ApiKeys.one_signal_player_id: "",
      };
      ResponseModel response = await AuthRepo().authMobileOtpVerifyRepo(bodyRequest: requestData);

      if (response.statusCode == 200) {
        OtpVerifyModel data = otpVerifyModelFromJson(jsonEncode(response.response?.data));

        final dataUser = response.response?.data?[ApiKeys.user] ?? false;

        ///if true user key the user created successfully....
        if (dataUser) {
          // When we navigate away via `offNamedUntil`, the OTP screen (and
          // its dim loading veil) is destroyed only once the destination has
          // been built. Keep `otpVerificationResponse` in LOADING across the
          // navigation so the veil stays up over the heavy
          // BottomNavigationBarScreen build — otherwise flipping to COMPLETE
          // here removes the veil on the still-visible OTP screen a frame
          // before the destination paints, producing a 1–2s "bare OTP screen"
          // gap. Only the non-navigating paths below clear the loader.
          bool navigatedAway = false;
          if (data.token != null && (data.token?.isNotEmpty ?? false)) {
            // OnesignalService.setOneSignalUserIdentity(
            //     data.data?.username ?? '');
            if (data.data?.accountType?.toUpperCase() == AppConstants.business) {
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.accountType, AppConstants.business);
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.userBusinessId, data.data?.business);
              await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, data.token);
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.userLoginMobile, data.data?.contactNo);
              await getMobileNo();
              await getUserLoginBusinessId();
              await getUserLoginAccountType();
              await getUserAuthToken();
              // Auth is now available — flush any FCM token that was queued
              // during the pre-login window so the backend gets the live
              // device token immediately.
              unawaited(AppNotificationHandler.flushPendingTokenSync());
              // iOS: also (re)register the VoIP/PushKit token now that we're
              // authenticated. The one-shot launch sync bailed while logged
              // out, so without this first-login devices never deliver their
              // VoIP token and the backend falls back to non-CallKit FCM
              // pushes. force: true bypasses the optimistic cache.
              unawaited(AppNotificationHandler.syncVoipToken(force: true));
              // Token is now in `authTokenGlobal` — open the chat socket
              // so incoming-call / chat events flow immediately this
              // session. CallController.onInit skipped the cold-start
              // connect while logged out; this is the first authenticated
              // connect, on which buffered call-event listeners replay.
              unawaited(ChatSocketService().connectToSocket());
              // First-time login has no cached business profile yet, so
              // `businessTypeGlobal` is still empty and `resolveBusinessScreen`
              // would briefly route to `_UnknownBusinessFallback` while
              // BottomNavigationBarScreen's post-frame init catches up.
              // Awaiting the fetch here keeps the user on the OTP screen
              // (under its dim overlay) until the prefs are populated;
              // _handlePostFrameInitialization then no-ops because the
              // response is already COMPLETE. Subsequent logins hit the
              // BusinessProfileCache instantly so this stays cheap.
              final viewProfileController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
              await viewProfileController.viewBusinessProfile();
              navigatedAway = true;
              Get.offNamedUntil(
                RouteHelper.getBottomNavigationBarScreenRoute(),
                (route) => false,
                // Business logs in onto the Me tab (index 0) so the merchant's
                // own shop/dashboard is front and centre. (Individuals still
                // land on Discover — see the branch below.)
                arguments: {ApiKeys.initialIndex: 0},
              );
            } else if (data.data?.accountType?.toUpperCase() == AppConstants.individual) {
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.userLoginMobile, data.data?.contactNo);
              await getMobileNo();

              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.accountType, AppConstants.individual);
              await getUserLoginAccountType();

              await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, data.token);

              await getUserAuthToken();
              // Auth is now available — flush any FCM token queued during the
              // pre-login window (see business branch above).
              unawaited(AppNotificationHandler.flushPendingTokenSync());
              // iOS: (re)register the VoIP/PushKit token now we're authed —
              // see business branch above.
              unawaited(AppNotificationHandler.syncVoipToken(force: true));
              // First authenticated connect — see business branch above.
              unawaited(ChatSocketService().connectToSocket());
              // Same first-time rationale as the business branch:
              // `userProfileTypeGlobal` is still empty until the personal
              // profile lands, and resolveIndividualScreen would briefly
              // show the fallback. Awaiting here keeps the user on the
              // OTP screen's dim overlay until the prefs are populated.
              // PersonalProfileCache makes this near-instant on subsequent
              // logins.
              final personalController = Get.put(ViewPersonalDetailsController(), permanent: true);
              await personalController.viewPersonalProfile(forceRefresh: true);

              // Riders must be reachable for live dispatch. On login, if the
              // required go-live device permissions aren't granted yet, walk
              // them through the permission gate → set-availability screen
              // (which persists their hours), then land on home.
              // NB: gate on areRequiredGranted (background location + overlay),
              // NOT areAllGranted — battery optimization can't be reliably
              // satisfied on Android 13+/16, so including it would force every
              // rider into the permission screen on every login. Same reasoning
              // as the go-live handlers.
              final isRider = userProfessionGlobal == BIKE_RIDER ||
                  userProfessionGlobal == CAR_TAXI_DRIVER;
              if (isRider &&
                  !await GoLivePermissionService.areRequiredGranted()) {
                await Get.to(() => const GoLivePermissionScreen());
                // final granted = await Get.to(() => const GoLivePermissionScreen());
                // if (granted == true) {
                //   await Get.to(() => const GroceryShopAvailabilityScreen());
                // }
              }

              navigatedAway = true;
              Get.offNamedUntil(
                RouteHelper.getBottomNavigationBarScreenRoute(),
                (route) => false,
                arguments: {ApiKeys.initialIndex: 1},
              );
            }

            // One-time post-login language refresh (names list + current
            // language). Fires once per login lifecycle, then served from the
            // local cache until the next logout/login or a manual language
            // change. assumeLoggedIn bypasses the in-memory login flag, which
            // may not be refreshed yet this session. Fire-and-forget — must
            // not block the post-login navigation.
            unawaited(getOrPut(() => LanguageControllerNew())
                .refreshAfterLoginOnce(assumeLoggedIn: true));

            // Now that the setup is done and we're navigating to the
            // bottom-nav, surface the success message — the snackbar
            // lands on the destination screen rather than flashing on
            // the OTP screen while the spinner is still running.
            commonSnackBar(message: response.message ?? AppStrings.success);

            final wasDeletionCancelled = data.accountDeletionCancelled == true;
            if (wasDeletionCancelled) {
              Future.delayed(const Duration(milliseconds: 400), () {
                commonSnackBar(
                  message: AppStrings.accountDeletionCancelledBanner.tr,
                  isFromHomeScreen: true,
                );
              });
            }
          } else {
            commonSnackBar(message: response.message ?? AppStrings.tokenIsNull);
          }
          // Only clear the loader when we stayed on the OTP screen. On the
          // nav branches the veil must persist until `offNamedUntil` tears
          // the screen down (see `navigatedAway` note above).
          if (!navigatedAway) {
            otpVerificationResponse.value = ApiResponse.complete(response);
          }
        }

        ///Guest create account but profile create.....
        else if (data.data?.accountType?.toUpperCase() == AppConstants.guest) {
          await SharedPreferenceUtils.guestUserLoggedIn(
            loginUserId_: "${data.data?.id}",
            contactNo: "${data.data?.contactNo}",
            autToken: "${data.token}",
            getUserName: "${data.data?.name ?? data.data?.username}",
            profileImage: data.data?.profileImage ?? '',
          );
          await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.accountType, AppConstants.guest);
          await getGuestUserLoginData();
          // await Future.delayed(Duration(milliseconds: 350));
          // Get.offAll(() => const ChooseAccountTypeScreen());
          Get.offAll(() => const CreateAccountTypeV2Screen());
          // New PDF-based onboarding flow. Legacy screen kept as a fallback:
          // Get.offAll(() => const CreateAccountTypeScreen());
          // Get.toNamed(RouteHelper.getCreateAccountTypeScreenRoute());

          // Get.offNamedUntil(
          //   RouteHelper.getBottomNavigationBarScreenRoute(),
          //   (route) => false,
          // );
          otpVerificationResponse.value = ApiResponse.complete(response);
        }

        ///GUEST ACCOUNT.....
        else {
          Get.offAll(() => const CompleteGuestProfileScreen());
          otpVerificationResponse.value = ApiResponse.complete(response);
        }
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        otpVerificationResponse.value = ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      logs("ERROR ${e}");
      logs("STACK TRACE: $s");
      otpVerificationResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
      // Get.dialog(CustomText(e.toString()));
    }
  }

  Future<void> addIndividualUser({required Map<String, dynamic>? reqData}) async {
    addUserResponse.value = ApiResponse.loading('loading');
    try {
      ResponseModel response = await AuthRepo().updateIndividualAccountUserRepo(bodyRequest: reqData);
      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        addUserResponse.value = ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final upgraded = IndividualUserResponseModel.fromJson(response.response?.data ?? {});
      if (!(upgraded.status ?? false)) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        addUserResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
        return;
      }

      await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.accountType, AppConstants.individual);
      await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, upgraded.token);
      await getUserLoginAccountType();
      await getUserAuthToken();
      // Guest → individual upgrade: token just landed, open the chat
      // socket so call/chat events flow without an app restart. Fire
      // and forget — UI must not block on socket handshake.
      unawaited(ChatSocketService().connectToSocket());

      // Parallelize the two slowest network steps so the user reaches
      // the Add Bio screen ~one round-trip sooner:
      //   1. viewPersonalProfile  — needed because the Add Bio screen
      //      reads the freshly-created personal profile.
      //   2. createServiceController / createMinimalEarnService —
      //      placeholder earn-service for PROFESSIONAL / SELF_EMPLOYED.
      //      Backend side-effect; navigation doesn't depend on it but
      //      we wait so any failure surfaces to the user before they
      //      leave this screen.
      final personalController = Get.put(ViewPersonalDetailsController(), permanent: true);
      final pending = <Future<void>>[
        personalController.viewPersonalProfile(forceRefresh: true),
      ];
      if (reqData?['profileType'] == PROFESSIONAL) {
        final controller = getOrPut(() => AiProfessionalsController());
        final data = {
          "name": reqData?['name'],
          "email": reqData?['email'],
          "gender": reqData?['gender'],
          "profileType": reqData?['profileType'],
          "profession": reqData?['profession'],
          "designation": reqData?['designation'],
          "pincode": reqData?['pincode'],
          "address": reqData?['address'],
        };
        pending.add(controller.createServiceController(reqParm: data));
      } else if (reqData?['profileType'] == SELF_EMPLOYED) {
        final controller = getOrPut(() => SelfWorkServiceController());
        controller.professionCategory = reqData?['profession'];
        pending.add(controller.createMinimalEarnService(
          serviceSubType: 'selfWork',
          professionCategoryOverride: controller.professionCategory?.toUpperCase(),
        ));
      } else if (reqData?['profession'] == CONTENT_CREATOR ||
          reqData?['profession'] == ARTIST) {
        // Artist / Content-Creator: create the earn-artist profile. Per the
        // earn-artist guide's field mapping, the parent group (ARTIST /
        // CONTENT_CREATOR) → payload `type`, and the picked subcategory
        // (carried in `designation`) → payload `category`.
        final artistController = getOrPut(() => EarnArtistController());
        pending.add(artistController
            .createMinimalArtistProfile(
              type: reqData?['profession'],
              category: reqData?['designation'],
            )
            .then<void>((_) {}));
      }
      await Future.wait(pending);
      // https://be.beapp.in/api/map-service/api/stores?page=1&limit=20&lat=21.1902733&lng=72.8644417&type=Service&radius=1500&category_id=CONSULTING_BUSINESS_SERVICES
      // Cascade settled — only now surface the success message so the
      // user sees it as a confirmation, not while the spinner is still
      // running.
      commonSnackBar(message: response.message ?? AppStrings.success);

      final dobJsonString = reqData?[ApiKeys.date_of_birth_Obj];
      final dobMap = jsonDecode(dobJsonString);

      if (Get.isRegistered<BottomBarController>()) {
        Get.find<BottomBarController>().currentIndex.value = 1;
      }

      // Already on the bottom-nav root — pop any profile-creation
      // screens stacked on top, then push the Add Bio screen on top
      // of bottom nav. Do NOT offAllNamed back to bottom nav:
      // recreating it re-runs meScreens()'s post-frame init and
      // re-opens the "complete profile" sheet on top of this screen.
      Get.until((route) => route.isFirst);
      Get.toNamed(
        RouteHelper.getAddBioViaAiScreenRoute(),
        arguments: {
          ApiKeys.argProfession: reqData?[ApiKeys.profession],
          ApiKeys.argDesignation: reqData?[ApiKeys.designation],
          ApiKeys.argSelectedDay: dobMap[ApiKeys.date],
          ApiKeys.argSelectedMonth: dobMap[ApiKeys.month],
          ApiKeys.argSelectedYear: dobMap[ApiKeys.year]
        },
      );

      clearAllData();
      addUserResponse.value = ApiResponse.complete(response);
    } catch (e) {
      logs("ERRPR $e");
      addUserResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  /// Automotive sub-sectors that are functionally "Service Other" — they
  /// have no dedicated module yet, so create-business hands them off to
  /// `createOtherProfileController` with `type = "other"`, identical to
  /// SUPPORT_SERVICES / generic Service businesses. Mirror of the set in
  /// `_isSpecificServiceSpecialAutomotive` on `BottomNavigationBarScreen`
  /// (which routes the same businesses to `AutomotiveServiceMain` on
  /// re-entry); both lists MUST stay in sync.
  static const Set<String> _automotiveOtherCategories = {
    'VEHICLE SERVICE',
    'VEHICLE_SERVICE',
    'TRANSPORT_LOGISTIC',
    'TRANSPORT LOGISTIC',
    'VEHICLE_SUPPORT',
    'VEHICLE SUPPORT',
    'TRANSPORT_LOGISTICS_PARKING',
    'TRANSPORT LOGISTICS PARKING',
  };

  Future<void> addBusinessUser({required Map<String, dynamic>? reqData}) async {
    addUserResponse.value = ApiResponse.loading('loading');
    try {
      ResponseModel response =
          await AuthRepo().updateBusinessAccountUserRepo(bodyRequest: reqData, showProgress: false);
      if (response.isSuccess) {
        final upgraded = BusinessUserResponseModel.fromJson(response.response?.data ?? {});
        if (upgraded.status ?? false) {
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, AppConstants.business);
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.userBusinessId, upgraded.businessId);
          await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, upgraded.token);

          await getUserLoginBusinessId();
          await getUserAuthToken();
          await getUserLoginAccountType();

          // Guest → business upgrade: token just landed, open the chat
          // socket so call/chat events flow without an app restart. Fire
          // and forget — UI must not block on socket handshake.
          unawaited(ChatSocketService().connectToSocket());

          final typeOfBusiness = reqData?[ApiKeys.type_of_business].toString().toUpperCase();
          final categoryOfBusiness = reqData?[ApiKeys.category_Of_Business].toString().toUpperCase();
          // Build with conditional spreads so null fields are omitted
          // entirely rather than serialized as JSON `null`. The
          // create*Profile endpoints below send this as a JSON body
          // (not multipart), and the backend rejects an explicit null
          // ("null data can't pass") — e.g. `nature_of_business` is null
          // for a Service-type business that has no nature of business.
          // (Multipart requests coerce null → "" so they didn't surface
          // this, which is why it only reproduced on the JSON path.)
          final reqBody = <String, dynamic>{
            ApiKeys.business_name: reqData?[ApiKeys.business_name],
            ApiKeys.business_location: reqData?[ApiKeys.business_location],
            ApiKeys.type_of_business: reqData?[ApiKeys.type_of_business],
            if (reqData?[ApiKeys.nature_of_business] != null)
              ApiKeys.nature_of_business: reqData?[ApiKeys.nature_of_business],
            ApiKeys.date_of_incorporation: reqData?[ApiKeys.date_of_incorporation],
            ApiKeys.category_Of_Business: reqData?[ApiKeys.category_Of_Business],
            if (reqData?[ApiKeys.sub_category_Of_Business] != null)
              ApiKeys.sub_category_Of_Business: reqData?[ApiKeys.sub_category_Of_Business],
            if (reqData?[ApiKeys.number_of_Employees] != null)
              ApiKeys.number_of_Employees: reqData?[ApiKeys.number_of_Employees],
            if (reqData?[ApiKeys.number_of_branch] != null)
              ApiKeys.number_of_branch: reqData?[ApiKeys.number_of_branch],
          };

          // Parallelize the slowest network steps so the user reaches
          // step 2 ~one round-trip sooner:
          //   1. viewBusinessProfile — needed because the next screen
          //      reads the freshly-created business profile.
          //   2. createSchool / createLab / createHospital / createOther
          //      / createHotel — placeholder side-effect for the
          //      specific business type. Navigation doesn't depend on
          //      it but we wait so any failure surfaces before the
          //      user leaves this screen.
          final viewProfileController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
          final pending = <Future<void>>[
            viewProfileController.viewBusinessProfile(),
          ];

          if (typeOfBusiness == BusinessType.Siksha.name.toUpperCase()) {
            pending.add(getOrPut(() => SchoolController()).createSchoolController(reqData: reqData));
          } else if (categoryOfBusiness == "Diagnostic".toUpperCase()) {
            pending
                .add(getOrPut(() => LabServiceAiController()).createLabServiceController(reqData: reqBody));
          } else if (categoryOfBusiness == "HOSPITALS" ||
              categoryOfBusiness == "ALTERNATIVE HEALTH" ||
              categoryOfBusiness == "DOCTORS" ||
              categoryOfBusiness == "CLINICS") {
            pending.add(getOrPut(() => HospitalServiceAiController())
                .createHospitalServiceController(reqData: reqBody));
          } else if (categoryOfBusiness == "SUPPORT_SERVICES" ||
              typeOfBusiness == BusinessType.Service.name.toUpperCase() ||
              (typeOfBusiness == BusinessType.Automotive.name.toUpperCase() &&
                  _automotiveOtherCategories.contains(categoryOfBusiness))) {
            // Direct instantiation (not `getOrPut`) — two classes share the
            // name `BusinessProfileFullController` (one under me/others, one
            // under me/automotive_service). GetX keys its registry by the
            // simple class name, so the wrong instance can be returned and
            // the cast then throws. We only need the controller for one
            // fire-and-forget call here, so binding to GetX is unnecessary.
            final controller = BusinessProfileFullController();
            reqBody['profileName'] = reqData?[ApiKeys.business_name];
            reqBody['type'] = "other";
            pending.add(controller.createOtherProfileController(reqParm: reqBody));
          } else if (typeOfBusiness == "FINANCE" || typeOfBusiness == "BANKING_SECTOR") {
            // Direct instantiation — see the comment in the SUPPORT_SERVICES
            // branch above for the GetX class-name collision rationale.
            final controller = BusinessProfileFullController();
            reqBody['profileName'] = reqData?[ApiKeys.business_name];
            reqBody['type'] = "finance";
            reqBody['sub_type'] = categoryOfBusiness;
            // reqBody['sub_type'] = typeOfBusiness;
            pending.add(controller.createOtherProfileController(reqParm: reqBody));
          } else if (typeOfBusiness == BusinessType.Motel.name.toUpperCase()) {
            // await SharedPreferenceUtils.setSecureValue(
            //     SharedPreferenceUtils.businessCategory, categoryOfBusiness);
            // businessCategoryGlobal = await SharedPreferenceUtils.getSecureValue(
            //     SharedPreferenceUtils.businessCategory) ??
            //     "";
            logs("categoryOfBusiness= ${categoryOfBusiness}");
            reqBody['category'] = categoryOfBusiness;

            pending.add(_createMotelService(reqData ?? {}));
          }

          await Future.wait(pending);

          // Cascade settled — only now surface the success message so
          // the user sees it as a confirmation, not while the spinner
          // is still running.
          commonSnackBar(message: response.message ?? AppStrings.success);

          if (Get.isRegistered<BottomBarController>()) {
            Get.find<BottomBarController>().currentIndex.value = 1;
          }

          // Already on the bottom-nav root — pop any business-creation
          // screens stacked on top, then push step 2 on top of bottom
          // nav. Do NOT offAllNamed back to bottom nav: recreating it
          // re-runs resolveBusinessScreen()'s post-frame init and
          // re-opens the "complete profile" sheet underneath / on top
          // of step 2.
          Get.until((route) => route.isFirst);
          Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepTwoRoute());
          addUserResponse.value = ApiResponse.complete(response);
          clearAllData();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          addUserResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
        }
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        addUserResponse.value = ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRPR $e");
      addUserResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  /// Motel branch helper for [addBusinessUser]: reverse-geocodes
  /// lat/lon to city/state/pincode, then creates the hotel-service
  /// placeholder. Extracted because the inline version was hard to
  /// read alongside the other branch creations inside `Future.wait`.
  Future<void> _createMotelService(Map<String, dynamic> reqData) async {
    final controller = getOrPut(() => HotelServiceController());
    final locationMap = jsonDecode(reqData[ApiKeys.business_location]);
    final lat = locationMap[ApiKeys.lat];
    final lon = locationMap[ApiKeys.lon];

    String city = '';
    String state = '';
    String pincode = '';
    final double? latD = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
    final double? lonD = lon is num ? lon.toDouble() : double.tryParse(lon.toString());
    if (latD != null && lonD != null) {
      try {
        final placemarks = await placemarkFromCoordinates(latD, lonD);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = p.locality?.isNotEmpty == true ? p.locality! : (p.subAdministrativeArea ?? '');
          state = p.administrativeArea ?? '';
          pincode = p.postalCode ?? '';
        }
      } catch (e) {
        log('Motel reverse-geocode failed: $e');
      }
    }

    await controller.createHotelServiceController(reqParm: {
      ApiKeys.businessId: businessId,
      "name": reqData[ApiKeys.business_name],
      "description": "",
      "website": "",
      "address": {"city": city, "state": state, "pincode": pincode},
      "location": {
        "name": "",
        "type": "Point",
        "coordinates": [lat, lon]
      },
      "bus_station_location": {"name": "", "type": "Point", "coordinates": []},
      "category": reqData["category_Of_Business"],
    });
  }

  Rx<GstVerifyModel>? gstVerifyModel = GstVerifyModel().obs;
  RxBool isValidate = false.obs, isHaveGstApprove = false.obs, hasGstNumber = false.obs;
  RxBool isGstVerifyLoading = false.obs;
  final businessNameTextController = TextEditingController();
  final businessOtherCategoryTextController = TextEditingController();
  RxString businessName = "".obs;

  Future<void> getGstVerify({required String? gstNumber}) async {
    try {
      isGstVerifyLoading.value = true;
      gstVerifyResponse.value = ApiResponse.loading('loading');

      ResponseModel responseModel = await AuthRepo().getUserVerifyGstRepo(gstNumber: gstNumber);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        gstVerifyModel?.value = GstVerifyModel.fromJson(data);

        if (gstVerifyModel?.value.isVerified == true) {
          List<String>? parts = gstVerifyModel?.value.data?.registrationDate?.split("/");

          selectedDay?.value = int.tryParse(parts?[0] ?? "") ?? 0;
          selectedMonth?.value = int.tryParse(parts?[1] ?? "") ?? 0;
          selectedYear?.value = int.tryParse(parts?[2] ?? "") ?? 0;
          isHaveGstApprove.value = true;
          businessNameTextController.text = gstVerifyModel?.value.data?.tradeName ?? "";
          businessName.value = gstVerifyModel?.value.data?.tradeName ?? "";

          gstVerifyResponse.value = ApiResponse.complete(responseModel);

          await _updateGstBusinessDetails(gstNumber: gstNumber);
        } else {
          isHaveGstApprove.value = false;
          gstVerifyResponse.value = ApiResponse.error(responseModel.message ?? AppStrings.somethingWentWrong);
          commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        isHaveGstApprove.value = false;
        gstVerifyResponse.value = ApiResponse.error(responseModel.message ?? AppStrings.somethingWentWrong);
        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isHaveGstApprove.value = false;
      gstVerifyResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isGstVerifyLoading.value = false;
    }
  }

  Future<void> _updateGstBusinessDetails({required String? gstNumber}) async {
    try {
      final data = gstVerifyModel?.value.data;
      final List<String>? parts = data?.registrationDate?.split("/");

      final Map<String, dynamic> body = {
        ApiKeys.gstNo: gstNumber ?? data?.gstin ?? "",
        if ((data?.tradeName ?? "").isNotEmpty) ApiKeys.businessName: data?.tradeName,
        if (parts != null && parts.length == 3)
          ApiKeys.date_of_incorporation: {
            ApiKeys.date: int.tryParse(parts[0]) ?? 0,
            ApiKeys.month: int.tryParse(parts[1]) ?? 0,
            ApiKeys.year: int.tryParse(parts[2]) ?? 0,
          },
        if (selectedTypeOfBusiness != null) ApiKeys.type_of_business: selectedTypeOfBusiness?.name,
        if (selectedNatureOfBusiness != null) ApiKeys.Nature_of_Business: selectedNatureOfBusiness?.name,
        if ((selectedCategorySlugId ?? "").isNotEmpty) ApiKeys.category_Of_Business: selectedCategorySlugId,
      };
      logs("bodyRequest for gst ==== ${body}");
      final ResponseModel response = await AuthRepo().authBusinessUserRegisterRepo(bodyRequest: body);

      if (response.isSuccess) {
        Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("updateGstBusinessDetails ERROR: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///CHECK USER NAME....

  /// -1 = none selected
  final selectedIndex = (-1).obs;

  void select(int i) {
    // Single select; tap again to unselect (optional)
    selectedIndex.value = (selectedIndex.value == i) ? -1 : i;
  }

  String? get selectedValue => selectedIndex.value == -1 ? null : userNameList[selectedIndex.value];
  RxBool isShowCheck = true.obs;
  RxList<String> userNameList = <String>[].obs;
  Rx<UsernameResModel> usernameResModel = UsernameResModel().obs;

  Future<void> getCheckUsernameController({required String? value}) async {
    userNameList.clear();
    try {
      ResponseModel responseModel = await AuthRepo().getCheckUsernameRepo(userName: value);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        usernameResModel.value = UsernameResModel.fromJson(data);
        if (usernameResModel.value.sampleUsername?.isNotEmpty ?? false)
          userNameList.addAll(usernameResModel.value.sampleUsername ?? []);
        isShowCheck.value = false;

        // commonSnackBar(
        //     message: usernameResModel.value.message ?? "username is available");
        getUserNameCheckResponse.value = ApiResponse.complete(responseModel);
      } else {
        isShowCheck.value = true;

        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isShowCheck.value = true;

      getUserNameCheckResponse.value = ApiResponse.error('error');
    }
  }

  ///DELETE USER ACCOUNT
  // Future<void> deleteUserController({required String? value}) async {
  //   try {
  //     ResponseModel responseModel =
  //     await AuthRepo().deleteUserAccountRepo(userName: value);
  //
  //     if (responseModel.isSuccess) {
  //       final data = responseModel.response?.data;
  //       // usernameResModel.value = UsernameResModel.fromJson(data);
  //
  //
  //       commonSnackBar(message: usernameResModel.value.message??"User Account Deleted Successfully");
  //       deleteUserAccountResponse.value = ApiResponse.complete(responseModel);
  //
  //     } else {
  //       deleteUserAccountResponse.value = ApiResponse.error('error');
  //
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //
  //     deleteUserAccountResponse.value = ApiResponse.error('error');
  //   }
  // }

  ///CLEAR ALL DATA..
  clearAllData() {
    selectedDay?.value = 0;
    selectedMonth?.value = 0;
    selectedYear?.value = 0;
    isValidate.value = false;
    isHaveGstApprove.value = false;
    businessNameTextController.clear();
    mobileNumberEditController.clear();
    subCategorySpecializationTextController.clear();
  }

  ///USER BLOCK(PARTIAL AND FULL)...
  Future<void> userBlocked({required bool isPartialBlocked, required String otherUserId}) async {
    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo: otherUserId,
        ApiKeys.type: isPartialBlocked ? BlockedType.partial.label : BlockedType.full.label,
        ApiKeys.duration: 0
      };

      final response = await AuthRepo().blockUser(params: params);

      if (response.isSuccess) {
        blockUserResponse = ApiResponse.complete(response);
        BlockUserResponse blockUser = BlockUserResponse.fromJson(response.response?.data);
        commonSnackBar(message: blockUser.message, isFromHomeScreen: true);
      } else {
        blockUserResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      blockUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {}
  }

  /// Status of the guest-account creation request. Drives the
  /// Continue button's inline loader on the Complete Guest Profile
  /// screen — the screen reads `.status` and shows a spinner while
  /// it's `Status.LOADING`.
  Rx<ApiResponse> createGuestProfileResponse = ApiResponse.initial('Initial').obs;

  ///Add User...
  Future<void> createGuestAccountUserController({required Map<String, dynamic> reqData}) async {
    createGuestProfileResponse.value = ApiResponse.loading('loading');
    try {
      final imagePath = reqData[ApiKeys.profile_image];
      if (imagePath is String && imagePath.isNotEmpty) {
        final image = await multiPartImage(imagePath: imagePath);
        if (image != null) {
          reqData[ApiKeys.profile_image] = image;
        } else {
          reqData.remove(ApiKeys.profile_image);
        }
      }
      ResponseModel response = await AuthRepo().createGuestAccountRepo(params: reqData);
      if (response.isSuccess) {
        GuestResModel guestResModel = guestResModelFromJson(jsonEncode(response.response?.data));
        if (guestResModel.success ?? false) {
          await SharedPreferenceUtils.guestUserLoggedIn(
            loginUserId_: "${guestResModel.data?.id}",
            contactNo: "${guestResModel.data?.contactNo}",
            autToken: "${guestResModel.token}",
            getUserName: "${guestResModel.data?.name}",
            profileImage: guestResModel.data?.profileImage ?? '',
          );
          await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.accountType, AppConstants.guest);
          await getGuestUserLoginData();
          await Future.delayed(Duration(milliseconds: 350));
          Get.offAll(() => const BottomNavigationBarScreen(initialIndex: 0));
          clearAllData();
          createGuestProfileResponse.value = ApiResponse.complete(response);
          commonSnackBar(message: response.message ?? AppStrings.success);
        } else {
          commonSnackBar(message: guestResModel.message ?? AppStrings.somethingWentWrong);
          createGuestProfileResponse.value =
              ApiResponse.error(guestResModel.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        createGuestProfileResponse.value =
            ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      createGuestProfileResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  RxBool isBusinessSubCategoriesLoading = false.obs;
  List<SubCategories> businessSubCategoriesList = [];
  Rxn<String> subCategoryErrorMessage = Rxn<String>();

  Future<void> fetchBusinessSubCategories({required String categorySlugId}) async {
    try {
      isBusinessSubCategoriesLoading.value = true;
      businessSubCategoriesList.clear();
      subCategoryErrorMessage.value = null;

      final response = await AuthRepo().getBusinessSubCategoriesRepo(tagId: categorySlugId);

      if (!response.isSuccess) {
        subCategoryErrorMessage.value = response.message;
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      final businessCategoryModel = SingleBusinessCategoryModelResponse.fromJson(jsonData);
      businessSubCategoriesList = businessCategoryModel.subCategories ?? [];

      businessSubCategoryResponse.value = ApiResponse.complete(response);
    } catch (e) {
      subCategoryErrorMessage.value = e.toString();
      businessSubCategoryResponse.value = ApiResponse.error('error');
    } finally {
      isBusinessSubCategoriesLoading.value = false;
    }
  }

  RxBool isBusinessCategoriesLoading = false.obs;
  List<BusinessCategory> businessCategoriesList = [];
  Rxn<String> categoryErrorMessage = Rxn<String>();

  Future<void> fetchBusinessCategoriesByType({required BusinessType businessTpe}) async {
    try {
      isBusinessCategoriesLoading.value = true;
      businessCategoriesList.clear();
      categoryErrorMessage.value = null;

      final response = await AuthRepo().fetchBusinessCategoriesByTypeRepo(businessType: businessTpe.name);

      if (!response.isSuccess) {
        categoryErrorMessage.value = response.message;
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      final businessCategoryResponseModel = BusinessCategoryResponseModel.fromJson(jsonData);
      businessCategoriesList = businessCategoryResponseModel.businessCategory ?? [];

      businessCategoryResponse = ApiResponse.complete(response);
    } catch (e) {
      categoryErrorMessage.value = e.toString();
      businessCategoryResponse = ApiResponse.error('error');
    } finally {
      isBusinessCategoriesLoading.value = false;
    }
  }

  RxBool isIndividualFieldLoading = false.obs;
  RxList<IndividualFields> arrIndividualFields = <IndividualFields>[].obs;
  RxList<SubCategories> arrIndividualSubCategories = <SubCategories>[].obs;

  Future<void> fetchIndividualFields({required String tagId}) async {
    try {
      isIndividualFieldLoading.value = true;
      arrIndividualFields.clear();
      arrIndividualSubCategories.clear();

      final response = await AuthRepo().getIndividualFieldsRepo(
        tagId: tagId,
      );

      if (response.isSuccess) {
        contentCreatorFieldResponse.value = ApiResponse.complete(response);
        final individualFieldsResponseModel = IndividualFieldsResponseModel.fromJson(response.response?.data);
        arrIndividualFields.value = individualFieldsResponseModel.data?.fields ?? [];
      } else {
        contentCreatorFieldResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      contentCreatorFieldResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isIndividualFieldLoading.value = false;
    }
  }

  /// Business and Personal Category

  /// True until we've populated the onboarding category buckets from
  /// either Hive or the network. Discover (and any other consumer) shows
  /// a shimmer / spinner while this is true, then swaps to the real cards.
  RxBool isInitialCategoriesLoading = true.obs;

  /// Cache-first loader for the master onboarding lists.
  ///
  /// The categories / professions master lists change rarely, so the network
  /// is hit **only when the local Hive cache is empty** — i.e. once after
  /// login (logout wipes the Hive boxes via `Hive.deleteFromDisk()`, so the
  /// next login refetches). Every other launch serves purely from cache and
  /// makes no `getAllcategories` / professions API call. Pass
  /// [forceRefresh] = true (e.g. pull-to-refresh) to fetch even when cached.
  Future<void> loadCategoriesCacheFirstThenRefresh({bool forceRefresh = false}) async {
    final hive = HiveServices();

    final cachedBusiness = hive.getAllCategories();
    final cachedProfessions = hive.getAllProfessions();

    final hasCachedBusiness = cachedBusiness != null && cachedBusiness.isNotEmpty;
    final hasCachedProfessions = cachedProfessions != null && cachedProfessions.isNotEmpty;

    if (hasCachedBusiness) {
      // log('from business cache');
      updateBusinessCategoriesFromApi(cachedBusiness);
    }
    if (hasCachedProfessions) {
      // log('from individual cache');
      updateIndividualCategoriesFromApi(cachedProfessions);
    }

    // If we have any cache, render immediately so no shimmer lingers.
    if (hasCachedBusiness || hasCachedProfessions) {
      isInitialCategoriesLoading.value = false;
    }

    // Fetch from the network ONLY for the lists whose local cache is empty
    // (or when an explicit refresh is requested). `_getAllBusinessCategories`
    // / `_getAllIndividualProfession` both write through to Hive on success
    // and rebuild the in-memory buckets, so the next launch is a pure cache
    // hit with no API call. These methods are private so external callers
    // always go through this cache-first entry point — single source of
    // truth, no path that bypasses Hive.
    final pending = <Future<void>>[];
    if (forceRefresh || !hasCachedBusiness) {
      pending.add(_getAllBusinessCategories());
    }
    if (forceRefresh || !hasCachedProfessions) {
      pending.add(_getAllIndividualProfession());
    }
    if (pending.isNotEmpty) {
      await Future.wait<void>(pending);
    }

    // First-launch path: no cache existed, so the shimmer was still
    // visible. Drop it now that the network has filled the buckets.
    if (isInitialCategoriesLoading.value) {
      isInitialCategoriesLoading.value = false;
    }
  }

  // Reactive buckets: mutating them (via `assignAll` in the update methods
  // below) notifies any `Obx` that reads them — including on the *silent*
  // network refresh — with no manual change-counter to keep in sync.
  final RxList<ProfessionTypeData> individualOnboardingSocialProfileList = <ProfessionTypeData>[].obs;
  final RxList<ProfessionTypeData> individualOnboardingGigWorkList = <ProfessionTypeData>[].obs;
  final RxList<ProfessionTypeData> individualOnboardingSkillWorkList = <ProfessionTypeData>[].obs;
  final RxList<ProfessionTypeData> individualOnboardingConsultationList = <ProfessionTypeData>[].obs;

  /// Derived flat master list of profession types — concatenates the four
  /// onboarding buckets (which are the source of truth). Exposed as a
  /// getter (not a stored field) so there's no second copy of the data
  /// that can drift from the buckets, and so profession state stays
  /// symmetric with business state, which has always lived as buckets
  /// only. Callers that previously read the stored `professionTypeDataList`
  /// field (profession-picker dialogs, `.isEmpty` guards in profile setup
  /// screens) keep working unchanged.
  List<ProfessionTypeData> get professionTypeDataList => [
        ...individualOnboardingSocialProfileList,
        ...individualOnboardingGigWorkList,
        ...individualOnboardingSkillWorkList,
        ...individualOnboardingConsultationList,
      ];

  /// Network-level fetch for the master profession list. Private — callers
  /// outside this controller MUST go through `loadCategoriesCacheFirstThenRefresh`
  /// so they can't accidentally bypass the Hive cache.
  Future<void> _getAllIndividualProfession() async {
    try {
      ResponseModel responseModel = await AuthRepo().getAllProfessionsRepo();

      if (responseModel.isSuccess) {
        professionListingResponse = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        // Local var only — there is no stored master list field. The
        // bucketing call below is the source of truth, and the
        // `professionTypeDataList` getter on this controller derives a
        // flat list from those buckets when consumers need one.
        final professions = PersonalProfessionModel.fromJson(data).data ?? [];
        // Persist BEFORE bucketing so each item's `individualProfileType`
        // enum is still null at serialize time — bucketing sets that
        // enum, and enums don't round-trip through jsonEncode.
        await HiveServices().saveProfessionList(professions);
        updateIndividualCategoriesFromApi(professions);
      } else {
        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
        professionListingResponse = ApiResponse.error('error');
      }
    } catch (e) {
      professionListingResponse = ApiResponse.error('error');
    }
  }

  void updateIndividualCategoriesFromApi(List<ProfessionTypeData> categoryData) {
    // Accumulate into local lists, then push each bucket once via `assignAll`.
    // assignAll replaces the contents and emits a single change notification,
    // so reactive consumers repaint exactly once per bucket (vs. one per
    // clear()/add() if we mutated the RxLists in place).
    final social = <ProfessionTypeData>[];
    final gig = <ProfessionTypeData>[];
    final skill = <ProfessionTypeData>[];
    final consult = <ProfessionTypeData>[];

    for (var apiCategory in categoryData) {
      final String apiType = apiCategory.profileType ?? "";
      // log('apitype-- $apiType');

      switch (apiType) {
        case 'Social Profile':
          apiCategory.individualProfileType = IndividualProfileType.SOCIAL_PROFILE;
          social.add(apiCategory);
          break;
        case 'GigWork':
          apiCategory.individualProfileType = IndividualProfileType.GIG_WORKER;
          gig.add(apiCategory);
          break;
        case 'Self Employed':
          apiCategory.individualProfileType = IndividualProfileType.SELF_EMPLOYED;
          skill.add(apiCategory);
          break;
        case 'Professional':
          apiCategory.individualProfileType = IndividualProfileType.PROFESSIONAL;
          consult.add(apiCategory);
          break;
      }
    }

    individualOnboardingSocialProfileList.assignAll(social);
    individualOnboardingGigWorkList.assignAll(gig);
    individualOnboardingSkillWorkList.assignAll(skill);
    individualOnboardingConsultationList.assignAll(consult);
  }

  RxBool isAllBusinessCategoriesLoading = false.obs;

  // Reactive buckets — see the profession buckets above for the rationale.
  final RxList<CategoryData> businessOnboardingServicesCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingProductsCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingGroceriesCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingFoodsCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingManufacturingCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingAutomotiveServicesCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingHealthcareSectorsCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingHospitalityStayCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingEducationTrainingCategories = <CategoryData>[].obs;
  final RxList<CategoryData> businessOnboardingFinancialSectorsCategories = <CategoryData>[].obs;

  /// Read inside an `Obx` to subscribe to *any* onboarding-bucket change —
  /// initial cache load or silent network refresh — when the actual bucket
  /// reads happen in child widgets across a build boundary (e.g. Discover's
  /// section cards, which the parent `Obx` can't see into). The returned
  /// count exists only to give the closure a value to read; the point is the
  /// reactive subscription that reading every bucket establishes. `assignAll`
  /// fires that subscription even when a refresh returns the same item count.
  int get onboardingBucketsWatch =>
      businessOnboardingServicesCategories.length +
      businessOnboardingProductsCategories.length +
      businessOnboardingGroceriesCategories.length +
      businessOnboardingFoodsCategories.length +
      businessOnboardingManufacturingCategories.length +
      businessOnboardingAutomotiveServicesCategories.length +
      businessOnboardingHealthcareSectorsCategories.length +
      businessOnboardingHospitalityStayCategories.length +
      businessOnboardingEducationTrainingCategories.length +
      businessOnboardingFinancialSectorsCategories.length +
      individualOnboardingSocialProfileList.length +
      individualOnboardingGigWorkList.length +
      individualOnboardingSkillWorkList.length +
      individualOnboardingConsultationList.length;

  /// Network-level fetch for the master business-category list. Private —
  /// callers outside this controller MUST go through
  /// `loadCategoriesCacheFirstThenRefresh` so they can't accidentally
  /// bypass the Hive cache.
  Future<void> _getAllBusinessCategories() async {
    try {
      isAllBusinessCategoriesLoading.value = true;

      final response = await AuthRepo().getBusinessCategoriesRepo();

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      List<CategoryData> businessCategories = CategoryModel.fromJson(jsonData).data ?? [];
      await HiveServices().saveCategoryList(businessCategories);
      updateBusinessCategoriesFromApi(businessCategories);
      businessCategoryResponse = ApiResponse.complete(response);
    } catch (e) {
      businessCategoryResponse = ApiResponse.error('error');
    } finally {
      isAllBusinessCategoriesLoading.value = false;
    }
  }

  void updateBusinessCategoriesFromApi(List<CategoryData> categoryData) {
    // Accumulate locally, then push each bucket once via `assignAll` (single
    // change notification per bucket — see `updateIndividualCategoriesFromApi`).
    final services = <CategoryData>[];
    final products = <CategoryData>[];
    final groceries = <CategoryData>[];
    final foods = <CategoryData>[];
    final manufacturing = <CategoryData>[];
    final automotive = <CategoryData>[];
    final healthcare = <CategoryData>[];
    final hospitality = <CategoryData>[];
    final education = <CategoryData>[];
    final finance = <CategoryData>[];

    for (var apiCategory in categoryData) {
      final String apiType = apiCategory.type ?? "";
      // log('apitype-- $apiType');

      switch (apiType) {
        case 'Service':
          apiCategory.businessType = BusinessType.Service;
          services.add(apiCategory);
          break;
        case 'Product':
          apiCategory.businessType = BusinessType.Product;
          products.add(apiCategory);
          break;
        case 'Grocery':
          apiCategory.businessType = BusinessType.Grocery;
          groceries.add(apiCategory);
          break;
        case 'Food':
          apiCategory.businessType = BusinessType.Food;
          foods.add(apiCategory);
          break;
        case 'Manufacturing':
          apiCategory.businessType = BusinessType.Manufacturing;
          manufacturing.add(apiCategory);
          break;
        case 'Automotive':
          apiCategory.businessType = BusinessType.Automotive;
          automotive.add(apiCategory);
          break;
        case 'Healthcare':
          apiCategory.businessType = BusinessType.Healthcare;
          healthcare.add(apiCategory);
          break;
        case 'Motel':
          apiCategory.businessType = BusinessType.Motel;
          hospitality.add(apiCategory);
          break;
        case 'Siksha':
          apiCategory.businessType = BusinessType.Siksha;
          education.add(apiCategory);
          break;
        case 'Finance':
          apiCategory.businessType = BusinessType.Finance;
          finance.add(apiCategory);
          break;
      }
    }

    businessOnboardingServicesCategories.assignAll(services);
    businessOnboardingProductsCategories.assignAll(products);
    businessOnboardingGroceriesCategories.assignAll(groceries);
    businessOnboardingFoodsCategories.assignAll(foods);
    businessOnboardingManufacturingCategories.assignAll(manufacturing);
    businessOnboardingAutomotiveServicesCategories.assignAll(automotive);
    // // DEBUG: dump the automotive-services categories so we can see exactly what
    // log('[AutomotiveCat] total=${automotive.length}');
    // for (final c in automotive) {
    //   log('[AutomotiveCat] name="${c.name}" tagId="${c.tagId}" id="${c.id}" '
    //       'type="${c.type}" '
    //       'subs=${c.subCategories?.map((s) => s.name).toList()}');
    // }

    businessOnboardingHealthcareSectorsCategories.assignAll(healthcare);
    businessOnboardingHospitalityStayCategories.assignAll(hospitality);
    businessOnboardingEducationTrainingCategories.assignAll(education);
    businessOnboardingFinancialSectorsCategories.assignAll(finance);
  }

// void debugPrintBusinessCategories() {
//   if (kDebugMode) {
//     final categoryGroups = {
//       'Services': businessOnboardingServicesCategories,
//       'Products': businessOnboardingProductsCategories,
//       'Groceries': businessOnboardingGroceriesCategories,
//       'Foods': businessOnboardingFoodsCategories,
//       'Manufacturing': businessOnboardingManufacturingCategories,
//       'Automotive': businessOnboardingAutomotiveServicesCategories,
//       'Healthcare': businessOnboardingHealthcareSectorsCategories,
//       'Hospitality': businessOnboardingHospitalityStayCategories,
//       'Education': businessOnboardingEducationTrainingCategories,
//       'Finance': businessOnboardingFinancialSectorsCategories,
//     };
//
//     log('=== BUSINESS CATEGORIES DEBUG START ===', name: 'CategorySync');
//
//     categoryGroups.forEach((name, list) {
//       if (list.isNotEmpty) {
//         log('--- $name (${list.length} items) ---', name: 'CategorySync');
//         for (var item in list) {
//           // Replace 'name' with whatever property identifies your CategoryData
//           log('  ID: ${item.id} | Title: ${item.name} | Tag Id: ${item.tagId}',
//               name: 'CategorySync');
//         }
//       } else {
//         log('--- $name (Empty) ---', name: 'CategorySync');
//       }
//     });
//
//     log('=== BUSINESS CATEGORIES DEBUG END ===', name: 'CategorySync');
//   }
// }
}
