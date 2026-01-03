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
  }) {
    isFormValid.value = name.isNotEmpty &&
        email.isEmail &&
        phone.isNotEmpty &&
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

      // API Integration logic here
      // await yourApiService.post('education-service/faculty', body);

      print("Payload: $body");
      Get.back(); // Return after success
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}