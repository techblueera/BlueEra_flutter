import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:flutter/material.dart';

/// Stats tab for the redesigned lab "me" profile.
///
/// The chat-click analytics endpoint that backs the medical statistics
/// screen is keyed by `businessId` (== `userId`). Reusing the medical
/// screen here gives the lab the same KPI cards + line charts + range
/// selector with zero divergence.
class LabStatsTabV2 extends StatelessWidget {
  const LabStatsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalStatisticsScreen(businessId: userId);
  }
}
