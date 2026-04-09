import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/home_made_food_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/tiffin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/add_self_work_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_dashboard_view.dart';
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


class SelfEmployeeScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  final int initialTabIndex;
  final int initialProductSubTab;
  const SelfEmployeeScreen({
    super.key,
    this.fromBottomNavBar = false,
    this.initialTabIndex = 0,
    this.initialProductSubTab = 0,
  });

  @override
  State<SelfEmployeeScreen> createState() => _SelfEmployeeScreenState();
}

class _SelfEmployeeScreenState extends State<SelfEmployeeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final controller = Get.find<ViewPersonalDetailsController>();
  final tiffinController = getOrPut(() => TiffinController());
  final homeMadeFoodController = getOrPut(() => HomeMadeFoodController());

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

      return SelfEmployeeDashboardView(
          fromBottomNavBar: widget.fromBottomNavBar,
          initialTabIndex: widget.initialTabIndex,
          initialProductSubTab: widget.initialProductSubTab,
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
