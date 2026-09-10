import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/automotive_business_profile_full_controller.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/automotive_home_screen_v2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Entry screen for the "Special Automotive" sub-categories:
///   - VEHICLE_SERVICE
///   - TRANSPORT_LOGISTIC
///   - VEHICLE_SUPPORT
///
/// This is a structural twin of `OthersMain` — the UI is identical
/// today, but every controller / view / widget it touches now lives in
/// `lib/features/me/automotive_service/` so the screen can diverge in
/// the future without rippling into the generic `OthersMain` tree
/// (which is still used by Finance, Service, and the Healthcare
/// SUPPORT_SERVICES sub-category).
///
/// Models and the repository layer are *intentionally* still shared
/// with the others module (`features/me/others/model/` and
/// `features/me/others/repo/other_repo.dart`) because they wrap the
/// backend contract, not the UI. Any API surface change continues to
/// land in one place.
class AutomotiveServiceMain extends StatefulWidget {
  const AutomotiveServiceMain({super.key});

  @override
  State<AutomotiveServiceMain> createState() => _AutomotiveServiceMainState();
}

class _AutomotiveServiceMainState extends State<AutomotiveServiceMain>
    with RouteAware {
  final controller = Get.put(AutomotiveBusinessProfileFullController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    _apiCalling();
  }

  Future<void> _apiCalling() async {
    await controller.getBusinessProfileFull();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Returned directly, with NO wrapper Scaffold: the app-wide themeable
    // background is painted by `GetMaterialApp.builder` (driven by
    // AppBackgroundController), and a Scaffold here would paint its own opaque
    // surface over it. Every Me home does the same — this is about the
    // background, not about what the business sells.
    return const AutomotiveHomeScreenV2();
  }
}
