import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professionals_contact_us_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:get/get.dart';

class ProfessionalsController extends GetxController {
  // Observables
  var isLoading = true.obs;
  var contactUsData = Rxn<ProfessionalsContactUsModel>();

  @override
  void onInit() {
    fetchHomeData();
    super.onInit();
  }

   fetchHomeData() async {
    try {
      isLoading(true);

      // call repo
      ResponseModel responseModel =
          await ProfessionalsRepo().getProfessionalByIdRepo();

      if (responseModel.isSuccess) {
        contactUsData.value =
            ProfessionalsContactUsModel.fromJson(responseModel.response?.data);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
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
        "contactPerson": branchName,
        "website": website,
        "email": email,
        "phone": phone,
        "address": address,
        "coordinates": [selectedLat, selectedLng]
      };

      ResponseModel response =
          await ProfessionalsRepo().addProfessionalContactRepo(reqBody: body);
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
