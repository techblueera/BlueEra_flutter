import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_form_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HealthCampDetailScreen extends StatefulWidget {
  const HealthCampDetailScreen({super.key});

  @override
  State<HealthCampDetailScreen> createState() => _HealthCampDetailScreenState();
}

class _HealthCampDetailScreenState extends State<HealthCampDetailScreen> {
  late final HealthCampController controller;
  bool _isDescExpanded = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HealthCampController>()) {
      controller = Get.put(HealthCampController(), permanent: true);
    } else {
      controller = Get.find<HealthCampController>();
    }
    controller.fetchCampFullDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.healthCamp.tr,
        buildCustomActionWidget: () => Obx(() {
          final camp = controller.campDetail.value;
          if (camp == null) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: () async {
                  await Get.to(() => HealthCampFormScreen(existing: camp));
                  controller.fetchCampFullDetails();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 22, color: AppColors.red),
                onPressed: () => _showDeleteConfirmation(camp),
              ),
            ],
          );
        }),
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final camp = controller.campDetail.value;
        if (camp == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  AppStrings.noHealthCampsFound.tr,
                  color: AppColors.greyA5,
                ),
                SizedBox(height: SizeConfig.size16),
                GestureDetector(
                  onTap: () async {
                    await Get.to(() => const HealthCampFormScreen());
                    controller.fetchCampFullDetails();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size20,
                      vertical: SizeConfig.size12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      AppStrings.createHealthCamp.tr,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCampHeader(camp),
              SizedBox(height: SizeConfig.size12),
              if (camp.testDiscounts != null && camp.testDiscounts!.isNotEmpty)
                _buildTestCategoryGroup(camp.title ?? "", camp.testDiscounts!),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCampHeader(HealthCamp camp) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (camp.images != null && camp.images!.isNotEmpty)
            _buildImageGallery(camp.images!),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            camp.title ?? "",
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: SizeConfig.size8),
          if (camp.description != null && camp.description!.isNotEmpty) ...[
            CustomText(
              camp.description!,
              fontSize: 13,
              color: AppColors.secondaryTextColor,
              maxLines: _isDescExpanded ? null : 3,
            ),
            if (camp.description!.length > 120)
              GestureDetector(
                onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                child: Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size4),
                  child: CustomText(
                    _isDescExpanded
                        ? AppStrings.readLess.tr
                        : AppStrings.readMore.tr,
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: SizeConfig.size8),
          ],
          if (camp.location?.name != null && camp.location!.name!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                Expanded(
                  child: CustomText(
                    camp.location!.name!,
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          SizedBox(height: SizeConfig.size12),
          _buildDateTimeSection(camp),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: images[index],
              width: 240,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 240,
                height: 180,
                color: AppColors.greyE5,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 240,
                height: 180,
                color: AppColors.greyE5,
                child: const Icon(Icons.broken_image_outlined,
                    size: 40, color: AppColors.greyA5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeSection(HealthCamp camp) {
    final startFormatted = _formatDate(camp.startDate);
    final endFormatted = _formatDate(camp.endDate);

    return Row(
      children: [
        // Start Date Container
        Expanded(
          child: _buildDateTimeBox(
            label: "Start Date", // Use localization key if needed
            date: startFormatted,
            time: camp.startTime ?? '',
          ),
        ),
        SizedBox(width: SizeConfig.size12), // Space between boxes
        // End Date Container
        Expanded(
          child: _buildDateTimeBox(
            label: "End Date", // Use localization key if needed
            date: endFormatted,
            time: camp.startTime ?? '', // Ensure you use endTime here
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeBox(
      {required String label, required String date, required String time}) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300), // Light grey border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Flexible(
                child: CustomText(
                  date,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomText(
                " • ", // The dot separator from your screenshot
                fontSize: 14,
                color: Colors.grey,
              ),
              CustomText(
                time,
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestCategoryGroup(String title, List<TestDiscount> discounts) {
    if (discounts.isEmpty) return const SizedBox.shrink();

    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: 18, // Adjusted for header style in image
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: SizeConfig.size16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: discounts.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: SizeConfig.size16),
            itemBuilder: (context, index) {
              final item = discounts[index];
              return Row(
                children: [
                  // Green Check Icon
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade600, size: 24),
                  SizedBox(width: SizeConfig.size12),

                  // Test Name
                  Expanded(
                    child: CustomText(
                      item.test?.testName ?? "N/A",
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),

                  // Eye Icon Button in Light Blue Container
                  GestureDetector(
                    onTap: () => _showTestDetailsDialog(context, item),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.visibility_outlined,
                          color: Colors.blue.shade600, size: 20),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTestDetailsDialog(BuildContext context, TestDiscount discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
// 1. Remove padding from the title and content
//         titlePadding: EdgeInsets.zero,
        // contentPadding: EdgeInsets.zero,

        // 2. Adjust the insetPadding if you want the dialog to be wider/full screen
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomText(
                discount.test?.testName ?? "Test Details",
                // fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          ],
        ),
        content: _buildTestCard(
            discount) /*Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow("Category:", discount.test?.groupCategory ?? "N/A"),
            const SizedBox(height: 8),
            _dialogRow("Discount:", "${discount.discountValue}%"),
            // Add more details here if needed
          ],
        )*/
        ,
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontWeight: FontWeight.bold, fontSize: 14),
        const SizedBox(width: 8),
        Expanded(child: CustomText(value, fontSize: 14)),
      ],
    );
  }

  //
  // Widget _buildTestDiscountsSection(List<TestDiscount> discounts) {
  //   // Group discounts by groupCategory
  //   final Map<String, List<TestDiscount>> grouped = {};
  //   for (final d in discounts) {
  //     final category = d.test?.groupCategory ?? "Other";
  //     grouped.putIfAbsent(category, () => []);
  //     grouped[category]!.add(d);
  //   }
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Available Free Test section (discountValue == 0 or free)
  //       _buildTestCategoryGroup(
  //         AppStrings.availableFreeTest.tr,
  //         discounts.where((d) => (d.discountValue ?? 0) == 0).toList(),
  //       ),
  //       SizedBox(height: SizeConfig.size12),
  //       // Available Discounted Test section (discountValue > 0)
  //       _buildTestCategoryGroup(
  //         AppStrings.availableDiscountedTest.tr,
  //         discounts.where((d) => (d.discountValue ?? 0) > 0).toList(),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildTestCategoryGroup(String title, List<TestDiscount> discounts) {
  //   if (discounts.isEmpty) return const SizedBox.shrink();
  //
  //   // Group by category
  //   final Map<String, List<TestDiscount>> grouped = {};
  //   for (final d in discounts) {
  //     final category = d.test?.groupCategory ?? "Other";
  //     grouped.putIfAbsent(category, () => []);
  //     grouped[category]!.add(d);
  //   }
  //
  //   return CommonCardWidget(
  //     cardMargin: 0,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         CustomText(
  //           title,
  //           fontSize: 14,
  //           fontWeight: FontWeight.w700,
  //         ),
  //         SizedBox(height: SizeConfig.size12),
  //         ...grouped.entries.map((entry) {
  //           return Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Category chip
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                     horizontal: 12, vertical: 6),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primaryColor.withValues(alpha: 0.08),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: CustomText(
  //                   entry.key,
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.w500,
  //                   color: AppColors.primaryColor,
  //                 ),
  //               ),
  //               SizedBox(height: SizeConfig.size8),
  //               // Test cards for this category
  //               ...entry.value.map((discount) => _buildTestCard(discount)),
  //               SizedBox(height: SizeConfig.size8),
  //             ],
  //           );
  //         }),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTestCard(TestDiscount discount) {
    final test = discount.test;
    if (test == null) return const SizedBox.shrink();

    final List<Color> cardColors = [
      const Color(0xFFFFFBEB),
      const Color(0xFFF0FDF4),
      const Color(0xFFEFF6FF),
      const Color(0xFFFAF5FF),
    ];
    final colorIndex = (test.testName?.hashCode ?? 0).abs() % cardColors.length;

    return Container(
      width: double.infinity,
      // margin: EdgeInsets.only(bottom: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: cardColors[colorIndex],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            test.testName ?? "",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (test.description != null && test.description!.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size4),
            CustomText(
              test.description!,
              fontSize: 11,
              color: Colors.grey.shade600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.grey.shade300, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pill(
                "Reports within ${test.estimatedReportHours ?? 24} Hrs",
                Colors.white,
              ),
              if (test.customerPrice != null)
                _pill(
                  "INR ${test.customerPrice}",
                  Colors.white,
                  isBold: true,
                ),
            ],
          ),
          if ((discount.discountValue ?? 0) > 0) ...[
            SizedBox(height: SizeConfig.size8),
            _pill(
              "${discount.discountValue}% ${discount.discountType ?? 'percentage'} off",
              AppColors.primaryColor.withValues(alpha: 0.1),
              textColor: AppColors.primaryColor,
              isBold: true,
            ),
          ],
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: Colors.grey),
              SizedBox(width: 8),
              CustomText(
                "${test.specimen ?? 'Blood'} sample collection",
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bgColor,
      {bool isBold = false, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomText(
        text,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
        fontSize: 11,
        color: textColor,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showDeleteConfirmation(HealthCamp camp) {
    showCommonDialog(
      context: context,
      text: AppStrings.confirmDeleteCamp.tr,
      confirmCallback: () async {
        Get.back();
        await controller.deleteCamp(camp.id!);
        controller.fetchCampFullDetails();
      },
      cancelCallback: () => Get.back(),
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
    );
  }
}
