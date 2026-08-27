import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_seller.dart';
import 'package:BlueEra/features/me/product/model/single_product_model.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Public landing screen for the product share deep link
/// `https://beapp.in/app/product/{productId}` (optionally `?seller={userId}`).
///
/// ## What this screen has to work around
///
/// The link's id is the **master product** record. `GET products/{id}` answers
/// with the product — name, media, variants, features — and **no seller**,
/// because the same record is what every store listing that product points at.
/// So the shop has to be resolved separately; see
/// [ProductController.resolveProductSeller] and [ProductSeller].
///
/// The recipient is almost always a stranger arriving from WhatsApp, so every
/// section renders only when the payload actually carries it, and the three
/// states that used to be indistinguishable — loading, failed, and loaded — are
/// now distinct. Previously a failed or empty fetch drew the same bare card as
/// a successful one, which is why a shared product looked like an empty screen.
///
/// Laid out to match [ProductsStoreDetailsScreen], the in-app product screen,
/// so a product opened from a link and the same product opened from a store
/// read the same way.
class ShareProductScreen extends StatefulWidget {
  final String productId;

  /// The store the link was shared from, when it carried one. See
  /// [productDeepLink].
  final String? sellerUserId;

  const ShareProductScreen({
    super.key,
    required this.productId,
    this.sellerUserId,
  });

  @override
  State<ShareProductScreen> createState() => _ShareProductScreenState();
}

