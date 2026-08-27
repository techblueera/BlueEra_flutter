import 'dart:developer';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/features/me/medical/widget/medical_selection_floating_cart.dart';
import 'package:BlueEra/widgets/already_added_badge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class MedicalProductSelectionScreen extends StatefulWidget {
  final List<MedicalNestedCategoryModel> arrLevel3Category;

  MedicalProductSelectionScreen({
    super.key,
    required this.arrLevel3Category,
  });

  /// The category list to open this screen with, for a tapped category.
  ///
  /// A category with children opens on those children — but a **leaf** has
  /// none, and the two callers each got that case wrong in a different way:
  /// the level-2 screen guarded with `if (children.isNotEmpty)` and so did
  /// nothing at all on tap, while the level-1 screen pushed this screen with
  /// an empty list, which then blew up on `.first`.
  ///
  /// A leaf isn't a dead end — products hang off it directly — so it opens on
  /// **itself**: one entry in the left rail, and its own `key` as the search
  /// term.
  static List<MedicalNestedCategoryModel> categoriesToOpen(
      MedicalNestedCategoryModel category) {
    final children = category.children ?? const <MedicalNestedCategoryModel>[];
    return children.isNotEmpty ? children : [category];
  }

  @override
  State<MedicalProductSelectionScreen> createState() =>
      _MedicalProductSelectionScreenState();
}

