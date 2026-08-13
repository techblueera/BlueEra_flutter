import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/kickstart/add_products_kickstart.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerAddProductViaAiStep1 extends StatefulWidget {
  final String id;
  final ProviderType providerType;

  /// True when this screen was opened by the app-open kickstart rather than by
  /// the merchant tapping "Add Product" — see [showAddProductsKickstartIfNeeded].
  /// It swaps the back arrow for a ✕ (nothing was navigated away from, so there
  /// is nothing to go back to) and explains, above the form, why it appeared.
  ///
  /// Manufacturing has no Quick Upload rails — its add flow IS this form — so
  /// this is the screen the kickstart opens for it.
  final bool isKickstart;

  ManufacturerAddProductViaAiStep1(
      {super.key,
      required this.id,
      required this.providerType,
      this.isKickstart = false});

  @override
  State<ManufacturerAddProductViaAiStep1> createState() =>
      _ManufacturerAddProductViaAiStep1State();
}

class _ManufacturerAddProductViaAiStep1State
    extends State<ManufacturerAddProductViaAiStep1> {
  final ManufacturerProductController controller =
      getOrPut(() => ManufacturerProductController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Manufacturer add always operates on business nested categories.
      if (controller.productsNestedCategoryList.isEmpty) {
        controller.fetchProductsNestedCategory();
      }
    });
  }

  @override
  void dispose() {
    deleteIfRegistered<ManufacturerProductController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        title: AppStrings.addProductViaAI,
        isLeading: !widget.isKickstart,
        leadingWidget: widget.isKickstart ? const KickstartCloseButton() : null,
      ),
      body: Form(
        key: controller.formKey,
        child: Obx(
          () => AbsorbPointer(
            absorbing: controller.isLoading.value,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size16,
                SizeConfig.size16,
                SizeConfig.size16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Why this page opened, when it opened itself.
                  if (widget.isKickstart) ...[
                    const KickstartIntroBanner(),
                    SizedBox(height: SizeConfig.size4),
                  ],
                  _buildHeader(),
                  SizedBox(height: SizeConfig.size16),
                  _buildMainCard(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Pinned bottom action bar (white) holding the primary CTA.
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.greyE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size16,
            SizeConfig.size12,
            SizeConfig.size16,
            SizeConfig.size12,
          ),
          child: Obx(() => _buildGenerateButton()),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER — gradient hero introducing the AI flow.
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue5CAF, AppColors.primaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -22,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 19),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      AppStrings.addProductWithin1Min,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      'Enter a few details and let AI build your listing',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
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

  // ─────────────────────────────────────────────────────────────
  // MAIN CARD — all input sections grouped under one clean sheet.
  // ─────────────────────────────────────────────────────────────
  Widget _buildMainCard() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12001120),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.sell_outlined, AppStrings.productNameBrand),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            textEditController: controller.productNameStep1Controller,
            title: '',
            hintText: AppStrings.egTShirtMobile,
            validator: ValidationMethod().validateProductName,
            maxLength: 30,
            isCounterVisible: true,
          ),
          SizedBox(height: SizeConfig.size20),
          _sectionHeader(Icons.image_outlined, AppStrings.uploadProductImages),
          SizedBox(height: SizeConfig.size10),
          _buildImageSection(),
          SizedBox(height: SizeConfig.size20),
          _sectionHeader(Icons.category_outlined, AppStrings.category.tr),
          SizedBox(height: SizeConfig.size10),
          _buildCategorySection(),
          SizedBox(height: SizeConfig.size20),
          _sectionHeader(Icons.notes_outlined, AppStrings.productDescSpec,
              optional: true),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            textEditController: controller.productDescriptionStep1Controller,
            title: '',
            hintText: AppStrings.hintProductDesc,
            maxLine: 4,
            validator: (val) => (val == null || val.trim().isEmpty)
                ? null
                : ValidationMethod().validateProductDescription(val),
            maxLength: 100,
            isCounterVisible: true,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, {bool optional = false}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: CustomText(
            title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ),
        if (optional) ...[
          SizedBox(width: SizeConfig.size8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.greyE5.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              'Optional',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // IMAGE SECTION — dashed drop tile when empty, thumbnail strip
  // once photos are added.
  // ─────────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    return GetBuilder<ManufacturerProductController>(
      builder: (c) {
        final images = c.step1Images;
        if (images.isEmpty) return _emptyImageDropTile();
        final canAddMore = images.length < c.maxStep1Images.value;
        return Column(
          children: [
            for (int i = 0; i < images.length; i++) ...[
              _imageTile(c, i),
              if (i != images.length - 1 || canAddMore)
                SizedBox(height: SizeConfig.size10),
            ],
            if (canAddMore) _addMoreTile(),
          ],
        );
      },
    );
  }

  Widget _emptyImageDropTile() {
    return GestureDetector(
      onTap: () => controller.pickImagesStep1(context),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primaryColor.withValues(alpha: 0.45),
          radius: 16,
        ),
        child: Container(
          height: 158,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    color: AppColors.primaryColor, size: 24),
              ),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                'Add product photo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_outlined,
                      size: 13, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 4),
                  CustomText('Upload',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-width image tile — matches the empty drop tile's footprint (and keeps
  // its dashed frame) so the photo doesn't shrink to a small thumbnail.
  Widget _imageTile(ManufacturerProductController c, int index) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.primaryColor.withValues(alpha: 0.45),
        radius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                height: 148,
                width: double.infinity,
                color: AppColors.whiteFE,
                child: Image.file(
                  File(c.step1Images[index]),
                  width: double.infinity,
                  height: 148,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => c.removeImageStep1(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addMoreTile() {
    return GestureDetector(
      onTap: () => controller.pickImagesStep1(context),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primaryColor.withValues(alpha: 0.45),
          radius: 16,
        ),
        child: Container(
          height: 158,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.primaryColor, size: 28),
              const SizedBox(height: 4),
              CustomText('Add another photo',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GENERATE — gradient CTA with sparkle + loading state.
  // ─────────────────────────────────────────────────────────────
  Widget _buildGenerateButton() {
    final loading = controller.isLoading.value;
    return GestureDetector(
      onTap: loading
          ? null
          : () => controller.onGenerate(
                controller,
                widget.id,
                widget.providerType,
              ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 19),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.generate,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return _buildNestedCategorySection();
  }

  Widget _buildNestedCategorySection() {
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Obx(() {
          bool hasSelection = controller.selectedProductLevel0.value != null;

          return Row(
            children: [
              Expanded(
                child: hasSelection
                    ? _buildSelectionPath()
                    : CustomText("Choose Category", color: Colors.grey[400]),
              ),
              const Icon(
                Icons.keyboard_arrow_down_outlined,
                size: 18,
                color: AppColors.secondaryTextColor,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSelectionPath() {
    List<String> path = [
      if (controller.selectedProductLevel0.value != null)
        controller.selectedProductLevel0.value!.name!,
      if (controller.selectedProductLevel1.value != null)
        controller.selectedProductLevel1.value!.name!,
      if (controller.selectedProductLevel2.value != null)
        controller.selectedProductLevel2.value!.name!,
      if (controller.selectedProductLevel3.value != null)
        controller.selectedProductLevel3.value!.name!,
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: path.asMap().entries.map((entry) {
        bool isLast = entry.key == path.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLast
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomText(
                entry.value,
                fontSize: 11,
                color: isLast
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isLast)
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        );
      }).toList(),
    );
  }

  void _showCategoryPicker() {
    RxList<dynamic> currentDisplayList = <dynamic>[].obs;
    currentDisplayList.assignAll(controller.productsNestedCategoryList);

    Get.bottomSheet(
      isScrollControlled: true,
      Obx(() => Container(
            constraints: BoxConstraints(maxHeight: Get.height * 0.7),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInteractiveSheetHeader(currentDisplayList),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: currentDisplayList.length,
                    itemBuilder: (context, index) {
                      final ProductNestedCategoryResponse item =
                          currentDisplayList[index];
                      final bool hasChildren =
                          (item.children != null && item.children!.isNotEmpty);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity:
                            const VisualDensity(horizontal: 0, vertical: -2),
                        title: CustomText(item.name ?? ""),
                        trailing: hasChildren
                            ? const Icon(Icons.chevron_right, size: 18)
                            : null,
                        onTap: () {
                          if (item.level == 0) {
                            controller.selectedProductLevel0.value = item;
                            controller.selectedProductLevel1.value = null;
                            controller.selectedProductLevel2.value = null;
                            controller.selectedProductLevel3.value = null;
                            if (hasChildren) {
                              currentDisplayList.assignAll(item.children!);
                            } else {
                              Get.back();
                            }
                          } else if (item.level == 1) {
                            controller.selectedProductLevel1.value = item;
                            controller.selectedProductLevel2.value = null;
                            controller.selectedProductLevel3.value = null;
                            if (hasChildren) {
                              currentDisplayList.assignAll(item.children!);
                            } else {
                              Get.back();
                            }
                          } else if (item.level == 2) {
                            controller.selectedProductLevel2.value = item;
                            controller.selectedProductLevel3.value = null;
                            if (hasChildren) {
                              currentDisplayList.assignAll(item.children!);
                            } else {
                              Get.back();
                            }
                          } else {
                            controller.selectedProductLevel3.value = item;
                            Get.back();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _buildInteractiveSheetHeader(RxList<dynamic> currentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText("Select Category",
                fontWeight: FontWeight.bold, fontSize: 16),
            IconButton(
                onPressed: () => Get.back(), icon: const Icon(Icons.close)),
          ],
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _pathStep("All", () {
              controller.selectedProductLevel0.value = null;
              controller.selectedProductLevel1.value = null;
              controller.selectedProductLevel2.value = null;
              controller.selectedProductLevel3.value = null;
              currentList.assignAll(controller.productsNestedCategoryList);
            }, controller.selectedProductLevel0.value == null),
            if (controller.selectedProductLevel0.value != null) ...[
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel0.value!.name!, () {
                controller.selectedProductLevel1.value = null;
                controller.selectedProductLevel2.value = null;
                controller.selectedProductLevel3.value = null;
                currentList
                    .assignAll(controller.selectedProductLevel0.value!.children!);
              }, controller.selectedProductLevel1.value == null),
            ],
            if (controller.selectedProductLevel1.value != null) ...[
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel1.value!.name!, () {
                controller.selectedProductLevel2.value = null;
                controller.selectedProductLevel3.value = null;
                currentList
                    .assignAll(controller.selectedProductLevel1.value!.children!);
              }, controller.selectedProductLevel2.value == null),
            ],
            if (controller.selectedProductLevel2.value != null) ...[
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel2.value!.name!, () {
                controller.selectedProductLevel3.value = null;
                currentList
                    .assignAll(controller.selectedProductLevel2.value!.children!);
              }, controller.selectedProductLevel3.value == null),
            ],
            if (controller.selectedProductLevel3.value != null) ...[
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.primaryColor),
              _pathStep(
                  controller.selectedProductLevel3.value!.name!, () {}, true),
            ],
          ],
        ),
        const SizedBox(height: 5),
        CommonHorizontalDivider(
          color: AppColors.greyE5,
          height: 0.5,
        ),
      ],
    );
  }

  Widget _pathStep(String label, VoidCallback onTap, bool isCurrent) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: CustomText(
          label,
          fontSize: 12,
          color:
              isCurrent ? AppColors.primaryColor : AppColors.secondaryTextColor,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Strokes a dashed rounded-rectangle border — used for the photo drop tiles
/// to signal an "add image" affordance without a heavy solid frame.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double dashWidth = 6;
  static const double dashGap = 4;
  static const double strokeWidth = 1.4;

  _DashedBorderPainter({
    required this.color,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = (dist + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
