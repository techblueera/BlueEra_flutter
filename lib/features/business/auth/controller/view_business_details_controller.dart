import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/model/view_business_profile_model_new.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../common/reel/models/channel_model.dart';
import '../../../common/reel/repo/channel_repo.dart';
import '../model/AllSubCategoryDetailsModel.dart';
import '../model/GetParticularReviewListModel.dart';
import '../model/getAllProductDetailsModel.dart';
import '../model/getBusinessVerifyViewModel.dart';
import '../model/viewBusinessProfileModel.dart';
import '../model/visitBusinessDetailedRatingModel.dart';
import '../model/visitBusinessRatingSumModel.dart';
import '../repo/business_profile_repo.dart';
import 'package:geolocator/geolocator.dart' as geo;

Future<double?> getDistanceInKm(double targetLat, double targetLng) async {
  print("Lat : ${targetLat} , lng : ${targetLng}");
  // 🔐 Check and request permission
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
    desiredAccuracy: geo.LocationAccuracy.high,
  );

  // 📏 Calculate distance (meters)
  double distanceMeters = geo.Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    targetLat,
    targetLng,
  );

  // ✅ Return km
  return distanceMeters / 1000.0;
}

class ViewBusinessDetailsController extends GetxController {
  ApiResponse viewBusinessResponse = ApiResponse.initial('Initial');
  ApiResponse viewBusinessResponseNew = ApiResponse.initial('Initial');
  ApiResponse subCategoryResponse = ApiResponse.initial('Initial');
  ApiResponse businessCategoryResponse = ApiResponse.initial('Initial');
  ApiResponse businessVerifyResponse = ApiResponse.initial('Initial');
  ApiResponse businessGetAllProductResponse = ApiResponse.initial('Initial');
  ApiResponse getParticularRatingResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> postsResponse = ApiResponse.initial('Initial').obs;

  ViewBusinessProfileModel? businessProfileDetails;
  Rx<GetBusinessVerifyViewModel>? viewBusinessVerifyStatus =
      GetBusinessVerifyViewModel().obs;
  RxList<SubCategoryData> subCategoriesList = <SubCategoryData>[].obs;

  // Rx<File?> selectedVideo = Rx<File?>(null);
  ViewBusinessProfileModel? visitedBusinessProfileDetails;
  Rx<VisitBusinessRatingSumModel> visitBusinessRatingSumModel=VisitBusinessRatingSumModel().obs;
  Rx<VisitBusinessDetailedRatingModel> visitBusinessDetailedRatingModel=VisitBusinessDetailedRatingModel().obs;

  // RxList<String> imgUploadL2 = <String>[].obs;
  RxList<String> imgLocalL3 = <String>[].obs;
  RxList<int> imgDeleteL3 = <int>[].obs;
  RxInt selectedIndex = 0.obs;
  RxDouble distanceFromKm = 0.0.obs;
  Rx<BusinessType>? selectedBusinessType = BusinessType.Both.obs;
  RxString? imagePath = "".obs;
  RxString conversationId = "".obs;
  RxInt? selectDay = 0.obs, selectMonth = 0.obs, selectYear = 0.obs;
  RxBool isImageUpdated = false.obs;
  Rx<CategoryData?> selectedCategoryOfBusiness = Rx<CategoryData?>(null);

  Rx<SubCategories?> selectedSubCategoryOfBusinessNew =
      Rx<SubCategories?>(null);
  Rx<SubCategoryData?> selectedSubCategoryOfBusiness_ =
      Rx<SubCategoryData?>(null);

  // Rx<SubCategoryData>? selectedSubCategoryOfBusiness = SubCategoryData(name: "Select sub category").obs;
  RxBool isListingDescriptionEdit = true.obs;
  RxString businessDescription = "".obs;
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

  // Method to set start location data
  void setStartLocation(double? lat, double? lng, String address) {
    if (lat != null) addressLat?.value = lat;
    if (lng != null) addressLong?.value = lng;
    businessAddress.value = address;
  }
  final controllerVisit = Get.put(VisitProfileController());

  Future<void> viewBusinessProfile() async {
    try {
      await getUserLoginBusinessId();
      ResponseModel responseModel =
          await BusinessProfileRepo().viewParticularBusinessProfile();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        businessProfileDetails = ViewBusinessProfileModel.fromJson(data);
        selectDay?.value =
            businessProfileDetails?.data?.dateOfIncorporation?.date ?? 0;
        selectMonth?.value =
            businessProfileDetails?.data?.dateOfIncorporation?.month ?? 0;
        selectYear?.value =
            businessProfileDetails?.data?.dateOfIncorporation?.year ?? 0;
        imagePath?.value = businessProfileDetails?.data?.logo ?? "";
        selectedCategoryOfBusiness.value = CategoryData(
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
                    : BusinessType.Both;
        businessDescription.value =
            businessProfileDetails?.data?.businessDescription ?? "";
        controllerVisit.isFollow.value=businessProfileDetails?.data?.is_following??false;
        if (selectedBusinessType?.value.name.toLowerCase() == "both") {
          selectedCategoryOfBusiness.value = null;
          selectedSubCategoryOfBusinessNew.value = null;
        }
        Get.find<AuthController>().imgPath.value =
            businessProfileDetails?.data?.logo ?? "";

        await SharedPreferenceUtils.userLoggedInBusiness(
            profileImage: businessProfileDetails?.data?.logo ?? '',
            businessName: businessProfileDetails?.data?.businessName ?? '',
            businessOwnerName:
                businessProfileDetails?.data?.ownerDetails?[0].name ?? '',
            businessId: businessProfileDetails!.data!.id!,
            loginBusinessUserId: businessProfileDetails!.data!.userId!,
            userNameAt: "");

        await getUserLoginData();

        viewBusinessResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        logs("ERROR BUSINESS PROFILE ${ responseModel.message ?? AppStrings.somethingWentWrong}");

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR BUSINESS PROFILE ${e}");
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

  Future<void> updateBusinessDetails(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await AuthRepo().updateBusinessAccountUserRepo(bodyRequest: params);

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
    }
  }

  RxList<CategoryData> businessCategoriesList = <CategoryData>[].obs;
  RxList<SubCategories> businessSubCategoriesList = <SubCategories>[].obs;

  Future<void> getAllCategories() async {
    businessSubCategoriesList.clear();
    try {
      ResponseModel responseModel =
          await AuthRepo().getBusinessCategoriesRepo();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        businessCategoriesList.value = CategoryModel.fromJson(data).data ?? [];

        final dataList = businessCategoriesList
            .where((e) =>
                e.id?.toLowerCase() ==
                selectedCategoryOfBusiness.value?.id.toString())
            .toList();
        if (dataList.isNotEmpty) {
          businessSubCategoriesList.addAll(dataList.first.subCategories ?? []);
        }

        // await getSubCategory();
        businessCategoryResponse = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      businessCategoryResponse = ApiResponse.error('error');
    }
  }

  Future<void> getSubCategory() async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getSubBusinessCat();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        subCategoryResponse = ApiResponse.complete(responseModel);
        subCategoriesList.value =
            AllSubCategoryDetailsModel.fromJson(data).data ?? [];
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      subCategoryResponse = ApiResponse.error('error');
    }
  }

