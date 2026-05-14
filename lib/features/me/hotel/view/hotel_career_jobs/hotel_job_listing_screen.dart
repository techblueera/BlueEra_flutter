import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/view/all_job_post_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lists job posts belonging to a hotel business and (when not read-only)
/// surfaces a "create job" CTA pinned to the bottom of the screen.
class HotelJobListingScreen extends StatelessWidget {
  const HotelJobListingScreen({super.key, this.isReadOnly = false});

  final bool isReadOnly;

  /// Channel tag sent to the jobs feed so the backend / UI can scope results
  /// and tag newly-created posts as originating from the hotel flow.
  static const String _hotelVia = 'hotel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.jobs),
      bottomNavigationBar: isReadOnly ? null : _buildCreateJobButton(),
      body: AllJobPostScreen(
        key: const ValueKey(AppConstants.All),
        onHeaderVisibilityChanged: (_) {},
        headerHeight: 0,
        screenListingVia: _hotelVia,
      ),
    );
  }

  Widget _buildCreateJobButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 40),
        child: PositiveCustomBtn(
          bgColor: AppColors.white,
          textColor: AppColors.primaryColor,
          borderColor: AppColors.primaryColor,
          title: AppStrings.createJob,
          onTap: _openCreateJobScreen,
        ),
      ),
    );
  }

  void _openCreateJobScreen() {
    Get.toNamed(
      RouteHelper.getCreateJobPostScreenRoute(),
      arguments: {
        'isEditMode': false,
        ApiKeys.jobId: '',
        'createJobVia': _hotelVia,
      },
    );
  }
}
