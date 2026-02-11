import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_form_screen.dart';
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
      appBar: CommonBackAppBar(
        title: "Health Camps",
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const HealthCampFormScreen());
        },
        child: const Icon(Icons.add,color: AppColors.white,),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.camps.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.camps.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText("No health camps found", color: AppColors.grey99),
                SizedBox(height: SizeConfig.size10),
                // ElevatedButton(
                //   onPressed: () => Get.to(() => const HealthCampFormScreen()),
                //   child: const Text("Create Health Camp"),
                // ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.size12),
          itemBuilder: (_, i) {
            final HealthCamp c = controller.camps[i];
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
                        CustomText(c.title ?? "", fontWeight: FontWeight.w700, fontSize: SizeConfig.size15),
                        if (c.description?.isNotEmpty == true)
                          Padding(
                            padding: EdgeInsets.only(top: SizeConfig.size4),
                            child: CustomText(c.description ?? "", fontSize: SizeConfig.small, color: AppColors.black28, maxLines: 2),
                          ),
                        SizedBox(height: SizeConfig.size8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _pill("Price: ${c.price ?? 0}"),
                            _pill("Discount: ${c.discountPrice ?? 0}"),
                            if (c.startTime != null) _pill("Start: ${c.startTime}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black),
                        onPressed: () {
                          Get.to(() => HealthCampFormScreen(existing: c));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          showCommonDialog(
                            context: context,
                            text: "Delete this health camp?",
                            confirmCallback: () => controller.deleteCamp(c.id!),
                            cancelCallback: () => Get.back(),
                            confirmText: AppStrings.delete,
                            cancelText: AppStrings.cancel,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
          itemCount: controller.camps.length,
        );
      }),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
      ),
      child: CustomText(text, fontSize: SizeConfig.small, color: AppColors.primaryColor),
    );
  }
}