  Future<void> postVerifyBusinessDocs(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().uploadVerifyBusinessDocs(params);

      if (responseModel.isSuccess) {
        businessVerifyResponse = ApiResponse.complete(responseModel);
        getBusinessVerification();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      businessVerifyResponse = ApiResponse.error('error');
    }
  }

  Future<void> postVerifyOwnerBusinessDocs(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().uploadVerificationOwnerDocs(params);
      if (responseModel.isSuccess) {
        businessVerifyResponse = ApiResponse.complete(responseModel);
        getBusinessVerification();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      businessVerifyResponse = ApiResponse.error('error');
    }
  }

  Future<void> getBusinessVerification() async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getBusinessVerificationStatus();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        businessVerifyResponse = ApiResponse.complete(responseModel);
        GetBusinessVerifyViewModel value =
            GetBusinessVerifyViewModel.fromJson(data['data']);
        viewBusinessVerifyStatus?.value = value;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      businessVerifyResponse = ApiResponse.error('error');
    }
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
        chatViewController.checkChatConnection(detas);
        imagePath?.value = visitedBusinessProfileDetails?.data?.logo ?? "";
        businessDescription.value =
            visitedBusinessProfileDetails?.data?.businessDescription ?? "";
        conversationId.value= ((chatViewController.newVisitContactApiResponse?.value?.data?.otherUserId==null)?chatViewController.newVisitContactApiResponse?.value?.data?.conversationId: chatViewController.newVisitContactApiResponse?.value?.data?.otherUserId)??'';
        viewBusinessResponseNew = ApiResponse.complete(responseModel);
        visitingcontroller.isFollow.value =
            visitedBusinessProfileDetails?.data?.is_following ?? false;
        distanceFromKm.value = await getDistanceInKm(visitedBusinessProfileDetails?.data?.businessLocation?.lat??0,visitedBusinessProfileDetails?.data?.businessLocation?.lon??0)??0.0;
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e}");
      viewBusinessResponseNew = ApiResponse.error('error');
    }
  }
  Future<void> getBusinessRatingsSummary(String userId) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getBusinessRatingsSummary(userId);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        visitBusinessRatingSumModel.value=VisitBusinessRatingSumModel.fromJson(data);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }
  Future<void> getBusinessDetailedRatings(String userId) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getBusinessDetailedRating(userId);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        log("kdjcnksjdcnksdc ${data}");
        visitBusinessDetailedRatingModel.value=VisitBusinessDetailedRatingModel.fromJson(data);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

  Future<void> getAllProductsApi(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getAllProductsApi(params);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getAllProductDetails?.value = GetAllProductDetailsModel.fromJson(data);
        businessGetAllProductResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      businessGetAllProductResponse = ApiResponse.error('error');
    }
  }

  Future<void> getParticularRatingApi(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getParticularRatingApi(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getParticularReviewListModel?.value =
            GetParticularReviewListModel.fromJson(data);
        getParticularRatingResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getParticularRatingResponse = ApiResponse.error('error');
    }
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

      ResponseModel?

        responseModel = await BusinessProfileRepo()
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

        responseModel = await BusinessProfileRepo()
            .submitRatingToPersonal(userId, params);

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
//
// Future<void> getAllPostApi(
//    ) async {
//   final Map<String, dynamic> queryParams = {
//     ApiKeys.page: 1,
//     ApiKeys.limit:10,
//     ApiKeys.filter: "latest"
//   };

//   // if (query == null) {
//     queryParams[ApiKeys.refresh] = refresh;
//   // }

//   try {
//     ResponseModel response =
//         await FeedRepo().getAllMyPosts(queryParams: queryParams);
//         if(response.isSuccess){
// postsResponse.value = ApiResponse.complete(response);
//       final postResponse = PostResponse.fromJson(response.response?.data);
//         }else{
//            postsResponse.value = ApiResponse.error('error');
//       commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
//         }
//   } catch (e) {
//       postsResponse.value = ApiResponse.error('error');
//     commonSnackBar(message: AppStrings.somethingWentWrong);
//   }
// }
}
