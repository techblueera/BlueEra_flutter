// ignore_for_file: deprecated_member_use


import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class ProgressDialog {
  static var isOpen = false;

  static showProgressDialog(bool showDialog, {String? apiPath}) {
    if (showDialog) {
      if (Get.isDialogOpen != true) {
        isOpen = true;
        if (kDebugMode) {
          print('|--------------->🕙️ Loader start 🕑️<---------------|');
        }

        Get.dialog(
          barrierColor: AppColors.white,
          WillPopScope(
            onWillPop: () => Future.value(true),
            child: CircularIndicator(
              apiPath: apiPath,
            ),
          ),
          barrierDismissible: false, /*useRootNavigator: false*/
        );
      }
    } else if (Get.isDialogOpen == true) {
      if (kDebugMode) {
        print('|--------------->🕙️ Loader end 🕑️<---------------|');
      }
      Get.back();
      isOpen = false;
    }
  }

  static Widget onlyPaginationLoader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryColor, strokeWidth: 5)
          // child: Lottie.asset(AppConstants.appLoader, height: 150.h, width: 150.w, ),
          ),
    );
  }
}

class ShimmerListView extends StatelessWidget {
  const ShimmerListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(

      appBar: CommonBackAppBar(isLeading: false,),
      body: ListView.builder(
        itemCount: 6, // Number of shimmer items
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Shimmer.fromColors(
            baseColor:AppColors.greyE6,
            highlightColor: theme.scaffoldBackgroundColor,
            child: Container(
              height: 100,
              width: Get.width,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:AppColors.greyE6,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircularIndicator extends StatelessWidget {
  const CircularIndicator(
      {Key? key, this.isExpand, this.bgColor, this.loaderHeight, this.apiPath})
      : super(key: key);
  final bool? isExpand;
  final Color? bgColor;
  final double? loaderHeight;
  final String? apiPath;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Material(
      color: AppColors.white,
      child: Container(
        height: loaderHeight ?? Get.height,
        width: isExpand == false ? SizeConfig.buttonXL : Get.width,
        color: bgColor ?? AppColors.white,
        // color: bgColor ?? theme.colorScheme.secondary,
        child: ((apiPath?.contains("sent-otp") ?? false) ||
                (apiPath?.contains("verify-otp") ?? false)||
                (apiPath?.contains("getAllcategories") ?? false)||
                (apiPath?.contains("add-user") ?? false))
            ? ProgressDialog.onlyPaginationLoader()
            : const ShimmerListView(),
      ),
    );
  }
}
