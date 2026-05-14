import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bootstraps a new laboratory record from the AI-generated profile data
/// captured during sign-up. The only consumer is the auth flow in
/// `auth_controller.dart`.
class LabServiceAiController extends GetxController {
  final LabServiceRepo _repo = LabServiceRepo();

  // ---- AI-generation form state --------------------------------------------

  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  final RxString labAddress = "".obs;

  /// Flips to `true` after [createLabServiceController] persists the lab.
  /// `laboratory_main` watches this to swap entry screens.
  final RxBool hasLabCreated = false.obs;

  final RxBool isSaving = false.obs;

  /// Resets every form field. Method name kept (typo: `clearFiled`) for
  /// parity with the hospital sibling — both are internal to their
  /// controllers.
  void clearFiled() {
    searchController.clear();
    websiteController.clear();
    labAddress.value = "";
  }

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    super.onClose();
  }

  Future<void> createLabServiceController({
    required Map<String, dynamic>? reqData,
  }) async {
    try {
      isSaving.value = true;
      final ResponseModel response =
          await _repo.createLabServiceRepo(reqBody: {"data": reqData});

      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.labServiceCreatedSuccess.tr);
        labAddress.value = "";
        final labID = response.response?.data['laboratoryId'] as String?;
        await setLabID(labID?.isNotEmpty == true ? labID! : "");
        await getLabID();
        hasLabCreated.value = true;
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      hasLabCreated.value = false;
      commonSnackBar(message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
