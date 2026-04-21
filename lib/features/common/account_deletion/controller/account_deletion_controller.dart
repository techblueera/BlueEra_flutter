import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/account_deletion/repo/account_deletion_repo.dart';
import 'package:BlueEra/features/common/auth/model/deletion_init_response_model.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDeletionController extends GetxController {
  final RxBool isLoading = false.obs;

  /// Entry point from Settings. Confirms, calls /init, and launches the
  /// deletion web flow in an in-app browser. All post-browser handling
  /// (401 → logout, login-side auto-cancel banner) lives elsewhere.
  Future<void> startAccountDeletion(BuildContext context) async {
    showCommonDialog(
      context: context,
      header: AppStrings.deleteAccount.tr,
      text: AppStrings.deleteAccountDialogBody.tr,
      confirmText: AppStrings.deleteAccountContinue.tr,
      cancelText: AppStrings.no.tr,
      confirmCallback: () async {
        Navigator.of(context).pop();
        await _initDeletion();
      },
      cancelCallback: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _initDeletion() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final ResponseModel response =
          await AccountDeletionRepo().initAccountDeletionRepo();

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
