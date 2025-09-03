import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:get/get.dart';

class ProfileBioController extends GetxController {
  var name = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var location = ''.obs;

  var isLoading = false.obs;

  // Future<void> fetchBio() async {
  //   isLoading.value = true;
  //   try {
  //     final res = await ResumeRepo().getProfileBio(params: {});
  //     if (res.isSuccess) {
  //       final data = res.response?.data;
  //       name.value = data?['name'] ?? '';
  //       email.value = data?['email'] ?? '';
  //       phone.value = data?['phone'] ?? '';
  //       location.value = data?['location'] ?? '';
  //     } else {
  //       name.value = '';
  //       email.value = '';
  //       phone.value = '';
  //       location.value = '';
  //     }
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> updateProfile(Map<String, dynamic> params) async {
    try {
      final res = await ResumeRepo().updateProfile(params);
      if (res.isSuccess) {
        commonSnackBar(message: res.response?.data['message'] ?? "Updated successfully");
        // await fetchBio();
      } else {
        commonSnackBar(message: res.message ?? "Update failed");
      }
    } catch (e) {
      commonSnackBar(message: "Error updating profile");
    }
  }
}

