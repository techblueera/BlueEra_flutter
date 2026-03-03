import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/features/me/social/view/social_home_screen.dart';
import 'package:BlueEra/features/me/social/view/social_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class SocialMainScreen extends StatefulWidget {
  const SocialMainScreen({
    super.key,
  });

  @override
  State<SocialMainScreen> createState() => _SocialMainScreenState();
}

class _SocialMainScreenState extends State<SocialMainScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        body: SafeArea(
            child: Column(
      children: [
        SizedBox(
          height: SizeConfig.size12,
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.secondaryTextColor,
          indicatorColor: AppColors.primaryColor,
          indicatorWeight: 4,
          tabAlignment: TabAlignment.fill,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppStrings.home.tr),
            Tab(text: AppStrings.update.tr),
            Tab(text: AppStrings.statistics.tr),
          ],
        ),
        Expanded(
            child: TabBarView(
          controller: _tabController,
          children: [
            // PersonalProfileSetupNewScreen(),
            SocialHomeScreen(),
            SocialUpdateScreen(),
            ComingSoon(),
          ],
        ))
      ],
    )));
  }
}
