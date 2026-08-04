import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/image_upload_response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/ai_document_verification_service.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/model/GetBlueeraPiolotModel.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/model/aadhaar_verification_model.dart';
import 'package:BlueEra/features/common/delivery_partner/model/associated_shops_model.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:BlueEra/features/common/delivery_partner/model/vehicle_enums_response.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum RiderProfileStep {
  personalInfo,
  addressInfo,
  personalIdentificationInfo,
  drivingInfo,
  vehicleImagesInfo,
  vehicleInfo,
  aadharInfo,
  rcInfo,
  panInfo
}

/// The visible stage of the Aadhaar OKYC (OTP) verification bottom-sheet.
enum AadhaarStage {
  /// Enter 12-digit Aadhaar + tick consent → generate OTP.
  entry,

  /// Enter the 6-digit OTP received on the Aadhaar-linked mobile → verify.
  otp,

  /// Identity verified — show name + masked number.
  verified,
}

class DeliveryPartnerController extends GetxController {
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingPersonalInformationResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingAddressResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingPersonalIdentificationResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingDrivingVerificationResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingVehicleImagesResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingVehicleInformationResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingStatusResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> vehicleDataResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> nearByRidersResponse = ApiResponse.initial('Initial').obs;

  /// Associated shops
  Rx<ApiResponse> associatedShopsResponse = ApiResponse.initial('Initial').obs;
  Rx<AssociatedShopsResponse> associatedShopsData = AssociatedShopsResponse().obs;
  RxList<AssociatedShop> associatedShops = <AssociatedShop>[].obs;
  RxBool isAssociatedShopsLoading = false.obs;
  int _associatedShopsPage = 1;
  bool _hasMoreAssociatedShops = true;

  final stepStatus = <RiderProfileStep, bool>{}.obs;
  String? riderVerificationStatus;

  /// step 1
  final fullNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final emailController = TextEditingController();
  Rx<GenderType?> selectedGender = Rx<GenderType?>(null);
  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;
  final GlobalKey<FormState> formKeyStep1 = GlobalKey<FormState>();

  /// step 2
  final GlobalKey<FormState> formKeyStep2 = GlobalKey<FormState>();
  final locationController = TextEditingController();
  final landmarkController = TextEditingController();
  final pinCodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool enabledLiveLocation = false.obs;
  RxBool isFetchingAddressDetails = false.obs;
  RxString isRiderServiceOpt = ''.obs;

  /// step 3
  final GlobalKey<FormState> formKeyStep3 = GlobalKey<FormState>();
  // Dedicated form keys for each document upload bottom-sheet so the
  // text-field validators (Aadhar/PAN/DL/RC number) actually fire — matching
  // the personal-document flow (GenericDocumentWidget wraps its field in a
  // Form and validates before upload).
  final GlobalKey<FormState> aadharFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> panFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> dlFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> rcFormKey = GlobalKey<FormState>();
  static const String livePhotoImageId = 'livePhotoImageId';
  final aadharController = TextEditingController();
  final panNumberController = TextEditingController();
  int maxLiveUploadImages = 2;

  final RxList<File> livePhoto = <File>[].obs;
  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<File> panCardImage = Rxn<File>();

  /// step 4
  final GlobalKey<FormState> formKeyStep4 = GlobalKey<FormState>();
  final rcController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final Rxn<File> rcFrontImage = Rxn<File>();
  final Rxn<File> rcBackImage = Rxn<File>();
  final Rxn<File> drivingLicenseFrontImage = Rxn<File>();
  final Rxn<File> drivingLicenseBackImage = Rxn<File>();

  /// step 5

  final RxList<File> vehicleNumberPlateImages = <File>[].obs;
  final RxList<File> vehicleRightSideImages = <File>[].obs;
  final RxList<File> vehicleLeftSideImages = <File>[].obs;
  final RxList<File> vehicleFrontImages = <File>[].obs;
  final RxList<File> vehicleBackImages = <File>[].obs;
  int maxVehicleImageUpload = 4;

  /// steps 6
  final GlobalKey<FormState> formKeyStep6 = GlobalKey<FormState>();
  final vehicleNameController = TextEditingController();
  final vehicleRegistrationNumberController = TextEditingController();
  final vehicleModelController = TextEditingController();

  final RxBool isTermsAccepted = false.obs;
  Rx<VehicleEnumItem?> selectedVehicleType = Rx<VehicleEnumItem?>(null);
  Rx<VehicleEnumItem?> selectedVehicleRegistrationType =
      Rx<VehicleEnumItem?>(null);
  Rx<VehicleEnumItem?> selectedVehicleUseType = Rx<VehicleEnumItem?>(null);
  Rx<VehicleEnumItem?> selectedFuelType = Rx<VehicleEnumItem?>(null);

  /// Vehicle model year (manufacturing) — current year back to last 40 years.
  final Rxn<String> selectedVehicleModelYear = Rxn<String>();

  List<String> get vehicleModelYears {
    final currentYear = DateTime.now().year;
    return List.generate(16, (i) => (currentYear - i).toString());
  }

  Future<ImageUploadResponseModel?> uploadInit(
      {required String fileType}) async {
    try {
      ResponseModel response = await DeliveryPartnerRepo()
          .initRiderServiceFileUploadRepo(fileType: fileType);

      if (response.isSuccess) {
        uploadInitResponse.value = ApiResponse.complete(response);
        final imageUploadResponseModel =
            ImageUploadResponseModel.fromJson(response.response?.data);
        return imageUploadResponseModel;
      }
    } catch (e) {
      uploadInitResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    }
    return null;
  }

  RxBool isRiderStatusLoading = true.obs;
  Rx<RiderOnboardingStatusData?> riderOnboardingStatusData =
      Rx<RiderOnboardingStatusData?>(null);

  /// Tracks an in-flight status fetch so concurrent callers share one request.
  Future<void>? _statusInFlight;

  /// Fetches the rider onboarding status.
  ///
  /// Cache-first: serves the rider's own status from the local cache and does
  /// NOT hit the network on normal screen opens. The API is called only when
  /// [forceRefresh] is true — i.e. when the status actually changes (after a
  /// document upload/delete or service-preference update) or on an explicit
  /// pull-to-refresh — and the fresh response is written back to the cache.
  /// The cache is wiped on logout (`Hive.deleteFromDisk()`), so a re-login
  /// refetches once.
  ///
  /// Coalesces concurrent callers: on login the bottom nav mounts both the
  /// rider dashboard (RiderServiceScreen) and the rider "me" tab (RiderMeScreen)
  /// at once, and each requests the status in its own initState — which fired
  /// two identical network GETs back to back. Any call arriving while a fetch is
  /// already running shares that single request instead. (A cached paid deposit
  /// is terminal, so a forceRefresh caller coalescing onto an in-flight fetch
  /// still gets a correct, current result.)
  // ── When the onboarding status is fetched ────────────────────────────────
  //
  //   No cached data            → call the API, cache the answer.
  //   Cached and SETTLED        → serve the cache. No call, ever.
  //   Cached and NOT settled    → serve the cache to paint, then call.
  //   Something was submitted   → call with forceRefresh: true.
  //
  // "Settled" means nothing is left that the backend can change on its own:
  // verification approved AND the deposit paid. Until then the value is
  // expected to move without any action in the app — ops approves the
  // documents, a Razorpay webhook clears the deposit — so it is re-checked
  // whenever the rider gives us a natural moment (screen open, tab change,
  // app resume). Once settled, those same moments cost nothing.
  //
  // That is the whole policy: no timers, no staleness windows. The data itself
  // decides whether another call is worth making.

