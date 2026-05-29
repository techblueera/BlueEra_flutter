import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/service/model/add_service_response_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/earn_service_model_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/predefined_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/earn_service_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/self_profession_desc_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/apiService/api_keys.dart';

class SelfWorkServiceController extends GetxController{
  Rx<ApiResponse> predefinedCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response =
  ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> serviceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> updateServiceResponse =
      ApiResponse.initial('Initial').obs;

  String? professionCategory;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- Service images ---
  final RxList<String> selectedImages = <String>[].obs;

  // --- Dropdown State ---
  // 1. Years List (1 Year to 9 Years, then 10+ Years)
  final List<String> experienceYears = [
    "1 Year",
    "2 Years",
    "3 Years",
    "4 Years",
    "5 Years",
    "6 Years",
    "7 Years",
    "8 Years",
    "9 Years",
    "10+ Years"
  ];

   // 2. Months List (1 Month to 12 Months)
  final List<String> experienceMonths = [
    "1 Month",
    "2 Months",
    "3 Months",
    "4 Months",
    "5 Months",
    "6 Months",
    "7 Months",
    "8 Months",
    "9 Months",
    "10 Months",
    "11 Months",
    "12 Months"
  ];

  final selectedExperienceYear = Rxn<String>();
  final selectedExperienceMonth = Rxn<String>();
  final serviceTypes = <String>[].obs;
  RxList<String> selectedServiceTypes = <String>[].obs;


  final RxList<String> serviceOptions = <String>[].obs;
  final RxList<String> installationOptions = <String>[].obs;
  final RxList<String> expertiseOptions = <String>[].obs;
  final RxList<String> workCategoryOptions = <String>[].obs;
  final RxList<String> whyChooseMeOptions = <String>[].obs;

  var selectedServices = <String>[].obs;
  var selectedInstallations = <String>[].obs;
  var selectedExpertise = <String>[].obs;
  var selectedWorkCategories = <String>[].obs;
  var selectedWhyChooseMe = <String>[].obs;

  static const String keyServiceTypes = "serviceTypes";
  static const String keyServicesOffered = "servicesOffered";
  static const String keyTypeOfWork = "typesOfWork";
  static const String keyExpertise = "expertise";
  static const String keyWorkCategories = "workCategories";
  static const String keyWhyChooseMe = "whyChooseMe";

  Map<String, RxList<String>> get allCategoryMap => {
    keyServicesOffered: serviceOptions,
    keyTypeOfWork: installationOptions,
    keyExpertise: expertiseOptions,
    keyWorkCategories: workCategoryOptions,
    keyWhyChooseMe: whyChooseMeOptions,
  };

  Map<String, RxList<String>> get selectedCategoryMap => {
    keyServicesOffered: selectedServices,
    keyTypeOfWork: selectedInstallations,
    keyExpertise: selectedExpertise,
    keyWorkCategories: selectedWorkCategories,
    keyWhyChooseMe: selectedWhyChooseMe,
  };

  Map<String, String> get categoryTitleMap => {
    keyServicesOffered: AppStrings.servicesOffered.tr,
    keyTypeOfWork: AppStrings.typesOfInstallations.tr,
    keyExpertise: AppStrings.expertise.tr,
    keyWorkCategories: AppStrings.workCategories.tr,
    keyWhyChooseMe: AppStrings.whyChooseMe.tr,
  };

  void updateSelection(String key, List<String> newItems) {
    if (selectedCategoryMap.containsKey(key)) {
      selectedCategoryMap[key]!.assignAll(newItems);
    }
  }

  // --- About Section ---
  final TextEditingController aboutController = TextEditingController();

  // --- Price / Fee Section ---
  // Owned by the controller (not the booking controller) so the
  // earn-service screen has a single source of truth for the user's
  // fee inputs. Seeded from [professionData.feeDetails] every time
  // [fetchSelfProfessionData] succeeds, and re-seeded on each price
  // sheet open via [seedPriceInputsFromProfession] so abandoned edits
  // don't bleed into the next session.
  final TextEditingController minFeeController = TextEditingController();
  final TextEditingController maxFeeController = TextEditingController();
  final TextEditingController feeTypeController = TextEditingController();

