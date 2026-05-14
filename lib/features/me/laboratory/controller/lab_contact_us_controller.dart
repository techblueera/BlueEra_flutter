import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/social/model/social_contact_us_res_model.dart';
import 'package:get/get.dart';

/// Manages the laboratory's branch / reception contact: load + create.
class LabContactUsController extends GetxController {
  final LabServiceRepo _repo = LabServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rxn<SocialContactUsResModel> contactUsData =
      Rxn<SocialContactUsResModel>();

  /// Form validity for the submit button.
  final RxBool isFormValid = false.obs;

  /// Coordinates from the location-picker on the branch form.
  double? selectedLat;
  double? selectedLng;

  // ---- Validation ----------------------------------------------------------

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\.]{3,50}$");
  static final RegExp _gmailRegex = RegExp(r'^[\w-\.]+@gmail\.com$');

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) {
    isFormValid.value = _nameRegex.hasMatch(branchName.trim()) &&
        (website.isEmpty || website.isURL) &&
        address.isNotEmpty &&
        _gmailRegex.hasMatch(email.trim()) &&
        phone.length >= 10;
  }

  // ---- API -----------------------------------------------------------------

  Future<void> fetchHomeData() async {
    try {
      isLoading.value = true;
      final ResponseModel response = await _repo.getSocialContactByIdRepo();
      if (response.isSuccess) {
        contactUsData.value =
            SocialContactUsResModel.fromJson(response.response?.data);
      }
    } catch (e) {
      logs("LabContactUsController.fetchHomeData ERROR $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(message: AppStrings.hotelSelectValidLocation.tr);
      return;
    }

    try {
      isSaving.value = true;
      final body = <String, dynamic>{
        "name": branchName,
        "websiteUrl": website,
        "email": email,
        "phoneNo": phone,
        "location": {
          "name": address,
          "type": "Point",
          "coordinates": [selectedLat, selectedLng],
        },
        "laboratoryId": labIDGlobal,
      };

      final ResponseModel response =
          await _repo.addSocialContactRepo(reqBody: body);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.hotelBranchAddedSuccess.tr);
        Get.back();
        await fetchHomeData();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("LabContactUsController.submitBranchDetails ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
