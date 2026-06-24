import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/widgets/business_profile_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/view_business_details_controller.dart';

class BusinessOwnProfileScreen extends StatefulWidget {
  final int? selectedIndex;
  final SortBy? sortBy;
  final String? isScreenFrom;

  const BusinessOwnProfileScreen(
      {super.key, this.selectedIndex, this.sortBy, this.isScreenFrom});

  @override
  State<BusinessOwnProfileScreen> createState() =>
      _BusinessOwnProfileScreenState();
}

class _BusinessOwnProfileScreenState extends State<BusinessOwnProfileScreen> {
  final viewProfileController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  @override
  void initState() {
    ///GET PROFILE API CALLING...
    viewProfileController.viewBusinessProfile();
    viewProfileController.getAllCategories();
    // Deep-link from the `business_go_live_reminder` notification: auto-prompt
    // go-live once the profile is on screen.
    final args = Get.arguments;
    if (args is Map && args['open_go_live'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewProfileController.goLiveNow();
      });
    }
    super.initState();
  }

  backClick() {
    if (widget.isScreenFrom == AppConstants.deepLinkScreen) {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: 1},
      );
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        backClick();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CommonBackAppBar(
          isLeading: true,
          isLogout: true,
          title: AppStrings.yourBusinessProfile,
          showRightTextButton: true,
          rightTextButtonText: 'Setup',
          rightTextButtonColor: AppColors.primaryColor,
          onRightTextButtonTap: () {
            Get.toNamed(
              RouteHelper.getBusinessOnboardingCategoryScreenRoute(),
            );
          },
          onBackTap: (){
            backClick();
          },
        ),
        body: SingleChildScrollView(
          child: BusinessProfileScreen(
            selectedIndex: widget.selectedIndex,
            sortBy: widget.sortBy,
          ),
        ),
      ),
    );
  }
}