  Future<void> ridersOnboardingStatusRepoApi({bool forceRefresh = false}) {
    final inFlight = _statusInFlight;
    if (inFlight != null) return inFlight;
    final future = _fetchOnboardingStatus(forceRefresh: forceRefresh);
    _statusInFlight = future;
    future.whenComplete(() {
      if (identical(_statusInFlight, future)) _statusInFlight = null;
    });
    return future;
  }

  Future<void> _fetchOnboardingStatus({bool forceRefresh = false}) async {
    try {
      // Cache-first. The cache always paints (no spinner on a screen we have
      // data for); whether we ALSO call the API depends on whether anything is
      // still expected to change.
      //
      // This used to return early on any cached response with the deposit paid,
      // and the cache has no expiry — so once a rider paid, the app never
      // called this endpoint again and an ops approval never reached them until
      // they killed the app.
      if (!forceRefresh) {
        final cached = await riderOnboardingStatusCache.get(userId);
        if (cached != null) {
          final parsed = RiderOnboardingStatusResponse.fromJson(cached);
          _applyOnboardingStatus(parsed);
          isRiderStatusLoading.value = false;
          if (_isStatusSettled(parsed.data)) return;
          // Not settled — fall through and re-check.
        }
      }

      ResponseModel response =
          await DeliveryPartnerRepo().ridersOnboardingStatusRepo();

      if (response.isSuccess) {
        _applyOnboardingStatus(
            RiderOnboardingStatusResponse.fromJson(response.response?.data));
        // Cache the raw response so subsequent screen opens paint instantly.
        final raw = response.response?.data;
        if (raw is Map) {
          await riderOnboardingStatusCache.save(
              userId, Map<String, dynamic>.from(raw));
        }
      } else {
        ridersOnboardingStatusResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      ridersOnboardingStatusResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderStatusLoading.value = false;
    }
  }

  /// Nothing left for the backend to change on its own.
  ///
  /// Both halves move WITHOUT any action in the app — ops approves the
  /// documents, and a Razorpay webhook clears the deposit — so while either is
  /// outstanding the cached copy is worth re-checking. Once both are done the
  /// answer is final and the cache can serve forever.
  ///
  /// A rejection is NOT settled on purpose: a rejected rider re-uploads and
  /// waits for the same approval, so the value is still expected to move.
  bool _isStatusSettled(RiderOnboardingStatusData? data) {
    if (data == null) return false;
    return data.securityDepositPaid == true &&
        data.verificationStatus?.toLowerCase() == 'approved';
  }

  /// Applies a parsed onboarding-status response (from cache or API) to the
  /// observable UI state.
  void _applyOnboardingStatus(RiderOnboardingStatusResponse parsed) {
    ridersOnboardingStatusResponse.value = ApiResponse.complete();
    riderOnboardingStatusData.value = parsed.data;
    riderVerificationStatus = parsed.data?.verificationStatus;
    stepStatus.assignAll({
      RiderProfileStep.personalInfo:
          parsed.data?.personalInformation ?? false,
      RiderProfileStep.addressInfo: parsed.data?.address ?? false,
      RiderProfileStep.aadharInfo: parsed.data?.aadhar ?? false,
      RiderProfileStep.panInfo: true,
      // RiderProfileStep.panInfo: parsed.data?.pan ?? false,
      RiderProfileStep.drivingInfo: parsed.data?.dl ?? false,
      RiderProfileStep.rcInfo: parsed.data?.rc ?? false,
      RiderProfileStep.vehicleImagesInfo:
          parsed.data?.vehicleImages ?? false,
      RiderProfileStep.vehicleInfo:
          parsed.data?.vehicleInformation ?? false,
    });
  }

  // ── Support ("Contact Us") query ────────────────────────────────────
  final RxBool isSupportQueryLoading = false.obs;

  /// Submit a rider support query (the "Contact Us" sheet). Returns true on
  /// success (201). On a validation/other error the server's `message` is
  /// surfaced via snackbar and it returns false.
  /// See docs/backend/SUPPORT_QUERY_FRONTEND_GUIDE.md.
  Future<bool> submitSupportQuery({
    required String category,
    required String description,
  }) async {
    try {
      isSupportQueryLoading.value = true;
      final response = await DeliveryPartnerRepo().submitSupportQueryRepo(
        params: {
          ApiKeys.category: category,
          ApiKeys.description: description,
        },
      );
      if (response.isSuccess) return true;
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isSupportQueryLoading.value = false;
    }
  }

  RxBool isRiderDeleteDocumentLoading = false.obs;

  /// Deletes a single uploaded onboarding document and refreshes status.
  /// [documentType] is one of:
  ///   aadhar | pan | dl | rc | vehicle-images | vehicle-information
  /// NOTE: relies on an assumed DELETE endpoint — confirm with backend.
  Future<void> ridersDeleteDocumentApi(String documentType) async {
    try {
      isRiderDeleteDocumentLoading.value = true;
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingDeleteDocumentRepo(documentType: documentType);
      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.documentDeletedSuccessfully.tr);
        await ridersOnboardingStatusRepoApi(forceRefresh: true);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderDeleteDocumentLoading.value = false;
    }
  }

  /*Future<void> ridersOnboardingStatusRepoApi() async {
    try {
      ResponseModel response =
          await DeliveryPartnerRepo().ridersOnboardingStatusRepo();

      if (response.isSuccess) {
        ridersOnboardingStatusResponse.value = ApiResponse.complete(response);
        final riderOnboardingStatusResponse =
            RiderOnboardingStatusResponse.fromJson(response.response?.data);

        riderVerificationStatus =
            riderOnboardingStatusResponse.data?.verificationStatus;
        stepStatus.assignAll({
          RiderProfileStep.personalInfo:
              riderOnboardingStatusResponse.data?.personalInformation ?? false,
          RiderProfileStep.addressInfo:
              riderOnboardingStatusResponse.data?.address ?? false,
          RiderProfileStep.personalIdentificationInfo:
              riderOnboardingStatusResponse.data?.personalIdentification ??
                  false,
          RiderProfileStep.drivingInfo:
              riderOnboardingStatusResponse.data?.drivingVerification ?? false,
          RiderProfileStep.vehicleImagesInfo:
              riderOnboardingStatusResponse.data?.vehicleImages ?? false,
          RiderProfileStep.vehicleInfo:
              riderOnboardingStatusResponse.data?.vehicleInformation ?? false,
        });
      } else {
        ridersOnboardingStatusResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      ridersOnboardingStatusResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderStatusLoading.value = false;
    }
  }*/

  /// Whether every *mandatory* onboarding step is complete — this gates the
  /// "Submit for verification" button. Steps that never block submission:
  ///   • vehicleImagesInfo — vehicle photos are always optional.
  ///   • panInfo — the PAN card is not required (and isn't even shown) for
  ///     bike riders / cab drivers, so it must not be validated for them.
  /// RC & Driving-Licence only need their number (image upload is optional),
  /// so their completion is driven by the backend `rc` / `dl` flags here.
  bool get mandatoryStepsCompleted {
    final optionalSteps = <RiderProfileStep>{
      RiderProfileStep.vehicleImagesInfo,
      if (userProfessionGlobal == BIKE_RIDER ||
          userProfessionGlobal == CAR_TAXI_DRIVER)
        RiderProfileStep.panInfo,
    };
    return stepStatus.entries
        .where((e) => !optionalSteps.contains(e.key))
        .every((e) => e.value == true);
  }

