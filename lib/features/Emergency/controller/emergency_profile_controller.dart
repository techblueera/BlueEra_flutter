import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:get/get.dart';
import '../model/emergency_profile_model.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class EmergencyProfileController extends GetxController {
  Rx<ApiResponse> profileResponse = ApiResponse.initial('Initial').obs;
  Rx<EmergencyProfileModel?> emergencyProfileData =
      Rxn<EmergencyProfileModel>();

  @override
  void onInit() {
    super.onInit();
    if (userId.isNotEmpty) {
      getEmergencyProfile1();
    } else {
      profileResponse.value = ApiResponse.error('User ID is empty');
    }
  }

  Future<void> getEmergencyProfile1() async {
    try {
      profileResponse.value = ApiResponse.loading('Fetching data');
      final responseModel =
          await EmergencyServiceRepo().getEmergencyProfile();

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data['data'];
        if (data != null) {
          emergencyProfileData.value = EmergencyProfileModel.fromJson(data);
          profileResponse.value = ApiResponse.complete(responseModel);
        } else {
          profileResponse.value = ApiResponse.complete(responseModel);
        }
      } else {
        profileResponse.value = ApiResponse.error('Error');
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      profileResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
