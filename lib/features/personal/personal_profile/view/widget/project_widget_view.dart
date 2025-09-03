import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/add_project_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectWidgetView extends StatelessWidget {
  ProjectWidgetView({super.key, required this.isSelfPortfolio});

  final bool isSelfPortfolio;

  final viewPersonaDetailsController =
      Get.find<ViewPersonalDetailsController>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: CommonCardWidget(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Project",
            fontWeight: FontWeight.bold,
            fontSize: SizeConfig.medium15,
          ),
          SizedBox(height: 16),
          if (viewPersonaDetailsController.projectsList?.isNotEmpty ?? false) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: viewPersonaDetailsController.projectsList?.length ?? 0,
              itemBuilder: (context, projectIndex) {
                Projects projectData =
                    viewPersonaDetailsController.projectsList?[projectIndex] ??
                        Projects();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            projectData.title,
                            fontSize: SizeConfig.large,
                            color: AppColors.primaryColor,
                          ),
                          CustomText(projectData.description),
                        ],
                      ),
                    ),
                    if (isSelfPortfolio)
                      InkWell(
                          onTap: () {
                            commonConformationDialog(
                                context: context,
                                text:
                                    "Are you sure you want delete this project?",
                                confirmCallback: () async {
                                  await Get.find<
                                          PersonalCreateProfileController>()
                                      .deleteProjectDetails(
                                          projectId: projectData.sId);
                                },
                                cancelCallback: () {
                                  Get.back();
                                });
                          },
                          child: LocalAssets(imagePath: AppIconAssets.deleteIcon))
                  ],
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider();
              },
            ),
          ],
          if ((viewPersonaDetailsController.projectsList?.isEmpty ?? false) &&
              !isSelfPortfolio) ...[CustomText("No Project found")],
          if (isSelfPortfolio) ...[
            SizedBox(height: 16),
            PositiveCustomBtn(
                onTap: () {
                  Get.to(AddProjectScreen(
                    isEdit: false,
                  ));
                },
                title: "add"),
          ],
        ],
      )),
    );
  }
}
