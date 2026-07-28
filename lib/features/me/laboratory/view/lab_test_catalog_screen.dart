import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabTestCatalogScreen extends StatefulWidget {
  final String collection;
  final String? title;

  /// Optional preset the previous screen picked (e.g. the collection name
  /// from `LabCategoryScreen` or `LabTestListScreen`). Forwarded to
  /// [AddLabTestScreen] via the "Add Manually" button so the Package Type
  /// surface can lock onto it.
  final String? presetPackageType;

  const LabTestCatalogScreen({
    super.key,
    required this.collection,
    this.title,
    this.presetPackageType,
  });

  @override
  State<LabTestCatalogScreen> createState() => _LabTestCatalogScreenState();
}

class _LabTestCatalogScreenState extends State<LabTestCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final LabTestController controller;
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabTestController>()) {
      controller = Get.put(LabTestController(), permanent: true);
    } else {
      controller = Get.find<LabTestController>();
    }
    // Tab 0 = manually-added tests, Tab 1 = catalog. Kept in this order so
    // owners land on their own tests first.
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchCatalog(
        groupCategory: widget.collection,
        page: 1,
      );
      // Populates `controller.tests` for the "Manually Added" tab. The
      // controller already refreshes this list after each successful
      // create/update, so no extra hook is needed on return.
      controller.fetchTests(widget.collection);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Trigger the next page 300px before the scroll extent so users don't
  // have to hit the very bottom to load more.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      controller.fetchMoreCatalog(groupCategory: widget.collection);
    }
  }

  // Bottom-of-list slot: spinner while the next page loads, muted "end of
  // list" caption once the backend has been exhausted.
  Widget _buildListTrailer() {
    if (controller.isLoadingMoreCatalog.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      child: Center(
        child: CustomText(
          AppStrings.noTestsFound.tr,
          color: AppColors.grey99,
          fontSize: SizeConfig.small,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        // Callers (`LabTestListScreen`, `LabCategoryScreen`) usually pass
        // just `collection` and leave `title` null — fall back to the
        // group-category name so the app bar always labels the current
        // page instead of rendering blank.
        title: widget.title ?? widget.collection,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: InkWell(
            onTap: () => Get.to(
              () => AddLabTestScreen(
                collection: widget.collection,
                presetPackageType: widget.presetPackageType,
              ),
            ),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomText(
                AppStrings.addManually.tr,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.grey99,
              indicatorColor: AppColors.primaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Tests'),
                Tab(text: 'My Test'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogTab(),
                _buildManualTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 0 — this lab's own tests filtered to `source == "manual"`.
  // Backend stamps `source: "manual"` on `POST /pathology-tests` and
  // `source: "catalog"` on `POST /test-catalog/select`; the filter is
  // client-side because the list endpoint returns both together.
  Widget _buildManualTab() {
    return Obx(() {
      final manualTests = controller.tests
          .where((t) => (t.source ?? '').toLowerCase() == 'manual')
          .toList();
      if (controller.isLoading.value && manualTests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (manualTests.isEmpty) {
        return Center(
          child: CustomText(
            AppStrings.noTestsFound.tr,
            color: AppColors.grey99,
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.all(SizeConfig.size12),
        itemCount: manualTests.length,
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size16),
        itemBuilder: (_, i) {
          final t = manualTests[i];
          return TestCard(
            test: t,
            backgroundColor: LabSoftCardColor.forIndex(i),
            canEdit: true,
            onEdit: () => Get.to(() => AddLabTestScreen(
                  testToEdit: t,
                  collection: widget.collection,
                )),
            onDelete: () => _confirmDelete(t),
          );
        },
      );
    });
  }

  // Tab 1 — unchanged catalog list. Kept its own scroll controller so
  // pagination fires only while this tab is visible.
  Widget _buildCatalogTab() {
    return Obx(() {
      if (controller.isLoading.value && controller.catalogTests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.catalogTests.isEmpty) {
        return Center(
          child:
              CustomText(AppStrings.noTestsFound.tr, color: AppColors.grey99),
        );
      }
      // `+ 1` reserves a trailing slot for the load-more indicator so
      // the user sees progress feedback while the next page fetches.
      final showTrailer = controller.isLoadingMoreCatalog.value ||
          controller.catalogHasMore.value == false;
      final itemCount = controller.catalogTests.length + (showTrailer ? 1 : 0);

      return ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.all(SizeConfig.size12),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size16),
        itemBuilder: (_, i) {
          if (i >= controller.catalogTests.length) {
            return _buildListTrailer();
          }
          return _CatalogCard(
            item: controller.catalogTests[i],
            backgroundColor: LabSoftCardColor.forIndex(i),
            onTap: () => _showCatalogBottomSheet(controller.catalogTests[i]),
          );
        },
      );
    });
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

  void _showCatalogBottomSheet(TestCatalogItem item) {
    final nameCtrl = TextEditingController(text: item.testName ?? "");
    final paramsCtrl = TextEditingController(
      text: (item.testParameters ?? []).join(", "),
    );
    final List<String> methodOptions = (item.testMethod ?? "")
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final selectedMethod = RxString(
      methodOptions.isNotEmpty ? methodOptions.first : "",
    );
    final hoursCtrl = TextEditingController(
      text: (item.estimatedReportHours ?? 24).toString(),
    );
    final feesCtrl = TextEditingController(
      text: (item.suggestedTestFees ?? 0).toString(),
    );
    final priceCtrl = TextEditingController(
      text: (item.suggestedCustomerPrice ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size16,
            right: SizeConfig.size16,
            top: SizeConfig.size16,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + SizeConfig.size16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.labCheckDetails.tr,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.size16,
                ),
                SizedBox(height: SizeConfig.size12),
                CommonTextField(
                  textEditController: nameCtrl,
                  title: AppStrings.labHintHemoglobin.tr,
                  hintText: AppStrings.labHint138.tr,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: paramsCtrl,
                  title: AppStrings.labTestParameters.tr,
                  hintText: AppStrings.labHint138.tr,
                  maxLine: 2,
                ),
                SizedBox(height: SizeConfig.size8),
                if (methodOptions.isNotEmpty) ...[
                  CustomText(
                    AppStrings.labTestMethod.tr,
                    fontWeight: FontWeight.w500,
                    fontSize: SizeConfig.size14,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: methodOptions
                            .map((method) => _methodChip(
                                  method: method,
                                  isSelected: selectedMethod.value == method,
                                  onTap: () => selectedMethod.value = method,
                                ))
                            .toList(),
                      )),
                ],
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: hoursCtrl,
                  title: AppStrings.labEstimatedReportHours.tr,
                  keyBoardType: TextInputType.number,
                  isValidate: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.required.tr;
                    }
                    final hours = int.tryParse(value);
                    if (hours == null || hours <= 0) return "Invalid hours";
                    if (hours > 999) return "Max 999 hours";
                    return null;
                  },
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        textEditController: feesCtrl,
                        title: AppStrings.labTestFees.tr,
                        keyBoardType: TextInputType.number,
                        isValidate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.required.tr;
                          }
                          final fees = int.tryParse(value);
                          if (fees == null || fees <= 0) return "Invalid fees";
                          if (fees > 1000000) return "Max 1,000,000";
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: CommonTextField(
                        textEditController: priceCtrl,
                        title: AppStrings.labCustomerPrice.tr,
                        keyBoardType: TextInputType.number,
                        isValidate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.required.tr;
                          }
                          final price = int.tryParse(value);
                          final mrp = int.tryParse(feesCtrl.text);
                          if (price == null || price <= 0) {
                            return "Invalid price";
                          }
                          if (price > 1000000) return "Max 1,000,000";
                          if (mrp != null && price > mrp) {
                            return "Customer price cannot exceed MRP";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size16),
                Obx(() => PositiveCustomBtn(
                      onTap: controller.isLoading.value
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                final overrides = {
                                  "testName": nameCtrl.text,
                                  "testParameters": paramsCtrl.text
                                      .split(",")
                                      .map((e) => e.trim())
                                      .toList(),
                                  "estimatedReportHours":
                                      int.tryParse(hoursCtrl.text) ?? 24,
                                  "testFees": int.tryParse(feesCtrl.text) ?? 0,
                                  "customerPrice":
                                      int.tryParse(priceCtrl.text) ?? 0,
                                  "testMethod": selectedMethod.value,
                                };
                                final ok = await controller.selectCatalog(
                                  item.id!,
                                  collection: widget.collection,
                                  customData: overrides,
                                );
                                if (ok) Get.back();
                              }
                            },
                      title: AppStrings.postNow,
                    )),
                SizedBox(height: SizeConfig.size30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodChip({
    required String method,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: CustomText(
          method,
          fontSize: SizeConfig.small,
          color: isSelected ? Colors.white : AppColors.primaryColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final TestCatalogItem item;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.item,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = item.alreadyAdded == true;
    // Highlight already-added tests with a thicker green border. The rest
    // of the card (soft pastel background, badges, chevron) stays intact so
    // the row still reads as tappable — the border is the "already added"
    // signal, the corner pill is the label.
    final borderColor =
        isAdded ? Colors.green.shade600 : Colors.black.withValues(alpha: 0.05);
    final borderWidth = isAdded ? 1.6 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + parameters + report time + price
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          item.testName ?? "",
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size18,
                          color: Colors.black87,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        if (item.testParameters?.isNotEmpty ?? false)
                          CustomText(
                            item.testParameters!.join(", "),
                            fontSize: SizeConfig.small,
                            color: Colors.black54,
                            maxLines: 1,
                          ),
                        const Divider(height: 30, thickness: 0.5),
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

                  // Home-collection bar + chevron
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 8, color: Colors.grey.shade600),
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
                            border: Border.all(
                              color: isAdded
                                  ? Colors.green.shade500
                                  : Colors.blue.shade400,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isAdded
                                ? Icons.check_rounded
                                : Icons.arrow_forward_ios,
                            size: 18,
                            color:
                                isAdded ? Colors.green.shade600 : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAdded)
            Positioned(
              top: 8,
              right: 8,
              child: _addedPill(),
            ),
        ],
      ),
    );
  }

  Widget _addedPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Added',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
              text:
                  "${item.estimatedReportHours ?? 0} ${AppStrings.labHoursWord.tr}",
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
        "${AppStrings.labInrPrefix.tr}${item.suggestedCustomerPrice ?? '0'}",
        fontWeight: FontWeight.bold,
        fontSize: SizeConfig.size14,
      ),
    );
  }
}
