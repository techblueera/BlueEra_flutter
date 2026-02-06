import 'dart:developer';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

import '../../auth/model/adminvideo_model.dart';

class ReferralController extends GetxController {


  Future<void> fetchMyReferralId() async {
    try {

      final res = await UserRepo().getMyReferralCodeApi();

      if (res.isSuccess) {
        log("My Referral Id  ${res.response?.data}");

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
    } finally {

    }
  }
  Future<void> getMyReferralHistoryApi() async {
    try {

      final res = await UserRepo().getMyReferralHistoryApi();

      if (res.isSuccess) {
        log("My Referral History  ${res.response?.data}");

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
    } finally {

    }
  }
}