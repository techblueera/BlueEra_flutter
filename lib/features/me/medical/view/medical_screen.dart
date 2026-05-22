import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/common/statistics/controller/business_statistics_controller.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/medical/view/medical_home_screen_v2.dart';
import 'package:BlueEra/features/common/statistics/view/business_statistics_screen.dart';
import 'package:BlueEra/features/me/medical/controller/user_medical_controller.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const MedicalScreen({super.key, this.fromBottomNavBar});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController searchController = TextEditingController();
  final List<Tab> _tabs = [
    Tab(text: AppStrings.home.tr),
    Tab(text: AppStrings.statistics.tr),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    MeTabRegistry.register(_tabController!);
  }

  @override
  void dispose() {
    if (_tabController != null) MeTabRegistry.unregister(_tabController!);
    _tabController?.dispose();
    deleteIfRegistered<MedicalController>();
    deleteIfRegistered<UserMedicalController>();
    deleteIfRegistered<BusinessStatisticsController>();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BottomNavHideOnScroll(
          child: TabBarView(
            controller: _tabController,
            children: [
              MedicalHomeScreenV2(businessId: userId),
              BusinessStatisticsScreen(businessId: userId),
            ],
          ),
        ),
      ),
    );
  }

}
