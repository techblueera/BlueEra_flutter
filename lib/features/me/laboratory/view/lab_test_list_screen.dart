import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_catalog_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabTestListScreen extends StatefulWidget {
  final String collection;
  final String? title;

  const LabTestListScreen({super.key, required this.collection, this.title});

  @override
  State<LabTestListScreen> createState() => _LabTestListScreenState();
}

class _LabTestListScreenState extends State<LabTestListScreen> {
  late final LabTestController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabTestController>()) {
      controller = Get.put(LabTestController(), permanent: true);
    } else {
      controller = Get.find<LabTestController>();
    }

      controller.fetchTests(widget.collection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title ?? "",
        showRightTextButton: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => LabTestCatalogScreen(collection: widget.collection));
        },
        child: Icon(
          Icons.add,
          color: AppColors.white,
        ),
      ),
      body: Obx(() {


        if (controller.isLoading.value && controller.tests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(AppStrings.noTestsFound.tr, color: AppColors.grey99),
                SizedBox(height: SizeConfig.size10),
                // ElevatedButton(
                //   onPressed: () => Get.to(() => AddLabTestScreen(collection: widget.collection)),
                //   child: const Text("Add Test"),
                // ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.size12),
          itemBuilder: (_, i) {
            final PathologyTest t = controller.tests[i];
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
                        CustomText(t.testName ?? "",
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.size15),
                        if (t.description?.isNotEmpty == true)
                          Padding(
                            padding: EdgeInsets.only(top: SizeConfig.size4),
                            child: CustomText(t.description ?? "",
                                fontSize: SizeConfig.small,
                                color: AppColors.black28,
                                maxLines: 2),
                          ),
                        SizedBox(height: SizeConfig.size8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _pill("${AppStrings.fees.tr}: ${t.testFees ?? 0}"),
                            _pill("${AppStrings.price.tr}: ${t.customerPrice ?? 0}"),
                            if (t.gender != null) _pill("${AppStrings.gender.tr}: ${t.gender}"),
                            if (t.estimatedReportHours != null)
                              _pill("${AppStrings.report.tr}: ${t.estimatedReportHours}h"),
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
                          Get.to(() => AddLabTestScreen(
                              testToEdit: t, collection: widget.collection));
                        },
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          showCommonDialog(
                            context: context,
                            text: AppStrings.deleteThisTest.tr,
                            confirmCallback: () =>
                                controller.deleteTest(t.id!, widget.collection),
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
          itemCount: controller.tests.length,
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
      child: CustomText(text,
          fontSize: SizeConfig.small, color: AppColors.primaryColor),
    );
  }
}
