import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/account_deletion/repo/account_deletion_repo.dart';
import 'package:BlueEra/features/common/auth/model/deletion_init_response_model.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDeletionController extends GetxController {
  final RxBool isLoading = false.obs;

  /// Entry point from Settings. Shows a confirm dialog whose "Continue" button
  /// carries an inline loader (and a dim full-screen veil, like the OTP screen)
  /// while `/init` runs; on success it launches the deletion web flow in an
  /// in-app browser. All post-browser handling (401 → logout, login-side
  /// auto-cancel banner) lives elsewhere.
  Future<void> startAccountDeletion(BuildContext context) async {
    Get.dialog(
      Obx(() {
        final loading = isLoading.value;
        return Dialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: Get.width,
                    color: AppColors.primaryColor,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                    child: CustomText(
                      AppStrings.deleteAccount.tr,
                      color: Colors.white,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: CustomText(
                      AppStrings.deleteAccountDialogBody.tr,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomBtn(
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryColor,
                            textColor: AppColors.primaryColor,
                            isLoading: loading,
                            onTap: _initDeletion,
                            title: AppStrings.deleteAccountContinue.tr,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: PositiveCustomBtn(
                            // Can't cancel mid-request.
                            onTap: loading ? () {} : () => Get.back(),
                            title: AppStrings.no.tr,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size15),
                ],
              ),
            ),
          ),
        );
      }),
      barrierDismissible: false,
      // Slight full-screen black veil behind the dialog while it's up —
      // matches the OTP screen's in-flight overlay.
      barrierColor: Colors.black.withValues(alpha: 0.2),
    );
  }

  Future<void> _initDeletion() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final ResponseModel response =
          await AccountDeletionRepo().initAccountDeletionRepo();

      // Close the confirm dialog before routing / launching the browser.
      if (Get.isDialogOpen ?? false) Get.back();

      switch (response.statusCode) {
        case 200:
          final parsed = DeletionInitResponseModel.fromJson(
            response.response?.data is String
                ? jsonDecode(response.response!.data)
                : response.response?.data,
          );
          final url = parsed.deletionUrl;
          if (url == null || url.isEmpty) {
            commonSnackBar(message: AppStrings.somethingWentWrong);
            return;
          }
          await _launchDeletionUrl(url);
          break;
        case 409:
          commonSnackBar(message: AppStrings.accountDeletionAlreadyPending.tr);
          break;
        case 429:
          commonSnackBar(message: AppStrings.accountDeletionRateLimited.tr);
          break;
        case 503:
          final ctx = Get.context;
          if (ctx != null) {
            showCommonDialog(
              context: ctx,
              text: AppStrings.accountDeletionFeatureDisabled.tr,
              confirmText: '',
              cancelText: AppStrings.ok.tr,
              confirmCallback: () {},
              cancelCallback: () => Navigator.of(ctx).pop(),
            );
          } else {
            commonSnackBar(
                message: AppStrings.accountDeletionFeatureDisabled.tr);
          }
          break;
        default:
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
      }
    } catch (e, s) {
      if (Get.isDialogOpen ?? false) Get.back();
      log('AccountDeletionController error: $e\n$s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _launchDeletionUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        final fallback = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!fallback) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } catch (e) {
      log('launchDeletionUrl error: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
