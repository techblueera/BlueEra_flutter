import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class HomeScreenController extends GetxController{
  Rx<ApiResponse> getDailyContentOrGreeting = ApiResponse.initial('Initial').obs;
  ApiResponse viewBusinessResponse = ApiResponse.initial('Initial');

  final RxBool isVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;

  Future<void> getDailyGreeting() async {
    try {

      ResponseModel responseModel = await UserRepo().getDailyContentOrGreeting();
      if (responseModel.isSuccess) {
        getDailyContentOrGreeting.value = ApiResponse.complete(responseModel);
        // UserTestimonialModel userTestimonialModel = UserTestimonialModel.fromJson(responseModel.response?.data);
        // testimonialsList?.value = userTestimonialModel.testimonials ?? [];
      } else {
        getDailyContentOrGreeting.value = ApiResponse.error('error');

        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getDailyContentOrGreeting.value = ApiResponse.error('error');
    }
  }


  Future<void> getBusinessProfileData() async {
    try {
      await getUserLoginBusinessId();
      ResponseModel responseModel = await BusinessProfileRepo().viewParticularBusinessProfile();

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        ViewBusinessProfileModel? businessProfileDetails = ViewBusinessProfileModel.fromJson(data);

        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.userProfile,
            businessProfileDetails.data?.logo);

        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.businessName,
            businessProfileDetails.data?.businessName);

        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.businessOwnerName,
            businessProfileDetails.data?.ownerDetails?[0].name);

        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.businessUserIdKey,
            businessProfileDetails.data?.userId);

        await getBusinessData();

        viewBusinessResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong
        );
      }
    } catch (e) {
      viewBusinessResponse = ApiResponse.error('error');
    }
  }

}