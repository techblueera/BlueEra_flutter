import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/jobs/view/all_job_post_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

class FinanceJobListingScreen extends StatelessWidget {
  const FinanceJobListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.jobs),
      body: AllJobPostScreen(
        key: const ValueKey(AppConstants.All),
        onHeaderVisibilityChanged: (_) {},
        headerHeight: 0,
        screenListingVia: "other",
      ),
    );
  }
}
