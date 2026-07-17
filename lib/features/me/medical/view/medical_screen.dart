import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/statistics/controller/profile_statistics_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_home_screen_v2.dart';
import 'package:BlueEra/features/me/medical/controller/user_medical_controller.dart';
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
    // MedicalController deliberately NOT deleted here.
    //
    // It owns the Products tab's lists and their FetchCache stamp, so tearing
    // it down on every exit meant re-entering the Me → Medical tab always
    // refetched, however recently the data loaded. It also raced the
    // post-publish refresh: publishing pops back through here, and a deleted
    // controller refetches into an instance nobody reads.
    //
    // Cost of keeping it: the product lists (and any snap-search File refs)
    // stay in memory for the session. The 5-min TTL on the cache still forces
    // a refetch once the data is actually stale.
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
        child: MedicalHomeScreenV2(businessId: userId),
      ),
    );
  }
}
