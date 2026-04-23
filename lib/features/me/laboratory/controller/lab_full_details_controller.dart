import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_full_details_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_profile_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class LabFullDetailsController extends GetxController {
  final LabFullDetailsRepo _repo = LabFullDetailsRepo();
  final LabProfileRepo _repoProfile = LabProfileRepo();

  var isLoading = false.obs;
  Rxn<LabDetailsData> details = Rxn<LabDetailsData>();

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchFullDetails() async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.getFullDetailsByUser();
      if (res.isSuccess) {
        final parsed = LabFullDetailsResModel.fromJson(res.response?.data);
        details.value = parsed.data;
      }
    } catch (e) {
      // commonSnackBar(message: "Error fetching full details: $e");
    } finally {
      isLoading.value = false;
    }
  }

  uploadSchoolLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response =
            await _repoProfile.postDescription({uploadVia: result.url});
        if (response.isSuccess) {
          commonSnackBar(message: response.message);
          fetchFullDetails();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);

      // TODO
    }
  }
}
