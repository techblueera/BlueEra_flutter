import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:flutter/material.dart';

/// Stats tab for the redesigned hotel "me" profile.
///
/// Reuses `ProfileStatisticsScreen` (chat-click analytics keyed by
/// `businessId == userId`) so the hotel surface gets the same KPI
/// cards + line charts + range selector with no divergence.
class HotelStatsTabV2 extends StatelessWidget {
  const HotelStatsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileStatisticsScreen(userId: userId);
  }
}
