import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/view/contribution_plans_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

/// Full-screen contribution surface used by drawer menu / account-settings
/// entry points. Wraps [ContributionPlansView] in a Scaffold + back app bar.
class ContributionScreen extends StatelessWidget {
  const ContributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF8FF),
      appBar: CommonBackAppBar(
        title: 'Contribution',
        isLeading: true,
        showElevation: 0,
      ),
      body: SafeArea(
        child: ColoredBox(
          color: const Color(0xFFEEF8FF),
          child: Padding(
            padding: EdgeInsets.only(top: SizeConfig.size4),
            child: const ContributionPlansView(
              pinCta: true,
              showHeader: false,
            ),
          ),
        ),
      ),
    );
  }
}
