import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_statistics_view.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_tab_scroll.dart';
import 'package:flutter/material.dart';

/// **Statistics tab** of the rider dashboard — the rider's own earnings and
/// performance dashboard.
///
/// This used to be `ProfileStatisticsScreen` + `EarnStatSections`: profile-view
/// and chat-click analytics borrowed from the grocery / medical / self-employed
/// dashboards. Those measure a shopfront, which is not what a rider has — a
/// rider is measured on money earned, rides done, and the acceptance /
/// cancellation / rating scores that decide how much work they are offered. See
/// [RiderStatisticsView] and docs/backend/RIDER_STATISTICS_API_GUIDE.md.
class RiderStaticsTab extends StatelessWidget {
  const RiderStaticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RiderTabScroll(
      children: [
        const RiderStatisticsView(),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }
}
