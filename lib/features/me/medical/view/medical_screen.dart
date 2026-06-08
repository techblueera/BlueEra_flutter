import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/common/statistics/controller/profile_statistics_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_home_screen_v2.dart';
import 'package:BlueEra/features/me/medical/controller/user_medical_controller.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:flutter/material.dart';

class MedicalScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const MedicalScreen({super.key, this.fromBottomNavBar});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  @override
  void dispose() {
    deleteIfRegistered<MedicalController>();
    deleteIfRegistered<UserMedicalController>();
    deleteIfRegistered<ProfileStatisticsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Home/Statistics tabs are now part of MedicalHomeScreenV2's own
    // real tab bar (it carries a "Stats" tab), so this screen renders it
    // directly — no redundant outer TabBarView.
    return Scaffold(
      body: SafeArea(
        child: BottomNavHideOnScroll(
          child: MedicalHomeScreenV2(businessId: userId),
        ),
      ),
    );
  }
}
