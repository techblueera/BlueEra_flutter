import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/add_self_work_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum EarnServiceTypes {
  selfWork('selfWork'),
  homeService('homeService'),
  homeMadeFood('homeMadeFood');

  final String label;
  const EarnServiceTypes(this.label);

  static EarnServiceTypes? fromLabel(String value) {
    return EarnServiceTypes.values.firstWhere(
          (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => EarnServiceTypes.selfWork, // default if not matched
    );
  }

  static List<String> get labels =>
      EarnServiceTypes.values.map((e) => e.label).toList();
}


class EarnServiceScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const EarnServiceScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<EarnServiceScreen> createState() => _EarnServiceScreenState();
}

class _EarnServiceScreenState extends State<EarnServiceScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final controller = Get.find<ViewPersonalDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      if(controller.isEarnServiceOpt.value.isEmpty){
        return _buildLoadingScaffold();
      }

      if(controller.isEarnServiceOpt.value == 'false'){
        return AddSelfServiceScreen(
          fromBottomNavBar: widget.fromBottomNavBar,
          designation: userProfessionGlobal,
          serviceSubType: EarnServiceTypes.selfWork,
        );
      }

      return EarnServiceDashboardView(
          fromBottomNavBar: widget.fromBottomNavBar
      );
    });
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: !widget.fromBottomNavBar,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }



}
