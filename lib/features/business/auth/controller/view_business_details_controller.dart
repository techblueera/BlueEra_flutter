import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
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
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
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

  final Rx<ViewBusinessProfileModel?> businessProfileDetails = Rx<ViewBusinessProfileModel?>(null);

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
    if (lat != null) addressLat?.value = lat;
    if (lng != null) addressLong?.value = lng;
    businessAddress.value = address;
  }

  final controllerVisit = Get.put(VisitProfileController());
  final isLoading = false.obs;
  final isProfileLoading = false.obs;

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

  Future<void> viewBusinessProfile() async {
    // try {
    await getUserLoginBusinessId();
    ResponseModel responseModel =
        await BusinessProfileRepo().viewParticularBusinessProfile();
    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;

      businessProfileDetails.value = ViewBusinessProfileModel.fromJson(data);

      selectDay?.value =
          businessProfileDetails.value?.data?.dateOfIncorporation?.date ?? 0;
      selectMonth?.value =
          businessProfileDetails.value?.data?.dateOfIncorporation?.month ?? 0;
      selectYear?.value =
          businessProfileDetails.value?.data?.dateOfIncorporation?.year ?? 0;
      imagePath?.value = businessProfileDetails.value?.data?.logo ?? "";
      coverImage?.value = businessProfileDetails.value?.data?.coverimage ?? "";
/*      selectedCategoryOfBusiness.value = CategoryData(
          id: businessProfileDetails?.data?.categoryDetails?.id,
          name: businessProfileDetails?.data?.categoryDetails?.name);
      selectedSubCategoryOfBusinessNew.value = SubCategories(
          sId: businessProfileDetails?.data?.subCategoryDetails?.id,
          name: businessProfileDetails?.data?.subCategoryDetails?.name);
      selectedBusinessType?.value =
          businessProfileDetails?.data?.typeOfBusiness == "Product"
              ? BusinessType.Product
              : businessProfileDetails?.data?.typeOfBusiness == "Service"
                  ? BusinessType.Service
                  : businessProfileDetails?.data?.typeOfBusiness == "Food"
                      ? BusinessType.Food
                      : businessProfileDetails?.data?.typeOfBusiness ==
                              "Grocery"
                          ? BusinessType.Grocery
                          : businessProfileDetails?.data?.typeOfBusiness ==
                                  "Manufacturing"
                              ? BusinessType.Manufacturing
                              : BusinessType.Both; // Default fallback*/

/*
      if (businessProfileDetails?.data?.typeOfBusiness ==
          BusinessType.Product.name) {
        selectedTypeOfBusiness.value = BusinessCategory(
          title: "Product Sales: Shop/Store/Showroom",
          subTitle:
              "(e.g., Clothes, Electronics, Pharmacy, Toy, Beauty product)",
          icon: AppIconAssets.product_sale,
          type: BusinessType.Product.name,
        );
      } else if (businessProfileDetails?.data?.typeOfBusiness ==
          BusinessType.Service.name) {
        selectedTypeOfBusiness.value = BusinessCategory(
          title: "Service Provider: Education/Hospital/Hotel etc.",
          subTitle: "(Consulting Farm, Doctors, All Service providers)",
          icon: AppIconAssets.service_provider,
          type: BusinessType.Service.name,
        );
      } else if (businessProfileDetails?.data?.typeOfBusiness ==
          BusinessType.Food.name) {
        selectedTypeOfBusiness.value = BusinessCategory(
          title: "Grocerie /Food /Restaurant/Beverage",
          subTitle:
              "All Kind of Cooking/Eatable Shops/Stall/Dairy\nRestaurants, Sweet Shops, Tea Stalls, Juice Centers",
          icon: AppIconAssets.food_service,
          type: BusinessType.Food.name,
        );
      } else {
        selectedTypeOfBusiness.value = BusinessCategory(
          title: "Others: Manufacturing Unit/Industry/Factory",
          subTitle:
              "If Your Business Is related to Manufacturing / create products Or other activity",
          icon: AppIconAssets.other_type,
          type: BusinessType
              .Both.name, // (requires Flutter 3.7+, else use Icons.work)
        );
      }
*/

      businessDescription.value =
          businessProfileDetails.value?.data?.businessDescription ?? "";
      tempDescription.value = businessDescription.value;
      controllerVisit.isFollow.value =
          businessProfileDetails.value?.data?.is_following ?? false;
      isBusinessVerified.value=businessProfileDetails.value?.data?.businessIsVerified ?? false;
      // if (selectedBusinessType?.value.name.toLowerCase() == "both") {
      //   selectedCategoryOfBusiness.value = null;
      //   selectedSubCategoryOfBusinessNew.value = null;
      // }
      Get.find<AuthController>().imgPath.value =
          businessProfileDetails.value?.data?.logo ?? "";
      log('business type -- ${businessProfileDetails.value?.data?.typeOfBusiness}');
      await SharedPreferenceUtils.userLoggedInBusiness(
        // contactNo: businessProfileDetails.value?.data?.userContactNo ?? '',
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
        typeOfBusiness: businessProfileDetails.value?.data?.typeOfBusiness ?? '',
        // typeOfBusiness: businessProfileDetails.value?.data?.typeOfBusiness ?? '',
      );

      await getUserLoginData();

      viewBusinessResponse = ApiResponse.complete(responseModel);
      update();
    } else {
      logs(
          "ERROR BUSINESS PROFILE ${responseModel.message ?? AppStrings.somethingWentWrong}");

      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
    // } catch (e) {
    //   logs("ERROR BUSINESS PROFILE ${e}");
    //   viewBusinessResponse = ApiResponse.error('error');
    // }
  }

  ///UPDATE BUSINESS IMAGES....
  saveBusinessImages(
      String imagePath, ViewBusinessDetailsController controller) async {
    dio.MultipartFile? imageByPart;

    String fileName = imagePath.split('/').last;
    imageByPart =
        await dio.MultipartFile.fromFile(imagePath, filename: fileName);

    Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};

    controller.uploadLiveStoreImage(params);
    await Future.delayed(Duration(seconds: 1));
    controller.imgDeleteL3.clear();
  }

  RxBool isUpdateBusinessDetailsLoading = false.obs;

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

  Future<void> updateBusinessProfileDetails(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().updateBusinessProfileDetails(params);

      if (responseModel.isSuccess) {
        commonSnackBar(message: "${responseModel.message}");

        viewBusinessProfile();
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

  final RxBool isCategoriesLoading = false.obs;
  final RxBool isSubCategoriesLoading = false.obs;
  RxList<CategoryData> businessCategoriesList = <CategoryData>[].obs;
  RxList<SubCategories> businessSubCategoriesList = <SubCategories>[].obs;
  RxString categorySpecializationText = "".obs;
  RxString errorMessage = "".obs;


  /// Step 1 – Nature of Business
  Rx<BusinessCategory?> selectedTypeOfBusiness =
  Rx<BusinessCategory?>(null);

  /// Step 2 – Parent Categories
  RxList<CategoryData> categoryList = <CategoryData>[].obs;
  Rx<CategoryData?> selectedCategory = Rx<CategoryData?>(null);

  /// Step 3 – Sub Categories / Products
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
      final response =
      await AuthRepo().getBusinessCategoriesByTypeRepo(selectedTypeOfBusiness.value?.type??"");

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

  Future<void> viewBusinessProfileById(String userId) async {
    try {
      isProfileLoading.value = true;
      ResponseModel responseModel =
          await BusinessProfileRepo().viewBusinessProfileById(userId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        visitedBusinessProfileDetails = ViewBusinessProfileModel.fromJson(data);
        // visitedBusinessProfileDetails = visitedBusinessProfileDetails_ as ViewBusinessProfileModel?;
        final chatViewController = Get.find<ChatViewController>();
        Map<String, dynamic> detas = {
          ApiKeys.user_id: visitedBusinessProfileDetails?.data?.userId
        };
        Map<String,dynamic>? checkCompleted =
            await chatViewController.checkChatConnection(detas);
        imagePath?.value = visitedBusinessProfileDetails?.data?.logo ?? "";
        businessDescription.value =
            visitedBusinessProfileDetails?.data?.businessDescription ?? "";

        conversationId.value = checkCompleted?[ApiKeys.conversation_id]??'';
        otherUserId?.value = checkCompleted?[ApiKeys.other_user_id]??'';
        if (checkCompleted!=null) {
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
    }finally{
      isProfileLoading.value = false;
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

  Future<void> getAllProductsApi(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getAllProductsApi(params);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getAllProductDetails?.value = GetAllProductDetailsModel.fromJson(data);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<void> getParticularRatingApi(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getParticularRatingApi(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getParticularReviewListModel?.value =
            GetParticularReviewListModel.fromJson(data);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<bool> submitBusinessRating({
    required String businessId,
    required int rating,
    required String comment,
  }) async {
    try {
      Map<String, dynamic> params = {
        "rating": rating,
        "comment": comment,
      };

      ResponseModel? responseModel = await BusinessProfileRepo()
          .submitRatingToBusiness(businessId, params);

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
      final responseModel =
          await BusinessProfileRepo().getProducts(businessId: visitBusinessId);
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
