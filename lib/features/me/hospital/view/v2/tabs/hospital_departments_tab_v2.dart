import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/hospital_required_banner.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Departments tab — wraps the existing OPD/IPD booking widget so users
/// can manage doctors and wards from this section.
class HospitalDepartmentsTabV2 extends StatelessWidget {
  final HospitalServiceAiController controller;

  const HospitalDepartmentsTabV2({super.key, required this.controller});

  /// Mirrors the school Quick Info gate (`SchoolOverviewTabV2`): departments
  /// are treated as mandatory profile data. Whenever the hospital record
  /// carries no departments the section prepends a nudge banner above the
  /// existing add form.
  ///
  /// A named-but-empty department (chip only, no doctors and no beds) does
  /// NOT count as data — otherwise the banner disappears the moment the
  /// user picks a department name, leaving the OPD/IPD sections showing
  /// "No Data found" with no top-level nudge to finish the job. Matches
  /// the overview-tab detector.
  bool _hasDepartments(HospitalFullData? data) {
    if (data == null) return false;
    return (data.departments ?? [])
        .any((d) => ((d.opd ?? []).isNotEmpty) || ((d.ipd ?? []).isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size10),
          // Contribution / Bank / Refer deck. No catalog card here: this tab IS
          // the add surface and carries its own add masthead, so a card pointing
          // at the screen you are already on would be noise.
          OrderActionsCarousel(),

          Obx(() {
            final data = controller.hospitalDataResModel?.value.data;
            if (_hasDepartments(data)) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(
                top: SizeConfig.size10,
                bottom: SizeConfig.size12,
              ),
              child: const HospitalRequiredBanner(
                heading: 'Departments are required',
                message:
                    'Please add at least one OPD or IPD department. This section is mandatory to complete your hospital profile.',
              ),
            );
          }),
          SizedBox(height: SizeConfig.size10),
          HospitalBookingScreen(isReadOnly: false),
        ],
      ),
    );
  }
}
