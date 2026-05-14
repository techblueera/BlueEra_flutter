import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabTestCatalogScreen extends StatefulWidget {
  final String collection;
  final String? title;

  const LabTestCatalogScreen({super.key, required this.collection, this.title});

  @override
  State<LabTestCatalogScreen> createState() => _LabTestCatalogScreenState();
}

class _LabTestCatalogScreenState extends State<LabTestCatalogScreen> {
  late final LabTestController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabTestController>()) {
      controller = Get.put(LabTestController(), permanent: true);
    } else {
      controller = Get.find<LabTestController>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchCatalog(
        groupCategory: widget.collection,
        page: 1,
        limit: 20,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: InkWell(
            onTap: () => Get.to(
              () => AddLabTestScreen(collection: widget.collection),
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
      body: Obx(() {
        if (controller.isLoading.value && controller.catalogTests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.catalogTests.isEmpty) {
          return Center(
            child:
                CustomText(AppStrings.noTestsFound.tr, color: AppColors.grey99),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.size12),
          itemCount: controller.catalogTests.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size16),
          itemBuilder: (_, i) => _CatalogCard(
            item: controller.catalogTests[i],
            backgroundColor: LabSoftCardColor.forIndex(i),
            onTap: () => _showCatalogBottomSheet(controller.catalogTests[i]),
          ),
        );
      }),
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
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
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
                      border:
                          Border.all(color: Colors.blue.shade400, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_ios,
                        size: 18, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
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
