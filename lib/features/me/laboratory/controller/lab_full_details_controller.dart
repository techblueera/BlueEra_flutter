import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_full_details_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_profile_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// Top-level controller for the laboratory home screen. Holds the merged
/// `profile + tests + galleries + facility + health camps` payload and
/// handles the banner/logo upload flow used by [lab_header_view].
class LabFullDetailsController extends GetxController {
  final LabFullDetailsRepo _repo = LabFullDetailsRepo();
  final LabProfileRepo _repoProfile = LabProfileRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rxn<LabDetailsData> details = Rxn<LabDetailsData>();

  Future<void> fetchFullDetails() async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getFullDetailsByUser();
      if (res.isSuccess) {
        details.value =
            LabFullDetailsResModel.fromJson(res.response?.data).data;
      } else {
        logs("LabFullDetailsController.fetchFullDetails: ${res.message}");
      }
    } catch (e) {
      logs("LabFullDetailsController.fetchFullDetails ERROR $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Uploads a banner/logo to S3 then patches the lab profile with the
  /// resulting URL. [uploadVia] is the JSON field to populate (e.g.
  /// `coverUrl` or `logoUrl`).
  Future<void> uploadSchoolLogoOrBannerImage({
    required File uploadFile,
    required String uploadVia,
  }) async {
    try {
      isSaving.value = true;
      final UploadResult result = await S3UploadService.uploadFile(uploadFile);
      if (!result.isSuccess) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }
      final ResponseModel response =
          await _repoProfile.postDescription({uploadVia: result.url});
      if (response.isSuccess) {
        commonSnackBar(message: response.message);
        await fetchFullDetails();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("LabFullDetailsController.uploadSchoolLogoOrBannerImage ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
