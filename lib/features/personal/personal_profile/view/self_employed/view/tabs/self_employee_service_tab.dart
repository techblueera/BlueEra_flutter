import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_profession_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/tabs/self_employee_tab_scroll.dart';
import 'package:flutter/material.dart';

/// **Service tab** of the self-employed dashboard — the provider's own service
/// listings, go-live state and enquiry entry points.
///
/// Extracted from `SelfEmployeeScreen` with the other two tabs: that screen was
/// a single 1,100-line State class where the identity dossier and the service
/// listings shared one file.
class SelfEmployeeServiceTab extends StatelessWidget {
  const SelfEmployeeServiceTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Promo strip appended INSIDE this tab's own scroll — see the note in
    // [RiderOrderTab]; this screen also hands its tabs to HomeTabScaffold
    // directly, so the wrap belongs here.
    return SelfEmployeeTabScroll(
      child: withQurekaPromoBelow(const SelfProfessionServiceScreen()),
    );
  }
}
