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

class SelfEmployeeScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const SelfEmployeeScreen({
    super.key,
    this.fromBottomNavBar = false,
  });

  @override
  State<SelfEmployeeScreen> createState() => _SelfEmployeeScreenState();
}

class _SelfEmployeeScreenState extends State<SelfEmployeeScreen> {
  final controller = Get.find<ViewPersonalDetailsController>();

  @override
  Widget build(BuildContext context) {
    return SelfEmployeeDashboardView(
      fromBottomNavBar: widget.fromBottomNavBar,
    );
  }
}
