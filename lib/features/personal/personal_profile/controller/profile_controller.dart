import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/user_profile_res.dart';
import 'package:BlueEra/core/api/model/user_testimonial_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../repo/user_repo.dart';

class VisitProfileController extends GetxController {
  var userProfileResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> followUnFollowResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addTestimonialResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getTestimonialResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getUserChannelDetailsResponse =
      ApiResponse.initial('Initial').obs;
  var userData = Rxn<UserProfileRes>();
  final fullNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final investmentController = TextEditingController();
  final messageController = TextEditingController();
  final cityController = TextEditingController();
  final List<String> qualificationsList = AppConstants.qualificationList;
  RxList<String> stateList = AppConstants.stateList.obs;
  RxString selectQualification = ''.obs;
  RxString haveYouWorkedHere = 'No'.obs;
  RxString partnerType = ''.obs;
  RxString selectedState = "Andhra Pradesh".obs;
  RxBool enquiryBtnLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
  }

  void selectState(String state) {
    selectedState.value = state;
  }

  final personalController = Get.find<PersonalCreateProfileController>();
  final personalProfileDetails =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  RxBool isProfileLoading = false.obs;
  Future<void> fetchUserById({required String userId}) async {
    try {
      isProfileLoading.value = true;
      ResponseModel response = await UserRepo().getUserById(userId: userId);
      if (response.isSuccess && response.response?.data != null) {
        // print("useralldata:${response.response?.data}");
        userData.value = UserProfileRes.fromJson(response.response?.data);
        //   print("useralldata:${ userData.value}");
        isFollow.value = userData.value?.isFollowing ?? false;
        followerCount.value = userData.value?.followersCount ?? 0;
        print("useralldata:${userData.value}");

        ///SET SKILL...
        personalController.skillsList.clear();
        personalController.skillsList
            .addAll(userData.value?.user?.skills ?? []);

        ///SET OVERVIEW
        personalProfileDetails.overView.value =
            userData.value?.user?.objective ?? "";

        print("useralldata:${personalProfileDetails}");
        userProfileResponse.value = ApiResponse.complete(response);
      } else {
        userProfileResponse.value =
            ApiResponse.error(response.message ?? "Something went wrong");
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
      isProfileLoading.value = false;
    } catch (e) {
      isProfileLoading.value = false;

      userProfileResponse.value = ApiResponse.error("Error: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  //  ratting Summary Api

  String formatDateOfBirth(DateOfBirth? dateOfBirth) {
    if (dateOfBirth == null) return 'Not available';
    try {
      return '${dateOfBirth.date.toString().padLeft(2, '0')}/${dateOfBirth.month.toString().padLeft(2, '0')}/${dateOfBirth.year}';
    } catch (e) {
      return 'Not available';
    }
  }

  List<SocialLinkItem> getAvailableSocialLinks() {
    final links = <SocialLinkItem>[];
    SocialLinks? social = userData.value?.user?.socialLinks;

    if (social == null) return [];
    //
    // if (social.instagram?.isNotEmpty == true) {
    //   links.add(SocialLinkItem(name: 'Instagram', url: social.instagram!));
    // }
    if (social.youtube?.isNotEmpty == true) {
      links.add(SocialLinkItem(name: 'YouTube', url: social.youtube!));
    }
    // if (social.linkedin?.isNotEmpty == true) {
    //   links.add(SocialLinkItem(name: 'LinkedIn', url: social.linkedin!));
    // }
    // if (social.website?.isNotEmpty == true) {
    //   links.add(SocialLinkItem(name: 'Website', url: social.website!));
    // }
    // if (social.twitter?.isNotEmpty == true) {
    //   links.add(SocialLinkItem(name: 'Twitter', url: social.twitter!));
    // }

    return links;
  }

  ///FOLLOW USER...
  RxBool isFollow = false.obs;
  RxInt followerCount = 0.obs;

  Future<void> followUserController(
      {required String? candidateResumeId}) async {
    try {
      followUnFollowResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().followUser(followUserId: candidateResumeId);

      if (responseModel.isSuccess) {
        isFollow.value = true;
        followUnFollowResponse.value = ApiResponse.complete(responseModel);
        followerCount.value++;

        // Following someone changes the logged-in user's followingCount, so
        // drop the cached own-counts — the next profile open refetches fresh.
        userCountsCache.clear();

        /// Update follow status in store screen
        updateFollowStatusForStore(candidateResumeId, true);
      } else {
        isFollow.value = false;

        followUnFollowResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isFollow.value = false;

      followUnFollowResponse.value = ApiResponse.error('error');
    }
    // if (isFollow.value == true) {
    //   followerCount.value = followerCount.value + 1;
    // }
  }

  ///UNFOLLOW USER...
  Future<void> unFollowUserController(
      {required String? candidateResumeId}) async {
    try {
      followUnFollowResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().unfollowUser(followUserId: candidateResumeId);
      if (responseModel.isSuccess) {
        isFollow.value = false;
        followUnFollowResponse.value = ApiResponse.complete(responseModel);
        followerCount--;

        // Unfollowing changes the logged-in user's followingCount, so drop the
        // cached own-counts — the next profile open refetches fresh.
        userCountsCache.clear();

        /// Update Unfollow status in store screen
        updateFollowStatusForStore(candidateResumeId, false);
      } else {
        isFollow.value = true;

        followUnFollowResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isFollow.value = true;

      followUnFollowResponse.value = ApiResponse.error('error');
    }
  }

  ///FOLLOW CHANNEL...

  Future<void> followChannelUserController(
      {required String? candidateResumeId}) async {
    try {
      followUnFollowResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().channelFollowUser(followUserId: candidateResumeId);
      if (responseModel.isSuccess) {
        isFollow.value = true;
        followUnFollowResponse.value = ApiResponse.complete(responseModel);
        followerCount.value++;

        /// Update follow status in store screen
        updateFollowStatusForStore(candidateResumeId, true);
      } else {
        isFollow.value = false;

        followUnFollowResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isFollow.value = false;

      followUnFollowResponse.value = ApiResponse.error('error');
    }
    // if (isFollow.value == true) {
    //   followerCount.value = followerCount.value + 1;
    // }
  }

  ///UNFOLLOW CHANNEL USER...
  Future<void> unChannelFollowUserController(
      {required String? candidateResumeId}) async {
    try {
      followUnFollowResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().channelUnfollowUser(followUserId: candidateResumeId);
      if (responseModel.isSuccess) {
        isFollow.value = false;
        followUnFollowResponse.value = ApiResponse.complete(responseModel);
        followerCount--;

        /// Update Unfollow status in store screen
        updateFollowStatusForStore(candidateResumeId, false);
      } else {
        isFollow.value = true;

        followUnFollowResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isFollow.value = true;

      followUnFollowResponse.value = ApiResponse.error('error');
    }
  }

  void updateFollowStatusForStore(String? candidateResumeId, bool isFollowed) {
    final controller = getOrPut(() => StoreController());

    // Update in allStore
    final listStoreData = controller.allStore;
    if (listStoreData.isNotEmpty) {
      final index = listStoreData.indexWhere(
        (elem) => elem.userId == candidateResumeId,
      );
      if (index != -1) {
        final data = listStoreData[index];
        listStoreData[index] = data.copyWith(isFollowed: isFollowed);
      }
    }

    controller.allStore.refresh();

    // if (Get.isRegistered<StoreScreenController>()) {
    //   final storeScreenController = Get.find<StoreScreenController>();
    //
    //   // 🔹 Update in allNearByStoresFeed
    //   final listAllData = storeScreenController.allNearByStoresFeed;
    //   if (listAllData.isNotEmpty) {
    //     final index = listAllData.indexWhere(
    //           (elem) => elem.businessData?.userId == candidateResumeId,
    //     );
    //     if (index != -1) {
    //       final data = listAllData[index];
    //       listAllData[index] = data.copyWith(
    //         businessData: data.businessData?.copyWith(isFollowed: isFollowed),
    //       );
    //     }
    //   }
    //
    //   // Update in allStore
    //   final listStoreData = storeScreenController.allStore;
    //   if (listStoreData.isNotEmpty) {
    //     final index = listStoreData.indexWhere(
    //           (elem) => elem.userId == candidateResumeId,
    //     );
    //     if (index != -1) {
    //       final data = listStoreData[index];
    //       listStoreData[index] = data.copyWith(isFollowed: isFollowed);
    //     }
    //   }
    //
    //   storeScreenController.allNearByStoresFeed.refresh();
    //   storeScreenController.allStore.refresh();
    // }
  }

  ///ADD TESTIMONIAL....
  Future<void> addTestimonialController(
      {required Map<String, dynamic>? bodyReq}) async {
    try {
      addTestimonialResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().addTestimonialRepo(reqPar: bodyReq);
      if (responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.response?.data['message'] ??
                AppStrings.somethingWentWrong);
        await getTestimonialController(userID: bodyReq?[ApiKeys.toUser]);
        addTestimonialResponse.value = ApiResponse.complete(responseModel);
      } else {
        addTestimonialResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addTestimonialResponse.value = ApiResponse.error('error');
    }
  }

  ///GET TESTIMONIAL....
  Rx<List<Testimonials>>? testimonialsList = Rx([]);

  Future<void> getTestimonialController({required String? userID}) async {
    try {
      testimonialsList?.value.clear();
      getTestimonialResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().getTestimonialRepo(userId: userID);
      if (responseModel.isSuccess) {
        UserTestimonialModel userTestimonialModel =
            UserTestimonialModel.fromJson(responseModel.response?.data);
        testimonialsList?.value = userTestimonialModel.testimonials ?? [];
        getTestimonialResponse.value = ApiResponse.complete(responseModel);
      } else {
        getTestimonialResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getTestimonialResponse.value = ApiResponse.error('error');
    }
  }

  ///GET CHANNEL DETAILS...
  RxString? channelUserName = "".obs;
  RxString? channelName = "".obs;
  RxString? channelUserId = "".obs;
  resetData() {
    channelName?.value = "";
    channelUserName?.value = "";
    channelUserId?.value = "";
  }

  Future<String?> getUserChannelDetailsController(
      {required String? userId}) async {
    try {
      resetData();
      getUserChannelDetailsResponse.value = ApiResponse.initial('Initial');

      ResponseModel response =
          await ChannelRepo().getChannelDetails(channelOrUserId: userId ?? "");

      if (response.statusCode == 200) {
        ChannelModel channelModel =
            ChannelModel.fromJson(response.response?.data);
        channelName?.value = channelModel.data.name;
        channelUserName?.value = channelModel.data.username;
        channelUserId?.value = channelModel.data.id;
        getUserChannelDetailsResponse.value = ApiResponse.complete(response);
      } else {
        getUserChannelDetailsResponse.value = ApiResponse.error('error');

        return null;
      }
    } catch (e) {
      getUserChannelDetailsResponse.value = ApiResponse.error('error');

      return null;
    }
    return null;
  }

  Future<void> enquiryFranchise() async {
    try {
      enquiryBtnLoading.value = true;
      Map<String, dynamic> params = {
        ApiKeys.firstName: fullNameController.text.trim(),
        ApiKeys.lastName: lastNameController.text.trim(),
        ApiKeys.email: emailController.text.trim(),
        ApiKeys.phone: "+91${phoneController.text.trim()}",
        'state': selectedState.value,
        'city': cityController.text.trim(),
        'qualification': selectQualification.value,
        ApiKeys.partnerType: partnerType.value,
        ApiKeys.investmentAmount:
            int.tryParse(investmentController.text.trim()) ?? 0,
        ApiKeys.hasExistingBusiness: haveYouWorkedHere.value == "Yes",
        'hasExperience': haveYouWorkedHere.value == "Yes",
        'message': messageController.text.trim(),
      };
      final response =
          await UserRepo().submitFranchiseInquiry(bodyRequest: params);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearFranchiseForm();
        commonSnackBar(message: AppStrings.franchiseSubmitSuccess.tr);
        Get.offAllNamed('/BottomNavigationBarScreen');
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      enquiryBtnLoading.value = false;
    }
  }

  void _clearFranchiseForm() {
    fullNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    investmentController.clear();
    cityController.clear();
    messageController.clear();
    selectQualification.value = '';
    partnerType.value = '';
    haveYouWorkedHere.value = 'No';
  }
}

class SocialLinkItem {
  final String name;
  final String url;

  SocialLinkItem({required this.name, required this.url});
}
