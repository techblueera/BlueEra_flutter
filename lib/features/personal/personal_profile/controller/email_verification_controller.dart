import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:get/get.dart';

class EmailVerificationController extends GetxController {
  ApiResponse verifyEmailResponse = ApiResponse.initial('Initial');
  RxBool isVerifying = false.obs;
  RxBool isVerified = false.obs;

  // Method to verify email
  Future<void> verifyEmail(String email) async {
    try {
      isVerifying.value = true;

      // Get the user ID from shared preferences

      // Prepare the API endpoint with query parameters
      // final endpoint = 'user-service/user/verify-email?userId=$userId&email=${Uri.encodeComponent(email)}';

      final endpoint =
          'user-service/user/requestEmailVerification/${Uri.encodeComponent(email)}';

      // Make the POST request
      ResponseModel responseModel = await ApiBaseHelper().postHTTP(
        endpoint,
        showProgress: true,
        onError: (error) {
          print("Email verification failed: $error");
        },
        onSuccess: (res) {
          print("Email verification response: ${res.response?.data}");
        },
      );

      if (responseModel.isSuccess) {
        verifyEmailResponse = ApiResponse.complete(responseModel);
        isVerified.value = true;
        commonSnackBar(
          message: responseModel.response?.data?['message'] ??
              "Email verified successfully",
        );
      } else {
        isVerified.value = false;
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      isVerified.value = false;
      verifyEmailResponse = ApiResponse.error('Verification failed');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isVerifying.value = false;
    }
  }
}