  /// Self Profession Data
  Rx<EarnServiceModelResponse> professionData = EarnServiceModelResponse().obs;
  RxBool isProfessionDataLoading = false.obs;
  String? serviceId;

  /// Multi-profile support
  RxInt selectedProfileIndex = 0.obs;

  void switchProfile(int index) {
    selectedProfileIndex.value = index;
  }

  RxBool isPredefinedCategoryServiceTypeLoading = false.obs;
  Future<void> fetchPredefinedCategoryServiceType({
    required String professionCategory,
    required String selectedServiceKey}) async {
    try {
      isPredefinedCategoryServiceTypeLoading.value = true;

      final response = await EarnServiceRepo().predefinedServiceCategoryRepo(
        professionCategory: professionCategory,
        queryParams: {
          ApiKeys.segment : selectedServiceKey,
        },
      );

      if (response.isSuccess) {
        predefinedCategoryResponse.value = ApiResponse.complete(response);
        final predefinedCategoryModel = PredefinedCategoryModel.fromJson(response.response?.data);
        serviceTypes.value = predefinedCategoryModel.items ?? [];
      } else {
        predefinedCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      predefinedCategoryResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isPredefinedCategoryServiceTypeLoading.value = false;
    }
  }

  RxBool isServiceSelectionLoading = false.obs;
  Future<void> fetchServiceSelectionOptions({
  required String professionCategory,
  required String selectedServiceKey}) async {
    try {
      isServiceSelectionLoading.value = true;

      final response = await EarnServiceRepo().predefinedServiceCategoryRepo(
        professionCategory: professionCategory,
        queryParams: {
          ApiKeys.segment : selectedServiceKey,
        },
      );

      if (response.isSuccess) {
        predefinedCategoryResponse.value = ApiResponse.complete(response);
        final predefinedCategoryModel = PredefinedCategoryModel.fromJson(response.response?.data);
        List<String> newItems = predefinedCategoryModel.items ?? [];

        RxList<String>? targetList = allCategoryMap[selectedServiceKey];

        if (targetList != null) {
          targetList.assignAll(newItems);

          // Log for verification
          log("Updated $selectedServiceKey with ${targetList.length} items");
        } else {
          log("Error: No list found for key $selectedServiceKey");
        }

      } else {
        predefinedCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      predefinedCategoryResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isServiceSelectionLoading.value = false;
    }
  }

  RxBool isCreateServiceLoading = false.obs;

  /// Minimal earn-service creation — posts only the four core fields
  /// so a placeholder row exists in the backend. The user then fills
  /// in the rest (price, service type, description, hours, expertise,
  /// etc.) one by one from the Service tab's section cards.

  Future<void> createMinimalEarnService({
    required String serviceSubType,
    String? professionCategoryOverride,
  }) async {
    try {
      isCreateServiceLoading.value = true;
      final cat = (professionCategoryOverride?.trim().isNotEmpty ?? false)
          ? professionCategoryOverride!
          : (professionCategory ?? ELECTRICIAN);
      final params = <String, dynamic>{
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProviderType.user.title,
        ApiKeys.subType: serviceSubType,
        ApiKeys.category: cat,
      };
      final ResponseModel responseModel =
          await EarnServiceRepo().addServiceRepo(params: params);
      if (responseModel.isSuccess) {
        createServiceResponse.value = ApiResponse.complete(responseModel);
        // Refresh profession data so the Service tab swaps from the
        // empty placeholder to the section cards.
        await fetchSelfProfessionData(isLoading: false);
      } else {
        createServiceResponse.value = ApiResponse.error('error');
        commonSnackBar(message: responseModel.message);
      }
    } catch (e, s) {
      log('createMinimalEarnService stack: $s');
      createServiceResponse.value = ApiResponse.error('error');
    } finally {
      isCreateServiceLoading.value = false;
    }
  }

  /// Create Self Service
  Future<void> createEarnServiceApi({
    required String serviceSubType
  }) async {

    // 1. Validate Form Fields (TextInputs)
    if (!formKey.currentState!.validate()) return;

    // 2. Validate Dropdowns & Single Selections
    if (selectedExperienceYear.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectExperienceYears.tr);
      return;
    }

    if (selectedExperienceMonth.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectExperienceMonths.tr);
      return;
    }

    if (selectedServiceTypes.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectServiceType.tr);
      return;
    }

