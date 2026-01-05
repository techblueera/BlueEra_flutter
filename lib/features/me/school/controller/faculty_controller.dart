import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';

class FacultyController extends GetxController {
  // Loading & Validation State
  var isLoading = false.obs;
  var isFormValid = false.obs;

  // Dynamic Lists for the Form
  var qualifications = <String>[].obs;
  var researchInterests = <String>[].obs;
  var publications = <Map<String, dynamic>>[].obs;

  void validateFacultyForm({
    required String name,
    required String email,
    required String phone,
    required String posController,
  }) {
    isFormValid.value = name.isNotEmpty &&
        email.isEmail &&
        phone.isNotEmpty &&
        posController.isNotEmpty &&
        qualifications.isNotEmpty;
  }

  // Helper to add to lists
  void addQualification(String val) => qualifications.add(val);
  void addInterest(String val) => researchInterests.add(val);
  void removeQualification(int index) => qualifications.removeAt(index);

  Future<void> submitFacultyData({
    required String name,
    required String position,
    required String bio,
    required String email,
    required String phone,
    required int expYears,
    required String expDetails,
  }) async {
    try {
      isLoading.value = true;

      // Constructing the nested JSON payload
      Map<String, dynamic> body = {
        "school": schoolIDGlobal,
        "name": name,
        "position": position,
        "qualifications": qualifications.toList(),
        "experience": {
          "years": expYears,
          "details": expDetails
        },
        "email": email,
        "phone": phone,
        "photo": "https://example.com/photo.jpg", // Static or from picker
        "bio": bio,
        "researchInterests": researchInterests.toList(),
        "publications": publications.toList()
      };

      ResponseModel response = await SchoolRepo().addFacultyRepo(
          reqParm: body,
        );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data['message'] ?? AppStrings.successful);

      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      print("Payload: $body");
      Get.back(); // Return after success
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}