class _ShareProductScreenState extends State<ShareProductScreen> {
  // `getOrPut` rather than `Get.put`: the deep link can land on top of a
  // screen that already owns this controller, and a second `put` would
  // replace the live instance underneath it.
  final ProductController controller =
      getOrPut<ProductController>(() => ProductController());

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await controller.fetchSingleProductDataApi(productId: widget.productId);
    if (!mounted) return;
    // Only worth asking once the product is in: the fallback path reads
    // `created_by_business` off it.
    await controller.resolveProductSeller(sellerUserId: widget.sellerUserId);
  }

  /// Images to show: the master product's own media. Empty is a real case —
  /// a product record can be published before its photos are — so the carousel
  /// has a placeholder rather than collapsing to nothing.
  List<String> _mediaOf(SingleProductData product) => product.media;

  /// The variant the header prices itself from. First one with a price, so a
  /// zero-priced placeholder variant doesn't headline the product at ₹0.
  Variant? _headlineVariant(SingleProductData product) {
    if (product.variants.isEmpty) return null;
    return product.variants.firstWhere(
      (v) => v.sellingPrice > 0,
      orElse: () => product.variants.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF1,
      appBar: CommonBackAppBar(
        isLeading: true,
        title: AppStrings.productDetails,
        onBackTap: () => Get.back(),
      ),
      body: Obx(() {
        if (controller.isSingleProductLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        final product = controller.singleProductData.value;
        // A product that never arrived. The old screen drew its empty card
        // here, which read as "this product has nothing in it" rather than
        // "this didn't load" — and offered no way to try again.
        if (product == null) {
          return _ErrorState(onRetry: _load);
        }
        return _content(product);
      }),
      bottomNavigationBar: Obx(() {
        final seller = controller.productSeller.value;
        // Chatting needs someone to chat WITH, and the seller is the only
        // person this screen knows. No seller resolved, or the viewer IS the
        // seller, means no bar at all rather than a button that can't act.
        if (seller == null || seller.userId == userId) {
          return const SizedBox.shrink();
        }
        return _ChatBar(sellerUserId: seller.userId);
      }),
    );
  }

  Widget _content(SingleProductData product) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(product),
            SizedBox(height: SizeConfig.paddingXS),
            _buildProductInfoCard(product),
            SizedBox(height: SizeConfig.paddingXS),

            // The shop. Reactive on its own so the product renders the moment
            // it lands instead of waiting on a second request that decorates
            // one card.
            Obx(() {
              final seller = controller.productSeller.value;
              if (controller.isProductSellerLoading.isTrue) {
                return _SellerCardSkeleton();
              }
              if (seller == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.paddingXS),
                child: _SellerCard(seller: seller),
              );
            }),

            if (product.variants.isNotEmpty) ...[
              _buildVariantsSection(product),
              SizedBox(height: SizeConfig.paddingXS),
            ],
            if (product.description.trim().isNotEmpty) ...[
              _buildDescriptionSection(product),
              SizedBox(height: SizeConfig.paddingXS),
            ],
            if (product.addProductFeatures.isNotEmpty) ...[
              _buildFeaturesSection(product),
              SizedBox(height: SizeConfig.paddingXS),
            ],
            if (product.addMoreDetails.isNotEmpty) ...[
              _buildMoreDetailsSection(product),
              SizedBox(height: SizeConfig.paddingXS),
            ],
            _buildPricingSection(product),
            SizedBox(height: SizeConfig.size100),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE CAROUSEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildImageCarousel(SingleProductData product) {
    final media = _mediaOf(product);
    if (media.isEmpty) {
      return Container(
        height: SizeConfig.size350,
        width: double.infinity,
        color: AppColors.white,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return Container(
      height: SizeConfig.size350,
      color: AppColors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: media.length,
            options: CarouselOptions(
              height: SizeConfig.size350,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: false,
              autoPlay: media.length > 1,
              onPageChanged: (index, _) => setState(() => _currentIndex = index),
            ),
            itemBuilder: (context, index, realIdx) {
              return InkWell(
                onTap: () => navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: product.name,
                    subTitle: product.description,
                    imageUrls: media,
                    initialIndex: realIdx,
                  ),
                ),
                // `contain`, not `cover`: a shared product is often the first
                // thing a stranger sees of the shop, and cropping a garment
                // photo to fill the box hides the thing being sold.
                child: CachedNetworkImage(
                  imageUrl: media[index],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image,
                        size: 40, color: Colors.grey[400]),
                  ),
                ),
              );
            },
          ),
          if (media.length > 1)
            Positioned(
              bottom: 10,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.paddingS,
                  vertical: SizeConfig.size4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomText(
                  "${_currentIndex + 1}/${media.length}",
                  fontSize: SizeConfig.size12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT INFO (name, price, tags)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductInfoCard(SingleProductData product) {
    final variant = _headlineVariant(product);
    final sellingPrice = variant?.sellingPrice;
    final mrp = variant?.mrp;
    final discount = (mrp != null && mrp > 0 && sellingPrice != null)
        ? (((mrp - sellingPrice) / mrp) * 100).toInt()
        : 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              product.name.isNotEmpty ? product.name : AppStrings.na,
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 3,
            ),
            if (product.brand.trim().isNotEmpty) ...[
              SizedBox(height: SizeConfig.size4),
              CustomText(
                product.brand,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
              ),
            ],
            if (sellingPrice != null && sellingPrice > 0) ...[
              SizedBox(height: SizeConfig.paddingXS),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    '${AppConstants.rupeeSymbol}${_plain(sellingPrice)}',
                    fontSize: SizeConfig.size24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                  if (mrp != null && mrp > sellingPrice) ...[
                    SizedBox(width: SizeConfig.paddingXS),
                    CustomText(
                      '${AppConstants.rupeeSymbol}${_plain(mrp)}',
                      fontSize: SizeConfig.size14,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                    SizedBox(width: SizeConfig.paddingXS),
                    if (discount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.paddingXS,
                          vertical: SizeConfig.size2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          "$discount% ${AppStrings.offSuffix.tr}",
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ],
              ),
            ],
            if (product.tags.isNotEmpty) ...[
              SizedBox(height: SizeConfig.paddingS),
              Wrap(
                spacing: SizeConfig.paddingXS,
                runSpacing: SizeConfig.size4,
                children: product.tags
                    .map(
                      (tag) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.paddingXS,
                          vertical: SizeConfig.size2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          tag,
                          fontSize: SizeConfig.size11,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VARIANTS
  // ─────────────────────────────────────────────────────────────────────────
  /// The variants as chips — colour/size/whatever the product defines.
  ///
  /// Read-only: this screen sells nothing (there is no inventory context in a
  /// master product record), it shows what the product comes in and hands the
  /// buyer to the shop. Ordering happens on the store screen.
  Widget _buildVariantsSection(SingleProductData product) {
    return _sectionCard(
      icon: Icons.style_outlined,
      title: AppStrings.variant,
      child: Wrap(
        spacing: SizeConfig.size8,
        runSpacing: SizeConfig.size8,
        children: product.variants.map((v) {
          final label = _variantLabel(v);
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
              vertical: SizeConfig.size6,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  label.isEmpty ? AppStrings.na : label,
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                if (v.sellingPrice > 0) ...[
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    '${AppConstants.rupeeSymbol}${_plain(v.sellingPrice)}',
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// "Black · L" from whatever attributes the variant carries.
  ///
  /// The attribute map is dynamic by design — the catalogue defines its own
  /// keys per category — so this formats values rather than looking for names
  /// it expects. `color` is the one special case: it arrives as an object and
  /// would otherwise stringify to a map literal on the chip.
  String _variantLabel(Variant v) {
    final parts = <String>[];
    v.attributesMap.forEach((key, value) {
      if (value == null) return;
      if (value is Map) {
        final name = (value['color_name'] ?? value['name'] ?? '').toString();
        if (name.trim().isNotEmpty) parts.add(name.trim());
        return;
      }
      final str = value.toString().trim();
      if (str.isNotEmpty) parts.add(str);
    });
    return parts.join(' · ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DESCRIPTION / FEATURES / DETAILS / PRICING
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDescriptionSection(SingleProductData product) {
    return _sectionCard(
      icon: Icons.description_outlined,
      title: AppStrings.productDescription,
      child: ExpandableText(
        text: product.description,
        trimLines: 4,
        style: TextStyle(
          fontSize: SizeConfig.size13,
          color: AppColors.secondaryTextColor,
          height: 1.5,
        ),
        expandMode: ExpandMode.dialog,
        dialogTitle: AppStrings.productDescription,
      ),
    );
  }

  Widget _buildFeaturesSection(SingleProductData product) {
    return _sectionCard(
      icon: Icons.checklist_outlined,
      title: AppStrings.productFeatures,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: product.addProductFeatures
            .where((f) => f.title.trim().isNotEmpty)
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: Colors.green.shade600),
                    SizedBox(width: SizeConfig.paddingXS),
                    Expanded(
                      child: CustomText(
                        f.title,
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMoreDetailsSection(SingleProductData product) {
    return _sectionCard(
      icon: Icons.info_outline,
      title: AppStrings.moreDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: product.addMoreDetails
            .map((d) => _infoRow(d.title, d.details))
            .toList(),
      ),
    );
  }

  Widget _buildPricingSection(SingleProductData product) {
    final hasMrp = product.mrpPerUnit > 0;
    final hasWarranty = product.productWarrenty.trim().isNotEmpty;
    final hasGuide = product.guideLine.any((g) => g.trim().isNotEmpty);
    final returnable = product.isReturnable && product.returningDay > 0;

    if (!hasMrp && !hasWarranty && !hasGuide && !returnable) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      icon: Icons.sell_outlined,
      title: AppStrings.pricingWarranty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMrp)
            _infoRow(AppStrings.mrp.tr,
                '${AppConstants.rupeeSymbol}${_plain(product.mrpPerUnit)}'),
          if (hasWarranty)
            _infoRow(AppStrings.productWarranty.tr, product.productWarrenty),
          if (returnable)
            _infoRow(AppStrings.returnPolicy.tr,
                '${product.returningDay} ${AppStrings.daysUnit.tr}'),
          if (hasGuide) ...[
            SizedBox(height: SizeConfig.paddingXS),
            CustomText(
              '${AppStrings.userGuidance.tr}:',
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            ...product.guideLine.where((g) => g.trim().isNotEmpty).map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: CustomText(
                            g,
                            fontSize: SizeConfig.size13,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  /// Drops a trailing `.0` — prices arrive as doubles and "₹1299.0" reads as
  /// a rounding error rather than a price.
  String _plain(num v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: SizeConfig.size20, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.paddingXS),
                CustomText(
                  title,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingS),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: SizeConfig.size100 + SizeConfig.size20,
            child: CustomText(
              label,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          Expanded(
            child: CustomText(
              value.trim().isNotEmpty ? value : '-',
              fontSize: SizeConfig.size13,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// SELLER CARD
// ───────────────────────────────────────────────────────────────────────────
/// The shop behind the product, and the way into it.
///
/// Mirrors `_buildSellerCard` on [ProductsStoreDetailsScreen] so the same shop
/// looks the same whether the product was reached from a link or from inside
/// the app. Tapping opens the store for a business account and the personal
/// profile otherwise — the same split the in-app card makes.
class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});

  final ProductSeller seller;

  void _open() {
    if (seller.userId.isEmpty) return;
    Get.to(() => seller.isBusiness
        ? VisitProductStoreDetailsScreen(visitUserId: seller.userId)
        : NewVisitProfileScreen(
            authorId: seller.userId,
            screenFromName: AppConstants.storeFeedScreen,
          ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _open,
        child: CommonCardWidget(
          cardMargin: 0,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                backgroundImage: seller.logoUrl.isNotEmpty
                    ? NetworkImage(seller.logoUrl)
                    : null,
                child: seller.logoUrl.isEmpty
                    ? CustomText(
                        // Initials need a name; without one the generic shop
                        // glyph says more than an empty circle.
                        seller.name.isNotEmpty
                            ? getInitials(seller.name)
                            : null,
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      )
                    : null,
              ),
              SizedBox(width: SizeConfig.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      // The shop's name when the lookup produced one. When it
                      // didn't, the row still opens the shop, so it says so
                      // rather than showing a blank line.
                      seller.name.isNotEmpty
                          ? seller.name.capitalizeFirst!
                          : AppStrings.visitStore.tr,
                      fontSize: SizeConfig.size14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (seller.category.isNotEmpty)
                      CustomText(
                        seller.category,
                        fontSize: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      CustomText(
                        AppStrings.visitStore.tr,
                        fontSize: SizeConfig.size12,
                        color: AppColors.primaryColor,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: SizeConfig.size16, color: AppColors.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder in the seller card's slot while the shop is being resolved.
///
/// It holds the row's height so the sections below don't jump when the shop
/// lands a moment after the product.
class _SellerCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.paddingS,
        right: SizeConfig.paddingS,
        bottom: SizeConfig.paddingXS,
      ),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.greyE5,
            ),
            SizedBox(width: SizeConfig.paddingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 140, color: AppColors.greyE5),
                  SizedBox(height: SizeConfig.size6),
                  Container(height: 10, width: 90, color: AppColors.greyE5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// CHAT BAR
// ───────────────────────────────────────────────────────────────────────────
/// "Chat" with the shop — the one action a stranger arriving from a link can
/// take on a master product record.
///
/// There is no Add-to-Cart here on purpose: the link carries no inventory, so
/// there is no priced listing to add. The buyer is handed to the shop instead.
class _ChatBar extends StatelessWidget {
  const _ChatBar({required this.sellerUserId});

  final String sellerUserId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.paddingS,
          right: SizeConfig.paddingS,
          bottom: SizeConfig.paddingM,
          top: SizeConfig.paddingXSL,
        ),
        child: PositiveCustomBtn(
          title: AppStrings.chat,
          onTap: () {
            // A link recipient is very often signed out — send them to create
            // a profile rather than into a chat that cannot open.
            if (isGuestUser()) {
              createProfileScreen();
              return;
            }
            if (!Get.isRegistered<ChatViewController>()) return;
            Get.find<ChatViewController>().checkChatConnectionAndOpenChat(
              userId: sellerUserId,
              route: AppConstants.route_discover,
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ───────────────────────────────────────────────────────────────────────────
/// Shown when the product did not load — a dead link, a withdrawn product, or
/// a network that dropped.
///
/// The distinction that matters is between "nothing here" and "didn't load",
/// and the retry is the whole point: a share link is usually opened on the
/// move, and a flaky first request used to leave a permanently empty screen.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              AppStrings.productNotAvailable.tr,
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: SizeConfig.size12),
            TextButton(
              onPressed: onRetry,
              child: CustomText(
                AppStrings.retry.tr,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