   // 3. Validate Multi-Selection Lists
    if (selectedServices.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectAtLeastOneServiceOffered.tr);
      return;
    }

    if (selectedInstallations.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseAddTypesOfInstallations.tr);
      return;
    }

    if (selectedExpertise.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseAddYourExpertise.tr);
      return;
    }

    if (selectedWorkCategories.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectWorkCategories.tr);
      return;
    }

    if (selectedWhyChooseMe.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseAddWhyChooseMePoints.tr);
      return;
    }

    try {

      isCreateServiceLoading.value = true;

      Map<String, dynamic> params = {
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProviderType.user.title,
        ApiKeys.subType: serviceSubType,
        ApiKeys.category: professionCategory ?? ELECTRICIAN,
        ApiKeys.serviceType: selectedServiceTypes,
        // ApiKeys.serviceType: selectedServiceTypes,
        ApiKeys.description: aboutController.text.trim(),
        ApiKeys.experience: {
          ApiKeys.years: selectedExperienceYear.value,
          ApiKeys.months:selectedExperienceMonth.value,
        },
       // ApiKeys.priceType: 'range',
       // ApiKeys.min: int.tryParse(minPriceCtrl.text.trim()),
       // ApiKeys.max: int.tryParse(maxPriceCtrl.text.trim()),
      };
      if (selectedServices.isNotEmpty) params[ApiKeys.servicesOffered] = selectedServices;
      if (selectedInstallations.isNotEmpty) params[ApiKeys.typesOfWork] = selectedInstallations;
      if (selectedExpertise.isNotEmpty) params[ApiKeys.expertise] = selectedExpertise;
      if (selectedWorkCategories.isNotEmpty) params[ApiKeys.workCategories] = selectedWorkCategories;
      if (selectedWhyChooseMe.isNotEmpty) params[ApiKeys.whyChooseMe] = selectedWhyChooseMe;

      // Prepare images
      List<UploadS3ImageModel> images = [];
      for (var imagePath in selectedImages) {
        final imageInfo = getFileInfo(File(imagePath));
        if (imageInfo.isNotEmpty) {
          images.add(
            UploadS3ImageModel(
                path: imagePath,
                mimeType: imageInfo['mimeType']!
            ),
          );
        }
      }

      if (images.isNotEmpty) {
        params[ApiKeys.imageContentTypes] =
            images.map((img) => img.mimeType).toList();
      }

      final ResponseModel responseModel = await EarnServiceRepo().addServiceRepo(params: params);


      if (responseModel.isSuccess) {
        createServiceResponse.value = ApiResponse.complete(responseModel);

        // Set preSignedUrls from response
        final addServiceResponseModel = AddServiceResponseModel.fromJson(responseModel.response!.data);
        List<String> preSignedUrlImages =
            addServiceResponseModel.uploadUrls?.images ?? [];

        if (images.length == preSignedUrlImages.length) {
          for (var i = 0; i < images.length; i++) {
            images[i].preSignedUrl = preSignedUrlImages[i];
          }

          // Upload all images with combined progress
          await uploadAllImages(images);
        }

        commonSnackBar(message: AppStrings.serviceAddedSuccess.tr);

        isCreateServiceLoading.value = false;

        // Get.offNamedUntil(
        //   RouteHelper.getAvailabilityScreenRoute(),
        //   arguments: {
        //     ApiKeys.argId: userId
        //   }, // 1. The new page to push
        //   (route) => route.settings.name == RouteHelper.getEarnServiceScreenRoute(),
        // );

        final controller = getOrPut(() => ViewPersonalDetailsController());
        await controller.viewPersonalProfile();

        // Refresh profession data so any open SelfProfessionDetailsScreen
        // rebuilds out of its empty state. Done here (single success path)
        // instead of on every back-pop from the nested selection sheets.
        fetchSelfProfessionData(isLoading: false);

        Get.toNamed(
          RouteHelper.getAvailabilityScreenRoute(),
          arguments: {
            ApiKeys.argId: userId
          },
        );


        // controller.updateUserProfileDetails(params: {
        //   ApiKeys.profession: SELF_EMPLOYED,
        //   ApiKeys.designation: designation,
        // },
        //   isFromProfileOnly: true,
        //   showProgress: false
        // );

      } else {
        isCreateServiceLoading.value = false;
        createServiceResponse.value = ApiResponse.error('error');
        commonSnackBar(message: responseModel.message);
      }
    } catch (e, s) {
      log('stack trace -- $s');
      isCreateServiceLoading.value = false;
      createServiceResponse.value = ApiResponse.error('error');
    } finally {
      // isCreateServiceLoading.value = false;
    }
  }


  /// Update Earn Service Data
    RxBool isUpdateServiceLoading = false.obs;
     Future<void> updateEarnServiceData({
         required Map<String, dynamic> params
  }) async {

    try {

      isUpdateServiceLoading.value = true;

      if(serviceId == null) return;
      final ResponseModel responseModel = await EarnServiceRepo().updateServiceRepo(serviceId: serviceId!, params: params);


      if (responseModel.isSuccess) {
        updateServiceResponse.value = ApiResponse.complete(responseModel);
        Get.back();
        fetchSelfProfessionData(isLoading: false);
      } else {
        updateServiceResponse.value = ApiResponse.error('error');
        commonSnackBar(message: responseModel.message);
      }
    } catch (e, s) {
      log('stack trace -- $s');
      updateServiceResponse.value = ApiResponse.error('error');
    } finally {
      isUpdateServiceLoading.value = false;
    }
  }

  Future<void> uploadAllImages(List<UploadS3ImageModel> images) async {
    if (images.isEmpty) return;

    final totalImages = images.length;

    try {
      for (var i = 0; i < totalImages; i++) {
        final image = images[i];
        final file = File(image.path);
        final fileType = image.mimeType;
        final preSignedUrl = image.preSignedUrl ?? '';

        await uploadFileToS3(
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl,
          onProgress: (progress) {
            final imageFraction = 0.8 / totalImages;
            final overallProgress =
                0.2 + (i * imageFraction) + (progress * imageFraction);

            // UploadProgressDialog.update(overallProgress.clamp(0.0, 1.0));

            debugPrint(
                "Uploading ${file.path}: ${(progress * 100).toStringAsFixed(0)}%, overall: ${(overallProgress * 100).toStringAsFixed(0)}%");
          },
        );
      }
    } catch (e) {
      // UploadProgressDialog.close();
      log('Something went wrong during image upload. $e');
    }
  }

  Future<void> uploadFileToS3({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async
  {
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
            message: response?.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      uploadFileToS3Response.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    }
  }

  RxBool isGenerateDescLoading = false.obs;
  var descriptionSuggestions = <String>[].obs;
  var selectedDescription = "".obs;
  Future<void> generateDescriptions({
    required Map<String, dynamic> bodyRequest,
    VoidCallback? onSaved, // <-- add this callback
  }) async {
    try {
      isGenerateDescLoading.value = true;
      descriptionSuggestions.clear();
      selectedDescription.value = '';

      final ResponseModel response = await EarnServiceRepo()
          .aiGenerateDescriptionRepo(bodyParam: bodyRequest);

      if (response.isSuccess && response.response?.data != null) {
        final rawData = response.response?.data['data']['description_suggestions'];

        if (rawData != null && rawData is List) {
          descriptionSuggestions.value = rawData.map((e) => e.toString()).toList();
        }

        await selfProfessionDescSelectionDialog(onSaved: onSaved);
      } else {
        commonSnackBar(
            message:
            "Error ${response.message ?? AppStrings.somethingWentWrong.tr}");
      }
    } catch (e) {
      logs("ERROR ${e}");
      commonSnackBar(message: e.toString());
    } finally {
      isGenerateDescLoading.value = false;
    }
  }

  Future<void> fetchSelfProfessionData({bool isLoading = true}) async {
    try {
      isProfessionDataLoading.value = isLoading;

      final response = await EarnServiceRepo().fetchProfessionDataRepo(
          {
            ApiKeys.all: false,
          }
      );
      if (response.isSuccess) {
        serviceResponse.value = ApiResponse.complete(response);
        final earnServiceModelResponse = EarnServiceModelResponse.fromJson(response.response?.data);
        professionData.value = earnServiceModelResponse;
        // Mirror the fresh fee/schedule into the local input state so
        // the section card hero + the update sheets render the latest
        // server values without another fetch.
        seedPriceInputsFromProfession();
        syncWorkingHoursFromProfession();
      } else {
        serviceResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      serviceResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isProfessionDataLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // PRICE / WORKING-HOURS STATE HELPERS
  // ─────────────────────────────────────────────

  /// Seed [minFeeController]/[maxFeeController]/[feeTypeController]
  /// from the latest `professionData.feeDetails`. Idempotent — safe
  /// to call on every sheet open so abandoned edits get discarded.
  void seedPriceInputsFromProfession() {
    final fee = professionData.value.feeDetails;
    minFeeController.text = fee?.minFee?.toString() ?? '';
    maxFeeController.text = fee?.maxFee?.toString() ?? '';
    feeTypeController.text = fee?.feeType ?? '';
  }

  /// Push `professionData.schedule` into the shared
  /// [VisitingHoursSelectorController] so the working-hours editor
  /// renders the persisted state. Mirrors the booking flow's
  /// `syncScheduleToController` so existing API day-name handling is
  /// preserved (Mon/Mon./monday all map to "Monday").
  void syncWorkingHoursFromProfession() {
    syncScheduleToVisitingController(professionData.value.schedule);
  }

  /// Map a [Schedule] list onto the [VisitingHoursSelectorController]'s
  /// RxMaps. Each day defaults to closed; only the days present in
  /// the schedule get opened, with the first time slot pre-filling
  /// start/end times.
  void syncScheduleToVisitingController(List<Schedule>? schedule) {
    final visitingCtrl = getOrPut(() => VisitingHoursSelectorController());
    const allDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (schedule == null) {
      visitingCtrl.syncAll(
        visitingHours: {for (final d in allDays) d: false},
        startTimes: {},
        endTimes: {},
      );
      return;
    }
    final newVisitingHours = <String, bool>{};
    final newStartTimes = <String, TimeOfDay>{};
    final newEndTimes = <String, TimeOfDay>{};
    for (final d in allDays) {
      newVisitingHours[d] = false;
    }
    for (final sch in schedule) {
      final uiDay = _mapApiDayToUiDay((sch.day ?? '').toLowerCase());
      if (uiDay == null) continue;
      newVisitingHours[uiDay] = sch.isOpen ?? false;
      final firstSlot = (sch.timeSlots ?? []).isNotEmpty
          ? sch.timeSlots!.first
          : null;
      if (firstSlot != null) {
        final start = _parseTimeOfDay(firstSlot.startTime);
        final end = _parseTimeOfDay(firstSlot.endTime);
        if (start != null) newStartTimes[uiDay] = start;
        if (end != null) newEndTimes[uiDay] = end;
      }
    }
    visitingCtrl.syncAll(
      visitingHours: newVisitingHours,
      startTimes: newStartTimes,
      endTimes: newEndTimes,
    );
  }

  /// Serialise the current [VisitingHoursSelectorController] state into
  /// the JSON shape the backend expects for the `schedule` field —
  /// the same shape the booking endpoint already understood, so the
  /// `AvailabilityScheduleCard` keeps working when re-rendered.
  List<Map<String, dynamic>> payloadForWorkingHours() {
    final visitingCtrl = getOrPut(() => VisitingHoursSelectorController());
    final out = <Map<String, dynamic>>[];
    visitingCtrl.visitingHours.forEach((day, isOpen) {
      if (!isOpen) return;
      final s = visitingCtrl.startTimes[day];
      final e = visitingCtrl.endTimes[day];
      if (s == null || e == null) return;
      out.add({
        'day': day,
        'isOpen': true,
        'timeSlots': [
          {
            'startTime': visitingCtrl.formatTime(s),
            'endTime': visitingCtrl.formatTime(e),
          }
        ],
      });
    });
    return out;
  }

  String? _mapApiDayToUiDay(String apiDayLower) {
    switch (apiDayLower) {
      case 'monday':
      case 'mon':
        return 'Monday';
      case 'tuesday':
      case 'tue':
      case 'tues':
        return 'Tuesday';
      case 'wednesday':
      case 'wed':
        return 'Wednesday';
      case 'thursday':
      case 'thu':
      case 'thur':
      case 'thurs':
        return 'Thursday';
      case 'friday':
      case 'fri':
        return 'Friday';
      case 'saturday':
      case 'sat':
        return 'Saturday';
      case 'sunday':
      case 'sun':
        return 'Sunday';
      default:
        return null;
    }
  }

  TimeOfDay? _parseTimeOfDay(String? raw) {
    if (raw == null) return null;
    try {
      final value = raw.trim();
      final upper = value.toUpperCase();
      final hasMeridian = upper.contains('AM') || upper.contains('PM');
      final regex = RegExp(r'^(\d{1,2}):(\d{2})');
      final match = regex.firstMatch(upper);
      if (match == null) return null;
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hasMeridian) {
        if (upper.contains('PM') && hour != 12) hour += 12;
        if (upper.contains('AM') && hour == 12) hour = 0;
      }
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    aboutController.dispose();
    minFeeController.dispose();
    maxFeeController.dispose();
    feeTypeController.dispose();
    super.onClose();
  }

  ///UPDATE BUSINESS IMAGES....
  saveGalleryImages(String serviceId, String imagePath) async {
    try {

      // Prepare image
      // List<UploadS3ImageModel> images = [];
      UploadS3ImageModel? image;
        final imageInfo = getFileInfo(File(imagePath));
        if (imageInfo.isNotEmpty) {
          image = UploadS3ImageModel(
              path: imagePath,
              mimeType: imageInfo['mimeType']!
          );
      }
      if(image==null) return;

      Map<String, dynamic> params = {
        ApiKeys.contentTypeKey: image
      };

      ResponseModel responseModel = await EarnServiceRepo().uploadProfessionImage(serviceId: serviceId, params: params);
      if (responseModel.isSuccess) {

        // Set preSignedUrls from response
        String preSignedUrlImages =
            responseModel.response!.data['uploadData'][0]['url'] ?? [];

        image.preSignedUrl = preSignedUrlImages;
        await uploadAllImages([image]);

        // if (images.length == preSignedUrlImages.length) {
        //   for (var i = 0; i < images.length; i++) {
        //     images[i].preSignedUrl = preSignedUrlImages[i];
        //   }
        //
        //   // Upload all images with combined progress
        //   await uploadAllImages(images);
        // }

        fetchSelfProfessionData(isLoading: false);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
    }
  }

  Future<void> deleteProfessionImage(String serviceId, String imagePath) async {
    try {
      Map<String, dynamic> params = {ApiKeys.image_url: imagePath};
      ResponseModel responseModel =
      await EarnServiceRepo().deleteProfessionImage(serviceId: serviceId, params: params);
      if (responseModel.isSuccess) {
        fetchSelfProfessionData(isLoading: false);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
    }
  }

}