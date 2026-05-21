import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/api/model/type_of_business_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/model/business_ratings_model.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart' hide Response;
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
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

class ViewBusinessDetailsController extends GetxController {
  ApiResponse viewBusinessResponse = ApiResponse.initial('Initial');
  ApiResponse viewBusinessResponseNew = ApiResponse.initial('Initial');
  Rx<ApiResponse> postsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessFoodResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessRatingsResponse = ApiResponse.initial('Initial').obs;

  final Rx<ViewBusinessProfileModel?> businessProfileDetails =
      Rx<ViewBusinessProfileModel?>(null);

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
        // getBusinessRatingsSummary(businessID),
        // getBusinessDetailedRatings(businessID)
      ]);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches the current business profile.
  ///
  /// [silent] = true skips the cache-replay step (used after an update
  /// so the cover/avatar UI doesn't flash the stale cached version
  /// between "shimmer off" and the server confirming the new asset).
  Future<void> viewBusinessProfile({bool silent = false}) async {
    await getUserLoginBusinessId();

    // 1. Show cached business profile (if any) immediately so the UI
    //    isn't blank while the network call is in flight. Skipped in
    //    `silent` mode — the caller (typically a post-update refresh)
    //    already has fresher in-memory state than the cache, and
    //    replaying the cache would visibly revert the change.
    final cacheKey = businessId.isNotEmpty ? businessId : userId;
    final cached = silent ? null : await BusinessProfileCache.read(cacheKey);
    if (cached != null) {
      _applyBusinessProfileData(cached, persistPrefs: false);
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
      update();
    } else {
      logs(
          "ERROR BUSINESS PROFILE ${responseModel.message ?? AppStrings.somethingWentWrong}");

      // Only surface the error to the user when we have nothing cached
      // to fall back on — otherwise the cached UI is already showing.
      if (cached == null) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
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

    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().imgPath.value =
          businessProfileDetails.value?.data?.logo ?? "";
    }

    if (!persistPrefs) return;

    log('business type -- ${businessProfileDetails.value?.data?.typeOfBusiness}');
    await SharedPreferenceUtils.userLoggedInBusiness(
      email: businessProfileDetails.value?.data?.ownerDetails?[0].email ?? '',
      profileImage: businessProfileDetails.value?.data?.logo ?? '',
      businessName: businessProfileDetails.value?.data?.businessName ?? '',
      businessOwnerName:
          businessProfileDetails.value?.data?.ownerDetails?[0].name ?? '',
      businessId: businessProfileDetails.value!.data!.id!,
      loginBusinessUserId: businessProfileDetails.value!.data!.userId!,
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

  Future<void> updateBusinessDetails(Map<String, dynamic> params,
      {bool? showProgress}) async {
    try {
      isUpdateBusinessDetailsLoading.value = true;
      ResponseModel responseModel = await AuthRepo()
          .updateBusinessAccountUserRepo(
              bodyRequest: params, showProgress: showProgress);

      // ResponseModel responseModel =
      //     await BusinessProfileRepo().updateBusinessProfileDetails(params);
      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.response?.data['message']);
        viewBusinessResponse = ApiResponse.complete(responseModel);
        viewBusinessProfile();
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    } finally {
      isUpdateBusinessDetailsLoading.value = false;
    }
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

  Future<void> uploadLiveStoreImage(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().uploadLiveStoreImages(params);
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

  final visitingcontroller = Get.put(VisitProfileController());

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
        // visitedBusinessProfileDetails = visitedBusinessProfileDetails_ as ViewBusinessProfileModel?;
        final chatViewController = Get.find<ChatViewController>();
        Map<String, dynamic> detas = {
          ApiKeys.user_id: visitedBusinessProfileDetails?.data?.userId
        };
        Map<String, dynamic>? checkCompleted =
            await chatViewController.checkChatConnection(detas);
        imagePath?.value = visitedBusinessProfileDetails?.data?.logo ?? "";
        businessDescription.value =
            visitedBusinessProfileDetails?.data?.businessDescription ?? "";

        conversationId.value = checkCompleted?[ApiKeys.conversation_id] ?? '';
        otherUserId?.value = checkCompleted?[ApiKeys.other_user_id] ?? '';
        if (checkCompleted != null) {
          viewBusinessResponseNew = ApiResponse.complete(responseModel);
        }
        visitingcontroller.isFollow.value =
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
        businessRatingsResponse.value = ApiResponse.complete(responseModel);

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
        businessRatingsResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      businessRatingsResponse.value = ApiResponse.error('error');
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

      final responseModel = await ProductRepo()
          .fetchProductsRepo(queryParams: queryParams);

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
