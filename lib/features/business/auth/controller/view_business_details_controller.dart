import 'dart:convert';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart' as widget;
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/model/getCountOfRatingModel.dart';
import 'package:BlueEra/features/business/auth/model/rating_feedback_model.dart';
import 'package:BlueEra/features/business/auth/model/rating_response_summary.dart';
import 'package:BlueEra/features/business/auth/model/visitingbusinessprofilestats.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

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
import '../repo/business_profile_repo.dart';

class ViewBusinessDetailsController extends GetxController {
  ApiResponse viewBusinessResponse = ApiResponse.initial('Initial');
  ApiResponse subCategoryResponse = ApiResponse.initial('Initial');
  ApiResponse businessCategoryResponse = ApiResponse.initial('Initial');
  ApiResponse businessVerifyResponse = ApiResponse.initial('Initial');
  ApiResponse businessGetAllProductResponse = ApiResponse.initial('Initial');
  ApiResponse getParticularRatingResponse = ApiResponse.initial('Initial');
  ApiResponse getAllBusinessRatingsResponse = ApiResponse.initial('Initial');
  ApiResponse getCountOfRatingResponse = ApiResponse.initial('Initial');
  ApiResponse getRatingByFiltersResponse = ApiResponse.initial('Initial');
  
  ApiResponse<ResponseModel> businessRatingsSummaryResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> postsResponse = ApiResponse.initial('Initial').obs;
    
  ViewBusinessProfileModel? businessProfileDetails;
  Rx<GetBusinessVerifyViewModel>? viewBusinessVerifyStatus =
      GetBusinessVerifyViewModel().obs;
  RxList<SubCategoryData> subCategoriesList = <SubCategoryData>[].obs;

  // Rx<File?> selectedVideo = Rx<File?>(null);
  ViewBusinessProfileModel? visitedBusinessProfileDetails;
     BusinessData? businessStatsData;
     
  Rx<Post> post = Post(id: '').obs;
  // RxList<String> imgUploadL2 = <String>[].obs;
  RxList<String> imgLocalL3 = <String>[].obs;
  RxList<int> imgDeleteL3 = <int>[].obs;
  RxInt selectedIndex = 0.obs;
  Rx<BusinessType>? selectedBusinessType = BusinessType.Both.obs;
  RxString? imagePath = "".obs;
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

  // RATINGS AND REVIEWS
  Rx<RatingSummaryResponse> ratingSummaryResponse = RatingSummaryResponse().obs;
   List<RatingDistribution> ratingDistributionList = [];
    List<FeedbackData> feedBackdataList = [];

  // Method to set start location data
  void setStartLocation(double? lat, double? lng, String address) {
    if (lat != null) addressLat?.value = lat;
    if (lng != null) addressLong?.value = lng;
    businessAddress.value = address;
  }

