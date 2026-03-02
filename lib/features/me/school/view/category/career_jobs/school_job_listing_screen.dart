import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/view/all_job_post_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolJobListingScreen extends StatefulWidget {
   SchoolJobListingScreen({super.key, required this.isEdit});
  final bool isEdit;

  @override
  State<SchoolJobListingScreen> createState() => _SchoolJobListingScreenState();
}

class _SchoolJobListingScreenState extends State<SchoolJobListingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title:AppStrings.jobs,
      ),
      bottomNavigationBar: (widget.isEdit) ?
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
              right: 10.0, left: 10.0, bottom: 40, top: 10),
          child: PositiveCustomBtn(
              bgColor: AppColors.white,
              textColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
              onTap: () {
                Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(),
                    arguments: {
                      'isEditMode': false,
                      'jobId': '',
                      'createJobVia': 'education',
                    });
              },
              title: AppStrings.createJob),
        ),
      ):null,

      body: AllJobPostScreen(
        key: ValueKey(AppConstants.All),
        onHeaderVisibilityChanged: (val){},
        headerHeight: 0,screenListingVia: "education",
      ),
    );
  }
}