  /// Gate check used by the Go Live toggles. Returns true when the deposit is
  /// paid. When the in-memory snapshot says unpaid/unknown, it FORCE-REFRESHES
  /// the onboarding status once before deciding — the deposit is reconciled
  /// server-side by the Razorpay webhook and nothing refreshed the snapshot
  /// after the rider paid on the contribution screen, so the gate kept seeing
  /// the stale pre-payment `paid:false` and bounced an already-paid rider
  /// back to the payment page forever.
  Future<bool> ensureSecurityDepositPaid() async {
    if (isSecurityDepositPaid) return true;
    await ridersOnboardingStatusRepoApi(forceRefresh: true);
    return isSecurityDepositPaid;
  }

  /// Whether the rider's security deposit is paid. Gates "Go Live": a rider
  /// can go online only once this is true. Reads the `securityDeposit.paid`
  /// flag from the latest onboarding-status response (null → treated as unpaid).
  bool get isSecurityDepositPaid =>
      riderOnboardingStatusData.value?.securityDepositPaid == true;

  /// The rider's FIRST ride is free — the security-deposit gate is waived until
  /// they complete it. Backend sends `freeRideUsed:false` while the free ride is
  /// still available and flips it to true afterwards. Absent (`null`, old
  /// backend) → treated as NOT free, so the deposit stays enforced — a safe
  /// default that never hands out free go-live to everyone by accident.
  /// See docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md.
  bool get isFirstRideFree =>
      riderOnboardingStatusData.value?.freeRideUsed == false;

  RiderVerificationState get riderVerificationState {
    final status = riderVerificationStatus?.toLowerCase();
    switch (status) {
      case 'approved':
        return RiderVerificationState.completed;

      case 'rejected':
        return RiderVerificationState.rejected;

      case 'pending':
        return RiderVerificationState.pending;

      default:
        return RiderVerificationState.pending;
    }
  }

  Future<void> uploadFileToS3Api({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
        onProgress: onProgress,
        file: file,
        fileType: fileType,
        preSignedUrl: preSignedUrl,
      );

      if (response?.isSuccess ?? false) {
        uploadFileToS3Response.value = ApiResponse.complete(response);
      } else {
        uploadFileToS3Response.value = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      uploadFileToS3Response.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<String?> _uploadToS3(File file) async {
    try {
      final fileInfo = getFileInfo(file);
      final mimeType = fileInfo['mimeType']!;

      final initModel = await uploadInit(fileType: mimeType);
      if (initModel == null) return null;

      await uploadFileToS3Api(
        file: file,
        fileType: mimeType,
        preSignedUrl: initModel.uploadUrl ?? '',
        onProgress: (progress) {
          debugPrint(
              " Uploading ${file.path.split('/').last}: ${(progress * 100).toStringAsFixed(0)}%");
        },
      );

      return initModel.fileUrl;
    } catch (e) {
      debugPrint("Upload failed for ${file.path}: $e");
      return null;
    }
  }

  // RxBool isPersonalInformationLoading = false.obs;
  //
  // /// ridersOnboardingPersonalInformationApi (Step 1)
  // Future<void> ridersOnboardingPersonalInformationApi(
  //     {String? screenName}) async {
  //   if (formKeyStep1.currentState!.validate()) {
  //     try {
  //       isPersonalInformationLoading.value = true;
  //       Map<String, dynamic> params = {
  //         ApiKeys.name: fullNameController.text,
  //         ApiKeys.gender: selectedGender.value?.name,
  //         ApiKeys.dob: '${selectedYear}-${selectedMonth}-${selectedDay}',
  //         ApiKeys.contactNo: mobileNumberController.text
  //       };
  //       if(emailController.text.trim().isNotEmpty) params[ApiKeys.email] = emailController.text;
  //
  //       ResponseModel response =
  //           await DeliveryPartnerRepo().ridersOnboardingPersonalInformationRepo(
  //         params: params,
  //       );
  //
  //       if (response.isSuccess) {
  //         ridersOnboardingPersonalInformationResponse.value =
  //             ApiResponse.complete(response);
  //         if (screenName == 'from_tab_view') {
  //           await ridersOnboardingStatusRepoApi();
  //         } else {
  //           Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
  //         }
  //       } else {
  //         ridersOnboardingPersonalInformationResponse.value =
  //             ApiResponse.error('error');
  //         commonSnackBar(
  //             message: response.message ?? AppStrings.somethingWentWrong);
  //       }
  //     } catch (e) {
  //       ridersOnboardingPersonalInformationResponse.value =
  //           ApiResponse.error('error');
  //       commonSnackBar(message: AppStrings.somethingWentWrong);
  //     } finally {
  //       isPersonalInformationLoading.value = false;
  //     }
  //   }
  // }

  // RxBool isRidersAddressLoading = false.obs;
  //
  // /// ridersOnboardingPersonalInformationApi (Step 2)
  // Future<void> ridersOnboardingAddressApi({String? screenName}) async {
  //   if (formKeyStep2.currentState!.validate()) {
  //     try {
  //       isRidersAddressLoading.value = true;
  //       Map<String, dynamic> params = {
  //         ApiKeys.homeLocation: {
  //           ApiKeys.latitude: latitude,
  //           ApiKeys.longitude: longitude
  //         },
  //         ApiKeys.streetAddress: locationController.text,
  //         ApiKeys.landmark: landmarkController.text,
  //         ApiKeys.pincode: pinCodeController.text,
  //         ApiKeys.city: cityController.text,
  //         ApiKeys.state: stateController.text,
  //         ApiKeys.locationPermission: enabledLiveLocation.value,
  //       };
  //
  //       ResponseModel response =
  //           await DeliveryPartnerRepo().ridersOnboardingAddressRepo(
  //         params: params,
  //       );
  //
  //       if (response.isSuccess) {
  //         ridersOnboardingAddressResponse.value =
  //             ApiResponse.complete(response);
  //         if (screenName == 'from_tab_view') {
  //           await ridersOnboardingStatusRepoApi();
  //         } else {
  //           Get.toNamed(RouteHelper.getVehicleInformationRidingScreenRoute());
  //         }
  //       } else {
  //         ridersOnboardingAddressResponse.value = ApiResponse.error('error');
  //         commonSnackBar(
  //             message: response.message ?? AppStrings.somethingWentWrong);
  //       }
  //     } catch (e) {
  //       ridersOnboardingAddressResponse.value = ApiResponse.error('error');
  //       commonSnackBar(message: AppStrings.somethingWentWrong);
  //     } finally {
  //       isRidersAddressLoading.value = false;
  //     }
  //   }
  // }
  //
  //
  // /// ridersOnboardingPersonalInformationApi (Step 3)
  // Future<void> ridersOnboardingPersonalIdentificationApi() async {
  //   if (formKeyStep3.currentState!.validate()) {
  //     // ---------- 1️⃣ VALIDATION ----------
  //     if (livePhoto.isEmpty) {
  //       commonSnackBar(message: AppStrings.pleaseSelectYourPhoto.tr);
  //       return;
  //     }
  //     if (aadharFrontImage.value == null) {
  //       commonSnackBar(message: AppStrings.pleaseSelectAadharFrontImage.tr);
  //       return;
  //     }
  //     if (aadharBackImage.value == null) {
  //       commonSnackBar(message: AppStrings.pleaseSelectAadharBackImage.tr);
  //       return;
  //     }
  //     if (panCardImage.value == null) {
  //       commonSnackBar(message: AppStrings.pleaseSelectPanCardImage.tr);
  //       return;
  //     }
  //
  //     try {
  //       isRiderPersonalIdentificationLoading.value = true;
  //
  //       // ---------- 2️⃣ INITIALIZE ----------
  //       List<String> userPictureUrls = [];
  //       String? aadharFrontImageUrl;
  //       String? aadharBackImageUrl;
  //       String? panCardImageUrl;
  //
  //       // ---------- 3️⃣ UPLOAD LIVE PHOTOS ----------
  //       for (final photo in livePhoto) {
  //         final fileUrl = await _uploadToS3(photo);
  //         if (fileUrl != null && fileUrl.isNotEmpty) {
  //           userPictureUrls.add(fileUrl);
  //         }
  //       }
  //
  //       // ---------- 4️⃣ UPLOAD AADHAR FRONT ----------
  //       aadharFrontImageUrl = await _uploadToS3(aadharFrontImage.value!);
  //
  //       // ---------- 5️⃣ UPLOAD AADHAR BACK ----------
  //       aadharBackImageUrl = await _uploadToS3(aadharBackImage.value!);
  //
  //       // ---------- 6️⃣ UPLOAD PAN CARD ----------
  //       panCardImageUrl = await _uploadToS3(panCardImage.value!);
  //
  //       // ---------- 7️⃣ PREPARE PAYLOAD ----------
  //       final params = {
  //         ApiKeys.aadharNo: aadharController.text,
  //         ApiKeys.panNo: panNumberController.text,
  //         ApiKeys.userPicture: userPictureUrls,
  //         ApiKeys.aadharImages: {
  //           ApiKeys.front: aadharFrontImageUrl,
  //           ApiKeys.back: aadharBackImageUrl,
  //         },
  //         ApiKeys.panImages: {
  //           ApiKeys.front: panCardImageUrl,
  //         },
  //       };
  //
  //       // ---------- 8️⃣ API CALL ----------
  //       final response = await DeliveryPartnerRepo()
  //           .ridersOnboardingPersonalIdentificationRepo(params: params);
  //
  //       // ---------- 9️⃣ HANDLE RESPONSE ----------
  //       if (response.isSuccess) {
  //         ridersOnboardingPersonalIdentificationResponse.value =
  //             ApiResponse.complete(response);
  //         Get.toNamed(RouteHelper.getDrivingVerificationRidingScreenRoute());
  //       } else {
  //         ridersOnboardingPersonalIdentificationResponse.value =
  //             ApiResponse.error('error');
  //         commonSnackBar(
  //           message: response.message ?? AppStrings.somethingWentWrong,
  //         );
  //       }
  //     } catch (e, s) {
  //       debugPrint('❌ ridersOnboardingPersonalIdentificationApi error: $e\n$s');
  //       ridersOnboardingPersonalIdentificationResponse.value =
  //           ApiResponse.error('error');
  //       commonSnackBar(message: AppStrings.somethingWentWrong);
  //     } finally {
  //       isRiderPersonalIdentificationLoading.value = false;
  //     }
  //   }
  // }

  /// ridersOnboardingPersonalInformationApi (Step 6)
  Future<void> ridersOnboardingVehicleInformationApi(String screenName) async {
    if (formKeyStep6.currentState!.validate()) {
      if (selectedVehicleRegistrationType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectVehicleRegType.tr);
        return;
      }

      if (selectedVehicleType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectVehicleType.tr);
        return;
      }

      if (selectedFuelType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectFuelType.tr);
        return;
      }

      if (!isTermsAccepted.value) {
        commonSnackBar(message: AppStrings.pleaseAcceptTermsAndConditions.tr);
        return;
      }

      try {
        isRiderVehicleInformationLoading.value = true;

        Map<String, dynamic> params = {
          ApiKeys.registrationType: selectedVehicleRegistrationType.value?.slugId,
          ApiKeys.registrationNo: vehicleRegistrationNumberController.text,
          ApiKeys.vehicleType: selectedVehicleType.value?.slugId,
          ApiKeys.vehicleUsesType: selectedVehicleUseType.value?.slugId,
          ApiKeys.vehicleName: vehicleNameController.text,
          ApiKeys.vehicleModelYear: vehicleModelController.text,
          ApiKeys.fuelType: selectedFuelType.value?.slugId,
        };

        ResponseModel response =
            await DeliveryPartnerRepo().ridersOnboardingVehicleInformationRepo(
          params: params,
        );

        if (response.isSuccess) {
          ridersOnboardingVehicleInformationResponse.value =
              ApiResponse.complete(response);

          await ridersOnboardingStatusRepoApi(forceRefresh: true);
          // From the tab view we're already on the bottom-nav route, so
          // there's nothing to pop — refreshing status is enough for the
          // parent Obx to swap the tab body to RiderProfileStatusScreen
          // (or DeliveryPartnerOrders once approved).
          if (screenName != 'from_tab_view') {
            Get.until((route) =>
                route.settings.name ==
                RouteHelper.getBottomNavigationBarScreenRoute());
          }
        } else {
          ridersOnboardingVehicleInformationResponse.value =
              ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
        checkStatusManageRoute();
      } catch (e) {
        ridersOnboardingVehicleInformationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isRiderVehicleInformationLoading.value = false;
      }
    }
  }

