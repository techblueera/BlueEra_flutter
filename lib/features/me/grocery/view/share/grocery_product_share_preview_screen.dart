import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Public landing screen reached from the grocery share deep link
/// `https://beapp.in/app/grocery/{productId}`. Hits
/// `GET /grocery-service/api/products/{productId}`, parses into
/// [GroceryProductData], and renders the design from img_1 + img_2:
/// hero image → Quick Actions → Current Price → Brand & Origin →
/// Variants → Product Details → Tags.
///
/// Scoped to deep-link use only — no in-app navigation paths should
/// open this screen. Card-tap flows continue to use the variants sheet
/// or store details.
class GroceryProductSharePreviewScreen extends StatefulWidget {
  final String productId;

  const GroceryProductSharePreviewScreen({
    super.key,
    required this.productId,
  });

  @override
  State<GroceryProductSharePreviewScreen> createState() =>
      _GroceryProductSharePreviewScreenState();
}

class _GroceryProductSharePreviewScreenState
    extends State<GroceryProductSharePreviewScreen> {
  final GrocerySelfPickupConsumerController _cart =
      getOrPut<GrocerySelfPickupConsumerController>(
          () => GrocerySelfPickupConsumerController());

  GroceryProductData? _product;
  bool _loading = true;
  String? _error;
  bool _variantsExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ResponseModel res =
        await GroceryRepo().fetchGroceryProductByIdRepo(widget.productId);
    if (!mounted) return;
    if (res.isSuccess && res.response?.data != null) {
      // Endpoint returns either the bare product object or a `{ data: {...} }`
      // envelope. Handle both so the deep-link landing doesn't break if the
      // backend shape evolves.
      final raw = res.response!.data;
      final Map<String, dynamic>? payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : null;
      if (payload != null) {
        setState(() {
          _product = GroceryProductData.fromJson(payload);
          _loading = false;
        });
        return;
      }
    }
    setState(() {
      _loading = false;
      _error = AppStrings.noDataFound.tr;
    });
  }

  /// First variant with pricing wins, else first overall — drives the
  /// Current Price card and the two CTAs.
  ProductVariants? get _firstVariant {
    final variants = _product?.variants;
    if (variants == null || variants.isEmpty) return null;
    return variants.firstWhere(
      (v) => (v.pricing?.isNotEmpty ?? false),
      orElse: () => variants.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: _product?.name ?? 'Product',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? _errorView()
              : _content(_product!),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_basket_outlined,
              size: 48, color: AppColors.secondaryTextColor),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            _error ?? AppStrings.noDataFound.tr,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          TextButton(
            onPressed: _fetch,
            child: CustomText(
              'Retry',
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(GroceryProductData product) {
    final imageUrl = (product.images?.isNotEmpty ?? false)
        ? product.images!.first.url
        : null;
    final inStock = product.isActive == true;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroCard(product, imageUrl, inStock),
          SizedBox(height: SizeConfig.size12),
          _quickActionsCard(),
          SizedBox(height: SizeConfig.size12),
          _currentPriceCard(),
          SizedBox(height: SizeConfig.size12),
          _brandOriginCard(product),
          SizedBox(height: SizeConfig.size12),
          if ((product.variants?.isNotEmpty ?? false)) ...[
            _variantsCard(product),
            SizedBox(height: SizeConfig.size12),
          ],
          _productDetailsCard(),
          if ((product.tags?.isNotEmpty ?? false)) ...[
            SizedBox(height: SizeConfig.size12),
            _tagsCard(product),
          ],
        ],
      ),
    );
  }

  // ─── Hero (image + identity + description) ────────────────────────
  Widget _heroCard(GroceryProductData product, String? imageUrl, bool inStock) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFF4F6FA)),
                      errorWidget: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          Wrap(
            spacing: SizeConfig.size6,
            runSpacing: SizeConfig.size6,
            children: [
              if (product.isVegetarian == true)
                _tagPill('Vegetarian', accent: const Color(0xFF1F7A3F)),
              if (product.isVegetarian == false)
                _tagPill('Non-Vegetarian', accent: const Color(0xFFB00020)),
              _tagPill(inStock ? 'In Stock' : 'Out of Stock',
                  accent: inStock
                      ? AppColors.primaryColor
                      : AppColors.secondaryTextColor),
              if ((product.sId ?? '').isNotEmpty) _tagPill(product.sId!),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            product.name ?? '—',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          if ((product.description ?? '').trim().isNotEmpty) ...[
            SizedBox(height: SizeConfig.size8),
            ExpandableText(
              text: product.description!.trim(),
              trimLines: 4,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFFF4F6FA),
        alignment: Alignment.center,
        child: LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          height: 80,
          width: 80,
        ),
      );

  // ─── Quick Actions ────────────────────────────────────────────────
  Widget _quickActionsCard() {
    final variant = _firstVariant;
    final canBuy = variant != null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('QUICK ACTIONS'),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            final qty = _cart.getQuantity(variant?.sId);
            return Column(
              children: [
                _primaryButton(
                  label: qty > 0 ? 'Added to Cart ($qty)' : 'Add to Cart',
                  icon: Icons.shopping_cart_outlined,
                  enabled: canBuy,
                  onTap: canBuy ? () => _addToCart(variant) : null,
                ),
                SizedBox(height: SizeConfig.size10),
                _secondaryButton(
                  label: 'Buy Now',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF1F7A3F),
                  enabled: canBuy,
                  onTap: canBuy ? () => _buyNow(variant) : null,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Current Price ────────────────────────────────────────────────
  Widget _currentPriceCard() {
    final variant = _firstVariant;
    final pricing =
        (variant?.pricing?.isNotEmpty ?? false) ? variant!.pricing!.first : null;
    final selling = pricing?.sellingPrice;
    final mrp = pricing?.mrp;
    final city = (pricing?.cityName ?? '').trim();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('CURRENT PRICE'),
          SizedBox(height: SizeConfig.size12),
          if (selling != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  '₹$selling',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                if (mrp != null && _showStrike(mrp, selling)) ...[
                  SizedBox(width: SizeConfig.size8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '₹$mrp',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            CustomText(
              '—',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          if (city.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              'Price for $city',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Brand & Origin ───────────────────────────────────────────────
  Widget _brandOriginCard(GroceryProductData product) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Brand',
          (product.brand ?? '').trim().isEmpty ? '—' : product.brand!.trim()),
      MapEntry(
          'Country',
          (product.countryOfOrigin ?? '').trim().isEmpty
              ? '—'
              : product.countryOfOrigin!.trim()),
      MapEntry('Status', product.isActive == true ? 'Active' : 'Inactive'),
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('BRAND & ORIGIN'),
          SizedBox(height: SizeConfig.size12),
          for (var i = 0; i < rows.length; i++) ...[
            _kvRow(rows[i].key, rows[i].value),
            if (i != rows.length - 1) SizedBox(height: SizeConfig.size8),
          ],
        ],
      ),
    );
  }

  // ─── Variants list with Hide/Show toggle ──────────────────────────
  Widget _variantsCard(GroceryProductData product) {
    final variants = product.variants ?? const <ProductVariants>[];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('VARIANTS'),
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      '${variants.length} options',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () =>
                    setState(() => _variantsExpanded = !_variantsExpanded),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size12,
                    vertical: SizeConfig.size6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        _variantsExpanded ? 'Hide' : 'Show',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      Icon(
                        _variantsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.mainTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_variantsExpanded) ...[
            SizedBox(height: SizeConfig.size12),
            for (var i = 0; i < variants.length; i++) ...[
              _variantRow(variants[i]),
              if (i != variants.length - 1) SizedBox(height: SizeConfig.size10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _variantRow(ProductVariants v) {
    final pricing = (v.pricing?.isNotEmpty ?? false) ? v.pricing!.first : null;
    final selling = pricing?.sellingPrice;
    final mrp = pricing?.mrp;
    final city = (pricing?.cityName ?? '').trim();
    final currency = (pricing?.currency ?? '').trim();
    final variantName = (v.variantName ?? '').trim();
    final unit = (v.unit ?? '').trim();
    final title = [
      if (variantName.isNotEmpty) variantName,
      if (variantName.isNotEmpty && unit.isNotEmpty) '•',
      if (unit.isNotEmpty) unit,
    ].join(' ');
    final sku = (v.sku ?? '').trim();

    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  title.isEmpty ? '—' : title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (selling != null)
                    CustomText(
                      '₹$selling',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  if (mrp != null &&
                      selling != null &&
                      _showStrike(mrp, selling))
                    Text(
                      '₹$mrp',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (sku.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              'SKU: $sku',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
          if (city.isNotEmpty || currency.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              [if (city.isNotEmpty) city, if (currency.isNotEmpty) currency]
                  .join('   '),
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Product Details ─────────────────────────────────────────────
  /// Hard-coded N/A — matches the web design. The model doesn't carry
  /// weight / packType / shelfLife today; populate these once the
  /// backend surfaces them on the single-product response.
  Widget _productDetailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PRODUCT DETAILS'),
          SizedBox(height: SizeConfig.size12),
          _kvRow('Weight', 'N/A'),
          SizedBox(height: SizeConfig.size8),
          _kvRow('Pack Type', 'N/A'),
          SizedBox(height: SizeConfig.size8),
          _kvRow('Shelf Life', 'N/A'),
        ],
      ),
    );
  }

  // ─── Tags ─────────────────────────────────────────────────────────
  Widget _tagsCard(GroceryProductData product) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('TAGS'),
          SizedBox(height: SizeConfig.size12),
          Wrap(
            spacing: SizeConfig.size8,
            runSpacing: SizeConfig.size8,
            children: (product.tags ?? [])
                .where((t) => t.trim().isNotEmpty)
                .map((t) => _tagPill(t))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Building blocks ──────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001022),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String label) {
    return CustomText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: AppColors.secondaryTextColor,
      letterSpacing: 1.2,
    );
  }

  Widget _kvRow(String key, String value) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            key,
            fontSize: SizeConfig.medium,
            color: AppColors.secondaryTextColor,
          ),
        ),
        CustomText(
          value,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }

  Widget _tagPill(String label, {Color? accent}) {
    final color = accent ?? AppColors.primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 13, color: color),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            SizedBox(width: SizeConfig.size8),
            CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    Color? iconColor,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor.withValues(alpha: 0.4)
                : AppColors.greyE5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor ?? AppColors.primaryColor),
            SizedBox(width: SizeConfig.size8),
            CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  bool _showStrike(num mrp, num selling) => mrp > selling;

  // ─── Cart actions ─────────────────────────────────────────────────
  void _addToCart(ProductVariants variant) {
    _cart.addToCart(
      variant,
      productId: _product?.sId,
      inventoryId: variant.sId,
      // Deep-link landing has no seller context; the cart row will fall
      // back to the variant's own metadata.
      productImage: (variant.images?.isNotEmpty ?? false)
          ? variant.images!.first.url
          : (_product?.images?.isNotEmpty ?? false)
              ? _product!.images!.first.url
              : null,
    );
  }

  void _buyNow(ProductVariants variant) {
    if (_cart.getQuantity(variant.sId) == 0) {
      _addToCart(variant);
    }
    Get.to(() => const GrocerySelfPickUpCartScreen());
  }
}
