import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:flutter/material.dart';

/// Stats tab for the redesigned school "me" profile.
///
/// Reuses `MedicalStatisticsScreen` (chat-click analytics keyed by
/// `businessId == userId`) so the school surface gets the same KPI
/// cards + line charts + range selector with no divergence.
class SchoolStatsTabV2 extends StatelessWidget {
  const SchoolStatsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalStatisticsScreen(businessId: userId);
  }
}