  RxBool isRiderPersonalIdentificationLoading = false.obs;

  Future<void> ridersPanCardApi() async {
    // ---------- 1️⃣ TEXT VALIDATION ----------
    if (!(panFormKey.currentState?.validate() ?? false)) return;

    try {
      isRiderPersonalIdentificationLoading.value = true;

      // ---------- 2️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.panNo: panNumberController.text,
      };

      // ---------- 3️⃣ API CALL ----------
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingPersonalIdentificationRepo(params: params);

      // ---------- 9️⃣ HANDLE RESPONSE ----------
      if (response.isSuccess) {
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.complete(response);
        Get.back();
      } else {
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
      await ridersOnboardingStatusRepoApi(forceRefresh: true);
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingPersonalIdentificationApi error: $e\n$s');
      ridersOnboardingPersonalIdentificationResponse.value =
          ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderPersonalIdentificationLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // Aadhaar OKYC (OTP) identity verification
  // Flow: checkAadhaarStatus() → generateAadhaarOtp() → verifyAadhaarOtp().
  // On a successful verify the entered Aadhaar number is also written to the
  // rider onboarding step so the delivery-partner "aadhar" gate is satisfied.
  // See docs/backend/aadhaar-verification-ui-integration.md.
  // ══════════════════════════════════════════════════════════════════
  final Rx<AadhaarStage> aadhaarStage = AadhaarStage.entry.obs;
  final RxBool isAadhaarStatusLoading = false.obs;
  final RxBool isAadhaarOtpSending = false.obs;
  final RxBool isAadhaarOtpVerifying = false.obs;

  /// True while the "verify by image" path (alternative to OTP) is uploading
  /// the Aadhaar front/back images and submitting them.
  final RxBool isAadhaarImageSubmitting = false.obs;

  /// Mandatory consent — must be explicitly ticked (never pre-ticked) before
  /// an OTP can be generated.
  final RxBool aadhaarConsentGiven = false.obs;

  /// reference_id returned by generate-otp; sent back with the OTP on verify.
  String aadhaarReferenceId = '';
  final aadhaarOtpController = TextEditingController();

  /// Verified identity, populated from status / verify-otp responses.
  final RxBool aadhaarIsVerified = false.obs;
  final RxnString aadhaarVerifiedName = RxnString();

  /// Masked number for display — "XXXX XXXX <last4>".
  final RxnString aadhaarMaskedNumber = RxnString();
  final RxnString aadhaarVerifiedAt = RxnString();

  /// Resend cooldown (seconds remaining). Resend is disabled while > 0.
  final RxInt aadhaarResendSeconds = 0.obs;
  Timer? _aadhaarResendTimer;

  static const int _aadhaarResendCooldown = 45; // 30–60 s window per guide.

  String _formatMaskedFromLast4(String? last4) =>
      (last4 == null || last4.isEmpty) ? '' : 'XXXX XXXX $last4';

  /// Resets the OKYC flow to a clean state and fetches the current status.
  /// Call whenever the bottom sheet opens.
  Future<void> initAadhaarFlow() async {
    _aadhaarResendTimer?.cancel();
    aadhaarResendSeconds.value = 0;
    aadhaarOtpController.clear();
    aadhaarReferenceId = '';
    aadhaarConsentGiven.value = false;
    // Clear any Aadhaar images picked in a previous open of the "by image" path.
    aadharFrontImage.value = null;
    aadharBackImage.value = null;
    aadhaarIsVerified.value = false;
    aadhaarVerifiedName.value = null;
    aadhaarMaskedNumber.value = null;
    aadhaarVerifiedAt.value = null;
    aadhaarStage.value = AadhaarStage.entry;
    await checkAadhaarStatus();
  }

  /// Cancels the resend timer — call from the sheet's dispose.
  void disposeAadhaarFlow() {
    _aadhaarResendTimer?.cancel();
  }

  void _startAadhaarResendCooldown() {
    _aadhaarResendTimer?.cancel();
    aadhaarResendSeconds.value = _aadhaarResendCooldown;
    _aadhaarResendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (aadhaarResendSeconds.value <= 1) {
        aadhaarResendSeconds.value = 0;
        t.cancel();
      } else {
        aadhaarResendSeconds.value--;
      }
    });
  }

