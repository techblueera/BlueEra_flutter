import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/card_image_action_chip.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/common_methods.dart';
import '../../../../../../core/services/share_service.dart';

/// Customer-facing product card for the self-pickup browse flow. Mirrors the
/// grocery `GroceryProductCard`: one card per PRODUCT, tapping it opens a
/// variants sheet where the customer ticks individual variants and saves them
/// into the cart.
///
/// The product cart ([ProductSelfPickupController]) is keyed by a product's
/// first variant id, so to support per-variant selection each ticked variant is
/// added as a single-variant clone of the product — no cart refactor needed and
/// the order payload naturally emits one line per selected variant.
class ProductCustomerCard extends StatelessWidget {
  final GetProductData product;
  final ProductSelfPickupController cartController;
  final String visitBusinessId;

  const ProductCustomerCard({
    super.key,
    required this.product,
    required this.cartController,
    required this.visitBusinessId,
  });

  // Name always reserves two lines so short and long names occupy the same
  // height — cards line up in the grid and the horizontal rail.
  static const double _nameLineHeight = 1.3;
  static double get _nameBlockHeight => SizeConfig.small * _nameLineHeight * 2;

  /// Exact content height of the card, so a fixed-height horizontal rail
  /// (the store-details top-selling section) can size itself to the card
  /// without leaving a gap below or clipping it.
  ///
  /// Scaled by the system text setting: the rail hands the card a TIGHT
  /// height, so a name block that grows with the user's font size while this
  /// doesn't overflows the rail (the same 2.5px overflow the grocery rail hit).
  static double get railCardHeight {
    const priceRowHeight = 26.0;
    final textScale =
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;
    // The add control lives ON the image now, so it adds no height here.
    return SizeConfig.size140 + // image
        SizeConfig.size6 * 2 + // details padding (top + bottom)
        _nameBlockHeight * textScale + // 2-line name block
        SizeConfig.size6 + // gap before price
        priceRowHeight;
  }

  List<Variant> get _variants => product.product.sellerClassification?.variants ?? const [];

  @override
  Widget build(BuildContext context) {
    final variants = _variants;
    final first = variants.isNotEmpty ? variants.first : null;
    final imageUrl = product.primaryImageUrl ?? '';
    final discount =
        (first != null && first.mrp > 0 && first.sellingPrice > 0 && first.sellingPrice < first.mrp)
            ? ((first.mrp - first.sellingPrice) / first.mrp * 100).round()
            : 0;

    return InkWell(
      onTap: () => _openVariantsSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + variants badge ──────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    height: SizeConfig.size140,
                    width: double.infinity,
                    child: _image(imageUrl),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blackMite,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomText(
                      '${variants.length} Variants',
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteFE,
                    ),
                  ),
                ),
                // Share moved to the top-LEFT so the top-right corner is free
                // for the add-to-cart chip — same corner assignment as the
                // grocery top-selling card.
                Positioned(
                  top: 6,
                  left: 6,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _shareProduct,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.blackMite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: LocalAssets(
                          imagePath: AppIconAssets.share_bold,
                          imgColor: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Add-to-cart chip on the image (top-right) rather than a
                // full-width button under the price — keeps the card compact
                // and matches the grocery cards.
                Positioned(
                  top: 6,
                  right: 6,
                  child: _buildAddChip(),
                ),
              ],
            ),

            // ── Details ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.0, vertical: SizeConfig.size6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _nameBlockHeight,
                    width: double.infinity,
                    child: CustomText(
                      product.product.details?.name ?? '',
                      fontSize: SizeConfig.small,
                      height: _nameLineHeight,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size6),
                  if (first != null)
                    PriceRow(
                      sellingPrice: '₹${first.sellingPrice.toStringAsFixed(0)}',
                      mrp: '₹${first.mrp.toStringAsFixed(0)}',
                      discount: '$discount% OFF',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String url) {
    if (url.isEmpty) {
      return LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.contain,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => Container(color: AppColors.greyE5),
      errorWidget: (_, __, ___) => LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.contain,
      ),
    );
  }

  /// Compact ADD / ADDED pill on the image (top-right); opens the same
  /// variants sheet the card body opens.
  Widget _buildAddChip() {
    return Obx(() {
      // Subscribe to the cart list so the chip flips on every add/remove.
      final _ = cartController.selectedProductVariants.length;
      final added = _variants.any((v) => cartController.isVariantInCart(v.id));
      return CardImageActionChip(
        active: added,
        icon: added ? Icons.check : Icons.add,
        label: added ? 'ADDED' : 'ADD',
        onTap: () => _openVariantsSheet(Get.context!),
      );
    });
  }

  Future<void> _shareProduct() async {
    final productId = product.product.details?.id ?? '';
    final name = product.product.details?.name ?? '';
    // The store this tile belongs to — a bare product id names the master
    // record, not the shop, and the recipient would land with no seller.
    final shareLink = productDeepLink(
      productId: productId,
      sellerUserId: product.product.user_id,
    );

    await ShareService.instance.openShareSheet(
      text: "Check out $name on BlueEra:\n$shareLink",
      subject: name,
    );
  }

  void _openVariantsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommonDraggableBottomSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        backgroundColor: AppColors.whiteF1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size10,
          bottom: 0,
        ),
        builder: (scrollController) => _ProductVariantsSheet(
          scrollController: scrollController,
          product: product,
          cartController: cartController,
          visitBusinessId: visitBusinessId,
        ),
      ),
    );
  }
}