class _MedicalProductSelectionScreenState extends State<MedicalProductSelectionScreen> {
  final controller = getOrPut(() => MedicalController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
    // Category FIRST, then fetch — same order grocery uses.
    // fetchGroceryCategoryProducts() sends `selectedMedicalData.value?.key` as
    // its searchTerm, so firing it before the selection was set (as this did)
    // queried a null/stale category while the title already read the first one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Defensive: a caller that still passes an empty list gets an empty
      // state instead of a "Bad state: No element" crash.
      if (widget.arrLevel3Category.isEmpty) return;
      controller.selectedMedicalData.value = widget.arrLevel3Category.first;
      controller.fetchGroceryCategoryProducts();
      // Which catalogue variants this pharmacy already stocks, so a product it
      // already sells is badged rather than offered again. Guarded and
      // snapshot-backed, so re-entering the add flow usually costs nothing.
      controller.fetchStockedVariantIdsIfNeeded();
    });
  }

  void _onScrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !controller.isMedicalCategoryProductsLoadingMore.value &&
        controller.medicalCategoryProductsHasMore) {
      controller.fetchGroceryCategoryProducts(
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold-wide Obx: the title, the left list (its own Obx lives inside
    // CommonGenericLeftSideCategoryList) and rightContent each subscribe for
    // themselves, so wrapping the whole tree just rebuilt everything on every
    // selection tap. Same shape as GroceryProductsSelectionScreen.
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final name = controller.selectedMedicalData.value?.name ?? '';
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        isShadowShow: false,
        // Search only. The cart badge that used to live here is now the
        // floating cart below — one cart affordance, not two.
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Icon(Icons.search),
        ),
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftCategoryList(),
              Expanded(child: rightContent()),
            ],
          ),
          // Floating cart — replaces the old "Next" bottom bar. Self-hides
          // while nothing is selected.
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: MedicalSelectionFloatingCart(controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<MedicalNestedCategoryModel>(
      items: widget.arrLevel3Category,
      placeholderAssetPath: 'assets/category/medical/medical_store.png',
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
          controller.selectedMedicalData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrLevel3Category[index];
        log('new selection ${controller.selectedMedicalData.value?.sId}');

        if (controller.selectedMedicalData.value?.sId == selected.sId) {
          return;
        }

        controller.selectedMedicalData.value = selected;

        /// api call
        controller.fetchGroceryCategoryProducts();
      },
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(8),
          child: controller.isMedicalCategoryProductsLoading.value
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Max Limit Error
                    if (controller.isMaxLimitHit)
                      Container(
                        width: SizeConfig.screenWidth,
                        decoration: BoxDecoration(
                            color: AppColors.redBE,
                            borderRadius: BorderRadius.circular(10.0)),
                        margin: EdgeInsets.only(bottom: SizeConfig.size10),
                        padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size4,
                            horizontal: SizeConfig.size10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              LocalAssets(
                                  imagePath: AppIconAssets.warningOutlineIcon,
                                  width: SizeConfig.size20,
                                  height: SizeConfig.size20),
                              SizedBox(width: SizeConfig.size8),
                              CustomText(
                                '${AppStrings.medicalCannotSelectMorePrefix.tr} ${controller.maxLimit} ${AppStrings.medicalCannotSelectMoreSuffix.tr}',
                                color: AppColors.redLite,
                                fontSize: SizeConfig.extraSmall,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // GRID
                    Expanded(
                      child: controller.isMedicalCategoryProductsLoading.value
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(SizeConfig.size20),
                                child: SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator()),
                              ),
                            )
                          : controller.arrMedicalCategoryProducts.isNotEmpty
                              ? LayoutBuilder(builder: (context, constraints) {
                                  double availableWidth = constraints.maxWidth;
                                  double crossAxisSpacing = 10.0;
                                  double gridItemWidth = (availableWidth -
                                          crossAxisSpacing) /
                                      2;
                                  double childAspectRatio = gridItemWidth / (gridItemWidth * 1.85);

                                  return GridView.builder(
                                    controller: scrollController,
                                    itemCount: controller
                                            .arrMedicalCategoryProducts.length +
                                        (controller
                                                .isMedicalCategoryProductsLoadingMore
                                                .value
                                            ? 1
                                            : 0),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                    // Extra clearance so the last row can
                                    // scroll clear of the floating cart.
                                    padding: EdgeInsets.only(
                                      bottom: controller
                                              .selectedMedicalProducts.isNotEmpty
                                          ? SizeConfig.size80
                                          : SizeConfig.size30,
                                    ),
                                    itemBuilder: (_, i) {
                                      if (i ==
                                          controller.arrMedicalCategoryProducts
                                              .length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        );
                                      }

                                      return medicalCard(controller
                                          .arrMedicalCategoryProducts[i]);
                                    },
                                  );
                                })
                              : Padding(
                                  padding: EdgeInsets.all(SizeConfig.size20),
                                  child: EmptyStateWidget(
                                      // Names the SELECTED category, not
                                      // `.first` — the left rail can move the
                                      // selection, and `.first` also threw on
                                      // an empty list.
                                      message: _emptyMessage())),
                    )
                  ],
                ),
        ));
  }

  /// "No products found in <category>" for whichever category is selected.
  String _emptyMessage() {
    final name = controller.selectedMedicalData.value?.name ??
        (widget.arrLevel3Category.isEmpty
            ? ''
            : widget.arrLevel3Category.first.name ?? '');
    return '${AppStrings.medicalNoFoundPrefix.tr} ${name.tr} '
        '${AppStrings.medicalNoFoundSuffix.tr}';
  }

  Widget medicalCard(MedicalProductData medicalProductData) {
    final bool isSelected =
        controller.selectedMedicalProducts.contains(medicalProductData);
    final bool alreadyStocked =
        controller.isProductFullyStocked(medicalProductData);
    final price =
        controller.getPriceDetails(medicalProductData.variants?.firstOrNull?.pricing);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(builder: (context, constraints) {
        final imageHeight = constraints.maxHeight * 0.42;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: (medicalProductData.images?.isNotEmpty ?? false)
                    ? CachedNetworkImage(
                        imageUrl: medicalProductData.images!.first.url ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        ),
                      )
                    : LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomText(
                      "${medicalProductData.name}",
                      fontSize: SizeConfig.small,
                      maxLines: 1,
                      color: AppColors.mainTextColor,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: AppColors.green00, width: 1),
                              borderRadius: BorderRadius.circular(2)),
                          padding: EdgeInsets.all(3),
                          child: Container(
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.green00),
                          ),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(width: 0.5, color: AppColors.greyE5)),
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                            child: CustomText(
                              _packLabel(medicalProductData.variants?.firstOrNull),
                              fontSize: 10,
                              color: Colors.grey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                    // "~" marks a price the catalog carries for other cities
                    // only — this shop's pincode has no row, so it's a
                    // reference figure, not what it sells at.
                    _priceRow(
                      price.isIndicative
                          ? '${AppStrings.price.tr} ~'
                          : AppStrings.price.tr,
                      price.sellingRange,
                      AppColors.primaryColor,
                      isBold: true,
                    ),
                    SizedBox(height: 2),
                    _priceRow(AppStrings.mrp.tr, price.mrpRange, AppColors.grayText),
                    SizedBox(height: 2),
                    _priceRow(AppStrings.discount.tr, price.discountRange, AppColors.green00, isBold: true),
                    SizedBox(height: 3),
                    // Already in this pharmacy's own inventory: adding it again
                    // would publish a duplicate record against the same
                    // catalogue variant. The button becomes a statement rather
                    // than a control, and the partial case gets its own line
                    // beneath.
                    if (alreadyStocked)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AlreadyAddedBadge(),
                      )
                    else
                      CustomBtn(
                        height: SizeConfig.size30,
                        onTap: () =>
                            controller.toggleSelection(medicalProductData),
                        title: isSelected
                            ? AppStrings.medicalAddedLabel.tr
                            : AppStrings.medicalAddBtnLabel.tr,
                        textColor:
                            isSelected ? AppColors.white : AppColors.primaryColor,
                        bgColor:
                            isSelected ? AppColors.primaryColor : AppColors.white,
                        radius: 6.0,
                        borderColor: AppColors.primaryColor,
                      ),
                    AlreadyAddedCountLine(
                      stocked:
                          controller.stockedVariantCount(medicalProductData),
                      total: medicalProductData.variants?.length ?? 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Pack size chip — "10 tablet", or just the unit when the catalog has no
  /// number for it.
  ///
  /// `weight` is genuinely absent on plenty of medical products (a spray has
  /// a unit but no quantity), and the old interpolation printed the missing
  /// value straight through, which is where the literal "null spray" on the
  /// card came from. Falls back to `variantName` so the chip never renders
  /// empty either.
  String _packLabel(VariantsData? variant) {
    if (variant == null) return '';
    final unit = (variant.unit ?? '').trim();
    final weight = variant.weight;
    if (weight != null && weight > 0) {
      final amount =
          weight == weight.roundToDouble() ? weight.round().toString() : '$weight';
      return unit.isEmpty ? amount : '$amount $unit';
    }
    if (unit.isNotEmpty) return unit;
    return (variant.variantName ?? '').trim();
  }

  Widget _priceRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      children: [
        CustomText(
          "$label: ",
          fontSize: 10,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w600,
        ),
        Flexible(
          child: CustomText(
            value,
            fontSize: 10,
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
