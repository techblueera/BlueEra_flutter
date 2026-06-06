import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/other_home_screen_v2.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
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
  final controller = Get.put(BusinessProfileFullController());
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BottomNavHideOnScroll(
          child: OtherHomeScreenV2(),
        ),
      ),
    );
  }
}
