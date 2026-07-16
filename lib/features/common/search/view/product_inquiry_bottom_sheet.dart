import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/search/controller/global_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/model/store_match_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Product detail bottom sheet.
///
/// Opened when a user taps a *product* result card in global search
/// (`product`, `variant` or `grocery_product` — see `_productTypes` in
/// global_search_screen.dart). Every element is driven by real API data and
/// hides itself when the backend doesn't send that field, so the sheet renders
/// honestly across the different result categories:
///
/// - The **product snapshot** (photo, name, brand, category, price, rating)
///   comes from the tapped [SearchResultItem] — i.e. the search-service
///   `/search` response (docs/backend/FLUTTER_INTEGRATION_SEARCH.md), which
///   sends only title/subtitle/imageUrl/brand/category/price/city/pincode.
/// - The **pack sizes** (500 g / 1 kg …) and **per-pack pricing** come from the
///   grocery Search-Order `search-by-product` response
///   (docs/backend/SEARCH_ORDER_FLUTTER_GUIDE.md step 2), whose
///   `inventories[].productVariant` carries the `quantity` + `unit` pair. Only
///   grocery inventory has these, so the size selector appears for grocery
///   products and stays hidden for the rest.
/// - The **Sellers near me** list is that same call, cheapest first; tapping a
///   store starts the real self-pickup order flow for the selected pack.
///
/// Stock is deliberately **not** a condition here: the inventory figures aren't
/// dependable enough to gate on, so no availability is labelled, no pack is
/// struck through, and every store stays orderable. `/track` and the shop's own
/// updates are the source of truth for availability (guide §7), not this sheet.
void showProductInquiryBottomSheet(BuildContext context, SearchResultItem item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProductInquirySheet(item: item),
  );
}

/// A pack/size of the product, aggregated across every nearby store: cheapest
/// price on offer and how many stores carry it.
class _PackOption {
  final String variantId;
  final String label;

  /// Cheapest price any nearby store charges for this pack.
  num price;

  /// Dearest price on offer — equal to [price] until a store undercuts another.
  num maxPrice;

  num? mrp;
  int storeCount;
  bool? isVegetarian;

  _PackOption({
    required this.variantId,
    required this.label,
    required this.price,
    required this.maxPrice,
    required this.storeCount,
    this.mrp,
    this.isVegetarian,
  });

  /// True when stores disagree on the price, so [price] is a "from" figure.
  bool get hasPriceRange => maxPrice > price;

  int? get discountPercent {
    final m = mrp;
    if (m == null || m <= price || m <= 0) return null;
    return (((m - price) / m) * 100).round();
  }
}

class _ProductInquirySheet extends StatefulWidget {
  final SearchResultItem item;

  const _ProductInquirySheet({required this.item});

  @override
  State<_ProductInquirySheet> createState() => _ProductInquirySheetState();
}

class _ProductInquirySheetState extends State<_ProductInquirySheet> {
  // ── Live store/inventory data (search-by-product) ───────────────────────
  List<StoreMatch> _stores = const [];
  List<_PackOption> _packs = const [];
  String? _selectedVariantId;
  bool _loadingStores = true;
  bool _storesError = false;

  /// The full product, for the fields the search index omits (description,
  /// country of origin, veg flag). Null until it lands, or when there is none.
  GroceryProductData? _detail;
  bool _descriptionExpanded = false;

  Color get _green => Colors.green.shade700;

  bool get _isGrocery => widget.item.entityType == 'grocery_product';

  @override
  void initState() {
    super.initState();
    // Independent calls — the stores list and the description each render as
    // soon as they arrive rather than waiting on the other.
    _loadStores();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await _controller.fetchProductDetail(widget.item);
    if (!mounted) return;
    setState(() => _detail = detail);
  }

  GlobalSearchController get _controller =>
      Get.isRegistered<GlobalSearchController>()
          ? Get.find<GlobalSearchController>()
          : Get.put(GlobalSearchController());

  /// Fetch the nearby stores that stock this product, then derive the pack
  /// options from their inventory rows.
  Future<void> _loadStores() async {
    setState(() {
      _loadingStores = true;
      _storesError = false;
    });
    try {
      final stores = await _controller.fetchStoresForProduct(widget.item);
      if (!mounted) return;
      final packs = _aggregatePacks(stores);
      setState(() {
        _stores = stores;
        _packs = packs;
        // Packs are cheapest-first, so the first is the best-value default.
        _selectedVariantId = packs.isEmpty ? null : packs.first.variantId;
        _loadingStores = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storesError = true;
        _loadingStores = false;
      });
    }
  }

