import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/controller/staff_controller.dart';
import 'package:BlueEra/features/me/others/model/staff_model.dart';
import 'package:BlueEra/features/me/automotive_service/view/staff/staff_form_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AutomotiveStaffController());

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherStaffsTitle.tr,
        isLeading: true,
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: controller.staffList.isNotEmpty
                  ? ListView.separated(
                      padding: EdgeInsets.all(SizeConfig.size15),
                      itemCount: controller.staffList.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: SizeConfig.size15),
                      itemBuilder: (context, index) {
                        final item = controller.staffList[index];
                        return _buildStaffCard(context, controller, item);
                      },
                    )
                  : Center(child: CustomText(AppStrings.otherNoStaffFound.tr)),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: SizeConfig.size35, right: 20, left: 20),
                child: AddMoreIconButton(onTapEvent: () {
                  controller.clearForm();
                  Get.to(() => StaffFormScreen());
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStaffCard(BuildContext context,
      AutomotiveStaffController controller, StaffData item) {
    String dateRange = "";
    try {
      if (item.joinedFrom != null) {
        final fromDate = DateTime.parse(item.joinedFrom!);
        final fromStr = DateFormat('d MMM, yyyy').format(fromDate);
        
        String toStr = AppStrings.present.tr;
        if (item.joinedTo != null) {
          final toDate = DateTime.parse(item.joinedTo!);
           // Assuming if joinedTo is same as joinedFrom or some logic, but usually it's a range.
           // However, if joinedTo is present, format it.
           // User snippet showed: "1st, Jan, 2024 - Present"
           // If joinedTo is null or equal to some default, maybe it's present?
           // The API response example showed joinedFrom and joinedTo having same value in one case, 
           // but typically logic is: if joinedTo is null -> Present.
           // The controller logic I wrote: if joinedTo is null -> Present.
           
           // If joinedTo is available, use it.
           toStr = DateFormat('d MMM, yyyy').format(toDate);
        } else {
           toStr = AppStrings.present.tr;
        }
        
        // However, if the user explicitly checked "Present", the API might send null or omitted joinedTo.
        // Or if the backend sends joinedTo same as joinedFrom for "Present"? No, that would be weird.
        // Let's assume null joinedTo means Present.
        
        if (item.joinedTo == null) {
          toStr = AppStrings.present.tr;
        }
        
        dateRange = "$fromStr - $toStr";
      }
    } catch (e) {
      dateRange = "N/A";
    }

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                          width: 24, 
                          height: 24, 
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            splashRadius: 20,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'Edit') {
                                controller.setFormData(item);
                                Get.to(() => StaffFormScreen());
                              } else if (value == 'Delete') {
                                commonConformationDialog(
                                  context: context,
                                  text:
                                      AppStrings.otherConfirmDeleteStaff.tr,
                                  confirmCallback: () {
                                    Get.back();
                                    controller.deleteStaff(item.sId ?? "");
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
                     if (dateRange.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: CustomText(
                          dateRange,
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
        ],
      ),
    );
  }
}
