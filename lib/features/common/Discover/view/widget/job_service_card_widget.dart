import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobServiceCardWidget extends StatelessWidget {
  const JobServiceCardWidget({super.key});

  /// Every tile — and the folder itself — opens the jobs list; a guest gets the
  /// sign-up dashboard instead, which is why this is resolved on tap rather
  /// than built once.
  void _openJobs() {
    final Widget dest = isGuestUser() ? GuestDashBoardScreen() : JobsScreen();
    Get.to(() => dest);
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.jobNearMe.tr,
      items: jobCategories,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (item) => _openJobs(),
    );
  }
}
