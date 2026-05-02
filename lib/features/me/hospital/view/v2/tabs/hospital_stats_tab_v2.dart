import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:flutter/material.dart';

/// Stats tab for the redesigned hospital "me" profile.
///
/// The chat-click analytics endpoint that backs the medical statistics
/// screen is keyed by `businessId`, which is the same identifier we
/// already pass for hospital accounts (`userId`). Reusing the medical
/// screen here gives us the identical KPI cards + line charts + range
/// selector with zero divergence — when product evolves the design,
/// both surfaces stay in sync automatically.
class HospitalStatsTabV2 extends StatelessWidget {
  const HospitalStatsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalStatisticsScreen(businessId: userId);
  }
}
