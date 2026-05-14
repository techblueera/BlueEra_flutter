import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_form_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_tag_pill.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthCampListScreen extends StatefulWidget {
  const HealthCampListScreen({super.key});

  @override
  State<HealthCampListScreen> createState() => _HealthCampListScreenState();
}

class _HealthCampListScreenState extends State<HealthCampListScreen> {
  late final HealthCampController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HealthCampController>()) {
      controller = Get.put(HealthCampController(), permanent: true);
    } else {
      controller = Get.find<HealthCampController>();
    }
    controller.fetchCamps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.healthCamps.tr),
      floatingActionButton: Obx(
        () => controller.hasCamp
            ? const SizedBox.shrink()
            : FloatingActionButton(
                onPressed: () => Get.to(() => const HealthCampFormScreen()),
                child: const Icon(Icons.add, color: AppColors.white),
              ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.camps.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.camps.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noHealthCampsFound.tr,
              color: AppColors.grey99,
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.size12),
          itemCount: controller.camps.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
          itemBuilder: (_, i) => _CampRow(
            camp: controller.camps[i],
            onDelete: () => _confirmDelete(controller.camps[i]),
          ),
        );
      }),
    );
  }

  void _confirmDelete(HealthCamp camp) {
    showCommonDialog(
      context: context,
      text: AppStrings.deleteThisHealthCamp.tr,
      confirmCallback: () => controller.deleteCamp(camp.id!),
      cancelCallback: () => Get.back(),
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
    );
  }
}

class _CampRow extends StatelessWidget {
  final HealthCamp camp;
  final VoidCallback onDelete;

  const _CampRow({required this.camp, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  camp.title ?? "",
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.size15,
                ),
                if (camp.description?.isNotEmpty == true)
                  Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size4),
                    child: CustomText(
                      camp.description ?? "",
                      fontSize: SizeConfig.small,
                      color: AppColors.black28,
                      maxLines: 2,
                    ),
                  ),
                SizedBox(height: SizeConfig.size8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    LabTagPill("${AppStrings.price.tr}: ${camp.price ?? 0}"),
                    LabTagPill(
                        "${AppStrings.discount.tr}: ${camp.discountPrice ?? 0}"),
                    if (camp.startTime != null)
                      LabTagPill("${AppStrings.start.tr}: ${camp.startTime}"),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () =>
                    Get.to(() => HealthCampFormScreen(existing: camp)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
