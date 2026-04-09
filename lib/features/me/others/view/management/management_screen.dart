import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/management_controller.dart';
import 'package:BlueEra/features/me/others/model/management_model.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_management_form_screen.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagementController());

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherManagementTitle.tr,
        isLeading: true,
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: controller.managementList.isNotEmpty
                  ? ListView.separated(
                      padding: EdgeInsets.all(SizeConfig.size15),
                      itemCount: controller.managementList.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: SizeConfig.size15),
                      itemBuilder: (context, index) {
                        final item = controller.managementList[index];
                        return _buildManagementCard(context, controller, item);
                      },
                    )
                  : Center(child: CustomText(AppStrings.otherNoManagementFound.tr)),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: SizeConfig.size35, right: 20, left: 20),
                child: AddMoreIconButton(onTapEvent: () {
                  controller.clearForm();
                  // _showFormDialog(context, controller);

                  Get.to(() => ManagementFormScreen());
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildManagementCard(BuildContext context,
      ManagementController controller, ManagementData item) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedAvatarWidget(
                  imageUrl: item.imageUrl ?? "",
                  size: SizeConfig.size80,
                  borderRadius: 0,
                  showProfileOnFullScreen: true,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomText(
                            item.name ?? "",
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.size16,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 24, // Control the exact width
                          height: 24, // Control the exact height
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            // Removes internal button padding
                            iconSize: 20,
                            // Adjust icon size to fit the box
                            splashRadius: 20,
                            // Controls the circular shadow on tap
                            constraints: const BoxConstraints(),
                            // Removes default min width/height
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'Edit') {
                                controller.setFormData(item);
                                Get.to(() => ManagementFormScreen());
                              } else if (value == 'Delete') {
                                commonConformationDialog(
                                  context: context,
                                  text:
                                      AppStrings.otherConfirmDeleteMember.tr,
                                  confirmCallback: () {
                                    Get.back();
                                    controller.deleteManagement(item.sId ?? "");
                                  },
                                  cancelCallback: () => Get.back(),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'Edit', child: Text(AppStrings.edit.tr)),
                              PopupMenuItem(
                                  value: 'Delete', child: Text(AppStrings.delete.tr)),
                            ],
                          ),
                        )
                      ],
                    ),
                    if (item.position != null && item.position!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: CustomText(
                          item.position ?? "N/A",
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.size12,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (item.qualification != null &&
                        item.qualification!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: CustomText(
                          item.qualification ?? "N/A",
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.size12,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size15),
          if (item.message != null && item.message!.isNotEmpty)
            ExpandableText(
              text:"NTo remove the extra padding that PopupMenuButton forces on its surroundings, you have to tackle two things: the Button Padding and the Minimum Hitbox size.",
              // text: item.message ?? "N/A",
              trimLines: 1,
              isReadMoreNewLine: false,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                fontFamily: AppConstants.OpenSans,
              ),
            )
          /*     else
                  InkWell(
                    onTap: () {
                      controller.setFormData(item);
                      Get.to(() => ManagementFormScreen());
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 14, color: AppColors.primaryColor),
                        SizedBox(width: 4),
                        CustomText(
                          "Add Message",
                          color: AppColors.primaryColor,
                          fontSize: SizeConfig.size12,
                        ),
                      ],
                    ),
                  )*/
        ],
      ),
    );
  }
}
