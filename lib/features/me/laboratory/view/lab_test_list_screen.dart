import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_catalog_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabTestListScreen extends StatefulWidget {
  final String collection;
  final String? title;
  final String? labId;

  /// When `false`, hides the "add test" FAB — used by the read-only
  /// entry from the Lab Tests tab's category grid where the user is
  /// only browsing what's already been added.
  final bool showAddButton;

  const LabTestListScreen({
    super.key,
    required this.collection,
    this.title,
    this.labId,
    this.showAddButton = true,
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
    final canAdd = !_isOtherProfile && widget.showAddButton;
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title ?? "",
        showRightTextButton: false,
        buildCustomActionWidget: canAdd ? _buildAddAction : null,
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
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size16),
          itemBuilder: (_, i) {
            final PathologyTest t = controller.tests[i];
            return _TestCard(
              test: t,
              backgroundColor: LabSoftCardColor.forIndex(i),
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

  // Circular "+" affordance rendered in the app bar's trailing slot via
  // [CommonBackAppBar.buildCustomActionWidget]. Replaces the previous FAB so
  // the add-test entry point sits next to the title instead of floating over
  // the list.
  //
  // Seeds `presetPackageType` with `widget.collection` — the catalog forwards
  // that to [AddLabTestScreen], where the Package Type surface locks onto it
  // (when the collection name is an entry in
  // [LabTestController.packageTypeList]). Mirrors the preset-lock behaviour
  // used by the Create-Your-Own-Packages landing.
  Widget _buildAddAction() {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size12),
      child: InkWell(
        onTap: () => Get.to(
          () => LabTestCatalogScreen(
            collection: widget.collection,
            presetPackageType: widget.collection,
          ),
        ),
        customBorder: const CircleBorder(),
        child: Container(
          width: SizeConfig.size32,
          height: SizeConfig.size32,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: AppColors.white, size: 20),
        ),
      ),
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

/// Card design ported from [_CatalogCard] in
/// `lab_test_catalog_screen.dart` so the added-tests list matches the
/// catalog visual language: soft pastel background, title + params,
/// divider, report-timing + price badges, and a home-collection bar with
/// a trailing action button.
///
/// Owner mode (`canEdit: true`) adds a floating delete pill in the top-right
/// corner and swaps the chevron for an edit-pencil so the whole card taps
/// straight into [AddLabTestScreen].
class _TestCard extends StatelessWidget {
  final PathologyTest test;
  final Color backgroundColor;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TestCard({
    required this.test,
    required this.backgroundColor,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // `testParameters` is a mixed list — API can return String IDs or full
    // [TestParameter] objects. Prefer the object names; fall back to
    // description when only IDs are present so the card never looks empty.
    final paramNames = (test.testParameters ?? const [])
        .whereType<TestParameter>()
        .map((p) => p.name ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final subtitle = paramNames.isNotEmpty ? paramNames : (test.description ?? '');

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canEdit ? onEdit : null,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          test.testName ?? "",
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size18,
                          color: Colors.black87,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        if (subtitle.isNotEmpty)
                          CustomText(
                            subtitle,
                            fontSize: SizeConfig.small,
                            color: Colors.black54,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const Divider(
                          height: 20,
                          color: Color(0xFFDDE2EE),
                          thickness: 0.5,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _reportTimingBadge(),
                            _priceBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size16,
                      0,
                      SizeConfig.size16,
                      SizeConfig.size16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                CustomText(
                                  AppStrings.labHomeSampleAvailable.tr,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.blue.shade400, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            canEdit ? Icons.edit_outlined : Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (canEdit)
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: onDelete,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: EdgeInsets.all(SizeConfig.size6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportTimingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black87,
            fontSize: SizeConfig.small,
          ),
          children: [
            TextSpan(text: "${AppStrings.labReportsWithinPrefix.tr} "),
            TextSpan(
              text: "${test.estimatedReportHours ?? 0} ${AppStrings.labHoursWord.tr}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: CustomText(
        "${AppStrings.labInrPrefix.tr}${test.customerPrice ?? 0}",
        fontWeight: FontWeight.bold,
        fontSize: SizeConfig.size14,
      ),
    );
  }
}
