import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/social/model/social_contact_us_res_model.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:get/get.dart';

class SocialContactUsController extends GetxController {
  // Observables
  var isLoading = true.obs;
  var contactUsData = Rxn<SocialContactUsResModel>();

  @override
  void onInit() {
    super.onInit();
  }

  fetchHomeData() async {
    try {
      isLoading(true);

      // call repo
      ResponseModel responseModel =
          await SocialProfileRepo().getSocialContactByIdRepo();

      if (responseModel.isSuccess) {
        contactUsData.value =
            SocialContactUsResModel.fromJson(responseModel.response?.data);
      }
    } finally {
      isLoading(false);
    }
  }

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) {
    // Basic validation logic
    bool isValid = branchName.isNotEmpty &&
        website.isURL &&
        address.isNotEmpty &&
        email.isEmail &&
        phone.length >= 10;

    isFormValid.value = isValid;
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(
          message: "Please select a valid location from the search.");
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "name": branchName,
        "websiteUrl": website,
        "email": email,
        "phoneNo": phone,
        "location": {
          "name": address,
          "type": "Point",
          "coordinates": [selectedLat, selectedLng]
        }
      };

      ResponseModel response =
          await SocialProfileRepo().addSocialContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details added successfully");
        Get.back();
        fetchHomeData();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      print("Request Body: $body");
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
}
