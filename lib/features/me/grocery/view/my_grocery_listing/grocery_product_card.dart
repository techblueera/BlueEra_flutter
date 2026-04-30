import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/model/images.dart';

enum GroceryCardFlowType { myStore, selfPickup, rider }

class GroceryProductCard extends StatelessWidget {
  final GroceryProductData groceryProducts;
  final GroceryCardFlowType flowType;
  final String? bId; // only needed for selfPickup flow

  GroceryProductCard({
    Key? key,
    required this.groceryProducts,
    required this.flowType,
    this.bId,
  }) : super(key: key);

  GroceryController get _groceryController => getOrPut(() => GroceryController());
  ViewBusinessDetailsController get _viewBusinessDetailsController =>
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  List<ProductVariants> get _variants {
    Images? productImage;
    if (groceryProducts.images != null && groceryProducts.images!.isNotEmpty) {
      productImage = groceryProducts.images![0];
    }
    final variants = groceryProducts.variants ?? [];
    for (final variant in variants) {
      if (productImage != null) {
        if (variant.images == null) {
          variant.images = [productImage];
        } else if (variant.images!.isEmpty) {
          variant.images!.add(productImage);
        }
      }
    }
    return variants;
  }

  @override
  Widget build(BuildContext context) {
    final price = _groceryController.getPriceDetails(
      groceryProducts.variants?.isNotEmpty == true
          ? groceryProducts.variants![0].pricing
          : null,
    );
    final imageUrl = groceryProducts.images?.isNotEmpty == true
        ? groceryProducts.images![0].url ?? ''
        : '';

    return InkWell(
      onTap: () => _showVariantsBottomSheet(Get.context!, _variants),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badges ────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    height: SizeConfig.size140,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => LocalAssets(
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

                // "+N Variants" badge — bottom-right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.blackMite,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomText(
                          AppStrings.groceryViewVariantsBadge.trParams({'count': '${groceryProducts.variants?.length ?? 0}'}),
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteFE,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3-dot menu — top-right (myStore only)
                if (flowType == GroceryCardFlowType.myStore)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blackMite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppColors.whiteFE,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Details ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 9.0,
                vertical: SizeConfig.size6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  CustomText(
                    groceryProducts.name ?? '',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size6),

                  // Veg dot + quantity badge
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.all(3.5),
                        child: Container(
                          height: 7,
                          width: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00,
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(width: 0.5, color: AppColors.greyE5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        child: CustomText(
                          '${groceryProducts.variants?[0].quantity ?? ''}',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size6),

                  // Price
                  PriceRow(
                    sellingPrice: '${price.sellingRange}',
                    mrp: '${price.mrpRange}',
                    discount: '${price.discountRange}',
                  ),
                  SizedBox(height: SizeConfig.size8),

                  // Action button
                  if (flowType == GroceryCardFlowType.myStore)
                    // _buildEditButton(onTap: () {})
                    SizedBox()
                  else
                    _buildCardAddButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAddButton() {
    return Obx(() {
      final bool isAdded;
      if (flowType == GroceryCardFlowType.selfPickup) {
        final ctrl = Get.find<GrocerySelfPickupConsumerController>();
        isAdded = groceryProducts.variants?.any(
              (v) => ctrl.selectedGroceriesVariants.any((s) => s.sId == v.sId),
            ) ??
            false;
      } else {
        final ctrl = Get.find<GroceryRiderConsumerController>();
        isAdded = groceryProducts.variants?.any(
              (v) => ctrl.selectedGroceriesVariants.any((s) => s.sId == v.sId),
            ) ??
            false;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: SizeConfig.size30,
        decoration: BoxDecoration(
          color: isAdded
              ? AppColors.green00.withValues(alpha: 0.08)
              : AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAdded ? AppColors.green00 : AppColors.primaryColor,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showVariantsBottomSheet(Get.context!, _variants),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isAdded ? Icons.check : Icons.add,
                  key: ValueKey(isAdded),
                  size: 12,
                  color: isAdded ? AppColors.green00 : AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: CustomText(
                  isAdded ? AppStrings.groceryViewAddedCaps.tr : AppStrings.groceryViewAddCaps.tr,
                  key: ValueKey(isAdded),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAdded ? AppColors.green00 : AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showVariantsBottomSheet(
      BuildContext context,
      List<ProductVariants> variants,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.whiteF1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            // Why: drop the kToolbarHeight bottom gap so the sticky save
            // footer can hug the sheet edge. The footer's own SafeArea
            // reserves space for the system home indicator.
            bottom: 0,
          ),
          builder: (scrollController) {
            return _VariantsSheetContent(
              scrollController: scrollController,
              product: groceryProducts,
              variants: variants,
              flowType: flowType,
              bId: bId,
              groceryController: _groceryController,
              businessDetailsController: _viewBusinessDetailsController,
            );
          },
        );
      },
    );
  }

}

/// Bottom-sheet body for the variants list. Holds a local DRAFT selection
/// (Set of variant IDs) so taps on add/remove only mutate the draft —
/// nothing reaches the cart controller until the user taps Save. Closing
/// the sheet (X / drag-down) discards the draft.
class _VariantsSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  final GroceryProductData product;
  final List<ProductVariants> variants;
  final GroceryCardFlowType flowType;
  final String? bId;
  final GroceryController groceryController;
  final ViewBusinessDetailsController businessDetailsController;

  const _VariantsSheetContent({
    required this.scrollController,
    required this.product,
    required this.variants,
    required this.flowType,
    required this.bId,
    required this.groceryController,
    required this.businessDetailsController,
  });

  @override
  State<_VariantsSheetContent> createState() => _VariantsSheetContentState();
}

class _VariantsSheetContentState extends State<_VariantsSheetContent> {
  GrocerySelfPickupConsumerController? _selfPickup;
  GroceryRiderConsumerController? _rider;
  late final Set<String> _initialIds;
  late Set<String> _draftIds;

  bool get _isCartFlow =>
      widget.flowType == GroceryCardFlowType.selfPickup ||
      widget.flowType == GroceryCardFlowType.rider;

  @override
  void initState() {
    super.initState();
    if (widget.flowType == GroceryCardFlowType.selfPickup) {
      _selfPickup = Get.find<GrocerySelfPickupConsumerController>();
    } else if (widget.flowType == GroceryCardFlowType.rider) {
      _rider = Get.find<GroceryRiderConsumerController>();
    }
    _initialIds = _readCartIds();
    _draftIds = {..._initialIds};
  }

  Set<String> _readCartIds() {
    final cart = _selfPickup?.selectedGroceriesVariants ??
        _rider?.selectedGroceriesVariants ??
        const <ProductVariants>[];
    return widget.variants
        .map((v) => v.sId ?? '')
        .where((id) => id.isNotEmpty && cart.any((c) => c.sId == id))
        .toSet();
  }

  bool get _hasChanges =>
      _draftIds.length != _initialIds.length ||
      !_draftIds.containsAll(_initialIds);

  void _toggleDraft(ProductVariants variant) {
    final id = variant.sId ?? '';
    if (id.isEmpty) return;
    setState(() {
      if (_draftIds.contains(id)) {
        _draftIds.remove(id);
      } else {
        _draftIds.add(id);
      }
    });
  }

  void _save() {
    final toAdd = _draftIds.difference(_initialIds);
    final toRemove = _initialIds.difference(_draftIds);
    final bDetails =
        widget.businessDetailsController.visitedBusinessProfileDetails?.data;

    for (final id in toRemove) {
      final v = widget.variants.firstWhere((x) => x.sId == id);
      if (widget.flowType == GroceryCardFlowType.selfPickup) {
        _selfPickup?.removeFromCart(v);
      } else {
        _rider?.removeFromCart(v);
      }
    }
    for (final id in toAdd) {
      final v = widget.variants.firstWhere((x) => x.sId == id);
      if (widget.flowType == GroceryCardFlowType.selfPickup) {
        _selfPickup?.addToCart(
          v,
          productId: v.sId,
          inventoryId: v.inventory?.inventoryId,
          businessId: widget.bId,
          businessName: bDetails?.businessName,
          businessLogo: bDetails?.logo,
          businessAddress: bDetails?.address,
          // Pass image + lat/lng/category so the cart screen can render
          // distance, shop-type pill and a thumbnail without re-fetching
          // the business profile.
          productImage: (widget.product.images?.isNotEmpty ?? false)
              ? widget.product.images!.first.url
              : null,
          businessLat: bDetails?.businessLocation?.lat?.toDouble(),
          businessLng: bDetails?.businessLocation?.lon?.toDouble(),
          businessCategory: bDetails?.subCategoryDetails?.name ??
              bDetails?.categoryOfBusiness ??
              bDetails?.natureOfBusiness,
        );
      } else {
        _rider?.addToCart(
          v,
          productId: v.sId,
          inventoryId: v.inventory?.inventoryId,
        );
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTextColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      widget.product.name ?? AppStrings.groceryViewAllVariants.tr,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  const CloseButton(),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.variants.length,
                separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
                itemBuilder: (_, index) {
                  final variant = widget.variants[index];
                  final productImage =
                      (widget.product.images?.isNotEmpty ?? false)
                          ? widget.product.images![0].url ?? ''
                          : '';
                  return _variantTile(variant, productImage);
                },
              ),
            ],
          ),
        ),
        if (_isCartFlow) _saveBar(),
      ],
    );
  }

  Widget _variantTile(ProductVariants variant, String productImage) {
    final price = widget.groceryController.getPriceDetails(variant.pricing);
    final isSelected = _draftIds.contains(variant.sId ?? '');

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        children: [
          (productImage.isNotEmpty)
              ? CustomImageSlideshow(
                  isLoading: false,
                  width: SizeConfig.size50,
                  height: SizeConfig.size50,
                  imagePaths: [productImage],
                  borderRadius: BorderRadius.circular(6),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.fill,
                    width: SizeConfig.size50,
                    height: SizeConfig.size50,
                  ),
                ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(variant.variantName ?? '', fontWeight: FontWeight.w600),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CustomText(
                      '${variant.quantity}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 0.5,
                      height: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    PriceRow(
                      sellingPrice: '${price.sellingRange}',
                      mrp: '${price.mrpRange}',
                      discount: '${price.discountRange}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          if (_isCartFlow) ...[
            DashedBorderContainer(
              borderColor: AppColors.greyE5,
              strokeWidth: 1,
              dashLength: 2,
              child: SizedBox(height: SizeConfig.size50, width: 1),
            ),
            SizedBox(width: SizeConfig.size10),
            _draftToggleButton(variant, isSelected),
          ],
        ],
      ),
    );
  }

  Widget _draftToggleButton(ProductVariants variant, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: SizeConfig.size70,
      height: SizeConfig.size30,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.red.withValues(alpha: 0.08)
            : AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.red : AppColors.primaryColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _toggleDraft(variant),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? Icons.remove : Icons.add,
                key: ValueKey(isSelected),
                size: 12,
                color: isSelected ? AppColors.red : AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 3),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: CustomText(
                isSelected
                    ? AppStrings.groceryViewRemoveCaps.tr
                    : AppStrings.groceryViewAddCaps.tr,
                key: ValueKey(isSelected),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.red : AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveBar() {
    final int selected = _draftIds.length;
    final int added = _draftIds.difference(_initialIds).length;
    final int removed = _initialIds.difference(_draftIds).length;

    // Why: full-bleed white footer with a hairline divider + soft upward
    // shadow gives the sheet a sticky checkout-bar feel, separating the
    // CTA from the scrolling list above without a hard line.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.greyE5.withValues(alpha: 0.7),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // Why: minimum bottom inset gives breathing room on devices
        // without a home indicator while still respecting it where present.
        minimum: EdgeInsets.only(bottom: SizeConfig.size8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Why: Flexible (not Expanded) so the summary takes only
              // what it needs and the CTA stays right-anchored — combined
              // with spaceBetween this pushes them to opposite ends.
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _hasChanges
                      ? _saveBarSummary(selected, added, removed)
                      : _saveBarIdleHint(),
                ),
              ),
              _saveBarCta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveBarSummary(int total, int added, int removed) {
    return Row(
      key: ValueKey('save_summary_${added}_$removed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: SizeConfig.size30,
          height: SizeConfig.size30,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(SizeConfig.size8),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.shopping_basket_rounded,
            size: 16,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                total == 0
                    ? 'No items'
                    : '$total ${total == 1 ? "item" : "items"} selected',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
              ),
              SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (added > 0) ...[
                    _saveBarDeltaChip(
                      label: '+$added',
                      color: AppColors.green00,
                    ),
                    SizedBox(width: SizeConfig.size4),
                  ],
                  if (removed > 0) ...[
                    _saveBarDeltaChip(
                      label: '−$removed',
                      color: AppColors.red,
                    ),
                    SizedBox(width: SizeConfig.size4),
                  ],
                  Flexible(
                    child: CustomText(
                      'unsaved',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _saveBarDeltaChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  Widget _saveBarIdleHint() {
    return Row(
      key: const ValueKey('save_idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: SizeConfig.size30,
          height: SizeConfig.size30,
          decoration: BoxDecoration(
            color: AppColors.greyE5.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(SizeConfig.size8),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.tune_rounded,
            size: 14,
            color: AppColors.secondaryTextColor,
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'No changes',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: 2),
              CustomText(
                'Tap variants to add or remove',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _saveBarCta() {
    final bool enabled = _hasChanges;
    // Why: the elevated/glowing primary state vs the muted disabled state
    // is the loudest affordance — reads at a glance whether tapping will
    // actually do anything.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primaryColor
            : AppColors.greyE5.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          onTap: enabled ? _save : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12 + SizeConfig.size4,
              vertical: SizeConfig.size12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  AppStrings.save.tr,
                  color: enabled
                      ? AppColors.white
                      : AppColors.secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                SizedBox(width: SizeConfig.size6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: enabled
                      ? AppColors.white
                      : AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}