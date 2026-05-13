import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/rental_tab_body.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standalone host for [RentalTabBody]. The rider and cab dashboards
/// surface rentals as an Overview-tab CTA card instead of a top-level
/// tab — tapping that CTA pushes this screen, which provides the
/// AppBar + scroll axis that [RentalTabBody] needs to stand on its own
/// (when embedded as a tab, its parent CustomScrollView supplies both).
///
/// [RentalTabBody] internally uses a shrink-wrapped MasonryGridView
/// with [NeverScrollableScrollPhysics], so wrapping it in a
/// SingleChildScrollView is what gives this screen its scroll axis.
class RentalServicesDashboardScreen extends StatelessWidget {
  const RentalServicesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.rentalServices.tr,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: SizeConfig.size12,
            bottom: SizeConfig.size24,
          ),
          child: const RentalTabBody(),
        ),
      ),
    );
  }
}
