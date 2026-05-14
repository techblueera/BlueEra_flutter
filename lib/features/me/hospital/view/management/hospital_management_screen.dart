import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_management_controller.dart';
import 'package:BlueEra/features/me/hospital/model/management_member_model.dart';
import 'package:BlueEra/features/me/hospital/view/management/management_form_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalManagementScreen extends StatefulWidget {
  const HospitalManagementScreen({super.key});

  @override
  State<HospitalManagementScreen> createState() =>
      _HospitalManagementScreenState();
}

class _HospitalManagementScreenState extends State<HospitalManagementScreen> {
  late final HospitalManagementController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HospitalManagementController());
  }

  void _openForm() => Get.to(const ManagementFormScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.managementTrust,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () {
              controller.startCreate();
              _openForm();
            },
            child: Container(
              height: 36,
              width: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                AppStrings.addedMembers,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (controller.members.isEmpty) {
          return Center(child: CustomText(AppStrings.nodata));
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: 50,
            right: SizeConfig.paddingM,
            left: SizeConfig.paddingM,
            top: SizeConfig.paddingM,
          ),
          child: ListView.builder(
            itemCount: controller.members.length,
            itemBuilder: (context, index) =>
                _buildMemberCard(context, controller.members[index]),
          ),
        );
      }),
    );
  }

  Widget _buildMemberCard(BuildContext context, ManagementMember member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (member.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      member.imageUrl,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        member.name,
                        fontSize: SizeConfig.size18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      CustomText(member.position, color: AppColors.black28),
                      if (member.education.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          member.education,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                ),
                _buildPopupMenu(context, member),
              ],
            ),
            if (member.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              CustomText(
                member.description,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, ManagementMember member) {
    return PopupMenuButton<String>(
      child: const Icon(Icons.more_vert, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "EDIT",
          onTap: () {
            controller.startEdit(member);
            // PopupMenu plays a close animation; let it finish before
            // pushing the next route to avoid a janky transition.
            Future.delayed(const Duration(milliseconds: 100), _openForm);
          },
          child: CustomText(AppStrings.edit),
        ),
        const PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Divider(height: 1),
        ),
        PopupMenuItem(
          value: "DELETE",
          height: 15,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              commonConformationDialog(
                context: context,
                text: AppStrings.deleteMemberConfirm,
                confirmCallback: () async {
                  Get.back();
                  await controller.deleteMember(member);
                },
                cancelCallback: Get.back,
              );
            });
          },
          child: CustomText(AppStrings.delete),
        ),
      ],
    );
  }
}
