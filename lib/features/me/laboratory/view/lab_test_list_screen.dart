import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_catalog_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_tag_pill.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabTestListScreen extends StatefulWidget {
  final String collection;
  final String? title;
  final String? labId;

  const LabTestListScreen({
    super.key,
    required this.collection,
    this.title,
    this.labId,
  });

  @override
  State<LabTestListScreen> createState() => _LabTestListScreenState();
}

class _LabTestListScreenState extends State<LabTestListScreen> {
  late final LabTestController controller;

  bool get _isOtherProfile => widget.labId != null;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabTestController>()) {
      controller = Get.put(LabTestController(), permanent: true);
    } else {
      controller = Get.find<LabTestController>();
    }

    if (_isOtherProfile) {
      controller.fetchTestsByLab(widget.labId!, widget.collection);
    } else {
      controller.fetchTests(widget.collection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title ?? "",
        showRightTextButton: false,
      ),
      floatingActionButton: _isOtherProfile
          ? null
          : FloatingActionButton(
              onPressed: () => Get.to(
                () => LabTestCatalogScreen(collection: widget.collection),
              ),
              child: const Icon(Icons.add, color: AppColors.white),
            ),
      body: Obx(() {
        if (controller.isLoading.value && controller.tests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tests.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noTestsFound.tr,
              color: AppColors.grey99,
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.size12),
          itemCount: controller.tests.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
          itemBuilder: (_, i) {
            final PathologyTest t = controller.tests[i];
            return _TestRow(
              test: t,
              canEdit: !_isOtherProfile,
              onEdit: () => Get.to(() => AddLabTestScreen(
                    testToEdit: t,
                    collection: widget.collection,
                  )),
              onDelete: () => _confirmDelete(t),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(PathologyTest t) {
    showCommonDialog(
      context: context,
      text: AppStrings.deleteThisTest.tr,
      confirmCallback: () {
        Get.back();
        controller.deleteTest(t.id!, widget.collection);
      },
      cancelCallback: () => Get.back(),
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
    );
  }
}

class _TestRow extends StatelessWidget {
  final PathologyTest test;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TestRow({
    required this.test,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

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
                  test.testName ?? "",
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.size15,
                ),
                if (test.description?.isNotEmpty == true)
                  Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size4),
                    child: CustomText(
                      test.description ?? "",
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
                    LabTagPill("${AppStrings.fees.tr}: ${test.testFees ?? 0}"),
                    LabTagPill(
                        "${AppStrings.price.tr}: ${test.customerPrice ?? 0}"),
                    if (test.gender != null)
                      LabTagPill("${AppStrings.gender.tr}: ${test.gender}"),
                    if (test.estimatedReportHours != null)
                      LabTagPill(
                          "${AppStrings.report.tr}: ${test.estimatedReportHours}h"),
                  ],
                ),
              ],
            ),
          ),
          if (canEdit)
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: onEdit,
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