/// Variants list with a local DRAFT selection — taps only mutate the draft;
/// nothing reaches the cart until the user taps Save (mirrors grocery).
class _ProductVariantsSheet extends StatefulWidget {
  final ScrollController scrollController;
  final GetProductData product;
  final ProductSelfPickupController cartController;
  final String visitBusinessId;

  const _ProductVariantsSheet({
    required this.scrollController,
    required this.product,
    required this.cartController,
    required this.visitBusinessId,
  });

  @override
  State<_ProductVariantsSheet> createState() => _ProductVariantsSheetState();
}

class _ProductVariantsSheetState extends State<_ProductVariantsSheet> {
  late final Set<String> _initialIds;
  late Set<String> _draftIds;

  List<Variant> get _variants => widget.product.product.sellerClassification?.variants ?? const [];

  @override
  void initState() {
    super.initState();
    _initialIds = _variants
        .map((v) => v.id)
        .where((id) => id.isNotEmpty && widget.cartController.isVariantInCart(id))
        .toSet();
    _draftIds = {..._initialIds};
  }

  bool get _hasChanges => _draftIds.length != _initialIds.length || !_draftIds.containsAll(_initialIds);

  void _toggleDraft(Variant v) {
    if (v.id.isEmpty) return;
    setState(() {
      if (_draftIds.contains(v.id)) {
        _draftIds.remove(v.id);
      } else {
        _draftIds.add(v.id);
      }
    });
  }

  /// A deep clone of the product narrowed to a single [variantId], so the
  /// product cart (keyed by first-variant-id) treats each selected variant as
  /// its own line.
  GetProductData _singleVariantClone(String variantId) {
    final clone = GetProductData.fromJson(widget.product.toJson());
    clone.product.sellerClassification?.variants.retainWhere((v) => v.id == variantId);
    return clone;
  }

  void _save() {
    final toAdd = _draftIds.difference(_initialIds);
    final toRemove = _initialIds.difference(_draftIds);

    final bDetails = Get.isRegistered<ViewBusinessDetailsController>()
        ? Get.find<ViewBusinessDetailsController>().visitedBusinessProfileDetails?.data
        : null;

    for (final id in toRemove) {
      widget.cartController.removeFromCart(_singleVariantClone(id));
    }
    for (final id in toAdd) {
      widget.cartController.addToCart(
        _singleVariantClone(id),
        userId: widget.visitBusinessId,
        businessName: bDetails?.businessName,
        businessLogo: bDetails?.logo,
        businessAddress: bDetails?.address,
      );
    }
    Navigator.of(context).pop();
  }

  String _variantLabel(Variant v) {
    final parts = <String>[];
    v.attributes.forEach((key, value) {
      if (value == null) return;
      if (key.toLowerCase() == 'color' && value is Map) {
        final name = (value['color_name'] ?? '').toString();
        if (name.isNotEmpty) parts.add(name);
      } else {
        final s = value.toString();
        if (s.isNotEmpty) parts.add(s);
      }
    });
    if (parts.isEmpty) return widget.product.product.details?.name ?? 'Variant';
    return parts.join(' · ');
  }

  String _variantImage(Variant v) {
    if (v.mediaRelatedToVariant.isNotEmpty && v.mediaRelatedToVariant.first.isNotEmpty) {
      return v.mediaRelatedToVariant.first;
    }
    return widget.product.primaryImageUrl ?? '';
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
                      widget.product.product.details?.name ?? 'All Variants',
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
                itemCount: _variants.length,
                separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
                itemBuilder: (_, i) => _variantTile(_variants[i]),
              ),
            ],
          ),
        ),
        _saveBar(),
      ],
    );
  }

  Widget _variantTile(Variant v) {
    final isSelected = _draftIds.contains(v.id);
    final image = _variantImage(v);
    final discount = (v.mrp > 0 && v.sellingPrice > 0 && v.sellingPrice < v.mrp)
        ? ((v.mrp - v.sellingPrice) / v.mrp * 100).round()
        : 0;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: SizeConfig.size50,
              height: SizeConfig.size50,
              child: image.isEmpty
                  ? LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.contain,
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(color: AppColors.greyE5),
                      errorWidget: (_, __, ___) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.contain,
                      ),
                    ),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(_variantLabel(v),
                    fontWeight: FontWeight.w600, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                PriceRow(
                  sellingPrice: '₹${v.sellingPrice.toStringAsFixed(0)}',
                  mrp: '₹${v.mrp.toStringAsFixed(0)}',
                  discount: '$discount% OFF',
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(height: SizeConfig.size50, width: 1),
          ),
          SizedBox(width: SizeConfig.size10),
          _toggleButton(v, isSelected),
        ],
      ),
    );
  }

  Widget _toggleButton(Variant v, bool isSelected) {
    return SizedBox(
      width: SizeConfig.size70,
      height: SizeConfig.size30,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _toggleDraft(v),
        child: Container(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? Icons.remove : Icons.add,
                  size: 12, color: isSelected ? AppColors.red : AppColors.primaryColor),
              const SizedBox(width: 3),
              CustomText(
                isSelected ? 'REMOVE' : 'ADD',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.red : AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveBar() {
    final selected = _draftIds.length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.greyE5.withValues(alpha: 0.7), width: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: SizeConfig.size8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: CustomText(
                  selected == 0
                      ? 'Tap variants to add or remove'
                      : '$selected ${selected == 1 ? "item" : "items"} selected',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              GestureDetector(
                onTap: _hasChanges ? _save : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    color: _hasChanges ? AppColors.primaryColor : AppColors.greyE5.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'Save',
                        color: _hasChanges ? AppColors.white : AppColors.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: _hasChanges ? AppColors.white : AppColors.secondaryTextColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
