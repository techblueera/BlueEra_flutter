import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_work_statistics_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/tabs/self_employee_tab_scroll.dart';
import 'package:flutter/material.dart';

/// **Statics tab** of the self-employed dashboard — a purpose-built
/// skilled-worker dashboard.
///
/// This used to be the generic `ProfileStatisticsScreen` (chat clicks + profile
/// visits) that every profile type shared, stacked with `EarnStatSections`
/// (per-earn-flavour "coming soon" placeholders). Both are gone: those two
/// numbers describe a *page*, and a self-employed account is a *trade* — an
/// electrician, plumber, tutor or gardener wants earnings, the enquiry funnel,
/// which of their services pay, their ratings, and how they compare with others
/// in the same trade nearby.
///
/// [SelfWorkStatisticsView] owns all of that, live off
/// `earn-service/self-work/statistics` — contract in
/// docs/backend/SELF_WORK_STATISTICS_API_GUIDE.md.
class SelfEmployeeStaticsTab extends StatelessWidget {
  const SelfEmployeeStaticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SelfEmployeeTabScroll(child: SelfWorkStatisticsView());
  }
}
