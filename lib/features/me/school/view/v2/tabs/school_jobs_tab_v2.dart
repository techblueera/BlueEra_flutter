import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/view/all_job_post_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Jobs tab for the school "me" profile.
///
/// Reuses the existing [AllJobPostScreen] body scoped to
/// `screenListingVia: "education"` — the same widget rendered by
/// `SchoolJobListingScreen`, minus its Scaffold/AppBar since this tab
/// already lives inside [HomeTabScaffold]. A right-aligned "Create Job"
/// pill on top routes to the standard create-job-post flow with
/// `createJobVia: "education"`.
class SchoolJobsTabV2 extends StatelessWidget {
  const SchoolJobsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size10,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(
                RouteHelper.getCreateJobPostScreenRoute(),
                arguments: {
                  'isEditMode': false,
                  'jobId': '',
                  'createJobVia': 'education',
                },
              ),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: CustomText(
                AppStrings.createJob.tr,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        // AllJobPostScreen manages its own scroll + fetch on init, so it
        // takes the remaining height directly rather than nesting under
        // the tab's SingleChildScrollView wrapper.
        Expanded(
          child: AllJobPostScreen(
            key: const ValueKey('school_v2_jobs'),
            onHeaderVisibilityChanged: (_) {},
            headerHeight: 0,
            screenListingVia: 'education',
          ),
        ),
      ],
    );
  }
}
