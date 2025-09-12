import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/business/widgets/business_profile_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/view_business_details_controller.dart';

class BusinessOwnProfileScreen extends StatefulWidget {
  final int? selectedIndex;
  final SortBy? sortBy;
  const BusinessOwnProfileScreen({super.key, this.selectedIndex, this.sortBy});

  @override
  State<BusinessOwnProfileScreen> createState() =>
      _BusinessOwnProfileScreenState();
}

class _BusinessOwnProfileScreenState extends State<BusinessOwnProfileScreen> {
  final viewProfileController = Get.put(ViewBusinessDetailsController());

  @override
  void initState() {
    ///GET PROFILE API CALLING...
    viewProfileController.viewBusinessProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        isLeading: true,
        isLogout: true,
        title: "Your Business Profile",
      ),
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   Get.to(PaySubscription());
      // }),
      body: SingleChildScrollView(
        child: BusinessProfileScreen(
          selectedIndex: widget.selectedIndex,
          sortBy: widget.sortBy,
        ),
      ),
    );
  }
}
