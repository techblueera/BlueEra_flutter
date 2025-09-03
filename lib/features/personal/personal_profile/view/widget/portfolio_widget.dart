import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/experience_widget_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/overview_widget_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/project_widget_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/skill_widget_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PortfolioWidget extends StatefulWidget {
  const PortfolioWidget({super.key, required this.isSelfPortfolio});

  final bool isSelfPortfolio;

  @override
  State<PortfolioWidget> createState() => _PortfolioWidgetState();
}

class _PortfolioWidgetState extends State<PortfolioWidget> {
  final viewPersonaDetailsController =
      Get.find<ViewPersonalDetailsController>();
  final personalProfileController = Get.find<PersonalCreateProfileController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

          SizedBox(
            height: SizeConfig.size10,
          ),
          OverviewWidgetView(
            isSelfPortfolio: widget.isSelfPortfolio,
          ),

          SizedBox(
            height: SizeConfig.size10,
          ),
          SkillWidgetView(
            isSelfPortfolio: widget.isSelfPortfolio,
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          ProjectWidgetView(
            isSelfPortfolio: widget.isSelfPortfolio,
          ),


          SizedBox(
            height: SizeConfig.size10,
          ),
          ExperienceWidgetView(
            isSelfPortfolio: widget.isSelfPortfolio,
          ),

        SizedBox(
          height: SizeConfig.size10,
        ),
      ],
    );
  }
}