  /// Collapse every store's inventory rows into one entry per pack, keeping the
  /// cheapest price on offer.
  List<_PackOption> _aggregatePacks(List<StoreMatch> stores) {
    final byVariant = <String, _PackOption>{};
    for (final store in stores) {
      for (final option in store.variantOptions) {
        final label = option.packLabel;
        if (option.variantId.isEmpty || label == null) continue;

        final existing = byVariant[option.variantId];
        if (existing == null) {
          byVariant[option.variantId] = _PackOption(
            variantId: option.variantId,
            label: label,
            price: option.sellingPrice,
            maxPrice: option.sellingPrice,
            mrp: option.mrp,
            storeCount: 1,
            isVegetarian: option.isVegetarian,
          );
          continue;
        }
        if (option.sellingPrice < existing.price) {
          existing.price = option.sellingPrice;
          existing.mrp = option.mrp;
        }
        if (option.sellingPrice > existing.maxPrice) {
          existing.maxPrice = option.sellingPrice;
        }
        existing.storeCount++;
        existing.isVegetarian ??= option.isVegetarian;
      }
    }
    return byVariant.values.toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  _PackOption? get _selectedPack {
    final id = _selectedVariantId;
    if (id == null) return null;
    for (final p in _packs) {
      if (p.variantId == id) return p;
    }
    return null;
  }

  // ── Derived product facts ───────────────────────────────────────────────

  /// Price to headline: the selected pack's real price, else the search
  /// result's own price, else the cheapest store's. Null when nothing priced
  /// it — the row then hides rather than inventing a number.
  num? get _displayPrice {
    final pack = _selectedPack;
    if (pack != null) return pack.price;
    if (widget.item.price != null) return widget.item.price;
    num? cheapest;
    for (final s in _stores) {
      if (s.minSellingPrice <= 0) continue;
      if (cheapest == null || s.minSellingPrice < cheapest) {
        cheapest = s.minSellingPrice;
      }
    }
    return cheapest;
  }

  /// Struck-through MRP — only a genuine one above the price.
  num? get _displayMrp {
    final price = _displayPrice;
    if (price == null) return null;
    final mrp = _selectedPack?.mrp ?? widget.item.mrp;
    return (mrp != null && mrp > price) ? mrp : null;
  }

  int? get _displayDiscount {
    final pack = _selectedPack;
    if (pack != null) return pack.discountPercent;
    return widget.item.hasDiscount ? widget.item.discountPercent : null;
  }

  /// The headline price is a "from" figure whenever it's the cheapest of
  /// several rather than *the* price: stores disagreeing on the selected pack,
  /// or no pack pinned and the figure derived from the cheapest store.
  bool get _priceIsFrom {
    final pack = _selectedPack;
    if (pack != null) return pack.hasPriceRange;
    return widget.item.price == null && _stores.isNotEmpty;
  }

  List<StoreMatch> get _visibleStores {
    final id = _selectedVariantId;
    if (id == null || id.isEmpty) return _stores;
    return _stores.where((s) => s.stocksVariant(id)).toList();
  }

  num _storePrice(StoreMatch store) =>
      store.optionFor(_selectedVariantId)?.sellingPrice ?? store.minSellingPrice;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    final specs = _specRows();
    final description = _description;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabHandle(),
          _sheetHeader(),
          const Divider(height: 1, color: AppColors.greyE5),
          Flexible(
            child: ListView(
              padding: EdgeInsets.only(
                  bottom: SizeConfig.size16 +
                      MediaQuery.of(context).padding.bottom),
              children: [
                _productHero(),
                if (_packs.isNotEmpty) ...[
                  _sectionDivider(),
                  _packSection(),
                ],
                if (description != null) ...[
                  _sectionDivider(),
                  _descriptionSection(description),
                ],
                if (specs.isNotEmpty) ...[
                  _sectionDivider(),
                  _specsSection(specs),
                ],
                _sectionDivider(),
                _sellersSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _grabHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.greyE5,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _sheetHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, 10, SizeConfig.size8, 10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.productDetails,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child:
                  Icon(Icons.close, size: 22, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Product hero: photo, name, brand, rating, pricing ────────────────────
  Widget _productHero() {
    final item = widget.item;
    // The pack's own flag is the more specific truth; the product's is the
    // fallback. Null on both => not a food item, or simply not declared.
    final isVeg = _selectedPack?.isVegetarian ?? _detail?.isVegetarian;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size16, SizeConfig.size16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroImage(item.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isVeg != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 6),
                        child: _vegMark(isVeg),
                      ),
                    ],
                    Expanded(
                      child: CustomText(
                        item.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // `subtitle` is the brand/shop the search service attaches.
                if ((item.subtitle?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    item.subtitle!.trim(),
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.rating != null) ...[
                  const SizedBox(height: 8),
                  _ratingBadge(item.rating!, item.ratingCount),
                ],
                if (_displayPrice != null) ...[
                  const SizedBox(height: 10),
                  _priceRow(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroImage(String? url) {
    final placeholder = Container(
      width: 110,
      height: 140,
      color: AppColors.whiteF9,
      alignment: Alignment.center,
      child: Icon(
          _isGrocery
              ? Icons.local_grocery_store_outlined
              : Icons.shopping_bag_outlined,
          color: AppColors.secondaryTextColor,
          size: 34),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                width: 110,
                height: 140,
                fit: BoxFit.contain,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              )
            : placeholder,
      ),
    );
  }

  /// The FSSAI-style veg / non-veg mark, shown only when the variant declares
  /// `isVegetarian`.
  Widget _vegMark(bool isVeg) {
    final color = isVeg ? _green : AppColors.red00;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _ratingBadge(double rating, int? ratingCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(rating.toStringAsFixed(1),
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white),
              const SizedBox(width: 2),
              const Icon(Icons.star, size: 12, color: AppColors.white),
            ],
          ),
        ),
        if (ratingCount != null) ...[
          const SizedBox(width: 6),
          CustomText('($ratingCount)',
              fontSize: SizeConfig.small, color: AppColors.secondaryTextColor),
        ],
        if (widget.item.assured) ...[
          const SizedBox(width: 8),
          const Icon(Icons.verified, size: 16, color: AppColors.blue5CAF),
          const SizedBox(width: 2),
          CustomText('Assured',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.blue5CAF),
        ],
      ],
    );
  }

  Widget _priceRow() {
    final price = _displayPrice!;
    final mrp = _displayMrp;
    final discount = _displayDiscount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (discount != null && mrp != null) ...[
          Icon(Icons.arrow_downward, size: 14, color: _green),
          CustomText('$discount%',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: _green),
          const SizedBox(width: 6),
          CustomText('₹${SearchResponse.formatPrice(mrp)}',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              decoration: TextDecoration.lineThrough),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: CustomText(
              '${_priceIsFrom ? 'From ' : ''}₹${SearchResponse.formatPrice(price)}',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ── Pack sizes (grocery `quantity` + `unit`) ─────────────────────────────
  Widget _packSection() {
    final selected = _selectedPack;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(_isGrocery ? 'Pack size: ' : 'Variant: ',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor),
              if (selected != null)
                Flexible(
                  child: CustomText(selected.label,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final pack in _packs) _packChip(pack)],
          ),
        ],
      ),
    );
  }

  Widget _packChip(_PackOption pack) {
    final isSelected = _selectedVariantId == pack.variantId;

    return GestureDetector(
      onTap: () => setState(() => _selectedVariantId = pack.variantId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue5CAF.withValues(alpha: 0.08)
              : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.blue5CAF : AppColors.greyE5,
            width: isSelected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              pack.label,
              fontSize: SizeConfig.small,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.blue5CAF : AppColors.mainTextColor,
            ),
            const SizedBox(height: 2),
            CustomText(
              '₹${SearchResponse.formatPrice(pack.price)}',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ── Description (from the product endpoint) ──────────────────────────────

  /// The product blurb, or null when there is none to show. The search index
  /// carries no description, so this only appears once the detail call lands.
  String? get _description {
    final text = _detail?.description?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Long blurbs collapse behind a "Read more" so they can't push the sellers
  /// list off the sheet.
  static const int _descriptionClampChars = 220;

  Widget _descriptionSection(String description) {
    final isLong = description.length > _descriptionClampChars;
    final collapsed = isLong && !_descriptionExpanded;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText('Description',
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          const SizedBox(height: 8),
          CustomText(
            description,
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
            height: 1.4,
            maxLines: collapsed ? 4 : null,
            overflow: collapsed ? TextOverflow.ellipsis : null,
          ),
          if (isLong)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: CustomText(collapsed ? 'Read more' : 'Read less',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue5CAF),
              ),
            ),
        ],
      ),
    );
  }

  // ── Details (only the fields the API actually sent) ──────────────────────
  List<MapEntry<String, String>> _specRows() {
    final item = widget.item;
    final rows = <MapEntry<String, String>>[];

    void add(String label, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) rows.add(MapEntry(label, v));
    }

    add('Brand', item.brand ?? _detail?.brand);
    add('Category', _displayCategory);
    final pack = _selectedPack;
    if (pack != null) add(_isGrocery ? 'Pack size' : 'Variant', pack.label);
    add('Country of origin', _detail?.countryOfOrigin);
    add('Available in', _availabilityLine());
    add('Delivery by', item.deliveryBy);
    add('Warranty', item.warranty);
    return rows;
  }

  /// Category is a display name on most results, but some services index the
  /// raw id instead — never surface a bare ObjectId as a product's category.
  String? get _displayCategory {
    final category = widget.item.category?.trim();
    if (category == null || category.isEmpty) return null;
    return _looksLikeObjectId(category) ? null : category;
  }

  bool _looksLikeObjectId(String value) {
    if (value.length != 24) return false;
    for (final c in value.codeUnits) {
      final isDigit = c >= 0x30 && c <= 0x39;
      final isHexLetter =
          (c >= 0x61 && c <= 0x66) || (c >= 0x41 && c <= 0x46); // a-f / A-F
      if (!isDigit && !isHexLetter) return false;
    }
    return true;
  }

  String? _availabilityLine() {
    final city = widget.item.city?.trim() ?? '';
    final pincode = widget.item.pincode?.trim() ?? '';
    if (city.isNotEmpty && pincode.isNotEmpty) return '$city · $pincode';
    if (city.isNotEmpty) return city;
    if (pincode.isNotEmpty) return pincode;
    return null;
  }

  Widget _specsSection(List<MapEntry<String, String>> rows) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText('Details',
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: CustomText(row.key,
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                        height: 1.35),
                  ),
                  Expanded(
                    child: CustomText(row.value,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        height: 1.35),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Sellers near me ──────────────────────────────────────────────────────
  Widget _sellersSection() {
    final count = _visibleStores.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size12, SizeConfig.size16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 20, color: AppColors.mainTextColor),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                    count > 0
                        ? 'Available at $count store${count == 1 ? '' : 's'} near you'
                        : 'Sellers near me',
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CustomText(
              _selectedPack != null
                  ? 'Tap a store to order ${_selectedPack!.label}'
                  : 'Tap a store to place your order',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor),
          const SizedBox(height: 12),
          _sellersBody(),
        ],
      ),
    );
  }

  Widget _sellersBody() {
    if (_loadingStores) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_storesError) {
      return _sellersPlaceholder(
        icon: Icons.cloud_off,
        message: 'Could not load nearby stores.',
        action: TextButton(
          onPressed: _loadStores,
          child: CustomText('Retry',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.blue5CAF),
        ),
      );
    }
    // Cheapest-first, exactly as the API sorted them.
    final stores = _visibleStores;
    if (stores.isEmpty) {
      return _sellersPlaceholder(
        icon: Icons.storefront_outlined,
        message: 'Not available in stores near you yet.',
      );
    }
    return Column(children: [for (final store in stores) _sellerCard(store)]);
  }

  Widget _sellersPlaceholder(
      {required IconData icon, required String message, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteF9,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.secondaryTextColor),
          const SizedBox(height: 8),
          CustomText(message,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _sellerCard(StoreMatch store) {
    final name = (store.businessName?.trim().isNotEmpty ?? false)
        ? store.businessName!.trim()
        : 'Store';
    final option = store.optionFor(_selectedVariantId);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _orderFromStore(store),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.greyE5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _sellerDp(store.businessLogo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(name,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CustomText(
                          '₹${SearchResponse.formatPrice(_storePrice(store))}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor),
                      // The pack this price buys, when the store's inventory
                      // named one.
                      if (option?.packLabel != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: CustomText('/ ${option!.packLabel}',
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.blue5CAF),
                      const SizedBox(width: 2),
                      Flexible(
                        child: CustomText(
                            store.distanceKm != null
                                ? '${store.distanceKm!.toStringAsFixed(1)} km away'
                                : (store.locationLine ?? 'Nearby'),
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue5CAF,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 22, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  /// Pick this store → start the real self-pickup order flow for it, pinned to
  /// the pack the user selected.
  void _orderFromStore(StoreMatch store) {
    final controller = _controller;
    Navigator.of(context).maybePop();
    controller.openProductOrder(widget.item,
        store: store, variantId: _selectedVariantId);
  }

  Widget _sellerDp(String? url) {
    final placeholder = Container(
      width: 48,
      height: 48,
      color: AppColors.greyE5,
      alignment: Alignment.center,
      child: const Icon(Icons.store_mall_directory_outlined,
          size: 24, color: AppColors.secondaryTextColor),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }

  // ── Shared bits ──────────────────────────────────────────────────────────
  Widget _sectionDivider() => Container(height: 8, color: AppColors.whiteF4);
}