  /// GET /user/aadhaar/status — decides whether to show the verified state or
  /// the entry form. An in-progress OTP attempt is treated as not verified.
  Future<void> checkAadhaarStatus() async {
    try {
      isAadhaarStatusLoading.value = true;
      final response = await DeliveryPartnerRepo().aadhaarStatusRepo();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        final status =
            AadhaarStatusData.fromJson(Map<String, dynamic>.from(data));
        if (status.isVerified) {
          aadhaarIsVerified.value = true;
          aadhaarVerifiedName.value = status.name;
          aadhaarMaskedNumber.value = _formatMaskedFromLast4(status.aadhaarLast4);
          aadhaarVerifiedAt.value = status.verifiedAt;
          aadhaarStage.value = AadhaarStage.verified;
        } else {
          aadhaarStage.value = AadhaarStage.entry;
        }
      }
    } catch (e) {
      // Non-fatal: fall back to the entry form so the user can still verify.
      debugPrint('❌ checkAadhaarStatus error: $e');
    } finally {
      isAadhaarStatusLoading.value = false;
    }
  }

  /// POST /user/aadhaar/generate-otp — sends an OTP to the Aadhaar-linked
  /// mobile. Requires a valid 12-digit number and the consent checkbox ticked.
  Future<void> generateAadhaarOtp() async {
    // Text validation (12-digit Aadhaar).
    if (!(aadharFormKey.currentState?.validate() ?? false)) return;

    if (!aadhaarConsentGiven.value) {
      commonSnackBar(
          message:
              'Please tick the consent checkbox to verify your Aadhaar.');
      return;
    }

    final aadhaar = aadharController.text.replaceAll(RegExp(r'\s+'), '');

    try {
      isAadhaarOtpSending.value = true;
      final response = await DeliveryPartnerRepo().aadhaarGenerateOtpRepo(
        params: {
          ApiKeys.aadhaarNumber: aadhaar,
          ApiKeys.consent: 'Y',
          ApiKeys.reason: 'For KYC',
        },
      );

      final body = response.response?.data;
      final isBusinessOk = body is Map && body['success'] == true;

      if (response.isSuccess && isBusinessOk) {
        final data = body['data'];
        aadhaarReferenceId =
            (data is Map ? data['reference_id']?.toString() : null) ?? '';
        aadhaarOtpController.clear();
        aadhaarStage.value = AadhaarStage.otp;
        _startAadhaarResendCooldown();
        commonSnackBar(
            message: (body['message']?.toString().isNotEmpty ?? false)
                ? body['message'].toString()
                : 'OTP sent to your Aadhaar-linked mobile number');
      } else {
        // 200-with-success:false (e.g. "Invalid Aadhaar Card", "Please retry
        // after 30 seconds") or a real error status.
        //
        // Go to the OTP screen ANYWAY. Two reasons:
        //   1. The provider's most common refusal — "Please retry after 30
        //      seconds" — is a rate limit, which means an OTP was just sent.
        //      Holding the rider on the number form strands someone who is
        //      holding a working code.
        //   2. That screen is also where the Aadhaar PHOTO path lives (front +
        //      back upload, under the "if the OTP isn't coming through" note),
        //      so a rider whose OTP never arrives still has a way to finish
        //      verification instead of a dead end.
        //
        // Nothing is faked: aadhaarReferenceId keeps whatever an earlier
        // successful send returned and is not invented here.
        aadhaarOtpController.clear();
        aadhaarStage.value = AadhaarStage.otp;
        // Respects the provider's own back-off — Resend unlocks after the
        // cooldown instead of letting the rider hammer a rate-limited endpoint.
        _startAadhaarResendCooldown();
        final msg = (body is Map ? body['message']?.toString() : null) ??
            response.message ??
            AppStrings.somethingWentWrong;
        commonSnackBar(message: msg);
      }
    } catch (e, s) {
      debugPrint('❌ generateAadhaarOtp error: $e\n$s');
      // A thrown request tells us nothing about whether the provider sent an
      // OTP, so let the rider try a code — or the photo path — either way.
      aadhaarOtpController.clear();
      aadhaarStage.value = AadhaarStage.otp;
      _startAadhaarResendCooldown();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isAadhaarOtpSending.value = false;
    }
  }

  /// POST /user/aadhaar/verify-otp — verifies the 6-digit OTP. On success the
  /// entered number is written to the rider onboarding step and the sheet is
  /// closed (via [checkStatusManageRoute]).
  Future<void> verifyAadhaarOtp() async {
    if (aadhaarReferenceId.isEmpty) {
      // Reachable by design now: a failed generate-otp still lands the rider
      // here. Keep them on this screen — Resend and the Aadhaar photo upload
      // are both on it, and throwing someone back to the number form after
      // they have typed a code is the worse half of the trade.
      commonSnackBar(
          message: 'No OTP request is active. Tap Resend, or verify with your '
              'Aadhaar photos below.');
      return;
    }
    if (aadhaarOtpController.text.trim().length != 6) {
      commonSnackBar(message: 'Please enter the 6-digit OTP.');
      return;
    }

    try {
      isAadhaarOtpVerifying.value = true;
      final response = await DeliveryPartnerRepo().aadhaarVerifyOtpRepo(
        params: {
          ApiKeys.referenceId: aadhaarReferenceId,
          ApiKeys.otp: aadhaarOtpController.text.trim(),
        },
      );

      final body = response.response?.data;
      final verified = body is Map &&
          body['success'] == true &&
          body['is_verified'] == true;

      if (response.isSuccess && verified) {
        _aadhaarResendTimer?.cancel();
        final data = body['data'];
        final identity = data is Map
            ? AadhaarVerifiedIdentity.fromJson(Map<String, dynamic>.from(data))
            : null;
        aadhaarIsVerified.value = true;
        aadhaarVerifiedName.value = identity?.name;
        aadhaarMaskedNumber.value =
            _formatMaskedFromLast4(identity?.aadhaarLast4);
        aadhaarVerifiedAt.value = DateTime.now().toIso8601String();
        aadhaarStage.value = AadhaarStage.verified;
        commonSnackBar(
            message: (body['message']?.toString().isNotEmpty ?? false)
                ? body['message'].toString()
                : 'Aadhaar verified successfully');

        // Bridge the verified identity into the rider onboarding step so the
        // delivery-partner "aadhar" gate is completed.
        await _submitRiderAadhaarStep(
            aadharController.text.replaceAll(RegExp(r'\s+'), ''));
      } else {
        // "Invalid OTP" / "OTP expired" / "No pending OTP request found" etc.
        final msg = (body is Map ? body['message']?.toString() : null) ??
            response.message ??
            AppStrings.somethingWentWrong;
        commonSnackBar(message: msg);
      }
    } catch (e, s) {
      debugPrint('❌ verifyAadhaarOtp error: $e\n$s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isAadhaarOtpVerifying.value = false;
    }
  }

  /// Go back from the OTP stage to the Aadhaar entry stage (edit number).
  void editAadhaarNumber() {
    _aadhaarResendTimer?.cancel();
    aadhaarResendSeconds.value = 0;
    aadhaarOtpController.clear();
    aadhaarStage.value = AadhaarStage.entry;
  }

  /// Alternative to the OTP flow: submit the Aadhaar number together with the
  /// card images (the "verify by image" option). Mirrors the old image-based
  /// identification payload — uploads the images to S3 and POSTs
  /// `{ aadharNo, aadharImages: { front, back? } }` to the same personal-
  /// identification endpoint the number-only path uses. Shown when OTP isn't
  /// working for the rider. Only the front is required — the number lives on
  /// that side, so the back is optional and simply omitted when not picked.
  /// On success the sheet closes and the onboarding status refreshes so the
  /// "aadhar" step reflects the submission.
  Future<void> submitAadhaarImages() async {
    // This runs from the OTP screen, where the entry-stage Form is no longer
    // mounted (so aadharFormKey.currentState is null). Validate the already-
    // entered number directly instead of via the form key.
    final aadhaar = aadharController.text.replaceAll(RegExp(r'\s+'), '');
    if (aadhaar.length != 12) {
      commonSnackBar(message: 'Please enter a valid 12-digit Aadhaar number.');
      return;
    }
    final front = aadharFrontImage.value;
    if (front == null) {
      commonSnackBar(message: 'Please select the Aadhaar front image.');
      return;
    }
    // Optional — the Aadhaar number is printed on the front, so the back adds
    // nothing the verifier needs.
    final back = aadharBackImage.value;
    try {
      isAadhaarImageSubmitting.value = true;

      // Gate the upload on the AI document check: the images must actually be
      // an Aadhaar card and carry the number typed above. Anything short of a
      // clean pass (type mismatch, unreadable/mismatched number, is_verified
      // false, or a check that couldn't complete) stops here — nothing reaches
      // S3 or the onboarding endpoint.
      final verification = await AiDocumentVerificationService().verify(
        documentName: AiDocumentVerificationService.aadhaar,
        documentNumber: aadhaar,
        images: [front, if (back != null) back],
      );
      if (!verification.isValid) {
        commonSnackBar(message: verification.failureMessage!);
        return;
      }

      final frontUrl = await _uploadToS3(front);
      final backUrl = back != null ? await _uploadToS3(back) : null;
      // A picked back image that fails to upload is still an error — only a
      // back that was never picked is allowed to be absent.
      if ((frontUrl ?? '').isEmpty ||
          (back != null && (backUrl ?? '').isEmpty)) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }
      final params = {
        ApiKeys.aadharNo: aadhaar,
        ApiKeys.aadharImages: {
          ApiKeys.front: frontUrl,
          if (backUrl != null) ApiKeys.back: backUrl,
        },
      };
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingPersonalIdentificationRepo(params: params);
      if (response.isSuccess) {
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.complete(response);
        // Show the SAME success/verified state the OTP path lands on, rather
        // than closing the sheet. The image submission carries no OKYC name, so
        // we surface the masked number from the entered Aadhaar for the row.
        aadhaarIsVerified.value = true;
        aadhaarMaskedNumber.value = _formatMaskedFromLast4(aadhaar.substring(8));
        aadhaarVerifiedAt.value = DateTime.now().toIso8601String();
        aadhaarStage.value = AadhaarStage.verified;
        commonSnackBar(
            message: response.message ?? 'Aadhaar submitted successfully');
        await ridersOnboardingStatusRepoApi(forceRefresh: true);
      } else {
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      debugPrint('❌ submitAadhaarImages error: $e\n$s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isAadhaarImageSubmitting.value = false;
    }
  }

  /// Writes the verified Aadhaar number to the rider onboarding step and
  /// resolves the sheet/route the same way the other document steps do.
  Future<void> _submitRiderAadhaarStep(String aadharNumber) async {
    try {
      isRiderPersonalIdentificationLoading.value = true;
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingPersonalIdentificationRepo(
              params: {ApiKeys.aadharNo: aadharNumber});
      if (response.isSuccess) {
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.complete(response);
      } else {
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
      checkStatusManageRoute();
    } catch (e, s) {
      debugPrint('❌ _submitRiderAadhaarStep error: $e\n$s');
      ridersOnboardingPersonalIdentificationResponse.value =
          ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderPersonalIdentificationLoading.value = false;
    }
  }

  RxBool isRiderDrivingVerificationLoading = false.obs;

  /// ridersOnboardingDrivingVerificationApi (Step 4)
  Future<void> ridersDrivingLicenceVerificationApi() async {
    // ---------- 1️⃣ TEXT VALIDATION ----------
    if (!(dlFormKey.currentState?.validate() ?? false)) return;

    try {
      isRiderDrivingVerificationLoading.value = true;

      // ---------- 2️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.dlNo: drivingLicenseController.text,
      };

      // ---------- 3️⃣ CALL API ----------
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingDrivingVerificationRepo(params: params);

      // ---------- 7️⃣ HANDLE RESPONSE ----------
      if (response.isSuccess) {
        ridersOnboardingDrivingVerificationResponse.value =
            ApiResponse.complete(response);
        Get.back();
      } else {
        ridersOnboardingDrivingVerificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
      checkStatusManageRoute();
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingDrivingVerificationApi error: $e\n$s');
      ridersOnboardingDrivingVerificationResponse.value =
          ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderDrivingVerificationLoading.value = false;
    }
  }

  Future<void> ridersRcBookVerificationApi() async {
    // ---------- 1️⃣ TEXT VALIDATION ----------
    if (!(rcFormKey.currentState?.validate() ?? false)) return;

    try {
      isRiderDrivingVerificationLoading.value = true;

      // ---------- 2️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.rcNo: rcController.text,
      };

      // ---------- 3️⃣ CALL API ----------
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingDrivingVerificationRepo(params: params);

      // ---------- 7️⃣ HANDLE RESPONSE ----------
      if (response.isSuccess) {
        ridersOnboardingDrivingVerificationResponse.value =
            ApiResponse.complete(response);
        Get.back();
      } else {
        ridersOnboardingDrivingVerificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
      checkStatusManageRoute();
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingDrivingVerificationApi error: $e\n$s');
      ridersOnboardingDrivingVerificationResponse.value =
          ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderDrivingVerificationLoading.value = false;
    }
  }

  Future<void> ridersOnboardingDrivingVerificationApi() async {
    if (formKeyStep4.currentState!.validate()) {
      // ---------- 1️⃣ VALIDATION ----------
      if (rcFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectRcFrontImage.tr);
        return;
      }
      if (rcBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectRcBackImage.tr);
        return;
      }
      if (drivingLicenseFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectDlFrontImage.tr);
        return;
      }
      if (drivingLicenseBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectDlBackImage.tr);
        return;
      }

      try {
        isRiderDrivingVerificationLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        String? rcFrontImageUrl;
        String? rcBackImageUrl;
        String? drivingLicenseFrontImageUrl;
        String? drivingLicenseBackImageUrl;

        // ---------- 3️⃣ UPLOAD RC IMAGES ----------
        rcFrontImageUrl = await _uploadToS3(rcFrontImage.value!);
        rcBackImageUrl = await _uploadToS3(rcBackImage.value!);

        // ---------- 4️⃣ UPLOAD DRIVING LICENSE IMAGES ----------
        drivingLicenseFrontImageUrl =
            await _uploadToS3(drivingLicenseFrontImage.value!);
        drivingLicenseBackImageUrl =
            await _uploadToS3(drivingLicenseBackImage.value!);

        // ---------- 5️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.rcNo: rcController.text,
          ApiKeys.dlNo: drivingLicenseController.text,
          ApiKeys.rcImages: {
            ApiKeys.front: rcFrontImageUrl,
            ApiKeys.back: rcBackImageUrl,
          },
          ApiKeys.dlImages: {
            ApiKeys.front: drivingLicenseFrontImageUrl,
            ApiKeys.back: drivingLicenseBackImageUrl,
          },
        };

        // ---------- 6️⃣ CALL API ----------
        final response = await DeliveryPartnerRepo()
            .ridersOnboardingDrivingVerificationRepo(params: params);

        // ---------- 7️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          ridersOnboardingDrivingVerificationResponse.value =
              ApiResponse.complete(response);
          // Get.toNamed(RouteHelper.getVehicleImagesRidingScreenRoute());
        } else {
          ridersOnboardingDrivingVerificationResponse.value =
              ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
      } catch (e, s) {
        debugPrint('❌ ridersOnboardingDrivingVerificationApi error: $e\n$s');
        ridersOnboardingDrivingVerificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isRiderDrivingVerificationLoading.value = false;
      }
    }
  }

  RxBool isRiderVehicleImagesLoading = false.obs;

  /// ridersOnboardingVehicleImagesApi (Step 5)
  Future<void> ridersOnboardingVehicleImagesApi() async {
    // ---------- 1️⃣ VALIDATION ----------
    if (vehicleNumberPlateImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectNumberPlateImage.tr);
      return;
    }

    if (vehicleRightSideImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectRightSideImages.tr);
      return;
    }

    // if (vehicleLeftSideImages.isEmpty) {
    //   commonSnackBar(message: AppStrings.pleaseSelectLeftSideImages.tr);
    //   return;
    // }

    if (vehicleFrontImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectFrontImage.tr);
      return;
    }

    if (vehicleBackImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectBackImage.tr);
      return;
    }

    try {
      isRiderVehicleImagesLoading.value = true;

      // ---------- 2️⃣ INITIALIZE ----------
      List<String> vehicleNumberPlateImageUrls = [];
      List<String> vehicleRightSideImageUrls = [];
      List<String> vehicleLeftSideImageUrls = [];
      List<String> vehicleFrontImageUrls = [];
      List<String> vehicleBackImageUrls = [];

      // ---------- 3️⃣ UPLOAD NUMBER PLATE IMAGES ----------
      for (final photo in vehicleNumberPlateImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleNumberPlateImageUrls.add(fileUrl);
        }
      }

      // ---------- 4️⃣ UPLOAD RIGHT SIDE IMAGES ----------
      for (final photo in vehicleRightSideImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleRightSideImageUrls.add(fileUrl);
        }
      }

      // ---------- 5️⃣ UPLOAD LEFT SIDE IMAGES ----------
      for (final photo in vehicleLeftSideImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleLeftSideImageUrls.add(fileUrl);
        }
      }

      // ---------- 6️⃣ UPLOAD FRONT IMAGES ----------
      for (final photo in vehicleFrontImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleFrontImageUrls.add(fileUrl);
        }
      }

      // ---------- 7️⃣ UPLOAD BACK IMAGES ----------
      for (final photo in vehicleBackImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleBackImageUrls.add(fileUrl);
        }
      }

      // ---------- 8️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.vehicleNoPlateImg: vehicleNumberPlateImageUrls.first,
        ApiKeys.vehicleRightHandSideImage: vehicleRightSideImageUrls,
        ApiKeys.vehicleLeftSideImage: vehicleLeftSideImageUrls,
        ApiKeys.vehicleFrontImage: vehicleFrontImageUrls.first,
        ApiKeys.vehicleBackImage: vehicleBackImageUrls.first,
      };

      // ---------- 9️⃣ API CALL ----------
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingVehicleImagesRepo(params: params);

      // ---------- 🔟 HANDLE RESPONSE ----------
      if (response.isSuccess) {
        ridersOnboardingVehicleImagesResponse.value =
            ApiResponse.complete(response);
        checkStatusManageRoute();
        // Get.toNamed(RouteHelper.getVehicleInformationRidingScreenRoute());
      } else {
        ridersOnboardingVehicleImagesResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingVehicleImagesApi error: $e\n$s');
      ridersOnboardingVehicleImagesResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isRiderVehicleImagesLoading.value = false;
    }
  }

  RxBool isRiderVehicleInformationLoading = false.obs;

  // ─── Rider service preference (vehicleUsesType) ──────────────────
  // Updates ONLY the rider's service preference — the field the
  // nearby-rider filter keys off (see docs/backend/RIDER_PREFERENCE_FILTER.md).
  // Reuses the vehicle-information PUT endpoint with a partial body so an
  // already-onboarded rider can switch what they deliver without re-entering
  // the rest of their vehicle details. Returns true on success.
  RxBool isRiderPreferenceUpdating = false.obs;

  Future<bool> updateRiderServicePreference(String vehicleUsesType) async {
    if (vehicleUsesType.trim().isEmpty) return false;
    try {
      isRiderPreferenceUpdating.value = true;
      final response =
          await DeliveryPartnerRepo().ridersOnboardingVehicleInformationRepo(
        params: {ApiKeys.vehicleUsesType: vehicleUsesType},
      );
      if (response.isSuccess) {
        // Refresh status so the saved preference is reflected everywhere
        // (and the Set Preference card stays in sync after a relaunch).
        await ridersOnboardingStatusRepoApi(forceRefresh: true);
        return true;
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isRiderPreferenceUpdating.value = false;
    }
  }

  // ─── En-route route (pickup→drop corridor) ───────────────────────
  // Declares the rider's fixed pickup→drop path so any open order whose
  // pickup AND drop both fall within [radiusKm] of the corridor becomes
  // claimable. Creating a route supersedes the previous active one (one
  // at a time). See docs/backend/RIDER_ROUTE_ENROUTE_ORDERS_FRONTEND_GUIDE.md.
  RxBool isRiderRouteSubmitting = false.obs;

  Future<bool> createRiderRoute({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    double radiusKm = 1,
    int expiresInMinutes = 240,
  }) async {
    try {
      isRiderRouteSubmitting.value = true;
      final params = <String, dynamic>{
        'pickup': {
          ApiKeys.latitude: pickupLat,
          ApiKeys.longitude: pickupLng,
          ApiKeys.address: pickupAddress,
        },
        'drop': {
          ApiKeys.latitude: dropLat,
          ApiKeys.longitude: dropLng,
          ApiKeys.address: dropAddress,
        },
        // No road polyline available here — omit `path` so the backend
        // falls back to a straight pickup→drop corridor.
        'radiusKm': radiusKm,
        'expiresInMinutes': expiresInMinutes,
      };
      final response =
          await DeliveryPartnerRepo().createRiderRouteRepo(params: params);
      if (response.isSuccess) {
        return true;
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isRiderRouteSubmitting.value = false;
    }
  }

  Future<void> addLivePhoto() async {
    final selectedPath = await PhotoPickerService.pickFromCamera(
        Get.context!,
        cropAspectRatio: CropAspectRatio(width: 3, height: 4));
    if (selectedPath != null) {
      livePhoto.add(File(selectedPath));
    }
    update([livePhotoImageId]);
  }

  Future<void> removeLivePhoto(int index) async {
    livePhoto.removeAt(index);
    update([livePhotoImageId]);
  }

  RxBool isVehicleDataEnumLoading = false.obs;
  VehicleEnumResponse? vehicleEnumResponse;

  // "twoWheelerRider",
  // "autoTempo",
  // "eRickshaw",
  // "carMini",
  // "carSedan",
  // "suvCar",
  // "miniBus",
  // "pickupGoods",
  // "miniTruckGoods",
  // "largeTruckGoods"

  /// Fetches the vehicle enums. [type] = the rider's profession; when supplied
  /// the backend returns only the options valid for that profession (the app no
  /// longer filters locally). Omit [type] for the full catalog (rental flow).
  Future<void> fetchVehicleDataEnum({String? type}) async {
    try {
      isVehicleDataEnumLoading.value = true;

      final response =
          await DeliveryPartnerRepo().fetchVehicleDataEnumRepo(type: type);

      if (response.isSuccess) {
        vehicleDataResponse.value = ApiResponse.complete(response);
        vehicleEnumResponse =
            VehicleEnumResponse.fromJson(response.response?.data);
        // Auto-select any filtered dropdown that has just one valid option for
        // this profession (e.g. a two-wheeler for a BIKE_RIDER) — nothing to
        // choose, so the dropdown never has to be touched.
        _autoSelectSingleVehicleOptions();
      } else {
        vehicleDataResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      vehicleDataResponse.value = ApiResponse.error('error');
    } finally {
      isVehicleDataEnumLoading.value = false;
    }
  }

  /// Pre-selects any of the three dropdowns that collapse to a single option
  /// for the signed-in rider's profession (nothing left to choose). The lists
  /// are now filtered server-side by the `?type=` query param, so this works
  /// purely off list length. Only fills a slot that's still empty, so it never
  /// clobbers a value hydrated from an existing vehicle.
  void _autoSelectSingleVehicleOptions() {
    final types = vehicleEnumResponse?.vehicleType ?? [];
    if (types.length == 1 && selectedVehicleType.value == null) {
      selectedVehicleType.value = types.first;
    }

    final uses = vehicleEnumResponse?.vehicleUsesType ?? [];
    if (uses.length == 1 && selectedVehicleUseType.value == null) {
      selectedVehicleUseType.value = uses.first;
    }

    final regs = vehicleEnumResponse?.registrationType ?? [];
    if (regs.length == 1 && selectedVehicleRegistrationType.value == null) {
      selectedVehicleRegistrationType.value = regs.first;
    }
  }

  checkStatusManageRoute() async {
    await ridersOnboardingStatusRepoApi(forceRefresh: true);
    // Use the profession-aware gate: PAN is not mandatory for bike riders /
    // cab drivers, and vehicle images are always optional.
    final allCompleted = mandatoryStepsCompleted;
    if (allCompleted) {
      final viewProfileController = Get.find<ViewPersonalDetailsController>();
      viewProfileController.viewPersonalProfile(forceRefresh: true);
      Get.offNamedUntil(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        (route) => false,
      );
      // Get.until((route) =>
      // route.settings.name ==
      //     RouteHelper.getBottomNavigationBarScreenRoute());
    } else {
      Get.back();
    }
  }

  RxBool isNearByRidersLoading = false.obs;
  RxList<Riders> arrRiders = <Riders>[].obs;

  Future<void> fetchNearByRidersApi() async {
    try {
      isNearByRidersLoading.value = true;

      double lat = LocationService.lat;
      double lng = LocationService.lng;

      Map<String, dynamic> queryParams = {
        // ApiKeys.latitude: 21.819289,
        // ApiKeys.longitude: 80.179749,
        ApiKeys.latitude: lat,
        ApiKeys.longitude: lng,
        ApiKeys.range_in_km: kmRadius5000,
      };

      final response =
          await GroceryRepo().fetchNearByRidersRepo(queryParams: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      nearByRidersResponse.value = ApiResponse.complete(response);

      final data = response.response?.data;

      GetBlueeraPiolotModel getBlueeraPiolotModel =
          GetBlueeraPiolotModel.fromJson(data);
      arrRiders.value = getBlueeraPiolotModel.users ?? [];

      update();
    } catch (e, s) {
      nearByRidersResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      isNearByRidersLoading.value = false;
    }
  }

  // ─── Associated Shops API ────────────────────────────────────

  Future<void> getAssociatedShops({
    String filter = 'all',
    bool isLoadMore = false,
  }) async {
    if (isLoadMore && !_hasMoreAssociatedShops) return;

    if (!isLoadMore) {
      _associatedShopsPage = 1;
      _hasMoreAssociatedShops = true;
      isAssociatedShopsLoading.value = true;
    }

    try {
      final params = <String, dynamic>{
        'filter': filter,
        'page': _associatedShopsPage,
        'limit': 10,
        'latitude': LocationService.lat,
        'longitude': LocationService.lng,
      };

      final response =
          await DeliveryPartnerRepo().getAssociatedShopsRepo(params: params);

      if (response.isSuccess) {
        final data = response.response?.data;
        final parsed = AssociatedShopsResponse.fromJson(data);

        if (!isLoadMore) {
          associatedShops.clear();
        }

        associatedShops.addAll(parsed.shops ?? []);
        associatedShopsData.value = parsed;

        final pagination = parsed.pagination;
        if (pagination != null &&
            pagination.page != null &&
            pagination.totalPages != null) {
          _hasMoreAssociatedShops =
              pagination.page! < pagination.totalPages!;
          if (_hasMoreAssociatedShops) _associatedShopsPage++;
        } else {
          _hasMoreAssociatedShops = false;
        }

        associatedShopsResponse.value = ApiResponse.complete(data);
      } else {
        if (!isLoadMore) {
          associatedShopsResponse.value =
              ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e, s) {
      log('getAssociatedShops error: $e\n$s');
      if (!isLoadMore) {
        associatedShopsResponse.value = ApiResponse.error('error');
      }
    } finally {
      isAssociatedShopsLoading.value = false;
    }
  }

  // ─── Send Association Request API ─────────────────────────────

  /// Track which store userIds have pending/sent requests to avoid duplicate taps
  final RxSet<String> pendingRequestUserIds = <String>{}.obs;

  Future<void> sendAssociationRequest({required String targetUserId}) async {
    if (pendingRequestUserIds.contains(targetUserId)) return;

    pendingRequestUserIds.add(targetUserId);
    try {
      final response = await DeliveryPartnerRepo()
          .sendAssociationRequestRepo(targetUserId: targetUserId);

      if (response.isSuccess) {
        commonSnackBar(message: 'Request sent successfully!');
      } else {
        final data = response.response?.data;
        final msg = (data is Map) ? data['message'] : null;
        commonSnackBar(message: msg ?? 'Failed to send request');
        pendingRequestUserIds.remove(targetUserId);
      }
    } catch (e) {
      log('sendAssociationRequest error: $e');
      commonSnackBar(message: 'Something went wrong. Try again.');
      pendingRequestUserIds.remove(targetUserId);
    }
  }
}
