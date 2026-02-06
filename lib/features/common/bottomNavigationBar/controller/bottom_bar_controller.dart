import 'dart:developer';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

import '../../auth/model/adminvideo_model.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;
  void onChangeIndex(int index) => currentIndex.value = index;
// already existing controller
  final RxBool adminVideoLoading = false.obs;
  final RxList<AdminVideo> adminVideos = <AdminVideo>[].obs;

List<CategoryData> businessCategoriesList = [];


  Future<void> fetchAllAdminVideoApiMenu() async {
    try {
      adminVideoLoading.value = true;

      final res = await ChannelRepo().fetchAllAdminVideoRepo(
        queryParams: {},
      );

      if (res.isSuccess) {
        // ✅ correct response model
        final response =
        AdminVideoResponse.fromJson(res.response?.data);

        adminVideos.clear();
        adminVideos.addAll(response.data ?? []);
      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
      log('[fetchAllAdminVideoApiMenu] $e');
    } finally {
      adminVideoLoading.value = false;
    }
  }
}