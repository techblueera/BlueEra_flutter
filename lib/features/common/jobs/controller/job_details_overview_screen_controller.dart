import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';


class JobDetailsOverviewController extends GetxController {

  JobRepo _repo = JobRepo();
  RxString name = "".obs;

  // Document upload properties
  RxString documentName = "".obs;
  RxString documentSize = "".obs;
  RxString uploadDateTime = "".obs;
  RxString? documentPath = "".obs;

  ///SUBMIT NEW JOB APPLICATION
  Future<void> submitNewJobApplicationApi({
    required  parameter,
  }) async {
    try {



      final response = await _repo.submitNewJobApplicationRepo(params: parameter);
      if (response.isSuccess) {
        showSuccessfulDialog();
        commonSnackBar(message: response.message ?? AppStrings.success);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  String? userID;

  // Reactive text controllers
  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString cityState = ''.obs;
  final RxString phone = ''.obs;



  // Method to update document details
  void updateDocumentDetails({
    required String name,
    required String size,
    required String dateTime,
    String? path,
  }) {
    documentName.value = name;
    documentSize.value = size;
    uploadDateTime.value = dateTime;
    documentPath?.value = path ?? "";
  }

  // Method to clear document details
  void clearDocumentDetails() {
    documentName.value = "";
    documentSize.value = "";
    uploadDateTime.value = "";
    documentPath?.value = "";
  }

  @override
  void onClose() {

    super.onClose();
  }


  void showSuccessfulDialog() {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.white, // Inner background color
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(blurRadius: 20, color: AppColors.black25)]),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ICON
              SvgPicture.asset(AppIconAssets.illustrationIcon),

              SizedBox(height: SizeConfig.size18),

              // Title
              CustomText(
                "Successful!",
                textAlign: TextAlign.center,
                color: AppColors.black28,
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: SizeConfig.size10),
              CustomText(
                "Congratulations, your application has been sent",
                textAlign: TextAlign.center,
                color: AppColors.black28,
                fontSize: SizeConfig.medium,
              ),

              SizedBox(height: SizeConfig.size18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                        height: SizeConfig.size40,
                        title: 'Home',
                        onTap: () {
                          Get.offAllNamed(
                            RouteHelper.getBottomNavigationBarScreenRoute(),
                            arguments: {ApiKeys.initialIndex: 3},
                          );
                        },
                        borderColor: AppColors.primaryColor,
                        bgColor: AppColors.white,
                        textColor: AppColors.primaryColor),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: CustomBtn(
                        height: SizeConfig.size40,
                        title: 'Connect',
                        onTap: () {
                          Get.offAllNamed(
                            RouteHelper.getBottomNavigationBarScreenRoute(),
                            arguments: {ApiKeys.initialIndex: 1},
                          );
                        },
                        borderColor: AppColors.primaryColor,
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
