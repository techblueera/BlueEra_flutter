import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart' show AppColors;
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/add_experience_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExperienceWidgetView extends StatelessWidget {
  ExperienceWidgetView({super.key, required this.isSelfPortfolio});

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
            "Experience",
            fontWeight: FontWeight.bold,
            fontSize: SizeConfig.medium15,
          ),
          SizedBox(height: 16),
          if (viewPersonaDetailsController.experiencesList?.isNotEmpty ??
              false) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount:
                  viewPersonaDetailsController.experiencesList?.length ?? 0,
              itemBuilder: (context, projectIndex) {
                Experiences experienceData =
                    viewPersonaDetailsController.experiencesList?[projectIndex] ??
                        Experiences();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            experienceData.companyName,
                            fontSize: SizeConfig.large,
                            color: AppColors.primaryColor,
                          ),
                          CustomText(experienceData.rolesAndResponsibility),
                        ],
                      ),
                    ),
                    if (isSelfPortfolio)
                      InkWell(
                          onTap: () {
                            commonConformationDialog(
                                context: context,
                                text:
                                    "Are you sure you want delete your experience?",
                                confirmCallback: () async {
                                  await Get.find<
                                          PersonalCreateProfileController>()
                                      .deleteExperienceDetails(
                                          experienceId: experienceData.sId);
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
          if ((viewPersonaDetailsController.experiencesList?.isEmpty ?? false)&&!isSelfPortfolio) ...[
            CustomText("No Experience found")
          ],
          if (isSelfPortfolio) ...[
            SizedBox(height: 16),
            PositiveCustomBtn(
                onTap: () {
                  Get.to(AddExperienceScreen(
                    isEdit: false,
                    // isEdit: false,
                  ));
                },
                title: "Add"),
          ],
        ],
      )),
    );
  }
}
