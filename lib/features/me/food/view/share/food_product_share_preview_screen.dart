import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Public landing screen reached from the food share deep link
/// `https://beapp.in/app/food/{foodId}`. Hits
/// `GET /food-service/api/foodProduct/{foodId}`, parses into
/// [CategoryFoodProductData], and renders a read-only preview:
/// hero image → Current Price → Variants → Ingredients →
/// Cooking Method → Nutrition → Category.
///
/// Scoped to deep-link use only — mirrors
/// `GroceryProductSharePreviewScreen`. No in-app navigation paths
/// should open this screen.
class FoodProductSharePreviewScreen extends StatefulWidget {
  final String foodId;

  const FoodProductSharePreviewScreen({
    super.key,
    required this.foodId,
  });

  @override
  State<FoodProductSharePreviewScreen> createState() =>
      _FoodProductSharePreviewScreenState();
}

class _FoodProductSharePreviewScreenState
    extends State<FoodProductSharePreviewScreen> {
  CategoryFoodProductData? _product;
  bool _loading = true;
  String? _error;

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
        await FoodRepo().fetchSingleFoodProductDetailsRepo(foodID: widget.foodId);
    if (!mounted) return;
    if (res.isSuccess && res.response?.data != null) {
      // Endpoint returns either the bare product object or a `{ data: {...} }`
      // envelope. Handle both so the deep-link landing doesn't break if the
      // backend shape evolves.
      final raw = res.response!.data;
      final dynamic payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic> ? raw['data'] : raw)
          : null;
      if (payload != null) {
        setState(() {
          _product = CategoryFoodProductData.fromJson(payload);
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

  /// First default variant with pricing wins, else first overall —
  /// drives the Current Price card.
  FoodVariants? get _firstVariant {
    final variants = _product?.variants;
    if (variants == null || variants.isEmpty) return null;
    return variants.firstWhere(
      (v) => v.isDefault == true,
      orElse: () => variants.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: _product?.name ?? 'Food',
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
          const Icon(Icons.restaurant_menu_outlined,
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

  Widget _content(CategoryFoodProductData product) {
    final imageUrl =
        (product.images?.isNotEmpty ?? false) ? product.images!.first : null;
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
          _currentPriceCard(product),
          if ((product.variants?.isNotEmpty ?? false)) ...[
            SizedBox(height: SizeConfig.size12),
            _variantsCard(product),
          ],
          if ((product.ingredients?.isNotEmpty ?? false)) ...[
            SizedBox(height: SizeConfig.size12),
            _chipsCard('INGREDIENTS', product.ingredients!),
          ],
          if ((product.cookingMethod?.isNotEmpty ?? false)) ...[
            SizedBox(height: SizeConfig.size12),
            _chipsCard('COOKING METHOD', product.cookingMethod!),
          ],
          if (product.nutritionalInfo != null) ...[
            SizedBox(height: SizeConfig.size12),
            _nutritionCard(product.nutritionalInfo!),
          ],
          if ((product.category?.name ?? '').trim().isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            _categoryCard(product),
          ],
        ],
      ),
    );
  }

  // ─── Hero (image + identity + description) ────────────────────────
  Widget _heroCard(
      CategoryFoodProductData product, String? imageUrl, bool inStock) {
    final dietary = (product.dietaryType ?? '').trim();
    final isVeg = dietary.toLowerCase().contains('veg') &&
        !dietary.toLowerCase().contains('non');
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
                      fit: BoxFit.cover,
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
              if (dietary.isNotEmpty)
                _tagPill(
                  isVeg ? 'Vegetarian' : dietary,
                  accent: isVeg
                      ? const Color(0xFF1F7A3F)
                      : const Color(0xFFB00020),
                ),
              _tagPill(inStock ? 'Available' : 'Unavailable',
                  accent: inStock
                      ? AppColors.primaryColor
                      : AppColors.secondaryTextColor),
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

  // ─── Current Price ────────────────────────────────────────────────
  Widget _currentPriceCard(CategoryFoodProductData product) {
    final variant = _firstVariant;
    final selling = product.displayPrice ?? variant?.baseSellingPrice;
    final mrp = product.displayMrp ?? variant?.mrp;

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
                  '${AppConstants.rupeeSymbol}$selling',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                if (mrp != null && _showStrike(mrp, selling)) ...[
                  SizedBox(width: SizeConfig.size8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${AppConstants.rupeeSymbol}$mrp',
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
        ],
      ),
    );
  }

  // ─── Variants list ────────────────────────────────────────────────
  Widget _variantsCard(CategoryFoodProductData product) {
    final variants = product.variants ?? const <FoodVariants>[];
    return _card(
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
          SizedBox(height: SizeConfig.size12),
          for (var i = 0; i < variants.length; i++) ...[
            _variantRow(variants[i]),
            if (i != variants.length - 1) SizedBox(height: SizeConfig.size10),
          ],
        ],
      ),
    );
  }

  Widget _variantRow(FoodVariants v) {
    final selling = v.baseSellingPrice;
    final mrp = v.mrp;
    final variantName = (v.variantName ?? '').trim();
    final unit = (v.quantityLabel ?? '').trim();
    final title = [
      if (variantName.isNotEmpty) variantName,
      if (variantName.isNotEmpty && unit.isNotEmpty) '•',
      if (unit.isNotEmpty) unit,
    ].join(' ');

    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      ),
      child: Row(
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
                  '${AppConstants.rupeeSymbol}$selling',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              if (mrp != null && selling != null && _showStrike(mrp, selling))
                Text(
                  '${AppConstants.rupeeSymbol}$mrp',
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
    );
  }

  // ─── Generic chips card (ingredients / cooking method) ────────────
  Widget _chipsCard(String label, List<String> values) {
    final items = values.where((t) => t.trim().isNotEmpty).toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(label),
          SizedBox(height: SizeConfig.size12),
          Wrap(
            spacing: SizeConfig.size8,
            runSpacing: SizeConfig.size8,
            children: items.map((t) => _tagPill(t)).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Nutrition ────────────────────────────────────────────────────
  Widget _nutritionCard(NutritionalInfo info) {
    final rows = <MapEntry<String, String>>[
      if (info.calories != null) MapEntry('Calories', '${info.calories}'),
      if (info.protein != null) MapEntry('Protein', '${info.protein}'),
      if (info.carbs != null) MapEntry('Carbs', '${info.carbs}'),
      if (info.fats != null) MapEntry('Fats', '${info.fats}'),
      if (info.fiber != null) MapEntry('Fiber', '${info.fiber}'),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('NUTRITION'),
          SizedBox(height: SizeConfig.size12),
          for (var i = 0; i < rows.length; i++) ...[
            _kvRow(rows[i].key, rows[i].value),
            if (i != rows.length - 1) SizedBox(height: SizeConfig.size8),
          ],
        ],
      ),
    );
  }

  // ─── Category ─────────────────────────────────────────────────────
  Widget _categoryCard(CategoryFoodProductData product) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('CATEGORY'),
          SizedBox(height: SizeConfig.size12),
          _kvRow('Category', product.category?.name ?? '—'),
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

  bool _showStrike(num mrp, num selling) => mrp > selling;
}
