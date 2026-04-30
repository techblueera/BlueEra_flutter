import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_dashboard_view.dart';
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
