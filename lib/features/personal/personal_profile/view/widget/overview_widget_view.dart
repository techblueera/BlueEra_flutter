import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/create_overview_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OverviewWidgetView extends StatelessWidget {
  OverviewWidgetView({super.key, required this.isSelfPortfolio});

  final bool isSelfPortfolio;

  final viewPersonaDetailsController =
      Get.find<ViewPersonalDetailsController>();

  bool? isTextNotEmpty = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      isTextNotEmpty = viewPersonaDetailsController.overView.value.isNotEmpty;
      return SizedBox(
        width: Get.width,
        child: CommonCardWidget(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "OverView",
                    fontWeight: FontWeight.bold,
                    fontSize: SizeConfig.medium15,
                  ),
                  if (isSelfPortfolio == true)
                    Row(
                      children: [
                        InkWell(
                            onTap: () {
                              Get.to(CreateOverviewScreen(
                                isEdit:
                                    (isTextNotEmpty ?? false) ? true : false,
                                data: viewPersonaDetailsController
                                        .overView.value,
                              ));
                            },
                            child: LocalAssets(
                                imagePath: (isTextNotEmpty ?? false)
                                    ? AppIconAssets.pencilIcon
                                    : AppIconAssets.addBlueIcon)),
                        /*  if (isTextNotEmpty ?? false)
                        InkWell(
                            onTap: () async {
                              commonConformationDialog(
                                  context: context,
                                  text: "Are you sure you want delete?",
                                  confirmCallback: () async {
                                    await Get.find<
                                            PersonalCreateProfileController>()
                                        .updateUserProfileDetails(
                                      params: {
                                        ApiKeys.id: userId,
                                        ApiKeys.objective: ""
                                      },
                                    );
                                  },
                                  cancelCallback: () {
                                    Get.back();
                                  });
                            },
                            child:
                                LocalAssets(imagePath: AppIconAssets.deleteIcon,imgColor: Colors.red,)),*/
                      ],
                    )
                ],
              ),
              if ((isTextNotEmpty ?? false)) ...[
                SizedBox(
                  height: SizeConfig.size10,
                ),
                CustomText(viewPersonaDetailsController.overView.value)
              ],
              if (viewPersonaDetailsController.overView.value.isEmpty &&
                  !isSelfPortfolio) ...[
                SizedBox(
                  height: SizeConfig.size10,
                ),
                CustomText("No overview found")
              ],
            ],
          ),
        ),
      );
    });
  }
}