  void handleWidgetProfileHeaderOption(String option, BusinessProfileDetails? data) {
  switch (option) {
    case 'Share':
      final link = profileDeepLink(userId: data?.userId ?? '');
      final message = "See my profile on BlueEra:\n$link\n";
      SharePlus.instance.share(ShareParams(
        text: message,
        subject: data?.businessName ?? '',
      ));
      // commonSnackBar(message: "Product Shared.");
      break;
    case 'Report':
      commonSnackBar(message: "Product Reported.");
      break;
  }
}


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
            userNameAt: ""
        );

        await getUserLoginData();

        viewBusinessResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }



  Future<void> getBusinessStats(String businessId) async {
    try {
      await getUserLoginBusinessId();
      ResponseModel responseModel =
          await BusinessProfileRepo().getBusinessStats(businessId);

      if (responseModel.isSuccess) {
        logs('getBusinessStats responseModel.response?.data ${responseModel.response?.data}');
         // Parse the API response
// Map<String, dynamic> jsonResponse = json.decode(response.body);
VisitBusinessProfileStatsModel apiResponse = VisitBusinessProfileStatsModel.fromJson(responseModel.response?.data);
 logs('getBusinessStats  apiResponse ${apiResponse.data.toJson()}');
   businessStatsData = apiResponse.data;
// // Access the data
// print(apiResponse.success); // true
// print(apiResponse.data.businessId); // "689e28a978385d314533ec66"
// print(apiResponse.data.avgRating); // "5.00"
// print(apiResponse.data.totalRatings); // 1
        update();
      } else {
        // commonSnackBar(
        //     message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      // viewBusinessResponse = ApiResponse.error('error');
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

  Future<String?> getChannelDetails() async {
    try {
      ResponseModel response =
          await ChannelRepo().getChannelDetails(channelOrUserId: userId);

      if (response.statusCode == 200) {
        ChannelModel channelModel =
            ChannelModel.fromJson(response.response?.data);
        String channelId = channelModel.data.id;
        SharedPreferenceUtils.setSecureValue(channelId, channelId);
        return channelId;
      } else {
        return null;
      }
    } catch (e) {
      return null;
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
        final chatViewController = Get.find<ChatViewController>();
        Map<String, dynamic> detas = {
          ApiKeys.user_id: visitedBusinessProfileDetails?.data?.userId
        };
        chatViewController.checkChatConnection(detas);
        imagePath?.value = visitedBusinessProfileDetails?.data?.logo ?? "";
        businessDescription.value =
            visitedBusinessProfileDetails?.data?.businessDescription ?? "";
        viewBusinessResponse = ApiResponse.complete(responseModel);
        visitingcontroller.isFollow.value =
            visitedBusinessProfileDetails?.data?.is_following ?? false;

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

  Future<void> getCountOfRatingApiRepo(String businessId) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getCountOfRatingRepo(businessId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        logs(" akrid data $data");
        // getCountOfRatingResponse = ApiResponse.complete(responseModel);
        RatingDistributionResponse ratingDistributionResponse = RatingDistributionResponse.fromJson(data);
         ratingDistributionList = ratingDistributionResponse.data;
        logs(" akrid ratingDistributionResponse ${ratingDistributionList}");
    
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getCountOfRatingResponse = ApiResponse.error('error');
    }
  }

  Future<void> getRatingsByFiltersApi(int rating, String businessId) async {
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getRatingsByFiltersRepo(rating, businessId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getRatingByFiltersResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getRatingByFiltersResponse = ApiResponse.error('error');
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

      ResponseModel responseModel = await BusinessProfileRepo()
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
 
 Future<void> businessRatingsSummary(String businessId) async {
    // https://api.blueera.ai/api/user-service/business/rating/689e28a978385d314533ec66
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().businessRatingsSummary(  businessId);

      if (responseModel.isSuccess) {
       
        businessRatingsSummaryResponse = ApiResponse.complete(responseModel);
        if ( businessRatingsSummaryResponse.status == Status.COMPLETE) {
 
    ratingSummaryResponse.value = RatingSummaryResponse.fromJson(businessRatingsSummaryResponse.data?.response?.data);

    print("akrid ratingSummaryResponse ${ratingSummaryResponse.value.data.toJson()}");


}

        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllBusinessRatingsResponse = ApiResponse.error('error');
    }
  }
 

  Future<void> getAllBusinessRatingsApi(String businessId) async {
    // https://api.blueera.ai/api/user-service/business/rating/689e28a978385d314533ec66
    try {
      ResponseModel responseModel =
          await BusinessProfileRepo().getAllBusinessRatings(  businessId);

      if (responseModel.isSuccess) {
       
        getAllBusinessRatingsResponse = ApiResponse.complete(responseModel);
        if ( getAllBusinessRatingsResponse.status == Status.COMPLETE) {
  final ratingsData =  getAllBusinessRatingsResponse.data?.response?.data;
  logs("akrid ratingsData ${ratingsData}");
  // logs(ratingsData.toString());
  // Map<String, dynamic> jsonResponse = json.decode(getAllBusinessRatingsResponse.data?.response?.data);
FeedbackResponse feedbackResponse = FeedbackResponse.fromJson(ratingsData);
  feedBackdataList = feedbackResponse.data;
logs("akrid Feedback ${feedBackdataList.length}");
 
}

        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllBusinessRatingsResponse = ApiResponse.error('error');
    }
  }
 

  Future<void> getAllPostApi(
     String userId,
     ) async {
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: 1,
      ApiKeys.limit:1,
      ApiKeys.filter: "latest",
      ApiKeys.authorId: userId
    };
      queryParams[ApiKeys.refresh] = refresh;
    try {
      ResponseModel  response = await FeedRepo().getAllOtherPosts(queryParams: queryParams);
          if(response.isSuccess){
            logs("akrid response.response?.data.toString() ${response.response?.data}");
            logs("akrid response.response?.data.toString() ${response.response?.data.runtimeType}");
            postsResponse.value = ApiResponse.complete(response);
            logs("akrid postsResponse.value.data?.data ${postsResponse.value.data?.data}");
              post.value  = Post.fromJson( postsResponse.value.data?.data.first);
            logs("akrid post ${post}");
            update();
          }else{
             postsResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
          }
    } catch (e) {
        postsResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


}
